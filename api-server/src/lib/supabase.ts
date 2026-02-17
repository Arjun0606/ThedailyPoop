import { createClient } from "@supabase/supabase-js";

// Service client — bypasses RLS for server-side operations
export function createServiceClient() {
  const url = process.env.SUPABASE_URL!;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  return createClient(url, key);
}

// Anon client — respects RLS, used for user-scoped operations
export function createAnonClient() {
  const url = process.env.SUPABASE_URL!;
  const key = process.env.SUPABASE_ANON_KEY!;
  return createClient(url, key);
}
