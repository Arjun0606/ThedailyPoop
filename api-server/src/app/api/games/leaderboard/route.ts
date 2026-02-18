import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function GET(request: NextRequest) {
  const db = createServiceClient();
  const { searchParams } = new URL(request.url);

  const date =
    searchParams.get("date") ??
    new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });
  const dropType = searchParams.get("drop") ?? "morning";

  // Get game ID for this date + drop
  const { data: game } = await db
    .from("word_games")
    .select("id")
    .eq("publish_date", date)
    .eq("drop_type", dropType)
    .maybeSingle();

  if (!game) {
    return NextResponse.json({ leaderboard: [], gameId: null });
  }

  // Fetch top 50 scores — premium users only on public leaderboard
  const { data: scores } = await db
    .from("word_game_scores")
    .select(
      `
      score,
      word_count,
      found_key_word,
      played_at,
      user_id
    `
    )
    .eq("game_id", game.id)
    .order("score", { ascending: false })
    .limit(100);

  if (!scores?.length) {
    return NextResponse.json({ leaderboard: [], gameId: game.id });
  }

  // Fetch user info for these scores
  const userIds = scores.map((s) => s.user_id);
  const { data: users } = await db
    .from("users")
    .select("id, username, display_name, avatar_url, is_premium")
    .in("id", userIds);

  const userMap = new Map((users ?? []).map((u) => [u.id, u]));

  // Filter to premium users only, take top 50
  const leaderboard = scores
    .map((entry) => {
      const user = userMap.get(entry.user_id);
      if (!user?.is_premium) return null;
      return {
        username: user.username,
        displayName: user.display_name,
        avatarUrl: user.avatar_url,
        score: entry.score,
        wordCount: entry.word_count,
        foundKeyWord: entry.found_key_word,
        isPremium: true,
      };
    })
    .filter(Boolean)
    .slice(0, 50)
    .map((entry, index) => ({
      rank: index + 1,
      ...entry,
    }));

  return NextResponse.json({ leaderboard, gameId: game.id });
}
