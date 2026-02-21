import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { validateUserRequest } from "@/lib/user-auth";

export async function POST(request: NextRequest) {
  const body = await request.json();
  const { userId, roastId, text } = body as { userId: string; roastId: string; text: string };

  if (!userId || !roastId || !text?.trim()) {
    return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  }

  const auth = await validateUserRequest(request, userId);
  if (auth instanceof NextResponse) return auth;

  const db = createServiceClient();

  // Get username
  const { data: user } = await db
    .from("users")
    .select("username")
    .eq("id", userId)
    .single();

  const { data: entry, error: saveError } = await db
    .from("roast_entries")
    .insert({
      prompt_id: roastId,
      user_id: userId,
      body: text.trim(),
    })
    .select("id, user_id, body, ai_score, upvotes, created_at")
    .single();

  if (saveError) {
    if (saveError.code === "23505") {
      return NextResponse.json({ error: "Already submitted" }, { status: 409 });
    }
    return NextResponse.json({ error: saveError.message }, { status: 500 });
  }

  return NextResponse.json({
    entry: {
      id: entry.id,
      user_id: entry.user_id,
      username: user?.username ?? "Anonymous",
      text: entry.body,
      ai_score: entry.ai_score,
      upvotes: entry.upvotes,
      created_at: entry.created_at,
    },
    aiScore: 0,
    aiFeedback: "Scoring coming soon!",
  });
}
