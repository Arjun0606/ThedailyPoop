import Foundation
import CloudKit
import UIKit

struct UserSession: Identifiable, Codable {
    let id: String
    let userID: String // Session owner
    let sessionStart: Date // When user opened app
    var sessionEnd: Date? // When user closed app
    var dropsViewed: Int // Engagement metric
    var adsViewed: Int // Revenue tracking
    var mapInteractions: Int // Feature usage
    let appVersion: String // Version tracking
    let deviceType: String // iOS device analytics
    
    init(id: String = UUID().uuidString,
         userID: String) {
        self.id = id
        self.userID = userID
        self.sessionStart = Date()
        self.sessionEnd = nil
        self.dropsViewed = 0
        self.adsViewed = 0
        self.mapInteractions = 0
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        self.deviceType = UIDevice.current.model
    }
    
    // Helper methods
    mutating func endSession() {
        sessionEnd = Date()
    }
    
    mutating func incrementDropsViewed() {
        dropsViewed += 1
    }
    
    mutating func incrementAdsViewed() {
        adsViewed += 1
    }
    
    mutating func incrementMapInteractions() {
        mapInteractions += 1
    }
    
    var sessionDuration: TimeInterval? {
        guard let end = sessionEnd else { return nil }
        return end.timeIntervalSince(sessionStart)
    }
    
    var isActive: Bool {
        return sessionEnd == nil
    }
}

// MARK: - CloudKit Extensions
extension UserSession {
    static let recordType = "UserSession"
    
    init?(from record: CKRecord) {
        guard let userID = record["userID"] as? String,
              let sessionStart = record["sessionStart"] as? Date,
              let appVersion = record["appVersion"] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.userID = userID
        self.sessionStart = sessionStart
        self.sessionEnd = record["sessionEnd"] as? Date
        self.dropsViewed = record["dropsViewed"] as? Int ?? 0
        self.adsViewed = record["adsViewed"] as? Int ?? 0
        self.mapInteractions = record["mapInteractions"] as? Int ?? 0
        self.appVersion = appVersion
        self.deviceType = record["deviceType"] as? String ?? "Unknown"
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: UserSession.recordType, recordID: CKRecord.ID(recordName: id))
        record["userID"] = userID
        record["sessionStart"] = sessionStart
        record["sessionEnd"] = sessionEnd
        record["dropsViewed"] = dropsViewed
        record["adsViewed"] = adsViewed
        record["mapInteractions"] = mapInteractions
        record["appVersion"] = appVersion
        record["deviceType"] = deviceType
        
        return record
    }
}

// MARK: - Sample Data
extension UserSession {
    static let sampleSession = UserSession(userID: "user123")
}
