import { createServiceClient } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import StoryCard from "@/components/StoryCard";
import StoryCTA from "@/components/StoryCTA";
import NewsletterForm from "@/components/NewsletterForm";
import Link from "next/link";

async function getTodayStories() {
  const db = createServiceClient();
  const today = new Date().toLocaleDateString("en-CA", {
    timeZone: "America/New_York",
  });

  let { data: briefings } = await db
    .from("briefings")
    .select("id")
    .eq("publish_date", today)
    .eq("status", "published");

  if (!briefings?.length) {
    const { data: latest } = await db
      .from("briefings")
      .select("id")
      .eq("status", "published")
      .order("publish_date", { ascending: false })
      .limit(1);
    briefings = latest;
  }

  if (!briefings?.length) return [];

  const { data: stories } = await db
    .from("stories")
    .select("*")
    .in(
      "briefing_id",
      briefings.map((b) => b.id)
    )
    .order("sort_order", { ascending: true })
    .limit(12);

  return stories ?? [];
}

export const dynamic = "force-dynamic";

export default async function Home() {
  const stories = await getTodayStories();

  return (
    <div className="min-h-screen bg-black">
      <Header />

      {/* Hero — full-bleed with ambient glow */}
      <section className="relative overflow-hidden border-b border-white/[0.04]">
        {/* Ambient glow */}
        <div className="pointer-events-none absolute inset-0">
          <div className="absolute left-1/2 top-1/2 h-[600px] w-[800px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[var(--accent)]/[0.04] blur-[120px]" />
        </div>

        <div className="relative px-5 py-20 text-center sm:px-8 sm:py-28 lg:px-12">
          <p className="text-[13px] font-bold uppercase tracking-[0.2em] text-[var(--accent)]">
            Daily Satirical Briefing
          </p>
          <h1 className="mx-auto mt-4 max-w-2xl text-4xl font-black leading-[1.1] tracking-tight text-white sm:text-6xl">
            News That Doesn&apos;t Suck
          </h1>
          <p className="mx-auto mt-5 max-w-md text-base text-zinc-400 leading-relaxed">
            25 stories a day. Zero boring ones. Dark satirical takes that
            actually make you laugh.
          </p>
          <div className="mt-8 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
            <a
              href="https://apps.apple.com/app/thedailypoop/id6738030377"
              target="_blank"
              rel="noopener noreferrer"
              className="pressable inline-flex items-center gap-2 rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)]"
            >
              <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
              Download Free
            </a>
            <Link
              href="/today"
              className="pressable rounded-full border border-white/[0.12] px-6 py-2.5 text-sm font-medium text-white transition hover:bg-white/[0.06]"
            >
              Read Today&apos;s Drop
            </Link>
          </div>
        </div>
      </section>

      <main className="px-5 sm:px-8 lg:px-12">
        {/* Today's Stories */}
        {stories.length > 0 && (
          <section className="mx-auto max-w-6xl py-12">
            <div className="mb-6 flex items-center justify-between">
              <h2 className="text-lg font-black text-white">
                Today&apos;s Drop
              </h2>
              <Link
                href="/today"
                className="text-[13px] font-medium text-[var(--accent)] hover:underline"
              >
                See all &rarr;
              </Link>
            </div>

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {stories.slice(0, 6).map((story) => (
                <StoryCard key={story.id} story={story} />
              ))}
            </div>

            {stories.length > 6 && (
              <div className="mt-8 text-center">
                <Link
                  href="/today"
                  className="text-sm font-medium text-[var(--accent)] hover:underline"
                >
                  View all {stories.length}+ stories &rarr;
                </Link>
              </div>
            )}
          </section>
        )}

        {/* App CTA */}
        <section className="mx-auto max-w-6xl pb-12">
          <StoryCTA />
        </section>

        {/* Newsletter */}
        <section className="mx-auto max-w-6xl pb-16">
          <div className="glass-card overflow-hidden">
            <div className="bg-gradient-to-r from-[var(--accent)]/10 to-transparent p-6 sm:p-8">
              <div className="sm:flex sm:items-start sm:gap-8">
                <div className="flex-1">
                  <div className="inline-block rounded-full bg-[var(--accent)]/15 px-3 py-1 text-[10px] font-bold uppercase tracking-wider text-[var(--accent)]">
                    Free Daily Email
                  </div>
                  <h2 className="mt-3 text-xl font-black text-white sm:text-2xl">
                    Your Morning Briefing, Delivered
                  </h2>
                  <p className="mt-2 text-sm text-[var(--text-secondary)] leading-relaxed">
                    All 25 stories + newsletter-exclusive sections you won&apos;t find
                    anywhere else. 7:30 AM ET, every morning.
                  </p>
                  <div className="mt-3 flex flex-wrap gap-3 text-xs text-[var(--text-tertiary)]">
                    <span>The Number</span>
                    <span>&middot;</span>
                    <span>The Bottom Line</span>
                    <span>&middot;</span>
                    <span>Quick Hits</span>
                    <span>&middot;</span>
                    <span>Top 5 Deep Dives</span>
                  </div>
                </div>
                <div className="mt-5 sm:mt-0 sm:w-80">
                  <NewsletterForm />
                  <p className="mt-2 text-center text-[11px] text-[var(--text-tertiary)]">
                    Free forever. Unsubscribe anytime. No spam, ever.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  );
}
