import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { generateWithMini } from "@/lib/openai";

// Runs daily at 9:00 AM — generates an AI challenge for each active group
export const dailyChallenges = inngest.createFunction(
  { id: "daily-challenges", name: "Generate Daily Group Challenges" },
  { cron: "0 9 * * *" },
  async ({ step }) => {
    const db = createServiceClient();

    // Get all active groups with at least 2 members
    const groups = await step.run("fetch-active-groups", async () => {
      const { data } = await db
        .from("groups")
        .select("id, name, emoji")
        .order("created_at", { ascending: false });
      return data ?? [];
    });

    // Filter to groups with 2+ members
    const activeGroups = await step.run("filter-active-groups", async () => {
      const results = [];
      for (const group of groups) {
        const { count } = await db
          .from("group_members")
          .select("*", { count: "exact", head: true })
          .eq("group_id", group.id);
        if ((count ?? 0) >= 2) {
          results.push(group);
        }
      }
      return results;
    });

    // Generate a challenge for each active group
    let generated = 0;
    for (const group of activeGroups) {
      await step.run(`generate-challenge-${group.id}`, async () => {
        // Get group members for context
        const { data: members } = await db
          .from("group_members")
          .select("users(username)")
          .eq("group_id", group.id);

        const memberNames =
          members
            ?.map((m: any) => m.users?.username)
            .filter(Boolean)
            .map((n: string) => `@${n}`) ?? [];

        // Get recent drops for poop-related context
        const { data: recentDrops } = await db
          .from("drops")
          .select("caption, location_name, users(username)")
          .eq("group_id", group.id)
          .order("created_at", { ascending: false })
          .limit(5);

        // Get recent gossip for spicy context
        const { data: recentGossip } = await db
          .from("gossip")
          .select("content")
          .eq("group_id", group.id)
          .order("created_at", { ascending: false })
          .limit(3);

        const challengeTypes = [
          "would_you_rather",
          "dare",
          "roast",
          "vote",
        ];
        const challengeType =
          challengeTypes[Math.floor(Math.random() * challengeTypes.length)];

        const prompt = `Generate a fun ${challengeType} challenge for a friend group called "${group.name}" ${group.emoji}.

Group members: ${memberNames.join(", ")}

${recentDrops?.length ? `Recent poop drops: ${recentDrops.map((d: any) => `${d.users?.username} dropped at ${d.location_name ?? "unknown location"}${d.caption ? ` ("${d.caption}")` : ""}`).join("; ")}` : ""}

${recentGossip?.length ? `Recent gossip: ${recentGossip.map((g: any) => g.content.substring(0, 50)).join("; ")}` : ""}

Rules:
- Keep it PG-13 and fun, not mean-spirited
- Tie it to poop/bathroom humor when possible — this is TheDailyPoop
- Use @mentions of actual group members when appropriate
- For "would_you_rather": give 2 funny options involving group members
- For "dare": give a silly dare someone in the group should do
- For "roast": pick a random member to roast (lighthearted)
- For "vote": create a "most likely to" or "who would" question

Return JSON: { "prompt": "the challenge text", "options": ["option1", "option2"] }
Options only needed for would_you_rather and vote types.`;

        const response = await generateWithMini(
          "You are a fun group chat challenge generator for TheDailyPoop, a poop-tracking social app where friends track each other's bathroom visits on a live map. Keep it funny, poop-themed, and lighthearted.",
          prompt
        );

        // Parse the AI response
        let challengeData: { prompt: string; options?: string[] };
        try {
          const cleaned = response
            .replace(/```json\n?/g, "")
            .replace(/```\n?/g, "")
            .trim();
          challengeData = JSON.parse(cleaned);
        } catch {
          challengeData = { prompt: response.trim() };
        }

        // Insert the challenge
        await db.from("challenges").insert({
          group_id: group.id,
          prompt: challengeData.prompt,
          challenge_type: challengeType,
          options: challengeData.options
            ? JSON.stringify(challengeData.options)
            : null,
          expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        });

        generated++;
      });
    }

    return { generated, totalGroups: activeGroups.length };
  }
);

// Runs daily at 9:00 PM — close voting and announce results
export const challengeResults = inngest.createFunction(
  { id: "challenge-results", name: "Close Daily Challenge Voting" },
  { cron: "0 21 * * *" },
  async ({ step }) => {
    const db = createServiceClient();

    // Find today's challenges that are still active
    const challenges = await step.run("fetch-today-challenges", async () => {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const { data } = await db
        .from("challenges")
        .select("id, group_id, prompt, challenge_type")
        .gte("created_at", today.toISOString())
        .neq("challenge_type", "weekly_recap")
        .order("created_at", { ascending: false });

      return data ?? [];
    });

    // For each challenge, tally results
    for (const challenge of challenges) {
      await step.run(`tally-${challenge.id}`, async () => {
        const { data: responses } = await db
          .from("challenge_responses")
          .select("user_id, response, voted_for")
          .eq("challenge_id", challenge.id);

        // TODO: Send push notification with results to group members

        return {
          challengeId: challenge.id,
          totalResponses: responses?.length ?? 0,
        };
      });
    }

    return { processed: challenges.length };
  }
);
