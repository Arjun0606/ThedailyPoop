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
                        
                        Text("Last Updated: September 30, 2025")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom, 16)
                        
                        Group {
                            SectionHeader(title: "Introduction")
                            BodyText(text: """
                            PoopDrop ("we," "us," or "our") respects your privacy. This Privacy Policy explains how we collect, use, store, and protect your personal information when you use the PoopDrop app ("the App").
                            
                            By using PoopDrop, you agree to the collection and use of information as described in this policy.
                            """)
                            
                            SectionHeader(title: "1. Information We Collect")
                            BodyText(text: """
                            We collect the following types of information:
                            
                            A. Account Information:
                            • Apple ID (encrypted identifier from Sign in with Apple)
                            • Username (chosen by you)
                            • Profile picture (optional, if uploaded)
                            • Date of birth
                            • Gender (optional)
                            • Email address (if you choose to share it via Sign in with Apple)
                            
                            B. Location Data:
                            • City, state, and country when you log a drop
                            • GPS coordinates (converted to city/state; exact coordinates are not stored long-term)
                            • Location history for map and statistics features
                            
                            C. Usage Data:
                            • Drops you log (timestamp, emoji, caption, location)
                            • Friends list and friend requests
                            • Reactions and interactions with other users' content
                            • Streak data, statistics, and achievements
                            • App usage analytics (screens viewed, features used)
                            
                            D. Device Information:
                            • Device model and operating system version
                            • Unique device identifiers (for analytics and advertising)
                            • App version and language settings
                            """)
                            
                            SectionHeader(title: "2. How We Use Your Information")
                            BodyText(text: """
                            We use your information to:
                            • Provide and maintain the PoopDrop service
                            • Display your drops on maps and in feeds
                            • Calculate statistics, streaks, and achievements
                            • Facilitate social features (friends, leaderboards, notifications)
                            • Send push notifications (drop alerts, streak reminders, friend activity)
                            • Improve app performance and user experience
                            • Display personalized advertisements
                            • Prevent fraud, abuse, and violations of our Terms of Service
                            • Comply with legal obligations
                            """)
                        }
                        
                        Group {
                            SectionHeader(title: "3. How We Share Your Information")
                            BodyText(text: """
                            Your privacy is important to us. We DO NOT sell your personal information to third parties.
                            
                            We share information only in these circumstances:
                            
                            A. With Your Friends:
                            • Your drops (emoji, caption, city/state, timestamp) are visible to friends you've accepted
                            • Your profile (username, avatar, stats) is visible to friends
                            • Your location history is visible to friends on the map
                            
                            B. With Service Providers:
                            • Apple CloudKit (for secure data storage and sync)
                            • Google AdMob (for advertising; see Advertising section below)
                            • Apple Push Notification Service (for notifications)
                            
                            C. For Legal Reasons:
                            • To comply with laws, regulations, or legal processes
                            • To protect our rights, property, or safety
                            • To prevent fraud or illegal activity
                            
                            D. Business Transfers:
                            • If PoopDrop is acquired or merged, your data may be transferred to the new entity
                            """)
                            
                            SectionHeader(title: "4. Advertising and Third-Party Services")
                            BodyText(text: """
                            PoopDrop uses Google AdMob to display advertisements. AdMob may collect:
                            • Device identifiers (IDFA on iOS)
                            • IP address and general location
                            • Ad interaction data (views, clicks)
                            
                            AdMob uses this data for targeted advertising. You can opt out of personalized ads in your iOS Settings:
                            Settings > Privacy > Tracking > Disable "Allow Apps to Request to Track"
                            
                            Learn more at: https://policies.google.com/privacy
                            """)
                            
                            SectionHeader(title: "5. Data Storage and Security")
                            BodyText(text: """
                            Your data is stored securely using Apple CloudKit, which provides:
                            • End-to-end encryption for private data
                            • Secure data centers in multiple regions
                            • Regular security audits and compliance certifications
                            
                            We implement industry-standard security measures, but no system is 100% secure. Use PoopDrop at your own risk.
                            
                            Data Retention:
                            • Drops are visible for 3 days in feeds, but stored indefinitely for map and stats
                            • Account data is retained until you delete your account
                            • Deleted accounts are purged within 30 days
                            """)
                        }
                        
                        Group {
                            SectionHeader(title: "6. Location Privacy")
                            BodyText(text: """
                            PoopDrop collects location data to provide map and location-based features. We prioritize your privacy:
                            
                            • Only city/state/country is displayed (not exact coordinates)
                            • Location data is collected only when you log a drop
                            • You can disable location access in Settings (app functionality will be limited)
                            • Location history is visible only to you and your friends
                            
                            We do not share your location with advertisers or third parties beyond what's necessary for service operation.
                            """)
                            
                            SectionHeader(title: "7. Your Privacy Rights")
                            BodyText(text: """
                            You have the right to:
                            • Access your personal data (view in Profile and Settings)
                            • Correct inaccurate information (edit profile in Settings)
                            • Delete your account (in Settings > Delete Account)
                            • Opt out of personalized ads (iOS device settings)
                            • Control push notifications (iOS device settings)
                            • Control location permissions (iOS device settings)
                            
                            To exercise these rights, use the in-app settings or contact us at arjunvarma2001@gmail.com.
                            
                            For users in the EU/EEA: You have additional rights under GDPR, including data portability and the right to object to processing.
                            """)
                            
                            SectionHeader(title: "8. Children's Privacy")
                            BodyText(text: """
                            PoopDrop is not intended for children under 13. We do not knowingly collect data from children under 13.
                            
                            If you are a parent and believe your child has created an account, please contact us immediately, and we will delete it.
                            
                            Users aged 13-17 should obtain parental consent before using PoopDrop.
                            """)
                            
                            SectionHeader(title: "9. International Data Transfers")
                            BodyText(text: """
                            PoopDrop is operated from India. Your data may be transferred to and stored in servers located outside your country of residence, including the United States (CloudKit data centers).
                            
                            By using PoopDrop, you consent to the transfer of your data to these locations. We ensure appropriate safeguards are in place to protect your data.
                            """)
                        }
                        
                        Group {
                            SectionHeader(title: "10. Push Notifications")
                            BodyText(text: """
                            With your permission, we send push notifications for:
                            • Friend drop alerts
                            • Streak reminders (if you haven't logged in 12+ hours)
                            • Streak break warnings
                            • Friend requests and acceptances
                            • Reactions to your drops
                            
                            You can disable notifications in iOS Settings > Notifications > PoopDrop.
                            """)
                            
                            SectionHeader(title: "11. Cookies and Tracking")
                            BodyText(text: """
                            PoopDrop does not use cookies (it's a native iOS app, not a website). However, third-party services like AdMob may use similar tracking technologies for advertising purposes.
                            
                            You can control tracking in iOS Settings > Privacy > Tracking.
                            """)
                            
                            SectionHeader(title: "12. Changes to This Policy")
                            BodyText(text: """
                            We may update this Privacy Policy from time to time. Changes will be posted in-app with an updated "Last Updated" date.
                            
                            Significant changes will be communicated via:
                            • In-app notification
                            • Email (if you've provided one)
                            
                            Continued use of PoopDrop after changes constitutes acceptance of the new Privacy Policy.
                            """)
                            
                            SectionHeader(title: "13. Your California Privacy Rights (CCPA)")
                            BodyText(text: """
                            If you are a California resident, you have the right to:
                            • Know what personal information we collect and how it's used
                            • Request deletion of your personal information
                            • Opt out of the "sale" of personal information (we do not sell data)
                            
                            To exercise these rights, contact us at arjunvarma2001@gmail.com or delete your account in Settings.
                            """)
                            
                            SectionHeader(title: "14. Data Breach Notification")
                            BodyText(text: """
                            In the event of a data breach that affects your personal information, we will:
                            • Notify affected users within 72 hours (if feasible)
                            • Provide details about the breach and steps we're taking
                            • Recommend actions you can take to protect yourself
                            
                            We will also notify relevant authorities as required by law.
                            """)
                        }
                        
                        Group {
                            SectionHeader(title: "15. Contact Information")
                            BodyText(text: """
                            If you have questions, concerns, or requests regarding this Privacy Policy or your personal data, contact us:
                            
                            Email: arjunvarma2001@gmail.com
                            X/Twitter: @Arjun06061
                            
                            We will respond to privacy inquiries within 7 business days.
                            """)
                            
                            SectionHeader(title: "16. Consent")
                            BodyText(text: """
                            By using PoopDrop, you consent to:
                            • Collection and use of your information as described
                            • Display of your drops and profile to friends
                            • Use of location data for map and stats features
                            • Display of advertisements powered by AdMob
                            • Transfer of data to service providers (CloudKit, AdMob)
                            
                            You can withdraw consent by deleting your account or discontinuing use of the App.
                            """)
                        }
                        
                        Text("Your privacy matters to us. We are committed to protecting your data and providing transparency about how we use it.")
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 16)
                            .background(Color.brown.opacity(0.2))
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
