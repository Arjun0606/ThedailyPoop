import Foundation
import CloudKit
import Combine

@MainActor
class FriendsManager: ObservableObject {
    @Published var friends: [User] = []
    @Published var friendRequests: [User] = []
    @Published var searchResults: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let cloudKitManager: CloudKitManager
    private var cancellables = Set<AnyCancellable>()
    
    init(cloudKitManager: CloudKitManager = CloudKitManager.shared) {
        self.cloudKitManager = cloudKitManager
    }
    
    // MARK: - Friend Management
    
    func loadFriends(for user: User) async {
        isLoading = true
        
        do {
            var friendUsers: [User] = []
            
            // Fetch each friend's user data
            for friendId in user.friends {
                if let friend = try await cloudKitManager.fetchUser(id: friendId) {
                    friendUsers.append(friend)
                }
            }
            
            await MainActor.run {
                self.friends = friendUsers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load friends: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func loadFriendRequests(for user: User) async {
        isLoading = true
        
        do {
            var requestUsers: [User] = []
            
            // Fetch each friend request user's data
            for requestId in user.friendRequests {
                if let requestUser = try await cloudKitManager.fetchUser(id: requestId) {
                    requestUsers.append(requestUser)
                }
            }
            
            await MainActor.run {
                self.friendRequests = requestUsers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load friend requests: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func searchUsers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                self.searchResults = []
            }
            return
        }
        
        isLoading = true
        
        do {
            let users = try await cloudKitManager.searchUsers(displayName: query)
            
            await MainActor.run {
                self.searchResults = users
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to search users: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func sendFriendRequest(to userId: String, from currentUser: User) async throws {
        // Add friend request to target user
        guard var targetUser = try await cloudKitManager.fetchUser(id: userId) else {
            throw FriendsError.userNotFound
        }
        
        // Check if already friends or request already sent
        if targetUser.friends.contains(currentUser.id) {
            throw FriendsError.alreadyFriends
        }
        
        if targetUser.friendRequests.contains(currentUser.id) {
            throw FriendsError.requestAlreadySent
        }
        
        // Add friend request
        targetUser.friendRequests.append(currentUser.id)
        try await cloudKitManager.saveUser(targetUser)
        
        // Send push notification to target user
        await NotificationManager.shared.sendFriendRequestNotification(
            to: targetUser,
            from: currentUser
        )
    }
    
    func acceptFriendRequest(from userId: String, currentUser: inout User) async throws {
        guard let requestUser = try await cloudKitManager.fetchUser(id: userId) else {
            throw FriendsError.userNotFound
        }
        
        // Remove from friend requests
        currentUser.friendRequests.removeAll { $0 == userId }
        
        // Add to friends list
        currentUser.friends.append(userId)
        
        // Add current user to requester's friends list
        var updatedRequestUser = requestUser
        updatedRequestUser.friends.append(currentUser.id)
        
        // Save both users
        try await cloudKitManager.saveUser(currentUser)
        try await cloudKitManager.saveUser(updatedRequestUser)
        
        // Send acceptance notification
        await NotificationManager.shared.sendFriendAcceptedNotification(
            to: updatedRequestUser,
            from: currentUser
        )
        
        // Reload friends list
        await loadFriends(for: currentUser)
    }
    
    func rejectFriendRequest(from userId: String, currentUser: inout User) async throws {
        // Simply remove from friend requests
        currentUser.friendRequests.removeAll { $0 == userId }
        try await cloudKitManager.saveUser(currentUser)
        
        // Reload friend requests
        await loadFriendRequests(for: currentUser)
    }
    
    func removeFriend(userId: String, currentUser: inout User) async throws {
        guard var friend = try await cloudKitManager.fetchUser(id: userId) else {
            throw FriendsError.userNotFound
        }
        
        // Remove from both users' friends lists
        currentUser.friends.removeAll { $0 == userId }
        friend.friends.removeAll { $0 == currentUser.id }
        
        // Save both users
        try await cloudKitManager.saveUser(currentUser)
        try await cloudKitManager.saveUser(friend)
        
        // Reload friends list
        await loadFriends(for: currentUser)
    }
    
    // MARK: - Friends Feed
    
    func getFriendDrops(for user: User) async throws -> [Drop] {
        // Get drops only from friends
        let allDrops = try await cloudKitManager.fetchDrops(limit: 100)
        
        // Filter to only show drops from friends
        let friendDrops = allDrops.filter { drop in
            user.friends.contains(drop.creatorId) || drop.creatorId == user.id
        }
        
        return friendDrops.sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Notification Manager
class NotificationManager {
    static let shared = NotificationManager()
    
    func sendFriendRequestNotification(to user: User, from sender: User) async {
        // Implementation for push notifications
        print("📱 Sending friend request notification to \(user.displayName) from \(sender.displayName)")
    }
    
    func sendFriendAcceptedNotification(to user: User, from accepter: User) async {
        print("📱 Sending friend accepted notification to \(user.displayName) from \(accepter.displayName)")
    }
    
    func sendPoopDropNotification(to friends: [User], from dropper: User, drop: Drop) async {
        let message = drop.isNoPoop 
            ? "\(dropper.displayName) had no poop today 😵‍💫"
            : "\(dropper.displayName) just dropped a poop! 💩"
        
        print("📱 Sending poop notification to \(friends.count) friends: \(message)")
    }
}

// MARK: - Friends Errors
enum FriendsError: LocalizedError {
    case userNotFound
    case alreadyFriends
    case requestAlreadySent
    case cannotAddSelf
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .alreadyFriends:
            return "You are already friends with this user"
        case .requestAlreadySent:
            return "Friend request already sent"
        case .cannotAddSelf:
            return "You cannot add yourself as a friend"
        }
    }
}
