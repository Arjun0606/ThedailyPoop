import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { createServiceClient } from "./supabase";

export type WebSession = {
  userId: string;
  email: string;
  isPremium: boolean;
} | null;

export async function getWebSession(): Promise<WebSession> {
  try {
    const url = process.env.SUPABASE_URL;
    const key = process.env.SUPABASE_ANON_KEY;
    if (!url || !key) return null;

    const cookieStore = await cookies();

    const supabase = createServerClient(url, key, {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // Called from Server Component — can't set cookies, that's fine
          }
        },
      },
    });

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) return null;

    // Check premium status from our users table
    const db = createServiceClient();
    const { data: profile } = await db
      .from("users")
      .select("is_premium, premium_expires_at")
      .eq("id", user.id)
      .single();

    const isPremium =
      profile?.is_premium &&
      (!profile.premium_expires_at ||
        new Date(profile.premium_expires_at) > new Date());

    return {
      userId: user.id,
      email: user.email || "",
      isPremium: !!isPremium,
    };
  } catch (e) {
    console.error("getWebSession error:", e);
    return null;
  }
}

// Create a Supabase client for use in Route Handlers (can set cookies)
export async function createSupabaseRouteClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          );
        },
      },
    }
  );
}
