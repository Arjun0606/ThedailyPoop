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
  const leadStory = stories[0];
  const restStories = stories.slice(1, 7);

  return (
    <div className="min-h-screen bg-black">
      <Header />

      <main className="px-5 sm:px-8 lg:px-12">
        {/* Above the fold — asymmetric split */}
        <section className="mx-auto max-w-6xl py-10 sm:py-14">
          <div className="grid gap-10 lg:grid-cols-[1fr,1.1fr] lg:items-start">
            {/* Left — pitch + newsletter */}
            <div>
              <h1 className="text-3xl font-black leading-[1.15] tracking-tight text-white sm:text-[2.75rem]">
                Your daily news,<br />
                <span className="text-[var(--accent)]">minus the boring.</span>
              </h1>
              <p className="mt-4 max-w-sm text-[15px] text-zinc-400 leading-relaxed">
                25 satirical stories every morning. Actually funny. Actually informed.
                Free on iOS and web.
              </p>

              {/* Inline newsletter */}
              <div className="mt-6">
                <p className="mb-2 text-xs font-bold uppercase tracking-widest text-zinc-600">
                  Get the morning email
                </p>
                <NewsletterForm />
              </div>

              {/* Secondary CTAs */}
              <div className="mt-5 flex items-center gap-4">
                <a
                  href="https://apps.apple.com/app/thedailypoop/id6738030377"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1.5 text-[13px] font-medium text-zinc-500 transition hover:text-white"
                >
                  <svg className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
                  iOS App
                </a>
                <span className="text-zinc-800">|</span>
                <Link
                  href="/today"
                  className="text-[13px] font-medium text-zinc-500 transition hover:text-white"
                >
                  Read today&apos;s stories &rarr;
                </Link>
              </div>
            </div>

            {/* Right — lead story as hero card */}
            {leadStory && (
              <div>
                <p className="mb-3 text-xs font-bold uppercase tracking-widest text-zinc-600">
                  Top story
                </p>
                <Link href={`/story/${leadStory.id}`} className="group block">
                  <article className="glass-card overflow-hidden p-5 sm:p-6 transition hover:border-zinc-700">
                    <div className="flex items-center gap-2 text-xs">
                      <span className="text-lg">{leadStory.emoji || "📰"}</span>
                      <span className="rounded-full bg-white/[0.06] px-2.5 py-0.5 font-bold uppercase tracking-wide text-zinc-400">
                        {leadStory.category}
                      </span>
                      {!leadStory.is_free && (
                        <span className="rounded-full bg-[var(--accent)]/20 px-2 py-0.5 text-[10px] font-black text-[var(--accent)]">
                          PRO
                        </span>
                      )}
                    </div>
                    <h2 className="mt-3 text-xl font-black leading-snug text-white transition group-hover:text-[var(--accent)] sm:text-2xl">
                      {leadStory.headline}
                    </h2>
                    {leadStory.tldr && (
                      <p className="mt-2 text-sm text-zinc-500 leading-relaxed line-clamp-3">
                        {leadStory.tldr}
                      </p>
                    )}
                    <p className="mt-4 text-[13px] font-medium text-[var(--accent)]">
                      Read story &rarr;
                    </p>
                  </article>
                </Link>
              </div>
            )}
          </div>
        </section>

        {/* Divider */}
        <div className="mx-auto max-w-6xl">
          <div className="h-px bg-gradient-to-r from-transparent via-zinc-800 to-transparent" />
        </div>

        {/* More stories */}
        {restStories.length > 0 && (
          <section className="mx-auto max-w-6xl py-10">
            <div className="mb-5 flex items-baseline justify-between">
              <h2 className="text-base font-black text-white">
                More from today
              </h2>
              <Link
                href="/today"
                className="text-[13px] font-medium text-[var(--accent)] hover:underline"
              >
                All stories &rarr;
              </Link>
            </div>

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {restStories.map((story) => (
                <StoryCard key={story.id} story={story} />
              ))}
            </div>
          </section>
        )}

        {/* App CTA */}
        <section className="mx-auto max-w-6xl pb-12">
          <StoryCTA />
        </section>
      </main>

      <Footer />
    </div>
  );
}
