import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function GET(request: Request) {
  const db = createServiceClient();
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get("userId");

  const today = new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });

  const { data: predictions, error } = await db
    .from("predictions")
    .select("id, publish_date, question, context, resolve_by, resolved_answer")
    .eq("publish_date", today)
    .order("created_at", { ascending: true });

  if (error || !predictions?.length) {
    return NextResponse.json({ predictions: [] });
  }

  // Check user bets if logged in
  let betMap = new Map<string, boolean>();
  if (userId) {
    const { data: bets } = await db
      .from("prediction_bets")
      .select("prediction_id, bet")
      .eq("user_id", userId)
      .in("prediction_id", predictions.map((p) => p.id));

    if (bets) {
      betMap = new Map(bets.map((b) => [b.prediction_id, b.bet]));
    }
  }

  const result = predictions.map((p) => ({
    id: p.id,
    publishDate: p.publish_date,
    question: p.question,
    context: p.context,
    resolveBy: p.resolve_by,
    resolvedAnswer: p.resolved_answer,
    userBet: betMap.has(p.id) ? betMap.get(p.id) : null,
  }));

  return NextResponse.json({ predictions: result });
}
