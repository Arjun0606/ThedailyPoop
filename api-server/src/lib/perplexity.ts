// Perplexity API client for fetching trending news stories

interface RawStory {
  title: string;
  summary: string;
  sourceUrl: string;
  sourceName: string;
}

type Category = "business" | "tech" | "politics" | "sports" | "culture";

const CATEGORY_QUERIES: Record<Category, string> = {
  business:
    "What are the top 6 wildest, most important, or most talked-about business and finance stories happening RIGHT NOW in the United States and globally? I want stories that would make a 22-year-old actually care about finance — think insane earnings numbers, CEO drama, massive layoffs, housing market chaos, wild stock moves, crypto drama, billionaires doing billionaire things, or major corporate moves. Prioritize US stories but include major global stories that affect American markets. For each story, provide the headline, a 2-3 sentence summary with specific numbers and details, the source publication name, and source URL. Return as JSON array with keys: title, summary, sourceUrl, sourceName.",
  tech: "What are the top 6 most interesting technology stories happening RIGHT NOW that would blow up on social media? I want AI breakthroughs, big tech drama, startup funding rounds, product launches that actually matter, cybersecurity incidents, or tech CEO controversies. Think stories that make people go 'wait that is actually insane'. Prioritize US and Silicon Valley stories but include major global tech news. For each story, provide the headline, a 2-3 sentence summary with specific details, the source publication name, and source URL. Return as JSON array with keys: title, summary, sourceUrl, sourceName.",
  politics:
    "What are the top 6 most important or wildest political stories happening RIGHT NOW that young Americans actually need to know about? I want major policy changes that affect jobs and money, election drama, geopolitical moves, government spending that is insane, political scandals, or laws being passed that will impact Gen Z directly. Prioritize US domestic politics and foreign policy, but include major global stories that affect Americans. For each story, provide the headline, a 2-3 sentence summary with specific details, the source publication name, and source URL. Return as JSON array with keys: title, summary, sourceUrl, sourceName.",
  sports:
    "What are the top 6 biggest or most dramatic sports stories happening RIGHT NOW? I want record-breaking performances, trade drama, rivalry games, controversial calls, athlete drama, major upsets, or stories where the money involved is insane. Prioritize American sports — NFL, NBA, MLB, NHL, MLS, college sports — but also include Premier League, Champions League, F1, UFC, and tennis majors when they're big. For each story, provide the headline, a 2-3 sentence summary with specific details, the source publication name, and source URL. Return as JSON array with keys: title, summary, sourceUrl, sourceName.",
  culture:
    "What are the top 6 most viral, controversial, or hilarious culture and entertainment stories happening RIGHT NOW in America? I want celebrity drama, viral TikTok moments, streaming wars, music industry beef, gaming news, movie/TV releases, or internet culture that is dominating the timeline. Focus on American pop culture and what's trending in the US. For each story, provide the headline, a 2-3 sentence summary, the source publication name, and source URL. Return as JSON array with keys: title, summary, sourceUrl, sourceName.",
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
    console.error("PERPLEXITY_API_KEY not set");
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
    console.error(`Perplexity API error for ${category}:`, error);
    return [];
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content ?? "";

  try {
    const parsed = JSON.parse(extractJSON(content));
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    console.error(`Failed to parse Perplexity response for ${category}:`, content.substring(0, 200));
    return [];
  }
}

export async function fetchAllCategories(): Promise<
  { category: Category; stories: RawStory[] }[]
> {
  const categories: Category[] = ["business", "tech", "politics", "sports", "culture"];

  const results = await Promise.all(
    categories.map(async (category) => ({
      category,
      stories: await fetchTrendingNews(category),
    }))
  );

  return results;
}
