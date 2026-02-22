import { Metadata } from "next";
import { notFound } from "next/navigation";
import { createServiceClient } from "@/lib/supabase";
import { getWebSession } from "@/lib/web-auth";
import { getCategoryColor } from "@/lib/category-colors";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import StoryCTA from "@/components/StoryCTA";
import NewsletterForm from "@/components/NewsletterForm";
import Link from "next/link";

export const dynamic = "force-dynamic";

interface PageProps {
  params: Promise<{ id: string }>;
}

async function getStory(id: string) {
  const db = createServiceClient();

  const { data: story } = await db
    .from("stories")
    .select("*, briefings(publish_date, vibe_label, vibe_emoji)")
    .eq("id", id)
    .single();

  return story;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id } = await params;
  const story = await getStory(id);
  if (!story) return { title: "Story Not Found" };

  return {
    title: story.headline,
    description: story.tldr || story.body.slice(0, 160),
    openGraph: {
      type: "article",
      title: story.headline,
      description: story.tldr || story.body.slice(0, 160),
      publishedTime: story.created_at,
      section: story.category,
      images: [
        {
          url: `/api/og?title=${encodeURIComponent(story.headline)}&emoji=${encodeURIComponent(story.emoji || "💩")}&category=${encodeURIComponent(story.category)}`,
          width: 1200,
          height: 630,
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: story.headline,
      description: story.tldr || story.body.slice(0, 160),
    },
  };
}

export default async function StoryPage({ params }: PageProps) {
  const { id } = await params;
  const story = await getStory(id);
  if (!story) notFound();

  const session = await getWebSession();
  const colors = getCategoryColor(story.category);
  const publishDate = story.briefings?.publish_date
    ? new Date(story.briefings.publish_date + "T12:00:00").toLocaleDateString(
        "en-US",
        { weekday: "long", month: "long", day: "numeric", year: "numeric" }
      )
    : "";

  // Determine access: free stories are open, pro stories need pro subscription
  const canRead = story.is_free || session?.isPremium;

  // JSON-LD structured data for Google Discover
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "NewsArticle",
    headline: story.headline,
    description: story.tldr || story.body.slice(0, 160),
    datePublished: story.created_at,
    dateModified: story.created_at,
    author: {
      "@type": "Organization",
      name: "TheDailyPoop",
      url: "https://thedailypoop.com",
    },
    publisher: {
      "@type": "Organization",
      name: "TheDailyPoop",
      logo: {
        "@type": "ImageObject",
        url: "https://thedailypoop.com/icon-192.png",
      },
    },
    image: `https://thedailypoop.com/api/og?title=${encodeURIComponent(story.headline)}&emoji=${encodeURIComponent(story.emoji || "💩")}&category=${encodeURIComponent(story.category)}`,
    mainEntityOfPage: `https://thedailypoop.com/story/${story.id}`,
    articleSection: story.category,
    isAccessibleForFree: story.is_free,
  };

  return (
    <div className="min-h-screen bg-black">
      <Header />

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

      <main className="mx-auto max-w-2xl px-4 py-8 sm:px-5">
        {/* Back link */}
        <Link
          href="/today"
          className="mb-6 inline-flex items-center gap-1 text-sm text-[var(--text-secondary)] hover:text-white transition"
        >
          &larr; Back to today
        </Link>

        {/* Hero gradient */}
        <div
          className="relative mb-6 flex h-40 items-center justify-center rounded-2xl sm:h-52"
          style={{
            background: `linear-gradient(135deg, ${colors.from}, ${colors.to})`,
          }}
        >
          <span className="text-7xl drop-shadow-lg sm:text-8xl">
            {story.emoji || "💩"}
          </span>
          {!story.is_free && (
            <span className="absolute top-3 right-3 rounded-full bg-[var(--accent)] px-3 py-1 text-xs font-black text-black">
              PRO
            </span>
          )}
        </div>

        {/* Meta */}
        <div className="mb-4 flex flex-wrap items-center gap-2 text-xs text-[var(--text-tertiary)]">
          <span className="rounded-full bg-white/[0.06] px-3 py-1 font-semibold capitalize text-[var(--text-secondary)]">
            {story.category}
          </span>
          {publishDate && <span>{publishDate}</span>}
          {story.source_name && (
            <>
              <span>·</span>
              <span>via {story.source_name}</span>
            </>
          )}
        </div>

        {/* Headline */}
        <h1 className="text-2xl font-black leading-tight text-white sm:text-3xl">
          {story.headline}
        </h1>

        {/* TLDR — always visible */}
        {story.tldr && (
          <p className="mt-3 rounded-xl bg-[var(--card-bg)] border border-white/[0.06] p-4 text-sm italic text-[var(--text-secondary)]">
            TL;DR: {story.tldr}
          </p>
        )}

        {canRead ? (
          <>
            {/* Full Body */}
            <div className="story-body mt-6 text-base leading-relaxed text-zinc-300">
              {story.body.split("\n\n").map((para: string, i: number) => (
                <p key={i}>{para}</p>
              ))}
            </div>

            {/* Source link */}
            {story.source_url && (
              <a
                href={story.source_url}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-6 inline-flex items-center gap-1 text-sm text-[var(--accent)] hover:underline"
              >
                Read original source &rarr;
              </a>
            )}

            {/* Share */}
            <div className="mt-8 flex gap-3">
              <a
                href={`https://twitter.com/intent/tweet?text=${encodeURIComponent(story.headline + " 💩")}&url=${encodeURIComponent("https://thedailypoop.com/story/" + story.id)}`}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-full border border-white/[0.12] px-4 py-2 text-xs font-medium text-white transition hover:bg-white/[0.06]"
              >
                Share on X
              </a>
              <a
                href={`https://www.reddit.com/submit?url=${encodeURIComponent("https://thedailypoop.com/story/" + story.id)}&title=${encodeURIComponent(story.headline)}`}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-full border border-white/[0.12] px-4 py-2 text-xs font-medium text-white transition hover:bg-white/[0.06]"
              >
                Share on Reddit
              </a>
            </div>
          </>
        ) : (
          /* Paywall — blurred body + CTA */
          <div className="relative mt-6">
            {/* Blurred teaser — first paragraph */}
            <div className="story-body text-base leading-relaxed text-zinc-300">
              <p>{story.body.split("\n\n")[0]}</p>
            </div>
            <div className="mt-2 h-32 bg-gradient-to-b from-transparent to-black" />

            {/* Paywall CTA */}
            <div className="rounded-2xl border border-[var(--accent)]/20 bg-[var(--accent-dim)] p-6 text-center">
              <span className="text-3xl">🔒</span>
              <h3 className="mt-2 text-lg font-black text-white">
                This is a Pro story
              </h3>
              <p className="mt-1 text-sm text-[var(--text-secondary)]">
                Get Pro to read all 25 daily stories, play all 6 games, and
                access 15 days of history.
              </p>
              <div className="mt-4 flex flex-col items-center gap-2">
                <a
                  href="https://apps.apple.com/app/thedailypoop/id6738030377"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-block rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:brightness-110"
                >
                  Get Pro — $7.99/mo
                </a>
                {!session && (
                  <Link
                    href="/signup"
                    className="text-sm font-medium text-[var(--accent)] hover:underline"
                  >
                    Or sign up free for Poop or Scoop + 3 days history
                  </Link>
                )}
              </div>
            </div>
          </div>
        )}

        {/* CTA */}
        <div className="mt-10">
          <StoryCTA />
        </div>

        {/* Newsletter */}
        <section className="mt-10 rounded-2xl border border-white/[0.06] bg-[var(--card-bg)] p-6">
          <h2 className="text-lg font-black text-white">
            Want this in your inbox?
          </h2>
          <p className="mt-1 mb-4 text-sm text-[var(--text-secondary)]">
            Free daily briefing every morning.
          </p>
          <NewsletterForm />
        </section>
      </main>

      <Footer />
    </div>
  );
}
