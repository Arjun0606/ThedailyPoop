import Foundation
import UserNotifications
import SwiftUI

/// Manages contextual permission requests (notifications, etc.)
/// Asks at the RIGHT moment when user understands value
@MainActor
class SmartPermissionManager: ObservableObject {
    static let shared = SmartPermissionManager()
    
    @Published var shouldShowNotificationPrompt = false
    @Published var notificationPromptContext: NotificationPromptContext?
    
    private let notificationManager: NotificationManager
    private let analyticsManager: AnalyticsManager
    
    private init() {
        self.notificationManager = NotificationManager.shared
        self.analyticsManager = AnalyticsManager.shared
    }
    
    // MARK: - Smart Prompts
    
    /// Called when user receives their first fart attack
    func checkAfterFirstAttackReceived() {
        // Only prompt if not already asked
        guard !hasAskedForNotifications() else { return }
        
        // Wait 2 seconds for attack animation to finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.notificationPromptContext = .firstAttackReceived
            self.shouldShowNotificationPrompt = true
        }
    }
    
    /// Called when user reaches 3-day streak
    func checkAfterStreakMilestone(days: Int) {
        // Only prompt at 3 days if not already asked
        guard days == 3, !hasAskedForNotifications() else { return }
        
        notificationPromptContext = .streakMilestone(days: days)
        shouldShowNotificationPrompt = true
    }
    
    /// Called when user's streak is about to break (hasn't logged in 20+ hours)
    func checkBeforeStreakBreak(currentStreak: Int) {
        // Only if they have a meaningful streak and notifications enabled
        guard currentStreak >= 3 else { return }
        
        // This would be called by a background task or server
        // For now, just log that we should send a notification
        print("⚠️ User streak \(currentStreak) at risk. Send reminder notification.")
    }
    
    // MARK: - Request Permissions
    
    func requestNotificationPermission(context: NotificationPromptContext) async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            
            // Track the result
            analyticsManager.trackNotificationPermission(granted: granted, context: context.analyticsKey)
            
            // Save that we asked
            UserDefaults.standard.set(true, forKey: "hasAskedForNotifications")
            UserDefaults.standard.set(Date(), forKey: "notificationAskedDate")
            
            if granted {
                // Register for remote notifications
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func dismissPrompt() {
        shouldShowNotificationPrompt = false
        notificationPromptContext = nil
        
        // Mark as asked (even if dismissed)
        UserDefaults.standard.set(true, forKey: "hasAskedForNotifications")
    }
    
    // MARK: - Helper Methods
    
    private func hasAskedForNotifications() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasAskedForNotifications")
    }
}

// MARK: - Notification Prompt Context

enum NotificationPromptContext {
    case firstAttackReceived
    case streakMilestone(days: Int)
    case comebackReminder
    
    var title: String {
        switch self {
        case .firstAttackReceived:
            return "Don't Miss Future Attacks!"
        case .streakMilestone(let days):
            return "Protect Your \(days)-Day Streak!"
        case .comebackReminder:
            return "Your Friends Miss You!"
        }
    }
    
    var message: String {
        switch self {
        case .firstAttackReceived:
            return "Get notified when friends send you fart attacks and react to yours. Never miss the fun!"
        case .streakMilestone:
            return "Enable notifications so we can remind you before your streak breaks. You've worked hard for this!"
        case .comebackReminder:
            return "Stay in the loop with friend activity and streak reminders."
        }
    }
    
    var analyticsKey: String {
        switch self {
        case .firstAttackReceived:
            return "first_attack"
        case .streakMilestone(let days):
            return "streak_\(days)_days"
        case .comebackReminder:
            return "comeback"
        }
    }
}

// MARK: - Smart Permission Prompt View

struct SmartNotificationPrompt: View {
    @EnvironmentObject var permissionManager: SmartPermissionManager
    let context: NotificationPromptContext
    let onGranted: () -> Void
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    permissionManager.dismissPrompt()
                }
            
            // Prompt card
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                // Title
                Text(context.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                // Message
                Text(context.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        Task {
                            let granted = await permissionManager.requestNotificationPermission(context: context)
                            await MainActor.run {
                                permissionManager.shouldShowNotificationPrompt = false
                                if granted {
                                    onGranted()
                                }
                            }
                        }
                    } label: {
                        Text("Enable Notifications")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        permissionManager.dismissPrompt()
                    } label: {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 40)
            .shadow(radius: 20)
        }
    }
}

