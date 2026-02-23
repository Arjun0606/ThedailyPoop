import { createServiceClient } from "@/lib/supabase";
import Image from "next/image";
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

      <main className="mx-auto max-w-6xl px-6">
        {/* Hero */}
        <section className="py-16 text-center sm:py-24">
          <Image
            src="/logo.png"
            alt="TheDailyPoop"
            width={80}
            height={80}
            className="mx-auto drop-shadow-xl"
          />
          <h1 className="mt-6 text-4xl font-black tracking-tight text-white sm:text-5xl">
            News That Doesn&apos;t Suck
          </h1>
          <p className="mx-auto mt-4 max-w-lg text-lg text-[var(--text-secondary)]">
            25 stories a day. Zero boring ones. Dark satirical briefings that
            actually make you laugh.
          </p>
          <div className="mt-8 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
            <a
              href="https://apps.apple.com/app/thedailypoop/id6738030377"
              target="_blank"
              rel="noopener noreferrer"
              className="pressable rounded-full bg-[var(--accent)] px-7 py-3 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)]"
            >
              Download Free on iPhone
            </a>
            <Link
              href="/today"
              className="pressable rounded-full border border-[var(--glass-border)] px-7 py-3 text-sm font-medium text-white transition hover:bg-white/[0.06]"
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

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
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
        <section className="glass-card mb-16 p-6 sm:p-8">
          <div className="sm:flex sm:items-center sm:gap-6">
            <div className="flex-1">
              <h2 className="text-lg font-black text-white">
                Get the Daily Briefing in Your Inbox
              </h2>
              <p className="mt-1 text-sm text-[var(--text-secondary)]">
                Every morning. Free forever. Unsubscribe anytime.
              </p>
            </div>
            <div className="mt-4 sm:mt-0 sm:w-80">
              <NewsletterForm />
            </div>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  );
}
