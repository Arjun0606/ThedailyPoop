"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import Image from "next/image";
import { createBrowserClient } from "@supabase/ssr";

interface Round {
  situation: string;
  correctExcuse: string;
  options: string[];
}

interface GameData {
  id: string;
  publishDate: string;
  rounds: Round[];
  played: boolean;
  userScore: { score: number; total: number } | null;
}

interface ResultItem {
  situation: string;
  correctExcuse: string;
  userAnswer: string;
  correct: boolean;
}

export default function SpinTheExcusePage() {
  const [game, setGame] = useState<GameData | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState<string[]>([]);
  const [results, setResults] = useState<ResultItem[] | null>(null);
  const [score, setScore] = useState<{ score: number; total: number } | null>(null);
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState<string | null>(null);
  const [noAuth, setNoAuth] = useState(false);

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

      const res = await fetch(`/api/games/excuse/today?userId=${session.user.id}`);
      const data = await res.json();

      if (data.game) {
        setGame(data.game);
        if (data.game.played && data.game.userScore) {
          setScore(data.game.userScore);
        }
      }
      setLoading(false);
    }
    init();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const handleAnswer = useCallback(
    async (answer: string) => {
      if (!game) return;

      const newAnswers = [...answers, answer];
      setAnswers(newAnswers);

      if (currentIndex < game.rounds.length - 1) {
        setCurrentIndex(currentIndex + 1);
      } else {
        const { data: { session } } = await getSupabase().auth.getSession();

        const res = await fetch("/api/games/excuse/submit", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${session?.access_token}`,
          },
          body: JSON.stringify({
            userId,
            gameId: game.id,
            answers: newAnswers,
          }),
        });

        const data = await res.json();
        if (data.results) {
          setResults(data.results);
          setScore({ score: data.score, total: data.total });
        }
      }
    },
    [game, currentIndex, answers, userId]
  );

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
          <h1 className="mt-4 text-2xl font-black text-white">Spin the Excuse</h1>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            Match the political situation to the real excuse they gave. Pro subscribers only.
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
    const pct = Math.round((score.score / score.total) * 100);
    return (
      <div className="min-h-screen bg-black px-4 py-8">
        <div className="mx-auto max-w-lg">
          <Link href="/games" className="mb-6 inline-flex items-center gap-1 text-sm text-[var(--text-secondary)] hover:text-white transition">&larr; Back to games</Link>

          <div className="text-center">
            <span className="text-5xl">{pct >= 80 ? "🏆" : pct >= 50 ? "👍" : "😬"}</span>
            <h1 className="mt-3 text-2xl font-black text-white">{score.score}/{score.total}</h1>
            <p className="text-sm text-[var(--text-secondary)]">
              {pct >= 80 ? "You think like a politician!" : pct >= 50 ? "Decent spin detection." : "These excuses are next level."}
            </p>
          </div>

          <div className="mt-8 space-y-3">
            {results.map((r, i) => (
              <div key={i} className={`glass-card p-4 ${r.correct ? "border-green-500/30 bg-green-500/5" : "border-red-500/30 bg-red-500/5"}`}>
                <p className="text-sm font-medium text-white">{r.situation}</p>
                <div className="mt-2 flex flex-wrap items-center gap-2 text-xs">
                  <span className={r.correct ? "text-green-400" : "text-red-400"}>{r.correct ? "Correct" : "Wrong"}</span>
                  <span className="text-[var(--text-tertiary)]">&middot;</span>
                  <span className="text-[var(--text-secondary)]">Real excuse: <strong className="text-white">{r.correctExcuse}</strong></span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // Game play
  const round = game.rounds[currentIndex];
  const progress = `${currentIndex + 1}/${game.rounds.length}`;

  return (
    <div className="min-h-screen bg-black px-4 py-8">
      <div className="mx-auto max-w-lg">
        <Link href="/games" className="mb-6 inline-flex items-center gap-1 text-sm text-[var(--text-secondary)] hover:text-white transition">&larr; Back to games</Link>

        <div className="text-center">
          <Image src="/logo.png" alt="" width={48} height={48} className="mx-auto drop-shadow-lg" />
          <h1 className="mt-2 text-xl font-black text-white">Spin the Excuse</h1>
          <p className="mt-1 text-xs text-[var(--text-tertiary)]">{progress}</p>
        </div>

        <div className="mt-4 h-1 rounded-full bg-white/[0.06]">
          <div className="h-1 rounded-full bg-[var(--accent)] transition-all" style={{ width: `${((currentIndex + 1) / game.rounds.length) * 100}%` }} />
        </div>

        <div className="mt-8 glass-card p-6">
          <p className="text-xs font-bold uppercase tracking-wide text-[var(--accent)] mb-2">The Situation</p>
          <p className="text-lg font-bold leading-snug text-white">{round.situation}</p>
          <p className="mt-3 text-xs text-[var(--text-tertiary)]">What excuse did they actually give?</p>
        </div>

        <div className="mt-6 grid gap-3">
          {round.options.map((opt) => (
            <button
              key={opt}
              onClick={() => handleAnswer(opt)}
              className="pressable glass-card px-4 py-3 text-left text-sm font-medium text-white transition hover:border-[var(--accent)]/30"
            >
              {opt}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
