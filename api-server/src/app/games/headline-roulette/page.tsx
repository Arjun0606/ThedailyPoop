"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { createBrowserClient } from "@supabase/ssr";

interface HeadlineItem {
  id: string;
  headline: string;
  insanityRank: number;
}

interface GameData {
  id: string;
  publishDate: string;
  headlines: HeadlineItem[];
  played: boolean;
  userScore: { score: number; maxScore: number } | null;
}

interface CorrectItem {
  id: string;
  headline: string;
  insanityRank: number;
}

export default function HeadlineRoulettePage() {
  const [game, setGame] = useState<GameData | null>(null);
  const [ranking, setRanking] = useState<HeadlineItem[]>([]);
  const [results, setResults] = useState<CorrectItem[] | null>(null);
  const [score, setScore] = useState<{ score: number; maxScore: number } | null>(null);
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState<string | null>(null);
  const [noAuth, setNoAuth] = useState(false);
  const [submitting, setSubmitting] = useState(false);

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

      const res = await fetch(`/api/games/headline-roulette/today?userId=${session.user.id}`);
      const data = await res.json();

      if (data.game) {
        setGame(data.game);
        // Shuffle headlines for initial display
        const shuffled = [...data.game.headlines].sort(() => Math.random() - 0.5);
        setRanking(shuffled);
        if (data.game.played && data.game.userScore) {
          setScore(data.game.userScore);
        }
      }
      setLoading(false);
    }
    init();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  function moveUp(index: number) {
    if (index === 0) return;
    const next = [...ranking];
    [next[index - 1], next[index]] = [next[index], next[index - 1]];
    setRanking(next);
  }

  function moveDown(index: number) {
    if (index === ranking.length - 1) return;
    const next = [...ranking];
    [next[index], next[index + 1]] = [next[index + 1], next[index]];
    setRanking(next);
  }

  async function handleSubmit() {
    if (!game || !userId) return;
    setSubmitting(true);

    const { data: { session } } = await getSupabase().auth.getSession();

    const res = await fetch("/api/games/headline-roulette/submit", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${session?.access_token}`,
      },
      body: JSON.stringify({
        userId,
        gameId: game.id,
        ranking: ranking.map((h) => h.id),
      }),
    });

    const data = await res.json();
    if (data.correctOrder) {
      setResults(data.correctOrder);
      setScore({ score: data.score, maxScore: data.maxScore });
    }
    setSubmitting(false);
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
          <h1 className="mt-4 text-2xl font-black text-white">Headline Roulette</h1>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            Rank 5 headlines from most to least insane. Pro subscribers only.
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

  if (!game) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black">
        <div className="text-center">
          <Image src="/logo.png" alt="" width={48} height={48} className="mx-auto drop-shadow-lg" />
          <p className="mt-3 text-lg font-bold text-white">No game available today</p>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">Check back when the next drop hits.</p>
          <Link href="/games" className="mt-4 inline-block text-sm text-[var(--accent)] hover:underline">&larr; Back to games</Link>
        </div>
      </div>
    );
  }

  // Results screen
  if (results && score) {
    const pct = Math.round((score.score / score.maxScore) * 100);

    // Build a map from headline ID to the user's rank position
    const userRankMap = new Map<string, number>();
    ranking.forEach((h, i) => userRankMap.set(h.id, i + 1));

    return (
      <div className="min-h-screen bg-black px-4 py-8">
        <div className="mx-auto max-w-lg">
          <Link href="/games" className="mb-6 inline-flex items-center gap-1 text-sm text-[var(--text-secondary)] hover:text-white transition">&larr; Back to games</Link>

          <div className="text-center">
            <span className="text-5xl">{pct >= 80 ? "🏆" : pct >= 50 ? "👍" : "😬"}</span>
            <h1 className="mt-3 text-2xl font-black text-white">{score.score}/{score.maxScore}</h1>
            <p className="text-sm text-[var(--text-secondary)]">
              {pct >= 80 ? "Insanity detector!" : pct >= 50 ? "Decent ranking skills." : "The news is too wild to rank."}
            </p>
          </div>

          <div className="mt-6 text-xs font-bold uppercase tracking-wide text-[var(--text-tertiary)] mb-3">Correct Order (Most → Least Insane)</div>
          <div className="space-y-2">
            {results.map((item, i) => {
              const userRank = userRankMap.get(item.id) ?? 0;
              const diff = Math.abs(userRank - (i + 1));
              const color = diff === 0 ? "border-green-500/30 bg-green-500/5" : diff === 1 ? "border-yellow-500/30 bg-yellow-500/5" : "border-red-500/30 bg-red-500/5";

              return (
                <div key={item.id} className={`glass-card flex items-center gap-3 p-4 ${color}`}>
                  <span className="flex h-7 w-7 items-center justify-center rounded-full bg-white/[0.06] text-xs font-bold text-white">
                    {i + 1}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-white">{item.headline}</p>
                  </div>
                  <div className="text-right text-xs">
                    <span className={diff === 0 ? "text-green-400" : diff === 1 ? "text-yellow-400" : "text-red-400"}>
                      {diff === 0 ? "Exact" : `Off by ${diff}`}
                    </span>
                    <div className="text-[var(--text-tertiary)]">You: #{userRank}</div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    );
  }

  // Game play — reorder
  return (
    <div className="min-h-screen bg-black px-4 py-8">
      <div className="mx-auto max-w-lg">
        <Link href="/games" className="mb-6 inline-flex items-center gap-1 text-sm text-[var(--text-secondary)] hover:text-white transition">&larr; Back to games</Link>

        <div className="text-center">
          <Image src="/logo.png" alt="" width={48} height={48} className="mx-auto drop-shadow-lg" />
          <h1 className="mt-2 text-xl font-black text-white">Headline Roulette</h1>
          <p className="mt-1 text-xs text-[var(--text-tertiary)]">Rank from most insane (#1) to least insane (#5)</p>
        </div>

        <div className="mt-8 space-y-2">
          {ranking.map((item, i) => (
            <div key={item.id} className="glass-card flex items-center gap-3 p-4">
              <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-[var(--accent)]/20 text-xs font-bold text-[var(--accent)]">
                {i + 1}
              </span>
              <p className="flex-1 min-w-0 text-sm font-medium text-white">{item.headline}</p>
              <div className="flex flex-col gap-1">
                <button
                  onClick={() => moveUp(i)}
                  disabled={i === 0}
                  className="rounded px-1.5 py-0.5 text-xs text-[var(--text-secondary)] transition hover:bg-white/[0.06] hover:text-white disabled:opacity-20"
                >
                  &#9650;
                </button>
                <button
                  onClick={() => moveDown(i)}
                  disabled={i === ranking.length - 1}
                  className="rounded px-1.5 py-0.5 text-xs text-[var(--text-secondary)] transition hover:bg-white/[0.06] hover:text-white disabled:opacity-20"
                >
                  &#9660;
                </button>
              </div>
            </div>
          ))}
        </div>

        <button
          onClick={handleSubmit}
          disabled={submitting}
          className="pressable mt-6 w-full rounded-full bg-[var(--accent)] py-3 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)] disabled:opacity-50"
        >
          {submitting ? "Submitting..." : "Submit Ranking"}
        </button>
      </div>
    </div>
  );
}
