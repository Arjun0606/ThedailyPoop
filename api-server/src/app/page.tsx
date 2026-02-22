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

  // Today's published briefings
  let { data: briefings } = await db
    .from("briefings")
    .select("id")
    .eq("publish_date", today)
    .eq("status", "published");

  // Fallback: latest published
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
    .eq("is_free", true)
    .order("sort_order", { ascending: true })
    .limit(10);

  return stories ?? [];
}

export const revalidate = 300; // refresh every 5 min

export default async function Home() {
  const stories = await getTodayStories();

  return (
    <div className="min-h-screen bg-black">
      <Header />

      <main className="mx-auto max-w-3xl px-4 sm:px-5">
        {/* Hero */}
        <section className="py-12 text-center sm:py-16">
          <p className="text-4xl">💩</p>
          <h1 className="mt-4 text-3xl font-black tracking-tight text-white sm:text-4xl">
            News That Doesn&apos;t Suck
          </h1>
          <p className="mt-3 text-lg text-[var(--text-secondary)]">
            25 stories a day. Zero boring ones. Dark satirical briefings that
            actually make you laugh.
          </p>
          <div className="mt-6 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
            <a
              href="https://apps.apple.com/app/thedailypoop/id6738030377"
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:brightness-110"
            >
              Download Free on iPhone
            </a>
            <Link
              href="/today"
              className="rounded-full border border-white/[0.12] px-6 py-2.5 text-sm font-medium text-white transition hover:bg-white/[0.06]"
            >
              Read Today&apos;s Drop
            </Link>
          </div>
        </section>

        {/* Today's Stories */}
        {stories.length > 0 && (
          <section>
            <div className="mb-6 flex items-center justify-between">
              <h2 className="text-xl font-black text-white">
                Today&apos;s Drop
              </h2>
              <Link
                href="/today"
                className="text-sm font-medium text-[var(--accent)] hover:underline"
              >
                See all &rarr;
              </Link>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              {stories.slice(0, 6).map((story) => (
                <StoryCard key={story.id} story={story} />
              ))}
            </div>

            {stories.length > 6 && (
              <div className="mt-6 text-center">
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
        <section className="my-12">
          <StoryCTA />
        </section>

        {/* Newsletter */}
        <section className="mb-16 rounded-2xl border border-white/[0.06] bg-[var(--card-bg)] p-6">
          <h2 className="text-lg font-black text-white">
            Get the Daily Briefing in Your Inbox
          </h2>
          <p className="mt-1 mb-4 text-sm text-[var(--text-secondary)]">
            Every morning. Free forever. Unsubscribe anytime.
          </p>
          <NewsletterForm />
        </section>
      </main>

      <Footer />
    </div>
  );
}
