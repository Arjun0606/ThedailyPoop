import { inngest } from "./client";
import { createServiceClient } from "@/lib/supabase";
import { generateWithPremium } from "@/lib/openai";

// Runs every Sunday at 6:00 PM — generates a funny AI recap for each group
export const weeklyRecap = inngest.createFunction(
  { id: "weekly-recap", name: "Generate Weekly Group Recap" },
  { cron: "0 18 * * 0" },
  async ({ step }) => {
    const db = createServiceClient();

    // Get all active groups
    const groups = await step.run("fetch-groups", async () => {
      const { data } = await db.from("groups").select("id, name, emoji");
      return data ?? [];
    });

    let generated = 0;

    for (const group of groups) {
      await step.run(`recap-${group.id}`, async () => {
        const weekAgo = new Date(
          Date.now() - 7 * 24 * 60 * 60 * 1000
        ).toISOString();

        // Gather week's data
        const [gossipResult, dropsResult, challengeResult] =
          await Promise.all([
            db
              .from("gossip")
              .select("content, created_at")
              .eq("group_id", group.id)
              .gte("created_at", weekAgo),
            db
              .from("drops")
              .select("user_id, caption, location_name, users(username)")
              .eq("group_id", group.id)
              .gte("created_at", weekAgo),
            db
              .from("challenge_responses")
              .select(
                "response, challenges(prompt, challenge_type), users(username)"
              )
              .eq("challenges.group_id", group.id)
              .gte("created_at", weekAgo),
          ]);

        const gossipCount = gossipResult.data?.length ?? 0;
        const dropCount = dropsResult.data?.length ?? 0;

        // Skip if group was inactive
        if (gossipCount + dropCount === 0) return;

        // Count who dropped the most
        const droppers: Record<string, number> = {};
        dropsResult.data?.forEach((d: any) => {
          const username = d.users?.username ?? "unknown";
          droppers[username] = (droppers[username] ?? 0) + 1;
        });
        const topDropper = Object.entries(droppers).sort(
          (a, b) => b[1] - a[1]
        )[0];

        // Find most interesting drop locations
        const locations = dropsResult.data
          ?.filter((d: any) => d.location_name)
          .map((d: any) => `${d.users?.username} at ${d.location_name}`)
          .slice(0, 5);

        const prompt = `Write a funny, dramatic weekly recap for the friend group "${group.name}" ${group.emoji} on TheDailyPoop app — a social app where friends track each other's poops on a live map.

This week's stats:
- ${dropCount} poop drops on the map
- ${gossipCount} anonymous gossip posts
${topDropper ? `- Top pooper: @${topDropper[0]} (${topDropper[1]} drops this week!)` : ""}

${locations?.length ? `Notable drop locations: ${locations.join(", ")}` : ""}

${gossipResult.data?.length ? `Gossip highlights: ${gossipResult.data.slice(0, 3).map((g: any) => g.content.substring(0, 80)).join(" | ")}` : ""}

${challengeResult.data?.length ? `Challenge responses: ${challengeResult.data.slice(0, 3).map((r: any) => `${r.users?.username}: "${r.response}"`).join(", ")}` : ""}

Write it like a dramatic sports announcer mixed with a gossip columnist.
Keep it to 3-4 short paragraphs. Use group member @mentions.
Make it funny, poop-themed, and engaging — this is the highlight of their week.
End with a teaser for next week.`;

        const recap = await generateWithPremium(
          "You are a hilarious weekly newsletter writer for TheDailyPoop, a social app where friend groups track each other's bathroom visits on a live map. Your style is dramatic, gossipy, and full of poop puns. Think TMZ meets your group chat meets a bathroom stall.",
          prompt
        );

        await db.from("challenges").insert({
          group_id: group.id,
          prompt: recap,
          challenge_type: "weekly_recap",
          expires_at: new Date(
            Date.now() + 7 * 24 * 60 * 60 * 1000
          ).toISOString(),
        });

        generated++;
      });
    }

    return { generated, totalGroups: groups.length };
  }
);
