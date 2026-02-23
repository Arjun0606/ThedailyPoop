import { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Image from "next/image";

export const metadata: Metadata = {
  title: "Advertise with TheDailyPoop",
  description:
    "Reach thousands of engaged, news-savvy readers every morning through our daily newsletter.",
};

const PLACEMENTS = [
  {
    name: "Header Sponsor",
    position: "Top of newsletter, above stories",
    description:
      "\"Presented by\" placement seen by every reader before they scroll. Maximum brand visibility.",
    emoji: "👑",
  },
  {
    name: "Mid-Roll",
    position: "Between Top Stories and Quick Hits",
    description:
      "Full card placement with your logo, tagline, and CTA. Native feel, high engagement.",
    emoji: "📣",
  },
  {
    name: "Quick Hits Inline",
    position: "Within the Quick Hits section",
    description:
      "Compact inline mention alongside stories. Great for app installs and product launches.",
    emoji: "⚡",
  },
];

export default function AdvertisePage() {
  return (
    <div className="min-h-screen bg-black">
      <Header />

      <main className="mx-auto max-w-4xl px-6 py-12">
        {/* Hero */}
        <div className="text-center">
          <Image
            src="/logo.png"
            alt=""
            width={64}
            height={64}
            className="mx-auto drop-shadow-lg"
          />
          <h1 className="mt-4 text-3xl font-black text-white sm:text-4xl">
            Advertise with TheDailyPoop
          </h1>
          <p className="mx-auto mt-3 max-w-lg text-base text-[var(--text-secondary)]">
            Reach thousands of engaged, news-savvy readers every morning through
            our daily newsletter. High open rates. Zero boring ads.
          </p>
        </div>

        {/* Stats */}
        <div className="mt-10 grid gap-4 sm:grid-cols-3">
          {[
            { label: "Daily Readers", value: "Growing", sub: "and counting" },
            { label: "Open Rate", value: "40-50%", sub: "industry-leading" },
            { label: "Audience", value: "18-35", sub: "news-obsessed" },
          ].map((stat) => (
            <div key={stat.label} className="glass-card p-5 text-center">
              <div className="text-2xl font-black text-white">{stat.value}</div>
              <div className="mt-1 text-xs text-[var(--text-tertiary)]">
                {stat.sub}
              </div>
              <div className="mt-2 text-xs font-bold uppercase tracking-wide text-[var(--accent)]">
                {stat.label}
              </div>
            </div>
          ))}
        </div>

        {/* Placements */}
        <div className="mt-12">
          <h2 className="text-center text-xs font-bold uppercase tracking-widest text-[var(--text-tertiary)]">
            Ad Placements
          </h2>
          <div className="mt-6 grid gap-4 sm:grid-cols-3">
            {PLACEMENTS.map((p) => (
              <div key={p.name} className="glass-card p-6">
                <span className="text-3xl">{p.emoji}</span>
                <h3 className="mt-3 text-base font-bold text-white">
                  {p.name}
                </h3>
                <p className="mt-1 text-xs font-medium text-[var(--accent)]">
                  {p.position}
                </p>
                <p className="mt-2 text-sm text-[var(--text-secondary)] leading-relaxed">
                  {p.description}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Audience */}
        <div className="mt-12 glass-card p-8 text-center">
          <h2 className="text-lg font-black text-white">Our Audience</h2>
          <p className="mx-auto mt-2 max-w-md text-sm text-[var(--text-secondary)] leading-relaxed">
            Young professionals, news addicts, and meme connoisseurs who read
            every morning. They care about politics, tech, culture, and chaos.
            High purchasing power, high engagement, zero patience for boring ads.
          </p>
        </div>

        {/* CTA */}
        <div className="mt-12 text-center">
          <h2 className="text-xl font-black text-white">
            Interested?
          </h2>
          <p className="mt-2 text-sm text-[var(--text-secondary)]">
            Get in touch and we&apos;ll send you our media kit with rates and
            audience data.
          </p>
          <a
            href="mailto:advertise@thedailypoop.com"
            className="pressable mt-4 inline-block rounded-full bg-[var(--accent)] px-8 py-3 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)]"
          >
            advertise@thedailypoop.com
          </a>
        </div>
      </main>

      <Footer />
    </div>
  );
}
