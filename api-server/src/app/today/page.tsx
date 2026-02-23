import { Metadata } from "next";
import Image from "next/image";
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

      <main className="mx-auto max-w-6xl px-6 py-8">
        <div className="mb-8 flex items-center gap-3">
          <Image
            src="/logo.png"
            alt=""
            width={40}
            height={40}
            className="drop-shadow-md"
          />
          <div>
            <h1 className="text-2xl font-black text-white sm:text-3xl">
              Today&apos;s Drop
            </h1>
            <p className="mt-0.5 text-sm text-[var(--text-secondary)]">
              {today}
            </p>
          </div>
        </div>

        {stories.length === 0 ? (
          <div className="glass-card p-12 text-center">
            <Image
              src="/logo.png"
              alt=""
              width={56}
              height={56}
              className="mx-auto drop-shadow-lg"
            />
            <p className="mt-4 text-lg font-bold text-white">
              No drop yet today
            </p>
            <p className="mt-1 text-sm text-[var(--text-secondary)]">
              Check back soon — drops hit at 7am, 12pm, and 5pm ET.
            </p>
          </div>
        ) : (
          <>
            {/* Story grid — 3 cols on desktop */}
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {stories.map((story, i) => (
                <div key={story.id}>
                  <StoryCard story={story} />
                  {(i + 1) % 6 === 0 && i < stories.length - 1 && (
                    <div className="sm:col-span-2 lg:col-span-3">
                      <AdSlot format="horizontal" />
                    </div>
                  )}
                </div>
              ))}
            </div>

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
