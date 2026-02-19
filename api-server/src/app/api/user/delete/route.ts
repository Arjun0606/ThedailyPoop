import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { validateUserRequest } from "@/lib/user-auth";

export async function POST(request: NextRequest) {
  const db = createServiceClient();

  let body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const { userId } = body;

  if (!userId) {
    return NextResponse.json(
      { error: "Missing required field: userId" },
      { status: 400 }
    );
  }

  // Verify the requester owns this account
  const auth = await validateUserRequest(request, userId);
  if (auth instanceof NextResponse) return auth;

  // Verify the user exists
  const { data: user } = await db
    .from("users")
    .select("id")
    .eq("id", userId)
    .maybeSingle();

  if (!user) {
    return NextResponse.json({ error: "User not found" }, { status: 404 });
  }

  // Delete related data (cascade handles most, but explicit for safety)
  await db.from("word_game_scores").delete().eq("user_id", userId);
  await db.from("user_reads").delete().eq("user_id", userId);
  await db.from("story_reactions").delete().eq("user_id", userId);
  await db.from("story_bookmarks").delete().eq("user_id", userId);
  await db.from("reader_sessions").delete().eq("user_id", userId);
  await db.from("user_preferences").delete().eq("user_id", userId);
  await db.from("device_tokens").delete().eq("user_id", userId);
  await db.from("subscriptions").delete().eq("user_id", userId);

  // Delete the user profile from the users table
  const { error: deleteUserError } = await db
    .from("users")
    .delete()
    .eq("id", userId);

  if (deleteUserError) {
    return NextResponse.json(
      { error: `Failed to delete user data: ${deleteUserError.message}` },
      { status: 500 }
    );
  }

  // Delete from Supabase Auth (this is the critical missing piece)
  const { error: authError } = await db.auth.admin.deleteUser(userId);

  if (authError) {
    return NextResponse.json(
      { error: `Failed to delete auth account: ${authError.message}` },
      { status: 500 }
    );
  }

  return NextResponse.json({ success: true });
}
