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
      <article className="glass-card flex h-full flex-col overflow-hidden">
        {/* Accent stripe + emoji */}
        <div
          className="relative flex h-2 shrink-0"
          style={{
            background: `linear-gradient(90deg, ${colors.from}, ${colors.to})`,
          }}
        />

        {/* Content */}
        <div className="flex flex-1 flex-col p-4">
          <div className="mb-3 flex items-center gap-2">
            <span className="text-lg">{story.emoji || "📰"}</span>
            <span
              className="category-pill text-white"
              style={{
                background: `linear-gradient(135deg, ${colors.from}CC, ${colors.to}CC)`,
              }}
            >
              {story.category}
            </span>
            {!story.is_free && (
              <span className="ml-auto rounded-full bg-[var(--accent)]/20 px-2 py-0.5 text-[10px] font-black tracking-wide text-[var(--accent)]">
                PRO
              </span>
            )}
          </div>

          <h3 className="text-[15px] font-bold leading-snug text-white transition group-hover:text-[var(--accent)]">
            {story.headline}
          </h3>

          {story.tldr && (
            <p className="mt-2 line-clamp-2 text-[13px] text-zinc-500 leading-relaxed">
              {story.tldr}
            </p>
          )}

          {/* Source row */}
          <div className="mt-auto flex items-center gap-2 pt-3 text-[11px] text-[var(--text-tertiary)]">
            <span className="font-medium text-zinc-500">
              {story.source_name || "TheDailyPoop"}
            </span>
            <span>&middot;</span>
            <span>{timeAgo(story.created_at)}</span>
          </div>
        </div>
      </article>
    </Link>
  );
}
