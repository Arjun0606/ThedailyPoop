import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function POST(request: NextRequest) {
  const body = await request.json();
  const { userId, storyId, username, storyHeadline } = body;

  if (!userId) {
    return NextResponse.json({ error: "userId required" }, { status: 400 });
  }

  // Vercel provides geo headers automatically
  const latitude = parseFloat(
    request.headers.get("x-vercel-ip-latitude") ?? "0"
  );
  const longitude = parseFloat(
    request.headers.get("x-vercel-ip-longitude") ?? "0"
  );
  const countryCode = request.headers.get("x-vercel-ip-country") ?? null;
  const city = request.headers.get("x-vercel-ip-city") ?? null;

  // Skip if no geo data (local dev)
  if (latitude === 0 && longitude === 0) {
    return NextResponse.json({ ok: true, geo: false });
  }

  // Map country codes to names for display
  const countryName = countryCode
    ? new Intl.DisplayNames(["en"], { type: "region" }).of(countryCode) ?? null
    : null;

  const db = createServiceClient();

  const { error } = await db.from("reader_sessions").insert({
    user_id: userId,
    story_id: storyId ?? null,
    username: username ?? null,
    story_headline: storyHeadline ?? null,
    latitude,
    longitude,
    country_code: countryCode,
    country_name: countryName,
    city,
  });

  if (error) {
    console.error("Reader ping insert error:", error.message);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({
    ok: true,
    geo: true,
    latitude,
    longitude,
    countryCode,
    countryName,
    city,
  });
}
