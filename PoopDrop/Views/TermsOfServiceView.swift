import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Terms of Service")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 8)

                        Text("Last Updated: February 2026")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom, 16)

                        SwiftUI.Group {
                            SectionHeader(title: "1. Acceptance of Terms")
                            BodyText(text: """
                            By downloading, installing, or using TheDailyPoop ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.

                            TheDailyPoop is operated by Arjun Varma ("we," "us," or "our"). The App is a daily news briefing service that delivers curated stories across business, tech, politics, sports, and culture.
                            """)

                            SectionHeader(title: "2. Description of Service")
                            BodyText(text: """
                            TheDailyPoop is a daily news briefing app that provides:
                            \u{2022} Curated news stories across 5 categories (business, tech, politics, sports, culture)
                            \u{2022} 3 daily briefings (morning, midday, evening drops)
                            \u{2022} AI-rewritten summaries in an accessible, irreverent voice
                            \u{2022} Reading streak tracking and engagement stats
                            \u{2022} A live globe showing readers worldwide
                            \u{2022} Archival access to past briefings

                            The service is provided "as is" and may be modified, suspended, or discontinued at any time.
                            """)

                            SectionHeader(title: "3. User Accounts")
                            BodyText(text: """
                            You must create an account using Sign in with Apple to use TheDailyPoop. You agree to:
                            \u{2022} Provide accurate information during registration
                            \u{2022} Maintain the security of your account credentials
                            \u{2022} Immediately notify us of unauthorized account access
                            \u{2022} Be responsible for all activity under your account

                            You must be at least 13 years old to use TheDailyPoop. Users under 18 should obtain parental consent.
                            """)

                            SectionHeader(title: "4. Content and Intellectual Property")
                            BodyText(text: """
                            News content in TheDailyPoop is sourced from publicly available information and rewritten using AI. We do not claim ownership of the underlying news events.

                            All rights, title, and interest in TheDailyPoop (including design, code, graphics, AI-generated summaries, and branding) belong to Arjun Varma. You may not:
                            \u{2022} Copy, modify, or distribute the App or its content
                            \u{2022} Use our trademarks or branding without permission
                            \u{2022} Scrape, crawl, or systematically extract content from the App
                            \u{2022} Create derivative works based on TheDailyPoop
                            """)
                        }

                        SwiftUI.Group {
                            SectionHeader(title: "5. Subscriptions and Payments")
                            BodyText(text: """
                            TheDailyPoop offers free content (3 stories per drop) and a premium subscription for full access.

                            Premium subscriptions:
                            \u{2022} Are billed through Apple's App Store
                            \u{2022} Auto-renew unless cancelled before the renewal date
                            \u{2022} Can be managed in your Apple ID subscription settings
                            \u{2022} Are subject to Apple's refund policy

                            Prices may change with notice. Current subscribers will be informed before any price increase takes effect.
                            """)

                            SectionHeader(title: "6. User Conduct")
                            BodyText(text: """
                            You agree NOT to:
                            \u{2022} Use the App for illegal activities
                            \u{2022} Attempt to hack, reverse engineer, or exploit the App
                            \u{2022} Share your account credentials with others
                            \u{2022} Use automated systems to access the service
                            \u{2022} Circumvent subscription restrictions

                            We reserve the right to suspend accounts that violate these rules.
                            """)

                            SectionHeader(title: "7. Privacy")
                            BodyText(text: """
                            Your privacy is important to us. Our Privacy Policy (available in-app) explains how we collect, use, and protect your data. By using TheDailyPoop, you agree to our Privacy Policy.

                            We do not sell your personal information to third parties.
                            """)
                        }

                        SwiftUI.Group {
                            SectionHeader(title: "8. Disclaimer of Warranties")
                            BodyText(text: """
                            THEDAILYPOOP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. WE DO NOT GUARANTEE:
                            \u{2022} Uninterrupted or error-free service
                            \u{2022} Accuracy or completeness of news content
                            \u{2022} Compatibility with all devices
                            \u{2022} Timeliness of news delivery

                            TheDailyPoop is for informational and entertainment purposes. News summaries are AI-generated and should not be relied upon as the sole source of information for critical decisions.
                            """)

                            SectionHeader(title: "9. Limitation of Liability")
                            BodyText(text: """
                            TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR:
                            \u{2022} Indirect, incidental, or consequential damages
                            \u{2022} Loss of data, profits, or goodwill
                            \u{2022} Inaccuracies in news content or summaries
                            \u{2022} Issues arising from third-party services

                            Our total liability shall not exceed $100 USD or the amount you paid us in the preceding 12 months (whichever is greater).
                            """)

                            SectionHeader(title: "10. Termination")
                            BodyText(text: """
                            We may terminate or suspend your account at any time for:
                            \u{2022} Violation of these Terms
                            \u{2022} Fraudulent or illegal activity
                            \u{2022} Request by law enforcement
                            \u{2022} Any reason, at our sole discretion

                            You may delete your account at any time through the Settings screen. Upon termination, your data will be deleted within 30 days.
                            """)
                        }

                        SwiftUI.Group {
                            SectionHeader(title: "11. Changes to Terms")
                            BodyText(text: """
                            We reserve the right to modify these Terms at any time. Changes will be posted in-app with an updated "Last Updated" date. Continued use of TheDailyPoop after changes constitutes acceptance of the new Terms.
                            """)

                            SectionHeader(title: "12. Governing Law")
                            BodyText(text: """
                            These Terms are governed by the laws of India. Any disputes shall be resolved in the courts of Karnataka, India. If you are outside India, local laws may also apply.
                            """)

                            SectionHeader(title: "13. Contact Information")
                            BodyText(text: """
                            If you have questions about these Terms, contact us:
                            \u{2022} Email: karjunvarma2001@gmail.com
                            \u{2022} X/Twitter: @Arjun06061

                            We will respond to inquiries within 7 business days.
                            """)
                        }

                        Text("By using TheDailyPoop, you acknowledge that you have read, understood, and agree to these Terms of Service.")
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 16)
                            .background(Theme.accent.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.top, 16)

                        Spacer(minLength: 50)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.top, 8)
    }
}

struct BodyText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundColor(.gray)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    TermsOfServiceView()
}
