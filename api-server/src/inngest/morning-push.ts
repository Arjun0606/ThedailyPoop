import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUsers } from "@/lib/push";

// Rotate through different push titles so it never feels stale
const PUSH_TITLES = [
  // OG classics
  "wake up babe, new poop just dropped 💩",
  "the world is on fire. here's your update 🔥",
  "you're gonna wanna sit down for this one 💩",
  // Unhinged energy
  "congress did something stupid again. shocking 💩",
  "a CEO said something unhinged. come guess who 🎤",
  "the news is so wild today we double-checked it 💩",
  "your boss hasn't read this yet. stay ahead 💩",
  "today's news brought to you by poor decisions 💩",
  "25 stories. 6 games. 1 toilet break 🚽",
  "the algorithm wants you to read boring news. we don't 💩",
  // FOMO drivers
  "your group chat is gonna need this 💩",
  "everyone's talking about today's drop except you 💩",
  "this is not a drill. today's news is unreal 🔥",
  "you vs today's Poop or Scoop. who wins? 💩",
  // Provocative
  "a politician lied today. we made it funny 🏛️",
  "billionaires did billionaire things again 💰💩",
  "someone got caught. someone got fired. someone got roasted 🔥",
  "the world is a circus and we wrote the reviews 🎪",
  "today in 'you can't make this up' 💩",
  "another day another dumpster fire. let's go 🔥💩",
  // Game hooks
  "6 news games just dropped. your lunch break is calling 🎮",
  "can you spot the fake headline? prove it 💩",
  "Who Said It — CEO, dictator, or cult leader? 🤔",
  // Short punchy
  "it's giving chaos 💩",
  "bro why is today's news like this 💀",
  "absolute scenes in today's briefing 🔥",
  "the poop is HOT today 💩🔥",
  "just... read it. trust us 💩",
  "5 minutes. 25 stories. zero cringe 💩",
  "your daily dose of organized chaos 💩",
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
