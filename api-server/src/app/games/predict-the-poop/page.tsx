"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { createBrowserClient } from "@supabase/ssr";

interface Prediction {
  id: string;
  publishDate: string;
  question: string;
  context: string;
  resolveBy: string;
  resolvedAnswer: boolean | null;
  userBet: boolean | null;
}

export default function PredictThePoopPage() {
  const [predictions, setPredictions] = useState<Prediction[]>([]);
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState<string | null>(null);
  const [noAuth, setNoAuth] = useState(false);
  const [betting, setBetting] = useState<string | null>(null);

  function getSupabase() {
    return createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
  }

  useEffect(() => {
    async function init() {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();

      if (!session) {
        setNoAuth(true);
        setLoading(false);
        return;
      }

      setUserId(session.user.id);

      const res = await fetch(`/api/games/predictions/today?userId=${session.user.id}`);
      const data = await res.json();

      if (data.predictions) {
        setPredictions(data.predictions);
      }
      setLoading(false);
    }
    init();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  async function handleBet(predictionId: string, bet: boolean) {
    if (!userId) return;
    setBetting(predictionId);

    const { data: { session } } = await getSupabase().auth.getSession();

    const res = await fetch("/api/games/predictions/bet", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${session?.access_token}`,
      },
      body: JSON.stringify({ userId, predictionId, bet }),
    });

    if (res.ok) {
      setPredictions((prev) =>
        prev.map((p) => (p.id === predictionId ? { ...p, userBet: bet } : p))
      );
    }
    setBetting(null);
  }

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black">
        <div className="text-center">
          <Image src="/logo.png" alt="" width={48} height={48} className="mx-auto drop-shadow-lg animate-pulse" />
          <p className="mt-3 text-sm text-[var(--text-secondary)]">Loading game...</p>
        </div>
      </div>
    );
  }

  if (noAuth) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black px-4">
        <div className="w-full max-w-sm text-center">
          <Image src="/logo.png" alt="" width={64} height={64} className="mx-auto drop-shadow-lg" />
          <h1 className="mt-4 text-2xl font-black text-white">Predict the Poop</h1>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            Bet on tomorrow&apos;s headlines. Get points when you&apos;re right. Pro subscribers only.
          </p>
          <div className="mt-6 flex flex-col items-center gap-3">
            <Link href="/pro" className="pressable rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)]">
              Get Pro to Play
            </Link>
            <Link href="/games" className="text-sm text-[var(--text-secondary)] hover:text-white">&larr; Back to games</Link>
          </div>
        </div>
      </div>
    );
  }

  if (!predictions.length) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black">
        <div className="text-center">
          <Image src="/logo.png" alt="" width={48} height={48} className="mx-auto drop-shadow-lg" />
          <p className="mt-3 text-lg font-bold text-white">No predictions today</p>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">Check back when the next drop hits.</p>
          <Link href="/games" className="mt-4 inline-block text-sm text-[var(--accent)] hover:underline">&larr; Back to games</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-black px-4 py-8">
      <div className="mx-auto max-w-lg">
        <Link href="/games" className="mb-6 inline-flex items-center gap-1 text-sm text-[var(--text-secondary)] hover:text-white transition">&larr; Back to games</Link>

        <div className="text-center">
          <Image src="/logo.png" alt="" width={48} height={48} className="mx-auto drop-shadow-lg" />
          <h1 className="mt-2 text-xl font-black text-white">Predict the Poop</h1>
          <p className="mt-1 text-xs text-[var(--text-tertiary)]">{predictions.length} prediction{predictions.length !== 1 ? "s" : ""} today</p>
        </div>

        <div className="mt-8 space-y-4">
          {predictions.map((p) => {
            const hasBet = p.userBet !== null;
            const isResolved = p.resolvedAnswer !== null;
            const wasCorrect = isResolved && hasBet && p.userBet === p.resolvedAnswer;

            return (
              <div
                key={p.id}
                className={`glass-card p-5 ${isResolved ? (wasCorrect ? "border-green-500/30" : "border-red-500/30") : ""}`}
              >
                <h3 className="text-base font-bold text-white leading-snug">{p.question}</h3>
                <p className="mt-2 text-sm text-[var(--text-secondary)] leading-relaxed">{p.context}</p>

                {isResolved && (
                  <div className={`mt-3 rounded-lg px-3 py-2 text-xs font-bold ${wasCorrect ? "bg-green-500/10 text-green-400" : "bg-red-500/10 text-red-400"}`}>
                    {wasCorrect ? "You got it right!" : "Wrong call."} Answer: {p.resolvedAnswer ? "Yes" : "No"}
                  </div>
                )}

                {!hasBet && !isResolved ? (
                  <div className="mt-4 grid grid-cols-2 gap-3">
                    <button
                      onClick={() => handleBet(p.id, true)}
                      disabled={betting === p.id}
                      className="pressable rounded-xl border border-green-500/30 bg-green-500/10 py-3 text-sm font-bold text-green-400 transition hover:bg-green-500/20 disabled:opacity-50"
                    >
                      Yes
                    </button>
                    <button
                      onClick={() => handleBet(p.id, false)}
                      disabled={betting === p.id}
                      className="pressable rounded-xl border border-red-500/30 bg-red-500/10 py-3 text-sm font-bold text-red-400 transition hover:bg-red-500/20 disabled:opacity-50"
                    >
                      No
                    </button>
                  </div>
                ) : hasBet && !isResolved ? (
                  <div className="mt-3 text-xs text-[var(--text-tertiary)]">
                    You bet: <strong className={p.userBet ? "text-green-400" : "text-red-400"}>{p.userBet ? "Yes" : "No"}</strong>
                    <span className="ml-2">· Resolves by {new Date(p.resolveBy).toLocaleDateString()}</span>
                  </div>
                ) : null}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
