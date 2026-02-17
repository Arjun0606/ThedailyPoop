import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { pushToUsers } from "@/lib/push";

// Runs at 7:00 AM ET — sends push notification for today's briefing
export const morningPush = inngest.createFunction(
  { id: "morning-push", name: "Morning Push Notification" },
  { cron: "0 7 * * *" }, // 7:00 AM UTC (adjust for ET)
  async ({ step }) => {
    const db = createServiceClient();
    const today = new Date().toISOString().split("T")[0];

    // Get today's briefing
    const briefing = await step.run("get-briefing", async () => {
      const { data } = await db
        .from("briefings")
        .select("id, headline")
        .eq("publish_date", today)
        .eq("status", "published")
        .single();
      return data;
    });

    if (!briefing) {
      return { skipped: true, reason: "No published briefing for today" };
    }

    // Get all users with push enabled
    const userIds = await step.run("get-push-users", async () => {
      // Get users who have device tokens
      const { data: tokens } = await db
        .from("device_tokens")
        .select("user_id");

      if (!tokens?.length) return [];

      const ids = [...new Set(tokens.map((t) => t.user_id))];

      // Filter out users who disabled push
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
        title: "Your Daily Poop is ready 💩",
        body: briefing.headline,
        data: { type: "daily_briefing", briefingId: briefing.id },
      });
    });

    return { sent, totalUsers: userIds.length };
  }
);
