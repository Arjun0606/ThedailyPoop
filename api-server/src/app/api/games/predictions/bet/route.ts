import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { validateUserRequest } from "@/lib/user-auth";

export async function POST(request: NextRequest) {
  const body = await request.json();
  const { userId, predictionId, bet } = body as { userId: string; predictionId: string; bet: boolean };

  if (!userId || !predictionId || bet === undefined) {
    return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  }

  const auth = await validateUserRequest(request, userId);
  if (auth instanceof NextResponse) return auth;

  const db = createServiceClient();

  const { error: saveError } = await db.from("prediction_bets").insert({
    user_id: userId,
    prediction_id: predictionId,
    bet,
  });

  if (saveError) {
    if (saveError.code === "23505") {
      return NextResponse.json({ error: "Already bet" }, { status: 409 });
    }
    return NextResponse.json({ error: saveError.message }, { status: 500 });
  }

  return NextResponse.json({ success: true, predictionId, bet });
}
