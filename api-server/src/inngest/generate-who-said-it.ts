import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { generateWithMini } from "@/lib/openai";

function extractJSON(text: string): string {
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) return fenceMatch[1].trim();
  return text.trim();
}

// Who Said It? — Match wild quotes to: CEO, Dictator, Cult Leader, or Reality TV Star
// 5 rounds per game, daily fresh, never repeat
export const generateWhoSaidIt = inngest.createFunction(
  { id: "generate-who-said-it", name: "Generate Who Said It Game" },
  { event: "briefing/published" },
  async ({ event, step }) => {
    const { briefingId, dropType, publishDate } = event.data;
    if (dropType !== "morning") return { skipped: true };

    const db = createServiceClient();

    const existing = await step.run("check-existing", async () => {
      const { data } = await db
        .from("who_said_it_games")
        .select("id")
        .eq("briefing_id", briefingId)
        .single();
      return data;
    });

    if (existing) return { skipped: true, reason: "Game already exists" };

    const rounds = await step.run("generate-rounds", async () => {
      const result = await generateWithMini(
        `You create quiz content for TheDailyPoop — a satirical news app with dark humor. The game is "Who Said It?" where players guess whether a quote came from a CEO, Dictator, Cult Leader, or Reality TV Star.`,
        `Generate 5 rounds for today's "Who Said It?" game.

Each round has:
- A REAL quote that someone actually said (or very close paraphrase)
- The correct answer: one of "CEO", "Dictator", "Cult Leader", "Reality TV Star"
- The person who said it (for the reveal)
- 4 options always in this order: ["CEO", "Dictator", "Cult Leader", "Reality TV Star"]

RULES:
- Use REAL quotes from real people. Not made up.
- Pick quotes that are genuinely ambiguous — the kind where you could see ANY of the 4 categories saying it.
- Mix it up: at least 2 different correct categories across the 5 rounds.
- Quotes should be unhinged, dramatic, or absurd enough to be funny.
- Include the person's name in "attribution" for the reveal screen.
- Prioritize quotes that are funny or shocking, not well-known.
- CRITICAL: The "quote" field must contain ONLY the quote text. Do NOT include the speaker's name, attribution, category, round number, or any label in the quote field. The attribution goes ONLY in the "attribution" field.

Examples of great quotes:
- "I could stand in the middle of Fifth Avenue and shoot somebody" — that energy
- "I'm the king of debt. I love debt." — that energy
- "Sleep is the cousin of death" — that energy

Return JSON array of 5 objects:
[{"quote": "...", "correctAnswer": "CEO"|"Dictator"|"Cult Leader"|"Reality TV Star", "attribution": "Person Name, Context", "options": ["CEO","Dictator","Cult Leader","Reality TV Star"]}]

ONLY the JSON array. No other text.`
      );

      try {
        const parsed = JSON.parse(extractJSON(result));
        if (Array.isArray(parsed) && parsed.length >= 5) {
          return parsed.slice(0, 5).map((r: any) => ({
            ...r,
            // Strip any accidental attribution leak from the quote
            quote: r.quote
              ?.replace(/\s*[—–\-]\s*(said by|attributed to|by)\s+.*/i, "")
              ?.replace(/^\d+[\.\)]\s*/, "")
              ?.trim() ?? r.quote,
          }));
        }
      } catch {
        console.error("Who Said It parse failed");
      }

      // Fallback rounds
      return [
        { quote: "I could buy any country I want.", correctAnswer: "CEO", attribution: "Paraphrased tech founder", options: ["CEO", "Dictator", "Cult Leader", "Reality TV Star"] },
        { quote: "I alone can fix it.", correctAnswer: "Dictator", attribution: "Classic authoritarian energy", options: ["CEO", "Dictator", "Cult Leader", "Reality TV Star"] },
        { quote: "The universe chose me for this purpose.", correctAnswer: "Cult Leader", attribution: "Generic cult leader", options: ["CEO", "Dictator", "Cult Leader", "Reality TV Star"] },
        { quote: "I didn't come here to make friends.", correctAnswer: "Reality TV Star", attribution: "Every reality show ever", options: ["CEO", "Dictator", "Cult Leader", "Reality TV Star"] },
        { quote: "Move fast and break things.", correctAnswer: "CEO", attribution: "Mark Zuckerberg, Facebook", options: ["CEO", "Dictator", "Cult Leader", "Reality TV Star"] },
      ];
    });

    const saved = await step.run("save-game", async () => {
      const { data, error } = await db
        .from("who_said_it_games")
        .insert({ briefing_id: briefingId, publish_date: publishDate, rounds })
        .select("id")
        .single();
      if (error) throw new Error(`Failed to save Who Said It game: ${error.message}`);
      return data;
    });

    return { success: true, gameId: saved.id, roundCount: rounds.length };
  }
);
