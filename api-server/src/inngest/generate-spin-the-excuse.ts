import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { generateWithMini } from "@/lib/openai";

function extractJSON(text: string): string {
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) return fenceMatch[1].trim();
  return text.trim();
}

// Spin the Excuse — A company/politician did something bad. Pick the REAL PR excuse from 4 options.
// 5 rounds per game, uses today's news for maximum relevance
export const generateSpinTheExcuse = inngest.createFunction(
  { id: "generate-spin-the-excuse", name: "Generate Spin the Excuse Game" },
  { event: "briefing/published" },
  async ({ event, step }) => {
    const { briefingId, dropType, publishDate } = event.data;
    if (dropType !== "morning") return { skipped: true };

    const db = createServiceClient();

    const existing = await step.run("check-existing", async () => {
      const { data } = await db
        .from("excuse_games")
        .select("id")
        .eq("briefing_id", briefingId)
        .single();
      return data;
    });

    if (existing) return { skipped: true, reason: "Game already exists" };

    // Get today's stories for context
    const stories = await step.run("fetch-stories", async () => {
      const { data } = await db
        .from("stories")
        .select("headline, body")
        .eq("briefing_id", briefingId)
        .order("sort_order", { ascending: true })
        .limit(10);
      return data ?? [];
    });

    const rounds = await step.run("generate-rounds", async () => {
      const storyContext = stories.map((s) => s.headline).join("\n");

      const result = await generateWithMini(
        `You create quiz content for TheDailyPoop — a satirical news app. The game is "Spin the Excuse" where players guess the REAL PR excuse used by companies or politicians after they did something bad.`,
        `Generate 5 rounds for today's "Spin the Excuse" game.

Today's news context (use these for inspiration when possible):
${storyContext}

Each round has:
- "scenario": A brief description of something bad a company/politician actually did (1-2 sentences). Use real events — recent or classic. Be specific with names and numbers.
- "correctExcuse": The REAL PR statement/excuse they actually used (or very close paraphrase).
- "options": Array of exactly 4 excuses. One is real, three are fake but plausible. Shuffle the correct answer's position randomly.
- "correctIndex": The index (0-3) of the correct excuse in the options array.

RULES:
- Use REAL scenarios from real life. Not made up situations.
- The real excuse should be corporate-speak, political-speak, or legal-speak that's hilariously out of touch.
- Fake excuses should be equally plausible corporate BS — hard to distinguish from real ones.
- Mix companies and politicians. Include at least 1 tech company, 1 political figure.
- Scenarios should be specific enough that the player learns something.
- Try to use at least 1-2 scenarios from today's news if applicable.

Return JSON array of 5 objects:
[{"scenario": "...", "correctExcuse": "...", "options": ["excuse1", "excuse2", "excuse3", "excuse4"], "correctIndex": 0}]

ONLY the JSON array. No other text.`
      );

      try {
        const parsed = JSON.parse(extractJSON(result));
        if (Array.isArray(parsed) && parsed.length >= 5) return parsed.slice(0, 5);
      } catch {
        console.error("Spin the Excuse parse failed");
      }

      return [
        { scenario: "Boeing's door plug blew off a plane mid-flight.", correctExcuse: "We are committed to taking the necessary steps to ensure events like this cannot happen again.", options: ["We are committed to taking the necessary steps to ensure events like this cannot happen again.", "Our internal investigation found no systemic issues with our manufacturing process.", "The aircraft performed within acceptable safety parameters despite the incident.", "We have already implemented enhanced quality control measures at all facilities."], correctIndex: 0 },
        { scenario: "Facebook was caught allowing Cambridge Analytica to harvest 87 million users' data.", correctExcuse: "We have a responsibility to protect your data, and if we can't then we don't deserve to serve you.", options: ["We are conducting a thorough internal review of our data sharing practices.", "User privacy has always been our top priority and we take this matter seriously.", "We have a responsibility to protect your data, and if we can't then we don't deserve to serve you.", "The data was accessed in violation of our terms of service by a third party."], correctIndex: 2 },
        { scenario: "A tech company laid off 12,000 employees right before the holidays.", correctExcuse: "We are taking these actions to position the company for long-term success.", options: ["We are taking these actions to position the company for long-term success.", "This difficult but necessary restructuring will strengthen our core business.", "We deeply value every team member and this was not an easy decision.", "Market conditions require us to reallocate resources to strategic priorities."], correctIndex: 0 },
        { scenario: "An airline overbooked a flight and forcibly dragged a passenger off.", correctExcuse: "We apologize for having to re-accommodate these customers.", options: ["We apologize for having to re-accommodate these customers.", "Our crew followed standard operating procedures for oversold flights.", "We are reviewing our boarding policies to improve the customer experience.", "The passenger was asked multiple times to voluntarily deplane."], correctIndex: 0 },
        { scenario: "A social media platform's algorithm was caught promoting eating disorder content to teens.", correctExcuse: "We want to be clear that the well-being of our community is our top priority.", options: ["Our algorithms are designed to surface content that users find engaging.", "We want to be clear that the well-being of our community is our top priority.", "We have invested billions in safety tools and content moderation.", "We are committed to working with experts to address these complex challenges."], correctIndex: 1 },
      ];
    });

    const saved = await step.run("save-game", async () => {
      const { data, error } = await db
        .from("excuse_games")
        .insert({ briefing_id: briefingId, publish_date: publishDate, rounds })
        .select("id")
        .single();
      if (error) throw new Error(`Failed to save Excuse game: ${error.message}`);
      return data;
    });

    return { success: true, gameId: saved.id, roundCount: rounds.length };
  }
);
