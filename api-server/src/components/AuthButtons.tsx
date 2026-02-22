"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";

interface AuthButtonsProps {
  user: { email: string; isPremium: boolean } | null;
}

export default function AuthButtons({ user }: AuthButtonsProps) {
  const router = useRouter();

  async function handleLogout() {
    const supabase = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  }

  if (user) {
    return (
      <div className="flex items-center gap-3">
        {user.isPremium && (
          <span className="rounded-full bg-[var(--accent)]/20 px-2 py-0.5 text-[10px] font-bold text-[var(--accent)]">
            PRO
          </span>
        )}
        <button
          onClick={handleLogout}
          className="text-xs font-medium text-[var(--text-secondary)] transition hover:text-white"
        >
          Log out
        </button>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-2">
      <Link
        href="/login"
        className="text-xs font-medium text-[var(--text-secondary)] transition hover:text-white"
      >
        Log in
      </Link>
      <Link
        href="/signup"
        className="rounded-full border border-[var(--accent)] px-3 py-1 text-xs font-bold text-[var(--accent)] transition hover:bg-[var(--accent)] hover:text-black"
      >
        Sign up
      </Link>
    </div>
  );
}
