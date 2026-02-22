import Link from "next/link";
import { getCategoryColor, timeAgo } from "@/lib/category-colors";

interface Story {
  id: string;
  headline: string;
  tldr?: string;
  emoji?: string;
  category: string;
  source_name?: string;
  is_free: boolean;
  created_at: string;
}

export default function StoryCard({ story }: { story: Story }) {
  const colors = getCategoryColor(story.category);

  return (
    <Link href={`/story/${story.id}`} className="group block">
      <article className="overflow-hidden rounded-2xl border border-white/[0.06] bg-[var(--card-bg)] transition hover:border-white/[0.12]">
        {/* Visual header — gradient card with emoji like Google Discover image */}
        <div
          className="relative flex h-48 items-center justify-center sm:h-56"
          style={{
            background: `linear-gradient(135deg, ${colors.from}, ${colors.to})`,
          }}
        >
          <span className="text-6xl drop-shadow-lg sm:text-7xl">
            {story.emoji || "💩"}
          </span>

          {/* Category badge */}
          <span className="absolute top-3 left-3 rounded-full bg-black/30 px-3 py-1 text-xs font-semibold capitalize text-white backdrop-blur-sm">
            {story.category}
          </span>

          {/* All stories free on web */}
        </div>

        {/* Content */}
        <div className="p-4">
          <h3 className="text-base font-bold leading-snug text-white group-hover:text-[var(--accent)] transition sm:text-lg">
            {story.headline}
          </h3>

          {story.tldr && (
            <p className="mt-1.5 line-clamp-2 text-sm text-[var(--text-secondary)]">
              {story.tldr}
            </p>
          )}

          {/* Source row — mimics Google Discover */}
          <div className="mt-3 flex items-center gap-2 text-xs text-[var(--text-tertiary)]">
            <span className="text-sm">💩</span>
            <span className="font-medium text-[var(--text-secondary)]">
              {story.source_name || "TheDailyPoop"}
            </span>
            <span>·</span>
            <span>{timeAgo(story.created_at)}</span>
          </div>
        </div>
      </article>
    </Link>
  );
}
