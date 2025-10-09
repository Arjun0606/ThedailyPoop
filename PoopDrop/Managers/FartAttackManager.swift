import Foundation
import AVFoundation
import CloudKit
import SwiftUI

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

