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

  const { userId, username, displayName, avatarUrl, appleUserId } = body;

  if (!userId || !username) {
    return NextResponse.json(
      { error: "Missing required fields: userId, username" },
      { status: 400 }
    );
  }

  // Verify the requester owns this account
  const auth = await validateUserRequest(request, userId);
  if (auth instanceof NextResponse) return auth;

  // Check username availability (exclude current user)
  const { data: taken } = await db
    .from("users")
    .select("id")
    .eq("username", username)
    .neq("id", userId)
    .maybeSingle();

  if (taken) {
    return NextResponse.json(
      { error: "Username already taken" },
      { status: 409 }
    );
  }

  // Upsert user profile (service client bypasses RLS)
  const { data, error } = await db
    .from("users")
    .upsert(
      {
        id: userId,
        username,
        display_name: displayName || null,
        avatar_url: avatarUrl || null,
        apple_user_id: appleUserId || userId,
      },
      { onConflict: "id" }
    )
    .select()
    .single();

  if (error) {
    return NextResponse.json(
      { error: `Failed to save profile: ${error.message}` },
      { status: 500 }
    );
  }

  return NextResponse.json({
    success: true,
    user: {
      id: data.id,
      username: data.username,
      displayName: data.display_name,
      avatarUrl: data.avatar_url,
      isPremium: data.is_premium ?? false,
      streakCount: data.streak_count ?? 0,
    },
  });
}
