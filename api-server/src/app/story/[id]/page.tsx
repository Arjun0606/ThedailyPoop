import { Metadata } from "next";
import { notFound } from "next/navigation";
import { createServiceClient } from "@/lib/supabase";
import { getCategoryColor } from "@/lib/category-colors";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import StoryCTA from "@/components/StoryCTA";
import NewsletterForm from "@/components/NewsletterForm";
import Link from "next/link";

export const revalidate = 3600;

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

  const colors = getCategoryColor(story.category);
  const publishDate = story.briefings?.publish_date
    ? new Date(story.briefings.publish_date + "T12:00:00").toLocaleDateString(
        "en-US",
        { weekday: "long", month: "long", day: "numeric", year: "numeric" }
      )
    : "";

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
          className="mb-6 flex h-40 items-center justify-center rounded-2xl sm:h-52"
          style={{
            background: `linear-gradient(135deg, ${colors.from}, ${colors.to})`,
          }}
        >
          <span className="text-7xl drop-shadow-lg sm:text-8xl">
            {story.emoji || "💩"}
          </span>
        </div>

        {/* Meta */}
        <div className="mb-4 flex flex-wrap items-center gap-2 text-xs text-[var(--text-tertiary)]">
          <span className="rounded-full bg-white/[0.06] px-3 py-1 font-semibold capitalize text-[var(--text-secondary)]">
            {story.category}
          </span>
          {!story.is_free && (
            <span className="rounded-full bg-[var(--accent)] px-2.5 py-0.5 font-black text-black">
              PRO
            </span>
          )}
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

        {/* TLDR */}
        {story.tldr && (
          <p className="mt-3 rounded-xl bg-[var(--card-bg)] border border-white/[0.06] p-4 text-sm italic text-[var(--text-secondary)]">
            TL;DR: {story.tldr}
          </p>
        )}

        {/* Body */}
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
