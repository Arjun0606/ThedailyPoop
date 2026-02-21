import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUsers } from "@/lib/push";

const MIDDAY_TITLES = [
  "lunch break? more like game break 🎮💩",
  "your coworkers are playing. don't fall behind 💩",
  "midday brain break: 6 games waiting 🎯",
  "the afternoon slump called. we have the cure 💩",
  "you haven't played today's games yet? bold 💩",
  "Poop or Scoop won't play itself 💩",
  "real headline or fake? prove you know the difference 🎯",
  "CEO, dictator, or cult leader? one way to find out 🤔",
  "your lunch is getting cold but these games are hot 🔥",
  "5 minutes + 6 games = justified procrastination 💩",
  "the news is wild today. the games are wilder 🎮",
  "someone in your city just scored 5/5. can you? 💩",
];

const MIDDAY_BODIES = [
  "6 games based on today's insane news. Your move.",
  "Today's Poop or Scoop is genuinely hard. Good luck.",
  "Can you spot the fake headline? Today's is tricky.",
  "Who Said It is live. CEO or cult leader? You decide.",
  "Today's games are ready. Your lunch break approves.",
  "The news is chaos. The games make it fun.",
];

function getRandomTitle(): string {
  return MIDDAY_TITLES[Math.floor(Math.random() * MIDDAY_TITLES.length)];
}

function getRandomBody(): string {
  return MIDDAY_BODIES[Math.floor(Math.random() * MIDDAY_BODIES.length)];
}

// Runs at 12 PM ET — game nudge for ALL users
export const middayPush = inngest.createFunction(
  { id: "midday-push", name: "Midday Game Nudge Push", retries: 2 },
  { cron: "TZ=America/New_York 0 12 * * *" },
  async ({ step }) => {
    const db = createServiceClient();

    // Push to ALL users with push enabled (not just premium)
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
        data: { type: "games" },
      });
    });

    return { sent, totalUsers: userIds.length };
  }
);
