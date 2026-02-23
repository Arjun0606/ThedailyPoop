import { Metadata } from "next";
import { getWebSession } from "@/lib/web-auth";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Image from "next/image";
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
    emoji: "🎯",
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
    description: "Rank 5 headlines from most to least insane. Can you spot the chaos?",
    tier: "pro" as const,
  },
];

export default async function GamesPage() {
  const session = await getWebSession();

  return (
    <div className="min-h-screen bg-black">
      <Header />

      <main className="mx-auto max-w-6xl px-6 py-8">
        <div className="mb-8 flex items-center gap-3">
          <Image
            src="/logo.png"
            alt=""
            width={40}
            height={40}
            className="drop-shadow-md"
          />
          <div>
            <h1 className="text-2xl font-black text-white sm:text-3xl">
              Games
            </h1>
            <p className="mt-0.5 text-sm text-[var(--text-secondary)]">
              6 AI-powered games, refreshed daily. One free — Pro unlocks all.
            </p>
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {GAMES.map((game) => {
            const isLocked =
              game.tier === "pro"
                ? !session?.isPremium
                : game.tier === "free"
                  ? !session
                  : true;

            return (
              <div key={game.id}>
                {isLocked ? (
                  <div className="glass-card p-6 opacity-70">
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
                        <Link
                          href="/pro"
                          className="text-xs font-bold text-[var(--accent)] hover:underline"
                        >
                          Get Pro to play &rarr;
                        </Link>
                      )}
                    </div>
                  </div>
                ) : (
                  <Link
                    href={`/games/${game.id}`}
                    className="glass-card pressable group block p-6"
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
          <div className="mt-10 glass-card border-[var(--accent)]/20 p-6 text-center">
            <Image
              src="/logo.png"
              alt=""
              width={56}
              height={56}
              className="mx-auto drop-shadow-lg"
            />
            <h3 className="mt-3 text-lg font-black text-white">
              Unlock All 6 Games
            </h3>
            <p className="mt-1 text-sm text-[var(--text-secondary)]">
              Pro gets you every game, every day — plus all 25 stories and 15
              days of history.
            </p>
            <Link
              href="/pro"
              className="pressable mt-4 inline-block rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)]"
            >
              Get Pro — $7.99/mo
            </Link>
          </div>
        )}
      </main>

      <Footer />
    </div>
  );
}
