// Perplexity API client for fetching trending news stories

interface RawStory {
  title: string;
  summary: string;
  sourceUrl: string;
  sourceName: string;
}

type Category = "business" | "tech" | "culture";

const CATEGORY_QUERIES: Record<Category, string> = {
  business:
    "What are the top 5 wildest, most important, or most talked-about business and finance stories happening RIGHT NOW? I want stories that would make a 22-year-old actually care about finance — think insane earnings numbers, CEO drama, massive layoffs, housing market chaos, wild stock moves, crypto drama, or billionaires doing billionaire things. Focus on US, UK, and Western Europe. For each story, provide the headline, a 2-3 sentence summary with specific numbers and details, the source publication name, and source URL. Return as JSON array with keys: title, summary, sourceUrl, sourceName.",
  tech: "What are the top 5 most interesting technology stories happening RIGHT NOW that would blow up on social media? I want AI breakthroughs, big tech drama, startup funding rounds, product launches that actually matter, cybersecurity incidents, or tech CEO controversies. Think stories that make people go 'wait that is actually insane'. Focus on US, UK, Europe, Australia. For each story, provide the headline, a 2-3 sentence summary with specific details, the source publication name, and source URL. Return as JSON array with keys: title, summary, sourceUrl, sourceName.",
  culture:
    "What are the top 5 most viral, controversial, or hilarious culture and entertainment stories happening RIGHT NOW? I want celebrity drama, sports chaos, viral TikTok moments, streaming wars, music industry beef, gaming news, or internet culture that is dominating the timeline. English-speaking Western audiences. For each story, provide the headline, a 2-3 sentence summary, the source publication name, and source URL. Return as JSON array with keys: title, summary, sourceUrl, sourceName.",
};

function extractJSON(text: string): string {
  // Strip markdown code fences if present
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) return fenceMatch[1].trim();
  return text.trim();
}

export async function fetchTrendingNews(
  category: Category
): Promise<RawStory[]> {
  const apiKey = process.env.PERPLEXITY_API_KEY;
  if (!apiKey) {
    console.error("⚠️ PERPLEXITY_API_KEY not set");
    return [];
  }

  const response = await fetch("https://api.perplexity.ai/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "sonar",
      messages: [
        {
          role: "system",
          content:
            'You are a news research assistant. Return ONLY a JSON array of objects with keys: title, summary, sourceUrl, sourceName. No other text.',
        },
        {
          role: "user",
          content: CATEGORY_QUERIES[category],
        },
      ],
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error(`❌ Perplexity API error for ${category}:`, error);
    return [];
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content ?? "";

  try {
    const parsed = JSON.parse(extractJSON(content));
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    console.error(`❌ Failed to parse Perplexity response for ${category}:`, content.substring(0, 200));
    return [];
  }
}

export async function fetchAllCategories(): Promise<
  { category: Category; stories: RawStory[] }[]
> {
  const categories: Category[] = ["business", "tech", "culture"];

  const results = await Promise.all(
    categories.map(async (category) => ({
      category,
      stories: await fetchTrendingNews(category),
    }))
  );

  return results;
}
