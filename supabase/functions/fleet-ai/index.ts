// Supabase Edge Function: `fleet-ai`
// ---------------------------------------------------------------------------
// Answers Technical Superintendent questions about the fleet — but only from
// a minimal, structured snapshot the signed-in client sends with the request
// (vessel health scores, risk severities/categories, short subjects, action
// counts). This function has NO database access of its own and no service
// role key: the client already reads under RLS, so the model can never see
// more than the user can.
//
// What is deliberately never in the context: crew personal data, costs,
// suppliers, record ids, attachments, free-form notes.
//
// The model summarizes and prioritizes; it does not decide. It is instructed
// to answer only from the provided snapshot and to say when something is not
// in it, so it cannot invent a certificate date or a defect that isn't there.
//
// Secrets: OPENROUTER_API_KEY (same key as `extract` / `assistant`).
// ---------------------------------------------------------------------------

const OPENROUTER_API_KEY = Deno.env.get("OPENROUTER_API_KEY") ?? "";

// Free models get delisted without warning, so walk a chain rather than
// pinning one. Free-only: hard project constraint.
const MODELS = [
  "nvidia/nemotron-3-super-120b-a12b:free",
  "nvidia/nemotron-3-nano-30b-a3b:free",
  "nvidia/nemotron-nano-9b-v2:free",
  "openai/gpt-oss-20b:free",
];
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

const SYSTEM_PROMPT = [
  "You are the fleet intelligence assistant for a marine Technical",
  "Superintendent managing offshore support vessels.",
  "",
  "You are given a JSON snapshot of the fleet: per-vessel health scores",
  "(0-100), detected risks with severity (critical/high/medium/low/info),",
  "category, rule name and a short subject, plus counts of open and overdue",
  "actions. This snapshot is your ONLY source of facts.",
  "",
  "Rules you must follow:",
  "1. Answer only from the snapshot. If something is not in it, say plainly",
  "   that the app does not have that information — never guess a date, a",
  "   cost, a certificate number or a technical cause.",
  "2. Never state a root cause for a defect. A repeated defect is a pattern",
  "   to review with the vessel, not a diagnosis.",
  "3. Prioritize: critical first, then high. Be specific about which vessel.",
  "4. Be concise and operational — short sentences, a numbered list when the",
  "   user asks what to do. You are advising a professional.",
  "5. Recommendations are proposals for a human to approve; never imply an",
  "   action has been taken, approved or closed.",
  "6. Answer in the same language the user writes in.",
].join("\n");

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

// Best-effort per-user throttle; resets on cold start. The real backstop is
// OpenRouter's own free-tier limit — this just stops one chatty client from
// starving the rest while the isolate is warm.
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 6;
const usage = new Map<string, number[]>();

function throttled(userId: string): boolean {
  const now = Date.now();
  const hits = (usage.get(userId) ?? []).filter((t) => now - t < WINDOW_MS);
  hits.push(now);
  usage.set(userId, hits);
  return hits.length > MAX_PER_WINDOW;
}

const MAX_MESSAGES = 12;
const MAX_CHARS = 1200;
const MAX_CONTEXT_CHARS = 24_000;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    if (!OPENROUTER_API_KEY) {
      return json({ error: "not_configured" }, 503);
    }

    const authHeader = req.headers.get("authorization") ?? "";
    if (throttled(authHeader || "anonymous")) {
      return json({ error: "rate_limited" }, 429);
    }

    const { messages, context } = await req.json();
    if (!Array.isArray(messages) || messages.length === 0) {
      return json({ error: "missing_messages" }, 400);
    }
    if (!context || typeof context !== "object") {
      return json({ error: "missing_context" }, 400);
    }

    const snapshot = JSON.stringify(context);
    if (snapshot.length > MAX_CONTEXT_CHARS) {
      return json({ error: "context_too_large" }, 413);
    }

    const trimmed = messages.slice(-MAX_MESSAGES).map((m) => ({
      role: m?.role === "assistant" ? "assistant" : "user",
      content: String(m?.content ?? "").slice(0, MAX_CHARS),
    }));

    const payload = [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "system", content: `FLEET SNAPSHOT (JSON):\n${snapshot}` },
      ...trimmed,
    ];

    let sawRateLimit = false;
    let lastFail = "";
    for (const model of MODELS) {
      const orRes = await fetch(OPENROUTER_URL, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "authorization": `Bearer ${OPENROUTER_API_KEY}`,
        },
        body: JSON.stringify({ model, messages: payload, max_tokens: 700 }),
      });

      if (orRes.status === 429) {
        sawRateLimit = true;
        await orRes.body?.cancel();
        continue;
      }
      if (!orRes.ok) {
        const detail = await orRes.text();
        lastFail = `ai_failed_${orRes.status}_${detail.slice(0, 200)}`;
        continue;
      }

      const dj = await orRes.json();
      const text = dj?.choices?.[0]?.message?.content;
      if (!text) {
        lastFail = "empty_reply";
        continue;
      }
      return json({ text });
    }

    if (sawRateLimit && !lastFail) {
      return json({ error: "rate_limited" }, 429);
    }
    return json({ error: lastFail || "ai_failed" }, 502);
  } catch (e) {
    return json({ error: "unexpected", detail: String(e) }, 500);
  }
});
