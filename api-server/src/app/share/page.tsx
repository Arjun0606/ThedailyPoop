"use client";

import { useState, useEffect } from "react";

interface Story {
  id: string;
  headline: string;
  body: string;
  tldr?: string;
  category: string;
  emoji?: string;
  sort_order: number;
  is_free: boolean;
}

interface Briefing {
  id: string;
  publish_date: string;
  headline: string;
  vibe_label?: string;
  vibe_emoji?: string;
}

interface Drop {
  briefing: Briefing;
  stories: Story[];
}

const CATEGORY_EMOJIS: Record<string, string> = {
  business: "\u{1F4B0}",
  tech: "\u{1F4F1}",
  politics: "\u{1F3DB}\u{FE0F}",
  culture: "\u{1F3AD}",
  sports: "\u{1F3C6}",
  world: "\u{1F30D}",
  science: "\u{1F52C}",
  health: "\u{1FA7A}",
};

const CATEGORY_COLORS: Record<string, string> = {
  business: "#F59E0B",
  tech: "#3B82F6",
  culture: "#A855F7",
  politics: "#EF4444",
  sports: "#10B981",
  world: "#F97316",
  science: "#06B6D4",
  default: "#6B7280",
};

type Format = "square" | "portrait" | "story";

const FORMAT_LABELS: Record<Format, string> = {
  square: "1:1 Feed",
  portrait: "4:5 Feed",
  story: "9:16 Story",
};

function extractBottomLine(body: string): string | null {
  const paragraphs = body.split("\n\n");
  for (const raw of paragraphs) {
    const trimmed = raw.trim();
    if (/^the bottom line:/i.test(trimmed)) {
      return trimmed.replace(/^the bottom line:\s*/i, "");
    }
  }
  return null;
}

export default function SharePage() {
  const [drops, setDrops] = useState<Drop[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedStory, setSelectedStory] = useState<Story | null>(null);
  const [format, setFormat] = useState<Format>("portrait");
  const [downloading, setDownloading] = useState(false);

  useEffect(() => {
    fetch("/api/briefing/today")
      .then((r) => r.json())
      .then((data) => {
        setDrops(data.drops || []);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const allStories = drops.flatMap((d) => d.stories);

  async function downloadCard(story: Story, fmt: Format) {
    setDownloading(true);
    try {
      const res = await fetch(`/api/ig/card?storyId=${story.id}&format=${fmt}`);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `tdp-${story.category}-${fmt}.png`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } finally {
      setDownloading(false);
    }
  }

  async function downloadAll(fmt: Format) {
    for (const story of allStories) {
      await downloadCard(story, fmt);
      // Small delay between downloads to avoid browser blocking
      await new Promise((r) => setTimeout(r, 300));
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-black flex items-center justify-center">
        <div className="text-zinc-500 text-lg">Loading briefing...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-black text-white">
      {/* Header */}
      <div className="border-b border-zinc-800 px-6 py-5">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">
              <span className="text-[#F59E0B]">{"\u{1F4A9}"}</span> Instagram Cards
            </h1>
            <p className="text-zinc-500 text-sm mt-1">
              {allStories.length} stories ready to share
            </p>
          </div>
          <div className="flex items-center gap-3">
            {/* Format selector */}
            <div className="flex bg-zinc-900 rounded-lg p-1 gap-1">
              {(Object.keys(FORMAT_LABELS) as Format[]).map((fmt) => (
                <button
                  key={fmt}
                  onClick={() => setFormat(fmt)}
                  className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                    format === fmt
                      ? "bg-[#F59E0B] text-black"
                      : "text-zinc-400 hover:text-white"
                  }`}
                >
                  {FORMAT_LABELS[fmt]}
                </button>
              ))}
            </div>
            <button
              onClick={() => downloadAll(format)}
              className="px-4 py-2 bg-zinc-800 hover:bg-zinc-700 rounded-lg text-sm font-medium transition-colors"
            >
              Download All
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-6 py-8">
        {/* Story Grid */}
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {allStories.map((story) => {
            const cat = (story.category || "default").toLowerCase();
            const color = CATEGORY_COLORS[cat] ?? CATEGORY_COLORS.default;
            const emoj = story.emoji || CATEGORY_EMOJIS[cat] || "\u{1F4F0}";
            const bl = extractBottomLine(story.body || "");

            return (
              <button
                key={story.id}
                onClick={() => setSelectedStory(story)}
                className="text-left group rounded-xl border border-zinc-800 hover:border-zinc-600 bg-zinc-900/50 p-4 transition-all hover:scale-[1.02]"
              >
                <div className="flex items-center gap-2 mb-3">
                  <span
                    className="inline-block w-2 h-2 rounded-full"
                    style={{ background: color }}
                  />
                  <span className="text-xs font-bold text-zinc-500 uppercase tracking-wider">
                    {emoj} {cat}
                  </span>
                  <span className="text-xs text-zinc-700 ml-auto">
                    #{story.sort_order}
                  </span>
                </div>
                <p className="text-sm font-semibold leading-snug line-clamp-3 group-hover:text-white text-zinc-200">
                  {story.headline}
                </p>
                {bl && (
                  <p className="text-xs text-zinc-500 mt-2 line-clamp-2 italic">
                    {bl}
                  </p>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Modal: Card Preview */}
      {selectedStory && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm"
          onClick={() => setSelectedStory(null)}
        >
          <div
            className="bg-zinc-900 rounded-2xl border border-zinc-800 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal header */}
            <div className="flex items-center justify-between p-5 border-b border-zinc-800">
              <h2 className="font-bold text-lg line-clamp-1">
                {selectedStory.headline}
              </h2>
              <button
                onClick={() => setSelectedStory(null)}
                className="text-zinc-500 hover:text-white text-xl"
              >
                {"\u2715"}
              </button>
            </div>

            {/* Card preview */}
            <div className="p-5 flex justify-center">
              <img
                src={`/api/ig/card?storyId=${selectedStory.id}&format=${format}`}
                alt={selectedStory.headline}
                className="rounded-xl shadow-2xl max-h-[60vh] w-auto"
              />
            </div>

            {/* Format selector + Download */}
            <div className="p-5 pt-0 flex items-center justify-between">
              <div className="flex gap-2">
                {(Object.keys(FORMAT_LABELS) as Format[]).map((fmt) => (
                  <button
                    key={fmt}
                    onClick={() => setFormat(fmt)}
                    className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                      format === fmt
                        ? "bg-[#F59E0B] text-black"
                        : "bg-zinc-800 text-zinc-400 hover:text-white"
                    }`}
                  >
                    {FORMAT_LABELS[fmt]}
                  </button>
                ))}
              </div>
              <button
                onClick={() => downloadCard(selectedStory, format)}
                disabled={downloading}
                className="px-5 py-2.5 bg-[#F59E0B] hover:bg-[#EAB308] text-black font-bold rounded-lg transition-colors disabled:opacity-50"
              >
                {downloading ? "Downloading..." : "Download"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
