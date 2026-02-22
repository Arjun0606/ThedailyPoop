import { Metadata } from "next";
import { getWebSession } from "@/lib/web-auth";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Games",
  description:
    "6 AI-powered daily games. Test your news IQ, roast politicians, and predict tomorrow's chaos.",
};

export const dynamic = "force-dynamic";

const GAMES = [
  {
    id: "poop-or-scoop",
    name: "Poop or Scoop",
    emoji: "💩",
    description: "Real headline or AI-generated BS? You decide.",
    tier: "free" as const,
  },
  {
    id: "who-said-it",
    name: "Who Said It?",
    emoji: "🗣️",
    description: "Match the unhinged quote to the public figure.",
    tier: "pro" as const,
  },
  {
    id: "spin-the-excuse",
    name: "Spin the Excuse",
    emoji: "🎰",
    description: "Generate the perfect political excuse. Spin to win.",
    tier: "pro" as const,
  },
  {
    id: "the-roast",
    name: "The Roast",
    emoji: "🔥",
    description: "Write the best roast for today's newsmaker. Community votes.",
    tier: "pro" as const,
  },
  {
    id: "predict-the-poop",
    name: "Predict the Poop",
    emoji: "🔮",
    description: "Bet on tomorrow's headlines. Get points when you're right.",
    tier: "pro" as const,
  },
  {
    id: "headline-roulette",
    name: "Headline Roulette",
    emoji: "🎲",
    description: "Spin the wheel, get a topic, write the funniest headline.",
    tier: "pro" as const,
  },
];

export default async function GamesPage() {
  const session = await getWebSession();

  return (
    <div className="min-h-screen bg-black">
      <Header />

      <main className="mx-auto max-w-3xl px-4 py-8 sm:px-5">
        <div className="mb-8">
          <h1 className="text-2xl font-black text-white sm:text-3xl">Games</h1>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            6 AI-powered games, refreshed daily. One free — Pro unlocks all.
          </p>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          {GAMES.map((game) => {
            const isLocked =
              game.tier === "pro"
                ? !session?.isPremium
                : game.tier === "free"
                  ? !session
                  : true;

            return (
              <div key={game.id} className="relative">
                {isLocked ? (
                  <div className="rounded-2xl border border-white/[0.06] bg-[var(--card-bg)] p-6 opacity-70">
                    <div className="flex items-start justify-between">
                      <span className="text-3xl">{game.emoji}</span>
                      <span className="text-lg">🔒</span>
                    </div>
                    <h3 className="mt-3 text-base font-bold text-white">
                      {game.name}
                    </h3>
                    <p className="mt-1 text-sm text-[var(--text-secondary)]">
                      {game.description}
                    </p>
                    <div className="mt-3">
                      {game.tier === "free" && !session ? (
                        <Link
                          href="/signup"
                          className="text-xs font-bold text-[var(--accent)] hover:underline"
                        >
                          Sign up free to play &rarr;
                        </Link>
                      ) : (
                        <a
                          href="https://apps.apple.com/app/thedailypoop/id6738030377"
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-xs font-bold text-[var(--accent)] hover:underline"
                        >
                          Get Pro to play &rarr;
                        </a>
                      )}
                    </div>
                  </div>
                ) : (
                  <Link
                    href={`/games/${game.id}`}
                    className="group block rounded-2xl border border-white/[0.06] bg-[var(--card-bg)] p-6 transition hover:border-white/[0.12]"
                  >
                    <div className="flex items-start justify-between">
                      <span className="text-3xl">{game.emoji}</span>
                      {game.tier === "pro" && (
                        <span className="rounded-full bg-[var(--accent)]/20 px-2 py-0.5 text-[10px] font-bold text-[var(--accent)]">
                          PRO
                        </span>
                      )}
                    </div>
                    <h3 className="mt-3 text-base font-bold text-white group-hover:text-[var(--accent)] transition">
                      {game.name}
                    </h3>
                    <p className="mt-1 text-sm text-[var(--text-secondary)]">
                      {game.description}
                    </p>
                    <p className="mt-3 text-xs font-bold text-[var(--accent)]">
                      Play now &rarr;
                    </p>
                  </Link>
                )}
              </div>
            );
          })}
        </div>

        {/* Upgrade CTA for non-pro users */}
        {!session?.isPremium && (
          <div className="mt-10 rounded-2xl border border-[var(--accent)]/20 bg-[var(--accent-dim)] p-6 text-center">
            <span className="text-3xl">🎮</span>
            <h3 className="mt-2 text-lg font-black text-white">
              Unlock All 6 Games
            </h3>
            <p className="mt-1 text-sm text-[var(--text-secondary)]">
              Pro gets you every game, every day — plus all 25 stories and 15
              days of history.
            </p>
            <a
              href="https://apps.apple.com/app/thedailypoop/id6738030377"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-4 inline-block rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:brightness-110"
            >
              Get Pro — $7.99/mo
            </a>
          </div>
        )}
      </main>

      <Footer />
    </div>
  );
}
