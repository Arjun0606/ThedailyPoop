import { Metadata } from "next";
import { createServiceClient } from "@/lib/supabase";
import { getWebSession } from "@/lib/web-auth";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Archive",
  description: "Browse past daily drops from TheDailyPoop.",
};

export const dynamic = "force-dynamic";

async function getArchive() {
  const db = createServiceClient();

  const { data: briefings, error } = await db
    .from("briefings")
    .select("id, publish_date, vibe_label, vibe_emoji, status")
    .eq("status", "published")
    .order("publish_date", { ascending: false })
    .limit(60);

  if (error) {
    console.error("Archive fetch error:", error);
  }

  const rows = briefings ?? [];
  const byDate: Record<string, typeof rows> = {};
  for (const b of rows) {
    (byDate[b.publish_date] ??= []).push(b);
  }

  return Object.entries(byDate).map(([date, drops]) => ({
    date,
    drops,
    formatted: new Date(date + "T12:00:00").toLocaleDateString("en-US", {
      weekday: "short",
      month: "short",
      day: "numeric",
    }),
  }));
}

function daysAgo(dateStr: string): number {
  const now = new Date();
  const d = new Date(dateStr + "T12:00:00");
  return Math.floor((now.getTime() - d.getTime()) / (1000 * 60 * 60 * 24));
}

export default async function ArchivePage() {
  const dates = await getArchive();
  const session = await getWebSession();

  // No account: today only (0 days)
  // Free account: 3 days
  // Pro: 15 days
  const maxDays = session?.isPremium ? 15 : session ? 3 : 0;

  const accessibleDates = dates.filter((d) => daysAgo(d.date) <= maxDays);
  const lockedDates = dates.filter((d) => daysAgo(d.date) > maxDays);

  return (
    <div className="min-h-screen bg-black">
      <Header />

      <main className="mx-auto max-w-3xl px-4 py-8 sm:px-5">
        <h1 className="mb-8 text-2xl font-black text-white sm:text-3xl">
          Archive
        </h1>

        {dates.length === 0 ? (
          <div className="rounded-2xl border border-white/[0.06] bg-[var(--card-bg)] p-12 text-center">
            <p className="text-4xl">💩</p>
            <p className="mt-3 text-lg font-bold text-white">
              No archives yet
            </p>
          </div>
        ) : (
          <>
            {/* Accessible dates */}
            <div className="space-y-2">
              {accessibleDates.map(({ date, formatted, drops }) => (
                <Link
                  key={date}
                  href={`/today?date=${date}`}
                  className="group flex items-center justify-between rounded-xl border border-white/[0.06] bg-[var(--card-bg)] px-5 py-4 transition hover:border-white/[0.12]"
                >
                  <div>
                    <p className="font-bold text-white group-hover:text-[var(--accent)] transition">
                      {formatted}
                    </p>
                    <p className="mt-0.5 text-xs text-[var(--text-tertiary)]">
                      {drops.length} drop{drops.length > 1 ? "s" : ""}
                      {drops[0]?.vibe_label &&
                        ` · ${drops[0].vibe_emoji || ""} ${drops[0].vibe_label}`}
                    </p>
                  </div>
                  <span className="text-[var(--text-tertiary)] group-hover:text-white transition">
                    &rarr;
                  </span>
                </Link>
              ))}
            </div>

            {/* Locked dates + upgrade CTA */}
            {lockedDates.length > 0 && (
              <div className="mt-6">
                <div className="space-y-2 opacity-40">
                  {lockedDates.slice(0, 3).map(({ date, formatted, drops }) => (
                    <div
                      key={date}
                      className="flex items-center justify-between rounded-xl border border-white/[0.06] bg-[var(--card-bg)] px-5 py-4"
                    >
                      <div>
                        <p className="font-bold text-white">{formatted}</p>
                        <p className="mt-0.5 text-xs text-[var(--text-tertiary)]">
                          {drops.length} drop{drops.length > 1 ? "s" : ""}
                          {drops[0]?.vibe_label &&
                            ` · ${drops[0].vibe_emoji || ""} ${drops[0].vibe_label}`}
                        </p>
                      </div>
                      <span className="text-lg">🔒</span>
                    </div>
                  ))}
                </div>

                <div className="mt-4 rounded-2xl border border-[var(--accent)]/20 bg-[var(--accent-dim)] p-5 text-center">
                  <span className="text-2xl">🔒</span>
                  {!session ? (
                    <>
                      <p className="mt-2 text-sm font-bold text-white">
                        Sign up free to access 3 days of history
                      </p>
                      <Link
                        href="/signup"
                        className="mt-3 inline-block rounded-full bg-[var(--accent)] px-5 py-2 text-sm font-bold text-black transition hover:brightness-110"
                      >
                        Sign Up Free
                      </Link>
                    </>
                  ) : !session.isPremium ? (
                    <>
                      <p className="mt-2 text-sm font-bold text-white">
                        Go Pro to access 15 days of history
                      </p>
                      <p className="mt-1 text-xs text-[var(--text-secondary)]">
                        {lockedDates.length} more day
                        {lockedDates.length > 1 ? "s" : ""} of drops waiting
                      </p>
                      <a
                        href="https://apps.apple.com/app/thedailypoop/id6738030377"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="mt-3 inline-block rounded-full bg-[var(--accent)] px-5 py-2 text-sm font-bold text-black transition hover:brightness-110"
                      >
                        Get Pro — $7.99/mo
                      </a>
                    </>
                  ) : (
                    <p className="mt-2 text-sm text-[var(--text-secondary)]">
                      Pro includes 15 days of history. Older drops are archived.
                    </p>
                  )}
                </div>
              </div>
            )}
          </>
        )}
      </main>

      <Footer />
    </div>
  );
}
