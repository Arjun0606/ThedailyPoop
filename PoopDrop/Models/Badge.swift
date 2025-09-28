import Foundation
import CoreLocation
import CloudKit

struct Badge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let iconName: String // Asset name from IconScout
    let category: BadgeCategory
    let requirement: BadgeRequirement
    let isUnlocked: Bool
    let unlockedAt: Date?
    let locationData: LocationData? // For geo-locked badges
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         iconName: String,
         category: BadgeCategory,
         requirement: BadgeRequirement,
         isUnlocked: Bool = false,
         unlockedAt: Date? = nil,
         locationData: LocationData? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.locationData = locationData
    }
}

enum BadgeCategory: String, CaseIterable, Codable {
    case travel = "Travel"
    case streak = "Streak"
    case social = "Social"
    case frequency = "Frequency"
    case special = "Special"
    
    var emoji: String {
        switch self {
        case .travel: return "✈️"
        case .streak: return "🔥"
        case .social: return "👥"
        case .frequency: return "💩"
        case .special: return "⭐"
        }
    }
}

struct BadgeRequirement: Codable {
    let type: RequirementType
    let value: Int
    let geoLocked: Bool
    
    enum RequirementType: String, Codable {
        case citiesVisited = "cities_visited"
        case countriesVisited = "countries_visited"
        case streakDays = "streak_days"
        case totalDrops = "total_drops"
        case friendsCount = "friends_count"
        case dropsInOneDay = "drops_in_one_day"
        case uniqueLocations = "unique_locations"
    }
}

struct LocationData: Codable {
    let city: String?
    let country: String?
    let coordinate: CLLocationCoordinate2D
    let verifiedAt: Date
}

// MARK: - CloudKit Extensions
extension Badge {
    static let recordType = "Badge"
    
    init?(from record: CKRecord) {
        guard let name = record["name"] as? String,
              let description = record["description"] as? String,
              let iconName = record["iconName"] as? String,
              let categoryRaw = record["category"] as? String,
              let category = BadgeCategory(rawValue: categoryRaw) else { return nil }
        
        self.id = record.recordID.recordName
        self.name = name
        self.description = description
        self.iconName = iconName
        self.category = category
        self.isUnlocked = record["isUnlocked"] as? Bool ?? false
        self.unlockedAt = record["unlockedAt"] as? Date
        
        // Decode requirement
        if let requirementData = record["requirement"] as? Data {
            self.requirement = (try? JSONDecoder().decode(BadgeRequirement.self, from: requirementData)) ?? BadgeRequirement(type: .totalDrops, value: 1, geoLocked: false)
        } else {
            self.requirement = BadgeRequirement(type: .totalDrops, value: 1, geoLocked: false)
        }
        
        // Decode location data
        if let locationData = record["locationData"] as? Data {
            self.locationData = try? JSONDecoder().decode(LocationData.self, from: locationData)
        } else {
            self.locationData = nil
        }
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Badge.recordType, recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["description"] = description
        record["iconName"] = iconName
        record["category"] = category.rawValue
        record["isUnlocked"] = isUnlocked
        record["unlockedAt"] = unlockedAt
        
        // Encode requirement
        if let requirementData = try? JSONEncoder().encode(requirement) {
            record["requirement"] = requirementData
        }
        
        // Encode location data
        if let locationData = locationData,
           let locationDataEncoded = try? JSONEncoder().encode(locationData) {
            record["locationData"] = locationDataEncoded
        }
        
        return record
    }
}

// MARK: - Badge Manager
@MainActor
class BadgeManager: ObservableObject {
    @Published var userBadges: [Badge] = []
    @Published var availableBadges: [Badge] = []
    @Published var recentlyUnlocked: Badge?
    
    private let cloudKitManager: CloudKitManager
    
    init(cloudKitManager: CloudKitManager = CloudKitManager.shared) {
        self.cloudKitManager = cloudKitManager
        setupDefaultBadges()
    }
    
    private func setupDefaultBadges() {
        availableBadges = [
            // Travel Badges (Pro Only)
            Badge(
                name: "City Hopper",
                description: "Pooped in 5 different cities",
                iconName: "city_badge", // IconScout asset
                category: .travel,
                requirement: BadgeRequirement(type: .citiesVisited, value: 5, geoLocked: true)
            ),
            Badge(
                name: "Globe Trotter",
                description: "Pooped in 3 different countries",
                iconName: "globe_badge",
                category: .travel,
                requirement: BadgeRequirement(type: .countriesVisited, value: 3, geoLocked: true)
            ),
            Badge(
                name: "World Pooper",
                description: "Pooped in 10 different countries",
                iconName: "world_badge",
                category: .travel,
                requirement: BadgeRequirement(type: .countriesVisited, value: 10, geoLocked: true)
            ),
            
            // Streak Badges
            Badge(
                name: "Week Warrior",
                description: "7-day poop streak",
                iconName: "week_streak_badge",
                category: .streak,
                requirement: BadgeRequirement(type: .streakDays, value: 7, geoLocked: false)
            ),
            Badge(
                name: "Month Master",
                description: "30-day poop streak",
                iconName: "month_streak_badge",
                category: .streak,
                requirement: BadgeRequirement(type: .streakDays, value: 30, geoLocked: false)
            ),
            Badge(
                name: "Streak Legend",
                description: "100-day poop streak",
                iconName: "legend_streak_badge",
                category: .streak,
                requirement: BadgeRequirement(type: .streakDays, value: 100, geoLocked: false)
            ),
            
            // Social Badges (Pro Only)
            Badge(
                name: "Social Butterfly",
                description: "Have 10 poop buddies",
                iconName: "social_badge",
                category: .social,
                requirement: BadgeRequirement(type: .friendsCount, value: 10, geoLocked: false)
            ),
            Badge(
                name: "Poop Network",
                description: "Have 50 poop buddies",
                iconName: "network_badge",
                category: .social,
                requirement: BadgeRequirement(type: .friendsCount, value: 50, geoLocked: false)
            ),
            
            // Frequency Badges
            Badge(
                name: "Centurion",
                description: "100 total poops",
                iconName: "centurion_badge",
                category: .frequency,
                requirement: BadgeRequirement(type: .totalDrops, value: 100, geoLocked: false)
            ),
            Badge(
                name: "Poop Machine",
                description: "5 poops in one day",
                iconName: "machine_badge",
                category: .frequency,
                requirement: BadgeRequirement(type: .dropsInOneDay, value: 5, geoLocked: false)
            ),
            
            // Special Badges (Pro Only)
            Badge(
                name: "Explorer",
                description: "Pooped in 25 unique locations",
                iconName: "explorer_badge",
                category: .special,
                requirement: BadgeRequirement(type: .uniqueLocations, value: 25, geoLocked: true)
            )
        ]
    }
    
    func checkBadgeEligibility(for user: User, drops: [Drop]) async {
        guard user.isPro else { return } // Only Pro users get badges
        
        for badge in availableBadges {
            if !userBadges.contains(where: { $0.id == badge.id }) {
                if await shouldUnlockBadge(badge, for: user, drops: drops) {
                    await unlockBadge(badge, for: user)
                }
            }
        }
    }
    
    private func shouldUnlockBadge(_ badge: Badge, for user: User, drops: [Drop]) async -> Bool {
        switch badge.requirement.type {
        case .citiesVisited:
            let cities = Set(drops.compactMap { drop in
                // This would need reverse geocoding in real implementation
                return drop.coordinate != nil ? "City_\(Int(drop.coordinate!.latitude))" : nil
            })
            return cities.count >= badge.requirement.value
            
        case .countriesVisited:
            let countries = Set(drops.compactMap { drop in
                // This would need reverse geocoding in real implementation
                return drop.coordinate != nil ? "Country_\(Int(drop.coordinate!.latitude / 10))" : nil
            })
            return countries.count >= badge.requirement.value
            
        case .streakDays:
            return user.streak >= badge.requirement.value
            
        case .totalDrops:
            return user.totalDrops >= badge.requirement.value
            
        case .friendsCount:
            return user.friends.count >= badge.requirement.value
            
        case .dropsInOneDay:
            let today = Calendar.current.startOfDay(for: Date())
            let todayDrops = drops.filter { 
                Calendar.current.isDate($0.createdAt, inSameDayAs: today)
            }
            return todayDrops.count >= badge.requirement.value
            
        case .uniqueLocations:
            let uniqueLocations = Set(drops.compactMap { drop in
                guard let coord = drop.coordinate else { return nil }
                // Round to ~100m precision
                return "\(Int(coord.latitude * 1000))_\(Int(coord.longitude * 1000))"
            })
            return uniqueLocations.count >= badge.requirement.value
        }
    }
    
    private func unlockBadge(_ badge: Badge, for user: User) async {
        var unlockedBadge = badge
        unlockedBadge = Badge(
            id: badge.id,
            name: badge.name,
            description: badge.description,
            iconName: badge.iconName,
            category: badge.category,
            requirement: badge.requirement,
            isUnlocked: true,
            unlockedAt: Date(),
            locationData: badge.locationData
        )
        
        userBadges.append(unlockedBadge)
        recentlyUnlocked = unlockedBadge
        
        // Save to CloudKit
        do {
            try await cloudKitManager.saveBadge(unlockedBadge, for: user)
        } catch {
            print("Failed to save badge: \(error)")
        }
        
        // Show celebration
        await showBadgeUnlockedCelebration(unlockedBadge)
    }
    
    private func showBadgeUnlockedCelebration(_ badge: Badge) async {
        // This would trigger a celebration animation
        print("🎉 Badge Unlocked: \(badge.name)!")
        
        // Send notification
        await NotificationManager.shared.sendBadgeUnlockedNotification(badge)
    }
}

// MARK: - CloudKit Extensions for BadgeManager
extension CloudKitManager {
    func saveBadge(_ badge: Badge, for user: User) async throws {
        let record = badge.toCKRecord()
        record["userId"] = user.id
        _ = try await privateDatabase.save(record)
    }
    
    func fetchUserBadges(for user: User) async throws -> [Badge] {
        let predicate = NSPredicate(format: "userId == %@", user.id)
        let query = CKQuery(recordType: Badge.recordType, predicate: predicate)
        
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        
        var badges: [Badge] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let badge = Badge(from: record) {
                    badges.append(badge)
                }
            case .failure(let error):
                print("Failed to fetch badge: \(error)")
            }
        }
        
        return badges
    }
}

// MARK: - Notification Extension
extension NotificationManager {
    func sendBadgeUnlockedNotification(_ badge: Badge) async {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Badge Unlocked!"
        content.body = "\(badge.name): \(badge.description)"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("badge_unlock.wav"))
        
        let request = UNNotificationRequest(
            identifier: "badge_unlock_\(badge.id)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
}
