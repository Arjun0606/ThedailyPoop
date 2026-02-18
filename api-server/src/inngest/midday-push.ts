import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUsers } from "@/lib/push";

const MIDDAY_TITLES = [
  "midday update just dropped 🔥",
  "plot twist: the afternoon is wild 💩",
  "your lunchtime debrief is ready 💩",
  "breaking: more stuff happened 💩",
  "things just got interesting 🔥💩",
  "afternoon poop incoming 💩",
  "stop what you're doing. read this 💩",
  "new stories just dropped. you need these 🔥",
];

function getRandomTitle(): string {
  return MIDDAY_TITLES[Math.floor(Math.random() * MIDDAY_TITLES.length)];
}

// Runs at 12:30 PM — sends push for midday drop
export const middayPush = inngest.createFunction(
  { id: "midday-push", name: "Midday Push Notification" },
  { cron: "30 12 * * *" },
  async ({ step }) => {
    const db = createServiceClient();
    const today = new Date().toISOString().split("T")[0];

    const briefing = await step.run("get-briefing", async () => {
      const { data } = await db
        .from("briefings")
        .select("id, headline")
        .eq("publish_date", today)
        .eq("drop_type", "midday")
        .eq("status", "published")
        .single();
      return data;
    });

    if (!briefing) {
      return { skipped: true, reason: "No midday drop for today" };
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
        data: { type: "midday_drop", briefingId: briefing.id },
      });
    });

    return { sent, totalUsers: userIds.length };
  }
);
