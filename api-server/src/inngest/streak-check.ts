import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUser } from "@/lib/push";

// Runs at midnight — update streaks based on story reads
export const streakCheck = inngest.createFunction(
  { id: "streak-check", name: "Daily Streak Check" },
  { cron: "0 0 * * *" },
  async ({ step }) => {
    const db = createServiceClient();

    // Find users who read at least 1 story yesterday
    const activeUserIds = await step.run("find-active-readers", async () => {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const { data: readers } = await db
        .from("user_reads")
        .select("user_id")
        .gte("read_at", yesterday.toISOString())
        .lt("read_at", today.toISOString());

      const activeSet = new Set<string>();
      readers?.forEach((r) => activeSet.add(r.user_id));
      return Array.from(activeSet);
    });

    // Increment streaks for active users
    const streaksUpdated = await step.run("update-streaks", async () => {
      let updated = 0;
      for (const userId of activeUserIds) {
        const { data: user } = await db
          .from("users")
          .select("streak_count, streak_last_active")
          .eq("id", userId)
          .single();

        if (!user) continue;

        const lastActive = user.streak_last_active
          ? new Date(user.streak_last_active)
          : null;
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);

        const isConsecutive =
          lastActive &&
          lastActive.toDateString() === yesterday.toDateString();

        const newStreak = isConsecutive ? (user.streak_count ?? 0) + 1 : 1;

        await db
          .from("users")
          .update({
            streak_count: newStreak,
            streak_last_active: new Date().toISOString().split("T")[0],
          })
          .eq("id", userId);

        // Celebrate milestone streaks
        if ([3, 7, 14, 30, 69, 100].includes(newStreak)) {
          await pushToUser(userId, {
            title:
              newStreak === 69 ? "nice." : `${newStreak}-day streak! 🔥`,
            body:
              newStreak === 69
                ? "nice streak. nice."
                : `You've read TheDailyPoop for ${newStreak} days straight. You're basically a news junkie now.`,
            data: { type: "streak_milestone" },
          });
        }

        updated++;
      }
      return updated;
    });

    // Notify at-risk streak users
    const atRisk = await step.run("notify-at-risk", async () => {
      const { data: usersWithStreaks } = await db
        .from("users")
        .select("id, streak_count, streak_last_active")
        .gt("streak_count", 2);

      if (!usersWithStreaks) return 0;

      let nudged = 0;
      for (const user of usersWithStreaks) {
        if (activeUserIds.includes(user.id)) continue;

        const lastActive = user.streak_last_active
          ? new Date(user.streak_last_active)
          : null;

        if (lastActive) {
          const daysSince = Math.floor(
            (Date.now() - lastActive.getTime()) / (24 * 60 * 60 * 1000)
          );

          if (daysSince === 1) {
            await pushToUser(user.id, {
              title: "Your streak is about to 💀",
              body: `${user.streak_count}-day streak dies at midnight. Read today's briefing to keep it alive.`,
              data: { type: "streak_warning" },
            });
            nudged++;
          }
        }
      }
      return nudged;
    });

    // Reset broken streaks
    const reset = await step.run("reset-broken-streaks", async () => {
      const twoDaysAgo = new Date();
      twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);

      const { data } = await db
        .from("users")
        .update({ streak_count: 0 })
        .lt("streak_last_active", twoDaysAgo.toISOString().split("T")[0])
        .gt("streak_count", 0)
        .select("id");

      return data?.length ?? 0;
    });

    return { streaksUpdated, atRiskNotified: atRisk, streaksReset: reset };
  }
);
