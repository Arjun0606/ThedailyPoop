import Foundation
import CloudKit

@MainActor
class StreakManager: ObservableObject {
    
    private let calendar = Calendar.current
    
    /// Just update the last poop date - no complex streak calculations
    func logPoop(for user: inout User) {
        user.lastPoopDate = Date()
        print("💩 Poop logged for \(user.username) at \(user.lastPoopDate?.formatted() ?? "unknown time")")
    }
    
    /// Calculate days since last poop (for displaying constipation status)
    func daysSinceLastPoop(for user: User) -> Int {
        guard let lastPoop = user.lastPoopDate else {
            return 0 // Never pooped (or new user)
        }
        
        let days = calendar.dateComponents([.day], from: lastPoop, to: Date()).day ?? 0
        return max(0, days)
    }
    
    /// Get a fun constipation message based on days
    func constipationMessage(days: Int) -> String {
        switch days {
        case 0:
            return "Just pooped! ✨"
        case 1:
            return "1 day ago 💩"
        case 2:
            return "2 days ago 😐"
        case 3:
            return "3 days ago 😬"
        case 4...6:
            return "\(days) days ago 😵‍💫"
        case 7...13:
            return "\(days) days... you okay? 🚨"
        default:
            return "\(days) days... LEGEND STATUS 💀"
        }
    }
}
