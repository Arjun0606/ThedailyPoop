import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";

// The Roast — Pick the day's most roastable story, users write one-liners, AI judges
// This just creates the daily prompt. User entries + AI judging happen via API routes.
export const generateRoast = inngest.createFunction(
  { id: "generate-roast", name: "Generate Daily Roast Prompt" },
  { event: "briefing/published" },
  async ({ event, step }) => {
    const { briefingId, dropType, publishDate } = event.data;
    if (dropType !== "morning") return { skipped: true };

    const db = createServiceClient();

    const existing = await step.run("check-existing", async () => {
      const { data } = await db
        .from("roast_prompts")
        .select("id")
        .eq("briefing_id", briefingId)
        .single();
      return data;
    });

    if (existing) return { skipped: true, reason: "Roast prompt already exists" };

    // Pick the most roastable story from today's briefing
    const roastStory = await step.run("pick-roast-story", async () => {
      const { data } = await db
        .from("stories")
        .select("headline, body, category")
        .eq("briefing_id", briefingId)
        .order("sort_order", { ascending: true })
        .limit(10);

      if (!data || data.length === 0) return null;

      // Pick stories about powerful people/institutions doing dumb things
      // Prioritize: politics, business, tech — they're the most roastable
      const priority = ["politics", "business", "tech", "sports", "culture"];
      const sorted = [...data].sort((a, b) => {
        const ai = priority.indexOf(a.category);
        const bi = priority.indexOf(b.category);
        return (ai === -1 ? 99 : ai) - (bi === -1 ? 99 : bi);
      });

      // Pick the first one that has a body long enough to be interesting
      const pick = sorted.find((s) => s.body.length > 200) ?? sorted[0];

      // Extract a short summary (first 2 paragraphs or 300 chars)
      const paragraphs = pick.body.split("\n\n").slice(0, 2).join("\n\n");
      const summary = paragraphs.length > 400 ? paragraphs.slice(0, 400) + "..." : paragraphs;

      return { headline: pick.headline, summary };
    });

    if (!roastStory) return { error: "No stories to roast" };

    const saved = await step.run("save-prompt", async () => {
      const { data, error } = await db
        .from("roast_prompts")
        .insert({
          briefing_id: briefingId,
          publish_date: publishDate,
          story_headline: roastStory.headline,
          story_summary: roastStory.summary,
        })
        .select("id")
        .single();
      if (error) throw new Error(`Failed to save roast prompt: ${error.message}`);
      return data;
    });

    return { success: true, promptId: saved.id, headline: roastStory.headline };
  }
);
