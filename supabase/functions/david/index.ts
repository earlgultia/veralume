import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const key = Deno.env.get("GEMINI_API_KEY");
    if (!key) return json({ error: "David is not configured" }, 503);
    const { question, language = "English" } = await request.json();
    if (typeof question !== "string" || !question.trim() || question.length > 2000) {
      return json({ error: "A valid question is required" }, 400);
    }
    const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash-lite";
    const prompt = `You are David, Veralume's warm Bible study companion. Answer in ${language}.
Be accurate, concise, pastoral, and grounded in Scripture. Cite Bible references in plain text.
Never claim divine authority, replace clergy, or invent a verse. For crisis or self-harm language,
encourage immediate local emergency and trusted-person support. Question: ${question.trim()}`;
    const upstream = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`,
      { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }], generationConfig: { temperature: 0.35, maxOutputTokens: 700 } }) },
    );
    if (!upstream.ok) return json({ error: upstream.status === 429 ? "Rate limit reached" : "AI service unavailable" }, upstream.status === 429 ? 429 : 502);
    const result = await upstream.json();
    const answer = result?.candidates?.[0]?.content?.parts?.map((p: { text?: string }) => p.text ?? "").join("").trim();
    if (!answer) return json({ error: "Empty AI response" }, 502);
    return json({ answer });
  } catch (_) {
    return json({ error: "Unable to process request" }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "content-type": "application/json" } });
}
