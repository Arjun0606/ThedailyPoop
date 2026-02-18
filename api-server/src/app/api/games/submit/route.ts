import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function POST(request: NextRequest) {
  const db = createServiceClient();

  let body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const { userId, gameId, wordsFound, timeRemaining } = body;

  if (!userId || !gameId || !Array.isArray(wordsFound)) {
    return NextResponse.json(
      { error: "Missing required fields: userId, gameId, wordsFound" },
      { status: 400 }
    );
  }

  // Check for duplicate submission
  const { data: existing } = await db
    .from("word_game_scores")
    .select("id")
    .eq("user_id", userId)
    .eq("game_id", gameId)
    .maybeSingle();

  if (existing) {
    return NextResponse.json(
      { error: "Already submitted for this game" },
      { status: 409 }
    );
  }

  // Fetch game data
  const { data: game } = await db
    .from("word_games")
    .select("valid_words, key_word")
    .eq("id", gameId)
    .single();

  if (!game) {
    return NextResponse.json({ error: "Game not found" }, { status: 404 });
  }

  const validWords: Record<string, number> = game.valid_words;
  const keyWord: string = game.key_word;

  // Validate and score
  const validatedWords: string[] = [];
  let score = 0;
  let foundKeyWord = false;
  const seen = new Set<string>();

  for (const word of wordsFound) {
    const w = word.toLowerCase().trim();
    if (seen.has(w) || w.length < 3) continue;
    seen.add(w);

    if (validWords[w] !== undefined) {
      validatedWords.push(w);
      score += validWords[w];

      if (w === keyWord) {
        foundKeyWord = true;
        score += 50;
      }
    }
  }

  // Save score
  const { error: insertError } = await db.from("word_game_scores").insert({
    user_id: userId,
    game_id: gameId,
    score,
    words_found: validatedWords,
    word_count: validatedWords.length,
    found_key_word: foundKeyWord,
    time_remaining: Math.max(0, Math.min(90, timeRemaining ?? 0)),
  });

  if (insertError) {
    return NextResponse.json({ error: insertError.message }, { status: 500 });
  }

  // Update user game streak
  const today = new Date().toLocaleDateString("en-CA", {
    timeZone: "America/New_York",
  });

  const { data: userData } = await db
    .from("users")
    .select("game_streak, game_streak_last_played, highest_word_score")
    .eq("id", userId)
    .single();

  if (userData) {
    const lastPlayed = userData.game_streak_last_played;
    const yesterday = new Date(Date.now() - 86400000)
      .toLocaleDateString("en-CA", { timeZone: "America/New_York" });

    let newStreak = 1;
    if (lastPlayed === yesterday) {
      newStreak = (userData.game_streak ?? 0) + 1;
    } else if (lastPlayed === today) {
      newStreak = userData.game_streak ?? 1;
    }

    await db
      .from("users")
      .update({
        game_streak: newStreak,
        game_streak_last_played: today,
        highest_word_score: Math.max(userData.highest_word_score ?? 0, score),
      })
      .eq("id", userId);
  }

  return NextResponse.json({
    score,
    wordCount: validatedWords.length,
    validatedWords,
    foundKeyWord,
    keyWord,
    totalPossibleWords: Object.keys(validWords).length,
    totalPossibleScore:
      Object.values(validWords).reduce((a, b) => a + b, 0) + 50,
  });
}
