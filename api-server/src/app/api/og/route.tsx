import { ImageResponse } from "next/og";
import { NextRequest } from "next/server";

export const runtime = "edge";

const CATEGORY_COLORS: Record<string, string> = {
  business: "#F59E0B",
  tech: "#3B82F6",
  culture: "#A855F7",
  politics: "#EF4444",
  sports: "#10B981",
  world: "#F97316",
  default: "#6B7280",
};

export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl;
  const title = searchParams.get("title") || "TheDailyPoop";
  const emoji = searchParams.get("emoji") || "💩";
  const category = searchParams.get("category") || "default";
  const color = CATEGORY_COLORS[category.toLowerCase()] ?? CATEGORY_COLORS.default;

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          background: `linear-gradient(135deg, ${color}, #000)`,
          padding: "60px",
        }}
      >
        <div style={{ fontSize: 100, marginBottom: 24 }}>{emoji}</div>
        <div
          style={{
            fontSize: 48,
            fontWeight: 900,
            color: "white",
            textAlign: "center",
            maxWidth: 900,
            lineHeight: 1.2,
          }}
        >
          {title}
        </div>
        <div
          style={{
            marginTop: 24,
            display: "flex",
            alignItems: "center",
            gap: 12,
          }}
        >
          <div style={{ fontSize: 28, color: "rgba(255,255,255,0.7)" }}>
            💩 TheDailyPoop
          </div>
        </div>
      </div>
    ),
    { width: 1200, height: 630 }
  );
}
