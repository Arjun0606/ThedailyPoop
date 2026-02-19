import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUsers } from "@/lib/push";

const MIDDAY_TITLES = [
  "Word Drop #2 just unlocked 🎯",
  "lunchtime brain break: Word Drop is live 💩",
  "new Word Drop puzzle waiting for you 🔥",
  "midday Word Drop: beat your morning score 💩",
  "your afternoon game just dropped 🎯💩",
  "Word Drop round 2 — let's go 🔥",
  "lunch break + Word Drop = perfect combo 💩",
  "new puzzle, new words, new score 🎯",
];

function getRandomTitle(): string {
  return MIDDAY_TITLES[Math.floor(Math.random() * MIDDAY_TITLES.length)];
}

// Runs at 12 PM ET (5 PM UTC) — notifies about midday Word Drop unlock
export const middayPush = inngest.createFunction(
  { id: "midday-push", name: "Midday Word Drop Push" },
  { cron: "0 17 * * *" }, // 5 PM UTC = 12 PM ET
  async ({ step }) => {
    const db = createServiceClient();
    const today = new Date().toISOString().split("T")[0];

    // Check that today's midday game exists
    const game = await step.run("check-game", async () => {
      const { data } = await db
        .from("word_games")
        .select("id")
        .eq("publish_date", today)
        .eq("drop_type", "midday")
        .single();
      return data;
    });

    if (!game) {
      return { skipped: true, reason: "No midday Word Drop for today" };
    }

    // Only push to premium users (midday game is premium-only)
    const userIds = await step.run("get-premium-push-users", async () => {
      const { data: tokens } = await db
        .from("device_tokens")
        .select("user_id");

      if (!tokens?.length) return [];
      const ids = [...new Set(tokens.map((t) => t.user_id))];

      // Filter to premium users only
      const { data: premiumUsers } = await db
        .from("users")
        .select("id")
        .in("id", ids)
        .eq("is_premium", true);

      const premiumIds = new Set(premiumUsers?.map((u) => u.id) ?? []);

      const { data: disabledUsers } = await db
        .from("user_preferences")
        .select("user_id")
        .eq("push_enabled", false);

      const disabledSet = new Set(disabledUsers?.map((u) => u.user_id) ?? []);
      return ids.filter((id) => premiumIds.has(id) && !disabledSet.has(id));
    });

    if (!userIds.length) {
      return { skipped: true, reason: "No premium users with push enabled" };
    }

    const sent = await step.run("send-push", async () => {
      return await pushToUsers(userIds, {
        title: getRandomTitle(),
        body: "A fresh Word Drop puzzle is ready. Can you top your morning score?",
        data: { type: "word_drop", gameId: game.id },
      });
    });

    return { sent, totalUsers: userIds.length };
  }
);
