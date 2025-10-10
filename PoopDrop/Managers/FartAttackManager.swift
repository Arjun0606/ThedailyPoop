import Foundation
import AVFoundation
import CloudKit
import SwiftUI
import CryptoKit

@MainActor
class FartAttackManager: ObservableObject {
    static let shared = FartAttackManager()
    
    @Published var inventory: FartAttackInventory?
    @Published var pendingAttacks: [FartAttack] = []
    @Published var isLoading = false
    @Published var showingAttackOverlay = false
    @Published var currentAttack: FartAttack?
    
    private var audioPlayer: AVAudioPlayer?
    private let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
    private var publicDatabase: CKDatabase
    private var privateDatabase: CKDatabase
    
    private init() {
        self.publicDatabase = container.publicCloudDatabase
        self.privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Inventory Management
    
    func loadInventory(for user: User) async {
        isLoading = true
        
        do {
            let recordID = CKRecord.ID(recordName: user.id)
            let record = try await privateDatabase.record(for: recordID)
            
            if let loadedInventory = FartAttackInventory(from: record) {
                await MainActor.run {
                    self.inventory = loadedInventory
                }
            }
        } catch {
            // First time - create new inventory
            print("No inventory found, creating new one")
            await MainActor.run {
                self.inventory = FartAttackInventory(userID: user.id, availableAttacks: 0)
            }
        }
        
        isLoading = false
    }
    
    func saveInventory() async {
        guard let inventory = inventory else { return }
        
        let record = inventory.toCKRecord()
        
        do {
            try await privateDatabase.save(record)
            print("✅ Inventory saved: \(inventory.availableAttacks) attacks available")
        } catch {
            print("❌ Failed to save inventory: \(error)")
        }
    }
    
    // MARK: - Purchase Handling
    
    func addAttacksFromPurchase(for user: User, count: Int = FartAttackPack.attacksPerPack) async {
        if inventory == nil {
            inventory = FartAttackInventory(userID: user.id)
        }
        
        inventory?.addAttacks(count)
        await saveInventory()
        
        print("💨 Added \(count) fart attacks! Total: \(inventory?.availableAttacks ?? 0)")
    }
    
    // MARK: - Sending Attacks
    
    func canSendAttack(to friend: User) -> Bool {
        guard let inventory = inventory else { return false }
        guard inventory.availableAttacks > 0 else { return false }
        return inventory.canAttack(friendID: friend.id)
    }
    
    func getCooldownRemaining(for friend: User) -> TimeInterval? {
        return inventory?.cooldownRemaining(friendID: friend.id)
    }
    
    func sendAttack(from currentUser: User, to friend: User) async -> Bool {
        guard var currentInventory = inventory else {
            print("❌ No inventory")
            return false
        }
        
        // Check if can attack
        guard currentInventory.useAttack(targetFriendID: friend.id) else {
            print("❌ Cannot attack: no attacks available or cooldown active")
            return false
        }
        
        // Update local inventory
        inventory = currentInventory
        
        // Create attack
        let attack = FartAttack(
            senderID: currentUser.id,
            senderUsername: currentUser.username,
            targetUserID: friend.id,
            targetUsername: friend.username,
            soundFileName: "fart_long_epidemic"
        )
        
        // Save to CloudKit
        do {
            let record = attack.toCKRecord()
            try await publicDatabase.save(record)
            print("💨 Fart attack sent to \(friend.username)!")
            
            // Save updated inventory
            await saveInventory()
            
            return true
        } catch {
            // Revert inventory on failure
            inventory?.addAttacks(1)
            print("❌ Failed to send attack: \(error)")
            return false
        }
    }
    
    // MARK: - External Sharing
    
    /// Hash a phone number or identifier for privacy
    private func hashIdentifier(_ identifier: String) -> String {
        let inputData = Data(identifier.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Check if can send external attack to a specific recipient
    func canSendExternalAttack(to recipientIdentifier: String) -> Bool {
        guard var currentInventory = inventory else { return false }
        guard currentInventory.availableAttacks > 0 else { return false }
        
        let hash = hashIdentifier(recipientIdentifier)
        return currentInventory.canAttackExternal(recipientHash: hash) && currentInventory.canShareExternally()
    }
    
    /// Get cooldown remaining for external recipient
    func getExternalCooldownRemaining(for recipientIdentifier: String) -> TimeInterval? {
        let hash = hashIdentifier(recipientIdentifier)
        return inventory?.externalCooldownRemaining(recipientHash: hash)
    }
    
    /// Create external fart attack and generate shareable link
    func createExternalAttack(from currentUser: User, recipientName: String, recipientIdentifier: String) async -> (success: Bool, shareURL: URL?, attackID: String?) {
        guard var currentInventory = inventory else {
            print("❌ No inventory")
            return (false, nil, nil)
        }
        
        let hash = hashIdentifier(recipientIdentifier)
        
        // Check if can attack
        guard currentInventory.useExternalAttack(recipientHash: hash) else {
            print("❌ Cannot attack: no attacks available, cooldown active, or daily limit reached")
            return (false, nil, nil)
        }
        
        // Update local inventory
        inventory = currentInventory
        
        // Create external attack
        let attackID = UUID().uuidString
        let attack = FartAttack(
            id: attackID,
            senderID: currentUser.id,
            senderUsername: currentUser.username,
            targetUserID: "", // External - no user ID yet
            targetUsername: recipientName,
            soundFileName: "fart_long_epidemic",
            isExternal: true,
            recipientIdentifier: hash
        )
        
        // Save to CloudKit
        do {
            let record = attack.toCKRecord()
            try await publicDatabase.save(record)
            print("💨 External fart attack created!")
            
            // Save updated inventory
            await saveInventory()
            
            // Generate share URL (Universal Link)
            // Format: https://thedailypoop.app/fart/[attackID]
            if let shareURL = URL(string: "https://thedailypoop.app/fart/\(attackID)") {
                return (true, shareURL, attackID)
            }
            
            return (true, nil, attackID)
        } catch {
            // Revert inventory on failure
            inventory?.addAttacks(1)
            print("❌ Failed to create external attack: \(error)")
            return (false, nil, nil)
        }
    }
    
    /// Process incoming external attack (from Universal Link)
    func processExternalAttackLink(attackID: String, currentUser: User?) async -> Bool {
        do {
            // Fetch attack from CloudKit
            let recordID = CKRecord.ID(recordName: attackID)
            let record = try await publicDatabase.record(for: recordID)
            
            guard var attack = FartAttack(from: record) else {
                print("❌ Invalid attack record")
                return false
            }
            
            // Update click timestamp
            attack.clickedAt = Date()
            
            // If user is logged in, associate the attack with them
            if let user = currentUser {
                var updatedAttack = attack
                updatedAttack.installedApp = true
                
                // Save updated attack
                let updatedRecord = updatedAttack.toCKRecord()
                try await publicDatabase.save(updatedRecord)
                
                // Add to pending attacks if not already played
                if !attack.wasPlayed {
                    await MainActor.run {
                        self.pendingAttacks.append(updatedAttack)
                        if !self.showingAttackOverlay {
                            self.playNextAttack()
                        }
                    }
                }
            } else {
                // User not logged in - just update click timestamp
                let updatedRecord = attack.toCKRecord()
                try await publicDatabase.save(updatedRecord)
            }
            
            print("✅ Processed external attack link")
            return true
        } catch {
            print("❌ Failed to process external attack: \(error)")
            return false
        }
    }
    
    // MARK: - Receiving Attacks
    
    func checkPendingAttacks(for user: User) async {
        isLoading = true
        
        do {
            // Query for unplayed attacks targeted at current user
            let predicate = NSPredicate(format: "targetUserID == %@ AND wasPlayed == 0", user.id)
            let query = CKQuery(recordType: FartAttack.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            
            let results = try await publicDatabase.records(matching: query)
            
            let attacks = results.matchResults.compactMap { _, result -> FartAttack? in
                guard case .success(let record) = result else { return nil }
                return FartAttack(from: record)
            }
            
            await MainActor.run {
                self.pendingAttacks = attacks
                self.isLoading = false
                
                // Auto-play if there are pending attacks
                if !attacks.isEmpty {
                    self.playNextAttack()
                }
            }
            
            print("💨 Found \(attacks.count) pending fart attacks")
            
        } catch {
            print("❌ Failed to check pending attacks: \(error)")
            isLoading = false
        }
    }
    
    // MARK: - Playing Attacks
    
    func playNextAttack() {
        guard !pendingAttacks.isEmpty else {
            showingAttackOverlay = false
            currentAttack = nil
            return
        }
        
        let attack = pendingAttacks[0]
        currentAttack = attack
        showingAttackOverlay = true
        
        // Play sound
        playAttackSound(attack.soundFileName)
        
        // Mark as played in CloudKit
        Task {
            await markAttackAsPlayed(attack)
        }
    }
    
    private func playAttackSound(_ fileName: String) {
        guard let soundURL = Bundle.main.url(forResource: fileName, withExtension: "wav") else {
            print("❌ Sound file not found: \(fileName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("🔊 Playing fart attack sound!")
        } catch {
            print("❌ Failed to play sound: \(error)")
        }
    }
    
    func dismissCurrentAttack() {
        // Remove first attack from queue
        if !pendingAttacks.isEmpty {
            pendingAttacks.removeFirst()
        }
        
        // Stop sound
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Play next if available, otherwise hide overlay
        if !pendingAttacks.isEmpty {
            // Small delay before next attack
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.playNextAttack()
            }
        } else {
            showingAttackOverlay = false
            currentAttack = nil
        }
    }
    
    private func markAttackAsPlayed(_ attack: FartAttack) async {
        var updatedAttack = attack
        updatedAttack.wasPlayed = true
        updatedAttack.playedAt = Date()
        
        let record = updatedAttack.toCKRecord()
        
        do {
            try await publicDatabase.save(record)
            print("✅ Marked attack as played")
        } catch {
            print("❌ Failed to mark attack as played: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    func formatCooldownTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

