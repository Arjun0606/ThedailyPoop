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
    "Top 7 business/finance stories RIGHT NOW that make someone under 30 stop scrolling. Shocking earnings with dollar amounts, CEO scandals with quotes, layoffs with headcounts, housing/rent data, wild stock moves with %, crypto swings, billionaire moves. Include one story affecting regular people's money. Prioritize US, include global if it impacts Americans.",
  tech:
    "Top 7 tech stories RIGHT NOW blowing up or should be. AI with real-world impact, big tech doing something sketchy, data breaches with user counts, product changes that anger/excite people, startup drama with numbers, app bans or regulatory moves. Stories a non-technical 22-year-old would care about.",
  politics:
    "Top 7 political stories RIGHT NOW young Americans would argue about at dinner. Policy changes affecting paychecks/rent/healthcare/student loans with numbers, scandals with quotes, insane government spending with dollar amounts, voting rights changes, international moves affecting gas/economy. Skip procedural stuff.",
  sports:
    "Top 7 sports stories RIGHT NOW even non-sports fans find interesting. Record-breaking performances with stats, massive trades with contract $, controversial moments, athlete stories transcending sports, rivalry drama, wild betting angles. Cover whatever's in season: NFL, NBA, MLB, NHL, college, Premier League, F1, UFC.",
  culture:
    "Top 7 culture/entertainment/internet stories RIGHT NOW dominating group chats. Celebrity drama with real details, viral moments with WHY context, streaming/music/film numbers (viewership, sales, records), internet culture revealing something about society, controversies people are genuinely split on.",
};

const SYSTEM_PROMPT = `You are a news research assistant. Find stories with SPECIFIC numbers, names, dates, and consequences — no vague summaries.

Return ONLY a JSON array of exactly 7 objects:
[{"title": "...", "summary": "2-3 sentences with SPECIFIC details", "sourceUrl": "...", "sourceName": "..."}]

No other text.`;

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
          content: SYSTEM_PROMPT,
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
