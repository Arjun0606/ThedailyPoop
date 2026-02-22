"use client";

import { useState } from "react";

export default function NewsletterForm() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<
    "idle" | "loading" | "success" | "error"
  >("idle");
  const [message, setMessage] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email) return;

    setStatus("loading");
    try {
      const res = await fetch("/api/newsletter/subscribe", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();

      if (res.ok) {
        setStatus("success");
        setMessage("You're in! Check your inbox tomorrow morning.");
        setEmail("");
      } else {
        setStatus("error");
        setMessage(data.error || "Something went wrong. Try again.");
      }
    } catch {
      setStatus("error");
      setMessage("Something went wrong. Try again.");
    }
  }

  if (status === "success") {
    return (
      <div className="rounded-2xl border border-[var(--accent)]/20 bg-[var(--accent-dim)] p-6 text-center">
        <p className="text-lg font-bold text-[var(--accent)]">💩 You're in!</p>
        <p className="mt-1 text-sm text-[var(--text-secondary)]">{message}</p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-3">
      <div className="flex gap-2">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="your@email.com"
          required
          className="flex-1 rounded-xl border border-white/[0.06] bg-[var(--card-bg)] px-4 py-3 text-sm text-white placeholder:text-[var(--text-tertiary)] outline-none focus:border-[var(--accent)]/40 transition"
        />
        <button
          type="submit"
          disabled={status === "loading"}
          className="rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-black transition hover:brightness-110 disabled:opacity-50"
        >
          {status === "loading" ? "..." : "Subscribe"}
        </button>
      </div>
      {status === "error" && (
        <p className="text-xs text-red-400">{message}</p>
      )}
      <p className="text-xs text-[var(--text-tertiary)]">
        Free daily briefing every morning. Unsubscribe anytime.
      </p>
    </form>
  );
}
