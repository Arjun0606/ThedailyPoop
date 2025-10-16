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
            // Use "inventory_" prefix to avoid conflict with User records
            let recordID = CKRecord.ID(recordName: "inventory_\(user.id)")
            let record = try await privateDatabase.record(for: recordID)
            
            if let loadedInventory = FartAttackInventory(from: record) {
                await MainActor.run {
                    self.inventory = loadedInventory
                }
            }
            
            // After loading inventory, claim any unclaimed referral credits
            await claimReferralCreditsIfAny(for: user)
        } catch {
            // First time - create new inventory
            print("No inventory found, creating new one")
            await MainActor.run {
                self.inventory = FartAttackInventory(userID: user.id, availableAttacks: 0)
            }
            
            // Even for new inventory, claim any credits
            await claimReferralCreditsIfAny(for: user)
        }
        
        isLoading = false
    }

    // MARK: - Referral Credits
    private func claimReferralCreditsIfAny(for user: User) async {
        do {
            // Query ReferralCredit where senderID == current user and claimed == 0
            let predicate = NSPredicate(format: "senderID == %@ AND claimed == 0", user.id)
            let query = CKQuery(recordType: ReferralCredit.recordType, predicate: predicate)
            let results = try await publicDatabase.records(matching: query)
            var totalReward = 0
            var recordsToUpdate: [CKRecord] = []
            
            for (_, result) in results.matchResults {
                if case .success(let record) = result, let credit = ReferralCredit(from: record) {
                    totalReward += max(0, credit.rewardCount)
                    // mark as claimed
                    record["claimed"] = 1
                    record["claimedAt"] = Date()
                    recordsToUpdate.append(record)
                }
            }
            
            if totalReward > 0 {
                if inventory == nil { inventory = FartAttackInventory(userID: user.id) }
                inventory?.addAttacks(totalReward)
                await saveInventory()
                print("🎉 Claimed referral rewards: +\(totalReward) attacks")
            }
            
            // Save updated credit records
            for record in recordsToUpdate {
                do { _ = try await publicDatabase.save(record) } catch {
                    print("⚠️ Failed to update referral credit as claimed: \(error)")
                }
            }
        } catch {
            print("⚠️ Failed to check referral credits: \(error)")
        }
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
    
    func addAttacksFromPurchase(for user: User, count: Int) async {
        if inventory == nil {
            inventory = FartAttackInventory(userID: user.id)
        }
        
        inventory?.addAttacks(count)
        await saveInventory()
        
        print("👻 Added \(count) ghost attacks! Total: \(inventory?.availableAttacks ?? 0)")
    }

    // Award free attacks for streak milestones (7/30/100), only once each
    func maybeAwardStreakMilestone(for user: inout User) async {
        let milestones = [7, 30, 100]
        for milestone in milestones where user.streak == milestone && !user.awardedStreakMilestones.contains(milestone) {
            if inventory == nil { inventory = FartAttackInventory(userID: user.id) }
            let reward = milestone == 7 ? 1 : (milestone == 30 ? 3 : 10)
            inventory?.addAttacks(reward)
            await saveInventory()
            user.awardedStreakMilestones.insert(milestone)
            print("🎁 Awarded \(reward) attacks for reaching \(milestone)-day streak")
        }
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
    
    func sendAttack(from currentUser: User, to friend: User, pointsManager: PointsManager) async -> Bool {
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
            
            // Create activity: sent
            let activity = AttackActivity(
                type: .sent,
                senderID: currentUser.id,
                senderUsername: currentUser.username,
                targetUserID: friend.id,
                targetUsername: friend.username,
                attackID: attack.id
            )
            do { _ = try await publicDatabase.save(activity.toCKRecord()) } catch { print("⚠️ Failed to save activity: \(error)") }
            
            // Update user stats for social validation
            var mutableCurrentUser = currentUser
            mutableCurrentUser.attacksSent += 1
            var mutableFriend = friend
            mutableFriend.attacksReceived += 1
            
            try await publicDatabase.save(mutableCurrentUser.toCKRecord())
            try await publicDatabase.save(mutableFriend.toCKRecord())
            
            // 🎯 AWARD POINTS FOR SENDING ATTACK
            await pointsManager.awardPoints(to: &mutableCurrentUser, for: .sendAttack)
            
            // 🎯 AWARD POINTS FOR RECEIVING ATTACK (to victim)
            await pointsManager.awardPoints(to: &mutableFriend, for: .receiveAttack)
            
            // 👻 THE #1 HOOK: Send Ghost Attack notification to victim
            await NotificationManager.shared.sendGhostAttackNotification(to: mutableFriend, attackID: attack.id)
            
            // ⚠️ MONETIZATION HOOK: Check if user is low on attacks
            if let currentInventory = inventory, currentInventory.availableAttacks <= 1 {
                await NotificationManager.shared.sendLowAttacksNotification(to: mutableCurrentUser, attacksRemaining: currentInventory.availableAttacks)
            }

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
    
    // MARK: - Attack Reactions
    
    func reactToAttack(attack: FartAttack, reactor: User, emoji: String, text: String?) async throws {
        // Create activity for the reaction
        let activity = AttackActivity(
            type: .reacted,
            senderID: reactor.id,
            senderUsername: reactor.username,
            targetUserID: attack.senderID,
            targetUsername: attack.senderUsername,
            attackID: attack.id,
            reactionEmoji: emoji,
            reactionText: text
        )
        
        // Save to CloudKit
        let record = activity.toCKRecord()
        try await publicDatabase.save(record)
        print("👍 Reaction saved!")
    }
}

