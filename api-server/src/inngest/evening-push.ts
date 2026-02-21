import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUsers } from "@/lib/push";

const EVENING_TITLES = [
  "you missed today's news? oh no 💀",
  "today's briefing expires soon. just saying 💩",
  "everyone played today's games except you 😬",
  "last call for today's poop 💩",
  "the day's almost over. the news isn't 🌙",
  "your evening scroll > their evening scroll 💩",
  "one last game before bed? 🎮💩",
  "today's news was actually insane. catch up 🔥",
  "plot twist: the evening news is funnier 🌙",
  "don't let today's stories expire unread 💩",
  "bedtime story but make it news 🌙💩",
  "your phone screen time is already high. make it count 💩",
];

const EVENING_BODIES = [
  "25 stories. 6 games. Don't let today slip away.",
  "Today's Poop or Scoop was the hardest one yet. Did you play?",
  "Your friends shared their scores today. Where's yours?",
  "The news doesn't sleep. Neither should your game streak.",
  "5 minutes before bed. That's all we need.",
  "Today's briefing had some absolute bangers. Just saying.",
];

function getRandomTitle(): string {
  return EVENING_TITLES[Math.floor(Math.random() * EVENING_TITLES.length)];
}

function getRandomBody(): string {
  return EVENING_BODIES[Math.floor(Math.random() * EVENING_BODIES.length)];
}

// Runs at 6 PM ET — FOMO engagement push for ALL users
export const eveningPush = inngest.createFunction(
  { id: "evening-push", name: "Evening Engagement Push", retries: 2 },
  { cron: "TZ=America/New_York 0 18 * * *" },
  async ({ step }) => {
    const db = createServiceClient();

    // Push to ALL users with push enabled
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
        body: getRandomBody(),
        data: { type: "daily_briefing" },
      });
    });

    return { sent, totalUsers: userIds.length };
  }
);
