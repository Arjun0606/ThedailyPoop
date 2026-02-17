import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { fetchAllCategories } from "@/lib/perplexity";
import { generateWithPremium, generateWithMini } from "@/lib/openai";

const STYLE_GUIDE = `You are the voice of TheDailyPoop — a daily news briefing that covers business, tech, and culture with the irreverence of a group chat and the depth of actual journalism.

Rules:
- Write like you're explaining the news to your smartest, funniest friend
- Lead with the "why should I care" angle, not the "what happened" angle
- Use analogies that a 25-year-old would get
- Be funny but NEVER sacrifice accuracy for a joke
- Swear sparingly but effectively (like seasoning)
- End each story with "The Bottom Line:" — a memorable one-liner
- Reference pop culture, memes, and internet culture naturally
- Call out corporate BS directly — don't both-sides everything
- Keep paragraphs SHORT (2-3 sentences max)`;

function extractJSON(text: string): string {
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) return fenceMatch[1].trim();
  return text.trim();
}

// Runs at 5:00 AM ET — generates the daily briefing
export const generateDailyBriefing = inngest.createFunction(
  { id: "generate-daily-briefing", name: "Generate Daily Briefing" },
  { cron: "0 5 * * *" }, // 5:00 AM UTC (adjust for ET as needed)
  async ({ step }) => {
    const db = createServiceClient();
    const today = new Date().toISOString().split("T")[0];

    // Check if briefing already exists for today
    const existing = await step.run("check-existing", async () => {
      const { data } = await db
        .from("briefings")
        .select("id")
        .eq("publish_date", today)
        .single();
      return data;
    });

    if (existing) {
      return { skipped: true, reason: "Briefing already exists for today" };
    }

    // Step 1: Fetch trending news from Perplexity
    const rawStories = await step.run("fetch-news", async () => {
      const results = await fetchAllCategories();
      return results;
    });

    const allStories = rawStories.flatMap((r) =>
      r.stories.map((s) => ({ ...s, category: r.category }))
    );

    if (allStories.length === 0) {
      return { error: "No stories fetched from Perplexity" };
    }

    // Step 2: Curate & rank top 10 stories
    const curatedStories = await step.run("curate-stories", async () => {
      const storiesJson = JSON.stringify(allStories, null, 2);

      const result = await generateWithPremium(
        `You are a news editor for TheDailyPoop. Select and rank the top 10 most interesting stories from the raw feed below. Prioritize stories with the highest "holy shit factor" — things people will actually want to talk about.

Return a JSON array of exactly 10 objects with these keys:
- title: original headline
- summary: original summary
- sourceUrl: original source URL
- sourceName: source publication
- category: "business" | "tech" | "culture"
- rank: 1-10 (1 = most interesting)

Stories ranked 1-3 will be free for all users. Stories 4-10 are premium.
Mix categories — aim for roughly 3-4 business, 3-4 tech, 2-3 culture.
Return ONLY the JSON array, no other text.`,
        `Here are today's raw stories:\n\n${storiesJson}`
      );

      try {
        return JSON.parse(extractJSON(result));
      } catch {
        console.error("Failed to parse curation result:", result.substring(0, 300));
        // Fallback: use first 10 raw stories
        return allStories.slice(0, 10).map((s, i) => ({
          ...s,
          rank: i + 1,
        }));
      }
    });

    // Step 3: Rewrite each story in TheDailyPoop voice
    const rewrittenStories = await step.run("rewrite-stories", async () => {
      const results = [];

      for (let i = 0; i < Math.min(curatedStories.length, 10); i++) {
        const story = curatedStories[i];
        const categoryEmoji =
          story.category === "business"
            ? "💰"
            : story.category === "tech"
            ? "📱"
            : "🎬";

        const result = await generateWithPremium(
          STYLE_GUIDE,
          `Rewrite this news story in TheDailyPoop voice. Return ONLY a JSON object with these keys:
- headline: a punchy, funny headline (max 80 chars)
- body: the full story rewrite (200-400 words)
- tldr: a single sentence summary

Original story:
Title: ${story.title}
Summary: ${story.summary}
Source: ${story.sourceName}

Remember: Be funny but accurate. End with "The Bottom Line:" one-liner. Return ONLY JSON, no other text.`
        );

        try {
          const parsed = JSON.parse(extractJSON(result));
          results.push({
            sortOrder: i + 1,
            isFree: i < 3,
            category: story.category,
            headline: parsed.headline ?? story.title,
            body: parsed.body ?? story.summary,
            tldr: parsed.tldr ?? null,
            sourceUrl: story.sourceUrl ?? null,
            sourceName: story.sourceName ?? null,
            emoji: categoryEmoji,
          });
        } catch {
          // Fallback: use raw story
          results.push({
            sortOrder: i + 1,
            isFree: i < 3,
            category: story.category,
            headline: story.title,
            body: story.summary,
            tldr: null,
            sourceUrl: story.sourceUrl ?? null,
            sourceName: story.sourceName ?? null,
            emoji: categoryEmoji,
          });
        }
      }

      return results;
    });

    // Step 4: Generate briefing headline + intro
    const briefingMeta = await step.run("generate-headline", async () => {
      const storyHeadlines = rewrittenStories
        .map((s) => `${s.emoji} ${s.headline}`)
        .join("\n");

      const result = await generateWithMini(
        STYLE_GUIDE,
        `Based on today's top stories, write a briefing headline and intro for TheDailyPoop.

Today's stories:
${storyHeadlines}

Return ONLY a JSON object with:
- headline: a punchy, funny headline that ties the day's themes together (max 60 chars)
- introText: a 2-3 sentence hook that makes people want to read (conversational, funny)

Return ONLY JSON, no other text.`
      );

      try {
        return JSON.parse(extractJSON(result));
      } catch {
        return {
          headline: "Your Daily Scoop Is Here",
          introText:
            "Another day, another pile of news. Here's what matters.",
        };
      }
    });

    // Step 5: Save everything to Supabase
    const saved = await step.run("save-to-db", async () => {
      // Insert briefing
      const { data: briefing, error: briefingError } = await db
        .from("briefings")
        .insert({
          publish_date: today,
          headline: briefingMeta.headline,
          intro_text: briefingMeta.introText,
          story_count: rewrittenStories.length,
          free_story_count: rewrittenStories.filter((s) => s.isFree).length,
          status: "published",
          published_at: new Date().toISOString(),
        })
        .select("id")
        .single();

      if (briefingError || !briefing) {
        throw new Error(
          `Failed to insert briefing: ${briefingError?.message}`
        );
      }

      // Insert stories
      const storyRows = rewrittenStories.map((s) => ({
        briefing_id: briefing.id,
        sort_order: s.sortOrder,
        is_free: s.isFree,
        category: s.category,
        headline: s.headline,
        body: s.body,
        tldr: s.tldr,
        source_url: s.sourceUrl,
        source_name: s.sourceName,
        emoji: s.emoji,
      }));

      const { error: storiesError } = await db
        .from("stories")
        .insert(storyRows);

      if (storiesError) {
        throw new Error(
          `Failed to insert stories: ${storiesError.message}`
        );
      }

      return { briefingId: briefing.id, storyCount: storyRows.length };
    });

    return {
      success: true,
      briefingId: saved.briefingId,
      storyCount: saved.storyCount,
      headline: briefingMeta.headline,
    };
  }
);
