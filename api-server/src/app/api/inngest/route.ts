import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import {
  generateDailyBriefing,
  generateWordGame,
  generatePoopOrScoop,
  generateWhoSaidIt,
  generateSpinTheExcuse,
  generateRoast,
  generatePredictions,
  generateHeadlineRoulette,
  morningPush,
  middayPush,
  eveningPush,
  streakCheck,
  cleanupSessions,
  weeklyDigest,
  sendDailyNewsletter,
} from "@/inngest/functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    generateDailyBriefing,   // 5:30am ET — daily briefing (25 stories, jester voice)
    generateWordGame,         // event-driven — word game after briefing
    generatePoopOrScoop,      // event-driven — real/fake headline game
    generateWhoSaidIt,        // event-driven — quote attribution game
    generateSpinTheExcuse,    // event-driven — PR excuse guessing game
    generateRoast,            // event-driven — daily roast prompt
    generatePredictions,      // event-driven — 3 daily predictions
    generateHeadlineRoulette, // event-driven — rank headlines by insanity
    morningPush,              // 7am ET — push notification
    middayPush,               // 12pm ET — midday push
    eveningPush,              // 5pm ET — evening push
    streakCheck,              // midnight — update/reset streaks
    cleanupSessions,          // hourly — delete old reader sessions
    weeklyDigest,             // Sunday 10am — weekly recap push
    sendDailyNewsletter,      // 7:30am ET — daily email newsletter
  ],
});
