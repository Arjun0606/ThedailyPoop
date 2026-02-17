import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function GET() {
  const db = createServiceClient();
  const today = new Date().toISOString().split("T")[0];

  // Fetch today's briefing
  const { data: briefing, error: briefingError } = await db
    .from("briefings")
    .select("*")
    .eq("publish_date", today)
    .eq("status", "published")
    .single();

  if (briefingError || !briefing) {
    return NextResponse.json(
      { error: "No briefing available for today" },
      { status: 404 }
    );
  }

  // Fetch stories for this briefing
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
