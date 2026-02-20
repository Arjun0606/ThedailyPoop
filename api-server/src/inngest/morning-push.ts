import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUsers } from "@/lib/push";

// Rotate through different push titles so it never feels stale
const PUSH_TITLES = [
  "wake up babe, new poop just dropped 💩",
  "the world is on fire. here's your update 🔥",
  "you're gonna wanna sit down for this one 💩",
  "your morning briefing is bussin 💩",
  "10 stories. 5 minutes. zero boring ones 💩",
  "the news just got interesting 💩",
  "stop doomscrolling. read this instead 💩",
  "your group chat is gonna need this 💩",
  "the poop is hot today 🔥💩",
  "today's news hits different 💩",
  "bad news: the world is wild. good news: we made it funny 💩",
  "breaking: stuff happened. we explained it 💩",
  "freshly squeezed news, just for you 💩",
  "your daily scoop awaits 💩",
];

function getRandomTitle(): string {
  return PUSH_TITLES[Math.floor(Math.random() * PUSH_TITLES.length)];
}

// Runs at 7:00 AM ET — sends push notification for today's briefing
export const morningPush = inngest.createFunction(
  { id: "morning-push", name: "Morning Push Notification", retries: 2 },
  { cron: "TZ=America/New_York 0 7 * * *" },
  async ({ step }) => {
    const db = createServiceClient();
    const today = new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });

    // Get today's morning briefing
    const briefing = await step.run("get-briefing", async () => {
      const { data } = await db
        .from("briefings")
        .select("id, headline")
        .eq("publish_date", today)
        .eq("drop_type", "daily")
        .eq("status", "published")
        .single();
      return data;
    });

    if (!briefing) {
      return { skipped: true, reason: "No published briefing for today" };
    }

    // Get all users with push enabled
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

    // Send push notifications
    const sent = await step.run("send-push", async () => {
      return await pushToUsers(userIds, {
        title: getRandomTitle(),
        body: briefing.headline,
        data: { type: "daily_briefing", briefingId: briefing.id },
      });
    });

    return { sent, totalUsers: userIds.length };
  }
);
