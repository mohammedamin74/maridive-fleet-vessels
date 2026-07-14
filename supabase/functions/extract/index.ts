// Supabase Edge Function: `extract`
// ---------------------------------------------------------------------------
// Reads an uploaded file from the shared `attachments` Storage bucket and uses
// OpenRouter's free-tier LLM API to extract structured defect or requisition
// fields as JSON. The client shows the result in an EDITABLE review sheet
// before anything is saved — the model never writes to the fleet database.
//
// Supported: Excel (.xlsx/.xls/.xlsm), Word (.docx), PDF, and plain text/csv.
// PDF text extraction is offloaded to OpenRouter's own file-parser plugin
// (Cloudflare AI engine, still free) rather than a PDF library running
// in-process — a known PDF.js-based library (unpdf) has an open, unresolved
// issue crashing specifically in Supabase's production Edge Runtime while
// working locally, and this app already lost hours to one such Deno/Node
// interop crash this session. Images aren't supported yet.
//
// Secrets required (no credit card needed, ever, for :free models):
//   supabase secrets set OPENROUTER_API_KEY=your_key_from_openrouter.ai
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.
// ---------------------------------------------------------------------------
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// The esm.sh build of `xlsx` pulls in Node-only internals (e.g. Buffer) that
// don't exist in Supabase's Deno Edge Runtime, crashing the isolate at boot.
// Deno's native `npm:` specifier uses Deno's own (more complete) Node compat
// layer instead, and is on Supabase's bundler allowlist.
import XLSX from "npm:xlsx@0.18.5";
import mammoth from "npm:mammoth@1.8.0";
import { Buffer } from "node:buffer";

const OPENROUTER_API_KEY = Deno.env.get("OPENROUTER_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const TEXT_MODEL = "tencent/hy3:free";
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

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

function extOf(path: string): string {
  return path.split(".").pop()?.toLowerCase() ?? "";
}

function isSpreadsheet(path: string): boolean {
  return ["xlsx", "xls", "xlsm"].includes(extOf(path));
}

function isDocx(path: string): boolean {
  return extOf(path) === "docx";
}

function isPdf(path: string): boolean {
  return extOf(path) === "pdf";
}

// Images, and the old binary .doc format (not zip/XML-based like .docx, so
// mammoth can't read it) — auto-extraction isn't supported for these yet.
// They still get downloaded and viewed fine, just not auto-filled from AI.
function isUnsupportedForExtraction(path: string): boolean {
  return ["doc", "png", "jpg", "jpeg", "webp", "gif"].includes(extOf(path));
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

async function docxToText(buf: Uint8Array): Promise<string> {
  const result = await mammoth.extractRawText({ buffer: Buffer.from(buf) });
  return result.value;
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

const REQUISITION_ITEM_SCHEMA = {
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

// A requisition file (a parts list / quotation) commonly lists many line
// items, unlike a defect report which is one incident — so requisitions
// extract as an array of items, each reviewed individually on the client
// before being saved, while defects stay a single object.
const REQUISITION_SCHEMA = {
  type: "object",
  properties: {
    items: { type: "array", items: REQUISITION_ITEM_SCHEMA },
  },
  required: ["items"],
};

function basePromptFor(kind: string): string {
  if (kind === "requisition") {
    return "You are reading a ship spare-parts requisition (a purchase request, " +
      "quotation, or parts list). It may list MULTIPLE items/rows. Extract " +
      "EVERY item as a separate entry — one per row. Do not skip rows or merge " +
      "items together. Use an empty string for unknown text fields and 0 for " +
      "unknown numbers.";
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
    if (!OPENROUTER_API_KEY) {
      return json({ error: "not_configured" }, 503);
    }
    const { path, kind } = await req.json();
    if (typeof path !== "string" || !path) {
      return json({ error: "missing_path" }, 400);
    }
    const extractionKind = kind === "requisition" ? "requisition" : "defect";

    if (isUnsupportedForExtraction(path)) {
      return json({ error: "extraction_unsupported_file_type" }, 415);
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

    // `userContent` is either a plain string (spreadsheet/docx/text — parsed
    // to text here) or a content-parts array carrying the raw PDF, which
    // OpenRouter's file-parser plugin turns into text on their end.
    let userContent: string | Record<string, unknown>[];
    let plugins: Record<string, unknown>[] | undefined;
    if (isSpreadsheet(path)) {
      try {
        userContent = `Spreadsheet content:\n\n${spreadsheetToText(buf)}`;
      } catch (_) {
        return json({ error: "parse_failed" }, 422);
      }
    } else if (isDocx(path)) {
      try {
        userContent =
          `Document content:\n\n${(await docxToText(buf)).slice(0, 20_000)}`;
      } catch (_) {
        return json({ error: "parse_failed" }, 422);
      }
    } else if (isPdf(path)) {
      let binary = "";
      for (let i = 0; i < buf.length; i++) binary += String.fromCharCode(buf[i]);
      const base64 = btoa(binary);
      userContent = [
        {
          type: "file",
          file: {
            filename: path.split("/").pop() ?? "document.pdf",
            file_data: `data:application/pdf;base64,${base64}`,
          },
        },
      ];
      plugins = [{ id: "file-parser", pdf: { engine: "cloudflare-ai" } }];
    } else {
      userContent = new TextDecoder().decode(buf).slice(0, 20_000);
    }

    let orRes: Response;
    try {
      orRes = await withTimeout(
        fetch(OPENROUTER_URL, {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "authorization": `Bearer ${OPENROUTER_API_KEY}`,
          },
          body: JSON.stringify({
            model: TEXT_MODEL,
            ...(plugins ? { plugins } : {}),
            response_format: {
              type: "json_schema",
              json_schema: {
                name: extractionKind === "requisition"
                  ? "requisition_extraction"
                  : "defect_extraction",
                schema,
              },
            },
            messages: [
              { role: "system", content: prompt },
              { role: "user", content: userContent },
            ],
          }),
        }),
        30_000,
      );
    } catch (_) {
      return json({ error: "ai_timeout" }, 504);
    }

    if (!orRes.ok) {
      const detail = await orRes.text();
      return json({ error: `ai_failed_${orRes.status}_${detail.slice(0, 400)}` }, 502);
    }

    const dj = await orRes.json();
    const text = dj?.choices?.[0]?.message?.content ?? "{}";
    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(text);
    } catch (_) {
      return json({ error: "parse_failed", raw: text }, 502);
    }

    const data = extractionKind === "requisition"
      ? (Array.isArray(parsed?.items) ? parsed.items : [])
      : parsed;

    return json({ kind: extractionKind, data });
  } catch (e) {
    return json({ error: "unexpected", detail: String(e) }, 500);
  }
});
