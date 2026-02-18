import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 8)

                        Text("Last Updated: February 2026")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom, 16)

                        SwiftUI.Group {
                            SectionHeader(title: "Introduction")
                            BodyText(text: """
                            TheDailyPoop ("we," "us," or "our") respects your privacy. This Privacy Policy explains how we collect, use, store, and protect your personal information when you use the TheDailyPoop app ("the App").

                            By using TheDailyPoop, you agree to the collection and use of information as described in this policy.
                            """)

                            SectionHeader(title: "1. Information We Collect")
                            BodyText(text: """
                            We collect the following types of information:

                            A. Account Information:
                            \u{2022} Apple ID (encrypted identifier from Sign in with Apple)
                            \u{2022} Username (chosen by you)
                            \u{2022} Display name (optional)
                            \u{2022} Profile picture (optional, if uploaded)
                            \u{2022} Email address (if you choose to share it via Sign in with Apple)

                            B. Usage Data:
                            \u{2022} Stories you read and reading history
                            \u{2022} Reading streak and engagement statistics
                            \u{2022} Subscription status
                            \u{2022} App usage analytics (screens viewed, features used)

                            C. Device Information:
                            \u{2022} Device model and operating system version
                            \u{2022} Push notification token (for notifications)
                            \u{2022} App version

                            D. Approximate Location (Live Globe):
                            \u{2022} IP-based geolocation (city/country level) when you read a story
                            \u{2022} Used solely for the live reader globe visualization
                            \u{2022} No GPS or precise location data is collected
                            """)

                            SectionHeader(title: "2. How We Use Your Information")
                            BodyText(text: """
                            We use your information to:
                            \u{2022} Provide and maintain the TheDailyPoop service
                            \u{2022} Deliver daily news briefings
                            \u{2022} Track reading streaks and engagement stats
                            \u{2022} Display the live reader globe (approximate location only)
                            \u{2022} Send push notifications (briefing alerts, streak reminders)
                            \u{2022} Process subscription payments via Apple
                            \u{2022} Improve app performance and user experience
                            \u{2022} Prevent fraud and abuse
                            """)
                        }

                        SwiftUI.Group {
                            SectionHeader(title: "3. How We Share Your Information")
                            BodyText(text: """
                            We DO NOT sell your personal information to third parties.

                            We share information only in these circumstances:

                            A. Live Globe (Public):
                            \u{2022} Your username and approximate city/country may appear on the live reader globe when you read a story
                            \u{2022} This is visible to other users of the App

                            B. Service Providers:
                            \u{2022} Supabase (database and authentication)
                            \u{2022} Apple Push Notification Service (notifications)
                            \u{2022} RevenueCat (subscription management)
                            \u{2022} Vercel (API hosting, IP geolocation headers)

                            C. Legal Reasons:
                            \u{2022} To comply with laws, regulations, or legal processes
                            \u{2022} To protect our rights, property, or safety
                            \u{2022} To prevent fraud or illegal activity
                            """)

                            SectionHeader(title: "4. Data Storage and Security")
                            BodyText(text: """
                            Your data is stored securely using Supabase (PostgreSQL), which provides:
                            \u{2022} Row-level security policies
                            \u{2022} Encrypted data at rest and in transit
                            \u{2022} Regular security audits

                            We implement industry-standard security measures, but no system is 100% secure.

                            Data Retention:
                            \u{2022} Account data is retained until you delete your account
                            \u{2022} Reader session data (live globe) is automatically deleted after 2 hours
                            \u{2022} Deleted accounts are purged within 30 days
                            """)

                            SectionHeader(title: "5. Your Privacy Rights")
                            BodyText(text: """
                            You have the right to:
                            \u{2022} Access your personal data (view in Profile and Settings)
                            \u{2022} Correct inaccurate information (edit profile in Settings)
                            \u{2022} Delete your account (in Settings > Delete Account)
                            \u{2022} Control push notifications (iOS device settings)

                            To exercise these rights, use the in-app settings or contact us at karjunvarma2001@gmail.com.

                            For users in the EU/EEA: You have additional rights under GDPR, including data portability and the right to object to processing.
                            """)
                        }

                        SwiftUI.Group {
                            SectionHeader(title: "6. Children's Privacy")
                            BodyText(text: """
                            TheDailyPoop is not intended for children under 13. We do not knowingly collect data from children under 13.

                            If you are a parent and believe your child has created an account, please contact us immediately, and we will delete it.

                            Users aged 13-17 should obtain parental consent before using TheDailyPoop.
                            """)

                            SectionHeader(title: "7. Push Notifications")
                            BodyText(text: """
                            With your permission, we send push notifications for:
                            \u{2022} New briefing alerts (morning, midday, evening)
                            \u{2022} Streak reminders
                            \u{2022} Breaking news (rare, high-impact stories only)

                            You can disable notifications in iOS Settings > Notifications > TheDailyPoop.
                            """)

                            SectionHeader(title: "8. Cookies and Tracking")
                            BodyText(text: """
                            TheDailyPoop does not use cookies or third-party advertising trackers. As a native iOS app, we do not track you for advertising purposes.

                            We do not participate in cross-app tracking and respect Apple's App Tracking Transparency framework.
                            """)
                        }

                        SwiftUI.Group {
                            SectionHeader(title: "9. California Privacy Rights (CCPA)")
                            BodyText(text: """
                            If you are a California resident, you have the right to:
                            \u{2022} Know what personal information we collect and how it's used
                            \u{2022} Request deletion of your personal information
                            \u{2022} Opt out of the "sale" of personal information (we do not sell data)

                            To exercise these rights, contact us at karjunvarma2001@gmail.com or delete your account in Settings.
                            """)

                            SectionHeader(title: "10. Changes to This Policy")
                            BodyText(text: """
                            We may update this Privacy Policy from time to time. Changes will be posted in-app with an updated "Last Updated" date. Continued use of TheDailyPoop after changes constitutes acceptance of the new Privacy Policy.
                            """)

                            SectionHeader(title: "11. Contact Information")
                            BodyText(text: """
                            If you have questions about this Privacy Policy, contact us:

                            Email: karjunvarma2001@gmail.com
                            X/Twitter: @Arjun06061

                            We will respond to privacy inquiries within 7 business days.
                            """)
                        }

                        Text("Your privacy matters to us. We are committed to protecting your data and providing transparency about how we use it.")
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
            .navigationTitle("Privacy Policy")
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

#Preview {
    PrivacyPolicyView()
}
