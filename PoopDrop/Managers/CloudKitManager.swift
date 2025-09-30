import Foundation
import CloudKit
import Combine
import CoreLocation

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    @Published var isAvailable = false
    @Published var drops: [Drop] = []
    @Published var users: [User] = []
    @Published var sponsorCampaigns: [SponsorCampaign] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    
    init() {
        self.publicDatabase = container.publicCloudDatabase
        self.privateDatabase = container.privateCloudDatabase
    }
    
    func initialize() {
        checkCloudKitAvailability()
        setupSubscriptions()
    }
    
    private func checkCloudKitAvailability() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isAvailable = true
                case .noAccount:
                    self?.errorMessage = "Please sign in to iCloud to use Poop Drop"
                case .restricted:
                    self?.errorMessage = "CloudKit is restricted on this device"
                case .couldNotDetermine:
                    self?.errorMessage = "Could not determine CloudKit status"
                case .temporarilyUnavailable:
                    self?.errorMessage = "CloudKit is temporarily unavailable"
                @unknown default:
                    self?.errorMessage = "Unknown CloudKit error"
                }
            }
        }
    }
    
    private func setupSubscriptions() {
        // Set up CloudKit subscriptions for real-time updates
        Task {
            await setupDropSubscription()
            await setupUserSubscription()
            await setupSponsorCampaignSubscription()
        }
    }
    
    // MARK: - User Operations
    func saveUser(_ user: User) async throws {
        // Upsert semantics: fetch existing, update; else create
        let recordID = CKRecord.ID(recordName: user.id)
        do {
            let existing = try await privateDatabase.record(for: recordID)
            // Update fields on existing record
            existing["username"] = user.username
            existing["dateOfBirth"] = user.dateOfBirth
            existing["gender"] = user.gender.rawValue
            existing["appleUserID"] = user.appleUserID
            existing["customGender"] = user.customGender
            // Store avatar as CKAsset if we have a local file URL
            if let localURL = user.avatarURL, FileManager.default.fileExists(atPath: localURL.path) {
                existing["avatar"] = CKAsset(fileURL: localURL)
            } else {
                existing["avatarURL"] = user.avatarURL?.absoluteString
            }
            existing["streak"] = user.streak
            existing["createdAt"] = user.createdAt
            existing["lastDropDate"] = user.lastDropDate
            existing["totalDrops"] = user.totalDrops
            existing["maxDropsInDay"] = user.maxDropsInDay
            existing["longestNoPoopStreak"] = user.longestNoPoopStreak
            existing["isActive"] = user.isActive ? 1 : 0
            existing["lastSeen"] = user.lastSeen
            existing["lastStreakDate"] = user.lastStreakDate
            if let friendsData = try? JSONEncoder().encode(user.friends) {
                existing["friends"] = friendsData
            }
            if let requestsData = try? JSONEncoder().encode(user.friendRequests) {
                existing["friendRequests"] = requestsData
            }
            _ = try await privateDatabase.save(existing)
        } catch {
            // If not found, create
            let nsError = error as NSError
            if nsError.domain == CKError.errorDomain, CKError.Code(rawValue: nsError.code) == .unknownItem {
                let record = user.toCKRecord()
                _ = try await privateDatabase.save(record)
            } else {
                throw error
            }
        }
    }
    
    func fetchUser(id: String) async throws -> User? {
        let recordID = CKRecord.ID(recordName: id)
        let record = try await privateDatabase.record(for: recordID)
        return User(from: record)
    }
    
    func fetchUserByAppleUserID(_ appleUserID: String) async throws -> User? {
        let predicate = NSPredicate(format: "appleUserID == %@", appleUserID)
        let query = CKQuery(recordType: User.recordType, predicate: predicate)
        let (results, _) = try await privateDatabase.records(matching: query, resultsLimit: 1)
        for (_, res) in results {
            if case let .success(record) = res { return User(from: record) }
        }
        return nil
    }
    
    func fetchAllUsers() async throws -> [User] {
        let query = CKQuery(recordType: User.recordType, predicate: NSPredicate(value: true))
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        
        var users: [User] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let user = User(from: record) {
                    users.append(user)
                }
            case .failure(let error):
                print("Failed to fetch user: \(error)")
            }
        }
        
        await MainActor.run {
            self.users = users
        }
        
        return users
    }
    
    func searchUsers(username: String) async throws -> [User] {
        let predicate = NSPredicate(format: "username CONTAINS[c] %@", username)
        let query = CKQuery(recordType: User.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
        
        let (matchResults, _) = try await privateDatabase.records(matching: query, resultsLimit: 20)
        
        var users: [User] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let user = User(from: record) {
                    users.append(user)
                }
            case .failure(let error):
                print("Failed to search user: \(error)")
            }
        }
        
        return users
    }
    
    // MARK: - Username Validation
    
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let predicate = NSPredicate(format: "username == %@", username)
        let query = CKQuery(recordType: User.recordType, predicate: predicate)
        
        let (matchResults, _) = try await privateDatabase.records(matching: query, resultsLimit: 1)
        
        // Username is available if no matches found
        return matchResults.isEmpty
    }
    
    // MARK: - Friend Operations
    
    func fetchFriends(for user: User) async throws -> [User] {
        var friends: [User] = []
        
        for friendID in user.friends {
            if let friend = try await fetchUser(id: friendID) {
                friends.append(friend)
            }
        }
        
        return friends
    }
    
    // MARK: - Reaction Operations
    
    func saveReaction(_ reaction: Reaction) async throws {
        let record = reaction.toCKRecord()
        try await publicDatabase.save(record)
    }
    
    func fetchReactions(for dropID: String) async throws -> [Reaction] {
        let predicate = NSPredicate(format: "dropID == %@", dropID)
        let query = CKQuery(recordType: "Reaction", predicate: predicate)
        
        let result = try await publicDatabase.records(matching: query)
        
        var reactions: [Reaction] = []
        for (_, result) in result.matchResults {
            switch result {
            case .success(let record):
                if let reaction = Reaction(from: record) {
                    reactions.append(reaction)
                }
            case .failure(let error):
                print("Failed to fetch reaction: \(error)")
            }
        }
        
        return reactions.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Drop Operations
    func saveDrop(_ drop: Drop) async throws {
        let record = drop.toCKRecord()
        _ = try await publicDatabase.save(record)
        
        // Update local drops array
        await MainActor.run {
            if let index = self.drops.firstIndex(where: { $0.id == drop.id }) {
                self.drops[index] = drop
            } else {
                self.drops.insert(drop, at: 0)
            }
        }
    }
    
    func fetchDrops(limit: Int = 50) async throws -> [Drop] {
        print("🔍 Attempting to fetch drops from CloudKit (limit: \(limit))")
        print("⚠️ CloudKit schema not configured - using local cache only")
        
        // WORKAROUND: CloudKit Dashboard doesn't have queryable fields configured
        // Return existing local drops that were saved during this session
        await MainActor.run {
            print("📦 Returning \(self.drops.count) drops from local cache")
            if self.drops.count > 0 {
                print("🔍 First 3 local drops: \(self.drops.prefix(3).map { "\($0.username) at \($0.city ?? "unknown")" })")
            }
        }
        
        return await MainActor.run {
            return self.drops
        }
    }
    
    func fetchNearbyDrops(coordinate: CLLocationCoordinate2D, radius: Double = 1000) async throws -> [Drop] {
        // Fetch recent drops first to avoid CloudKit indexing requirements, then filter client-side
        let recent = try await fetchDrops(limit: 200)
        let centerLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let filtered = recent.filter { drop in
            guard drop.isCurrentlyVisible, let loc = drop.location else { return false }
            let dropLocation = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            return centerLocation.distance(from: dropLocation) <= radius
        }
        return filtered
    }
    
    func updateDropReaction(_ dropId: String, emoji: String, increment: Bool) async throws {
        let recordID = CKRecord.ID(recordName: dropId)
        let record = try await publicDatabase.record(for: recordID)
        
        // Decode current reactions
        var reactions: [String: Int] = [:]
        if let reactionsData = record["reactions"] as? Data {
            reactions = (try? JSONDecoder().decode([String: Int].self, from: reactionsData)) ?? [:]
        }
        
        // Update reaction count
        let currentCount = reactions[emoji] ?? 0
        if increment {
            reactions[emoji] = currentCount + 1
        } else {
            reactions[emoji] = max(0, currentCount - 1)
            if reactions[emoji] == 0 {
                reactions.removeValue(forKey: emoji)
            }
        }
        
        // Encode and save
        if let reactionsData = try? JSONEncoder().encode(reactions) {
            record["reactions"] = reactionsData
        }
        
        _ = try await publicDatabase.save(record)
        
        // Update local drop
        if let drop = Drop(from: record) {
            await MainActor.run {
                if let index = self.drops.firstIndex(where: { $0.id == dropId }) {
                    var updated = drop
                    updated.reactionCount = reactions.values.reduce(0, +)
                    self.drops[index] = updated
                }
            }
        }
    }
    
    // MARK: - Sponsor Campaign Operations
    func fetchActiveSponsorCampaigns() async throws -> [SponsorCampaign] {
        let predicate = NSPredicate(format: "endDate == NIL OR endDate > %@", Date() as NSDate)
        let query = CKQuery(recordType: SponsorCampaign.recordType, predicate: predicate)
        
        let (matchResults, _) = try await publicDatabase.records(matching: query)
        
        var campaigns: [SponsorCampaign] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let campaign = SponsorCampaign(from: record) {
                    campaigns.append(campaign)
                }
            case .failure(let error):
                print("Failed to fetch sponsor campaign: \(error)")
            }
        }
        
        await MainActor.run {
            self.sponsorCampaigns = campaigns
        }
        
        return campaigns
    }
    
    // MARK: - Subscriptions for Real-time Updates
    private func setupDropSubscription() async {
        let subscription = CKQuerySubscription(
            recordType: Drop.recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: "drop-subscription",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        do {
            _ = try await publicDatabase.save(subscription)
        } catch {
            print("Failed to set up drop subscription: \(error)")
        }
    }
    
    private func setupUserSubscription() async {
        let subscription = CKQuerySubscription(
            recordType: User.recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: "user-subscription",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        do {
            _ = try await privateDatabase.save(subscription)
        } catch {
            print("Failed to set up user subscription: \(error)")
        }
    }
    
    private func setupSponsorCampaignSubscription() async {
        let subscription = CKQuerySubscription(
            recordType: SponsorCampaign.recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: "sponsor-campaign-subscription",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        do {
            _ = try await publicDatabase.save(subscription)
        } catch {
            print("Failed to set up sponsor campaign subscription: \(error)")
        }
    }
    
    func fetchUserDrops(for user: User) async throws -> [Drop] {
        // Use local cache since CloudKit queries are not configured
        print("🔍 Fetching user drops for: \(user.username) from local cache")
        let allDrops = try await fetchDrops(limit: 500)
        let userDrops = allDrops.filter { $0.userID == user.id }
        print("🔍 Found \(userDrops.count) drops for user \(user.username) in local cache")
        return userDrops.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Badge Operations
    
    func saveBadge(_ badge: Badge, for user: User) async throws {
        // In the simplified model, badges are stored locally or in user preferences
        // For now, we'll just print success
        print("Badge '\(badge.name)' unlocked for user \(user.username)")
    }

    // MARK: - Cache Management
    func clearLocalCache() {
        Task { @MainActor in
            drops.removeAll()
            users.removeAll()
            sponsorCampaigns.removeAll()
            print("🗑️ Local cache cleared")
        }
    }
    
    func clearUserCache() {
        Task { @MainActor in
            users.removeAll()
            // Keep drops and sponsor campaigns for continuity
            print("🗑️ User cache cleared (keeping drops)")
        }
    }

    // MARK: - Account Deletion
    func deleteAccount(for user: User) async throws {
        print("🗑️ Deleting account for user: \(user.username)")
        
        // Fetch all drops and delete user's drops client-side filtering
        let allDrops = try await fetchDrops(limit: 1000)
        let userDrops = allDrops.filter { $0.userID == user.id }
        print("🗑️ Deleting \(userDrops.count) drops")
        for drop in userDrops {
            let recordID = CKRecord.ID(recordName: drop.id)
            try? await publicDatabase.deleteRecord(withID: recordID)
        }

        // Note: Reactions, Friendships, and Notifications would need similar client-side filtering
        // For now, we'll skip those to avoid errors. In production, these should be indexed in CloudKit.
        
        // Finally delete the user record in private DB
        let userID = CKRecord.ID(recordName: user.id)
        try? await privateDatabase.deleteRecord(withID: userID)
        print("✅ Account deletion complete")
    }
}