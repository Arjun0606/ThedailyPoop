import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

const DROP_ORDER = ["morning", "midday", "evening"];

export async function GET() {
  const db = createServiceClient();
  const today = new Date().toISOString().split("T")[0];

  // Fetch all published drops for today
  const { data: briefings, error: briefingError } = await db
    .from("briefings")
    .select("*")
    .eq("publish_date", today)
    .eq("status", "published");

  if (briefingError || !briefings?.length) {
    return NextResponse.json(
      { error: "No briefing available for today" },
      { status: 404 }
    );
  }

  // Sort by drop order (morning → midday → evening)
  briefings.sort(
    (a, b) => DROP_ORDER.indexOf(a.drop_type) - DROP_ORDER.indexOf(b.drop_type)
  );

  // Fetch stories for all briefings
  const briefingIds = briefings.map((b) => b.id);
  const { data: allStories } = await db
    .from("stories")
    .select("*")
    .in("briefing_id", briefingIds)
    .order("sort_order", { ascending: true });

  // Group stories by briefing
  const stories = allStories ?? [];
  const storiesByBriefing: Record<string, typeof stories> = {};
  for (const story of stories) {
    if (!storiesByBriefing[story.briefing_id]) {
      storiesByBriefing[story.briefing_id] = [];
    }
    storiesByBriefing[story.briefing_id].push(story);
  }

  const drops = briefings.map((briefing) => ({
    briefing,
    stories: storiesByBriefing[briefing.id] ?? [],
  }));

  return NextResponse.json({ drops });
}
