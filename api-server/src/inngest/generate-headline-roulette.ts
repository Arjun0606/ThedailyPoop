import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { generateWithMini } from "@/lib/openai";

function extractJSON(text: string): string {
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) return fenceMatch[1].trim();
  return text.trim();
}

// Headline Roulette — Rank 5 headlines from most to least insane. Compare your insanity meter.
export const generateHeadlineRoulette = inngest.createFunction(
  { id: "generate-headline-roulette", name: "Generate Headline Roulette Game" },
  { event: "briefing/published" },
  async ({ event, step }) => {
    const { briefingId, dropType, publishDate } = event.data;
    if (dropType !== "morning") return { skipped: true };

    const db = createServiceClient();

    const existing = await step.run("check-existing", async () => {
      const { data } = await db
        .from("headline_roulette_games")
        .select("id")
        .eq("briefing_id", briefingId)
        .single();
      return data;
    });

    if (existing) return { skipped: true, reason: "Game already exists" };

    // Get today's stories
    const stories = await step.run("fetch-stories", async () => {
      const { data } = await db
        .from("stories")
        .select("headline")
        .eq("briefing_id", briefingId)
        .order("sort_order", { ascending: true })
        .limit(10);
      return data ?? [];
    });

    if (stories.length < 5) return { error: "Not enough stories for Headline Roulette" };

    // Get AI to rank 5 headlines by "insanity level"
    const headlines = await step.run("rank-headlines", async () => {
      const headlineList = stories.map((s) => s.headline).join("\n");

      const result = await generateWithMini(
        `You are a judge for TheDailyPoop's "Headline Roulette" game. Your job is to pick the 5 most insane headlines from today and rank them by objective insanity level.`,
        `Here are today's headlines:

${headlineList}

Pick the 5 MOST INSANE headlines and rank them from 1 (most insane) to 5 (least insane, but still wild).

"Insanity" means: how absurd, shocking, hypocritical, or "bro what" is the underlying story? Not just the headline — what the headline REPRESENTS.

Ranking criteria:
- Rank 1: "This cannot be real" — genuinely jaw-dropping
- Rank 2: "I need to tell someone about this immediately"
- Rank 3: "This is peak [year]"
- Rank 4: "Classic. Absolutely classic."
- Rank 5: "Wild but somehow not even the craziest thing today"

Return JSON array of 5 objects, ordered by insanityRank (1 first):
[{"headline": "exact headline text", "insanityRank": 1}, ...]

ONLY the JSON array. No other text.`
      );

      try {
        const parsed = JSON.parse(extractJSON(result));
        if (Array.isArray(parsed) && parsed.length >= 5) return parsed.slice(0, 5);
      } catch {
        console.error("Headline Roulette parse failed");
      }

      // Fallback: pick first 5 stories, rank them in order
      return stories.slice(0, 5).map((s, i) => ({
        headline: s.headline,
        insanityRank: i + 1,
      }));
    });

    const saved = await step.run("save-game", async () => {
      // Shuffle the headlines for presentation (player has to re-order them)
      const shuffled = [...headlines];
      for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
      }

      const { data, error } = await db
        .from("headline_roulette_games")
        .insert({
          briefing_id: briefingId,
          publish_date: publishDate,
          headlines: shuffled,
        })
        .select("id")
        .single();
      if (error) throw new Error(`Failed to save Headline Roulette game: ${error.message}`);
      return data;
    });

    return { success: true, gameId: saved.id, headlineCount: headlines.length };
  }
);
