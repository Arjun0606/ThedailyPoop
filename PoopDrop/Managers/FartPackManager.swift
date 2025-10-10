import Foundation
import AVFoundation
import CloudKit

@MainActor
class FartPackManager: ObservableObject {
    static let shared = FartPackManager()
    
    @Published var purchasedPacks: Set<String> = []
    @Published var selectedSound: FartSound?
    @Published var isLoading = false
    
    private var audioPlayer: AVAudioPlayer?
    private let cloudKitManager = CloudKitManager.shared
    
    private init() {
        // Load purchased packs from local storage on init
        loadPurchasedPacks()
        
        Task {
            await fetchPurchasedPacksFromCloudKit()
        }
    }
    
    // MARK: - Available Packs
    var allPacks: [FartPack] {
        return FartPack.allPacks
    }
    
    var unlockedPacks: [FartPack] {
        return allPacks.filter { pack in
            pack.isDefault || purchasedPacks.contains(pack.id)
        }
    }
    
    var lockedPacks: [FartPack] {
        return allPacks.filter { pack in
            !pack.isDefault && !purchasedPacks.contains(pack.id)
        }
    }
    
    // MARK: - Check Pack Status
    func isPackUnlocked(_ pack: FartPack) -> Bool {
        return pack.isDefault || purchasedPacks.contains(pack.id)
    }
    
    func isPackUnlocked(packID: String) -> Bool {
        if let pack = allPacks.first(where: { $0.id == packID }) {
            return isPackUnlocked(pack)
        }
        return false
    }
    
    // MARK: - Unlock Pack
    func unlockPack(packID: String) async {
        // Add to purchased packs
        purchasedPacks.insert(packID)
        
        // Save locally
        savePurchasedPacks()
        
        // Save to CloudKit
        await savePurchasedPacksToCloudKit()
    }
    
    // MARK: - Get All Available Sounds
    var availableSounds: [FartSound] {
        return unlockedPacks.flatMap { $0.sounds }
    }
    
    // MARK: - Sound Selection
    func selectSound(_ sound: FartSound) {
        selectedSound = sound
        playSound(sound)
    }
    
    func clearSelection() {
        selectedSound = nil
    }
    
    // MARK: - Sound Playback
    func playSound(_ sound: FartSound) {
        guard let soundURL = Bundle.main.url(forResource: sound.fileName, withExtension: "wav") else {
            print("Sound file not found: \(sound.fileName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - Local Storage
    private let purchasedPacksKey = "com.thedailypoop.purchasedFartPacks"
    
    private func savePurchasedPacks() {
        let packIDs = Array(purchasedPacks)
        UserDefaults.standard.set(packIDs, forKey: purchasedPacksKey)
    }
    
    private func loadPurchasedPacks() {
        if let packIDs = UserDefaults.standard.array(forKey: purchasedPacksKey) as? [String] {
            purchasedPacks = Set(packIDs)
        }
    }
    
    // MARK: - CloudKit Sync
    private func savePurchasedPacksToCloudKit() async {
        guard let currentUser = AuthenticationManager.shared.currentUser else {
            print("No current user to save purchases for")
            return
        }
        
        isLoading = true
        
        var purchases = UserFartPackPurchases(userID: currentUser.id, purchasedPackIDs: purchasedPacks)
        let record = purchases.toCKRecord()
        
        do {
            try await cloudKitManager.saveRecord(record)
            print("Successfully saved fart pack purchases to CloudKit")
        } catch {
            print("Failed to save purchases to CloudKit: \(error)")
        }
        
        isLoading = false
    }
    
    func fetchPurchasedPacksFromCloudKit() async {
        guard let currentUser = AuthenticationManager.shared.currentUser else {
            print("No current user to fetch purchases for")
            return
        }
        
        isLoading = true
        
        let recordID = CKRecord.ID(recordName: currentUser.id)
        
        do {
            let record = try await cloudKitManager.fetchRecord(recordID: recordID, recordType: UserFartPackPurchases.recordType)
            
            if let purchases = UserFartPackPurchases(from: record) {
                await MainActor.run {
                    self.purchasedPacks = purchases.purchasedPackIDs
                    self.savePurchasedPacks() // Save to local storage too
                }
            }
        } catch {
            print("Failed to fetch purchases from CloudKit (might not exist yet): \(error)")
            // This is okay - user might not have any purchases yet
        }
        
        isLoading = false
    }
    
    // MARK: - Pack Purchase Flow
    func purchasePack(_ pack: FartPack) async -> Bool {
        guard !pack.isDefault else {
            print("Cannot purchase default pack")
            return false
        }
        
        guard !isPackUnlocked(pack) else {
            print("Pack already unlocked")
            return true
        }
        
        // Get the product from StoreKitManager
        guard let product = StoreKitManager.shared.getProduct(for: pack.productID) else {
            print("Product not found: \(pack.productID)")
            return false
        }
        
        do {
            let success = try await StoreKitManager.shared.purchase(product)
            if success {
                await unlockPack(packID: pack.id)
            }
            return success
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        await StoreKitManager.shared.restorePurchases()
        await fetchPurchasedPacksFromCloudKit()
    }
}

// MARK: - CloudKit Manager Extension
extension CloudKitManager {
    func saveRecord(_ record: CKRecord) async throws {
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        _ = try await database.save(record)
    }
    
    func fetchRecord(recordID: CKRecord.ID, recordType: String) async throws -> CKRecord {
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        return try await database.record(for: recordID)
    }
}

