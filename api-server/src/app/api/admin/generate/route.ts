import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { fetchAllCategories } from "@/lib/perplexity";

// Direct debug endpoint — runs just the news fetch step to test
// GET /api/admin/generate — tests Perplexity + returns raw stories
export async function GET() {
  const db = createServiceClient();
  const today = new Date().toISOString().split("T")[0];

  try {
    // Step 1: Check if briefing already exists
    const { data: existing } = await db
      .from("briefings")
      .select("id, headline")
      .eq("publish_date", today)
      .eq("drop_type", "daily")
      .single();

    if (existing) {
      return NextResponse.json({
        status: "already_exists",
        briefing: existing,
      });
    }

    // Step 2: Fetch news from Perplexity
    const rawStories = await fetchAllCategories();
    const allStories = rawStories.flatMap((r) =>
      r.stories.map((s) => ({ ...s, category: r.category }))
    );

    return NextResponse.json({
      status: "fetched",
      totalStories: allStories.length,
      byCategory: rawStories.map((r) => ({
        category: r.category,
        count: r.stories.length,
        titles: r.stories.map((s) => s.title),
      })),
    });
  } catch (error: unknown) {
    return NextResponse.json(
      {
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack?.split("\n").slice(0, 5) : undefined,
      },
      { status: 500 }
    );
  }
}
