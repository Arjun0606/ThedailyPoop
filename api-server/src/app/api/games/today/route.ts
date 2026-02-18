import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function GET(request: NextRequest) {
  const db = createServiceClient();

  // Use Eastern time for date consistency with briefing generation
  const today = new Date().toLocaleDateString("en-CA", {
    timeZone: "America/New_York",
  });

  // Get user ID from auth header if present
  const authHeader = request.headers.get("authorization");
  let userId: string | null = null;
  if (authHeader?.startsWith("Bearer ")) {
    const token = authHeader.slice(7);
    const {
      data: { user },
    } = await db.auth.getUser(token);
    userId = user?.id ?? null;
  }

  // Also accept userId from query param (for simple auth)
  if (!userId) {
    userId = request.nextUrl.searchParams.get("userId");
  }

  // Fetch today's games (exclude valid_words and key_word)
  const { data: games, error } = await db
    .from("word_games")
    .select(
      "id, briefing_id, drop_type, publish_date, letters, key_word, story_headline, story_id, created_at"
    )
    .eq("publish_date", today)
    .order("created_at", { ascending: true });

  if (error || !games?.length) {
    return NextResponse.json({ games: [] });
  }

  // Sanitize: hide key_word, expose keyWordLength
  const sanitized = games.map((g) => ({
    id: g.id,
    briefingId: g.briefing_id,
    dropType: g.drop_type,
    publishDate: g.publish_date,
    letters: g.letters,
    keyWordLength: g.key_word.length,
    storyHeadline: g.story_headline,
    storyId: g.story_id,
    played: false as boolean,
    userScore: null as {
      score: number;
      wordsFound: string[];
      wordCount: number;
      foundKeyWord: boolean;
    } | null,
  }));

  // If user is logged in, check which games they already played
  if (userId) {
    const gameIds = games.map((g) => g.id);
    const { data: scores } = await db
      .from("word_game_scores")
      .select("game_id, score, words_found, word_count, found_key_word")
      .eq("user_id", userId)
      .in("game_id", gameIds);

    if (scores) {
      const scoreMap = new Map(scores.map((s) => [s.game_id, s]));
      for (const game of sanitized) {
        const userScore = scoreMap.get(game.id);
        if (userScore) {
          game.played = true;
          game.userScore = {
            score: userScore.score,
            wordsFound: userScore.words_found,
            wordCount: userScore.word_count,
            foundKeyWord: userScore.found_key_word,
          };
        }
      }
    }
  }

  return NextResponse.json({ games: sanitized });
}
