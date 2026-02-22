import { Metadata } from "next";
import { createServiceClient } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import StoryCard from "@/components/StoryCard";
import StoryCTA from "@/components/StoryCTA";
import AdSlot from "@/components/AdSlot";

export const metadata: Metadata = {
  title: "Today's Drop",
  description:
    "Today's 25 satirical news stories from TheDailyPoop. Dark humor, zero boredom.",
};

export const dynamic = "force-dynamic";

async function getTodayDrop() {
  const db = createServiceClient();
  const today = new Date().toLocaleDateString("en-CA", {
    timeZone: "America/New_York",
  });

  let { data: briefings } = await db
    .from("briefings")
    .select("*")
    .eq("publish_date", today)
    .eq("status", "published");

  if (!briefings?.length) {
    const { data: latest } = await db
      .from("briefings")
      .select("*")
      .eq("status", "published")
      .order("publish_date", { ascending: false })
      .limit(3);
    briefings = latest;
  }

  if (!briefings?.length) return { briefings: [], stories: [] };

  const briefingIds = briefings.map((b) => b.id);
  const { data: stories } = await db
    .from("stories")
    .select("*")
    .in("briefing_id", briefingIds)
    .order("sort_order", { ascending: true });

  return { briefings, stories: stories ?? [] };
}

export default async function TodayPage() {
  const { stories } = await getTodayDrop();

  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
    year: "numeric",
    timeZone: "America/New_York",
  });

  return (
    <div className="min-h-screen bg-black">
      <Header />

      <main className="mx-auto max-w-3xl px-4 py-8 sm:px-5">
        <div className="mb-8">
          <h1 className="text-2xl font-black text-white sm:text-3xl">
            Today&apos;s Drop
          </h1>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">{today}</p>
        </div>

        {stories.length === 0 ? (
          <div className="rounded-2xl border border-white/[0.06] bg-[var(--card-bg)] p-12 text-center">
            <p className="text-4xl">💩</p>
            <p className="mt-3 text-lg font-bold text-white">
              No drop yet today
            </p>
            <p className="mt-1 text-sm text-[var(--text-secondary)]">
              Check back soon — drops hit at 7am, 12pm, and 5pm ET.
            </p>
          </div>
        ) : (
          <>
            {/* All stories — free on web */}
            <div className="grid gap-4 sm:grid-cols-2">
              {stories.map((story, i) => (
                <div key={story.id}>
                  <StoryCard story={story} />
                  {/* Ad after every 5th story */}
                  {(i + 1) % 5 === 0 && i < stories.length - 1 && (
                    <div className="sm:col-span-2">
                      <AdSlot format="horizontal" />
                    </div>
                  )}
                </div>
              ))}
            </div>

            {/* App CTA — games + better experience */}
            <section className="mt-10">
              <StoryCTA />
            </section>
          </>
        )}
      </main>

      <Footer />
    </div>
  );
}
