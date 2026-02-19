import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { inngest } from "@/inngest/client";
import { validateAdminRequest } from "@/lib/admin-auth";

// GET /api/admin/trigger — health check + system status
export async function GET(request: NextRequest) {
  const authError = validateAdminRequest(request);
  if (authError) return authError;

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

// POST /api/admin/trigger — manually trigger daily briefing generation or word games
export async function POST(request: NextRequest) {
  const authError = validateAdminRequest(request);
  if (authError) return authError;

  const db = createServiceClient();
  const body = await request.json().catch(() => ({}));

  // If action=games, trigger word games for today's existing briefing
  if (body.action === "games") {
    const today = new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });
    const { data: briefing } = await db
      .from("briefings")
      .select("id")
      .eq("publish_date", today)
      .eq("status", "published")
      .single();

    if (!briefing) {
      return NextResponse.json({ error: "No briefing found for today" }, { status: 404 });
    }

    const events = ["morning", "midday", "evening"].map((dropType) => ({
      name: "briefing/published" as const,
      data: { briefingId: briefing.id, dropType, publishDate: today },
    }));

    const result = await inngest.send(events);
    return NextResponse.json({
      triggered: true,
      action: "games",
      briefingId: briefing.id,
      events: events.length,
      inngestResult: result,
    });
  }

  try {
    // Send event via Inngest
    const result = await inngest.send({
      name: "admin/trigger-briefing",
      data: { triggeredAt: new Date().toISOString() },
    });

    return NextResponse.json({
      triggered: true,
      inngestResult: result,
      message: "Daily briefing generation triggered via Inngest event.",
      time: new Date().toISOString(),
    });
  } catch (error: unknown) {
    const errMsg = error instanceof Error ? error.message : String(error);

    // Fallback: try to run the first step (fetch news) directly
    // This won't complete the full pipeline but shows if the API keys work
    try {
      const { fetchAllCategories } = await import("@/lib/perplexity");
      const categories = await fetchAllCategories();
      const storyCount = categories.reduce((sum, c) => sum + c.stories.length, 0);

      return NextResponse.json({
        triggered: false,
        inngestError: errMsg,
        fallbackTest: {
          perplexityWorking: storyCount > 0,
          storiesFetched: storyCount,
          categories: categories.map((c) => ({
            name: c.category,
            count: c.stories.length,
          })),
        },
        message: "Inngest event failed, but Perplexity API is working. Check Inngest dashboard.",
      });
    } catch (fallbackError: unknown) {
      return NextResponse.json(
        {
          error: errMsg,
          fallbackError: fallbackError instanceof Error ? fallbackError.message : String(fallbackError),
        },
        { status: 500 }
      );
    }
  }
}
