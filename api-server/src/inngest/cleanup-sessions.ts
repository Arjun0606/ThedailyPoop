import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";

// Runs every hour — deletes reader_sessions older than 2 hours
export const cleanupSessions = inngest.createFunction(
  { id: "cleanup-sessions", name: "Cleanup Reader Sessions" },
  { cron: "0 * * * *" }, // every hour
  async ({ step }) => {
    const deleted = await step.run("delete-old-sessions", async () => {
      const db = createServiceClient();
      const cutoff = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();

      const { count, error } = await db
        .from("reader_sessions")
        .delete({ count: "exact" })
        .lt("created_at", cutoff);

      if (error) {
        console.error("Cleanup error:", error.message);
        return { error: error.message };
      }

      return { deleted: count ?? 0 };
    });

    return deleted;
  }
);
