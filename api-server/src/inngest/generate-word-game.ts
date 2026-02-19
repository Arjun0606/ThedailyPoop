import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { generateWithMini } from "@/lib/openai";
import { findAllValidWords, isGoodKeyWord } from "@/lib/word-list";

function extractJSON(text: string): string {
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) return fenceMatch[1].trim();
  return text.trim();
}

export const generateWordGame = inngest.createFunction(
  { id: "generate-word-game", name: "Generate Word Drop Game" },
  { event: "briefing/published" },
  async ({ event, step }) => {
    const { briefingId, dropType, publishDate } = event.data;
    const db = createServiceClient();

    // Step 1: Fetch a story headline — each drop uses a different story
    // morning=1st story, midday=2nd, evening=3rd for variety
    const sortOrder = dropType === "morning" ? 1 : dropType === "midday" ? 2 : 3;

    const topStory = await step.run("fetch-top-story", async () => {
      const { data } = await db
        .from("stories")
        .select("id, headline")
        .eq("briefing_id", briefingId)
        .eq("sort_order", sortOrder)
        .single();

      // Fallback to sort_order=1 if the preferred story doesn't exist
      if (!data) {
        const { data: fallback } = await db
          .from("stories")
          .select("id, headline")
          .eq("briefing_id", briefingId)
          .eq("sort_order", 1)
          .single();
        return fallback;
      }
      return data;
    });

    if (!topStory) {
      return { error: "No stories found for briefing" };
    }

    // Step 2: Extract key word from headline using AI
    const keyWordResult = await step.run("extract-key-word", async () => {
      const result = await generateWithMini(
        "You are a word game designer. Extract the best word from a news headline for an anagram-style word game.",
        `Headline: "${topStory.headline}"

Pick ONE word from this headline for a word game.

RULES:
- Must be 5-8 letters long
- Must be a common English word (no proper nouns, abbreviations, or obscure words)
- Should contain a good mix of consonants and vowels
- Prefer words that allow many smaller words to be formed from their letters
- Also provide 1-2 filler letters (common consonants or vowels not in the word) to add variety

Return ONLY a JSON object:
{"keyWord": "theword", "fillerLetters": ["s", "n"]}`
      );

      try {
        const parsed = JSON.parse(extractJSON(result));
        const word = parsed.keyWord?.toLowerCase().replace(/[^a-z]/g, "");
        const fillers = (parsed.fillerLetters ?? [])
          .map((l: string) => l.toLowerCase().replace(/[^a-z]/g, ""))
          .filter((l: string) => l.length === 1)
          .slice(0, 2);

        if (word && word.length >= 5 && word.length <= 8 && isGoodKeyWord(word)) {
          return { keyWord: word, fillerLetters: fillers };
        }
      } catch {
        // fall through to fallback
      }

      // Fallback: pick best valid word from headline (most sub-words)
      const candidates = topStory.headline
        .replace(/[^a-zA-Z\s]/g, "")
        .split(/\s+/)
        .filter((w: string) => w.length >= 5 && w.length <= 8)
        .map((w: string) => w.toLowerCase())
        .filter((w: string) => isGoodKeyWord(w));

      const fallback = candidates[0] ?? "trades";
      return { keyWord: fallback, fillerLetters: ["s", "e"] };
    });

    const keyWord = keyWordResult.keyWord;
    const fillerLetters: string[] = keyWordResult.fillerLetters;
    const allLetters = [...keyWord.split(""), ...fillerLetters];

    // Step 3: Pre-compute all valid words
    const validWordsMap = await step.run("compute-valid-words", async () => {
      const words = findAllValidWords(allLetters);

      // If too few words, add another filler letter and retry
      if (Object.keys(words).length < 10) {
        const extraLetters = [...allLetters, "e"];
        return findAllValidWords(extraLetters);
      }

      return words;
    });

    // Step 4: Save to DB
    const saved = await step.run("save-word-game", async () => {
      const { data, error } = await db
        .from("word_games")
        .insert({
          briefing_id: briefingId,
          drop_type: dropType,
          publish_date: publishDate,
          key_word: keyWord,
          letters: allLetters,
          valid_words: validWordsMap,
          story_headline: topStory.headline,
          story_id: topStory.id,
        })
        .select("id")
        .single();

      if (error) throw new Error(`Failed to save word game: ${error.message}`);
      return data;
    });

    return {
      success: true,
      gameId: saved.id,
      keyWord,
      letterCount: allLetters.length,
      validWordCount: Object.keys(validWordsMap).length,
    };
  }
);
