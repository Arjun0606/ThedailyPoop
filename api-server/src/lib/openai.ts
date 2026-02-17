import OpenAI from "openai";

// Lazy init — avoids build failure when env vars aren't set
let _openai: OpenAI | null = null;
function getClient(): OpenAI {
  if (!_openai) {
    _openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });
  }
  return _openai;
}

// gpt-5-mini: reasoning model for contextual challenges, roasts, prompts
export async function generateWithMini(
  systemPrompt: string,
  userPrompt: string
): Promise<string> {
  const response = await getClient().chat.completions.create({
    model: "gpt-5-mini",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userPrompt },
    ],
    max_completion_tokens: 4000,
  });
  return response.choices[0]?.message?.content ?? "";
}

// gpt-5.2: standard model for long-form creative writing (weekly recaps)
export async function generateWithPremium(
  systemPrompt: string,
  userPrompt: string
): Promise<string> {
  const response = await getClient().chat.completions.create({
    model: "gpt-5.2",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userPrompt },
    ],
    max_completion_tokens: 8000,
  });
  return response.choices[0]?.message?.content ?? "";
}
