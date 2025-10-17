import SwiftUI

struct DailyPollView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var friendsManager: FriendsManager
    @EnvironmentObject var pointsManager: PointsManager
    @StateObject private var pollManager = PollManager.shared
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    @State private var showingResults = false
    @State private var results: [(userID: String, votes: Int)] = []
    @State private var selectedFriends: Set<String> = []
    @State private var showingCreatePoll = false
    @State private var newPollQuestion = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let poll = pollManager.todaysPoll {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 12) {
                                Text("📊")
                                    .font(.system(size: 60))
                                
                                Text("Today's Poll")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                
                                Text(poll.questionText)
                                    .font(.title3)
                                    .foregroundColor(.yellow)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 20)
                            
                            if !pollManager.hasVotedToday {
                                // Voting Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Vote for 1 friend:")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(selectedFriends.isEmpty ? "Tap to select" : "✓ Selected")
                                        .font(.subheadline)
                                        .foregroundColor(selectedFriends.isEmpty ? .gray : .green)
                                    
                                    ForEach(friendsManager.friends) { friend in
                                        FriendVoteCard(
                                            friend: friend,
                                            isSelected: selectedFriends.contains(friend.id),
                                            onTap: {
                                                toggleFriendSelection(friend.id)
                                            }
                                        )
                                    }
                                    
                                    if selectedFriends.count == 1 {
                                        Button(action: submitVotes) {
                                            Text("Submit Vote")
                                                .font(.headline)
                                                .foregroundColor(.black)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.yellow)
                                                .cornerRadius(12)
                                        }
                                        .padding(.top)
                                    }
                                }
                                .padding()
                            } else {
                                // Already Voted
                                VStack(spacing: 16) {
                                    Text("✅")
                                        .font(.system(size: 60))
                                    
                                    Text("You've voted!")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("Check back at midnight for tomorrow's poll")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: { showingResults = true }) {
                                        HStack {
                                            Image(systemName: "eye")
                                            Text("See Results")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.vertical, 40)
                            }
                        }
                        .padding()
                    }
                } else {
                    // No poll today - show create poll button
                    VStack(spacing: 24) {
                        Text("💭")
                            .font(.system(size: 80))
                        
                        Text("No Poll Today")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text("Be the first to create today's poll!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingCreatePoll = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Poll")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
            .navigationTitle("Daily Poll")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingResults) {
                PollResultsView(
                    poll: pollManager.todaysPoll!,
                    results: results
                )
            }
            .sheet(isPresented: $showingCreatePoll) {
                CreatePollView(
                    pollQuestion: $newPollQuestion,
                    onCreate: { question in
                        guard let currentUser = authManager.currentUser else { return }
                        Task {
                            await pollManager.createPoll(creator: currentUser, questionText: question)
                        }
                        showingCreatePoll = false
                    }
                )
            }
            .task {
                guard let currentUser = authManager.currentUser else { return }
                await pollManager.loadTodaysPoll(for: currentUser)
            }
        }
    }
    
    private func toggleFriendSelection(_ friendID: String) {
        if selectedFriends.contains(friendID) {
            selectedFriends.remove(friendID)
        } else {
            // Only allow 1 selection - clear previous and add new
            selectedFriends.removeAll()
            selectedFriends.insert(friendID)
        }
    }
    
    private func submitVotes() {
        guard let currentUser = authManager.currentUser,
              let poll = pollManager.todaysPoll,
              selectedFriends.count == 1 else { return }
        
        Task {
            for friendID in selectedFriends {
                if let friend = friendsManager.friends.first(where: { $0.id == friendID }) {
                    await pollManager.vote(
                        pollID: poll.id,
                        friend: friend,
                        voter: currentUser
                    )
                }
            }
            
            // Award points for voting
            var updatedUser = currentUser
            await pointsManager.awardPoints(to: &updatedUser, for: .winPoll)
        }
    }
}

struct FriendVoteCard: View {
    let friend: User
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar placeholder
                Circle()
                    .fill(Color.brown)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(friend.username.prefix(1)).uppercased())
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.username)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(friend.totalDrops) drops")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.yellow.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct PollResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var friendsManager: FriendsManager
    @StateObject private var storeKitManager = StoreKitManager.shared
    @StateObject private var pollManager = PollManager.shared
    
    let poll: Poll
    let results: [(userID: String, votes: Int)]
    
    @State private var showingPurchase = false
    @State private var hasRevealed = false
    @State private var detailedVotes: [PollVote] = []
    
    var currentUserRank: Int {
        guard let currentUser = authManager.currentUser else { return 0 }
        if let index = results.firstIndex(where: { $0.userID == currentUser.id }) {
            return index + 1
        }
        return results.count + 1
    }
    
    var currentUserVotes: Int {
        guard let currentUser = authManager.currentUser else { return 0 }
        return results.first(where: { $0.userID == currentUser.id })?.votes ?? 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("📊")
                                .font(.system(size: 60))
                            
                            Text(poll.questionText)
                                .font(.title3.bold())
                                .foregroundColor(.yellow)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // FIX 4: Leaderboard with competitive messaging
                        leaderboardSection
                        
                        // FIX 2: Partial results tease
                        if !hasRevealed {
                            partialResultsTeaseSection
                        } else {
                            fullResultsSection
                        }
                    }
                }
            }
            .navigationTitle("Poll Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Purchase Poll Reveal", isPresented: $showingPurchase) {
                Button("Buy $0.99") {
                    purchaseReveal()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("See exactly who voted for you and who didn't!")
            }
            .task {
                await loadDetailedVotes()
            }
        }
    }
    
    // FIX 4: Leaderboard Section with Competitive Messaging
    private var leaderboardSection: some View {
        VStack(spacing: 16) {
            Text("🏆 Leaderboard")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(Array(results.prefix(3).enumerated()), id: \.offset) { index, result in
                    if let friend = friendsManager.friends.first(where: { $0.id == result.userID }) {
                        HStack(spacing: 12) {
                            Text(index == 0 ? "🥇" : index == 1 ? "🥈" : "🥉")
                                .font(.title2)
                            
                            Text(friend.username)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(result.votes) votes")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(authManager.currentUser?.id == result.userID ? Color.purple.opacity(0.3) : Color.white.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            // Competitive messaging
            competitiveMessage
                .padding(.horizontal)
        }
    }
    
    private var competitiveMessage: some View {
        VStack(spacing: 8) {
            if currentUserRank == 1 {
                HStack {
                    Text("🔥")
                    Text("You're #1! Defend your position tomorrow!")
                        .font(.subheadline)
                        .foregroundColor(.yellow)
                }
            } else if currentUserRank <= 3 {
                let votesNeeded = results[currentUserRank - 2].votes - currentUserVotes + 1
                HStack {
                    Text("💪")
                    Text("Just \(votesNeeded) more vote\(votesNeeded == 1 ? "" : "s") to reach #\(currentUserRank - 1)!")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            } else {
                HStack {
                    Text("🎯")
                    Text("You're #\(currentUserRank). Win more votes tomorrow!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // FIX 2: Partial Results Tease
    private var partialResultsTeaseSection: some View {
        VStack(spacing: 20) {
            // Show ONE voter (tease)
            if let currentUser = authManager.currentUser,
               let firstVoter = detailedVotes.first(where: { $0.votedForID == currentUser.id }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WHO VOTED FOR YOU:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("@\(firstVoter.voterUsername) voted for you")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.2))
                    )
                    
                    if currentUserVotes > 1 {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.yellow)
                            Text("🔒 \(currentUserVotes - 1) more people voted for you...")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Reveal CTA
            VStack(spacing: 16) {
                Text("💎")
                    .font(.system(size: 60))
                
                Text("Unlock All Voters")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text("See everyone who voted for you and who didn't!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                if let product = storeKitManager.getProduct(byID: IAPProducts.gossipReveal) {
                    Button(action: { showingPurchase = true }) {
                        VStack(spacing: 8) {
                            Text("Reveal All Voters")
                                .font(.headline)
                            Text(product.displayPrice)
                                .font(.subheadline)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: { showingPurchase = true }) {
                        Text("Reveal All Voters - $0.99")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
    
    // Full results after purchase
    private var fullResultsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("WHO VOTED FOR YOU:")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            if let currentUser = authManager.currentUser {
                ForEach(detailedVotes.filter { $0.votedForID == currentUser.id }, id: \.id) { vote in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("@\(vote.voterUsername) voted for you")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.2))
                    )
                    .padding(.horizontal)
                }
            }
            
            Text("ALL VOTES:")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.top)
            
            ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                if let friend = friendsManager.friends.first(where: { $0.id == result.userID }) {
                    ResultCard(
                        rank: index + 1,
                        friend: friend,
                        votes: result.votes
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func loadDetailedVotes() async {
        detailedVotes = await pollManager.loadPollResults(pollID: poll.id)
    }
    
    private func purchaseReveal() {
        Task {
            do {
                if let product = storeKitManager.getProduct(byID: IAPProducts.gossipReveal) {
                    try await storeKitManager.purchase(product)
                    hasRevealed = true
                }
            } catch {
                print("❌ Purchase failed: \(error)")
            }
        }
    }
}

struct ResultCard: View {
    let rank: Int
    let friend: User
    let votes: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(rank)")
                .font(.title.bold())
                .foregroundColor(rank == 1 ? .yellow : .white)
                .frame(width: 40)
            
            Circle()
                .fill(Color.brown)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(friend.username.prefix(1)).uppercased())
                        .font(.title3.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.username)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(votes) vote\(votes == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if rank == 1 {
                Text("👑")
                    .font(.title)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct HiddenResultCard: View {
    let rank: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(rank)")
                .font(.title.bold())
                .foregroundColor(.white)
                .frame(width: 40)
            
            Circle()
                .fill(Color.gray)
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("??????")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("? votes")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    DailyPollView()
        .environmentObject(AuthenticationManager())
        .environmentObject(FriendsManager())
}

// MARK: - Create Poll View

struct CreatePollView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var pollQuestion: String
    let onCreate: (String) -> Void
    
    @State private var questionText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Text("💭")
                            .font(.system(size: 80))
                        
                        Text("Create Today's Poll")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("Ask your friends a fun question!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    // Question input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Question:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $questionText)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .font(.body)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("\(questionText.count) / 100 characters")
                            .font(.caption)
                            .foregroundColor(questionText.count > 100 ? .red : .gray)
                    }
                    .padding(.horizontal)
                    
                    // Example questions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Examples:")
                            .font(.subheadline.bold())
                            .foregroundColor(.gray)
                        
                        ForEach([
                            "Who's most likely to forget to flush?",
                            "Who has the funniest bathroom stories?",
                            "Who takes the longest bathroom breaks?"
                        ], id: \.self) { example in
                            Button(action: { questionText = example }) {
                                Text("• \(example)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Create button
                    Button(action: {
                        onCreate(questionText)
                    }) {
                        Text("Create Poll")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(questionText.count > 0 && questionText.count <= 100 ? Color.yellow : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(questionText.isEmpty || questionText.count > 100)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

