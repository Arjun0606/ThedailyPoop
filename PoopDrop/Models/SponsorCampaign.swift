import Foundation
import CloudKit

struct SponsorCampaign: Identifiable, Codable {
    let id: String
    let brandName: String
    let assetName: String? // Custom emoji or image asset
    let startDate: Date
    let endDate: Date?
    let actionType: String // "coupon", "challenge", "badge", "reaction"
    let actionPayload: [String: String] // Flexible data for different action types
    let targetAudience: String? // "all", "pro", "city:SF", etc.
    let isActive: Bool
    
    init(id: String = UUID().uuidString,
         brandName: String,
         assetName: String? = nil,
         startDate: Date = Date(),
         endDate: Date? = nil,
         actionType: String,
         actionPayload: [String: String] = [:],
         targetAudience: String? = nil) {
        self.id = id
        self.brandName = brandName
        self.assetName = assetName
        self.startDate = startDate
        self.endDate = endDate
        self.actionType = actionType
        self.actionPayload = actionPayload
        self.targetAudience = targetAudience
        self.isActive = endDate.map { Date() < $0 } ?? true
    }
}

// MARK: - Campaign Types
extension SponsorCampaign {
    enum ActionType {
        static let coupon = "coupon"
        static let challenge = "challenge"
        static let badge = "badge"
        static let reaction = "reaction"
        static let sponsoredDrop = "sponsored_drop"
    }
    
    var isCouponCampaign: Bool { actionType == ActionType.coupon }
    var isChallengeCampaign: Bool { actionType == ActionType.challenge }
    var isBadgeCampaign: Bool { actionType == ActionType.badge }
    var isReactionCampaign: Bool { actionType == ActionType.reaction }
    var isSponsoredDropCampaign: Bool { actionType == ActionType.sponsoredDrop }
}

// MARK: - CloudKit Extensions
extension SponsorCampaign {
    static let recordType = "SponsorCampaign"
    
    init?(from record: CKRecord) {
        guard let brandName = record["brandName"] as? String,
              let actionType = record["actionType"] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.brandName = brandName
        self.assetName = record["assetName"] as? String
        self.startDate = record["startDate"] as? Date ?? Date()
        self.endDate = record["endDate"] as? Date
        self.actionType = actionType
        self.targetAudience = record["targetAudience"] as? String
        
        // Decode action payload from CloudKit
        if let payloadData = record["actionPayload"] as? Data {
            self.actionPayload = (try? JSONDecoder().decode([String: String].self, from: payloadData)) ?? [:]
        } else {
            self.actionPayload = [:]
        }
        
        self.isActive = endDate.map { Date() < $0 } ?? true
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: SponsorCampaign.recordType, recordID: CKRecord.ID(recordName: id))
        record["brandName"] = brandName
        record["assetName"] = assetName
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["actionType"] = actionType
        record["targetAudience"] = targetAudience
        
        // Encode action payload for CloudKit
        if let payloadData = try? JSONEncoder().encode(actionPayload) {
            record["actionPayload"] = payloadData
        }
        
        return record
    }
}

// MARK: - Sample Data
extension SponsorCampaign {
    static let tacoBellCampaign = SponsorCampaign(
        brandName: "Taco Bell",
        assetName: "🌮💩",
        actionType: ActionType.sponsoredDrop,
        actionPayload: [
            "emoji": "🌮💩",
            "discount": "20% off next order",
            "code": "POOP20"
        ]
    )
    
    static let starbucksCampaign = SponsorCampaign(
        brandName: "Starbucks",
        assetName: "🎃💩",
        endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
        actionType: ActionType.challenge,
        actionPayload: [
            "challenge": "Drop 5 Pumpkin Spice Poops",
            "reward": "Free PSL",
            "emoji": "🎃💩"
        ]
    )
    
    static let hotCheetosCampaign = SponsorCampaign(
        brandName: "Hot Cheetos",
        assetName: "🔥💩",
        actionType: ActionType.reaction,
        actionPayload: [
            "reaction": "🔥💩",
            "message": "by Hot Cheetos"
        ]
    )
}
