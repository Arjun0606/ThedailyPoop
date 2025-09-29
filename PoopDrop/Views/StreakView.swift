import SwiftUI

struct StreakView: View {
    let user: User
    let fontSize: Font
    
    init(user: User, fontSize: Font = .caption) {
        self.user = user
        self.fontSize = fontSize
    }
    
    private var isConstipated: Bool {
        // Check if user has a "No Poop" entry in the last 24 hours
        // For now, we'll use a simple heuristic - if they have a streak but no recent drop
        guard let lastDropDate = user.lastDropDate else { return false }
        let hoursSinceLastDrop = Date().timeIntervalSince(lastDropDate) / 3600
        return hoursSinceLastDrop > 12 && user.streak > 0
    }
    
    var body: some View {
        if user.streak > 0 {
            HStack(spacing: 4) {
                // Flame emoji
                Text("🔥")
                    .font(fontSize)
                
                // Streak number
                Text("\(user.streak)")
                    .font(fontSize)
                    .foregroundColor(.orange)
                
                // Constipation indicator
                if isConstipated {
                    Text("😵‍💫")
                        .font(fontSize)
                        .scaleEffect(0.8)
                }
            }
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
