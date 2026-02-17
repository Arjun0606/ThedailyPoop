import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import {
  dailyChallenges,
  challengeResults,
  weeklyRecap,
  expireContent,
} from "@/inngest/functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    dailyChallenges,
    challengeResults,
    weeklyRecap,
    expireContent,
  ],
});
