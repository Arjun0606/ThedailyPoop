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
                        
                        Text("Last Updated: September 30, 2025")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom, 16)
                        
                        Group {
                            SectionHeader(title: "1. Acceptance of Terms")
                            BodyText(text: """
                            By downloading, installing, or using Plop ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.
                            
                            Plop is operated by Arjun Varma ("we," "us," or "our"). The App is designed for entertainment and personal tracking purposes related to bathroom habits.
                            """)
                            
                            SectionHeader(title: "2. Description of Service")
                            BodyText(text: """
                            Plop is a social tracking app that allows you to:
                            • Log your bathroom visits with timestamps and locations
                            • View your activity on an interactive map
                            • Connect with friends and view their activity
                            • Track streaks, statistics, and earn achievements
                            • React to and comment on friends' activity
                            • Compete on leaderboards
                            
                            The service is provided "as is" and may be modified, suspended, or discontinued at any time.
                            """)
                            
                            SectionHeader(title: "3. User Accounts")
                            BodyText(text: """
                            You must create an account using Sign in with Apple to use Plop. You agree to:
                            • Provide accurate information during registration
                            • Maintain the security of your account credentials
                            • Immediately notify us of unauthorized account access
                            • Be responsible for all activity under your account
                            
                            You must be at least 13 years old to use Plop. Users under 18 should obtain parental consent.
                            """)
                            
                            SectionHeader(title: "4. User Content and Conduct")
                            BodyText(text: """
                            You are responsible for all content you post through Plop, including drop captions and reactions. You agree NOT to:
                            • Post offensive, harassing, or inappropriate content
                            • Impersonate others or create fake accounts
                            • Spam, harass, or bully other users
                            • Share others' personal information without consent
                            • Use the App for illegal activities
                            • Attempt to hack, reverse engineer, or exploit the App
                            
                            We reserve the right to remove content and suspend accounts that violate these rules.
                            """)
                        }
                        
                        Group {
                            SectionHeader(title: "5. Location Data")
                            BodyText(text: """
                            Plop collects your location when you log a drop. By using the App, you consent to:
                            • Collection of city/state-level location data
                            • Display of your drops on maps visible to your friends
                            • Storage of location history for statistical purposes
                            
                            You can control location permissions in your device settings. Disabling location will limit app functionality.
                            """)
                            
                            SectionHeader(title: "6. Privacy")
                            BodyText(text: """
                            Your privacy is important to us. Our Privacy Policy (available in-app) explains how we collect, use, and protect your data. By using Plop, you agree to our Privacy Policy.
                            
                            We do not sell your personal information to third parties. We use CloudKit for secure data storage and Google AdMob for advertising.
                            """)
                            
                            SectionHeader(title: "7. Advertising")
                            BodyText(text: """
                            Plop displays advertisements through Google AdMob. By using the App, you agree to see ads. Advertisers may collect data about your device and usage for targeted advertising. See our Privacy Policy for details.
                            """)
                            
                            SectionHeader(title: "8. Intellectual Property")
                            BodyText(text: """
                            All rights, title, and interest in Plop (including design, code, graphics, and branding) belong to Arjun Varma. You may not:
                            • Copy, modify, or distribute the App
                            • Use our trademarks or branding without permission
                            • Create derivative works based on Plop
                            
                            You retain ownership of your user-generated content but grant us a worldwide license to use, display, and distribute it within the App.
                            """)
                        }
                        
                        Group {
                            SectionHeader(title: "9. Disclaimer of Warranties")
                            BodyText(text: """
                            POOPDROP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. WE DO NOT GUARANTEE:
                            • Uninterrupted or error-free service
                            • Accuracy of data or statistics
                            • Compatibility with all devices
                            • Security against data loss or breaches
                            
                            Plop is for entertainment and personal tracking only. It is NOT a medical app and should not be used for health diagnosis or treatment.
                            """)
                            
                            SectionHeader(title: "10. Limitation of Liability")
                            BodyText(text: """
                            TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR:
                            • Indirect, incidental, or consequential damages
                            • Loss of data, profits, or goodwill
                            • Damages resulting from unauthorized account access
                            • Issues arising from third-party services (CloudKit, AdMob)
                            
                            Our total liability shall not exceed $100 USD or the amount you paid us (if any).
                            """)
                            
                            SectionHeader(title: "11. Indemnification")
                            BodyText(text: """
                            You agree to indemnify and hold harmless Arjun Varma from any claims, damages, or expenses arising from:
                            • Your use of Plop
                            • Your violation of these Terms
                            • Your violation of others' rights
                            • Content you post through the App
                            """)
                            
                            SectionHeader(title: "12. Termination")
                            BodyText(text: """
                            We may terminate or suspend your account at any time for:
                            • Violation of these Terms
                            • Fraudulent or illegal activity
                            • Request by law enforcement
                            • Any reason, at our sole discretion
                            
                            You may delete your account at any time through the Settings screen. Upon termination, your data will be deleted within 30 days.
                            """)
                        }
                        
                        Group {
                            SectionHeader(title: "13. Changes to Terms")
                            BodyText(text: """
                            We reserve the right to modify these Terms at any time. Changes will be posted in-app with an updated "Last Updated" date. Continued use of Plop after changes constitutes acceptance of the new Terms.
                            """)
                            
                            SectionHeader(title: "14. Governing Law")
                            BodyText(text: """
                            These Terms are governed by the laws of India. Any disputes shall be resolved in the courts of Karnataka, India. If you are outside India, local laws may also apply.
                            """)
                            
                            SectionHeader(title: "15. Contact Information")
                            BodyText(text: """
                            If you have questions about these Terms, contact us:
                            • Email: karjunvarma2001@gmail.com
                            • X/Twitter: @Arjun06061
                            
                            We will respond to inquiries within 7 business days.
                            """)
                            
                            SectionHeader(title: "16. Miscellaneous")
                            BodyText(text: """
                            • Severability: If any provision is unenforceable, the rest remains valid.
                            • No Waiver: Failure to enforce a right does not waive it.
                            • Entire Agreement: These Terms constitute the full agreement between you and us.
                            • Assignment: We may assign these Terms; you may not.
                            """)
                        }
                        
                        Text("By using Plop, you acknowledge that you have read, understood, and agree to these Terms of Service.")
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
