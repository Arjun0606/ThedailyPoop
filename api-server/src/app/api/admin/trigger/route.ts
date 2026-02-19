import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { inngest } from "@/inngest/client";

// GET /api/admin/trigger — health check + system status
export async function GET(request: NextRequest) {
  const db = createServiceClient();

  const { data: briefings, error: dbError } = await db
    .from("briefings")
    .select("id, publish_date, drop_type, headline, status")
    .eq("status", "published")
    .order("publish_date", { ascending: false })
    .limit(5);

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
    hint: "POST to this endpoint to manually trigger briefing generation",
  });
}

// POST /api/admin/trigger — manually trigger daily briefing generation
export async function POST(_request: NextRequest) {
  try {
    await inngest.send({
      name: "admin/trigger-briefing",
      data: { triggeredAt: new Date().toISOString() },
    });

    return NextResponse.json({
      triggered: true,
      message: "Daily briefing generation triggered. Check Inngest dashboard for progress.",
      time: new Date().toISOString(),
    });
  } catch (error) {
    return NextResponse.json(
      { error: `Failed to trigger: ${error}` },
      { status: 500 }
    );
  }
}
