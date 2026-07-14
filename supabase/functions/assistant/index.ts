// Supabase Edge Function: `assistant`
// ---------------------------------------------------------------------------
// Help-only chat assistant for the Maridive Fleet app, backed by Groq's
// free-tier LLM API (same key as the `extract` function). Answers "how do
// I..." questions about using the app. Never receives vessel data, crew PII,
// or any fleet records — only the user's typed messages and a static system
// prompt. Chat history is session-only on the client; nothing is persisted
// here.
//
// Secrets required (same key as `extract`, set once, no credit card needed):
//   supabase secrets set GROQ_API_KEY=your_key_from_console.groq.com
// ---------------------------------------------------------------------------

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") ?? "";
const MODEL = "llama-3.3-70b-versatile";
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

const SYSTEM_PROMPT =
  "You are the Maridive Fleet Vessels app assistant. You help crew and shore " +
  "staff use the app: logging tank readings, raising defects and " +
  "requisitions, managing port call logistics and port arrival " +
  "requirements, crew lists, certifications, daily tasks, notifications, and " +
  "exporting reports. Be concise and practical, using short steps. You have " +
  "no access to this fleet's actual data (no vessel names, readings, crew, " +
  "or files) — never claim to look anything up or invent specific figures. " +
  "If asked something outside how-to-use-the-app guidance, say briefly that " +
  "you can only help with using the app. Answer in the same language the " +
  "user writes in.";

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

// Best-effort per-user throttle. State lives in the isolate's memory, so it
// resets on cold start — the real backstop is Groq's own free-tier rate
// limit, this just keeps one chatty user from starving everyone else while
// the isolate is warm. No database table needed.
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 8;
const usage = new Map<string, number[]>();

function throttled(userId: string): boolean {
  const now = Date.now();
  const hits = (usage.get(userId) ?? []).filter((t) => now - t < WINDOW_MS);
  hits.push(now);
  usage.set(userId, hits);
  return hits.length > MAX_PER_WINDOW;
}

const MAX_MESSAGES = 20;
const MAX_CHARS = 2000;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    if (!GROQ_API_KEY) {
      return json({ error: "not_configured" }, 503);
    }

    const authHeader = req.headers.get("authorization") ?? "";
    const userId = authHeader || "anonymous";
    if (throttled(userId)) {
      return json({ error: "rate_limited" }, 429);
    }

    const { messages } = await req.json();
    if (!Array.isArray(messages) || messages.length === 0) {
      return json({ error: "missing_messages" }, 400);
    }

    const trimmed = messages.slice(-MAX_MESSAGES).map((m) => ({
      role: m?.role === "assistant" ? "assistant" : "user",
      content: String(m?.content ?? "").slice(0, MAX_CHARS),
    }));

    const groqRes = await fetch(GROQ_URL, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "authorization": `Bearer ${GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: MODEL,
        messages: [{ role: "system", content: SYSTEM_PROMPT }, ...trimmed],
        max_tokens: 512,
      }),
    });

    if (groqRes.status === 429) {
      return json({ error: "rate_limited" }, 429);
    }
    if (!groqRes.ok) {
      const detail = await groqRes.text();
      return json({ error: `ai_failed_${groqRes.status}_${detail.slice(0, 400)}` }, 502);
    }

    const gj = await groqRes.json();
    const text = gj?.choices?.[0]?.message?.content;
    if (!text) {
      return json({ error: "empty_reply" }, 502);
    }

    return json({ text });
  } catch (e) {
    return json({ error: "unexpected", detail: String(e) }, 500);
  }
});
