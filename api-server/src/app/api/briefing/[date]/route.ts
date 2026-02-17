import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ date: string }> }
) {
  const { date } = await params;
  const db = createServiceClient();

  // Validate date format
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return NextResponse.json(
      { error: "Invalid date format. Use YYYY-MM-DD." },
      { status: 400 }
    );
  }

  // Fetch briefing for the given date
  const { data: briefing, error: briefingError } = await db
    .from("briefings")
    .select("*")
    .eq("publish_date", date)
    .eq("status", "published")
    .single();

  if (briefingError || !briefing) {
    return NextResponse.json(
      { error: `No briefing available for ${date}` },
      { status: 404 }
    );
  }

  // Fetch stories
  const { data: stories } = await db
    .from("stories")
    .select("*")
    .eq("briefing_id", briefing.id)
    .order("sort_order", { ascending: true });

  return NextResponse.json({
    briefing,
    stories: stories ?? [],
  });
}
