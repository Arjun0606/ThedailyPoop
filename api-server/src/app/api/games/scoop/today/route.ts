import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function GET(request: Request) {
  const db = createServiceClient();
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get("userId");

  const today = new Date().toISOString().split("T")[0];

  const { data: game, error } = await db
    .from("scoop_games")
    .select("id, publish_date, headlines, created_at")
    .eq("publish_date", today)
    .single();

  if (error || !game) {
    return NextResponse.json({ game: null });
  }

  // Strip isReal and sourceStoryId from headlines (anti-cheat)
  const safeHeadlines = (game.headlines as { headline: string }[]).map(
    (h) => ({ headline: h.headline })
  );

  let played = false;
  let userScore = null;

  if (userId) {
    const { data: score } = await db
      .from("scoop_scores")
      .select("score, total, answers")
      .eq("user_id", userId)
      .eq("game_id", game.id)
      .single();

    if (score) {
      played = true;
      userScore = score;
    }
  }

  return NextResponse.json({
    game: {
      id: game.id,
      publishDate: game.publish_date,
      headlines: safeHeadlines,
      headlineCount: safeHeadlines.length,
      played,
      userScore,
    },
  });
}
