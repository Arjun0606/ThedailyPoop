import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";

// Runs every hour — delete expired gossip (24h)
// Drops do NOT expire — they stay on the map permanently
export const expireContent = inngest.createFunction(
  { id: "expire-content", name: "Expire Old Gossip" },
  { cron: "0 * * * *" },
  async ({ step }) => {
    const db = createServiceClient();
    const now = new Date().toISOString();

    const gossipResult = await step.run("expire-gossip", async () => {
      const { count } = await db
        .from("gossip")
        .delete({ count: "exact" })
        .lt("expires_at", now);
      return count ?? 0;
    });

    return { expiredGossip: gossipResult };
  }
);
