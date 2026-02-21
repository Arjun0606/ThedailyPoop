import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function GET(request: Request) {
  const db = createServiceClient();
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get("userId");

  const today = new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });

  let { data: prompt, error } = await db
    .from("roast_prompts")
    .select("id, publish_date, story_headline, story_summary")
    .eq("publish_date", today)
    .single();

  if (error || !prompt) {
    const fallback = await db
      .from("roast_prompts")
      .select("id, publish_date, story_headline, story_summary")
      .order("publish_date", { ascending: false })
      .limit(1)
      .single();
    prompt = fallback.data;
  }

  if (!prompt) return NextResponse.json({ roast: null });

  // Fetch top entries with username from users table
  const { data: rawEntries } = await db
    .from("roast_entries")
    .select("id, user_id, body, ai_score, upvotes, created_at, users!user_id(username)")
    .eq("prompt_id", prompt.id)
    .order("upvotes", { ascending: false })
    .limit(20);

  const entries = (rawEntries ?? []).map((e: any) => ({
    id: e.id,
    user_id: e.user_id,
    username: e.users?.username ?? "Anonymous",
    text: e.body,
    ai_score: e.ai_score,
    upvotes: e.upvotes,
    created_at: e.created_at,
  }));

  let userEntry = null;
  if (userId) {
    userEntry = entries.find((e) => e.user_id === userId) ?? null;
  }

  return NextResponse.json({
    roast: {
      id: prompt.id,
      publishDate: prompt.publish_date,
      storyHeadline: prompt.story_headline,
      storySummary: prompt.story_summary,
      userEntry,
      topEntries: entries,
    },
  });
}
