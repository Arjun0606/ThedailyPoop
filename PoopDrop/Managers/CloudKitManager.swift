import Foundation
import CloudKit
import Combine

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
        let record = user.toCKRecord()
        _ = try await privateDatabase.save(record)
    }
    
    func fetchUser(id: String) async throws -> User? {
        let recordID = CKRecord.ID(recordName: id)
        let record = try await privateDatabase.record(for: recordID)
        return User(from: record)
    }
    
    func fetchAllUsers() async throws -> [User] {
        let query = CKQuery(recordType: User.recordType, predicate: NSPredicate(value: true))
        let (matchResults, _) = try await publicDatabase.records(matching: query)
        
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
    
    func searchUsers(displayName: String) async throws -> [User] {
        let predicate = NSPredicate(format: "displayName CONTAINS[c] %@", displayName)
        let query = CKQuery(recordType: User.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]
        
        let (matchResults, _) = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: 20)
        
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
        let query = CKQuery(recordType: Drop.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (matchResults, _) = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: limit)
        
        var drops: [Drop] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let drop = Drop(from: record) {
                    drops.append(drop)
                }
            case .failure(let error):
                print("Failed to fetch drop: \(error)")
            }
        }
        
        await MainActor.run {
            self.drops = drops
        }
        
        return drops
    }
    
    func fetchNearbyDrops(coordinate: CLLocationCoordinate2D, radius: Double = 1000) async throws -> [Drop] {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let predicate = NSPredicate(format: "distanceToLocation:fromLocation:(location, %@) < %f", location, radius)
        
        let query = CKQuery(recordType: Drop.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (matchResults, _) = try await publicDatabase.records(matching: query)
        
        var drops: [Drop] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let drop = Drop(from: record) {
                    drops.append(drop)
                }
            case .failure(let error):
                print("Failed to fetch nearby drop: \(error)")
            }
        }
        
        return drops
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
                    self.drops[index] = drop
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
        let predicate = NSPredicate(format: "creatorId == %@", user.id)
        let query = CKQuery(recordType: Drop.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        
        var drops: [Drop] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let drop = Drop(from: record) {
                    drops.append(drop)
                }
            case .failure(let error):
                print("Failed to fetch drop: \(error)")
            }
        }
        
        return drops
    }
    
    func fetchNearbyDrops(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Drop] {
        // For now, fetch all visible drops and filter by distance
        // In production, you'd use CloudKit's location-based queries
        let predicate = NSPredicate(format: "expiresAt > %@", Date() as NSDate)
        let query = CKQuery(recordType: Drop.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        
        var drops: [Drop] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let drop = Drop(from: record) {
                    // Filter by distance
                    if let dropCoord = drop.coordinate {
                        let dropLocation = CLLocation(latitude: dropCoord.latitude, longitude: dropCoord.longitude)
                        let centerLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        let distance = dropLocation.distance(from: centerLocation)
                        
                        if distance <= radius {
                            drops.append(drop)
                        }
                    }
                }
            case .failure(let error):
                print("Failed to fetch drop: \(error)")
            }
        }
        
        return drops
    }
}
