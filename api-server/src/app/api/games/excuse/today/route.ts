import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function GET(request: Request) {
  const db = createServiceClient();
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get("userId");

  const today = new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });

  let { data: game, error } = await db
    .from("excuse_games")
    .select("id, publish_date, rounds")
    .eq("publish_date", today)
    .single();

  if (error || !game) {
    const fallback = await db
      .from("excuse_games")
      .select("id, publish_date, rounds")
      .order("publish_date", { ascending: false })
      .limit(1)
      .single();
    game = fallback.data;
  }

  if (!game) return NextResponse.json({ game: null });

  // Map scenario → situation for Swift client, strip correctIndex
  const safeRounds = (game.rounds as { scenario: string; correctExcuse: string; options: string[] }[]).map((r) => ({
    situation: r.scenario,
    correctExcuse: r.correctExcuse,
    options: r.options,
  }));

  let played = false;
  let userScore = null;

  if (userId) {
    const { data: score } = await db
      .from("excuse_scores")
      .select("score, total")
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
      rounds: safeRounds,
      played,
      userScore,
    },
  });
}
