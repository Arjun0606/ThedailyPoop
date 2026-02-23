"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { createBrowserClient } from "@supabase/ssr";

export default function SignupPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [appleLoading, setAppleLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  function getSupabase() {
    return createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
  }

  async function handleSignup(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    const { error } = await getSupabase().auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/api/auth/callback`,
      },
    });

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    setSuccess(true);
    setLoading(false);
  }

  async function handleAppleSignup() {
    setError("");
    setAppleLoading(true);

    const { error } = await getSupabase().auth.signInWithOAuth({
      provider: "apple",
      options: {
        redirectTo: `${window.location.origin}/api/auth/callback`,
      },
    });

    if (error) {
      setError(error.message);
      setAppleLoading(false);
    }
  }

  if (success) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black px-4">
        <div className="w-full max-w-sm text-center">
          <span className="text-4xl">📬</span>
          <h1 className="mt-4 text-2xl font-black text-white">Check your email</h1>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            We sent a confirmation link to <strong className="text-white">{email}</strong>.
            Click it to activate your account.
          </p>
          <Link
            href="/"
            className="mt-6 inline-block text-sm font-medium text-[var(--accent)] hover:underline"
          >
            Back to home
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-black px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 text-center">
          <Link href="/" className="inline-block">
            <Image
              src="/logo.png"
              alt="TheDailyPoop"
              width={64}
              height={64}
              className="mx-auto drop-shadow-lg"
            />
          </Link>
          <h1 className="mt-4 text-2xl font-black text-white">Create an account</h1>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            Free — unlocks Poop or Scoop &amp; 3 days of history
          </p>
        </div>

        {/* Apple Sign In */}
        <button
          onClick={handleAppleSignup}
          disabled={appleLoading}
          className="pressable flex w-full items-center justify-center gap-2.5 rounded-xl bg-white py-3 text-sm font-semibold text-black transition hover:bg-zinc-200 disabled:opacity-50"
        >
          <svg width="17" height="17" viewBox="0 0 814 1000" fill="currentColor">
            <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57.8-155.5-127.4c-58.8-82-106.9-209.2-106.9-330.8 0-194.3 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8.7 15.6 1.3 18.2 2.6.6 6.4 1.3 10.2 1.3 45.4 0 103.5-30.4 139.5-71.4z"/>
          </svg>
          {appleLoading ? "Redirecting..." : "Continue with Apple"}
        </button>

        <div className="my-5 flex items-center gap-3">
          <div className="h-px flex-1 bg-white/[0.08]" />
          <span className="text-xs text-zinc-600">or</span>
          <div className="h-px flex-1 bg-white/[0.08]" />
        </div>

        <form onSubmit={handleSignup} className="space-y-4">
          <div>
            <label className="mb-1 block text-xs font-medium text-[var(--text-secondary)]">
              Email
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-xl border border-[var(--glass-border)] bg-[var(--glass-bg)] px-4 py-3 text-sm text-white placeholder-[var(--text-tertiary)] outline-none focus:border-[var(--accent)] backdrop-blur-md transition"
              placeholder="you@email.com"
            />
          </div>

          <div>
            <label className="mb-1 block text-xs font-medium text-[var(--text-secondary)]">
              Password
            </label>
            <input
              type="password"
              required
              minLength={6}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-xl border border-[var(--glass-border)] bg-[var(--glass-bg)] px-4 py-3 text-sm text-white placeholder-[var(--text-tertiary)] outline-none focus:border-[var(--accent)] backdrop-blur-md transition"
              placeholder="Min 6 characters"
            />
          </div>

          {error && (
            <p className="text-sm text-red-400">{error}</p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="pressable w-full rounded-xl bg-[var(--accent)] py-3 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)] disabled:opacity-50"
          >
            {loading ? "Creating account..." : "Sign Up Free"}
          </button>
        </form>

        <p className="mt-6 text-center text-sm text-[var(--text-secondary)]">
          Already have an account?{" "}
          <Link href="/login" className="font-medium text-[var(--accent)] hover:underline">
            Log in
          </Link>
        </p>
      </div>
    </div>
  );
}
