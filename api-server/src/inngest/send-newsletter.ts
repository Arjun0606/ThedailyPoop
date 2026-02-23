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

    // Get subscriber count for social proof
    const subscriberCount = await step.run("get-subscriber-count", async () => {
      const { count } = await db
        .from("newsletter_subscribers")
        .select("*", { count: "exact", head: true })
        .eq("status", "active");
      return count ?? 0;
    });

    // Build newsletter HTML and publish to Beehiiv
    const result = await step.run("publish-to-beehiiv", async () => {
      const html = buildNewsletterHTML(stories, briefing, today, subscriberCount);

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

// --- NEWSLETTER-EXCLUSIVE CONTENT GENERATORS ---

const OPENING_LINES = [
  "Another day, another disaster. Let's get into it.",
  "The news is dumb. We made it dumber. You're welcome.",
  "Coffee first. Then chaos.",
  "We read the news so you don't have to cry alone.",
  "Today's forecast: 100% chance of audacity.",
  "Welcome back to the worst timeline. Here's your recap.",
  "Somewhere, a PR team is already panicking. Let's see why.",
  "Some days the news writes itself. Today was not subtle.",
  "You could skip the news today. But you'd miss the best parts.",
  "Buckle up. Today's news had zero chill.",
  "Hot takes, served fresh. No filter, no apologies.",
  "The world didn't slow down overnight. Neither did we.",
  "If today's news were a movie, it'd be rated R.",
  "Your boss can wait. This can't.",
  "We found the chaos so you don't have to doom-scroll.",
];

function getOpeningLine(date: string): string {
  // Deterministic based on date so it's consistent if regenerated
  const hash = date.split("-").reduce((acc, n) => acc + parseInt(n), 0);
  return OPENING_LINES[hash % OPENING_LINES.length];
}

function extractTheNumber(stories: Story[]): { number: string; context: string; storyId: string } | null {
  const patterns = [
    /(\$[\d,.]+\s*(million|billion|trillion)?)/i,
    /(\d{1,3}(,\d{3})+)/,
    /(\d+(\.\d+)?%)/,
    /(\d+\s*(million|billion|trillion))/i,
  ];

  for (const story of stories) {
    for (const pattern of patterns) {
      const match = story.body.match(pattern);
      if (match) {
        const sentences = story.body.split(/[.!?]+/);
        const sentence = sentences.find((s) => s.includes(match[1]));
        if (sentence) {
          return {
            number: match[1].trim(),
            context: sentence.trim().slice(0, 120),
            storyId: story.id,
          };
        }
      }
    }
  }
  return null;
}

function pickBottomLine(stories: Story[]): Story | null {
  const funnyCategories = ["politics", "culture", "world"];
  const withTldr = stories.filter((s) => s.tldr);
  const funny = withTldr.filter((s) => funnyCategories.includes(s.category.toLowerCase()));
  const pool = funny.length > 0 ? funny : withTldr;
  return pool.length > 2 ? pool[Math.floor(pool.length / 2)] : pool[0] || null;
}

// Pick "If You Only Read One Thing" — the most impactful story
function pickOneThingStory(stories: Story[]): Story {
  // Prefer pro stories (they're the premium content), or first story as fallback
  const pro = stories.filter((s) => !s.is_free && s.tldr);
  return pro[0] || stories[0];
}

// Generate daily poll question from today's stories
function generatePoll(stories: Story[]): { question: string; options: string[] } {
  const POLL_TEMPLATES = [
    {
      question: "Who had the worst day?",
      pickFrom: (s: Story[]) => s.slice(0, 4).map((x) => x.headline.split(/[:\-–—]/).pop()?.trim().slice(0, 40) || x.category),
    },
    {
      question: "Which headline sounds fake but isn't?",
      pickFrom: (s: Story[]) => s.filter((x) => x.is_free).slice(0, 4).map((x) => x.headline.slice(0, 45)),
    },
    {
      question: "What's the biggest story today?",
      pickFrom: (s: Story[]) => s.slice(0, 4).map((x) => `${x.emoji || "📰"} ${x.headline.slice(0, 40)}`),
    },
  ];

  const today = new Date();
  const template = POLL_TEMPLATES[today.getDate() % POLL_TEMPLATES.length];
  const options = template.pickFrom(stories);
  return { question: template.question, options: options.slice(0, 4) };
}

interface SponsorSlot {
  name: string;
  tagline: string;
  url: string;
  position: "header" | "midroll" | "quickhits";
}

function buildSponsorHTML(sponsor: SponsorSlot): string {
  return `
        <tr>
          <td style="padding: 16px 0;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="background: #0a0a0a; border: 1px solid #222; border-radius: 12px;">
              <tr>
                <td style="padding: 16px 20px;">
                  <div style="font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: #52525b; margin-bottom: 8px;">Sponsored</div>
                  <a href="${sponsor.url}" style="text-decoration: none;">
                    <div style="font-size: 14px; font-weight: 800; color: #FFF;">${sponsor.name}</div>
                    <div style="font-size: 13px; color: #a1a1aa; margin-top: 4px; line-height: 1.5;">${sponsor.tagline}</div>
                    <div style="margin-top: 8px; font-size: 12px; color: #F59E0B; font-weight: 700;">Learn more &rarr;</div>
                  </a>
                </td>
              </tr>
            </table>
          </td>
        </tr>`;
}

function buildNewsletterHTML(
  stories: Story[],
  briefing: { vibe_label?: string; vibe_emoji?: string },
  date: string,
  subscriberCount: number,
  sponsors?: SponsorSlot[]
) {
  const formattedDate = new Date(date + "T12:00:00").toLocaleDateString(
    "en-US",
    { weekday: "long", month: "long", day: "numeric", year: "numeric" }
  );

  const openingLine = getOpeningLine(date);
  const oneThingStory = pickOneThingStory(stories);
  const featured = stories.slice(0, 5);

  // Sponsor slots (render only if provided)
  const headerSponsor = sponsors?.find((s) => s.position === "header");
  const midrollSponsor = sponsors?.find((s) => s.position === "midroll");
  const quickhitsSponsor = sponsors?.find((s) => s.position === "quickhits");
  const quickHits = stories.slice(5);
  const theNumber = extractTheNumber(stories);
  const bottomLine = pickBottomLine(stories.slice(5));
  const poll = generatePoll(stories);

  // Category breakdown for scoreboard
  const categoryCounts: Record<string, number> = {};
  for (const s of stories) {
    const cat = s.category.toLowerCase();
    categoryCounts[cat] = (categoryCounts[cat] || 0) + 1;
  }
  const topCategories = Object.entries(categoryCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 4);

  const categoryEmojis: Record<string, string> = {
    politics: "🏛️", tech: "⚡", business: "💰", culture: "🎭",
    sports: "🏆", world: "🌍", science: "🔬", health: "🩺",
  };

  const featuredBlocks = featured
    .map(
      (s, i) => `
        <tr>
          <td style="padding: 0 0 ${i < featured.length - 1 ? "20px" : "0"} 0;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="background: #111; border-radius: 12px; overflow: hidden;">
              <tr>
                <td style="padding: 16px 20px 0;">
                  <table cellpadding="0" cellspacing="0" border="0" width="100%">
                    <tr>
                      <td><span style="font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: #F59E0B; background: rgba(245,158,11,0.12); padding: 3px 8px; border-radius: 99px;">${s.category}</span></td>
                      <td align="right">${!s.is_free ? '<span style="font-size: 10px; font-weight: 800; color: #F59E0B;">PRO</span>' : ""}</td>
                    </tr>
                  </table>
                </td>
              </tr>
              <tr>
                <td style="padding: 12px 20px 0;">
                  <span style="font-size: 24px;">${s.emoji || "📰"}</span>
                  <a href="https://thedailypoop.lol/story/${s.id}" style="text-decoration: none;">
                    <div style="font-size: 18px; font-weight: 800; color: #FFFFFF; line-height: 1.3; margin-top: 8px;">${s.headline}</div>
                  </a>
                </td>
              </tr>
              ${s.tldr ? `<tr><td style="padding: 8px 20px 0;"><div style="font-size: 14px; color: #a1a1aa; line-height: 1.5; font-style: italic;">TL;DR: ${s.tldr}</div></td></tr>` : ""}
              <tr>
                <td style="padding: 10px 20px 0;">
                  <div style="font-size: 14px; color: #d4d4d8; line-height: 1.65;">${s.body.split("\n\n").slice(0, 2).join("<br><br>")}</div>
                </td>
              </tr>
              <tr>
                <td style="padding: 12px 20px 16px;">
                  <a href="https://thedailypoop.lol/story/${s.id}" style="font-size: 13px; color: #F59E0B; text-decoration: none; font-weight: 700;">Keep reading &rarr;</a>
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
                <td width="32" style="vertical-align: top; font-size: 20px; padding-right: 10px;">${s.emoji || "📰"}</td>
                <td style="vertical-align: top;">
                  <a href="https://thedailypoop.lol/story/${s.id}" style="text-decoration: none;">
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

  const subscriberProof =
    subscriberCount >= 100
      ? `<div style="font-size: 11px; color: #52525b; margin-top: 4px;">Join ${subscriberCount.toLocaleString()}+ readers</div>`
      : "";

  // Poll options as visual buttons (link to website since email can't have real interactivity)
  const pollHTML = `
        <tr>
          <td style="padding: 24px 0;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="background: #0a0a0a; border: 1px solid #1a1a1a; border-radius: 12px;">
              <tr>
                <td style="padding: 20px;">
                  <div style="font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; color: #F59E0B; margin-bottom: 10px;">🗳️ Daily Poll</div>
                  <div style="font-size: 16px; font-weight: 800; color: #FFF; margin-bottom: 14px;">${poll.question}</div>
                  ${poll.options
                    .map(
                      (opt) => `
                  <div style="margin-bottom: 8px;">
                    <a href="https://thedailypoop.lol/today" style="display: block; text-decoration: none; padding: 10px 14px; background: #111; border: 1px solid #222; border-radius: 8px; font-size: 13px; color: #d4d4d8; transition: background 0.2s;">${opt}</a>
                  </div>`
                    )
                    .join("")}
                  <div style="font-size: 11px; color: #3f3f46; margin-top: 6px;">Reply with your answer — we'll share results tomorrow</div>
                </td>
              </tr>
            </table>
          </td>
        </tr>`;

  return `
<table cellpadding="0" cellspacing="0" border="0" width="100%" style="background-color: #000; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
  <tr>
    <td align="center" style="padding: 20px;">
      <table cellpadding="0" cellspacing="0" border="0" width="560" style="max-width: 560px;">

        <!-- HEADER -->
        <tr>
          <td style="padding: 32px 0 20px; text-align: center;">
            <a href="https://thedailypoop.lol" style="text-decoration: none;">
              <img src="https://thedailypoop.lol/logo.png" width="56" height="56" alt="TheDailyPoop" style="border: 0; display: inline-block;" />
            </a>
            <div style="font-size: 24px; font-weight: 900; color: #FFF; letter-spacing: -0.03em; margin-top: 12px;">TheDailyPoop</div>
            <div style="font-size: 11px; color: #52525b; margin-top: 6px; letter-spacing: 1px; text-transform: uppercase;">${formattedDate}</div>
            ${subscriberProof}
          </td>
        </tr>

        <!-- OPENING LINE -->
        <tr>
          <td style="padding: 0 0 20px; text-align: center;">
            <div style="font-size: 15px; color: #a1a1aa; font-style: italic; line-height: 1.5;">${openingLine}</div>
          </td>
        </tr>

        ${headerSponsor ? buildSponsorHTML(headerSponsor) : ""}

        <!-- TODAY'S VIBE -->
        ${briefing.vibe_label ? `
        <tr>
          <td style="padding: 0 0 20px; text-align: center;">
            <table cellpadding="0" cellspacing="0" border="0" align="center">
              <tr>
                <td style="background: #111; border: 1px solid #222; border-radius: 99px; padding: 8px 20px;">
                  <span style="font-size: 14px;">${briefing.vibe_emoji || "🌀"}</span>
                  <span style="font-size: 13px; font-weight: 700; color: #e4e4e7; margin-left: 6px;">Today's Vibe: ${briefing.vibe_label}</span>
                </td>
              </tr>
            </table>
          </td>
        </tr>` : ""}

        <!-- IF YOU ONLY READ ONE THING -->
        <tr>
          <td style="padding: 0 0 24px;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="border: 2px solid #F59E0B; border-radius: 12px; overflow: hidden;">
              <tr>
                <td style="background: linear-gradient(135deg, #1a1200, #0a0a00); padding: 20px;">
                  <div style="font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; color: #F59E0B; margin-bottom: 10px;">👆 If You Only Read One Thing</div>
                  <a href="https://thedailypoop.lol/story/${oneThingStory.id}" style="text-decoration: none;">
                    <div style="font-size: 17px; font-weight: 800; color: #FFF; line-height: 1.3;">${oneThingStory.emoji || "📰"} ${oneThingStory.headline}</div>
                  </a>
                  ${oneThingStory.tldr ? `<div style="font-size: 13px; color: #a1a1aa; margin-top: 8px; line-height: 1.5;">${oneThingStory.tldr}</div>` : ""}
                  <a href="https://thedailypoop.lol/story/${oneThingStory.id}" style="display: inline-block; margin-top: 10px; font-size: 13px; color: #F59E0B; text-decoration: none; font-weight: 700;">Read this one &rarr;</a>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- TODAY'S SCOREBOARD -->
        <tr>
          <td style="padding: 0 0 24px;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="background: #0a0a0a; border: 1px solid #1a1a1a; border-radius: 12px;">
              <tr>
                <td style="padding: 16px 20px;">
                  <div style="font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; color: #71717a; margin-bottom: 12px;">Today's Scoreboard</div>
                  <table cellpadding="0" cellspacing="0" border="0" width="100%">
                    <tr>
                      <td style="text-align: center; width: 25%;">
                        <div style="font-size: 22px; font-weight: 900; color: #FFF;">${stories.length}</div>
                        <div style="font-size: 10px; color: #52525b; margin-top: 2px;">STORIES</div>
                      </td>
                      ${topCategories.map(([cat, count]) => `
                      <td style="text-align: center; width: 25%;">
                        <div style="font-size: 18px;">${categoryEmojis[cat] || "📰"}</div>
                        <div style="font-size: 11px; color: #71717a; margin-top: 2px;">${count} ${cat}</div>
                      </td>`).join("")}
                    </tr>
                  </table>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- DIVIDER -->
        <tr><td style="padding: 0 0 24px;"><div style="height: 1px; background: linear-gradient(to right, transparent, #333, transparent);"></div></td></tr>

        <!-- TOP STORIES -->
        <tr><td style="padding: 0 0 8px;"><div style="font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; color: #F59E0B;">🔥 Today's Top Stories</div></td></tr>
        ${featuredBlocks}

        ${midrollSponsor ? buildSponsorHTML(midrollSponsor) : ""}

        <!-- THE NUMBER -->
        ${theNumber ? `
        <tr>
          <td style="padding: 28px 0;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="border: 1px solid #F59E0B33; border-radius: 12px; overflow: hidden;">
              <tr>
                <td style="background: linear-gradient(135deg, #1a1500, #111); padding: 24px; text-align: center;">
                  <div style="font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; color: #F59E0B;">📊 The Number</div>
                  <div style="font-size: 32px; font-weight: 900; color: #F59E0B; margin-top: 12px;">${theNumber.number}</div>
                  <div style="font-size: 14px; color: #d4d4d8; margin-top: 8px; line-height: 1.5;">${theNumber.context}</div>
                  <a href="https://thedailypoop.lol/story/${theNumber.storyId}" style="display: inline-block; margin-top: 12px; font-size: 12px; color: #F59E0B; text-decoration: none; font-weight: 600;">Full story &rarr;</a>
                </td>
              </tr>
            </table>
          </td>
        </tr>` : ""}

        <!-- QUICK HITS -->
        ${quickHits.length > 0 ? `
        <tr><td style="padding: 20px 0 8px;"><div style="font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; color: #F59E0B;">⚡ Quick Hits</div></td></tr>
        ${quickHitRows}` : ""}

        ${quickhitsSponsor ? buildSponsorHTML(quickhitsSponsor) : ""}

        <!-- DAILY POLL -->
        ${pollHTML}

        <!-- THE BOTTOM LINE (Newsletter-Exclusive) -->
        ${bottomLine ? `
        <tr>
          <td style="padding: 4px 0 24px;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="border: 1px solid #333; border-radius: 12px; overflow: hidden;">
              <tr>
                <td style="background: #0a0a0a; padding: 24px;">
                  <div style="font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; color: #F59E0B; margin-bottom: 12px;">💬 The Bottom Line</div>
                  <div style="font-size: 15px; color: #e4e4e7; line-height: 1.6; font-style: italic;">"${bottomLine.body.split("\n\n").slice(-1)[0]?.slice(0, 200) || bottomLine.tldr || bottomLine.headline}"</div>
                  <div style="font-size: 12px; color: #52525b; margin-top: 10px;">— on <a href="https://thedailypoop.lol/story/${bottomLine.id}" style="color: #F59E0B; text-decoration: none;">${bottomLine.headline.slice(0, 60)}${bottomLine.headline.length > 60 ? "..." : ""}</a></div>
                  <div style="font-size: 11px; color: #3f3f46; margin-top: 8px;">📧 Newsletter exclusive — you won't find this in the app</div>
                </td>
              </tr>
            </table>
          </td>
        </tr>` : ""}

        <!-- REFERRAL PROGRAM -->
        <tr>
          <td style="padding: 4px 0 20px;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="background: linear-gradient(135deg, #111, #0a0a0a); border: 1px solid #F59E0B33; border-radius: 12px;">
              <tr>
                <td style="padding: 24px; text-align: center;">
                  <div style="font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; color: #F59E0B; margin-bottom: 8px;">🏆 Refer &amp; Earn</div>
                  <div style="font-size: 16px; font-weight: 800; color: #FFF;">Share TheDailyPoop, Get Rewarded</div>
                  <div style="font-size: 13px; color: #71717a; margin-top: 6px; line-height: 1.5;">Forward this email or share your link. Here's what you unlock:</div>
                  <table cellpadding="0" cellspacing="0" border="0" width="100%" style="margin-top: 16px;">
                    <tr>
                      <td style="padding: 8px; text-align: center; width: 50%;">
                        <div style="background: #1a1a1a; border-radius: 10px; padding: 14px 8px;">
                          <div style="font-size: 20px;">🎯</div>
                          <div style="font-size: 12px; font-weight: 800; color: #FFF; margin-top: 4px;">5 referrals</div>
                          <div style="font-size: 11px; color: #F59E0B; margin-top: 2px;">1 month Pro free</div>
                        </div>
                      </td>
                      <td style="padding: 8px; text-align: center; width: 50%;">
                        <div style="background: #1a1a1a; border-radius: 10px; padding: 14px 8px;">
                          <div style="font-size: 20px;">📣</div>
                          <div style="font-size: 12px; font-weight: 800; color: #FFF; margin-top: 4px;">25 referrals</div>
                          <div style="font-size: 11px; color: #F59E0B; margin-top: 2px;">Shoutout + 1 month Pro</div>
                        </div>
                      </td>
                    </tr>
                  </table>
                  <a href="https://thedailypoop.lol" style="display: inline-block; margin-top: 16px; background: #F59E0B; color: #000; font-size: 13px; font-weight: 700; padding: 10px 24px; border-radius: 99px; text-decoration: none;">Share Your Link</a>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- GAMES CTA -->
        <tr>
          <td style="padding: 4px 0 24px;">
            <table cellpadding="0" cellspacing="0" border="0" width="100%" style="background: #111; border: 1px solid #222; border-radius: 12px;">
              <tr>
                <td style="padding: 24px; text-align: center;">
                  <div style="font-size: 24px;">🎮</div>
                  <div style="font-size: 16px; font-weight: 800; color: #FFF; margin-top: 8px;">Play Today's Games</div>
                  <div style="font-size: 13px; color: #71717a; margin-top: 4px; line-height: 1.4;">6 AI-powered games refreshed daily. Can you spot the fake headlines?</div>
                  <a href="https://thedailypoop.lol/games" style="display: inline-block; margin-top: 14px; background: #F59E0B; color: #000; font-size: 13px; font-weight: 700; padding: 10px 24px; border-radius: 99px; text-decoration: none;">Play Free on Web</a>
                  <div style="margin-top: 10px;"><span style="font-size: 12px; color: #71717a; font-weight: 600;">iOS app coming soon</span></div>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- REPLY CTA (Deliverability Booster) -->
        <tr>
          <td style="padding: 0 0 24px; text-align: center;">
            <div style="font-size: 20px; margin-bottom: 6px;">💩 or 🍦?</div>
            <div style="font-size: 13px; color: #71717a; line-height: 1.5;">
              Hit reply with a <strong style="color: #d4d4d8;">💩</strong> if today's news was trash or <strong style="color: #d4d4d8;">🍦</strong> if it was a treat.<br>
              <span style="font-size: 11px; color: #3f3f46;">(Replies help us land in your inbox, not spam. For real.)</span>
            </div>
          </td>
        </tr>

        <!-- FOOTER -->
        <tr><td style="padding: 0 0 8px;"><div style="height: 1px; background: linear-gradient(to right, transparent, #222, transparent);"></div></td></tr>
        <tr>
          <td style="padding: 16px 0; text-align: center;">
            <a href="https://thedailypoop.lol" style="text-decoration: none;">
              <img src="https://thedailypoop.lol/logo.png" width="28" height="28" alt="" style="border: 0; display: inline-block; opacity: 0.5;" />
            </a>
            <div style="font-size: 11px; color: #3f3f46; margin-top: 10px; line-height: 1.8;">
              You're getting this because you're one of us.<br>
              <a href="https://thedailypoop.lol" style="color: #52525b; text-decoration: none;">thedailypoop.lol</a><br>
              Not your vibe anymore? Unsubscribe below — no hard feelings.
            </div>
          </td>
        </tr>

      </table>
    </td>
  </tr>
</table>`;
}
