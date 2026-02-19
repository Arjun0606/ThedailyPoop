import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "./supabase";

/**
 * Validates a user request via Supabase Bearer token.
 * Returns the authenticated user's ID, or an error response.
 *
 * If `requiredUserId` is provided, also checks that the token
 * belongs to that specific user (prevents acting on others' data).
 */
export async function validateUserRequest(
  request: NextRequest,
  requiredUserId?: string
): Promise<{ userId: string } | NextResponse> {
  const authHeader = request.headers.get("authorization");

  if (!authHeader?.startsWith("Bearer ")) {
    return NextResponse.json(
      { error: "Missing authorization header" },
      { status: 401 }
    );
  }

  const token = authHeader.slice(7);
  const db = createServiceClient();

  const {
    data: { user },
    error,
  } = await db.auth.getUser(token);

  if (error || !user) {
    return NextResponse.json(
      { error: "Invalid or expired token" },
      { status: 401 }
    );
  }

  if (requiredUserId && user.id !== requiredUserId) {
    return NextResponse.json(
      { error: "Forbidden: token does not match userId" },
      { status: 403 }
    );
  }

  return { userId: user.id };
}
