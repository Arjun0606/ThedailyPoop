// Test script to verify CloudKit schema is working
// Copy this into a test function in your app to verify everything works

import CloudKit
import Foundation

func testCloudKitSchema() async {
    print("🧪 Testing CloudKit Schema...")
    
    let container = CKContainer.default()
    let publicDB = container.publicCloudDatabase
    
    // Test 1: AttackActivity
    do {
        let activity = AttackActivity(
            type: .sent,
            senderID: "test_sender",
            senderUsername: "TestSender",
            targetUserID: "test_target",
            targetUsername: "TestTarget",
            attackID: "test_attack_123"
        )
        
        let record = activity.toCKRecord()
        _ = try await publicDB.save(record)
        print("✅ AttackActivity: Schema working")
        
        // Clean up
        try? await publicDB.deleteRecord(withID: record.recordID)
    } catch {
        print("❌ AttackActivity: \(error)")
    }
    
    // Test 2: ReferralCredit
    do {
        let credit = ReferralCredit(
            referrerID: "test_referrer",
            recipientID: "test_recipient",
            rewardCount: 1
        )
        
        let record = credit.toCKRecord()
        _ = try await publicDB.save(record)
        print("✅ ReferralCredit: Schema working")
        
        // Clean up
        try? await publicDB.deleteRecord(withID: record.recordID)
    } catch {
        print("❌ ReferralCredit: \(error)")
    }
    
    // Test 3: AnalyticsEvent
    do {
        let event = AnalyticsEvent(
            type: .install,
            userID: "test_user",
            properties: ["source": "test"]
        )
        
        let record = event.toCKRecord()
        _ = try await publicDB.save(record)
        print("✅ AnalyticsEvent: Schema working")
        
        // Clean up
        try? await publicDB.deleteRecord(withID: record.recordID)
    } catch {
        print("❌ AnalyticsEvent: \(error)")
    }
    
    // Test 4: Query AttackActivity (test indexes)
    do {
        let predicate = NSPredicate(format: "senderID == %@", "test_sender")
        let query = CKQuery(recordType: "AttackActivity", predicate: predicate)
        let results = try await publicDB.records(matching: query, resultsLimit: 10)
        print("✅ AttackActivity Query: Indexes working (\(results.matchResults.count) results)")
    } catch {
        print("❌ AttackActivity Query: \(error)")
    }
    
    // Test 5: Query ReferralCredit (test indexes)
    do {
        let predicate = NSPredicate(format: "referrerID == %@ AND claimed == 0", "test_referrer")
        let query = CKQuery(recordType: "ReferralCredit", predicate: predicate)
        let results = try await publicDB.records(matching: query, resultsLimit: 10)
        print("✅ ReferralCredit Query: Indexes working (\(results.matchResults.count) results)")
    } catch {
        print("❌ ReferralCredit Query: \(error)")
    }
    
    print("🏁 CloudKit Schema Test Complete!")
}

// Usage:
// Task { await testCloudKitSchema() }

