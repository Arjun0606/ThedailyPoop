import Foundation
import CloudKit

struct FartSound: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let fileName: String
    let duration: Double // in seconds
    let description: String
    
    init(id: String = UUID().uuidString, name: String, fileName: String, duration: Double, description: String) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.duration = duration
        self.description = description
    }
}

struct FartPack: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let productID: String
    let price: Double
    let sounds: [FartSound]
    let isDefault: Bool // If true, available to everyone
    
    init(id: String = UUID().uuidString, 
         name: String, 
         description: String,
         emoji: String,
         productID: String,
         price: Double = 1.99,
         sounds: [FartSound],
         isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.emoji = emoji
        self.productID = productID
        self.price = price
        self.sounds = sounds
        self.isDefault = isDefault
    }
}

// MARK: - Predefined Fart Packs
extension FartPack {
    static let epicBlastPack = FartPack(
        name: "Epic Blast",
        description: "Professional studio quality fart sound - Legendary and unforgettable!",
        emoji: "⭐",
        productID: "com.thedailypoop.fartpack.premium",
        price: 1.99,
        sounds: [
            FartSound(
                name: "The Epic Blast",
                fileName: "fart_long_epidemic",
                duration: 4.0,
                description: "4 seconds of professional studio quality from Epidemic Sound"
            )
        ],
        isDefault: false
    )
    
    // All available packs
    static let allPacks: [FartPack] = [
        epicBlastPack
    ]
    
    // Only purchasable packs (excluding default)
    static let purchasablePacks: [FartPack] = allPacks.filter { !$0.isDefault }
}

// MARK: - User Purchase Tracking
struct UserFartPackPurchases: Codable {
    let userID: String
    var purchasedPackIDs: Set<String>
    var lastUpdated: Date
    
    init(userID: String, purchasedPackIDs: Set<String> = [], lastUpdated: Date = Date()) {
        self.userID = userID
        self.purchasedPackIDs = purchasedPackIDs
        self.lastUpdated = lastUpdated
    }
    
    mutating func addPurchase(packID: String) {
        purchasedPackIDs.insert(packID)
        lastUpdated = Date()
    }
    
    func hasPurchased(_ pack: FartPack) -> Bool {
        return pack.isDefault || purchasedPackIDs.contains(pack.id)
    }
}

// MARK: - CloudKit Extensions
extension UserFartPackPurchases {
    static let recordType = "UserFartPackPurchases"
    
    init?(from record: CKRecord) {
        guard let userID = record["userID"] as? String else { return nil }
        
        self.userID = userID
        
        // Decode purchased pack IDs
        if let purchasedData = record["purchasedPackIDs"] as? Data {
            self.purchasedPackIDs = (try? JSONDecoder().decode(Set<String>.self, from: purchasedData)) ?? []
        } else {
            self.purchasedPackIDs = []
        }
        
        self.lastUpdated = record["lastUpdated"] as? Date ?? Date()
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: UserFartPackPurchases.recordType, recordID: CKRecord.ID(recordName: userID))
        record["userID"] = userID
        
        // Encode purchased pack IDs
        if let purchasedData = try? JSONEncoder().encode(purchasedPackIDs) {
            record["purchasedPackIDs"] = purchasedData
        }
        
        record["lastUpdated"] = lastUpdated
        
        return record
    }
}

