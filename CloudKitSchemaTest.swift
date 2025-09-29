import CloudKit
import Foundation

// Test script to verify CloudKit schema setup
class CloudKitSchemaTest {
    let container = CKContainer.default()
    
    func testSchemaSetup() async {
        print("🧪 Testing CloudKit Schema Setup...")
        
        // Test 1: Check if we can access CloudKit
        await testCloudKitAccess()
        
        // Test 2: Try to create a test user
        await testUserCreation()
        
        // Test 3: Try to create a test drop
        await testDropCreation()
        
        print("✅ CloudKit schema test completed!")
    }
    
    private func testCloudKitAccess() async {
        do {
            let accountStatus = try await container.accountStatus()
            switch accountStatus {
            case .available:
                print("✅ CloudKit account available")
            case .noAccount:
                print("❌ No iCloud account signed in")
            case .couldNotDetermine:
                print("⚠️ Could not determine iCloud account status")
            case .restricted:
                print("❌ iCloud account restricted")
            @unknown default:
                print("❓ Unknown iCloud account status")
            }
        } catch {
            print("❌ Error checking CloudKit account: \(error)")
        }
    }
    
    private func testUserCreation() async {
        let testUser = CKRecord(recordType: "User")
        testUser["displayName"] = "Test User"
        testUser["isPro"] = 0
        testUser["streak"] = 1
        testUser["totalDrops"] = 0
        testUser["maxDropsInDay"] = 0
        testUser["longestNoPoopStreak"] = 0
        testUser["createdAt"] = Date()
        
        do {
            let savedRecord = try await container.publicCloudDatabase.save(testUser)
            print("✅ Test user created: \(savedRecord.recordID)")
            
            // Clean up - delete test record
            try await container.publicCloudDatabase.deleteRecord(withID: savedRecord.recordID)
            print("🗑️ Test user cleaned up")
        } catch {
            print("❌ Error creating test user: \(error)")
        }
    }
    
    private func testDropCreation() async {
        let testDrop = CKRecord(recordType: "Drop")
        testDrop["creatorId"] = "test-user-id"
        testDrop["creatorName"] = "Test User"
        testDrop["createdAt"] = Date()
        testDrop["isNoPoop"] = 0
        testDrop["isProUser"] = 0
        testDrop["expiresAt"] = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        
        do {
            let savedRecord = try await container.publicCloudDatabase.save(testDrop)
            print("✅ Test drop created: \(savedRecord.recordID)")
            
            // Clean up
            try await container.publicCloudDatabase.deleteRecord(withID: savedRecord.recordID)
            print("🗑️ Test drop cleaned up")
        } catch {
            print("❌ Error creating test drop: \(error)")
        }
    }
}

// Run the test
Task {
    let test = CloudKitSchemaTest()
    await test.testSchemaSetup()
}
