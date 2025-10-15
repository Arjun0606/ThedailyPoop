import SwiftUI

struct StreakView: View {
    let user: User
    let fontSize: Font
    @StateObject private var streakManager = StreakManager()
    
    init(user: User, fontSize: Font = .caption) {
        self.user = user
        self.fontSize = fontSize
    }
    
    private var daysSinceLastPoop: Int {
        return streakManager.daysSinceLastPoop(for: user)
    }
    
    private var poopEmoji: String {
        switch daysSinceLastPoop {
        case 0:
            return "💩" // Just pooped
        case 1...2:
            return "💩" // Recent
        case 3...6:
            return "😬" // Getting concerning
        default:
            return "😵‍💫" // Very constipated
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Poop emoji
            Text(poopEmoji)
                .font(fontSize)
            
            // Days since last poop
            Text("\(daysSinceLastPoop)")
                .font(fontSize)
                .foregroundColor(daysSinceLastPoop == 0 ? .green : (daysSinceLastPoop <= 2 ? .yellow : .orange))
            
            // Total drops badge
            Text("💰")
                .font(fontSize)
            Text("\(user.totalDrops)")
                .font(fontSize)
                .foregroundColor(.yellow)
        }
    }
}

// MARK: - Constipation Status Extension
extension User {
    var isConstipated: Bool {
        // Check if user marked "No Poop" recently or hasn't pooped in 12+ hours
        guard let lastDropDate = lastDropDate else { return false }
        let hoursSinceLastDrop = Date().timeIntervalSince(lastDropDate) / 3600
        return hoursSinceLastDrop > 12 && streak > 0
    }
    
    var streakDisplayText: String {
        if isConstipated {
            return "🔥 \(streak) 😵‍💫"
        } else {
            return "🔥 \(streak)"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Normal streak
        StreakView(user: User(
            username: "normaluser",
            dateOfBirth: Date(),
            gender: .male,
            appleUserID: "test",
            streak: 7
        ))
        
        // Constipated user (would need lastDropDate set to 13 hours ago in real usage)
        StreakView(user: User(
            username: "constipateduser", 
            dateOfBirth: Date(),
            gender: .female,
            appleUserID: "test2",
            streak: 5
        ))
    }
    .padding()
    .background(Color.black)
}
