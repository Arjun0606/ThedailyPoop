import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

// Health check + admin status endpoint
// GET /api/admin/trigger — returns system status
// Useful for verifying everything is connected

export async function GET(request: NextRequest) {
  const db = createServiceClient();

  // Check DB connection
  const { data: briefings, error: dbError } = await db
    .from("briefings")
    .select("id, publish_date, drop_type, headline, status")
    .eq("status", "published")
    .order("publish_date", { ascending: false })
    .limit(5);

  // Check env vars
  const envStatus = {
    SUPABASE_URL: !!process.env.SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
    OPENAI_API_KEY: !!process.env.OPENAI_API_KEY,
    PERPLEXITY_API_KEY: !!process.env.PERPLEXITY_API_KEY,
    INNGEST_EVENT_KEY: !!process.env.INNGEST_EVENT_KEY,
    INNGEST_SIGNING_KEY: !!process.env.INNGEST_SIGNING_KEY,
  };

  const allEnvSet = Object.values(envStatus).every(Boolean);

  return NextResponse.json({
    status: allEnvSet && !dbError ? "ready" : "issues",
    database: dbError ? `error: ${dbError.message}` : "connected",
    envVars: envStatus,
    recentBriefings: briefings?.length ?? 0,
    latestBriefings: briefings ?? [],
  });
}
