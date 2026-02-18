import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import {
  generateMorningDrop,
  generateMiddayDrop,
  generateEveningDrop,
  generateWordGame,
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
    generateMorningDrop,   // 5am — morning briefing (10 stories)
    generateMiddayDrop,    // 12pm — midday drop (5 stories)
    generateEveningDrop,   // 5pm — evening wrap (3 stories)
    generateWordGame,      // event-driven — word game after briefing
    morningPush,           // 7am — morning push notification
    middayPush,            // 12:30pm — midday push notification
    eveningPush,           // 5:30pm — evening push notification
    streakCheck,           // midnight — update/reset streaks
    cleanupSessions,       // hourly — delete old reader sessions
    weeklyDigest,          // Sunday 10am — weekly recap push
  ],
});
