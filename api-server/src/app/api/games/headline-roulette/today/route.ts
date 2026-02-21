import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function GET(request: Request) {
  const db = createServiceClient();
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get("userId");

  const today = new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });

  let { data: game, error } = await db
    .from("headline_roulette_games")
    .select("id, publish_date, headlines")
    .eq("publish_date", today)
    .single();

  if (error || !game) {
    const fallback = await db
      .from("headline_roulette_games")
      .select("id, publish_date, headlines")
      .order("publish_date", { ascending: false })
      .limit(1)
      .single();
    game = fallback.data;
  }

  if (!game) return NextResponse.json({ game: null });

  // Each headline needs an id for the Swift model
  const headlines = (game.headlines as { headline: string; insanityRank: number }[]).map((h, i) => ({
    id: `${game!.id}-${i}`,
    headline: h.headline,
    insanityRank: h.insanityRank,
  }));

  let played = false;
  let userScore = null;

  if (userId) {
    const { data: score } = await db
      .from("headline_roulette_scores")
      .select("score, max_score")
      .eq("user_id", userId)
      .eq("game_id", game.id)
      .single();
    if (score) {
      played = true;
      userScore = { score: score.score, maxScore: score.max_score };
    }
  }

  return NextResponse.json({
    game: {
      id: game.id,
      publishDate: game.publish_date,
      headlines,
      played,
      userScore,
    },
  });
}
