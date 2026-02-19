import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { fetchAllCategories } from "@/lib/perplexity";
import { generateWithPremium, generateWithMini } from "@/lib/openai";
import { fetchOgImages } from "@/lib/og-image";

const STYLE_GUIDE = `You are TheDailyPoop — the unholy love child of Dan Toomey, the WSJ editorial board, and your group chat at 2 AM. You have a finance degree, a podcast mic, and absolutely no respect for authority. You sound like a business bro who actually reads the filings but explains them like he's three beers deep at a rooftop bar.

YOUR PERSONALITY:
- You're the guy at the pregame who starts ranting about Fed policy and somehow everyone's listening
- You talk like money Twitter but you're funnier and you don't shill shitcoins
- You treat CEOs like pledges — respect is earned, not given. "Tim Cook said what? Bro sit down"
- You're genuinely obsessed with how the machine works: money, power, incentives, the real game behind the game
- You explain complex shit like you're helping your friend not fail econ — simple, specific, with killer analogies
- You have the energy of someone who just found out something insane and can't wait to tell everyone

VOICE RULES:
- Write like you're voice-noting your boys, not drafting a memo. Conversational. Direct. Zero filler.
- Headlines should HIT — think tweet energy. Short, punchy, slightly unhinged. Examples of GOOD headlines:
  * "The Fed Just Picked a Fight With Your Mortgage"
  * "Apple's AI Play Is Giving 'Trust Me Bro' Energy"
  * "Congress Can't Even Agree on Lunch, Let Alone a Budget"
  * "This CEO Got Paid $400M to Lose Money. America!"
  * "China Just Speed-Ran What Took Us 20 Years"
- Use real comparisons that slap: "That's like Venmo-ing your landlord $3K and he ghosts you"
- Casual language that sounds HUMAN: "they're cooked", "genuinely insane", "make it make sense", "absolute scenes", "not great Bob" — but only when it hits naturally
- Pop culture references should be current and specific: name the show, the meme, the person
- Humor should be OBSERVATIONAL and SPECIFIC, not generic: "Zuckerberg spent $10B on the metaverse which is roughly the GDP of a small country, and what we got was legless avatars in a conference room that looks like a Wii game from 2007"
- Swear like a person, not a script — "what the hell", "they're absolutely cooked", "this is genuinely nuts"
- Call out the game: follow the money, name the incentives, expose the PR spin. "They called it a 'strategic realignment.' It's layoffs. They did layoffs."
- Every story MUST end with "The Bottom Line:" — make it the line people screenshot. Sharp, quotable, slightly savage.

STRUCTURE:
- Short paragraphs. 1-3 sentences. This is phone reading, not the Sunday paper.
- Lead with the SPICIEST detail, not the boring setup
- Use line breaks aggressively — white space is your friend
- Analogies should feel like "oh shit that actually makes sense"
- Mix confidence with humor: you KNOW this stuff AND you think it's hilarious

WHAT TO AVOID:
- NEVER sound like a news anchor, a LinkedIn post, or a press release
- NEVER use: "in a stunning turn of events", "it remains to be seen", "only time will tell", "in today's fast-paced world", "buckle up" (overused)
- NEVER start with "Well," or "So," — start with something that makes people stop scrolling
- NEVER be try-hard cringe — if a joke doesn't land instantly, kill it. Confidence > quantity
- NEVER punch down — go after the powerful. Your readers are the people getting screwed by the system.
- NEVER use "delve", "landscape", "paradigm", "synergy", "navigate", "unpack", "deep dive" (as a verb), "at the end of the day" — dead AI giveaways
- NEVER use parenthetical asides excessively like "(yes, really)" "(you read that right)" — one per article MAX`;

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
  [{ cron: "0 9 * * *" }, { event: "admin/trigger-briefing" }], // 9 AM UTC = 4 AM ET + manual trigger
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
"headline": MAX 80 chars. Write it like a tweet that would go viral. Short, punchy, opinionated. Use active voice. NO colons in headlines. Bad: "Fed Policy: A New Direction". Good: "The Fed Just Told Your Wallet to Go F*** Itself".
${DEEP_DIVE_PROMPT}
"tldr": One sentence a friend would text you about this story.

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
"headline": MAX 80 chars. Tweet-energy headline — short, opinionated, slightly unhinged. NO colons. Active voice.
${STANDARD_PROMPT}
"tldr": One sentence a friend would text you.

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

Return JSON: "headline" (max 80 chars, tweet-energy, NO colons, active voice, slightly unhinged), ${QUICK_HIT_PROMPT}, "tldr" (one friend-text sentence).
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
"headline": 3-7 words, max 50 chars. This is the MAIN HEADLINE users see first. Make it feel like a group chat message about today's news. Examples: "Tech Bros Are Down Bad Today", "Everyone's Getting Sued Apparently", "The Fed Chose Violence", "America Is Having a Week"
"introText": 2-3 sentences that make people NEED to scroll. Reference the wildest stories. Write like you're hyping up your boys: "Congress is literally on fire, the Fed picked a hawk, and AI just replaced your manager. It's a lot."

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
