import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

// Normalization: each game contributes 0–100 points to the daily total (max 400)
function normalizeScore(raw: number, game: string): number {
  switch (game) {
    case "scoop":    return Math.round((raw / 10) * 100);        // 0-10 → 0-100
    case "word":     return Math.round((Math.min(raw, 200) / 200) * 100); // 0-200+ → 0-100
    case "wsi":      return Math.round((raw / 5) * 100);         // 0-5 → 0-100
    case "excuse":   return Math.round((raw / 5) * 100);         // 0-5 → 0-100
    default:         return 0;
  }
}

export async function GET(request: NextRequest) {
  const db = createServiceClient();
  const { searchParams } = new URL(request.url);

  const date =
    searchParams.get("date") ??
    new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });

  // Find today's game IDs for each type (parallel queries)
  const [scoopGame, wordGame, wsiGame, excuseGame] =
    await Promise.all([
      db.from("scoop_games").select("id").eq("publish_date", date).maybeSingle(),
      db.from("word_games").select("id").eq("publish_date", date).eq("drop_type", "morning").maybeSingle(),
      db.from("who_said_it_games").select("id").eq("publish_date", date).maybeSingle(),
      db.from("excuse_games").select("id").eq("publish_date", date).maybeSingle(),
    ]);

  // Collect scores per user across all games
  const userScores = new Map<string, { total: number; gamesPlayed: number }>();

  const gameQueries: { gameId: string | null; table: string; game: string }[] = [
    { gameId: scoopGame.data?.id, table: "scoop_scores", game: "scoop" },
    { gameId: wordGame.data?.id, table: "word_game_scores", game: "word" },
    { gameId: wsiGame.data?.id, table: "who_said_it_scores", game: "wsi" },
    { gameId: excuseGame.data?.id, table: "excuse_scores", game: "excuse" },
  ];

  await Promise.all(
    gameQueries
      .filter((q) => q.gameId)
      .map(async ({ gameId, table, game }) => {
        const { data: scores } = await db
          .from(table)
          .select("user_id, score")
          .eq("game_id", gameId!);

        if (scores) {
          for (const s of scores) {
            const existing = userScores.get(s.user_id) ?? { total: 0, gamesPlayed: 0 };
            existing.total += normalizeScore(s.score, game);
            existing.gamesPlayed += 1;
            userScores.set(s.user_id, existing);
          }
        }
      })
  );

  if (userScores.size === 0) {
    return NextResponse.json({ leaderboard: [], gamesAvailable: gameQueries.filter((q) => q.gameId).length });
  }

  // Fetch user info
  const userIds = Array.from(userScores.keys());
  const { data: users } = await db
    .from("users")
    .select("id, username, display_name, avatar_url, is_premium")
    .in("id", userIds);

  const userMap = new Map((users ?? []).map((u) => [u.id, u]));

  // Build leaderboard — all users who played, sorted by total score
  const leaderboard = Array.from(userScores.entries())
    .map(([userId, scores]) => {
      const user = userMap.get(userId);
      if (!user) return null;
      return {
        username: user.username ?? "anonymous",
        displayName: user.display_name,
        avatarUrl: user.avatar_url,
        score: scores.total,
        gamesPlayed: scores.gamesPlayed,
        isPremium: user.is_premium ?? false,
      };
    })
    .filter(Boolean)
    .sort((a, b) => b!.score - a!.score)
    .slice(0, 50)
    .map((entry, index) => ({
      rank: index + 1,
      ...entry,
    }));

  return NextResponse.json({
    leaderboard,
    gamesAvailable: gameQueries.filter((q) => q.gameId).length,
  });
}
