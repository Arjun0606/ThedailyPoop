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
        .select("id, publish_date, vibe_label, vibe_emoji")
        .eq("publish_date", today)
        .eq("status", "published")
        .limit(1)
        .single();
      return data;
    });

    if (!briefing) return { skipped: true, reason: "no briefing today" };

    // Get ALL stories — free and pro
    const stories = await step.run("fetch-stories", async () => {
      const { data } = await db
        .from("stories")
        .select("headline, tldr, emoji, category, id, body, is_free")
        .eq("briefing_id", briefing.id)
        .order("sort_order", { ascending: true });
      return data ?? [];
    });

    if (!stories.length) return { skipped: true, reason: "no stories" };

    // Build newsletter HTML and publish to Beehiiv
    const result = await step.run("publish-to-beehiiv", async () => {
      const html = buildNewsletterHTML(stories, briefing, today);

      // Dynamic subject line — lead with the spiciest headline
      const leadStory = stories[0];
      const subjectEmoji = leadStory?.emoji || "📰";
      const subjectLine = `${subjectEmoji} ${leadStory?.headline || "Today's Drop"}`;

      const subtitle = briefing.vibe_label
        ? `${briefing.vibe_emoji || ""} ${briefing.vibe_label}`
        : "Your daily drop just landed";

      return createBeehiivPost({
        title: subjectLine,
        subtitle,
        html,
        sendNow: true,
      });
    });

    return {
      published: true,
      date: today,
      storyCount: stories.length,
      beehiiv: result,
    };
  }
);

interface Story {
  headline: string;
  tldr?: string;
  emoji?: string;
  category: string;
  id: string;
  body: string;
  is_free: boolean;
}

function buildNewsletterHTML(
  stories: Story[],
  briefing: { vibe_label?: string; vibe_emoji?: string },
  date: string
) {
  const formattedDate = new Date(date + "T12:00:00").toLocaleDateString(
    "en-US",
    { weekday: "long", month: "long", day: "numeric", year: "numeric" }
  );

  // Split into featured (first 5) and the rest as quick hits
  const featured = stories.slice(0, 5);
  const quickHits = stories.slice(5);

  // Pick "The Number" — find a story with a number in the headline
  const numberStory = stories.find((s) =>
    /\$[\d,.]+|\d{2,}%|\d{1,3}(,\d{3})+|\d+ (million|billion|trillion)/i.test(
      s.headline
    )
  );

  const featuredBlocks = featured
    .map(
      (s, i) => `
        <tr>
          <td style="padding: 0 0 ${i < featured.length - 1 ? "24px" : "0"} 0;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="background: #111; border-radius: 12px; overflow: hidden;">
              <!-- Category + PRO badge -->
              <tr>
                <td style="padding: 16px 20px 0;">
                  <table cellpadding="0" cellspacing="0" border="0" width="100%">
                    <tr>
                      <td>
                        <span style="font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: #F59E0B; background: rgba(245,158,11,0.12); padding: 3px 8px; border-radius: 99px;">${s.category}</span>
                      </td>
                      <td align="right">
                        ${!s.is_free ? '<span style="font-size: 10px; font-weight: 800; color: #F59E0B;">PRO</span>' : ""}
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
              <!-- Emoji + Headline -->
              <tr>
                <td style="padding: 12px 20px 0;">
                  <span style="font-size: 24px;">${s.emoji || "📰"}</span>
                  <a href="https://thedailypoop.com/story/${s.id}" style="text-decoration: none;">
                    <div style="font-size: 18px; font-weight: 800; color: #FFFFFF; line-height: 1.3; margin-top: 8px;">
                      ${s.headline}
                    </div>
                  </a>
                </td>
              </tr>
              <!-- TLDR -->
              ${
                s.tldr
                  ? `<tr><td style="padding: 8px 20px 0;"><div style="font-size: 14px; color: #a1a1aa; line-height: 1.5; font-style: italic;">TL;DR: ${s.tldr}</div></td></tr>`
                  : ""
              }
              <!-- Body excerpt -->
              <tr>
                <td style="padding: 10px 20px 0;">
                  <div style="font-size: 14px; color: #d4d4d8; line-height: 1.65;">
                    ${s.body
                      .split("\n\n")
                      .slice(0, 2)
                      .join("<br><br>")}
                  </div>
                </td>
              </tr>
              <!-- Read more -->
              <tr>
                <td style="padding: 12px 20px 16px;">
                  <a href="https://thedailypoop.com/story/${s.id}" style="font-size: 13px; color: #F59E0B; text-decoration: none; font-weight: 700;">
                    Keep reading &rarr;
                  </a>
                </td>
              </tr>
            </table>
          </td>
        </tr>`
    )
    .join("");

  const quickHitRows = quickHits
    .map(
      (s) => `
        <tr>
          <td style="padding: 12px 0; border-bottom: 1px solid #1a1a1a;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%">
              <tr>
                <td width="32" style="vertical-align: top; font-size: 20px; padding-right: 10px;">
                  ${s.emoji || "📰"}
                </td>
                <td style="vertical-align: top;">
                  <a href="https://thedailypoop.com/story/${s.id}" style="text-decoration: none;">
                    <div style="font-size: 15px; font-weight: 700; color: #FFF; line-height: 1.35;">${s.headline}</div>
                  </a>
                  ${s.tldr ? `<div style="font-size: 13px; color: #71717a; margin-top: 4px; line-height: 1.4;">${s.tldr}</div>` : ""}
                </td>
                <td width="40" align="right" style="vertical-align: top;">
                  ${!s.is_free ? '<span style="font-size: 9px; font-weight: 800; color: #F59E0B; background: rgba(245,158,11,0.12); padding: 2px 6px; border-radius: 99px;">PRO</span>' : ""}
                </td>
              </tr>
            </table>
          </td>
        </tr>`
    )
    .join("");

  const numberBlock = numberStory
    ? `
        <!-- THE NUMBER -->
        <tr>
          <td style="padding: 28px 0;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="background: linear-gradient(135deg, #1a1500, #111); border: 1px solid #F59E0B33; border-radius: 12px;">
              <tr>
                <td style="padding: 24px; text-align: center;">
                  <div style="font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; color: #F59E0B;">The Number</div>
                  <div style="font-size: 14px; color: #d4d4d8; margin-top: 12px; line-height: 1.5;">
                    ${numberStory.tldr || numberStory.headline}
                  </div>
                  <a href="https://thedailypoop.com/story/${numberStory.id}" style="display: inline-block; margin-top: 10px; font-size: 12px; color: #F59E0B; text-decoration: none; font-weight: 600;">
                    Read more &rarr;
                  </a>
                </td>
              </tr>
            </table>
          </td>
        </tr>`
    : "";

  // Beehiiv Ad Network will auto-inject ads between content blocks
  return `
<table cellpadding="0" cellspacing="0" border="0" width="100%" style="background-color: #000; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
  <tr>
    <td align="center" style="padding: 20px;">
      <table cellpadding="0" cellspacing="0" border="0" width="560" style="max-width: 560px;">

        <!-- HEADER -->
        <tr>
          <td style="padding: 32px 0 24px; text-align: center;">
            <a href="https://thedailypoop.com" style="text-decoration: none;">
              <img src="https://thedailypoop.com/logo.png" width="56" height="56" alt="TheDailyPoop" style="border: 0; display: inline-block;" />
            </a>
            <div style="font-size: 24px; font-weight: 900; color: #FFF; letter-spacing: -0.03em; margin-top: 12px;">
              TheDailyPoop
            </div>
            <div style="font-size: 12px; color: #52525b; margin-top: 6px; letter-spacing: 0.5px;">
              ${formattedDate.toUpperCase()}
            </div>
          </td>
        </tr>

        <!-- TODAY'S VIBE -->
        ${
          briefing.vibe_label
            ? `
        <tr>
          <td style="padding: 0 0 24px; text-align: center;">
            <table cellpadding="0" cellspacing="0" border="0" align="center">
              <tr>
                <td style="background: #111; border: 1px solid #222; border-radius: 99px; padding: 8px 20px;">
                  <span style="font-size: 14px;">${briefing.vibe_emoji || "🌀"}</span>
                  <span style="font-size: 13px; font-weight: 700; color: #e4e4e7; margin-left: 6px;">Today's Vibe: ${briefing.vibe_label}</span>
                </td>
              </tr>
            </table>
          </td>
        </tr>`
            : ""
        }

        <!-- DIVIDER -->
        <tr>
          <td style="padding: 0 0 28px;">
            <div style="height: 1px; background: linear-gradient(to right, transparent, #333, transparent);"></div>
          </td>
        </tr>

        <!-- STORY COUNT INTRO -->
        <tr>
          <td style="padding: 0 0 24px;">
            <div style="font-size: 13px; color: #71717a; text-align: center;">
              ${stories.length} stories today &middot; ${Math.round(stories.length * 0.8)} min read
            </div>
          </td>
        </tr>

        <!-- FEATURED STORIES (Top 5 — full cards) -->
        ${featuredBlocks}

        ${numberBlock}

        <!-- QUICK HITS SECTION -->
        ${
          quickHits.length > 0
            ? `
        <tr>
          <td style="padding: 24px 0 8px;">
            <div style="font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; color: #F59E0B;">
              ⚡ Quick Hits
            </div>
          </td>
        </tr>
        ${quickHitRows}`
            : ""
        }

        <!-- GAMES CTA -->
        <tr>
          <td style="padding: 32px 0;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="background: #111; border: 1px solid #222; border-radius: 12px;">
              <tr>
                <td style="padding: 24px; text-align: center;">
                  <div style="font-size: 24px;">🎮</div>
                  <div style="font-size: 16px; font-weight: 800; color: #FFF; margin-top: 8px;">
                    Play Today's Games
                  </div>
                  <div style="font-size: 13px; color: #71717a; margin-top: 4px; line-height: 1.4;">
                    6 AI-powered games refreshed daily. Poop or Scoop is free — can you spot the fake headlines?
                  </div>
                  <a href="https://thedailypoop.com/games" style="display: inline-block; margin-top: 14px; background: #F59E0B; color: #000; font-size: 13px; font-weight: 700; padding: 10px 24px; border-radius: 99px; text-decoration: none;">
                    Play Now on Web
                  </a>
                  <div style="margin-top: 10px;">
                    <a href="https://apps.apple.com/app/thedailypoop/id6738030377" style="font-size: 12px; color: #F59E0B; text-decoration: none; font-weight: 600;">
                      or download the app &rarr;
                    </a>
                  </div>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- READ ON WEB -->
        <tr>
          <td style="padding: 0 0 24px; text-align: center;">
            <a href="https://thedailypoop.com/today" style="font-size: 13px; color: #F59E0B; text-decoration: none; font-weight: 700;">
              Read all stories on the web &rarr;
            </a>
          </td>
        </tr>

        <!-- FOOTER -->
        <tr>
          <td style="padding: 24px 0 8px;">
            <div style="height: 1px; background: linear-gradient(to right, transparent, #222, transparent);"></div>
          </td>
        </tr>
        <tr>
          <td style="padding: 16px 0; text-align: center;">
            <a href="https://thedailypoop.com" style="text-decoration: none;">
              <img src="https://thedailypoop.com/logo.png" width="28" height="28" alt="" style="border: 0; display: inline-block; opacity: 0.5;" />
            </a>
            <div style="font-size: 11px; color: #3f3f46; margin-top: 10px; line-height: 1.8;">
              You're getting this because you're one of us.<br>
              <a href="https://thedailypoop.com" style="color: #52525b; text-decoration: none;">thedailypoop.com</a><br>
              Not your vibe anymore? Unsubscribe below — no hard feelings.
            </div>
          </td>
        </tr>

      </table>
    </td>
  </tr>
</table>`;
}
