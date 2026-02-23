"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { createBrowserClient } from "@supabase/ssr";
import { initRevenueCat, purchasePackage, checkEntitlement } from "@/lib/revenuecat";

type PageState = "loading" | "no-auth" | "already-pro" | "pricing" | "purchasing" | "success" | "error";

export default function ProPage() {
  const [state, setState] = useState<PageState>("loading");
  const [errorMsg, setErrorMsg] = useState("");
  const [userId, setUserId] = useState<string | null>(null);
  const router = useRouter();

  function getSupabase() {
    return createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
  }

  useEffect(() => {
    async function init() {
      const supabase = getSupabase();
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (!session) {
        setState("no-auth");
        return;
      }

      setUserId(session.user.id);

      // Check if already premium via RevenueCat
      try {
        const rc = initRevenueCat(session.user.id);
        const isPremium = await checkEntitlement(rc);
        if (isPremium) {
          setState("already-pro");
          return;
        }
      } catch {
        // RC not configured yet or error — fall through to pricing
      }

      setState("pricing");
    }
    init();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  async function handlePurchase(productId: string) {
    if (!userId) return;
    setState("purchasing");
    setErrorMsg("");

    try {
      const rc = initRevenueCat(userId);
      await purchasePackage(rc, productId);
      setState("success");
      setTimeout(() => router.push("/today"), 2000);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Purchase failed. Please try again.";
      setErrorMsg(message);
      setState("error");
    }
  }

  if (state === "loading") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black">
        <div className="text-center">
          <Image src="/logo.png" alt="" width={48} height={48} className="mx-auto animate-pulse drop-shadow-lg" />
          <p className="mt-3 text-sm text-[var(--text-secondary)]">Loading...</p>
        </div>
      </div>
    );
  }

  if (state === "no-auth") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black px-4">
        <div className="w-full max-w-sm text-center">
          <Image src="/logo.png" alt="" width={64} height={64} className="mx-auto drop-shadow-lg" />
          <h1 className="mt-4 text-2xl font-black text-white">Get Pro</h1>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            Sign up or log in first, then come back to subscribe.
          </p>
          <div className="mt-6 flex flex-col items-center gap-3">
            <Link
              href="/signup?next=/pro"
              className="pressable rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)]"
            >
              Sign Up Free
            </Link>
            <Link href="/login?next=/pro" className="text-sm text-[var(--accent)] hover:underline">
              Already have an account? Log in
            </Link>
          </div>
        </div>
      </div>
    );
  }

  if (state === "already-pro") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black px-4">
        <div className="w-full max-w-sm text-center">
          <span className="text-5xl">🏆</span>
          <h1 className="mt-4 text-2xl font-black text-white">You&apos;re Pro!</h1>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            You have full access to all 25 stories, 6 games, and 15 days of history.
          </p>
          <Link
            href="/today"
            className="pressable mt-6 inline-block rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)]"
          >
            Go to Today&apos;s Drop
          </Link>
        </div>
      </div>
    );
  }

  if (state === "success") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black px-4">
        <div className="w-full max-w-sm text-center">
          <span className="text-5xl">🎉</span>
          <h1 className="mt-4 text-2xl font-black text-white">Welcome to Pro!</h1>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            You now have full access. Redirecting...
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-black px-4">
      <div className="w-full max-w-md">
        <div className="text-center">
          <Image src="/logo.png" alt="" width={64} height={64} className="mx-auto drop-shadow-lg" />
          <h1 className="mt-4 text-3xl font-black text-white">Go Pro</h1>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            All 25 stories. All 6 games. 15 days of history. Zero limits.
          </p>
        </div>

        {/* Feature list */}
        <div className="mt-6 glass-card p-4">
          <ul className="space-y-2 text-sm text-zinc-300">
            {[
              "Read all 25 daily stories (not just 15)",
              "Play all 6 AI-powered daily games",
              "15 days of archive history",
              "Support independent journalism",
            ].map((f) => (
              <li key={f} className="flex items-start gap-2">
                <span className="mt-0.5 text-[var(--accent)]">✓</span>
                {f}
              </li>
            ))}
          </ul>
        </div>

        {/* Plan cards */}
        <div className="mt-6 grid gap-3 sm:grid-cols-2">
          <button
            onClick={() => handlePurchase("tdp_monthly")}
            disabled={state === "purchasing"}
            className="pressable glass-card p-5 text-left transition hover:border-[var(--accent)]/30 disabled:opacity-50"
          >
            <div className="text-xs font-bold uppercase tracking-wide text-[var(--text-tertiary)]">Monthly</div>
            <div className="mt-2 text-2xl font-black text-white">
              $7.99<span className="text-sm font-normal text-[var(--text-secondary)]">/mo</span>
            </div>
            <div className="mt-1 text-xs text-[var(--text-tertiary)]">Cancel anytime</div>
          </button>

          <button
            onClick={() => handlePurchase("tdp_annual")}
            disabled={state === "purchasing"}
            className="pressable glass-card border-[var(--accent)]/30 p-5 text-left transition hover:border-[var(--accent)]/50 disabled:opacity-50"
          >
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold uppercase tracking-wide text-[var(--accent)]">Annual</span>
              <span className="rounded-full bg-[var(--accent)]/20 px-2 py-0.5 text-[10px] font-bold text-[var(--accent)]">
                SAVE 37%
              </span>
            </div>
            <div className="mt-2 text-2xl font-black text-white">
              $59.99<span className="text-sm font-normal text-[var(--text-secondary)]">/yr</span>
            </div>
            <div className="mt-1 text-xs text-[var(--text-tertiary)]">$5/mo billed annually</div>
          </button>
        </div>

        {state === "purchasing" && (
          <p className="mt-4 text-center text-sm text-[var(--text-secondary)] animate-pulse">
            Processing...
          </p>
        )}

        {state === "error" && (
          <div className="mt-4 rounded-lg border border-red-500/30 bg-red-500/10 p-3 text-center">
            <p className="text-sm text-red-400">{errorMsg}</p>
            <button
              onClick={() => setState("pricing")}
              className="mt-2 text-xs font-bold text-[var(--accent)] hover:underline"
            >
              Try again
            </button>
          </div>
        )}

        <p className="mt-6 text-center text-xs text-[var(--text-tertiary)]">
          7-day free trial included. Cancel anytime.
        </p>

        <div className="mt-4 text-center">
          <Link href="/today" className="text-sm text-[var(--text-secondary)] hover:text-white transition">
            &larr; Back to today
          </Link>
        </div>
      </div>
    </div>
  );
}
