import { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "Terms of Service",
  description: "TheDailyPoop terms of service — the rules of engagement.",
};

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-black">
      <Header />

      <main className="mx-auto max-w-3xl px-6 py-12">
        <h1 className="text-3xl font-black text-white">Terms of Service</h1>
        <p className="mt-2 text-sm text-[var(--text-tertiary)]">Last updated: February 2026</p>

        <div className="mt-8 space-y-8 text-sm leading-relaxed text-zinc-300">
          <section>
            <h2 className="text-lg font-bold text-white">The Service</h2>
            <p className="mt-3">TheDailyPoop is a daily news entertainment platform that delivers 25 satirical news stories per day, along with AI-powered games, through our iOS app, website, and newsletter. By using TheDailyPoop, you agree to these terms.</p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Accounts</h2>
            <ul className="mt-3 list-disc space-y-2 pl-5">
              <li>You must provide a valid email address to create an account</li>
              <li>You are responsible for maintaining the security of your account</li>
              <li>One account per person. Shared accounts may be terminated</li>
              <li>You must be at least 13 years old to use TheDailyPoop</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Subscriptions</h2>
            <ul className="mt-3 list-disc space-y-2 pl-5">
              <li><strong className="text-white">Free tier</strong> — access to 15-20 free stories, 1 game, and 3 days of history</li>
              <li><strong className="text-white">Pro subscription</strong> — $7.99/month or $59.99/year for full access</li>
              <li>Pro includes a 7-day free trial for new subscribers</li>
              <li>Subscriptions auto-renew unless cancelled before the renewal date</li>
              <li>iOS subscriptions are managed through Apple and subject to Apple&apos;s terms</li>
              <li>Web subscriptions are processed by Stripe through RevenueCat</li>
              <li>Refunds for iOS purchases are handled by Apple. Web refunds can be requested by email</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Content</h2>
            <ul className="mt-3 list-disc space-y-2 pl-5">
              <li>Our stories are satirical commentary and entertainment, not financial, legal, or professional advice</li>
              <li>All content is created by AI and edited by humans. We aim for accuracy in facts but our tone is intentionally irreverent</li>
              <li>You may share individual stories via the share buttons provided. Bulk copying or republishing is not permitted</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">User-Generated Content</h2>
            <p className="mt-3">When you submit roasts, predictions, or other game content:</p>
            <ul className="mt-2 list-disc space-y-2 pl-5">
              <li>You retain ownership of your submissions</li>
              <li>You grant us a non-exclusive license to display them within the app and newsletter</li>
              <li>Do not submit content that is illegal, threatening, or violates others&apos; rights</li>
              <li>We may remove submissions at our discretion</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Acceptable Use</h2>
            <p className="mt-3">Don&apos;t:</p>
            <ul className="mt-2 list-disc space-y-2 pl-5">
              <li>Use bots or automated tools to access our content or APIs</li>
              <li>Attempt to bypass paywalls or subscription gating</li>
              <li>Resell or redistribute our content</li>
              <li>Harass other users through game features</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Limitation of Liability</h2>
            <p className="mt-3">TheDailyPoop is provided &ldquo;as is&rdquo; without warranties. We are not liable for any damages arising from your use of the service. Our total liability is limited to the amount you paid us in the past 12 months.</p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Changes</h2>
            <p className="mt-3">We may update these terms. Continued use after changes constitutes acceptance. We&apos;ll notify you of material changes via email or in-app notification.</p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white">Contact</h2>
            <p className="mt-3">Questions? Email <a href="mailto:legal@thedailypoop.com" className="text-[var(--accent)] hover:underline">legal@thedailypoop.com</a>.</p>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  );
}
