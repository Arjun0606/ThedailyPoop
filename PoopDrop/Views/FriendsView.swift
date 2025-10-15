import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @StateObject private var friendsManager = FriendsManager()
    @State private var showingAddFriend = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    FriendsTabSelector(selectedTab: $selectedTab)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Content based on selected tab
                    TabView(selection: $selectedTab) {
                        // Friends list
                        FriendsListView(friends: friendsManager.friends, selectedTab: $selectedTab)
                            .tag(0)
                        
                        // Friend requests
                        FriendRequestsView(
                            requests: friendsManager.friendRequests,
                            onAccept: { userId in
                                await acceptFriendRequest(userId)
                            },
                            onReject: { userId in
                                await rejectFriendRequest(userId)
                            }
                        )
                        .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("👥 Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: DailyLeaderboardView()) {
                        HStack(spacing: 4) {
                            Text("🏆")
                            Text("Ranks")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.yellow)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView()
                .environmentObject(friendsManager)
        }
        .onAppear {
            loadFriendsData()
        }
    }
    
    private func loadFriendsData() {
        guard let user = authManager.currentUser else { return }
        
        Task {
            await friendsManager.loadFriends(for: user)
            await friendsManager.loadFriendRequests(for: user)
        }
    }
    
    private func acceptFriendRequest(_ userId: String) async {
        guard var user = authManager.currentUser else { return }
        
        do {
            try await friendsManager.acceptFriendRequest(from: userId, currentUser: &user)
            authManager.currentUser = user
        } catch {
            friendsManager.errorMessage = error.localizedDescription
        }
    }
    
    private func rejectFriendRequest(_ userId: String) async {
        guard var user = authManager.currentUser else { return }
        
        do {
            try await friendsManager.rejectFriendRequest(from: userId, currentUser: &user)
            authManager.currentUser = user
        } catch {
            friendsManager.errorMessage = error.localizedDescription
        }
    }
}

struct FriendsTabSelector: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                selectedTab = 0
            }) {
                VStack(spacing: 4) {
                    Text("Friends")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Rectangle()
                        .fill(selectedTab == 0 ? Color.white : Color.clear)
                        .frame(height: 2)
                }
                .foregroundColor(selectedTab == 0 ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            
            Button(action: {
                selectedTab = 1
            }) {
                VStack(spacing: 4) {
                    Text("Requests")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Rectangle()
                        .fill(selectedTab == 1 ? Color.white : Color.clear)
                        .frame(height: 2)
                }
                .foregroundColor(selectedTab == 1 ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct FriendsListView: View {
    let friends: [User]
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var pointsManager: PointsManager
    @StateObject private var fartAttackManager = FartAttackManager.shared
    @Binding var selectedTab: Int
    @State private var showingInvite = false
    
    var attacksAvailable: Int {
        fartAttackManager.inventory?.availableAttacks ?? 0
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Removed "Out of Ghost Attacks" banner per user request
                
                // Invite Friends Card (below action card)
                InviteFriendsCard(showingInvite: $showingInvite)
                    .padding(.horizontal)
                
                if friends.isEmpty {
                    EmptyFriendsView()
                } else {
                        ForEach(friends) { friend in
                            FriendRowView(friend: friend, selectedTab: $selectedTab)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .sheet(isPresented: $showingInvite) {
            InviteFriendsView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - Dynamic Action Card (Buy More or Attack)
struct DynamicActionCard: View {
    let attacksAvailable: Int
    @Binding var showingInvite: Bool
    @Binding var selectedTab: Int
    @State private var showingShop = false
    
    var body: some View {
        if attacksAvailable <= 1 {
            // Show "Buy More Attacks" when low
            NavigationLink(destination: FartAttackShopView()) {
                HStack(spacing: 16) {
                    Text("💸")
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if attacksAvailable == 0 {
                            Text("Out of Ghost Attacks!")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Get 3 attacks for $2.99")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        } else {
                            Text("Running Low!")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Stock up now - $2.99 for 3 more")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.yellow)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.red.opacity(0.3), Color.orange.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                )
            }
        } else {
            // Show "Attack a Friend" when they have attacks
            Button(action: {
                // Scroll to friends list (they're already on this view)
            }) {
                HStack(spacing: 16) {
                    Text("💨")
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready to Prank!")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("You have \(attacksAvailable) attack\(attacksAvailable == 1 ? "" : "s") - tap a friend below")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.orange)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.purple.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
            }
        }
    }
}

struct InviteFriendsCard: View {
    @Binding var showingInvite: Bool
    
    var body: some View {
        Button(action: {
            showingInvite = true
        }) {
            HStack(spacing: 16) {
                Text("👥")
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invite Friends")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Share TheDailyPoop with your friends!")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
    }
}

struct FriendRequestsView: View {
    let requests: [User]
    let onAccept: (String) async -> Void
    let onReject: (String) async -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if requests.isEmpty {
                    EmptyRequestsView()
                } else {
                    ForEach(requests) { request in
                        FriendRequestRowView(
                            request: request,
                            onAccept: { await onAccept(request.id) },
                            onReject: { await onReject(request.id) }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
}

struct FriendRowView: View {
    let friend: User
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationLink(destination: FriendDetailView(friend: friend, selectedTab: $selectedTab)) {
            HStack(spacing: 12) {
            // Profile picture
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brown.opacity(0.7), Color.brown],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(friend.username.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(friend.username)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    // Pro badges removed - all users get badges now
                    if true {
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.yellow)
                            .cornerRadius(3)
                    }
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("💩")
                            .font(.caption)
                        Text("\(friend.totalDrops)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    StreakView(user: friend, fontSize: .caption)
                    
                    Text("Location Private")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Friend Detail View
struct FriendDetailView: View {
    let friend: User
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var pointsManager: PointsManager
    @StateObject private var fartAttackManager = FartAttackManager.shared
    @Binding var selectedTab: Int
    @State private var showingPurchaseSheet = false
    @State private var showingInvite = false
    @State private var sendingAttack = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var canSendAttack: Bool {
        fartAttackManager.canSendAttack(to: friend)
    }
    
    var cooldownRemaining: TimeInterval? {
        fartAttackManager.getCooldownRemaining(for: friend)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header - Compact
                    VStack(spacing: 12) {
            Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.brown.opacity(0.7), Color.brown],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(friend.username.prefix(1)).uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Text("@\(friend.username)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 12)
                    
                    // FART ATTACK SECTION - MOST PROMINENT
                    VStack(spacing: 16) {
                        // Low inventory banner
                        BuyMoreBanner(selectedTab: $selectedTab)
                        // Ghost Attack Button
                        if let inventory = fartAttackManager.inventory, inventory.availableAttacks > 0 {
                            if canSendAttack {
                                Button(action: {
                                    sendFartAttack()
                                }) {
                                    VStack(spacing: 12) {
                                        Text("💨")
                                            .font(.system(size: 60))
                                        
                                        Text("Send Ghost Attack!")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                        
                                        Text("Send legendary 4-second fart")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Text("Attacks available: \(inventory.availableAttacks)")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                            .padding(.top, 4)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.orange, Color.red.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(16)
                                }
                                .disabled(sendingAttack)
                            } else if let remaining = cooldownRemaining {
                                VStack(spacing: 12) {
                                    Text("⏰")
                                        .font(.system(size: 60))
                                    
                                    Text("Cooldown Active")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Can attack again in:")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text(fartAttackManager.formatCooldownTime(remaining))
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(16)
                            }
                        } else {
                            // No attacks available - show buy button
                            VStack(spacing: 12) {
                                Button(action: { showingPurchaseSheet = true }) {
                                    VStack(spacing: 12) {
                                        Text("💨")
                                            .font(.system(size: 60))
                                        Text("Get Ghost Attacks")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                        Text("Pick a pack: 3 / 10 / 25")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(16)
                                }
                                
                                // Secondary CTA: Invite friends to keep virality high
                                Button(action: { showingInvite = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Invite friends while you wait")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Stats Section
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("\(friend.totalDrops)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Drops")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Divider()
                            .frame(height: 40)
                            .background(Color.white.opacity(0.2))
                        
                        VStack(spacing: 4) {
                            Text("\(friend.streak)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Streak")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ghost Attack Sent!", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your legendary fart will hit @\(friend.username) when they open the app! 💨")
        }
        .alert("Failed to Send", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingPurchaseSheet) {
            FartAttackShopView()
        }
        .sheet(isPresented: $showingInvite) {
            InviteFriendsView()
        }
    }
    
    private func sendFartAttack() {
        guard let currentUser = authManager.currentUser else {
            errorMessage = "Please sign in to send ghost attacks."
            showingError = true
            return
        }
        
        sendingAttack = true
        
        Task {
            let success = await fartAttackManager.sendAttack(from: currentUser, to: friend, pointsManager: pointsManager)
            
            await MainActor.run {
                sendingAttack = false
                
                if success {
                    showingSuccess = true
                } else {
                    errorMessage = "Failed to send ghost attack. Please try again."
                    showingError = true
                }
            }
        }
    }
}

struct FriendRequestRowView: View {
    let request: User
    let onAccept: () async -> Void
    let onReject: () async -> Void
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brown.opacity(0.7), Color.brown],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(request.username.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // Request info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(request.username)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    // Pro badges removed - all users get badges now
                    if false { // Hide Pro badge for now
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.yellow)
                            .cornerRadius(3)
                    }
                }
                
                Text("Wants to be friends")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Action buttons
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                HStack(spacing: 8) {
                    Button(action: {
                        Task {
                            isProcessing = true
                            await onReject()
                            isProcessing = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(Color.red.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        Task {
                            isProcessing = true
                            await onAccept()
                            isProcessing = false
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct EmptyFriendsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("👥")
                .font(.system(size: 60))
            
            VStack(spacing: 8) {
                Text("No Friends Yet")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Add friends to see their poop drops and compete on leaderboards!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 60)
    }
}

struct EmptyRequestsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("📬")
                .font(.system(size: 60))
            
            VStack(spacing: 8) {
                Text("No Friend Requests")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("When someone sends you a friend request, it will appear here.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 60)
    }
}

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var friendsManager: FriendsManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("Search by name...", text: $searchText)
                            .foregroundColor(.white)
                            .onChange(of: searchText) { newValue in
                                searchUsers(query: newValue)
                            }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Search results
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if isSearching {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .padding()
                            } else if friendsManager.searchResults.isEmpty && !searchText.isEmpty {
                                Text("No users found")
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding()
                            } else {
                                ForEach(friendsManager.searchResults) { user in
                                    SearchResultRowView(user: user) {
                                        await sendFriendRequest(to: user.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Add Friend")
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
        .preferredColorScheme(.dark)
    }
    
    private func searchUsers(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isSearching = true
        
        Task {
            await friendsManager.searchUsers(query: query)
            await MainActor.run {
                isSearching = false
            }
        }
    }
    
    private func sendFriendRequest(to userId: String) async {
        guard let currentUser = authManager.currentUser else { return }
        
        do {
            try await friendsManager.sendFriendRequest(to: userId, from: currentUser)
        } catch {
            friendsManager.errorMessage = error.localizedDescription
        }
    }
}

struct SearchResultRowView: View {
    let user: User
    let onAddFriend: () async -> Void
    @State private var isSending = false
    @State private var requestSent = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brown.opacity(0.7), Color.brown],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.username)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    // Pro badges removed - all users get badges now
                    if false { // Hide Pro badge for now
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.yellow)
                            .cornerRadius(3)
                    }
                }
                
                Text("Location Private")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Add friend button
            if requestSent {
                Text("Sent")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            } else if isSending {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button(action: {
                    Task {
                        isSending = true
                        await onAddFriend()
                        isSending = false
                        requestSent = true
                    }
                }) {
                    Text("Add")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

