import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUsers } from "@/lib/push";

const EVENING_TITLES = [
  "evening wrap: today was a movie 🎬💩",
  "day's almost over. here's what you missed 💩",
  "tonight's debrief just dropped 💩",
  "end of day recap 🌙💩",
  "that's a wrap. today was wild 🔥💩",
  "evening poop: the day in review 💩",
  "before you log off... read this 💩",
  "your nighttime news dump 🌙💩",
];

function getRandomTitle(): string {
  return EVENING_TITLES[Math.floor(Math.random() * EVENING_TITLES.length)];
}

// Runs at 5:30 PM — sends push for evening drop
export const eveningPush = inngest.createFunction(
  { id: "evening-push", name: "Evening Push Notification" },
  { cron: "30 17 * * *" },
  async ({ step }) => {
    const db = createServiceClient();
    const today = new Date().toISOString().split("T")[0];

    const briefing = await step.run("get-briefing", async () => {
      const { data } = await db
        .from("briefings")
        .select("id, headline")
        .eq("publish_date", today)
        .eq("drop_type", "evening")
        .eq("status", "published")
        .single();
      return data;
    });

    if (!briefing) {
      return { skipped: true, reason: "No evening drop for today" };
    }

    const userIds = await step.run("get-push-users", async () => {
      const { data: tokens } = await db
        .from("device_tokens")
        .select("user_id");

      if (!tokens?.length) return [];
      const ids = [...new Set(tokens.map((t) => t.user_id))];

      const { data: disabledUsers } = await db
        .from("user_preferences")
        .select("user_id")
        .eq("push_enabled", false);

      const disabledSet = new Set(disabledUsers?.map((u) => u.user_id) ?? []);
      return ids.filter((id) => !disabledSet.has(id));
    });

    if (!userIds.length) {
      return { skipped: true, reason: "No users with push enabled" };
    }

    const sent = await step.run("send-push", async () => {
      return await pushToUsers(userIds, {
        title: getRandomTitle(),
        body: briefing.headline,
        data: { type: "evening_drop", briefingId: briefing.id },
      });
    });

    return { sent, totalUsers: userIds.length };
  }
);
