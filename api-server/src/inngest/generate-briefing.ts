import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { fetchAllCategories } from "@/lib/perplexity";
import { generateWithPremium, generateWithMini } from "@/lib/openai";

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

// Runs at 5:00 AM ET — generates the daily briefing
export const generateDailyBriefing = inngest.createFunction(
  { id: "generate-daily-briefing", name: "Generate Daily Briefing" },
  { cron: "0 5 * * *" }, // 5:00 AM UTC (adjust for ET as needed)
  async ({ step }) => {
    const db = createServiceClient();
    const today = new Date().toISOString().split("T")[0];

    // Check if briefing already exists for today
    const existing = await step.run("check-existing", async () => {
      const { data } = await db
        .from("briefings")
        .select("id")
        .eq("publish_date", today)
        .single();
      return data;
    });

    if (existing) {
      return { skipped: true, reason: "Briefing already exists for today" };
    }

    // Step 1: Fetch trending news from Perplexity
    const rawStories = await step.run("fetch-news", async () => {
      const results = await fetchAllCategories();
      return results;
    });

    const allStories = rawStories.flatMap((r) =>
      r.stories.map((s) => ({ ...s, category: r.category }))
    );

    if (allStories.length === 0) {
      return { error: "No stories fetched from Perplexity" };
    }

    // Step 2: Curate & rank top 10 stories
    const curatedStories = await step.run("curate-stories", async () => {
      const storiesJson = JSON.stringify(allStories, null, 2);

      const result = await generateWithPremium(
        `You are the editorial director at TheDailyPoop — the news app that makes finance, tech, and culture actually interesting to young people. Your job is to pick the 10 stories that will make our readers say "yooo no way" and send to their group chat.

SELECTION CRITERIA (in order of importance):
1. "Holy shit factor" — would someone screenshot this and text it to a friend?
2. Money impact — does this affect people's wallets, jobs, or future?
3. Conversation starter — will people argue about this at lunch?
4. Meme potential — is this inherently funny, ironic, or absurd?
5. Power moves — big corporations, billionaires, or politicians doing wild things

HARD RULES:
- Stories 1-3 are FREE (these need to be absolute bangers to hook people into premium)
- Stories 4-10 are PREMIUM
- Mix it: roughly 3-4 business/finance, 3-4 tech/AI, 2-3 culture/sports/viral
- SKIP boring earnings reports unless the numbers are genuinely shocking
- SKIP generic "company releases new product" unless it's actually a big deal
- PRIORITIZE stories with conflict, irony, huge numbers, or real consequences

Return a JSON array of exactly 10 objects with keys: title, summary, sourceUrl, sourceName, category ("business" | "tech" | "culture"), rank (1-10).
Return ONLY the JSON array.`,
        `Here are today's raw stories:\n\n${storiesJson}`
      );

      try {
        return JSON.parse(extractJSON(result));
      } catch {
        console.error("Failed to parse curation result:", result.substring(0, 300));
        // Fallback: use first 10 raw stories
        return allStories.slice(0, 10).map((s, i) => ({
          ...s,
          rank: i + 1,
        }));
      }
    });

    // Step 3: Rewrite each story in TheDailyPoop voice
    const rewrittenStories = await step.run("rewrite-stories", async () => {
      const results = [];

      for (let i = 0; i < Math.min(curatedStories.length, 10); i++) {
        const story = curatedStories[i];
        const categoryEmoji =
          story.category === "business"
            ? "💰"
            : story.category === "tech"
            ? "📱"
            : "🎬";

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
            isFree: i < 3,
            category: story.category,
            headline: parsed.headline ?? story.title,
            body: parsed.body ?? story.summary,
            tldr: parsed.tldr ?? null,
            sourceUrl: story.sourceUrl ?? null,
            sourceName: story.sourceName ?? null,
            emoji: categoryEmoji,
          });
        } catch {
          // Fallback: use raw story
          results.push({
            sortOrder: i + 1,
            isFree: i < 3,
            category: story.category,
            headline: story.title,
            body: story.summary,
            tldr: null,
            sourceUrl: story.sourceUrl ?? null,
            sourceName: story.sourceName ?? null,
            emoji: categoryEmoji,
          });
        }
      }

      return results;
    });

    // Step 4: Generate briefing headline + intro
    const briefingMeta = await step.run("generate-headline", async () => {
      const storyHeadlines = rewrittenStories
        .map((s) => `${s.emoji} ${s.headline}`)
        .join("\n");

      const result = await generateWithMini(
        STYLE_GUIDE,
        `Write the daily briefing header for TheDailyPoop.

Today's stories:
${storyHeadlines}

Return a JSON object with:
"headline": A punchy 3-8 word title that captures today's vibe. Think newspaper headline meets meme. Max 60 chars. Examples: "Tech Bros Are Down Bad Today", "Your Portfolio Called. It's Crying.", "Everyone Got Fired Except AI"
"introText": 2-3 sentences that make people NEED to scroll down. Be specific — reference 1-2 of the craziest stories. Don't be generic. Bad: "Another big day in the news!" Good: "Apple somehow made $90 billion while also forgetting how math works, TikTok's CEO went full savage in Congress, and someone just paid $4M for a JPEG. Happy Tuesday."

Return ONLY JSON.`
      );

      try {
        return JSON.parse(extractJSON(result));
      } catch {
        return {
          headline: "Your Daily Scoop Is Here",
          introText:
            "Another day, another pile of news. Here's what matters.",
        };
      }
    });

    // Step 5: Save everything to Supabase
    const saved = await step.run("save-to-db", async () => {
      // Insert briefing
      const { data: briefing, error: briefingError } = await db
        .from("briefings")
        .insert({
          publish_date: today,
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

      // Insert stories
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

    return {
      success: true,
      briefingId: saved.briefingId,
      storyCount: saved.storyCount,
      headline: briefingMeta.headline,
    };
  }
);
