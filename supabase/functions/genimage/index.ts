// Generates a single AI image from a text prompt via Gemini's image model.
// Used for fleet profile imagery (synthetic, never for evidence photos).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const MODEL_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }
  const { prompt } = await req.json().catch(() => ({}));
  if (typeof prompt !== "string" || prompt.length < 3 || prompt.length > 2000) {
    return Response.json({ error: "bad_request" }, { status: 400 });
  }
  if (!GEMINI_KEY) {
    return Response.json({ error: "not_configured" }, { status: 500 });
  }

  const res = await fetch(MODEL_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": GEMINI_KEY,
    },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: {
        responseModalities: ["IMAGE"],
        imageConfig: { aspectRatio: "16:9" },
      },
    }),
  });
  const body = await res.text();
  if (!res.ok) {
    return Response.json(
      { error: "upstream", detail: body.slice(0, 500) },
      { status: 502 },
    );
  }
  const json = JSON.parse(body);
  const part = (json.candidates?.[0]?.content?.parts ?? []).find(
    (p: { inlineData?: { mimeType: string; data: string } }) => p.inlineData,
  );
  if (!part) {
    return Response.json(
      { error: "no_image", detail: body.slice(0, 300) },
      { status: 502 },
    );
  }
  return Response.json({
    mime: part.inlineData.mimeType,
    image: part.inlineData.data,
  });
});
