import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { validateUserRequest } from "@/lib/user-auth";

export async function POST(request: NextRequest) {
  const body = await request.json();
  const { userId, gameId, ranking } = body as { userId: string; gameId: string; ranking: string[] };

  if (!userId || !gameId || !ranking?.length) {
    return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  }

  const auth = await validateUserRequest(request, userId);
  if (auth instanceof NextResponse) return auth;

  const db = createServiceClient();

  const { data: game, error: gameError } = await db
    .from("headline_roulette_games")
    .select("id, headlines")
    .eq("id", gameId)
    .single();

  if (gameError || !game) {
    return NextResponse.json({ error: "Game not found" }, { status: 404 });
  }

  const headlines = game.headlines as { headline: string; insanityRank: number }[];
  const maxScore = headlines.length * 5;

  // Build id-to-rank map (ranking array contains headline IDs in user's order)
  // User's ranking: index 0 = most insane, index 4 = least insane
  let score = 0;
  for (let userRank = 0; userRank < ranking.length; userRank++) {
    const headlineId = ranking[userRank];
    const idx = parseInt(headlineId.split("-").pop() ?? "0");
    const headline = headlines[idx];
    if (headline) {
      const correctRank = headline.insanityRank;
      const diff = Math.abs((userRank + 1) - correctRank);
      score += Math.max(0, 5 - diff);
    }
  }

  const { error: saveError } = await db.from("headline_roulette_scores").insert({
    user_id: userId,
    game_id: gameId,
    score,
    max_score: maxScore,
    ranking,
  });

  if (saveError) {
    if (saveError.code === "23505") {
      return NextResponse.json({ error: "Already played" }, { status: 409 });
    }
    return NextResponse.json({ error: saveError.message }, { status: 500 });
  }

  const correctOrder = [...headlines]
    .sort((a, b) => a.insanityRank - b.insanityRank)
    .map((h, i) => ({
      id: `${game.id}-${headlines.indexOf(h)}`,
      headline: h.headline,
      insanityRank: h.insanityRank,
    }));

  return NextResponse.json({ score, maxScore, correctOrder });
}
