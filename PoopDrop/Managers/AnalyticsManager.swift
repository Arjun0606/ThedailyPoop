import Foundation
import CloudKit

/// Lightweight analytics manager for tracking key metrics
/// Stores events in CloudKit for later analysis
@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
    private var publicDatabase: CKDatabase
    
    // Session tracking
    @Published var sessionStartTime: Date?
    @Published var installSource: String? // "organic", "referral", "product_hunt"
    
    private init() {
        self.publicDatabase = container.publicCloudDatabase
    }
    
    // MARK: - Core Events
    
    /// Track app install/first launch
    func trackInstall(source: String = "organic", referrerID: String? = nil) {
        let event = AnalyticsEvent(
            type: .install,
            userID: getUserID(),
            properties: [
                "source": source,
                "referrer_id": referrerID ?? "none"
            ]
        )
        saveEvent(event)
        installSource = source
    }
    
    /// Track first purchase (critical conversion metric)
    func trackFirstPurchase(productID: String, price: Double) {
        let event = AnalyticsEvent(
            type: .firstPurchase,
            userID: getUserID(),
            properties: [
                "product_id": productID,
                "price": String(price),
                "time_to_purchase": String(timeSinceInstall())
            ]
        )
        saveEvent(event)
    }
    
    /// Track any purchase
    func trackPurchase(productID: String, price: Double, quantity: Int = 1) {
        let event = AnalyticsEvent(
            type: .purchase,
            userID: getUserID(),
            properties: [
                "product_id": productID,
                "price": String(price),
                "quantity": String(quantity)
            ]
        )
        saveEvent(event)
    }
    
    /// Track fart attack sent
    func trackAttackSent(to targetUserID: String) {
        let event = AnalyticsEvent(
            type: .attackSent,
            userID: getUserID(),
            properties: [
                "target_id": targetUserID
            ]
        )
        saveEvent(event)
    }
    
    /// Track notification permission granted
    func trackNotificationPermission(granted: Bool, context: String) {
        let event = AnalyticsEvent(
            type: .notificationPermission,
            userID: getUserID(),
            properties: [
                "granted": granted ? "true" : "false",
                "context": context // "first_attack", "3_day_streak", etc.
            ]
        )
        saveEvent(event)
    }
    
    /// Track daily retention (Day 1, Day 7, Day 30)
    func trackDailyOpen() {
        let installDate = getInstallDate()
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        
        // Only log milestone days
        if [1, 7, 30].contains(daysSinceInstall) {
            let event = AnalyticsEvent(
                type: .retention,
                userID: getUserID(),
                properties: [
                    "day": "D\(daysSinceInstall)",
                    "install_date": ISO8601DateFormatter().string(from: installDate)
                ]
            )
            saveEvent(event)
        }
    }
    
    /// Track session start
    func startSession() {
        sessionStartTime = Date()
        trackDailyOpen()
    }
    
    /// Track session end
    func endSession() {
        guard let start = sessionStartTime else { return }
        let duration = Date().timeIntervalSince(start)
        
        let event = AnalyticsEvent(
            type: .sessionEnd,
            userID: getUserID(),
            properties: [
                "duration_seconds": String(Int(duration))
            ]
        )
        saveEvent(event)
        sessionStartTime = nil
    }
    
    // MARK: - Helper Methods
    
    private func getUserID() -> String {
        // Use the current user's ID if available, otherwise generate a device ID
        if let userID = UserDefaults.standard.string(forKey: "currentUserID") {
            return userID
        }
        
        // Generate and save a device ID
        if let deviceID = UserDefaults.standard.string(forKey: "analyticsDeviceID") {
            return deviceID
        }
        
        let newDeviceID = UUID().uuidString
        UserDefaults.standard.set(newDeviceID, forKey: "analyticsDeviceID")
        return newDeviceID
    }
    
    private func getInstallDate() -> Date {
        if let installDate = UserDefaults.standard.object(forKey: "appInstallDate") as? Date {
            return installDate
        }
        
        // First launch - save install date
        let installDate = Date()
        UserDefaults.standard.set(installDate, forKey: "appInstallDate")
        return installDate
    }
    
    private func timeSinceInstall() -> TimeInterval {
        return Date().timeIntervalSince(getInstallDate())
    }
    
    private func saveEvent(_ event: AnalyticsEvent) {
        Task {
            do {
                let record = event.toCKRecord()
                _ = try await publicDatabase.save(record)
                print("📊 Analytics: \(event.type.rawValue)")
            } catch {
                print("⚠️ Failed to save analytics event: \(error)")
            }
        }
    }
}

// MARK: - Analytics Event Model

enum AnalyticsEventType: String {
    case install = "install"
    case firstPurchase = "first_purchase"
    case purchase = "purchase"
    case externalLinkClick = "external_link_click"
    case externalLinkOpen = "external_link_open"
    case attackSent = "attack_sent"
    case notificationPermission = "notification_permission"
    case retention = "retention"
    case sessionEnd = "session_end"
}

struct AnalyticsEvent {
    let id: String
    let type: AnalyticsEventType
    let userID: String
    let timestamp: Date
    let properties: [String: String]
    
    static let recordType = "AnalyticsEvent"
    
    init(
        id: String = UUID().uuidString,
        type: AnalyticsEventType,
        userID: String,
        timestamp: Date = Date(),
        properties: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.userID = userID
        self.timestamp = timestamp
        self.properties = properties
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["type"] = type.rawValue as CKRecordValue
        record["userID"] = userID as CKRecordValue
        record["timestamp"] = timestamp as CKRecordValue
        
        // Encode properties as JSON
        if let jsonData = try? JSONEncoder().encode(properties),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            record["properties"] = jsonString as CKRecordValue
        }
        
        return record
    }
}

