import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function POST(request: NextRequest) {
  const authHeader = request.headers.get("authorization");
  const expectedToken = process.env.REVENUECAT_WEBHOOK_AUTH_TOKEN;

  if (!expectedToken || authHeader !== `Bearer ${expectedToken}`) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const event = body.event;

  if (!event?.app_user_id || !event?.type) {
    return NextResponse.json({ error: "Invalid event" }, { status: 400 });
  }

  const userId = event.app_user_id;
  const type: string = event.type;
  const db = createServiceClient();

  if (
    [
      "INITIAL_PURCHASE",
      "RENEWAL",
      "PRODUCT_CHANGE",
      "UNCANCELLATION",
    ].includes(type)
  ) {
    const expiresAt = event.expiration_at_ms
      ? new Date(event.expiration_at_ms).toISOString()
      : null;

    await db
      .from("users")
      .update({
        is_premium: true,
        premium_expires_at: expiresAt,
      })
      .eq("id", userId);
  }

  if (type === "EXPIRATION") {
    await db
      .from("users")
      .update({ is_premium: false })
      .eq("id", userId);
  }

  return NextResponse.json({ received: true });
}
