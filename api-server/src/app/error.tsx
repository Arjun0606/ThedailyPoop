"use client";

import Link from "next/link";

export default function Error({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-black px-4 text-center">
      <span className="text-6xl">💀</span>
      <h1 className="mt-4 text-3xl font-black text-white">Something broke</h1>
      <p className="mt-2 text-sm text-zinc-500">
        We pooped the bed. Try again or head back to today&apos;s stories.
      </p>
      <div className="mt-6 flex gap-3">
        <button
          onClick={reset}
          className="pressable rounded-full border border-white/[0.12] px-5 py-2.5 text-sm font-medium text-white transition hover:bg-white/[0.06]"
        >
          Try again
        </button>
        <Link
          href="/today"
          className="pressable rounded-full bg-[var(--accent)] px-5 py-2.5 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)]"
        >
          Back to today
        </Link>
      </div>
    </div>
  );
}
