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
    "What are the top 7 business and finance stories happening RIGHT NOW that would make someone under 30 actually stop scrolling? I need stories with SPECIFIC numbers, names, and consequences. Think: shocking earnings misses with exact dollar amounts, CEO firings or scandals with quotes, massive layoffs with headcounts, housing/rent data that makes people angry, wild stock moves with percentages, crypto collapses or surges, billionaire moves that reveal how the system works. Include at least one story about how something directly affects regular people's money (rent, groceries, jobs, student loans). Prioritize US but include global stories that impact Americans. For each: title, 2-3 sentence summary with SPECIFIC NUMBERS AND NAMES, sourceUrl, sourceName. Return ONLY JSON array.",
  tech:
    "What are the top 7 technology stories happening RIGHT NOW that are blowing up or SHOULD be blowing up? I want: AI developments with real-world implications (not just announcements), big tech doing something sketchy or bold, data breaches or privacy scandals with how many people affected, product changes that piss people off or excite them, startup drama with real numbers, app bans or regulatory moves. Every story needs SPECIFIC details — user numbers, dollar amounts, dates. Not vague summaries. Prioritize stories a non-technical 22-year-old would care about. For each: title, 2-3 sentence summary with SPECIFIC DETAILS, sourceUrl, sourceName. Return ONLY JSON array.",
  politics:
    "What are the top 7 political stories happening RIGHT NOW that young Americans would actually argue about at dinner? I want: policy changes that directly affect paychecks/rent/healthcare/student loans with SPECIFIC numbers, political scandals with actual quotes or evidence, government spending that seems insane with dollar amounts, voting rights or civil liberties changes, international moves that will affect gas prices or the economy. Skip procedural stuff that only political nerds care about. Every story needs concrete details — bill names, vote counts, dollar figures. For each: title, 2-3 sentence summary with SPECIFIC DETAILS, sourceUrl, sourceName. Return ONLY JSON array.",
  sports:
    "What are the top 7 sports stories happening RIGHT NOW that even non-sports fans would find interesting? I want: record-breaking performances with stats, massive trades with contract dollar amounts, controversial moments with context, athlete stories that transcend sports, rivalry drama, betting or money angles that are wild. Prioritize NFL, NBA, MLB, NHL, college sports, Premier League, Champions League, F1, UFC, tennis — whatever is actually in season and generating buzz RIGHT NOW. Every story needs specific stats, scores, or dollar amounts. For each: title, 2-3 sentence summary with SPECIFIC STATS AND DETAILS, sourceUrl, sourceName. Return ONLY JSON array.",
  culture:
    "What are the top 7 culture, entertainment, and internet stories happening RIGHT NOW that are dominating group chats and social media? I want: celebrity drama with actual details not just rumors, viral moments with context for why they went viral, streaming/music/film news with numbers (viewership, sales, records broken), internet culture moments that reveal something about society, controversy that people are genuinely split on. Not just 'celebrity did a thing' — I want the WHY behind the virality. For each: title, 2-3 sentence summary with SPECIFIC DETAILS, sourceUrl, sourceName. Return ONLY JSON array.",
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
