# CloudKit Schema - Fart Attack Feature (v1.02)

## 🎯 Overview

This document outlines the CloudKit schema additions required for the Fart Attack Pack feature.

---

## 📊 New Record Types

### 1. FartAttack (Public Database)

Stores individual fart attacks sent between users.

**Record Type Name**: `FartAttack`  
**Database**: Public Database

| Field Name | Field Type | Indexed | Required | Notes |
|------------|------------|---------|----------|-------|
| senderID | String | ✅ Yes | ✅ Yes | User who sent the attack |
| senderUsername | String | ✅ Yes | ✅ Yes | Username of sender (denormalized) |
| targetUserID | String | ✅ Yes | ✅ Yes | User who will receive the attack |
| targetUsername | String | ❌ No | ✅ Yes | Username of target (denormalized) |
| timestamp | Date/Time | ✅ Yes | ✅ Yes | When attack was sent |
| soundFileName | String | ❌ No | ✅ Yes | Sound file to play (default: "fart_long_epidemic") |
| wasPlayed | Int64 | ✅ Yes | ✅ Yes | 0=pending, 1=played |
| playedAt | Date/Time | ❌ No | ❌ No | When attack was played |

**Indexes**:
- `senderID` (Queryable)
- `senderUsername` (Queryable)  
- `targetUserID` (Queryable) - **CRITICAL for finding user's pending attacks**
- `timestamp` (Sortable)
- `wasPlayed` (Queryable) - **CRITICAL for finding unplayed attacks**

**Security Roles**:
- World: Readable
- Creator: Writable

---

### 2. FartAttackInventory (Private Database)

Tracks how many attacks each user has available and cooldowns.

**Record Type Name**: `FartAttackInventory`  
**Database**: Private Database

| Field Name | Field Type | Indexed | Required | Notes |
|------------|------------|---------|----------|-------|
| userID | String | ✅ Yes | ✅ Yes | User who owns this inventory |
| availableAttacks | Int64 | ❌ No | ✅ Yes | Number of attacks remaining |
| lastUpdated | Date/Time | ✅ Yes | ✅ Yes | Last modification time |
| cooldowns | Bytes | ❌ No | ❌ No | JSON dictionary [friendID: Date] |

**Indexes**:
- `userID` (Queryable) - **CRITICAL for loading user's inventory**
- `lastUpdated` (Sortable)

**Security Roles**:
- Creator: Readable, Writable

**Notes**:
- `cooldowns` field stores JSON-encoded dictionary mapping friend user IDs to last attack timestamps
- Used to enforce 24-hour cooldown per friend pair

---

## 🔧 Setup Instructions

### Step 1: Go to CloudKit Dashboard

1. Visit [icloud.developer.apple.com/dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container: `iCloud.com.poopdrop.app`
3. Click **"Schema"** → **"Record Types"**

---

### Step 2: Create FartAttack Record Type

1. Click **"+"** to add new record type
2. Name: `FartAttack`
3. Database: **Public Database**
4. Add fields (see table above)
5. Configure indexes:
   - `senderID`: Queryable
   - `senderUsername`: Queryable
   - `targetUserID`: Queryable
   - `timestamp`: Sortable
   - `wasPlayed`: Queryable
6. Security:
   - World: Readable ✅
   - Creator: Writable ✅
7. Click **"Save"**

---

### Step 3: Create FartAttackInventory Record Type

1. Click **"+"** to add new record type
2. Name: `FartAttackInventory`
3. Database: **Private Database**
4. Add fields (see table above)
5. Configure indexes:
   - `userID`: Queryable
   - `lastUpdated`: Sortable
6. Security:
   - Creator: Readable ✅, Writable ✅
7. Click **"Save"**

---

## 🔍 Key Queries Used in App

### Query 1: Find Pending Attacks for Current User

```swift
let predicate = NSPredicate(format: "targetUserID == %@ AND wasPlayed == 0", currentUserID)
let query = CKQuery(recordType: "FartAttack", predicate: predicate)
query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
```

**Purpose**: Check for unplayed attacks when user opens app

---

### Query 2: Load User's Inventory

```swift
let recordID = CKRecord.ID(recordName: currentUserID)
let record = try await database.record(for: recordID)
```

**Purpose**: Load available attacks and cooldowns

---

## 💾 Data Flow

### Sending an Attack

```
User A buys pack ($1.99)
    ↓
FartAttackInventory updated: availableAttacks += 3
    ↓
User A taps "Send Fart Attack" on Friend B's profile
    ↓
Check cooldown (can't attack same friend within 24hrs)
    ↓
Create FartAttack record:
  - senderID: User A's ID
  - targetUserID: User B's ID
  - wasPlayed: 0
    ↓
Update FartAttackInventory:
  - availableAttacks -= 1
  - cooldowns[User B's ID] = now
    ↓
Save both records to CloudKit
```

---

### Receiving an Attack

```
User B opens app
    ↓
MainTabView.onAppear() triggers checkPendingAttacks()
    ↓
Query CloudKit: targetUserID == User B AND wasPlayed == 0
    ↓
Found 2 attacks (from User A and User C)
    ↓
Sort by timestamp (oldest first)
    ↓
Play first attack:
  - Full-screen overlay
  - 4-second fart sound
  - Mark wasPlayed = 1, playedAt = now
    ↓
Dismiss → play next attack
    ↓
All attacks played → return to app
```

---

## 🚦 Cooldown Logic

### Enforced Locally (Not in CloudKit)

The 24-hour cooldown is enforced in the app:

```swift
func canAttack(friendID: String) -> Bool {
    guard let lastAttack = cooldowns[friendID] else {
        return true // Never attacked this friend
    }
    
    let hoursSinceLastAttack = Date().timeIntervalSince(lastAttack) / 3600
    return hoursSinceLastAttack >= 24
}
```

**Why not in CloudKit?**
- Simpler schema
- Faster local checks
- Cooldowns stored in user's inventory record
- Syncs across devices automatically

---

## 📈 Scaling Considerations

### Expected Data Volume

**Conservative** (10K users, 500 buyers, 1.5 packs avg):
- 2,250 attacks total
- ~5-10 attacks/day
- Minimal CloudKit usage

**Moderate** (50K users, prank wars):
- 15,000 attacks total
- ~100 attacks/day
- Moderate CloudKit usage

**Viral** (100K users, social media):
- 150,000 attacks total
- ~1,000 attacks/day
- High CloudKit usage (still well within limits)

---

### Cleanup Strategy

**Old Attacks**:
- Keep played attacks for 30 days (for history/analytics)
- Delete attacks older than 30 days automatically
- Run cleanup job weekly

**Implementation**:
```swift
let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
let predicate = NSPredicate(format: "wasPlayed == 1 AND playedAt < %@", thirtyDaysAgo as NSDate)
// Query and delete old records
```

---

## 🔒 Security

### Attack Spam Prevention

**Client-Side**:
- 24-hour cooldown per friend
- UI only shows button if attacks available
- Purchase required for attacks

**Server-Side** (Future Enhancement):
- CloudKit Triggers to validate:
  - Sender has valid inventory
  - Cooldown period elapsed
  - Both users are friends

---

## 🧪 Testing

### Test Data Creation

```swift
// Create test attack
let attack = FartAttack(
    senderID: "test-user-1",
    senderUsername: "tester1",
    targetUserID: "test-user-2",
    targetUsername: "tester2",
    soundFileName: "fart_long_epidemic"
)

let record = attack.toCKRecord()
try await database.save(record)
```

---

## ✅ Verification Checklist

After setup, verify:

### FartAttack Record Type
- [ ] Record type exists in Public Database
- [ ] All 8 fields present with correct types
- [ ] Indexes configured (5 total)
- [ ] Security: World readable, Creator writable

### FartAttackInventory Record Type
- [ ] Record type exists in Private Database
- [ ] All 4 fields present with correct types
- [ ] Indexes configured (2 total)
- [ ] Security: Creator readable/writable

### Test in App
- [ ] Can query pending attacks
- [ ] Can create new attack
- [ ] Can update inventory
- [ ] Cooldowns persist across app restarts

---

## 🆘 Troubleshooting

### "Record type not found"
**Solution**: Verify record type name is exact: `FartAttack` and `FartAttackInventory`

### "Permission denied"
**Solution**: Check security settings - Public DB for attacks, Private DB for inventory

### "Query returns no results"
**Solution**: 
- Verify indexes are created
- Check `targetUserID` and `wasPlayed` are indexed
- Wait 5-10 minutes for index propagation

### "Inventory not syncing"
**Solution**:
- Check user is signed into iCloud
- Verify Private Database access
- Check `userID` matches current user

---

**Setup Time**: ~15 minutes  
**Status**: Required for v1.02 Fart Attack feature  
**Last Updated**: October 7, 2025

