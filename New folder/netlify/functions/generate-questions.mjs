export default async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  try {
    const { book, passage, count, difficulty, types } = await req.json();
    if (!process.env.OPENAI_API_KEY) return Response.json({ error: "AI is not configured. Add OPENAI_API_KEY in Netlify environment variables." }, { status: 503 });
    if (!passage || !Array.isArray(types) || !types.length) return Response.json({ error: "Provide a Bible passage and at least one question type." }, { status: 400 });
    const n = Math.max(1, Math.min(50, Number(count) || 10));
    const allowed = ["mcq","tf","short","essay","blank"].filter(t => types.includes(t));
    const prompt = `Create exactly ${n} accurate Bible quiz questions based on ${passage} in ${book}. Difficulty: ${difficulty}. Use only these formats: ${allowed.join(", ")}. Return JSON only with shape {"questions":[{"type":"mcq|tf|short|essay|blank","question":"...","options":["A","B","C","D"],"answer":"...","reference":"Book chapter:verse","points":1}]}. For mcq, give exactly four options and answer must exactly match one option. For tf, answer must be True or False. For short and blank, provide a concise expected answer. For essay, provide a marking-guide answer. Include a precise Scripture reference for each item. Avoid questions not supported by the passage. Do not fabricate quotations or references. Use a balanced distribution across requested types.`;
    const r = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: process.env.OPENAI_MODEL || "gpt-4o-mini", temperature: 0.4, response_format: { type: "json_object" }, messages: [{ role: "system", content: "You are a careful Bible quiz writer. Ground every question in the specified biblical passage. Return valid JSON only." }, { role: "user", content: prompt }] })
    });
    const data = await r.json();
    if (!r.ok) return Response.json({ error: data.error?.message || "AI provider request failed." }, { status: 502 });
    const parsed = JSON.parse(data.choices?.[0]?.message?.content || "{}");
    return Response.json({ questions: (parsed.questions || []).slice(0,n) });
  } catch (e) {
    return Response.json({ error: "Could not generate questions. Please check the request and try again." }, { status: 500 });
  }
};
