import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import {
  generateDailyBriefing,
  generateWordGame,
  generatePoopOrScoop,
  morningPush,
  middayPush,
  eveningPush,
  streakCheck,
  cleanupSessions,
  weeklyDigest,
} from "@/inngest/functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    generateDailyBriefing, // 4am ET — daily briefing (20 stories)
    generateWordGame,      // event-driven — word game after briefing (×3)
    generatePoopOrScoop,   // event-driven — poop or scoop after briefing (×1)
    morningPush,           // 7am ET — push notification
    middayPush,            // 12pm ET — midday game unlock push
    eveningPush,           // 5pm ET — evening game unlock push
    streakCheck,           // midnight — update/reset streaks
    cleanupSessions,       // hourly — delete old reader sessions
    weeklyDigest,          // Sunday 10am — weekly recap push
  ],
});
