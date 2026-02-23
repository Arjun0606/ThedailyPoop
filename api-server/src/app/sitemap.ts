import { MetadataRoute } from "next";
import { createServiceClient } from "@/lib/supabase";

export const dynamic = "force-dynamic";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const db = createServiceClient();

  // Fetch all published stories (last 30 days for freshness)
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const { data: stories } = await db
    .from("stories")
    .select("id, created_at, is_free")
    .gte("created_at", thirtyDaysAgo.toISOString())
    .order("created_at", { ascending: false });

  // Fetch published briefing dates for archive pages
  const { data: briefings } = await db
    .from("briefings")
    .select("publish_date")
    .eq("status", "published")
    .order("publish_date", { ascending: false })
    .limit(30);

  const storyUrls: MetadataRoute.Sitemap = (stories ?? []).map((s) => ({
    url: `https://thedailypoop.lol/story/${s.id}`,
    lastModified: new Date(s.created_at),
    changeFrequency: "never" as const,
    priority: s.is_free ? 0.8 : 0.6,
  }));

  const staticPages: MetadataRoute.Sitemap = [
    {
      url: "https://thedailypoop.lol",
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 1.0,
    },
    {
      url: "https://thedailypoop.lol/today",
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 0.9,
    },
    {
      url: "https://thedailypoop.lol/archive",
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 0.7,
    },
    {
      url: "https://thedailypoop.lol/games",
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 0.7,
    },
    {
      url: "https://thedailypoop.lol/games/poop-or-scoop",
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 0.6,
    },
    {
      url: "https://thedailypoop.lol/games/who-said-it",
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 0.6,
    },
    {
      url: "https://thedailypoop.lol/games/spin-the-excuse",
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 0.6,
    },
    {
      url: "https://thedailypoop.lol/games/the-roast",
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 0.6,
    },
    {
      url: "https://thedailypoop.lol/games/predict-the-poop",
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 0.6,
    },
    {
      url: "https://thedailypoop.lol/games/headline-roulette",
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 0.6,
    },
  ];

  return [...staticPages, ...storyUrls];
}
