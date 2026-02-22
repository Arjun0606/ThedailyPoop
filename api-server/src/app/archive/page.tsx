import { Metadata } from "next";
import { createServiceClient } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Archive",
  description: "Browse past daily drops from TheDailyPoop.",
};

export const revalidate = 3600;

async function getArchive() {
  const db = createServiceClient();

  const { data: briefings } = await db
    .from("briefings")
    .select("id, publish_date, vibe_label, vibe_emoji, status")
    .eq("status", "published")
    .order("publish_date", { ascending: false })
    .limit(60);

  // Group by date
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

export default async function ArchivePage() {
  const dates = await getArchive();

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
          <div className="space-y-2">
            {dates.map(({ date, formatted, drops }) => (
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
                    {drops[0]?.vibe_label && ` · ${drops[0].vibe_emoji || ""} ${drops[0].vibe_label}`}
                  </p>
                </div>
                <span className="text-[var(--text-tertiary)] group-hover:text-white transition">
                  &rarr;
                </span>
              </Link>
            ))}
          </div>
        )}
      </main>

      <Footer />
    </div>
  );
}
