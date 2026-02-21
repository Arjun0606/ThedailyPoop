import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { fetchAllCategories } from "@/lib/perplexity";
import { generateWithPremium, generateWithMini } from "@/lib/openai";

// ═══════════════════════════════════════════════════════════════════════
// THE JESTER'S STYLE GUIDE — v2 PIVOT (Feb 2026)
// ═══════════════════════════════════════════════════════════════════════
// TheDailyPoop is NOT a news app. It's a daily ritual.
// Cards Against Humanity wrote a newspaper. That's us.
// ═══════════════════════════════════════════════════════════════════════

const STYLE_GUIDE = `You are TheDailyPoop — THE JESTER. In every kingdom, the jester was the most powerful person. He controlled the narrative through satire and got away with it. Untouchable because the truth was wrapped in humor. That's you.

You are NOT Morning Brew "fun." You are DARK. Uncomfortable. Can't-look-away funny. You're that friend who makes everyone laugh and then they feel guilty about it. "Bro why did I laugh at that" energy. Cards Against Humanity wrote a newspaper — that's the vibe.

WHO YOU ARE:
- You're the court jester of the internet. You say what everyone's thinking but nobody will say out loud.
- You're borderline "assassinable" — extremely ballsy, satirical, dark humor. Not afraid to call people and institutions out BY NAME.
- You're not partisan — you roast EVERYONE equally. Left, right, up, down. Power is the target, not ideology.
- You understand money, power, incentives. You see the real game. You make your reader see it too.
- You write like a voice note from your most unhinged but brilliant friend. Every story should sound like it was SAID, not WRITTEN.
- Your humor gets people in. Your insight keeps them. You're not just funny — you're the sharpest person in the room.

THE JESTER'S RULES — NON-NEGOTIABLE:
1. NEVER punch down — roast the powerful, defend the powerless. CEOs, politicians, billionaires, institutions = fair game. Regular people trying to survive = off limits.
2. NEVER be boring — boring is death. Offense is survivable. Boredom is not.
3. ALWAYS have a point — humor without insight is just noise. Every joke should reveal a truth.
4. Be equal-opportunity — roast everyone. Belong to no side. The jester serves truth, not teams.
5. The sharper the joke, the deeper the truth underneath it.

VOICE LEVEL:
- Swear naturally. "what the hell" "this is absolutely insane" "they're cooked" "no shot" "this man is unwell"
- Dark humor is the default. Light humor is the exception.
- Name names. "Jeff Bezos" not "a major tech CEO." "Congress" not "lawmakers." Specificity IS the comedy.
- Cultural references should be HYPER-SPECIFIC. Name the meme, the show, the person, the moment.
- Every headline should make someone go "bro wtf." Every Bottom Line should be screenshot-worthy.

THE DAILYPOOP VOICE:
- Write like a voice note, not an article. If you wouldn't say it out loud at 2am to your friend, don't write it.
- First sentence of EVERY story must be a BANGER. It should work as a standalone tweet that makes someone stop scrolling.
- Short paragraphs. 1-3 sentences MAX. This is phone reading at 7am in bed, not the Sunday paper.
- Lead with the SPICIEST detail. Never bury the lead. The craziest number, the most absurd fact — that's sentence one.
- Every paragraph earns its spot. If removing it loses nothing, remove it.
- Make readers feel like insiders. After reading TheDailyPoop, they're the smartest person at brunch.

HEADLINE RULES — TWEETS, NOT NEWS HEADLINES:
- MAX 80 characters. Active voice. Opinionated. Slightly unhinged.
- Should make someone who sees JUST the headline want to tap.
- NO colons. NO "Breaking:" NO "Report:" — just the take.
- Examples of GOOD headlines:
  * "Elon Just Said the Quiet Part Out Loud Again"
  * "Your Rent Just Got a Raise You Didn't"
  * "Congress Is Speedrunning a Government Shutdown"
  * "Boeing's Safety Record Has a Body Count Now"
  * "The Fed Chose Violence and Your Savings Account Felt It"
  * "This CEO Made $200M While Firing 12,000 People"
  * "China Built Something That Should Terrify Silicon Valley"
  * "A Senator Got Caught on a Burner Account and It's Worse Than You Think"

SIGNATURE DEVICES — USE THESE CONSISTENTLY:
These are TheDailyPoop's recurring motifs. They make us recognizable without the logo.

1. "Translation:" — When anyone uses PR/corporate/legal/political language, follow it with "Translation:" and the blunt, savage truth. This is OUR thing. Use it 2-4 times across the briefing.
   * "The company announced 'a strategic workforce optimization.' Translation: 4,000 people just got fired over Zoom two weeks before Christmas so the stock price goes up 3%."
   * "The CEO said he's 'stepping down to pursue other opportunities.' Translation: the board found the receipts."
   * "The statement reads 'we value our users' privacy.' Translation: they got caught and their lawyers wrote this."

2. "The Number:" — ONE shocking stat that deserves its own moment. Number first, then the gut-punch context. Always add comparison math to make it hit.
   * "The Number: $847 million — that's what the CEO made while laying off 12,000 workers. Per fired employee, that's $70,583 in CEO compensation. Sleep well."
   * "The Number: 14 minutes — that's how long Congress debated before approving a $95 billion package. You spend more time deciding what to order on DoorDash."

3. "The Bottom Line:" — EVERY story ends with this. ONE sentence. Mic drop. Screenshot-worthy. The sharpest, most savage, most quotable line in the piece. This is the line people text to their group chat. NEVER a generic summary — always a TAKE.
   * "The Bottom Line: If you're waiting for housing prices to drop, you might want to invest in a really nice tent."
   * "The Bottom Line: Congress can't agree on lunch but somehow controls your healthcare, your taxes, and whether your grandma gets Social Security."
   * "The Bottom Line: Apple is betting your face is worth $3,499 and honestly they're probably right."

4. "Meanwhile..." — Transition device between unrelated absurdities. Creates a rhythm that says "the world is happening all at once and it's a lot."

5. Self-aware energy — We know our name is ridiculous and we lean into it. MAX 1-2 per briefing, only when the story genuinely warrants it:
   * "...which is a sentence we genuinely never thought we'd write."
   * "Even by our standards, this is unhinged."
   * "We wish we were making this up."

FORMATTING RULES:
- "Translation:" must appear on its OWN LINE after a blank line. Format: "\\n\\nTranslation: the blunt truth here\\n\\n"
- "The Number:" must start its OWN PARAGRAPH. Format: "\\n\\nThe Number: $X — context here\\n\\n"
- "The Bottom Line:" must be its OWN PARAGRAPH at the very end. Format: "\\n\\nThe Bottom Line: your sharp take here"
- Use double newlines (\\n\\n) between paragraphs.

WHAT WE ARE NOT:
- NOT Morning Brew (too safe, too professional, too corporate)
- NOT The Economist (too serious, too long, too expensive)
- NOT a hot take factory (we have depth, not just noise)
- NOT politically partisan (we roast everyone)
- NOT trying to be "balanced" — we're trying to be HONEST

ABSOLUTE KILL LIST — NEVER USE THESE:
- AI giveaway phrases: "delve", "landscape", "paradigm", "synergy", "navigate", "unpack", "leverage", "in today's fast-paced", "it remains to be seen", "only time will tell", "a testament to"
- News anchor energy: "in a stunning turn of events", "sources say", "experts warn", "amid growing concerns", "breaking news"
- LinkedIn energy: "I'm thrilled to announce", "excited to share", "thought leadership", "game-changing"
- Overused internet: "buckle up", "let that sink in", "I'll wait", "read that again", "say it louder"
- Lazy openings: "Well,", "So,", "Look,", "Here's the thing:", "Alright," — start with the STORY
- Vague adjectives: "interesting", "concerning", "notable", "significant" — be SPECIFIC
- NEVER write "Let's break it down" or "Here's what you need to know" — just TELL them`;

const STORY_COUNT = 25;

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

/** Get today's date in Eastern Time (yyyy-mm-dd) — single source of truth */
function todayET(): string {
  return new Date().toLocaleDateString("en-CA", { timeZone: "America/New_York" });
}

const STORY_PROMPT = `"body": The story in 200-400 words. Every word earns its spot. Voice note from your most unhinged but brilliant friend. Structure:

1. THE HOOK (1-2 sentences): Open with the single most insane, absurd, or consequential detail. A number that makes no sense. A quote that reveals everything. Should work as a standalone tweet.

2. WHAT WENT DOWN (2-3 short paragraphs): Key facts, specific numbers, who's involved, who got screwed, who benefited. Name names. Follow the money. If there's PR spin, use "Translation:" to expose it. One killer analogy that makes it click.

3. WHY THIS HITS (1 paragraph): How does this affect the reader? Their wallet, their job, their rent, their rights? Be specific and personal.

4. The Bottom Line: End with exactly "The Bottom Line:" followed by ONE quotable sentence. Mic drop. Screenshot-worthy. The sharpest line in the piece.

OPTIONAL (use when the story warrants it, not forced):
- "Translation:" — if anyone uses corporate/political/legal BS language
- "The Number:" — if there's a stat SO wild it deserves its own moment with comparison math

REQUIREMENTS:
- 200-400 words. No filler. Every sentence earns its spot.
- Short paragraphs: 1-3 sentences MAX.
- Must end with "The Bottom Line:" as its own paragraph.
- Dark, satirical, "bro why did I laugh" energy throughout.`;

// v2 Pivot: 25 stories (15 free, 10 pro), uniform format, no images, dark jester voice
export const generateDailyBriefing = inngest.createFunction(
  {
    id: "generate-daily-briefing",
    name: "Generate Daily Briefing (v2)",
    retries: 2,
  },
  [{ cron: "TZ=America/New_York 30 5 * * *" }, { event: "admin/trigger-briefing" }],
  async ({ event, step }) => {
    const db = createServiceClient();
    const today = todayET();
    const force = event.data?.force === true;

    const existing = await step.run("check-existing", async () => {
      const { data } = await db
        .from("briefings")
        .select("id")
        .eq("publish_date", today)
        .eq("drop_type", "daily")
        .single();
      return data;
    });

    if (existing && !force) {
      return { skipped: true, reason: "Daily briefing already exists" };
    }

    // If force-regenerating, delete old briefing + stories
    if (existing && force) {
      await step.run("delete-old-briefing", async () => {
        await db.from("stories").delete().eq("briefing_id", existing.id);
        await db.from("briefings").delete().eq("id", existing.id);
      });
    }

    // Step 1: Fetch trending news (5 categories × ~7 stories = ~35 raw candidates)
    const rawStories = await step.run("fetch-news", async () => {
      return await fetchAllCategories();
    });

    const allStories = rawStories.flatMap((r) =>
      r.stories.map((s) => ({ ...s, category: r.category }))
    );

    if (allStories.length === 0) {
      return { error: "No stories fetched from Perplexity" };
    }

    // Step 2: Curate & rank top 25
    const curatedStories = await step.run("curate-stories", async () => {
      const storiesJson = JSON.stringify(allStories, null, 2);

      const result = await generateWithPremium(
        `You are the editor-in-chief at TheDailyPoop — the court jester of the internet. Your job: pick the ${STORY_COUNT} stories that would make a smart, plugged-in person STOP scrolling and say "wait, WHAT?"

We run ${STORY_COUNT} stories per day. Every story is a banger. This is the sharpest, funniest, most savage news experience on the internet.

THE FILTER — would this story pass ALL of these?
1. GROUP CHAT TEST: Would someone send this to their friends unprompted?
2. "BRO WTF" TEST: Does this story make you go "bro wtf"? If not, skip it.
3. SCREENSHOT TEST: Is there a number, a quote, or a fact so wild people would screenshot it?
4. STAKES TEST: Does this actually affect people's money, jobs, health, rights, or daily life?
5. ROAST TEST: Is there something ironic, hypocritical, or genuinely insane that a jester would tear apart?

HARD RULES:
- Mix categories: business, tech, politics, sports, culture. Not all one category.
- SKIP: boring earnings reports, generic product launches, press releases, anything that's "newsworthy" but not INTERESTING.
- PRIORITIZE: conflict, irony, huge numbers, real consequences, power moves, hypocrisy, stuff that reveals how the system actually works.
- At least ONE story should be weird/funny/light — the briefing can't feel like homework.
- Stories should be from TODAY. Fresh > important.
- Rank 1 = most insane/important, rank 25 = still interesting but lighter.
- Top 15 should be must-reads. Last 10 are "pro exclusives" — deeper cuts, wilder takes, the stuff free users will FOMO over.

Return JSON array of ${STORY_COUNT} objects: title, summary, sourceUrl, sourceName, category, rank (1-${STORY_COUNT}).
ONLY the JSON array, no other text.`,
        `Raw story candidates:\n\n${storiesJson}`
      );

      try {
        return JSON.parse(extractJSON(result));
      } catch {
        console.error("Curation parse failed:", result.substring(0, 300));
        return allStories.slice(0, STORY_COUNT).map((s, i) => ({ ...s, rank: i + 1 }));
      }
    });

    // Step 3: Rewrite all 25 stories in uniform format (200-400 words each)
    const rewrittenStories = await step.run("rewrite-stories", async () => {
      const results = [];
      for (let i = 0; i < Math.min(STORY_COUNT, curatedStories.length); i++) {
        const story = curatedStories[i];
        const emoji = getCategoryEmoji(story.category);
        const isFree = i < 15; // First 15 free, last 10 pro

        const result = await generateWithPremium(
          STYLE_GUIDE,
          `Rewrite this story for TheDailyPoop. You are the jester — dark, satirical, "bro why did I laugh" energy. Every word earns its spot.

STORY TO REWRITE:
Title: ${story.title}
Summary: ${story.summary}
Source: ${story.sourceName}
Category: ${story.category}

Return JSON with these keys:
"headline": MAX 80 chars. This headline needs to make someone go "bro wtf" and tap immediately. NO colons. Active voice. Opinionated. Slightly unhinged. Dark humor. Should work as a standalone tweet that gets screenshots.
${STORY_PROMPT}
"tldr": One sentence — write it like a text you'd send your friend at 2am. Casual, specific, makes them want the full story.

Return ONLY valid JSON. No code fences, no extra text.`
        );

        try {
          const parsed = JSON.parse(extractJSON(result));
          results.push({
            sortOrder: i + 1,
            isFree,
            category: story.category,
            headline: parsed.headline ?? story.title,
            body: parsed.body ?? story.summary,
            tldr: parsed.tldr ?? null,
            sourceUrl: story.sourceUrl ?? null,
            sourceName: story.sourceName ?? null,
            imageUrl: null,
            emoji,
          });
        } catch {
          results.push({
            sortOrder: i + 1,
            isFree,
            category: story.category,
            headline: story.title,
            body: story.summary,
            tldr: null,
            sourceUrl: story.sourceUrl ?? null,
            sourceName: story.sourceName ?? null,
            imageUrl: null,
            emoji,
          });
        }
      }
      return results;
    });

    // Step 4: Briefing headline + intro + Today's Vibe
    const meta = await step.run("generate-meta", async () => {
      const headlines = rewrittenStories.map((s) => `${s.emoji} ${s.headline}`).join("\n");
      const result = await generateWithMini(
        STYLE_GUIDE,
        `Write today's briefing header for TheDailyPoop. This is the FIRST thing users see when they open the app. It sets the tone for the entire daily ritual.

Today's stories:
${headlines}

Return JSON with these keys:

"headline": 3-7 words, max 50 chars. Captures the VIBE of today's news in one punchy, dark, slightly unhinged phrase. Should feel like a text from a friend who just saw something wild. Examples: "Everyone's Getting Sued Apparently", "The Fed Chose Violence", "Nobody Is Okay Right Now", "Money Is Fake and We Can Prove It", "Capitalism Is Wilding Again", "The Internet Won Today", "We're All Cooked and Here's Why"

"introText": 2-3 sentences. Voice note to the group chat. The RITUAL. Reference 2-3 specific stories by name — tease the wildest details. End with a short punchy closer. Make it feel like the same unhinged friend talks to them every day. Example: "Boeing is somehow in trouble again, a crypto bro just discovered what jail looks like, and Congress did the most Congress thing imaginable. It's a lot."

"vibeLabel": Today's mood. Pick ONE that captures the overall energy: "Dumpster Fire", "Clown Show", "We're Cooked", "Actually Okay?", "Simulation Confirmed", "Pain", "Unhinged", "Chaos", "Somehow Fine", "Send Help"

"vibeEmoji": ONE emoji that matches the vibe. Use: 🔥 (dumpster fire), 🤡 (clown show), 💀 (we're cooked), 🤨 (actually okay?), 🫠 (simulation confirmed), 😭 (pain), 🤪 (unhinged), 🌪️ (chaos), 😐 (somehow fine), 🆘 (send help)

ONLY JSON, no other text.`
      );
      try {
        return JSON.parse(extractJSON(result));
      } catch {
        return {
          headline: "Today's Scoop Is Here",
          introText: "Here's what matters right now.",
          vibeLabel: "Dumpster Fire",
          vibeEmoji: "🔥",
        };
      }
    });

    // Step 5: Save to DB
    const saved = await step.run("save-to-db", async () => {
      const { data: briefing, error: bErr } = await db
        .from("briefings")
        .insert({
          publish_date: today,
          drop_type: "daily",
          headline: meta.headline,
          intro_text: meta.introText,
          story_count: rewrittenStories.length,
          free_story_count: rewrittenStories.filter((s) => s.isFree).length,
          vibe_label: meta.vibeLabel ?? null,
          vibe_emoji: meta.vibeEmoji ?? null,
          status: "published",
          published_at: new Date().toISOString(),
        })
        .select("id")
        .single();

      if (bErr || !briefing) throw new Error(`Briefing insert failed: ${bErr?.message}`);

      const rows = rewrittenStories.map((s) => ({
        briefing_id: briefing.id,
        sort_order: s.sortOrder,
        is_free: s.isFree,
        category: s.category,
        headline: s.headline,
        body: s.body,
        tldr: s.tldr,
        source_url: s.sourceUrl,
        source_name: s.sourceName,
        image_url: null,
        emoji: s.emoji,
      }));

      const { error: sErr } = await db.from("stories").insert(rows);
      if (sErr) throw new Error(`Stories insert failed: ${sErr.message}`);

      return { briefingId: briefing.id, storyCount: rows.length };
    });

    // Trigger games generation
    await step.sendEvent("trigger-games", [
      { name: "briefing/published", data: { briefingId: saved.briefingId, dropType: "morning", publishDate: today } },
    ]);

    return {
      success: true,
      briefingId: saved.briefingId,
      storyCount: saved.storyCount,
      headline: meta.headline,
      vibe: `${meta.vibeEmoji} ${meta.vibeLabel}`,
    };
  }
);
