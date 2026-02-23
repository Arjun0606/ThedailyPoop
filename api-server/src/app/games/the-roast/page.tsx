"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { createBrowserClient } from "@supabase/ssr";

interface RoastEntry {
  id: string;
  user_id: string;
  username: string;
  text: string;
  ai_score: number;
  upvotes: number;
  created_at: string;
}

interface RoastData {
  id: string;
  publishDate: string;
  storyHeadline: string;
  storySummary: string;
  userEntry: RoastEntry | null;
  topEntries: RoastEntry[];
}

export default function TheRoastPage() {
  const [roast, setRoast] = useState<RoastData | null>(null);
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState<string | null>(null);
  const [noAuth, setNoAuth] = useState(false);
  const [text, setText] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [userEntry, setUserEntry] = useState<RoastEntry | null>(null);
  const [entries, setEntries] = useState<RoastEntry[]>([]);
  const [votedIds, setVotedIds] = useState<Set<string>>(new Set());

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

      const res = await fetch(`/api/games/roast/today?userId=${session.user.id}`);
      const data = await res.json();

      if (data.roast) {
        setRoast(data.roast);
        setUserEntry(data.roast.userEntry);
        setEntries(data.roast.topEntries || []);
      }
      setLoading(false);
    }
    init();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  async function handleSubmit() {
    if (!roast || !text.trim() || !userId) return;
    setSubmitting(true);

    const { data: { session } } = await getSupabase().auth.getSession();

    const res = await fetch("/api/games/roast/submit", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${session?.access_token}`,
      },
      body: JSON.stringify({
        userId,
        roastId: roast.id,
        text: text.trim(),
      }),
    });

    const data = await res.json();
    if (data.entry) {
      setUserEntry(data.entry);
      setText("");
    }
    setSubmitting(false);
  }

  async function handleUpvote(entryId: string) {
    if (votedIds.has(entryId) || !userId) return;

    const { data: { session } } = await getSupabase().auth.getSession();

    setVotedIds((prev) => new Set(prev).add(entryId));
    setEntries((prev) =>
      prev.map((e) => (e.id === entryId ? { ...e, upvotes: e.upvotes + 1 } : e))
    );

    await fetch("/api/games/roast/upvote", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${session?.access_token}`,
      },
      body: JSON.stringify({ userId, entryId }),
    });
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
          <h1 className="mt-4 text-2xl font-black text-white">The Roast</h1>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            Write the best roast for today&apos;s newsmaker. Community votes. Pro subscribers only.
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

  if (!roast) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black">
        <div className="text-center">
          <Image src="/logo.png" alt="" width={48} height={48} className="mx-auto drop-shadow-lg" />
          <p className="mt-3 text-lg font-bold text-white">No roast prompt today</p>
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
          <h1 className="mt-2 text-xl font-black text-white">The Roast</h1>
        </div>

        {/* Prompt */}
        <div className="mt-6 glass-card p-6">
          <p className="text-xs font-bold uppercase tracking-wide text-[var(--accent)] mb-2">Today&apos;s Target</p>
          <h2 className="text-lg font-black text-white leading-snug">{roast.storyHeadline}</h2>
          <p className="mt-2 text-sm text-[var(--text-secondary)] leading-relaxed">{roast.storySummary}</p>
        </div>

        {/* Write roast or show user's entry */}
        {userEntry ? (
          <div className="mt-6 glass-card border-[var(--accent)]/30 p-4">
            <p className="text-xs font-bold text-[var(--accent)] mb-1">Your Roast</p>
            <p className="text-sm text-white">{userEntry.text}</p>
            <div className="mt-2 flex items-center gap-3 text-xs text-[var(--text-tertiary)]">
              <span>&#9650; {userEntry.upvotes}</span>
            </div>
          </div>
        ) : (
          <div className="mt-6">
            <textarea
              value={text}
              onChange={(e) => setText(e.target.value.slice(0, 280))}
              placeholder="Write your best roast..."
              className="w-full rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-white placeholder-zinc-600 outline-none backdrop-blur-md focus:border-[var(--accent)]/30 resize-none"
              rows={3}
            />
            <div className="mt-2 flex items-center justify-between">
              <span className="text-xs text-[var(--text-tertiary)]">{text.length}/280</span>
              <button
                onClick={handleSubmit}
                disabled={!text.trim() || submitting}
                className="pressable rounded-full bg-[var(--accent)] px-5 py-2 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)] disabled:opacity-50"
              >
                {submitting ? "Submitting..." : "Submit Roast"}
              </button>
            </div>
          </div>
        )}

        {/* Community leaderboard */}
        {entries.length > 0 && (
          <div className="mt-8">
            <h3 className="text-xs font-bold uppercase tracking-wide text-[var(--text-tertiary)] mb-3">Community Roasts</h3>
            <div className="space-y-2">
              {entries.map((entry, i) => (
                <div key={entry.id} className="glass-card flex gap-3 p-4">
                  <button
                    onClick={() => handleUpvote(entry.id)}
                    disabled={votedIds.has(entry.id) || entry.user_id === userId}
                    className="flex flex-col items-center gap-0.5 text-xs transition disabled:opacity-40"
                  >
                    <span className={votedIds.has(entry.id) ? "text-[var(--accent)]" : "text-[var(--text-tertiary)] hover:text-white"}>&#9650;</span>
                    <span className={votedIds.has(entry.id) ? "font-bold text-[var(--accent)]" : "text-[var(--text-tertiary)]"}>{entry.upvotes}</span>
                  </button>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-white">{entry.text}</p>
                    <div className="mt-1 flex items-center gap-2 text-xs text-[var(--text-tertiary)]">
                      {i === 0 && <span className="text-[var(--accent)]">&#x1F451;</span>}
                      <span>{entry.username}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
