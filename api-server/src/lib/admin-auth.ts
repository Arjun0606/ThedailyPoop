import { NextRequest, NextResponse } from "next/server";

/**
 * Validates admin requests using ADMIN_API_KEY from env.
 * Accepts either:
 *   - Header: Authorization: Bearer <key>
 *   - Query param: ?key=<key>
 */
export function validateAdminRequest(request: NextRequest): NextResponse | null {
  const adminKey = process.env.ADMIN_API_KEY;

  if (!adminKey) {
    return NextResponse.json(
      { error: "Admin API key not configured on server" },
      { status: 500 }
    );
  }

  const authHeader = request.headers.get("authorization");
  const queryKey = request.nextUrl.searchParams.get("key");

  const providedKey = authHeader?.startsWith("Bearer ")
    ? authHeader.slice(7)
    : queryKey;

  if (providedKey !== adminKey) {
    return NextResponse.json(
      { error: "Unauthorized" },
      { status: 401 }
    );
  }

  return null; // Auth passed
}
