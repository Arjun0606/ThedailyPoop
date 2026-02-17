import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import {
  generateDailyBriefing,
  morningPush,
  streakCheck,
  cleanupSessions,
  weeklyDigest,
} from "@/inngest/functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    generateDailyBriefing, // 5am — AI briefing generation
    morningPush,           // 7am — push notification
    streakCheck,           // midnight — update/reset streaks
    cleanupSessions,       // hourly — delete old reader sessions
    weeklyDigest,          // Sunday 10am — weekly recap push
  ],
});
