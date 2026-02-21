import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { validateUserRequest } from "@/lib/user-auth";

export async function POST(request: NextRequest) {
  const body = await request.json();
  const { userId, entryId } = body as { userId: string; entryId: string };

  if (!userId || !entryId) {
    return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  }

  const auth = await validateUserRequest(request, userId);
  if (auth instanceof NextResponse) return auth;

  const db = createServiceClient();

  // Insert vote (unique constraint prevents double-voting)
  const { error: voteError } = await db.from("roast_votes").insert({
    user_id: userId,
    entry_id: entryId,
  });

  if (voteError) {
    if (voteError.code === "23505") {
      return NextResponse.json({ error: "Already voted" }, { status: 409 });
    }
    return NextResponse.json({ error: voteError.message }, { status: 500 });
  }

  // Update upvotes count based on actual votes
  const { count } = await db
    .from("roast_votes")
    .select("*", { count: "exact", head: true })
    .eq("entry_id", entryId);

  await db
    .from("roast_entries")
    .update({ upvotes: count ?? 0 })
    .eq("id", entryId);

  return NextResponse.json({ success: true });
}
