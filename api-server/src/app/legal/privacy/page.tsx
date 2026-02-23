import { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: "TheDailyPoop privacy policy — how we collect, use, and protect your data.",
};

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-black">
      <Header />

      <main className="mx-auto max-w-3xl px-6 py-12">
        <h1 className="text-3xl font-black text-white">Privacy Policy</h1>
        <p className="mt-2 text-sm text-[var(--text-tertiary)]">Last updated: February 2026</p>

        <div className="mt-8 space-y-8 text-sm leading-relaxed text-zinc-300">
          <section>
            <h2 className="text-lg font-bold text-white">What We Collect</h2>
            <ul className="mt-3 list-disc space-y-2 pl-5">
              <li><strong className="text-white">Account info</strong> — email address and password when you sign up</li>
              <li><strong className="text-white">Apple ID</strong> — if you sign in via the iOS app</li>
              <li><strong className="text-white">Game data</strong> — your scores, submissions, and streaks</li>
              <li><strong className="text-white">Subscription status</strong> — whether you have an active Pro subscription</li>
              <li><strong className="text-white">Newsletter preferences</strong> — your email if you subscribe to our newsletter</li>
              <li><strong className="text-white">Usage data</strong> — pages viewed, reading patterns (anonymized)</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">How We Use It</h2>
            <ul className="mt-3 list-disc space-y-2 pl-5">
              <li>To deliver your daily briefing and personalize your experience</li>
              <li>To manage your subscription and premium access</li>
              <li>To send you the daily newsletter (if you opted in)</li>
              <li>To track game scores and leaderboards</li>
              <li>To improve our content and product</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Third-Party Services</h2>
            <ul className="mt-3 list-disc space-y-2 pl-5">
              <li><strong className="text-white">Supabase</strong> — authentication and database hosting</li>
              <li><strong className="text-white">RevenueCat</strong> — subscription management (iOS and web)</li>
              <li><strong className="text-white">Beehiiv</strong> — newsletter delivery and analytics</li>
              <li><strong className="text-white">Google AdSense</strong> — display advertising (web only)</li>
              <li><strong className="text-white">Vercel</strong> — web hosting</li>
            </ul>
            <p className="mt-2">Each service has its own privacy policy. We recommend reviewing them.</p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Data Retention</h2>
            <p className="mt-3">We retain your data for as long as your account is active. Game scores and leaderboard entries persist indefinitely. If you delete your account, we remove your personal data within 30 days.</p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Your Rights</h2>
            <ul className="mt-3 list-disc space-y-2 pl-5">
              <li><strong className="text-white">Access</strong> — request a copy of your data</li>
              <li><strong className="text-white">Delete</strong> — delete your account and all associated data</li>
              <li><strong className="text-white">Unsubscribe</strong> — opt out of the newsletter at any time</li>
            </ul>
            <p className="mt-2">To exercise these rights, email us at <a href="mailto:privacy@thedailypoop.com" className="text-[var(--accent)] hover:underline">privacy@thedailypoop.com</a>.</p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Cookies</h2>
            <p className="mt-3">We use essential cookies for authentication. Third-party ad services may use cookies for ad targeting. You can manage cookies in your browser settings.</p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Contact</h2>
            <p className="mt-3">Questions? Email <a href="mailto:privacy@thedailypoop.com" className="text-[var(--accent)] hover:underline">privacy@thedailypoop.com</a>.</p>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  );
}
