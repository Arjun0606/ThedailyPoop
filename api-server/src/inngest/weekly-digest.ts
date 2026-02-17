import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUsers } from "@/lib/push";

// Runs every Sunday at 10:00 AM — sends weekly reading recap
export const weeklyDigest = inngest.createFunction(
  { id: "weekly-digest", name: "Weekly Digest Push" },
  { cron: "0 10 * * 0" }, // Sunday 10am UTC
  async ({ step }) => {
    const db = createServiceClient();

    // Get all users with device tokens
    const users = await step.run("get-users", async () => {
      const { data: tokens } = await db
        .from("device_tokens")
        .select("user_id");

      if (!tokens?.length) return [];

      const userIds = [...new Set(tokens.map((t) => t.user_id))];

      // Get user details + read counts for the week
      const oneWeekAgo = new Date(
        Date.now() - 7 * 24 * 60 * 60 * 1000
      ).toISOString();

      const results = [];
      for (const userId of userIds) {
        const { count } = await db
          .from("user_reads")
          .select("*", { count: "exact", head: true })
          .eq("user_id", userId)
          .gte("read_at", oneWeekAgo);

        const { data: user } = await db
          .from("users")
          .select("username, streak_count")
          .eq("id", userId)
          .single();

        results.push({
          userId,
          storiesRead: count ?? 0,
          streak: user?.streak_count ?? 0,
          username: user?.username ?? "",
        });
      }

      return results;
    });

    if (!users.length) {
      return { skipped: true, reason: "No users to notify" };
    }

    // Send personalized push to each user
    const sent = await step.run("send-digests", async () => {
      let count = 0;
      for (const user of users) {
        if (user.storiesRead === 0) continue;

        const body =
          user.streak > 0
            ? `You read ${user.storiesRead} stories this week. Streak: ${user.streak} days 🔥`
            : `You read ${user.storiesRead} stories this week. Start a streak tomorrow!`;

        try {
          await pushToUsers([user.userId], {
            title: "Your Weekly Poop Report 💩",
            body,
            data: { type: "weekly_digest" },
          });
          count++;
        } catch {
          // Skip failed pushes
        }
      }
      return count;
    });

    return { sent, totalUsers: users.length };
  }
);
