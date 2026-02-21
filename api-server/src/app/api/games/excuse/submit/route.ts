import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { validateUserRequest } from "@/lib/user-auth";

export async function POST(request: NextRequest) {
  const body = await request.json();
  const { userId, gameId, answers } = body as { userId: string; gameId: string; answers: string[] };

  if (!userId || !gameId || !answers?.length) {
    return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  }

  const auth = await validateUserRequest(request, userId);
  if (auth instanceof NextResponse) return auth;

  const db = createServiceClient();

  const { data: game, error: gameError } = await db
    .from("excuse_games")
    .select("id, rounds")
    .eq("id", gameId)
    .single();

  if (gameError || !game) {
    return NextResponse.json({ error: "Game not found" }, { status: 404 });
  }

  const rounds = game.rounds as { scenario: string; correctExcuse: string; options: string[] }[];

  let correct = 0;
  const results = rounds.map((round, i) => {
    const userAnswer = answers[i] ?? "";
    const isCorrect = userAnswer === round.correctExcuse;
    if (isCorrect) correct++;
    return {
      situation: round.scenario,
      correctExcuse: round.correctExcuse,
      userAnswer,
      correct: isCorrect,
    };
  });

  const { error: saveError } = await db.from("excuse_scores").insert({
    user_id: userId,
    game_id: gameId,
    score: correct,
    total: rounds.length,
    answers: results,
  });

  if (saveError) {
    if (saveError.code === "23505") {
      return NextResponse.json({ error: "Already played" }, { status: 409 });
    }
    return NextResponse.json({ error: saveError.message }, { status: 500 });
  }

  return NextResponse.json({ score: correct, total: rounds.length, results });
}
