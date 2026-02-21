import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { generateWithMini } from "@/lib/openai";

function extractJSON(text: string): string {
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) return fenceMatch[1].trim();
  return text.trim();
}

// Predict the Poop — 3 daily predictions based on today's news. Users bet yes/no.
// Predictions resolve in 1-7 days. Accuracy tracked over time.
export const generatePredictions = inngest.createFunction(
  { id: "generate-predictions", name: "Generate Daily Predictions" },
  { event: "briefing/published" },
  async ({ event, step }) => {
    const { briefingId, dropType, publishDate } = event.data;
    if (dropType !== "morning") return { skipped: true };

    const db = createServiceClient();

    // Check if we already have predictions for today
    const existing = await step.run("check-existing", async () => {
      const { count } = await db
        .from("predictions")
        .select("id", { count: "exact", head: true })
        .eq("briefing_id", briefingId);
      return (count ?? 0) > 0;
    });

    if (existing) return { skipped: true, reason: "Predictions already exist" };

    // Get today's stories for context
    const stories = await step.run("fetch-stories", async () => {
      const { data } = await db
        .from("stories")
        .select("headline, body, category")
        .eq("briefing_id", briefingId)
        .order("sort_order", { ascending: true })
        .limit(10);
      return data ?? [];
    });

    const predictions = await step.run("generate-predictions", async () => {
      const storyContext = stories.map((s) => `[${s.category}] ${s.headline}`).join("\n");

      const result = await generateWithMini(
        `You create prediction questions for TheDailyPoop — a satirical news app with dark humor. "Predict the Poop" is a game where users bet on what will happen next based on today's news.`,
        `Based on today's news, generate 3 predictions for "Predict the Poop."

Today's stories:
${storyContext}

Each prediction should:
- Be a clear yes/no question about something that COULD realistically happen in the next 1-7 days
- Be directly related to one of today's stories
- Be specific enough to have a definitive answer (not vague)
- Be entertaining and slightly provocative in TheDailyPoop's voice
- Include brief context (1 sentence) explaining why this prediction matters

RULES:
- Questions should be genuinely uncertain — not obvious yes or obvious no
- Mix difficulty: 1 easy-ish, 1 medium, 1 spicy/bold
- Include a "resolve by" timeframe in days (1-7)
- Write questions in TheDailyPoop voice — slightly unhinged, specific, funny

Examples:
- "Will Elon tweet about this before midnight?" (1 day)
- "Will Congress actually pass this bill before Friday?" (3 days)
- "Will the stock drop below $100 this week?" (5 days)

Return JSON array of 3 objects:
[{"question": "Will X happen?", "context": "Brief context why this matters", "resolveDays": 1-7}]

ONLY the JSON array. No other text.`
      );

      try {
        const parsed = JSON.parse(extractJSON(result));
        if (Array.isArray(parsed) && parsed.length >= 3) return parsed.slice(0, 3);
      } catch {
        console.error("Predictions parse failed");
      }

      return [
        { question: "Will today's biggest story still be trending tomorrow?", context: "Testing the news cycle's attention span.", resolveDays: 1 },
        { question: "Will any CEO mentioned today issue a public apology this week?", context: "The PR machine is warming up.", resolveDays: 5 },
        { question: "Will Congress do literally anything productive this week?", context: "Spoiler alert: probably not.", resolveDays: 7 },
      ];
    });

    const saved = await step.run("save-predictions", async () => {
      const rows = predictions.map((p: { question: string; context: string; resolveDays: number }) => {
        const resolveDate = new Date(publishDate);
        resolveDate.setDate(resolveDate.getDate() + (p.resolveDays || 3));

        return {
          briefing_id: briefingId,
          publish_date: publishDate,
          question: p.question,
          context: p.context ?? null,
          resolve_by: resolveDate.toISOString().split("T")[0],
        };
      });

      const { data, error } = await db
        .from("predictions")
        .insert(rows)
        .select("id");
      if (error) throw new Error(`Failed to save predictions: ${error.message}`);
      return data;
    });

    return { success: true, predictionCount: saved.length };
  }
);
