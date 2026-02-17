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
    "What are the top 4 most important business and finance news stories today that would matter to professionals in the US, UK, and Western Europe? Include major market moves, corporate deals, and economic policy. For each, give the headline, a 2-3 sentence summary, the source publication name, and source URL. Return as JSON array.",
  tech: "What are the top 4 most important technology and startup news stories today relevant to audiences in the US, UK, Europe, and Australia? Include AI, big tech, startups, and product launches. For each, give the headline, a 2-3 sentence summary, the source publication name, and source URL. Return as JSON array.",
  culture:
    "What are the top 4 most interesting culture, entertainment, and internet news stories today relevant to English-speaking audiences in Western countries? Include pop culture, social media trends, sports, and viral moments. For each, give the headline, a 2-3 sentence summary, the source publication name, and source URL. Return as JSON array.",
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
