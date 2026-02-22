import { NextRequest, NextResponse } from "next/server";
import { createSupabaseRouteClient } from "@/lib/web-auth";

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/today";

  if (code) {
    const supabase = await createSupabaseRouteClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      return NextResponse.redirect(new URL(next, request.url));
    }
  }

  // Auth error — redirect to login
  return NextResponse.redirect(new URL("/login?error=auth", request.url));
}
