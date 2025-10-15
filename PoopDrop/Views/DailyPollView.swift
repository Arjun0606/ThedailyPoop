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
                                    Text("Vote for 3 friends:")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("\(selectedFriends.count) / 3 selected")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    ForEach(friendsManager.friends) { friend in
                                        FriendVoteCard(
                                            friend: friend,
                                            isSelected: selectedFriends.contains(friend.id),
                                            onTap: {
                                                toggleFriendSelection(friend.id)
                                            }
                                        )
                                    }
                                    
                                    if selectedFriends.count == 3 {
                                        Button(action: submitVotes) {
                                            Text("Submit Votes")
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
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                        Text("Loading today's poll...")
                            .foregroundColor(.gray)
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
            .task {
                guard let currentUser = authManager.currentUser else { return }
                await pollManager.loadTodaysPoll(for: currentUser)
            }
        }
    }
    
    private func toggleFriendSelection(_ friendID: String) {
        if selectedFriends.contains(friendID) {
            selectedFriends.remove(friendID)
        } else if selectedFriends.count < 3 {
            selectedFriends.insert(friendID)
        }
    }
    
    private func submitVotes() {
        guard let currentUser = authManager.currentUser,
              let poll = pollManager.todaysPoll,
              selectedFriends.count == 3 else { return }
        
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
    @EnvironmentObject var friendsManager: FriendsManager
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    let poll: Poll
    let results: [(userID: String, votes: Int)]
    
    @State private var showingPurchase = false
    @State private var hasRevealed = false
    
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
                        
                        // Results
                        if hasRevealed {
                            VStack(spacing: 12) {
                                ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                                    if let friend = friendsManager.friends.first(where: { $0.id == result.userID }) {
                                        ResultCard(
                                            rank: index + 1,
                                            friend: friend,
                                            votes: result.votes
                                        )
                                    }
                                }
                            }
                            .padding()
                        } else {
                            // Blurred preview
                            VStack(spacing: 12) {
                                ForEach(0..<min(3, results.count), id: \.self) { index in
                                    HiddenResultCard(rank: index + 1)
                                }
                            }
                            .padding()
                            .blur(radius: 5)
                            
                            // Reveal button
                            VStack(spacing: 16) {
                                Text("💎")
                                    .font(.system(size: 60))
                                
                                Text("See who voted for you!")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                
                                if let product = storeKitManager.getProduct(byID: IAPProducts.pollReveal) {
                                    Button(action: { showingPurchase = true }) {
                                        VStack(spacing: 8) {
                                            Text("Reveal Voters")
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
                                        Text("Reveal Voters - $0.99")
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
                Text("See exactly who voted for you in this poll!")
            }
        }
    }
    
    private func purchaseReveal() {
        Task {
            do {
                if let product = storeKitManager.getProduct(byID: IAPProducts.pollReveal) {
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

