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
    <Link href={`/story/${story.id}`} className="group block pressable">
      <article className="glass-card overflow-hidden">
        {/* Gradient header with emoji */}
        <div
          className="relative flex h-36 items-center justify-center sm:h-44"
          style={{
            background: `linear-gradient(135deg, ${colors.from}, ${colors.to})`,
          }}
        >
          <span className="text-5xl drop-shadow-lg sm:text-6xl">
            {story.emoji || "📰"}
          </span>

          {/* Category pill */}
          <span
            className="category-pill absolute top-3 left-3 text-white"
            style={{
              background: "rgba(0,0,0,0.3)",
              backdropFilter: "blur(8px)",
            }}
          >
            {story.category}
          </span>

          {/* PRO badge */}
          {!story.is_free && (
            <span className="absolute top-3 right-3 rounded-full bg-[var(--accent)] px-2.5 py-0.5 text-[10px] font-black tracking-wide text-black">
              PRO
            </span>
          )}
        </div>

        {/* Content */}
        <div className="p-4">
          <h3 className="text-[15px] font-bold leading-snug text-white transition group-hover:text-[var(--accent)]">
            {story.headline}
          </h3>

          {story.tldr && (
            <p className="mt-1.5 line-clamp-2 text-[13px] text-[var(--text-secondary)]">
              {story.tldr}
            </p>
          )}

          {/* Source row */}
          <div className="mt-3 flex items-center gap-2 text-[11px] text-[var(--text-tertiary)]">
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
