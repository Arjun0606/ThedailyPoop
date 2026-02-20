import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUsers } from "@/lib/push";

const EVENING_TITLES = [
  "final Word Drop of the day 🌙",
  "evening Word Drop just dropped 🎯",
  "last chance to play today's Word Drop 💩",
  "nighttime brain teaser unlocked 🌙💩",
  "Word Drop #3 — end the day strong 🔥",
  "one more game before bed? 🎯💩",
  "evening puzzle is live. go get it 🌙",
  "your night cap Word Drop awaits 🔥",
];

function getRandomTitle(): string {
  return EVENING_TITLES[Math.floor(Math.random() * EVENING_TITLES.length)];
}

// Runs at 5 PM ET — notifies about evening Word Drop unlock
export const eveningPush = inngest.createFunction(
  { id: "evening-push", name: "Evening Word Drop Push", retries: 2 },
  { cron: "TZ=America/New_York 0 17 * * *" },
  async ({ step }) => {
    const db = createServiceClient();
    const today = new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });

    // Check that today's evening game exists
    const game = await step.run("check-game", async () => {
      const { data } = await db
        .from("word_games")
        .select("id")
        .eq("publish_date", today)
        .eq("drop_type", "evening")
        .single();
      return data;
    });

    if (!game) {
      return { skipped: true, reason: "No evening Word Drop for today" };
    }

    // Only push to premium users (evening game is premium-only)
    const userIds = await step.run("get-premium-push-users", async () => {
      const { data: tokens } = await db
        .from("device_tokens")
        .select("user_id");

      if (!tokens?.length) return [];
      const ids = [...new Set(tokens.map((t) => t.user_id))];

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
        body: "Last Word Drop of the day. End on a high score!",
        data: { type: "word_drop", gameId: game.id },
      });
    });

    return { sent, totalUsers: userIds.length };
  }
);
