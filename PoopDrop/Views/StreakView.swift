import SwiftUI

struct StreakView: View {
    let user: User
    let fontSize: Font
    
    init(user: User, fontSize: Font = .caption) {
        self.user = user
        self.fontSize = fontSize
    }
    
    private var constipatedDays: Int {
        // Count full days since last REAL poop
        guard let lastReal = user.lastRealDropDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: lastReal, to: Date()).day ?? 0
        return max(0, days)
    }
    
    var body: some View {
        if user.streak > 0 {
            HStack(spacing: 6) {
                // Flame emoji
                Text("🔥")
                    .font(fontSize)
                
                // Streak number
                Text("\(user.streak)")
                    .font(fontSize)
                    .foregroundColor(.orange)
                
                // Constipated counter (days without a real poop)
                if constipatedDays >= 1 {
                    Text("😵‍💫 \(constipatedDays)")
                        .font(fontSize)
                        .foregroundColor(.white)
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
