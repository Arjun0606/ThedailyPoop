import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

interface SubmitBody {
  userId: string;
  gameId: string;
  answers: { headline: string; guessedReal: boolean }[];
}

export async function POST(request: Request) {
  const body: SubmitBody = await request.json();
  const { userId, gameId, answers } = body;

  if (!userId || !gameId || !answers?.length) {
    return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  }

  const db = createServiceClient();

  // Fetch the game with answers
  const { data: game, error: gameError } = await db
    .from("scoop_games")
    .select("id, headlines")
    .eq("id", gameId)
    .single();

  if (gameError || !game) {
    return NextResponse.json({ error: "Game not found" }, { status: 404 });
  }

  const realHeadlines = game.headlines as {
    headline: string;
    isReal: boolean;
    sourceStoryId: string | null;
  }[];

  // Build a lookup map
  const truthMap = new Map(
    realHeadlines.map((h) => [h.headline, h.isReal])
  );

  // Score the answers
  let correct = 0;
  const scoredAnswers = answers.map((a) => {
    const wasReal = truthMap.get(a.headline) ?? false;
    const isCorrect = a.guessedReal === wasReal;
    if (isCorrect) correct++;
    return {
      headline: a.headline,
      guessedReal: a.guessedReal,
      wasReal,
      correct: isCorrect,
    };
  });

  // Save score
  const { error: saveError } = await db.from("scoop_scores").insert({
    user_id: userId,
    game_id: gameId,
    score: correct,
    total: answers.length,
    answers: scoredAnswers,
  });

  if (saveError) {
    // Unique constraint = already played
    if (saveError.code === "23505") {
      return NextResponse.json(
        { error: "Already played this game" },
        { status: 409 }
      );
    }
    return NextResponse.json(
      { error: saveError.message },
      { status: 500 }
    );
  }

  return NextResponse.json({
    score: correct,
    total: answers.length,
    answers: scoredAnswers,
    // Reveal the truth for all headlines
    allHeadlines: realHeadlines.map((h) => ({
      headline: h.headline,
      isReal: h.isReal,
    })),
  });
}
