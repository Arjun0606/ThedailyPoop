import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { fetchAllCategories } from "@/lib/perplexity";
import { generateWithPremium, generateWithMini } from "@/lib/openai";
import { fetchOgImages } from "@/lib/og-image";

const STYLE_GUIDE = `You are the voice of TheDailyPoop — imagine if your funniest, most unhinged friend who also happens to be weirdly knowledgeable about finance, tech, and culture was texting you the news every morning. You sound like Dan Toomey meets Morning Brew meets a group chat that's way too smart for its own good.

YOUR PERSONALITY:
- You're the friend who makes everyone at the table spit out their coffee
- You explain complex shit so simply that a 19-year-old AND a 35-year-old both feel smart
- You have ZERO patience for corporate PR speak — you translate it into what they actually mean
- You're the person at a party who makes economics sound like the most interesting thing ever
- You're lowkey obsessed with how money and power actually work

VOICE RULES:
- Write like you're voice-noting your group chat, not writing an article
- Start stories with a HOOK that makes people stop scrolling — a wild stat, a spicy take, or a "wait what?"
- Explain business/finance concepts with comparisons to real life: "That's like if your landlord raised rent 40% and then said 'we're doing this for you'"
- Use gen z language NATURALLY (not forced): "no cap", "lowkey", "that's crazy", "the math ain't mathing" — but only when it fits
- Drop specific references: Minecraft, Fortnite, TikTok trends, Drake, Taylor Swift, Netflix shows — whatever is relevant
- Be ACTUALLY funny. Not "in a move that surprised absolutely no one" (that's AI humor and it's ass). Real humor like: "Amazon made $150B in revenue which is roughly what you'd spend on Prime same-day delivery if you have no impulse control"
- Swear like a normal person — "this is wild", "what the hell", "they're cooked" — not gratuitous, just natural
- Call out hypocrisy and BS HARD: "Company posts record profits → lays off 10,000 people → CEO buys third yacht. Make it make sense"
- Every story MUST end with "The Bottom Line:" — this is the quotable take. It should be the line people screenshot and send to friends. Make it SHARP.

STRUCTURE:
- Paragraphs are 1-3 sentences MAX. If a paragraph is 4+ sentences, you've lost them.
- Lead with WHY THIS MATTERS TO YOU, not what happened
- Use line breaks liberally — this is mobile reading, not a newspaper
- The tone should make someone think "damn, I actually understand this now" AND "lmaooo"

WHAT TO AVOID:
- Never sound like a news anchor or a textbook
- Never use "in a stunning turn of events", "it remains to be seen", "only time will tell", "in today's fast-paced world"
- Never start with "Well," or "So," — start with something that HITS
- Never be cringe — if a joke feels forced, cut it. One genuine funny line beats three try-hard ones
- Never punch down — punch UP at corporations, billionaires, and politicians. Your readers are the regular people.
- Never use the word "delve" or "landscape" or "paradigm" or "synergy" — those are dead giveaways you're AI`;

function extractJSON(text: string): string {
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) return fenceMatch[1].trim();
  return text.trim();
}

function getCategoryEmoji(category: string): string {
  switch (category) {
    case "business": return "💰";
    case "tech": return "📱";
    case "politics": return "🏛️";
    case "sports": return "🏆";
    default: return "🎬";
  }
}

interface DropConfig {
  id: string;
  name: string;
  cron: string;
  dropType: string;
  storyCount: number;
  freeCount: number;
  timeFocus?: string;
  headlineStyle: string;
}

function createDropFunction(config: DropConfig) {
  return inngest.createFunction(
    { id: config.id, name: config.name },
    { cron: config.cron },
    async ({ step }) => {
      const db = createServiceClient();
      const today = new Date().toISOString().split("T")[0];

      // Check if this drop already exists for today
      const existing = await step.run("check-existing", async () => {
        const { data } = await db
          .from("briefings")
          .select("id")
          .eq("publish_date", today)
          .eq("drop_type", config.dropType)
          .single();
        return data;
      });

      if (existing) {
        return { skipped: true, reason: `${config.dropType} drop already exists for today` };
      }

      // Step 1: Fetch trending news from Perplexity
      const rawStories = await step.run("fetch-news", async () => {
        const results = await fetchAllCategories(config.timeFocus);
        return results;
      });

      const allStories = rawStories.flatMap((r) =>
        r.stories.map((s) => ({ ...s, category: r.category }))
      );

      if (allStories.length === 0) {
        return { error: "No stories fetched from Perplexity" };
      }

      // Step 2: Curate & rank stories
      const curatedStories = await step.run("curate-stories", async () => {
        const storiesJson = JSON.stringify(allStories, null, 2);

        const result = await generateWithPremium(
          `You are the editorial director at TheDailyPoop — the news app that makes finance, tech, politics, sports, and culture actually interesting to young people. Your job is to pick the ${config.storyCount} stories that will make our readers say "yooo no way" and send to their group chat.

SELECTION CRITERIA (in order of importance):
1. "Holy shit factor" — would someone screenshot this and text it to a friend?
2. Money impact — does this affect people's wallets, jobs, or future?
3. Conversation starter — will people argue about this at lunch?
4. Meme potential — is this inherently funny, ironic, or absurd?
5. Power moves — big corporations, billionaires, or politicians doing wild things

HARD RULES:
- Stories 1-${config.freeCount} are FREE (these need to be absolute bangers to hook people into premium)
- Stories ${config.freeCount + 1}-${config.storyCount} are PREMIUM
- Mix across categories: spread evenly across business, tech, politics, sports, culture — but flex if one category has weaker stories
- SKIP boring earnings reports unless the numbers are genuinely shocking
- SKIP generic "company releases new product" unless it's actually a big deal
- SKIP dry policy stories unless the impact is massive or the hypocrisy is wild
- PRIORITIZE stories with conflict, irony, huge numbers, or real consequences

Return a JSON array of exactly ${config.storyCount} objects with keys: title, summary, sourceUrl, sourceName, category ("business" | "tech" | "politics" | "sports" | "culture"), rank (1-${config.storyCount}).
Return ONLY the JSON array.`,
          `Here are today's raw stories:\n\n${storiesJson}`
        );

        try {
          return JSON.parse(extractJSON(result));
        } catch {
          console.error("Failed to parse curation result:", result.substring(0, 300));
          return allStories.slice(0, config.storyCount).map((s, i) => ({
            ...s,
            rank: i + 1,
          }));
        }
      });

      // Step 3: Fetch OG images from source articles
      const ogImages = await step.run("fetch-og-images", async () => {
        const urls: string[] = curatedStories
          .map((s: { sourceUrl?: string }) => s.sourceUrl)
          .filter(Boolean) as string[];

        const imageMap = await fetchOgImages(urls);
        return Object.fromEntries(imageMap);
      });

      // Step 4: Rewrite each story in TheDailyPoop voice
      const rewrittenStories = await step.run("rewrite-stories", async () => {
        const results = [];

        for (let i = 0; i < Math.min(curatedStories.length, config.storyCount); i++) {
          const story = curatedStories[i];
          const categoryEmoji = getCategoryEmoji(story.category);

          const result = await generateWithPremium(
            STYLE_GUIDE,
            `Rewrite this news story for TheDailyPoop. Make it genuinely entertaining AND informative.

ORIGINAL STORY:
Title: ${story.title}
Summary: ${story.summary}
Source: ${story.sourceName}
Category: ${story.category}

WHAT I NEED (return as JSON object):

"headline": A headline that makes someone stop scrolling. Max 80 chars. Examples of GOOD headlines:
- "Apple Just Admitted Their AI Can't Count and Honestly, Same"
- "JPMorgan Made More Money Than God Last Quarter"
- "TikTok's CEO Went to Congress and Chose Violence"
Examples of BAD headlines (do NOT write like this):
- "Apple Releases Update to Address AI Concerns"
- "JPMorgan Reports Strong Q4 Earnings"

"body": The full story in 200-400 words. Structure:
1. HOOK (first 1-2 sentences): Start with the most insane detail, a wild stat, or a spicy take. NOT "So here's what happened" — more like "Netflix just spent $17 billion on content this year. That's enough to buy every house in Wyoming. Twice."
2. CONTEXT (2-3 short paragraphs): Explain what happened AND why it matters to the reader. Use analogies to make complex stuff click. Break down numbers into relatable terms.
3. THE BOTTOM LINE: End with exactly "The Bottom Line:" followed by a one-liner that's quotable, sharp, and makes people want to share it. This is the line that goes on their Instagram story.

"tldr": One sentence, casual tone, that captures the vibe. Like something you'd text: "basically apple fumbled again lol"

Return ONLY the JSON object, no markdown fences, no explanation.`
          );

          try {
            const parsed = JSON.parse(extractJSON(result));
            results.push({
              sortOrder: i + 1,
              isFree: i < config.freeCount,
              category: story.category,
              headline: parsed.headline ?? story.title,
              body: parsed.body ?? story.summary,
              tldr: parsed.tldr ?? null,
              sourceUrl: story.sourceUrl ?? null,
              sourceName: story.sourceName ?? null,
              imageUrl: story.sourceUrl ? ogImages[story.sourceUrl] ?? null : null,
              emoji: categoryEmoji,
            });
          } catch {
            results.push({
              sortOrder: i + 1,
              isFree: i < config.freeCount,
              category: story.category,
              headline: story.title,
              body: story.summary,
              tldr: null,
              sourceUrl: story.sourceUrl ?? null,
              sourceName: story.sourceName ?? null,
              imageUrl: story.sourceUrl ? ogImages[story.sourceUrl] ?? null : null,
              emoji: categoryEmoji,
            });
          }
        }

        return results;
      });

      // Step 5: Generate briefing headline + intro
      const briefingMeta = await step.run("generate-headline", async () => {
        const storyHeadlines = rewrittenStories
          .map((s) => `${s.emoji} ${s.headline}`)
          .join("\n");

        const result = await generateWithMini(
          STYLE_GUIDE,
          `Write the ${config.dropType} briefing header for TheDailyPoop.

Today's stories:
${storyHeadlines}

${config.headlineStyle}

Return ONLY JSON.`
        );

        try {
          return JSON.parse(extractJSON(result));
        } catch {
          return {
            headline: config.dropType === "morning"
              ? "Your Daily Scoop Is Here"
              : config.dropType === "midday"
              ? "Midday Drop Just Landed"
              : "Evening Wrap Is In",
            introText: "Here's what matters right now.",
          };
        }
      });

      // Step 6: Save everything to Supabase
      const saved = await step.run("save-to-db", async () => {
        const { data: briefing, error: briefingError } = await db
          .from("briefings")
          .insert({
            publish_date: today,
            drop_type: config.dropType,
            headline: briefingMeta.headline,
            intro_text: briefingMeta.introText,
            story_count: rewrittenStories.length,
            free_story_count: rewrittenStories.filter((s) => s.isFree).length,
            status: "published",
            published_at: new Date().toISOString(),
          })
          .select("id")
          .single();

        if (briefingError || !briefing) {
          throw new Error(
            `Failed to insert briefing: ${briefingError?.message}`
          );
        }

        const storyRows = rewrittenStories.map((s) => ({
          briefing_id: briefing.id,
          sort_order: s.sortOrder,
          is_free: s.isFree,
          category: s.category,
          headline: s.headline,
          body: s.body,
          tldr: s.tldr,
          source_url: s.sourceUrl,
          source_name: s.sourceName,
          image_url: s.imageUrl,
          emoji: s.emoji,
        }));

        const { error: storiesError } = await db
          .from("stories")
          .insert(storyRows);

        if (storiesError) {
          throw new Error(
            `Failed to insert stories: ${storiesError.message}`
          );
        }

        return { briefingId: briefing.id, storyCount: storyRows.length };
      });

      // Trigger Word Drop game generation
      await step.sendEvent("trigger-word-game", {
        name: "briefing/published",
        data: {
          briefingId: saved.briefingId,
          dropType: config.dropType,
          publishDate: today,
        },
      });

      return {
        success: true,
        dropType: config.dropType,
        briefingId: saved.briefingId,
        storyCount: saved.storyCount,
        headline: briefingMeta.headline,
      };
    }
  );
}

// Morning Drop — 10 stories, runs at 5 AM
export const generateMorningDrop = createDropFunction({
  id: "generate-morning-drop",
  name: "Generate Morning Drop",
  cron: "0 5 * * *",
  dropType: "morning",
  storyCount: 10,
  freeCount: 3,
  headlineStyle: `Return a JSON object with:
"headline": A punchy 3-8 word title that captures today's vibe. Think newspaper headline meets meme. Max 60 chars. Examples: "Tech Bros Are Down Bad Today", "Your Portfolio Called. It's Crying.", "Everyone Got Fired Except AI"
"introText": 2-3 sentences that make people NEED to scroll down. Be specific — reference 1-2 of the craziest stories. Don't be generic. Bad: "Another big day in the news!" Good: "Apple somehow made $90 billion while also forgetting how math works, TikTok's CEO went full savage in Congress, and someone just paid $4M for a JPEG. Happy Tuesday."`,
});

// Midday Drop — 5 stories, runs at 12 PM
export const generateMiddayDrop = createDropFunction({
  id: "generate-midday-drop",
  name: "Generate Midday Drop",
  cron: "0 12 * * *",
  dropType: "midday",
  storyCount: 5,
  freeCount: 1,
  timeFocus: "Focus ONLY on stories that broke or developed significantly in the LAST 6 HOURS. I want fresh breaking news, not stories from this morning. If a story has been developing, give me the latest update.",
  headlineStyle: `Return a JSON object with:
"headline": A punchy 3-6 word title for the MIDDAY update. Max 50 chars. Examples: "Afternoon Plot Twist", "Lunch Break Chaos", "Things Just Got Spicy"
"introText": 1-2 sentences teasing the hottest story that just broke. Keep it urgent — this is breaking news energy.`,
});

// Evening Drop — 3 stories, runs at 5 PM
export const generateEveningDrop = createDropFunction({
  id: "generate-evening-drop",
  name: "Generate Evening Drop",
  cron: "0 17 * * *",
  dropType: "evening",
  storyCount: 3,
  freeCount: 1,
  timeFocus: "Focus on the BIGGEST stories of the entire day — the ones everyone is talking about tonight. Include stories that developed or escalated throughout the day, and any late-breaking stories from the afternoon.",
  headlineStyle: `Return a JSON object with:
"headline": A punchy 3-6 word title wrapping up the day. Max 50 chars. Examples: "Today Was a Movie", "That's a Wrap, Folks", "Day's Final Plot Twist"
"introText": 1-2 sentences that sum up today's vibe. What was the theme? What will people be talking about at dinner?`,
});

// Keep backward-compat export name for existing registrations
export const generateDailyBriefing = generateMorningDrop;
