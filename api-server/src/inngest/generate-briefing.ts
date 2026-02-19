import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { fetchAllCategories } from "@/lib/perplexity";
import { generateWithPremium, generateWithMini } from "@/lib/openai";
import { fetchOgImages } from "@/lib/og-image";

const STYLE_GUIDE = `You are the voice of TheDailyPoop — imagine the Wall Street Journal's editorial team got replaced by your funniest, sharpest friend who also happens to have a finance degree and zero filter. You sound like Dan Toomey meets Morning Brew meets a group chat that's way too smart for its own good.

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

function isFreeStory(index: number): boolean {
  // 10 free: first 2 deep dives + first 3 standard + first 5 quick hits
  if (index < 2) return true;                   // Deep Dive slots 0-1
  if (index >= 5 && index < 8) return true;      // Standard slots 5-7
  if (index >= 13 && index < 18) return true;    // Quick Hit slots 13-17
  return false;
}

const DEEP_DIVE_PROMPT = `"body": The full story in 1500-2000 words. Think WSJ longform meets your funniest friend. This is a DEEP DIVE — go hard. Structure:
1. HOOK (2-3 sentences): Start with the most insane detail — a wild number, an absurd situation, or a "wait what?" moment.
2. THE BACKSTORY (2-3 paragraphs): What led to this moment? Full context — timelines, key players. Make readers feel like insiders.
3. WHAT ACTUALLY HAPPENED (3-4 paragraphs): Details, quotes, specific numbers, reactions. Use analogies to make complex stuff click.
4. WHY YOU SHOULD CARE (1-2 paragraphs): How this affects the reader's money, career, or daily life. Be specific.
5. WHAT'S NEXT (1 paragraph): Stakes going forward.
6. THE BOTTOM LINE: End with exactly "The Bottom Line:" followed by a quotable one-liner for Instagram stories.`;

const STANDARD_PROMPT = `"body": The story in 500-700 words. Punchy, smart, no filler. Think Economist-style analysis but actually fun to read. Structure:
1. HOOK (1-2 sentences): The wildest detail or most important number.
2. WHAT HAPPENED (2-3 short paragraphs): Key facts, specific numbers, consequences. One killer analogy. 1-3 sentences per paragraph MAX.
3. WHY YOU SHOULD CARE (1 paragraph): Direct connection to reader's money, career, or life.
4. THE BOTTOM LINE: Quotable one-liner.`;

const QUICK_HIT_PROMPT = `"body": The story in 150-200 words. Speed read — hit them fast and hard. Structure:
1. HOOK (1 sentence): The wildest detail, period.
2. THE FACTS (2-3 sentences): What happened, the key number, who's involved.
3. WHY IT MATTERS (1 sentence): So what?
4. THE BOTTOM LINE: Sharp one-liner.`;

const STORY_COUNT = 20;

// ONE daily briefing — 20 articles (5 deep dives, 8 standard, 7 quick hits)
// Generated at 4 AM ET so content is ready when America wakes up
export const generateDailyBriefing = inngest.createFunction(
  { id: "generate-daily-briefing", name: "Generate Daily Briefing" },
  { cron: "0 9 * * *" }, // 9 AM UTC = 4 AM ET
  async ({ step }) => {
    const db = createServiceClient();
    const today = new Date().toISOString().split("T")[0];

    const existing = await step.run("check-existing", async () => {
      const { data } = await db
        .from("briefings")
        .select("id")
        .eq("publish_date", today)
        .eq("drop_type", "daily")
        .single();
      return data;
    });

    if (existing) {
      return { skipped: true, reason: "Daily briefing already exists" };
    }

    // Step 1: Fetch trending news (5 categories × 6 stories = 30 raw)
    const rawStories = await step.run("fetch-news", async () => {
      return await fetchAllCategories();
    });

    const allStories = rawStories.flatMap((r) =>
      r.stories.map((s) => ({ ...s, category: r.category }))
    );

    if (allStories.length === 0) {
      return { error: "No stories fetched from Perplexity" };
    }

    // Step 2: Curate & rank top 20
    const curatedStories = await step.run("curate-stories", async () => {
      const storiesJson = JSON.stringify(allStories, null, 2);

      const result = await generateWithPremium(
        `You are the editorial director at TheDailyPoop — imagine WSJ meets your unhinged group chat. Pick the ${STORY_COUNT} stories that will make readers say "yooo no way" and send to their friends.

SELECTION CRITERIA:
1. "Holy shit factor" — would someone screenshot this?
2. Money impact — wallets, jobs, or future?
3. Conversation starter — will people argue?
4. Meme potential — funny, ironic, absurd?
5. Power moves — corporations, billionaires, politicians doing wild things

RANKING:
- Stories 1-5: DEEP DIVES — absolute best stories deserving long-form treatment
- Stories 6-13: STANDARD — important stories needing solid coverage
- Stories 14-20: QUICK HITS — interesting stories as fast reads

HARD RULES:
- Mix categories: business, tech, politics, sports, culture
- SKIP boring earnings unless numbers are shocking
- SKIP generic product launches
- PRIORITIZE conflict, irony, huge numbers, real consequences

Return JSON array of ${STORY_COUNT} objects: title, summary, sourceUrl, sourceName, category, rank (1-${STORY_COUNT}).
ONLY the JSON array.`,
        `Raw stories:\n\n${storiesJson}`
      );

      try {
        return JSON.parse(extractJSON(result));
      } catch {
        console.error("Curation parse failed:", result.substring(0, 300));
        return allStories.slice(0, STORY_COUNT).map((s, i) => ({ ...s, rank: i + 1 }));
      }
    });

    // Step 3: Fetch OG images
    const ogImages = await step.run("fetch-og-images", async () => {
      const urls = curatedStories
        .map((s: { sourceUrl?: string }) => s.sourceUrl)
        .filter(Boolean) as string[];
      const imageMap = await fetchOgImages(urls);
      return Object.fromEntries(imageMap);
    });

    // Step 4a: Deep Dives (stories 1-5) — 1500-2000 words each
    const deepDives = await step.run("rewrite-deep-dives", async () => {
      const results = [];
      for (let i = 0; i < Math.min(5, curatedStories.length); i++) {
        const story = curatedStories[i];
        const emoji = getCategoryEmoji(story.category);
        const result = await generateWithPremium(
          STYLE_GUIDE,
          `Rewrite as a DEEP DIVE for TheDailyPoop. Flagship long-form — give it everything.

ORIGINAL: ${story.title}
Summary: ${story.summary}
Source: ${story.sourceName}
Category: ${story.category}

Return JSON:
"headline": Scroll-stopping, max 80 chars.
${DEEP_DIVE_PROMPT}
"tldr": One casual text-style sentence.

ONLY JSON, no fences.`
        );
        try {
          const parsed = JSON.parse(extractJSON(result));
          results.push({
            sortOrder: i + 1, isFree: isFreeStory(i), category: story.category,
            headline: parsed.headline ?? story.title, body: parsed.body ?? story.summary,
            tldr: parsed.tldr ?? null, sourceUrl: story.sourceUrl ?? null,
            sourceName: story.sourceName ?? null,
            imageUrl: story.sourceUrl ? ogImages[story.sourceUrl] ?? null : null, emoji,
          });
        } catch {
          results.push({
            sortOrder: i + 1, isFree: isFreeStory(i), category: story.category,
            headline: story.title, body: story.summary, tldr: null,
            sourceUrl: story.sourceUrl ?? null, sourceName: story.sourceName ?? null,
            imageUrl: story.sourceUrl ? ogImages[story.sourceUrl] ?? null : null, emoji,
          });
        }
      }
      return results;
    });

    // Step 4b: Standard stories (stories 6-13) — 500-700 words each
    const standard = await step.run("rewrite-standard", async () => {
      const results = [];
      const batch = curatedStories.slice(5, 13);
      for (let i = 0; i < batch.length; i++) {
        const gi = i + 5;
        const story = batch[i];
        const emoji = getCategoryEmoji(story.category);
        const result = await generateWithPremium(
          STYLE_GUIDE,
          `Rewrite as a STANDARD article for TheDailyPoop. Punchy, smart, no filler.

ORIGINAL: ${story.title}
Summary: ${story.summary}
Source: ${story.sourceName}
Category: ${story.category}

Return JSON:
"headline": Max 80 chars.
${STANDARD_PROMPT}
"tldr": One casual sentence.

ONLY JSON, no fences.`
        );
        try {
          const parsed = JSON.parse(extractJSON(result));
          results.push({
            sortOrder: gi + 1, isFree: isFreeStory(gi), category: story.category,
            headline: parsed.headline ?? story.title, body: parsed.body ?? story.summary,
            tldr: parsed.tldr ?? null, sourceUrl: story.sourceUrl ?? null,
            sourceName: story.sourceName ?? null,
            imageUrl: story.sourceUrl ? ogImages[story.sourceUrl] ?? null : null, emoji,
          });
        } catch {
          results.push({
            sortOrder: gi + 1, isFree: isFreeStory(gi), category: story.category,
            headline: story.title, body: story.summary, tldr: null,
            sourceUrl: story.sourceUrl ?? null, sourceName: story.sourceName ?? null,
            imageUrl: story.sourceUrl ? ogImages[story.sourceUrl] ?? null : null, emoji,
          });
        }
      }
      return results;
    });

    // Step 4c: Quick Hits (stories 14-20) — 150-200 words each
    const quickHits = await step.run("rewrite-quick-hits", async () => {
      const results = [];
      const batch = curatedStories.slice(13, STORY_COUNT);
      for (let i = 0; i < batch.length; i++) {
        const gi = i + 13;
        const story = batch[i];
        const emoji = getCategoryEmoji(story.category);
        const result = await generateWithMini(
          STYLE_GUIDE,
          `Rewrite as a QUICK HIT for TheDailyPoop. Ultra-short.

ORIGINAL: ${story.title} — ${story.summary} (${story.category})

Return JSON: "headline" (max 80 chars), ${QUICK_HIT_PROMPT}, "tldr" (one sentence).
ONLY JSON.`
        );
        try {
          const parsed = JSON.parse(extractJSON(result));
          results.push({
            sortOrder: gi + 1, isFree: isFreeStory(gi), category: story.category,
            headline: parsed.headline ?? story.title, body: parsed.body ?? story.summary,
            tldr: parsed.tldr ?? null, sourceUrl: story.sourceUrl ?? null,
            sourceName: story.sourceName ?? null,
            imageUrl: story.sourceUrl ? ogImages[story.sourceUrl] ?? null : null, emoji,
          });
        } catch {
          results.push({
            sortOrder: gi + 1, isFree: isFreeStory(gi), category: story.category,
            headline: story.title, body: story.summary, tldr: null,
            sourceUrl: story.sourceUrl ?? null, sourceName: story.sourceName ?? null,
            imageUrl: story.sourceUrl ? ogImages[story.sourceUrl] ?? null : null, emoji,
          });
        }
      }
      return results;
    });

    const allRewritten = [...deepDives, ...standard, ...quickHits];

    // Step 5: Briefing headline + intro
    const meta = await step.run("generate-headline", async () => {
      const headlines = allRewritten.slice(0, 8).map((s) => `${s.emoji} ${s.headline}`).join("\n");
      const result = await generateWithMini(
        STYLE_GUIDE,
        `Write today's briefing header for TheDailyPoop.

Top stories:
${headlines}

Return JSON:
"headline": 3-8 word title, max 60 chars. E.g. "Tech Bros Are Down Bad Today"
"introText": 2-3 sentences making people scroll. Reference the craziest stories.

ONLY JSON.`
      );
      try { return JSON.parse(extractJSON(result)); }
      catch { return { headline: "Today's Scoop Is Here", introText: "Here's what matters right now." }; }
    });

    // Step 6: Save to DB
    const saved = await step.run("save-to-db", async () => {
      const { data: briefing, error: bErr } = await db
        .from("briefings")
        .insert({
          publish_date: today,
          drop_type: "daily",
          headline: meta.headline,
          intro_text: meta.introText,
          story_count: allRewritten.length,
          free_story_count: allRewritten.filter((s) => s.isFree).length,
          status: "published",
          published_at: new Date().toISOString(),
        })
        .select("id")
        .single();

      if (bErr || !briefing) throw new Error(`Briefing insert failed: ${bErr?.message}`);

      const rows = allRewritten.map((s) => ({
        briefing_id: briefing.id, sort_order: s.sortOrder, is_free: s.isFree,
        category: s.category, headline: s.headline, body: s.body, tldr: s.tldr,
        source_url: s.sourceUrl, source_name: s.sourceName, image_url: s.imageUrl,
        emoji: s.emoji,
      }));

      const { error: sErr } = await db.from("stories").insert(rows);
      if (sErr) throw new Error(`Stories insert failed: ${sErr.message}`);

      return { briefingId: briefing.id, storyCount: rows.length };
    });

    // Trigger 3 Word Drop games (morning=free, midday+evening=premium)
    await step.sendEvent("trigger-word-games", [
      { name: "briefing/published", data: { briefingId: saved.briefingId, dropType: "morning", publishDate: today } },
      { name: "briefing/published", data: { briefingId: saved.briefingId, dropType: "midday", publishDate: today } },
      { name: "briefing/published", data: { briefingId: saved.briefingId, dropType: "evening", publishDate: today } },
    ]);

    return {
      success: true,
      briefingId: saved.briefingId,
      storyCount: saved.storyCount,
      breakdown: { deepDives: deepDives.length, standard: standard.length, quickHits: quickHits.length },
      headline: meta.headline,
    };
  }
);
