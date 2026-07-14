// Supabase Edge Function: `extract`
// ---------------------------------------------------------------------------
// Reads an uploaded file from the shared `attachments` Storage bucket and uses
// Groq's free-tier LLM API to extract structured defect or requisition fields
// as JSON. The client shows the result in an EDITABLE review sheet before
// anything is saved — the model never writes to the fleet database.
//
// Secrets required (set once, no credit card needed):
//   supabase secrets set GROQ_API_KEY=your_key_from_console.groq.com
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.
// ---------------------------------------------------------------------------
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// The esm.sh build of `xlsx` pulls in Node-only internals (e.g. Buffer) that
// don't exist in Supabase's Deno Edge Runtime, crashing the isolate at boot.
// Deno's native `npm:` specifier uses Deno's own (more complete) Node compat
// layer instead, and is on Supabase's bundler allowlist.
import XLSX from "npm:xlsx@0.18.5";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const TEXT_MODEL = "llama-3.3-70b-versatile";
const VISION_MODEL = "llama-3.2-90b-vision-preview";
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });

// Guarantees every request resolves within a bound — a stalled upstream call
// can never hang the client's loading dialog forever.
function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    p,
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error("timeout")), ms)
    ),
  ]);
}

function isSpreadsheet(path: string): boolean {
  const ext = path.split(".").pop()?.toLowerCase() ?? "";
  return ext === "xlsx" || ext === "xls" || ext === "xlsm";
}

function isPdf(path: string): boolean {
  return (path.split(".").pop()?.toLowerCase() ?? "") === "pdf";
}

function isImage(path: string): boolean {
  const ext = path.split(".").pop()?.toLowerCase() ?? "";
  return ["png", "jpg", "jpeg", "webp", "gif"].includes(ext);
}

// The AI can't parse the binary .xlsx zip format directly, so we parse the
// workbook here and hand it a plain-text CSV rendering of every sheet.
function spreadsheetToText(buf: Uint8Array): string {
  const wb = XLSX.read(buf, { type: "array" });
  return wb.SheetNames.map((name: string) => {
    const csv = XLSX.utils.sheet_to_csv(wb.Sheets[name]);
    return `Sheet: ${name}\n${csv}`;
  }).join("\n\n");
}

function mimeFor(path: string): string {
  const ext = path.split(".").pop()?.toLowerCase() ?? "";
  switch (ext) {
    case "png":
      return "image/png";
    case "jpg":
    case "jpeg":
      return "image/jpeg";
    case "webp":
      return "image/webp";
    case "gif":
      return "image/gif";
    default:
      return "application/octet-stream";
  }
}

const DEFECT_SCHEMA = {
  type: "object",
  properties: {
    title: { type: "string" },
    description: { type: "string" },
    location: {
      type: "string",
      enum: ["engineRoom", "deck", "bridge", "accommodation", "galley", "other"],
    },
    priority: {
      type: "string",
      enum: ["low", "medium", "high", "critical"],
    },
    assignedOfficer: { type: "string" },
    requiredSpareParts: { type: "string" },
  },
};

const REQUISITION_SCHEMA = {
  type: "object",
  properties: {
    itemName: { type: "string" },
    partNumber: { type: "string" },
    oemManufacturer: { type: "string" },
    quantity: { type: "number" },
    unit: { type: "string" },
    unitPrice: { type: "number" },
    department: { type: "string", enum: ["engine", "deck", "steward"] },
    priority: { type: "string", enum: ["low", "normal", "urgent"] },
    notes: { type: "string" },
  },
};

function basePromptFor(kind: string): string {
  if (kind === "requisition") {
    return "You are reading a ship spare-parts requisition (a purchase request, " +
      "quotation, or parts list). Extract the requested item's details. Use an " +
      "empty string for unknown text fields and 0 for unknown numbers. If several " +
      "items appear, extract the primary/first one.";
  }
  return "You are reading a ship equipment defect / fault report. Extract the " +
    "defect details. Choose the closest location and priority. Use an empty " +
    "string for anything not stated.";
}

// Groq's JSON mode guarantees syntactically valid JSON but not a specific
// schema, so the exact field names/types/enums are spelled out in the prompt.
function promptFor(kind: string, schema: Record<string, unknown>): string {
  return `${basePromptFor(kind)} Respond with ONLY a single JSON object (no ` +
    `markdown fences, no commentary) matching exactly this JSON schema: ` +
    `${JSON.stringify(schema)}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    if (!GROQ_API_KEY) {
      return json({ error: "not_configured" }, 503);
    }
    const { path, kind } = await req.json();
    if (typeof path !== "string" || !path) {
      return json({ error: "missing_path" }, 400);
    }
    const extractionKind = kind === "requisition" ? "requisition" : "defect";

    if (isPdf(path)) {
      return json({ error: "pdf_not_supported" }, 415);
    }

    // Download the file bytes with the service role (bypasses RLS).
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE);
    const dl = await admin.storage.from("attachments").download(path);
    if (dl.error || !dl.data) {
      return json({ error: "download_failed" }, 404);
    }
    const buf = new Uint8Array(await dl.data.arrayBuffer());

    const schema = extractionKind === "requisition"
      ? REQUISITION_SCHEMA
      : DEFECT_SCHEMA;
    const prompt = promptFor(extractionKind, schema);

    let groqBody: Record<string, unknown>;
    if (isSpreadsheet(path)) {
      let sheetText: string;
      try {
        sheetText = spreadsheetToText(buf);
      } catch (_) {
        return json({ error: "parse_failed" }, 422);
      }
      groqBody = {
        model: TEXT_MODEL,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: `Spreadsheet content:\n\n${sheetText}` },
        ],
      };
    } else if (isImage(path)) {
      let binary = "";
      for (let i = 0; i < buf.length; i++) binary += String.fromCharCode(buf[i]);
      const base64 = btoa(binary);
      groqBody = {
        model: VISION_MODEL,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              {
                type: "image_url",
                image_url: { url: `data:${mimeFor(path)};base64,${base64}` },
              },
            ],
          },
        ],
      };
    } else {
      const text = new TextDecoder().decode(buf);
      groqBody = {
        model: TEXT_MODEL,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: text.slice(0, 20_000) },
        ],
      };
    }

    let groqRes: Response;
    try {
      groqRes = await withTimeout(
        fetch(GROQ_URL, {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "authorization": `Bearer ${GROQ_API_KEY}`,
          },
          body: JSON.stringify(groqBody),
        }),
        30_000,
      );
    } catch (_) {
      return json({ error: "ai_timeout" }, 504);
    }

    if (!groqRes.ok) {
      const detail = await groqRes.text();
      return json({ error: `ai_failed_${groqRes.status}_${detail.slice(0, 400)}` }, 502);
    }

    const gj = await groqRes.json();
    const text = gj?.choices?.[0]?.message?.content ?? "{}";
    let data: Record<string, unknown>;
    try {
      data = JSON.parse(text);
    } catch (_) {
      return json({ error: "parse_failed", raw: text }, 502);
    }

    return json({ kind: extractionKind, data });
  } catch (e) {
    return json({ error: "unexpected", detail: String(e) }, 500);
  }
});
