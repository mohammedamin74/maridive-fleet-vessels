// Supabase Edge Function: `extract`
// ---------------------------------------------------------------------------
// Reads an uploaded file from the shared `attachments` Storage bucket and uses
// Google Gemini (multimodal, free tier) to extract structured defect or
// requisition fields as JSON. The client shows the result in an EDITABLE review
// sheet before anything is saved — the model never writes to the fleet database.
//
// Secrets required (set once):
//   supabase secrets set GEMINI_API_KEY=your_key_from_aistudio.google.com
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.
// ---------------------------------------------------------------------------
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// The esm.sh build of `xlsx` pulls in Node-only internals (e.g. Buffer) that
// don't exist in Supabase's Deno Edge Runtime, crashing the isolate at boot
// for every request regardless of import timing. SheetJS publishes an
// official Deno-native build on their own CDN specifically to avoid this —
// same API, no Node shims.
import * as XLSX from "https://cdn.sheetjs.com/xlsx-0.20.3/package/xlsx.mjs";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const MODEL = "gemini-2.0-flash";

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

// Guarantees every request resolves within a bound — a stuck dynamic import
// (esm.sh unreachable) or a stalled upstream call can never hang the client's
// loading dialog forever.
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

// Gemini's multimodal API only reads inline_data as an image/PDF/audio/video/
// plain-text document — it can't parse the binary .xlsx zip format directly.
// So for spreadsheets we parse the workbook here and hand Gemini a plain-text
// CSV rendering of every sheet instead of the raw bytes.
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
    case "pdf":
      return "application/pdf";
    case "png":
      return "image/png";
    case "jpg":
    case "jpeg":
      return "image/jpeg";
    case "webp":
      return "image/webp";
    case "gif":
      return "image/gif";
    case "txt":
    case "csv":
      return "text/plain";
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

function promptFor(kind: string): string {
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    if (!GEMINI_API_KEY) {
      return json({ error: "not_configured" }, 503);
    }
    const { path, kind } = await req.json();
    if (typeof path !== "string" || !path) {
      return json({ error: "missing_path" }, 400);
    }
    const extractionKind = kind === "requisition" ? "requisition" : "defect";

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

    let parts: Record<string, unknown>[];
    if (isSpreadsheet(path)) {
      let sheetText: string;
      try {
        sheetText = spreadsheetToText(buf);
      } catch (_) {
        return json({ error: "parse_failed" }, 422);
      }
      parts = [
        { text: promptFor(extractionKind) },
        { text: `Spreadsheet content:\n\n${sheetText}` },
      ];
    } else {
      let binary = "";
      for (let i = 0; i < buf.length; i++) binary += String.fromCharCode(buf[i]);
      const base64 = btoa(binary);
      parts = [
        { inline_data: { mime_type: mimeFor(path), data: base64 } },
        { text: promptFor(extractionKind) },
      ];
    }

    let geminiRes: Response;
    try {
      geminiRes = await withTimeout(
        fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}`,
          {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({
              contents: [{ parts }],
              generationConfig: {
                responseMimeType: "application/json",
                responseSchema: schema,
              },
            }),
          },
        ),
        30_000,
      );
    } catch (_) {
      return json({ error: "ai_timeout" }, 504);
    }

    if (!geminiRes.ok) {
      const detail = await geminiRes.text();
      return json({ error: "ai_failed", status: geminiRes.status, detail }, 502);
    }

    const gj = await geminiRes.json();
    const text = gj?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
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
