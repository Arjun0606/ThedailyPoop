import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { createBeehiivPost } from "@/lib/beehiiv";

// Publishes daily newsletter to Beehiiv at 7:30am ET
// Beehiiv handles sending to all subscribers + injects Ad Network ads for monetization
export const sendDailyNewsletter = inngest.createFunction(
  { id: "send-daily-newsletter", name: "Send Daily Newsletter (Beehiiv)" },
  { cron: "TZ=America/New_York 30 7 * * *" },
  async ({ step }) => {
    const db = createServiceClient();
    const today = new Date().toLocaleDateString("en-CA", {
      timeZone: "America/New_York",
    });

    // Get today's briefing
    const briefing = await step.run("fetch-briefing", async () => {
      const { data } = await db
        .from("briefings")
        .select("id, publish_date, vibe")
        .eq("publish_date", today)
        .eq("status", "published")
        .limit(1)
        .single();
      return data;
    });

    if (!briefing) return { skipped: true, reason: "no briefing today" };

    // Get free stories (10 best for newsletter)
    const stories = await step.run("fetch-stories", async () => {
      const { data } = await db
        .from("stories")
        .select("headline, tldr, emoji, category, id, body")
        .eq("briefing_id", briefing.id)
        .eq("is_free", true)
        .order("sort_order", { ascending: true })
        .limit(10);
      return data ?? [];
    });

    if (!stories.length) return { skipped: true, reason: "no stories" };

    // Build newsletter HTML and publish to Beehiiv
    const result = await step.run("publish-to-beehiiv", async () => {
      const html = buildNewsletterHTML(stories, briefing, today);
      const subtitle = briefing.vibe
        ? `Today's Vibe: ${briefing.vibe}`
        : "Your daily dose of news that doesn't suck";

      return createBeehiivPost({
        title: `${stories[0]?.emoji || "💩"} ${stories[0]?.headline || "Today's Drop"}`,
        subtitle,
        html,
        sendNow: true,
      });
    });

    return { published: true, date: today, beehiiv: result };
  }
);

function buildNewsletterHTML(
  stories: Array<{
    headline: string;
    tldr?: string;
    emoji?: string;
    category: string;
    id: string;
    body: string;
  }>,
  briefing: { vibe?: string },
  date: string
) {
  const formattedDate = new Date(date + "T12:00:00").toLocaleDateString(
    "en-US",
    { weekday: "long", month: "long", day: "numeric" }
  );

  const storyBlocks = stories
    .map(
      (s, i) => `
    <tr>
      <td style="padding: 20px 0; ${i < stories.length - 1 ? "border-bottom: 1px solid #222;" : ""}">
        <table cellpadding="0" cellspacing="0" border="0" width="100%">
          <tr>
            <td width="44" style="vertical-align: top; padding-right: 12px;">
              <div style="font-size: 28px; line-height: 1;">${s.emoji || "💩"}</div>
            </td>
            <td style="vertical-align: top;">
              <a href="https://thedailypoop.com/story/${s.id}" style="text-decoration: none;">
                <div style="font-size: 17px; font-weight: 700; color: #FFFFFF; line-height: 1.3;">
                  ${s.headline}
                </div>
              </a>
              ${s.tldr ? `<div style="font-size: 14px; color: #a1a1aa; margin-top: 6px; line-height: 1.5;">${s.tldr}</div>` : ""}
              <div style="font-size: 14px; color: #d4d4d8; margin-top: 8px; line-height: 1.6;">
                ${s.body.split("\n\n").slice(0, 2).join("<br><br>")}
              </div>
              <div style="margin-top: 8px;">
                <a href="https://thedailypoop.com/story/${s.id}" style="font-size: 13px; color: #F59E0B; text-decoration: none; font-weight: 600;">
                  Read full story →
                </a>
              </div>
              <div style="font-size: 11px; color: #52525b; margin-top: 6px; text-transform: capitalize;">${s.category}</div>
            </td>
          </tr>
        </table>
      </td>
    </tr>`
    )
    .join("");

  // Beehiiv Ad Network will auto-inject ads between content blocks
  return `
<table cellpadding="0" cellspacing="0" border="0" width="100%" style="background-color: #000; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
  <tr>
    <td align="center" style="padding: 20px;">
      <table cellpadding="0" cellspacing="0" border="0" width="560" style="max-width: 560px;">

        <!-- Header -->
        <tr>
          <td style="padding: 28px 0; text-align: center; border-bottom: 1px solid #222;">
            <div style="font-size: 36px; margin-bottom: 8px;">💩</div>
            <div style="font-size: 22px; font-weight: 900; color: #FFF; letter-spacing: -0.02em;">TheDailyPoop</div>
            <div style="font-size: 13px; color: #52525b; margin-top: 6px;">${formattedDate}${briefing.vibe ? ` · Today's Vibe: ${briefing.vibe}` : ""}</div>
          </td>
        </tr>

        <!-- Intro -->
        <tr>
          <td style="padding: 20px 0 4px; text-align: center;">
            <div style="font-size: 14px; color: #a1a1aa; line-height: 1.5;">
              Here's your daily drop. ${stories.length} stories, zero boring ones.
            </div>
          </td>
        </tr>

        <!-- Stories -->
        ${storyBlocks}

        <!-- More stories CTA -->
        <tr>
          <td style="padding: 24px 0; text-align: center; border-top: 1px solid #222;">
            <div style="font-size: 14px; color: #a1a1aa; margin-bottom: 12px;">
              Want all 25 stories + 6 AI games?
            </div>
            <a href="https://apps.apple.com/app/thedailypoop/id6738030377" style="display: inline-block; background: #F59E0B; color: #000; font-size: 14px; font-weight: 700; padding: 12px 28px; border-radius: 9999px; text-decoration: none;">
              Get the App Free
            </a>
          </td>
        </tr>

        <!-- Read on web -->
        <tr>
          <td style="padding: 12px 0; text-align: center;">
            <a href="https://thedailypoop.com/today" style="font-size: 13px; color: #F59E0B; text-decoration: none; font-weight: 600;">
              Read all stories on the web →
            </a>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="padding: 20px 0; text-align: center; border-top: 1px solid #222;">
            <div style="font-size: 11px; color: #52525b; line-height: 1.6;">
              <a href="https://thedailypoop.com" style="color: #71717a;">thedailypoop.com</a><br>
              You're getting this because you subscribed to TheDailyPoop.<br>
              Not your thing? No hard feelings — unsubscribe below.
            </div>
          </td>
        </tr>

      </table>
    </td>
  </tr>
</table>`;
}
