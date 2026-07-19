// Supabase Edge Function: `extract`
// ---------------------------------------------------------------------------
// Reads an uploaded file from the shared `attachments` Storage bucket and uses
// OpenRouter's free-tier LLM API to extract structured module fields as JSON.
// Every module has a registered `kind` (see KINDS below) — defects, tanks,
// certificates, crew, handover reports, etc. The client shows the result in an
// EDITABLE review sheet before anything is saved — the model never writes to
// the fleet database.
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
// The esm.sh build of `xlsx` pulls in Node-only internals (e.g. Buffer) that
// don't exist in Supabase's Deno Edge Runtime, crashing the isolate at boot.
// Deno's native `npm:` specifier uses Deno's own (more complete) Node compat
// layer instead, and is on Supabase's bundler allowlist.
import XLSX from "npm:xlsx@0.18.5";
import mammoth from "npm:mammoth@1.8.0";
import { Buffer } from "node:buffer";

const OPENROUTER_API_KEY = Deno.env.get("OPENROUTER_API_KEY") ?? "";
// Google AI Studio key (aistudio.google.com — free, no credit card). When
// set, Gemini is the PRIMARY extractor: far higher free daily quota than
// OpenRouter's 50 req/day, native PDF understanding (including scanned
// documents — OCR built in), and image input. OpenRouter stays as fallback.
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
// Free-tier models (hard project constraint: never a paid model) are
// individually flaky — tencent/hy3 measured 504s and truncated outputs on
// 2026-07-15 after two clean 44-item runs days earlier. A fallback chain
// makes extraction survive any one model having a bad day. Order: fastest
// first, the historically-accurate hy3 second.
// Rate-limited models reject in <1s, so a long chain is nearly free to walk;
// the slow-but-accurate hy3 sits late so faster models get first shot while
// hy3 still inherits most of the time budget when they're all rate-limited.
const TEXT_MODELS = [
  "qwen/qwen3-next-80b-a3b-instruct:free",
  "nvidia/nemotron-3-super-120b-a12b:free",
  "tencent/hy3:free",
  "meta-llama/llama-3.3-70b-instruct:free",
  // Last: measured hanging for 67s without answering on 2026-07-15, which
  // starved the models after it — only safe in the final slot.
  "openai/gpt-oss-20b:free",
];
// For scanned PDFs and photos — free models that accept image input. These
// endpoints don't reliably support json_schema response_format, so the
// vision path relies on the prompt + fence stripping + the schema gate.
const VISION_MODELS = [
  "nvidia/nemotron-nano-12b-v2-vl:free",
  "google/gemma-4-31b-it:free",
  "google/gemma-4-26b-a4b-it:free",
];
// Gemini free-tier models, best first. All are multimodal (text, images,
// and whole PDFs — scans included), so one chain serves every file type.
// The "-latest" aliases lead because Google retires concrete model ids for
// new accounts (gemini-2.5-* now 404s with "no longer available to new
// users"); the aliases always resolve to a callable model.
const GEMINI_MODELS = [
  "gemini-flash-latest",
  "gemini-3.5-flash",
  "gemini-flash-lite-latest",
  "gemini-3.1-flash-lite",
];
const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models";
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

// Only the old binary .doc format (not zip/XML-based like .docx, so mammoth
// can't read it) has no extraction path. Images go to free vision models.
function isUnsupportedForExtraction(path: string): boolean {
  return extOf(path) === "doc";
}

const IMAGE_MIMES: Record<string, string> = {
  png: "image/png",
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  webp: "image/webp",
  gif: "image/gif",
};

function toBase64(bytes: Uint8Array): string {
  // Chunked conversion — a per-byte concat loop burns CPU on multi-MB files.
  let binary = "";
  const CHUNK = 0x8000;
  for (let i = 0; i < bytes.length; i += CHUNK) {
    binary += String.fromCharCode(...bytes.subarray(i, i + CHUNK));
  }
  return btoa(binary);
}

function indexOfBytes(
  haystack: Uint8Array,
  needle: number[],
  from: number,
): number {
  outer: for (let i = from; i <= haystack.length - needle.length; i++) {
    for (let j = 0; j < needle.length; j++) {
      if (haystack[i + j] !== needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

// Scanner-produced PDFs are one embedded JPEG per page with no text layer —
// the text-based file-parser returns nothing for them. Pull the JPEGs out
// (SOI FFD8FF … EOI FFD9) so they can go to a free vision model instead.
function extractPdfJpegs(buf: Uint8Array): Uint8Array[] {
  const images: Uint8Array[] = [];
  let pos = 0;
  while (images.length < 4) {
    const start = indexOfBytes(buf, [0xFF, 0xD8, 0xFF], pos);
    if (start < 0) break;
    const end = indexOfBytes(buf, [0xFF, 0xD9], start + 3);
    if (end < 0) break;
    const jpeg = buf.subarray(start, end + 2);
    // Skip thumbnails; a full scanned page is comfortably >20KB.
    if (jpeg.length > 20_000) images.push(jpeg);
    pos = end + 2;
  }
  return images;
}

// A text PDF always references at least one /Font; a pure scan has none.
function pdfHasTextLayer(buf: Uint8Array): boolean {
  return indexOfBytes(
    buf,
    [0x2F, 0x46, 0x6F, 0x6E, 0x74], // "/Font"
    0,
  ) >= 0;
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

// ---------------------------------------------------------------------------
// Schema registry — the ONLY thing that grows when a module gains AI-fill.
// Field names mirror the Dart models exactly, so extracted JSON maps straight
// onto each module's form. `mode: "list"` kinds wrap items in {items: [...]}
// (one entry per document row); `mode: "fields"` kinds return one object.
// Dates are requested as ISO 8601 strings; the client parses leniently.
// ---------------------------------------------------------------------------
type Kind = {
  schema: Record<string, unknown>;
  prompt: string;
  mode: "fields" | "list";
};

const DATE = { type: "string", description: "ISO 8601 date, e.g. 2026-07-15" };

function listOf(item: Record<string, unknown>): Record<string, unknown> {
  return {
    type: "object",
    properties: { items: { type: "array", items: item } },
    required: ["items"],
  };
}

const LIST_RULES = " It may list MULTIPLE items/rows. Extract EVERY item as " +
  "a separate entry — one per row. Do not skip rows or merge items together. " +
  "Use an empty string for unknown text fields and 0 for unknown numbers.";
const FIELD_RULES = " Use an empty string for anything not stated and 0 for " +
  "unknown numbers. Choose the closest enum value where a list is given.";

const KINDS: Record<string, Kind> = {
  defect: {
    mode: "list",
    prompt: "You are reading a ship equipment defect / fault report or a " +
      "defect register/log (e.g. an Excel sheet listing multiple defects, " +
      "one per row). It may describe a SINGLE defect or MULTIPLE defects." +
      LIST_RULES,
    schema: listOf({
      type: "object",
      properties: {
        title: { type: "string" },
        description: { type: "string" },
        location: {
          type: "string",
          enum: [
            "engineRoom",
            "deck",
            "bridge",
            "accommodation",
            "galley",
            "other",
          ],
        },
        priority: {
          type: "string",
          enum: ["low", "medium", "high", "critical"],
        },
        assignedOfficer: { type: "string" },
        requiredSpareParts: { type: "string" },
      },
    }),
  },
  requisition: {
    mode: "list",
    prompt: "You are reading a ship spare-parts requisition (a purchase " +
      "request, quotation, or parts list)." + LIST_RULES,
    schema: listOf({
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
    }),
  },
  tank_reading: {
    mode: "list",
    prompt: "You are reading a ship tank sounding / ullage sheet or ROB " +
      "(remaining on board) report. Each row is one tank measurement. Report " +
      "volumes in cubic meters in levelM3 (convert liters by dividing by " +
      "1000)." + LIST_RULES,
    schema: listOf({
      type: "object",
      properties: {
        tankName: { type: "string" },
        levelM3: { type: "number" },
        temperatureC: { type: "number" },
        timestamp: DATE,
      },
    }),
  },
  logbook: {
    mode: "fields",
    prompt: "You are reading a ship logbook page or operational note. Copy " +
      "the entry faithfully into `text` (keep times, headings and figures; " +
      "use new lines between events) and extract the entry date." +
      FIELD_RULES,
    schema: {
      type: "object",
      properties: { text: { type: "string" }, timestamp: DATE },
    },
  },
  maintenance: {
    mode: "list",
    prompt: "You are reading a planned-maintenance (PMS) sheet, work order, " +
      "or maintenance report for a ship. Each job/work order is one entry." +
      LIST_RULES,
    schema: listOf({
      type: "object",
      properties: {
        title: { type: "string" },
        description: { type: "string" },
        performedBy: { type: "string" },
        dueDate: DATE,
        status: {
          type: "string",
          enum: ["planned", "inProgress", "completed"],
        },
      },
    }),
  },
  port_call: {
    mode: "fields",
    prompt: "You are reading a port call notice, agent appointment, or " +
      "pre-arrival message for a ship. Extract the port call logistics; " +
      "bunkers and fresh water are numbers as stated in the document." +
      FIELD_RULES,
    schema: {
      type: "object",
      properties: {
        portName: { type: "string" },
        arrivalEta: DATE,
        pilotBoardingTime: DATE,
        agentName: { type: "string" },
        agentContact: { type: "string" },
        bunkersMgoRequired: { type: "number" },
        bunkersHfoRequired: { type: "number" },
        freshWaterRequired: { type: "number" },
        provisionsRequired: { type: "string" },
        sludgeDisposalRequired: { type: "boolean" },
        sludgeQuantity: { type: "number" },
      },
    },
  },
  port_requirement: {
    mode: "list",
    prompt: "You are reading a list of documents/requirements a ship must " +
      "have ready before arriving at a port (customs, health, security, " +
      "provisions). Each requirement is one entry." + LIST_RULES,
    schema: listOf({
      type: "object",
      properties: {
        title: { type: "string" },
        portName: { type: "string" },
        category: {
          type: "string",
          enum: [
            "documents",
            "customs",
            "health",
            "security",
            "provisions",
            "other",
          ],
        },
        notes: { type: "string" },
      },
    }),
  },
  vessel_certificate: {
    mode: "list",
    prompt: "You are reading one or more ship (vessel) certificates or a " +
      "certificate status list — class, flag, safety, radio, load line, " +
      "etc. Each certificate is one entry; capture exact issue and expiry " +
      "dates." + LIST_RULES,
    schema: listOf({
      type: "object",
      properties: {
        documentName: { type: "string" },
        issuingAuthority: { type: "string" },
        issueDate: DATE,
        expiryDate: DATE,
      },
    }),
  },
  crew_certificate: {
    mode: "list",
    prompt: "You are reading crew/officer certificates (CoC, STCW courses, " +
      "medical fitness) or a crew certificate matrix. Each certificate per " +
      "person is one entry; capture exact issue and expiry dates." +
      LIST_RULES,
    schema: listOf({
      type: "object",
      properties: {
        officerName: { type: "string" },
        rank: { type: "string" },
        certType: {
          type: "string",
          enum: ["coc", "stcw", "medical", "other"],
        },
        issueDate: DATE,
        expiryDate: DATE,
      },
    }),
  },
  crew: {
    mode: "list",
    prompt: "You are reading a ship crew list or sign-on/sign-off document. " +
      "Each crew member is one entry. Do NOT include passport or ID numbers " +
      "anywhere in the output, even in notes." + LIST_RULES,
    schema: listOf({
      type: "object",
      properties: {
        name: { type: "string" },
        rank: { type: "string" },
        nationality: { type: "string" },
        signOnDate: DATE,
        signOffDate: DATE,
        notes: { type: "string" },
      },
    }),
  },
  daily_task: {
    mode: "list",
    prompt: "You are reading a ship daily work plan, watch routine, or " +
      "inspection rounds sheet. Each task/round is one entry." + LIST_RULES,
    schema: listOf({
      type: "object",
      properties: {
        title: { type: "string" },
        category: {
          type: "string",
          enum: [
            "engineRoomRounds",
            "deckRounds",
            "safetyEquipmentChecks",
            "navigationEquipmentTests",
            "galleyHygieneInspections",
          ],
        },
        assignedTo: { type: "string" },
        frequency: { type: "string", enum: ["daily", "everyWatch", "weekly"] },
        scheduledTime: DATE,
      },
    }),
  },
  urgent_notification: {
    mode: "fields",
    prompt: "You are reading an urgent alert, incident message, or " +
      "emergency notification from a ship. Extract the alert details." +
      FIELD_RULES,
    schema: {
      type: "object",
      properties: {
        alertType: {
          type: "string",
          enum: ["fire", "flooding", "engineFailure", "routing", "other"],
        },
        location: { type: "string" },
        description: { type: "string" },
        timestamp: DATE,
      },
    },
  },
  handover: {
    mode: "fields",
    prompt: "You are reading a crew/officer handover report (taking-over / " +
      "handing-over notes between an outgoing and incoming officer). Fill " +
      "each section with the relevant content, preserving figures and " +
      "equipment names; leave a section empty if the document has nothing " +
      "for it." + FIELD_RULES,
    schema: {
      type: "object",
      properties: {
        outgoingOfficer: { type: "string" },
        incomingOfficer: { type: "string" },
        rank: { type: "string" },
        handoverDate: DATE,
        safety: { type: "string" },
        machinery: { type: "string" },
        pendingDefects: { type: "string" },
        bunkersAndTanks: { type: "string" },
        certificatesExpiring: { type: "string" },
        remarks: { type: "string" },
      },
    },
  },
};

// The free model's JSON mode guarantees syntactically valid JSON but not a
// specific schema, so the exact field names/types/enums are spelled out in
// the prompt.
function promptFor(kind: Kind): string {
  return `${kind.prompt} Respond with ONLY a single JSON object (no ` +
    `markdown fences, no commentary) matching exactly this JSON schema: ` +
    `${JSON.stringify(kind.schema)}`;
}

// Models often emit literal newlines/tabs inside JSON string values when a
// field holds multiline text (measured on Gemini for handover sections);
// JSON.parse rejects raw control characters in strings. Walk the text and
// escape them only inside string literals — everything else is untouched.
function escapeControlCharsInStrings(text: string): string {
  let out = "";
  let inString = false;
  let escaped = false;
  for (const ch of text) {
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch === "\\") {
        escaped = true;
      } else if (ch === '"') {
        inString = false;
      } else if (ch === "\n") {
        out += "\\n";
        continue;
      } else if (ch === "\r") {
        out += "\\r";
        continue;
      } else if (ch === "\t") {
        out += "\\t";
        continue;
      }
    } else if (ch === '"') {
      inString = true;
    }
    out += ch;
  }
  return out;
}

// Returns the first balanced top-level JSON object/array in the text, or
// null. String-aware, so braces inside values don't miscount. Rescues
// answers with commentary or a second JSON object after the real one.
function firstBalancedJson(text: string): string | null {
  const start = text.search(/[{[]/);
  if (start < 0) return null;
  const open = text[start];
  const close = open === "{" ? "}" : "]";
  let depth = 0;
  let inString = false;
  let escaped = false;
  for (let i = start; i < text.length; i++) {
    const ch = text[i];
    if (inString) {
      if (escaped) escaped = false;
      else if (ch === "\\") escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }
    if (ch === '"') inString = true;
    else if (ch === open) depth++;
    else if (ch === close && --depth === 0) {
      return text.slice(start, i + 1);
    }
  }
  return null;
}

// Strip optional markdown fences (some models add them despite instructions)
// and parse; on failure retry with control characters escaped inside string
// values, then with the first balanced JSON value only; null when nothing
// parses.
function parseModelJson(raw: string): Record<string, unknown> | null {
  let text = raw.trim();
  const fence = text.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/);
  if (fence) text = fence[1];
  try {
    return JSON.parse(text) as Record<string, unknown>;
  } catch (_) {
    // fall through to repairs
  }
  const repaired = escapeControlCharsInStrings(text);
  try {
    return JSON.parse(repaired) as Record<string, unknown>;
  } catch (_) {
    // fall through to balanced extraction
  }
  const balanced = firstBalancedJson(repaired);
  if (balanced !== null) {
    try {
      return JSON.parse(balanced) as Record<string, unknown>;
    } catch (_) {
      // unrecoverable
    }
  }
  return null;
}

// Syntactically-valid garbage is a real free-tier failure mode — one
// measured answer packed all the other fields, escaped, inside `title`.
// Accept only answers that actually resemble the schema: fields mode needs
// ≥2 expected keys present; list mode needs an `items` array whose first
// entry shares ≥1 expected key.
function matchesSchema(
  kindDef: Kind,
  candidate: Record<string, unknown>,
): boolean {
  const expectedKeys = (def: Record<string, unknown>): string[] =>
    Object.keys((def.properties as Record<string, unknown> | undefined) ?? {});
  if (kindDef.mode === "list") {
    const items = (candidate as { items?: unknown }).items;
    const itemSchema = ((kindDef.schema.properties as {
      items?: { items?: Record<string, unknown> };
    })?.items?.items) ?? {};
    return Array.isArray(items) &&
      (items.length === 0 ||
        (typeof items[0] === "object" && items[0] !== null &&
          expectedKeys(itemSchema).some((k) => k in (items[0] as object))));
  }
  const present = expectedKeys(kindDef.schema)
    .filter((k) => k in candidate).length;
  return present >= 2;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    if (!OPENROUTER_API_KEY) {
      return json({ error: "not_configured" }, 503);
    }
    const { path, kind, diag } = await req.json();
    // Temporary diagnostic: list the Gemini models this project's key can
    // actually call (model availability varies by account age/tier).
    if (diag === "gemini_models") {
      if (!GEMINI_API_KEY) return json({ error: "no_gemini_key" }, 503);
      const r = await fetch(`${GEMINI_URL}?pageSize=200`, {
        headers: { "x-goog-api-key": GEMINI_API_KEY },
      });
      const j = await r.json();
      const names = (j?.models ?? [])
        .filter((m: { supportedGenerationMethods?: string[] }) =>
          m.supportedGenerationMethods?.includes("generateContent"))
        .map((m: { name?: string }) => m.name);
      return json({ status: r.status, models: names });
    }
    if (typeof path !== "string" || !path) {
      return json({ error: "missing_path" }, 400);
    }
    // Unknown kinds fall back to "defect" (the pre-registry behavior) so an
    // older client build can never brick extraction with a typo'd kind.
    const kindName = typeof kind === "string" && kind in KINDS ? kind : "defect";
    const kindDef = KINDS[kindName];

    if (isUnsupportedForExtraction(path)) {
      return json({ error: "extraction_unsupported_file_type" }, 415);
    }

    // Download the file bytes with the service role (bypasses RLS) via a
    // plain fetch to the Storage REST API. supabase-js is deliberately not
    // imported: its esm.sh bundle slowed cold boots and intermittently threw
    // an opaque TypeError ("Cannot read properties of undefined (reading
    // 'error')") from inside its own error handling, surfacing as a 500.
    const encodedPath = path.split("/").map(encodeURIComponent).join("/");
    let dlRes: Response;
    try {
      dlRes = await withTimeout(
        fetch(`${SUPABASE_URL}/storage/v1/object/attachments/${encodedPath}`, {
          headers: {
            authorization: `Bearer ${SERVICE_ROLE}`,
            apikey: SERVICE_ROLE,
          },
        }),
        20_000,
      );
    } catch (_) {
      return json({ error: "download_failed" }, 404);
    }
    if (!dlRes.ok) {
      return json({ error: "download_failed" }, 404);
    }
    const buf = new Uint8Array(await dlRes.arrayBuffer());

    const schema = kindDef.schema;
    const prompt = promptFor(kindDef);

    // `userContent` is a plain string (spreadsheet/docx/text — parsed to
    // text here), a content-parts array carrying the raw PDF for OpenRouter's
    // file-parser plugin, or image parts headed to a free vision model
    // (photos, and scanned PDFs where the parser would find no text).
    let userContent: string | Record<string, unknown>[];
    let plugins: Record<string, unknown>[] | undefined;
    let models = TEXT_MODELS;
    // Vision endpoints don't reliably support json_schema response_format.
    let useJsonSchema = true;
    // Gemini-native content parts. Gemini reads PDFs directly (scans
    // included), so its parts are simpler than the OpenRouter routing.
    let geminiParts: Record<string, unknown>[];

    const imageMime = IMAGE_MIMES[extOf(path)];
    if (buf.length > 15 * 1024 * 1024) {
      // Keep uploads under OpenRouter's payload comfort zone and the edge
      // runtime's memory/CPU budget.
      return json({ error: "file_too_large" }, 413);
    }
    const imageParts = (imgs: { mime: string; bytes: Uint8Array }[]) => [
      { type: "text", text: "Read the document in the image(s):" },
      ...imgs.map((img) => ({
        type: "image_url",
        image_url: { url: `data:${img.mime};base64,${toBase64(img.bytes)}` },
      })),
    ];

    if (isSpreadsheet(path)) {
      let text: string;
      try {
        text = `Spreadsheet content:\n\n${spreadsheetToText(buf)}`;
      } catch (_) {
        return json({ error: "parse_failed" }, 422);
      }
      userContent = text;
      geminiParts = [{ text }];
    } else if (isDocx(path)) {
      let text: string;
      try {
        text =
          `Document content:\n\n${(await docxToText(buf)).slice(0, 20_000)}`;
      } catch (_) {
        return json({ error: "parse_failed" }, 422);
      }
      userContent = text;
      geminiParts = [{ text }];
    } else if (imageMime) {
      userContent = imageParts([{ mime: imageMime, bytes: buf }]);
      models = VISION_MODELS;
      useJsonSchema = false;
      geminiParts = [
        { inline_data: { mime_type: imageMime, data: toBase64(buf) } },
      ];
    } else if (isPdf(path)) {
      geminiParts = [
        { inline_data: { mime_type: "application/pdf", data: toBase64(buf) } },
      ];
      const scanJpegs = pdfHasTextLayer(buf) ? [] : extractPdfJpegs(buf);
      if (scanJpegs.length > 0) {
        // A scan: no text layer, one JPEG per page. The text-based
        // file-parser returns nothing for these (measured on a real Safe
        // Manning certificate) — send the page images to a vision model.
        userContent = imageParts(
          scanJpegs.map((bytes) => ({ mime: "image/jpeg", bytes })),
        );
        models = VISION_MODELS;
        useJsonSchema = false;
      } else {
        userContent = [
          {
            type: "file",
            file: {
              filename: path.split("/").pop() ?? "document.pdf",
              file_data: `data:application/pdf;base64,${toBase64(buf)}`,
            },
          },
        ];
        plugins = [{ id: "file-parser", pdf: { engine: "cloudflare-ai" } }];
      }
    } else {
      const text = new TextDecoder().decode(buf).slice(0, 20_000);
      userContent = text;
      geminiParts = [{ text }];
    }

    // The client gives up at 150s, so the whole chain must answer before
    // then (Supabase edge requests also hard-cap at ~150s wall clock). Any
    // per-model failure (HTTP error, stall, unparseable output) falls
    // through to the next model; only a fully exhausted chain errors.
    const deadline = Date.now() + 135_000;
    let parsed: Record<string, unknown> | null = null;
    let modelUsed = "";
    let lastError = "ai_timeout";
    // Per-model failure log, returned on full-chain failure so a flaky
    // free-tier day is diagnosable from the client/dashboard alone.
    const attempts: { model: string; error: string; ms: number }[] = [];

    // --- Primary: Gemini (free, no card, high daily quota) when its key is
    // configured. Native JSON mode + native PDF/scan/image understanding.
    if (GEMINI_API_KEY) {
      for (const model of GEMINI_MODELS) {
        const remaining = deadline - Date.now();
        if (remaining < 15_000) break;
        const startedAt = Date.now();
        const logAttempt = (error: string) =>
          attempts.push({ model, error, ms: Date.now() - startedAt });
        let gRes: Response;
        try {
          gRes = await withTimeout(
            fetch(`${GEMINI_URL}/${model}:generateContent`, {
              method: "POST",
              headers: {
                "content-type": "application/json",
                "x-goog-api-key": GEMINI_API_KEY,
              },
              body: JSON.stringify({
                systemInstruction: { parts: [{ text: prompt }] },
                contents: [{ role: "user", parts: geminiParts }],
                generationConfig: {
                  responseMimeType: "application/json",
                  // Gemini 3.x are thinking models: reasoning tokens count
                  // against this cap, so 8192 truncated real answers into
                  // unparseable JSON. Keep it generous.
                  maxOutputTokens: 32768,
                },
              }),
            }),
            Math.min(70_000, remaining),
          );
        } catch (_) {
          lastError = "ai_timeout";
          logAttempt(lastError);
          continue;
        }
        if (!gRes.ok) {
          const detail = await gRes.text();
          lastError = `ai_failed_${gRes.status}_${detail.slice(0, 200)}`;
          logAttempt(lastError);
          continue;
        }
        let gj: {
          candidates?: {
            content?: { parts?: { text?: string; thought?: boolean }[] };
            finishReason?: string;
          }[];
        };
        try {
          gj = await withTimeout(
            gRes.json(),
            Math.min(60_000, deadline - Date.now()),
          );
        } catch (_) {
          lastError = "ai_timeout";
          logAttempt(lastError);
          continue;
        }
        // Skip thought parts (thinking models interleave them with the
        // answer) — only the real output is JSON.
        const text = (gj?.candidates?.[0]?.content?.parts ?? [])
          .filter((p) => !p.thought)
          .map((p) => p.text ?? "").join("");
        if (!text) {
          lastError = "ai_empty";
          logAttempt(lastError);
          continue;
        }
        const candidate = parseModelJson(text);
        if (candidate === null) {
          // Include finishReason + a snippet so truncation vs. junk output
          // is distinguishable straight from the attempts log.
          lastError = `parse_failed_${gj?.candidates?.[0]?.finishReason ?? ""}_${
            text.slice(0, 80)
          }`;
          logAttempt(lastError);
          continue;
        }
        if (!matchesSchema(kindDef, candidate)) {
          lastError = "schema_mismatch";
          logAttempt(lastError);
          continue;
        }
        parsed = candidate;
        modelUsed = model;
        break;
      }
    }

    // --- Fallback: OpenRouter free-model chain (or primary when no Gemini
    // key is configured).
    if (parsed === null) for (const model of models) {
      const remaining = deadline - Date.now();
      // Not enough time left for a meaningful attempt.
      if (remaining < 15_000) break;
      const startedAt = Date.now();
      const logAttempt = (error: string) =>
        attempts.push({ model, error, ms: Date.now() - startedAt });

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
              model,
              // Some free endpoints default to a small completion cap; a
              // 36-row parts list needs thousands of tokens and truncated
              // JSON fails to parse. Set the cap explicitly.
              max_tokens: 8192,
              ...(plugins ? { plugins } : {}),
              ...(useJsonSchema
                ? {
                  response_format: {
                    type: "json_schema",
                    json_schema: {
                      name: `${kindName}_extraction`,
                      schema,
                    },
                  },
                }
                : {}),
              messages: [
                { role: "system", content: prompt },
                { role: "user", content: userContent },
              ],
            }),
          }),
          // hy3 completes generation BEFORE response headers arrive (measured
          // 49-87s to first byte on real parts lists) — a tight per-attempt
          // cap silently kills its good answers, and rate-limited models
          // reject in <1s anyway, so a generous cap costs nothing.
          Math.min(80_000, remaining),
        );
      } catch (_) {
        lastError = "ai_timeout";
        logAttempt(lastError);
        continue;
      }

      if (!orRes.ok) {
        const detail = await orRes.text();
        // Account-level daily cap (50 free requests/day without credits):
        // every further free-model call today fails identically, so stop
        // walking the chain and tell the client plainly.
        if (detail.includes("free-models-per-day")) {
          lastError = "quota_exhausted";
          logAttempt(lastError);
          break;
        }
        lastError = `ai_failed_${orRes.status}_${detail.slice(0, 200)}`;
        logAttempt(lastError);
        continue;
      }

      // fetch() resolving only means headers arrived — the body (the actual
      // generation, when the response streams) needs its own bound. A real
      // 44-row parts list measured ~45s of generation on tencent/hy3.
      let dj: Record<string, unknown> & {
        choices?: { message?: { content?: string } }[];
      };
      try {
        dj = await withTimeout(
          orRes.json(),
          Math.min(60_000, deadline - Date.now()),
        );
      } catch (_) {
        lastError = "ai_timeout";
        logAttempt(lastError);
        continue;
      }

      const text = dj?.choices?.[0]?.message?.content ?? "";
      if (!text) {
        lastError = "ai_empty";
        logAttempt(lastError);
        continue;
      }
      const candidate = parseModelJson(text);
      if (candidate === null) {
        // finish_reason distinguishes truncation ("length") from garbage.
        const finish = (dj?.choices?.[0] as { finish_reason?: string })
          ?.finish_reason ?? "?";
        lastError = `parse_failed_${finish}`;
        logAttempt(lastError);
        continue;
      }
      if (!matchesSchema(kindDef, candidate)) {
        lastError = "schema_mismatch";
        logAttempt(lastError);
        continue;
      }
      parsed = candidate;
      modelUsed = model;
      break;
    }

    if (parsed === null) {
      const status = lastError === "ai_timeout"
        ? 504
        : lastError === "quota_exhausted"
        ? 429
        : 502;
      return json({ error: lastError, attempts }, status);
    }

    const data = kindDef.mode === "list"
      ? (Array.isArray(parsed?.items) ? parsed.items : [])
      : parsed;

    // attempts also rides along on success so a silently-failing primary
    // provider (e.g. a bad Gemini key masked by the OpenRouter fallback)
    // stays diagnosable from a single response.
    return json(
      { kind: kindName, mode: kindDef.mode, data, model: modelUsed, attempts },
    );
  } catch (e) {
    return json({ error: "unexpected", detail: String(e) }, 500);
  }
});
