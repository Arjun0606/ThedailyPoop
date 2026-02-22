import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function GET() {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const anon = process.env.SUPABASE_ANON_KEY;

  const envCheck = {
    SUPABASE_URL: url ? `${url.slice(0, 12)}...` : "MISSING",
    SUPABASE_SERVICE_ROLE_KEY: key ? `${key.slice(0, 10)}...${key.slice(-6)}` : "MISSING",
    SUPABASE_ANON_KEY: anon ? `${anon.slice(0, 10)}...${anon.slice(-6)}` : "MISSING",
  };

  let dbTest = "not tested";
  try {
    const db = createServiceClient();
    const { data, error } = await db
      .from("briefings")
      .select("id")
      .limit(1);
    if (error) {
      dbTest = `error: ${error.message}`;
    } else {
      dbTest = `ok, got ${data?.length ?? 0} rows`;
    }
  } catch (e: unknown) {
    dbTest = `exception: ${e instanceof Error ? e.message : String(e)}`;
  }

  return NextResponse.json({ envCheck, dbTest });
}
