import Foundation
import CloudKit

@MainActor
class StreakManager: ObservableObject {
    
    private let calendar = Calendar.current
    
    // Checks streak and resets if broken. No grace period.
    func checkAndUpdateStreak(for user: inout User) {
        guard let lastLogDate = user.lastStreakLogDate else {
            return
        }
        
        // If the last log was not yesterday or today, the streak is broken.
        if !calendar.isDateInToday(lastLogDate) && !calendar.isDateInYesterday(lastLogDate) {
            if user.streak > 0 {
                print("🔥 Streak broken for user \(user.username). Was \(user.streak) days. Resetting to 0.")
                user.streak = 0
            }
        }
    }
    
    func logPoop(for user: inout User) {
        let today = Date()
        
        if let lastLogDate = user.lastStreakLogDate {
            if calendar.isDateInToday(lastLogDate) {
                // Already logged today.
            } else if calendar.isDateInYesterday(lastLogDate) {
                // Logged yesterday, increment streak.
                user.streak += 1
            } else {
                // Missed a day or more, reset to 1.
                user.streak = 1
            }
        } else {
            // First ever poop log.
            user.streak = 1
        }
        
        // Update user properties
        user.lastStreakLogDate = today
        if user.streak > user.longestStreak {
            user.longestStreak = user.streak
        }
        
        print("💩 Poop logged for \(user.username). New streak: \(user.streak). Longest: \(user.longestStreak)")
    }
}
