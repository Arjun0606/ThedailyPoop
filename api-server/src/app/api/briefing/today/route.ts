import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

const DROP_ORDER = ["morning", "midday", "evening"];

export async function GET() {
  const db = createServiceClient();
  const today = new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });

  // Fetch all published drops for today
  let { data: briefings } = await db
    .from("briefings")
    .select("*")
    .eq("publish_date", today)
    .eq("status", "published");

  // Fallback: if no briefings today, return the most recent available
  if (!briefings?.length) {
    const { data: latest } = await db
      .from("briefings")
      .select("*")
      .eq("status", "published")
      .order("publish_date", { ascending: false })
      .limit(3);

    briefings = latest;
  }

  if (!briefings?.length) {
    return NextResponse.json(
      { error: "No briefings available yet" },
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
