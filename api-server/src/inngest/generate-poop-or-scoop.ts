import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { generateWithMini } from "@/lib/openai";

function extractJSON(text: string): string {
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) return fenceMatch[1].trim();
  return text.trim();
}

function stripHeadlineLabels(headline: string): string {
  return headline
    .replace(/^(Fictional|Fake|Real|Made.?up|Fabricated)\s*[—–\-:]\s*/i, "")
    .replace(/^\d+[\.\)]\s*/, "")
    .trim();
}

// Generates a Poop or Scoop game after daily briefing is published
// Uses real headlines from today + AI-generated fake ones
export const generatePoopOrScoop = inngest.createFunction(
  { id: "generate-poop-or-scoop", name: "Generate Poop or Scoop Game" },
  { event: "briefing/published" },
  async ({ event, step }) => {
    const { briefingId, dropType, publishDate } = event.data;

    // Only generate once per briefing (morning event triggers it)
    if (dropType !== "morning") {
      return { skipped: true, reason: "Only generate on morning event" };
    }

    const db = createServiceClient();

    // Check if already exists
    const existing = await step.run("check-existing", async () => {
      const { data } = await db
        .from("scoop_games")
        .select("id")
        .eq("briefing_id", briefingId)
        .single();
      return data;
    });

    if (existing) {
      return { skipped: true, reason: "Scoop game already exists" };
    }

    // Step 1: Get 5 real headlines from today's briefing
    const realHeadlines = await step.run("fetch-real-headlines", async () => {
      const { data } = await db
        .from("stories")
        .select("id, headline")
        .eq("briefing_id", briefingId)
        .order("sort_order", { ascending: true })
        .limit(10);

      if (!data || data.length < 5) return data ?? [];

      // Pick 5 spread across the briefing for variety
      const picks = [0, 2, 4, 6, 8].map((i) => data[Math.min(i, data.length - 1)]);
      // Deduplicate
      const seen = new Set<string>();
      return picks.filter((p) => {
        if (seen.has(p.id)) return false;
        seen.add(p.id);
        return true;
      });
    });

    if (realHeadlines.length < 3) {
      return { error: "Not enough stories to generate scoop game" };
    }

    // Step 2: Generate 5 fake but believable headlines
    const fakeHeadlines = await step.run("generate-fake-headlines", async () => {
      const realList = realHeadlines.map((s) => s.headline).join("\n");

      const result = await generateWithMini(
        "You are a headline writer for a satirical news game called Poop or Scoop.",
        `Here are today's REAL news headlines:

${realList}

Generate exactly 5 FAKE but extremely believable news headlines. They should:
- Sound like real breaking news from WSJ, Reuters, or Bloomberg
- Be in similar style/tone to the real headlines above
- Cover similar topics (business, tech, politics, sports, culture)
- Include specific numbers, company names, or people to sound credible
- Be plausible but NOT actually true
- NOT be obviously satirical or absurd — they should genuinely fool people

CRITICAL: Return ONLY the headline text. Do NOT prefix with "Fictional", "Fake", "Real", or any label. Do NOT number them. Just the raw headline string as it would appear on a news site.

Return ONLY a JSON array of 5 strings. No other text.`
      );

      try {
        const parsed = JSON.parse(extractJSON(result));
        if (Array.isArray(parsed) && parsed.length >= 5) {
          return parsed.slice(0, 5).map((h: string) => stripHeadlineLabels(String(h)));
        }
      } catch {
        // fallback
      }

      // Fallback fake headlines
      return [
        "Federal Reserve Announces Emergency Rate Hike of 75 Basis Points",
        "Apple Acquires TikTok's US Operations for $50 Billion",
        "NASA Confirms Discovery of Microbial Life on Mars Surface",
        "Amazon Plans to Launch Physical Department Stores in 30 States",
        "Supreme Court Rules Social Media Companies Must Verify User Ages",
      ];
    });

    // Step 3: Combine, shuffle, and save
    const saved = await step.run("save-game", async () => {
      const headlines = [
        ...realHeadlines.map((s) => ({
          headline: s.headline,
          isReal: true,
          sourceStoryId: s.id,
        })),
        ...fakeHeadlines.map((h: string) => ({
          headline: h,
          isReal: false,
          sourceStoryId: null,
        })),
      ];

      // Fisher-Yates shuffle
      for (let i = headlines.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [headlines[i], headlines[j]] = [headlines[j], headlines[i]];
      }

      const { data, error } = await db
        .from("scoop_games")
        .insert({
          briefing_id: briefingId,
          publish_date: publishDate,
          headlines,
        })
        .select("id")
        .single();

      if (error) throw new Error(`Failed to save scoop game: ${error.message}`);
      return data;
    });

    return {
      success: true,
      gameId: saved.id,
      realCount: realHeadlines.length,
      fakeCount: fakeHeadlines.length,
    };
  }
);
