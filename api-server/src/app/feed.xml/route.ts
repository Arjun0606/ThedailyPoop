import { createServiceClient } from "@/lib/supabase";

export const dynamic = "force-dynamic";

export async function GET() {
  const db = createServiceClient();

  // Get last 7 days of stories
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const { data: stories } = await db
    .from("stories")
    .select("*, briefings(publish_date)")
    .eq("is_free", true)
    .gte("created_at", sevenDaysAgo.toISOString())
    .order("created_at", { ascending: false })
    .limit(50);

  const items = (stories ?? [])
    .map(
      (s) => `
    <item>
      <title><![CDATA[${s.headline}]]></title>
      <link>https://thedailypoop.lol/story/${s.id}</link>
      <guid isPermaLink="true">https://thedailypoop.lol/story/${s.id}</guid>
      <description><![CDATA[${s.tldr || s.body.slice(0, 200)}]]></description>
      <category>${s.category}</category>
      <pubDate>${new Date(s.created_at).toUTCString()}</pubDate>
      <media:content url="https://thedailypoop.lol/api/og?title=${encodeURIComponent(s.headline)}&amp;emoji=${encodeURIComponent(s.emoji || "📰")}&amp;category=${encodeURIComponent(s.category)}" medium="image" width="1200" height="630" />
      <media:thumbnail url="https://thedailypoop.lol/api/og?title=${encodeURIComponent(s.headline)}&amp;emoji=${encodeURIComponent(s.emoji || "📰")}&amp;category=${encodeURIComponent(s.category)}" width="1200" height="630" />
    </item>`
    )
    .join("");

  const feed = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/">
  <channel>
    <title>TheDailyPoop — News That Doesn't Suck</title>
    <link>https://thedailypoop.lol</link>
    <description>25 stories a day. Zero boring ones. Dark satirical news briefings.</description>
    <language>en-us</language>
    <lastBuildDate>${new Date().toUTCString()}</lastBuildDate>
    <image>
      <url>https://thedailypoop.lol/icon-192.png</url>
      <title>TheDailyPoop</title>
      <link>https://thedailypoop.lol</link>
    </image>
    <atom:link href="https://thedailypoop.lol/feed.xml" rel="self" type="application/rss+xml"/>
    ${items}
  </channel>
</rss>`;

  return new Response(feed, {
    headers: {
      "Content-Type": "application/rss+xml; charset=utf-8",
      "Cache-Control": "public, max-age=1800",
    },
  });
}
