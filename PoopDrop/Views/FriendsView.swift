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
                        FriendsListView(friends: friendsManager.friends)
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
                    NavigationLink(destination: FriendLeaderboardView()) {
                        HStack(spacing: 4) {
                            Text("🏆")
                            Text("Leaderboard")
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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if friends.isEmpty {
                    EmptyFriendsView()
                } else {
                    ForEach(friends) { friend in
                        FriendRowView(friend: friend)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
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
                    
                    Text("Share Plopper with your friends!")
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
            
            // Friend status indicator
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
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

// MARK: - Invite Friends View
struct InviteFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var copied = false
    
    var inviteLink: String {
        "https://poopdrop.app/invite?ref=\(authManager.currentUser?.id ?? "app")"
    }
    
    var inviteMessage: String {
        """
        Hey! Join me on Plopper 💩
        
        Track your bathroom breaks, compete with friends, and unlock badges around the world!
        
        Download now: \(inviteLink)
        """
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Icon
                    Text("💩")
                        .font(.system(size: 80))
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Invite Your Friends!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Share Plopper and compete with friends!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Stats
                    VStack(spacing: 12) {
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("0")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Invited")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 1, height: 40)
                            
                            VStack(spacing: 4) {
                                Text("0")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Joined")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            shareInvite()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Invite Link")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            copyToClipboard()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copied!" : "Copy Link")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 32)
            }
            .navigationTitle("Invite Friends")
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
    
    private func shareInvite() {
        let activityVC = UIActivityViewController(
            activityItems: [inviteMessage],
            applicationActivities: nil
        )
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = root.view
            root.present(activityVC, animated: true)
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = inviteLink
        copied = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

#Preview {
    FriendsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(CloudKitManager())
}
