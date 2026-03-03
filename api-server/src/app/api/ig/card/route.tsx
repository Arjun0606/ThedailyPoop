import { ImageResponse } from "next/og";
import { NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export const runtime = "edge";

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

const FORMATS: Record<string, { width: number; height: number }> = {
  square: { width: 1080, height: 1080 },
  portrait: { width: 1080, height: 1350 },
  story: { width: 1080, height: 1920 },
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

export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl;
  const storyId = searchParams.get("storyId");
  const format = searchParams.get("format") || "portrait";

  if (!storyId) {
    return new Response("Missing storyId", { status: 400 });
  }

  const dims = FORMATS[format] ?? FORMATS.portrait;

  const db = createServiceClient();
  const { data: story, error } = await db
    .from("stories")
    .select("*")
    .eq("id", storyId)
    .single();

  if (error || !story) {
    return new Response("Story not found", { status: 404 });
  }

  const category = (story.category || "default").toLowerCase();
  const categoryColor = CATEGORY_COLORS[category] ?? CATEGORY_COLORS.default;
  const emoji = story.emoji || CATEGORY_EMOJIS[category] || "\u{1F4F0}";
  const categoryLabel = category.charAt(0).toUpperCase() + category.slice(1);
  const bottomLine = extractBottomLine(story.body || "");
  const displayText = bottomLine || story.tldr || "";
  const headline = story.headline || "";

  // Scale font sizes based on format
  const isStory = format === "story";
  const isSquare = format === "square";
  const headlineSize = isStory ? 44 : isSquare ? 40 : 42;
  const bodySize = isStory ? 28 : isSquare ? 24 : 26;
  const padding = isStory ? 80 : 60;

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          background: "linear-gradient(160deg, #141414, #1a1810)",
          padding: `${padding}px`,
          fontFamily: "sans-serif",
        }}
      >
        {/* Top: Category + Branding */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            width: "100%",
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "10px",
              fontSize: 22,
              fontWeight: 700,
              color: "rgba(255,255,255,0.6)",
              letterSpacing: "0.5px",
            }}
          >
            <span style={{ fontSize: 28 }}>{emoji}</span>
            <span>{categoryLabel}</span>
          </div>
          <div
            style={{
              fontSize: 20,
              fontWeight: 800,
              color: "#F59E0B",
              letterSpacing: "1.5px",
            }}
          >
            TheDailyPoop
          </div>
        </div>

        {/* Middle: Headline + Bottom Line */}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: "32px",
            flex: 1,
            justifyContent: "center",
          }}
        >
          {/* Headline */}
          <div
            style={{
              fontSize: headlineSize,
              fontWeight: 900,
              color: "white",
              lineHeight: 1.25,
            }}
          >
            {headline}
          </div>

          {/* Divider */}
          <div
            style={{
              width: "100%",
              height: "2px",
              background: "rgba(245, 158, 11, 0.3)",
            }}
          />

          {/* Bottom Line / TLDR */}
          {displayText && (
            <div
              style={{
                display: "flex",
                flexDirection: "column",
                gap: "12px",
              }}
            >
              <div
                style={{
                  fontSize: 14,
                  fontWeight: 900,
                  color: "#F59E0B",
                  letterSpacing: "3px",
                }}
              >
                {bottomLine ? "THE BOTTOM LINE" : "TLDR"}
              </div>
              <div
                style={{
                  fontSize: bodySize,
                  fontWeight: 500,
                  color: "rgba(255,255,255,0.85)",
                  lineHeight: 1.5,
                }}
              >
                {displayText}
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            width: "100%",
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "10px",
              fontSize: 18,
              fontWeight: 600,
              color: "rgba(255,255,255,0.4)",
            }}
          >
            <span style={{ fontSize: 22 }}>{"\u{1F4A9}"}</span>
            <span>thedailypoop.lol</span>
          </div>
          {/* Category accent dot */}
          <div
            style={{
              width: "12px",
              height: "12px",
              borderRadius: "50%",
              background: categoryColor,
            }}
          />
        </div>

        {/* Border overlay */}
        <div
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            border: "2px solid rgba(245, 158, 11, 0.15)",
            borderRadius: "0px",
            pointerEvents: "none",
          }}
        />
      </div>
    ),
    {
      ...dims,
      headers: {
        "Cache-Control": "public, max-age=3600",
        "Content-Disposition": `inline; filename="thedailypoop-${storyId}.png"`,
      },
    }
  );
}
