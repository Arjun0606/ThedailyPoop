"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import { createBrowserClient } from "@supabase/ssr";

interface Headline {
  headline: string;
}

interface GameData {
  id: string;
  publishDate: string;
  headlines: Headline[];
  headlineCount: number;
  played: boolean;
  userScore: { score: number; total: number; answers: ScoredAnswer[] } | null;
}

interface ScoredAnswer {
  headline: string;
  guessedReal: boolean;
  wasReal: boolean;
  correct: boolean;
}

export default function PoopOrScoopPage() {
  const [game, setGame] = useState<GameData | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState<
    { headline: string; guessedReal: boolean }[]
  >([]);
  const [results, setResults] = useState<ScoredAnswer[] | null>(null);
  const [score, setScore] = useState<{ score: number; total: number } | null>(
    null
  );
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState<string | null>(null);
  const [noAuth, setNoAuth] = useState(false);

  const supabase = createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );

  useEffect(() => {
    async function init() {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (!session) {
        setNoAuth(true);
        setLoading(false);
        return;
      }

      setUserId(session.user.id);

      const res = await fetch(
        `/api/games/scoop/today?userId=${session.user.id}`
      );
      const data = await res.json();

      if (data.game) {
        setGame(data.game);
        if (data.game.played && data.game.userScore) {
          setScore({
            score: data.game.userScore.score,
            total: data.game.userScore.total,
          });
          setResults(data.game.userScore.answers);
        }
      }
      setLoading(false);
    }
    init();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const handleGuess = useCallback(
    async (guessedReal: boolean) => {
      if (!game) return;

      const headline = game.headlines[currentIndex].headline;
      const newAnswers = [...answers, { headline, guessedReal }];
      setAnswers(newAnswers);

      if (currentIndex < game.headlines.length - 1) {
        setCurrentIndex(currentIndex + 1);
      } else {
        // Submit
        const {
          data: { session },
        } = await supabase.auth.getSession();

        const res = await fetch("/api/games/scoop/submit", {
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
        if (data.answers) {
          setResults(data.answers);
          setScore({ score: data.score, total: data.total });
        }
      }
    },
    [game, currentIndex, answers, userId, supabase]
  );

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black">
        <div className="text-center">
          <span className="text-4xl">💩</span>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            Loading game...
          </p>
        </div>
      </div>
    );
  }

  if (noAuth) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black px-4">
        <div className="w-full max-w-sm text-center">
          <span className="text-5xl">💩</span>
          <h1 className="mt-4 text-2xl font-black text-white">
            Poop or Scoop
          </h1>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            Sign up for a free account to play. Real headline or AI-generated
            BS? You decide.
          </p>
          <div className="mt-6 flex flex-col items-center gap-3">
            <Link
              href="/signup"
              className="rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:brightness-110"
            >
              Sign Up Free to Play
            </Link>
            <Link
              href="/games"
              className="text-sm text-[var(--text-secondary)] hover:text-white"
            >
              &larr; Back to games
            </Link>
          </div>
        </div>
      </div>
    );
  }

  if (!game) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black">
        <div className="text-center">
          <span className="text-4xl">💩</span>
          <p className="mt-2 text-lg font-bold text-white">
            No game available today
          </p>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            Check back when the next drop hits.
          </p>
          <Link
            href="/games"
            className="mt-4 inline-block text-sm text-[var(--accent)] hover:underline"
          >
            &larr; Back to games
          </Link>
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
          <Link
            href="/games"
            className="mb-6 inline-flex items-center gap-1 text-sm text-[var(--text-secondary)] hover:text-white transition"
          >
            &larr; Back to games
          </Link>

          <div className="text-center">
            <span className="text-5xl">{pct >= 80 ? "🏆" : pct >= 50 ? "👍" : "💩"}</span>
            <h1 className="mt-3 text-2xl font-black text-white">
              {score.score}/{score.total}
            </h1>
            <p className="text-sm text-[var(--text-secondary)]">
              {pct >= 80
                ? "You know your shit!"
                : pct >= 50
                  ? "Not bad, but the AI fooled you."
                  : "The AI owned you. Try again tomorrow."}
            </p>
          </div>

          <div className="mt-8 space-y-3">
            {results.map((r, i) => (
              <div
                key={i}
                className={`rounded-xl border p-4 ${
                  r.correct
                    ? "border-green-500/30 bg-green-500/5"
                    : "border-red-500/30 bg-red-500/5"
                }`}
              >
                <p className="text-sm font-medium text-white">{r.headline}</p>
                <div className="mt-1 flex items-center gap-2 text-xs">
                  <span className={r.correct ? "text-green-400" : "text-red-400"}>
                    {r.correct ? "Correct" : "Wrong"}
                  </span>
                  <span className="text-[var(--text-tertiary)]">·</span>
                  <span className="text-[var(--text-secondary)]">
                    {r.wasReal ? "Real headline" : "AI-generated"}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // Game play screen
  const headline = game.headlines[currentIndex];
  const progress = `${currentIndex + 1}/${game.headlines.length}`;

  return (
    <div className="min-h-screen bg-black px-4 py-8">
      <div className="mx-auto max-w-lg">
        <Link
          href="/games"
          className="mb-6 inline-flex items-center gap-1 text-sm text-[var(--text-secondary)] hover:text-white transition"
        >
          &larr; Back to games
        </Link>

        <div className="text-center">
          <span className="text-4xl">💩</span>
          <h1 className="mt-2 text-xl font-black text-white">
            Poop or Scoop?
          </h1>
          <p className="mt-1 text-xs text-[var(--text-tertiary)]">
            {progress}
          </p>
        </div>

        {/* Progress bar */}
        <div className="mt-4 h-1 rounded-full bg-white/[0.06]">
          <div
            className="h-1 rounded-full bg-[var(--accent)] transition-all"
            style={{
              width: `${((currentIndex + 1) / game.headlines.length) * 100}%`,
            }}
          />
        </div>

        {/* Headline card */}
        <div className="mt-8 rounded-2xl border border-white/[0.06] bg-[var(--card-bg)] p-6">
          <p className="text-lg font-bold leading-snug text-white">
            &ldquo;{headline.headline}&rdquo;
          </p>
        </div>

        {/* Buttons */}
        <div className="mt-6 grid grid-cols-2 gap-4">
          <button
            onClick={() => handleGuess(false)}
            className="rounded-xl border border-red-500/30 bg-red-500/10 py-4 text-sm font-bold text-red-400 transition hover:bg-red-500/20"
          >
            💩 Poop (Fake)
          </button>
          <button
            onClick={() => handleGuess(true)}
            className="rounded-xl border border-green-500/30 bg-green-500/10 py-4 text-sm font-bold text-green-400 transition hover:bg-green-500/20"
          >
            🍦 Scoop (Real)
          </button>
        </div>
      </div>
    </div>
  );
}
