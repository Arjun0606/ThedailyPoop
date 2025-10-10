# CloudKit Schema Setup Guide - Complete

## Overview
This guide will help you set up all the CloudKit record types needed for PoopDrop to work properly.

## Access CloudKit Dashboard
1. Go to https://icloud.developer.apple.com/
2. Sign in with your Apple Developer account
3. Select your app's container: `iCloud.com.poopdrop.app`
4. Click "Schema" in the left sidebar

---

## Record Types to Create

### 1. AttackActivity (NEW)
**Purpose:** Tracks all fart attack-related activities for the public feed

**Record Type Name:** `AttackActivity`
**Database:** Public

**Fields:**
| Field Name | Type | Required | Indexed | Description |
|------------|------|----------|---------|-------------|
| `type` | String | Yes | Yes | "sent" or "reacted" |
| `senderID` | String | Yes | Yes | User who performed the action |
| `senderUsername` | String | Yes | No | Display name |
| `targetUserID` | String | No | Yes | Target of the action (optional) |
| `targetUsername` | String | No | No | Target display name |
| `attackID` | String | No | Yes | Related attack ID |
| `reactionEmoji` | String | No | No | Emoji reaction (if type=reacted) |
| `reactionText` | String | No | No | Text reaction (if type=reacted) |
| `timestamp` | Date/Time | Yes | Yes | When action occurred |

**Indexes:**
- `type` (Queryable)
- `senderID` (Queryable)
- `targetUserID` (Queryable)
- `timestamp` (Sortable)

**Permissions:**
- World readable: Yes
- World writable: Yes

---

### 2. ReferralCredit (NEW)
**Purpose:** Tracks referral rewards when users install via external links

**Record Type Name:** `ReferralCredit`
**Database:** Public

**Fields:**
| Field Name | Type | Required | Indexed | Description |
|------------|------|----------|---------|-------------|
| `referrerID` | String | Yes | Yes | User who sent the external attack |
| `recipientID` | String | Yes | Yes | User who clicked and installed |
| `claimed` | Int64 | Yes | Yes | 0 = unclaimed, 1 = claimed |
| `rewardCount` | Int64 | Yes | No | Number of attacks to award (default: 1) |
| `claimedAt` | Date/Time | No | No | When the reward was claimed |
| `timestamp` | Date/Time | Yes | Yes | When the credit was created |

**Indexes:**
- `referrerID` (Queryable)
- `recipientID` (Queryable)
- `claimed` (Queryable)
- `timestamp` (Sortable)

**Permissions:**
- World readable: Yes
- World writable: Yes

---

### 3. AnalyticsEvent (NEW)
**Purpose:** Lightweight analytics for tracking key user behaviors

**Record Type Name:** `AnalyticsEvent`
**Database:** Public

**Fields:**
| Field Name | Type | Required | Indexed | Description |
|------------|------|----------|---------|-------------|
| `type` | String | Yes | Yes | Event type (install, purchase, etc.) |
| `userID` | String | Yes | Yes | User or device ID |
| `timestamp` | Date/Time | Yes | Yes | When event occurred |
| `properties` | String | No | No | JSON string of additional data |

**Indexes:**
- `type` (Queryable)
- `userID` (Queryable)
- `timestamp` (Sortable)

**Permissions:**
- World readable: Yes
- World writable: Yes

---

### 4. User (EXISTING - Update if needed)
**Purpose:** Core user profile data

**Record Type Name:** `User`
**Database:** Public

**NEW Fields to Add (if not present):**
| Field Name | Type | Required | Indexed | Description |
|------------|------|----------|---------|-------------|
| `lastStreakRewardClaimed` | Date/Time | No | No | Last time streak reward was claimed |
| `pendingStreakFreeze` | Int64 | No | No | 0 or 1, if streak freeze prompt shown |
| `streakFreezeExpiration` | Date/Time | No | No | 24h window to buy freeze |
| `awardedStreakMilestones` | Bytes | No | No | Encoded Set<Int> of milestones |

**Note:** Other User fields should already exist from your current schema.

---

### 5. FartAttack (EXISTING - Verify)
**Purpose:** Stores sent fart attacks

**Record Type Name:** `FartAttack`
**Database:** Public

**Fields to Verify:**
| Field Name | Type | Required | Indexed |
|------------|------|----------|---------|
| `senderID` | String | Yes | Yes |
| `senderUsername` | String | Yes | No |
| `targetUserID` | String | Yes | Yes |
| `targetUsername` | String | Yes | No |
| `timestamp` | Date/Time | Yes | Yes |
| `soundFileName` | String | Yes | No |
| `wasPlayed` | Int64 | Yes | No |
| `playedAt` | Date/Time | No | No |
| `isExternal` | Int64 | Yes | Yes |
| `recipientIdentifier` | String | No | Yes |
| `clickedAt` | Date/Time | No | No |
| `installedApp` | Int64 | No | No |

---

### 6. FartAttackInventory (EXISTING - Verify)
**Purpose:** Tracks user's attack inventory and cooldowns

**Record Type Name:** `FartAttackInventory`
**Database:** Private

**Fields to Verify:**
| Field Name | Type | Required | Indexed |
|------------|------|----------|---------|
| `userID` | String | Yes | Yes |
| `availableAttacks` | Int64 | Yes | No |
| `lastUpdated` | Date/Time | Yes | No |
| `cooldowns` | Bytes | No | No |
| `externalCooldowns` | Bytes | No | No |
| `externalSharesToday` | Int64 | No | No |
| `lastExternalShareDate` | Date/Time | No | No |

**Note:** This is in the **Private** database, not Public.

---

## Step-by-Step Setup Instructions

### For Each New Record Type:

1. **Click "Add Record Type"**
   - Enter the record type name exactly as shown above
   - Click "Save"

2. **Add Fields**
   - Click "Add Field" for each field in the table
   - Select the correct field type (String, Int64, Date/Time, Bytes)
   - Check "Required" if marked Yes
   - Click "Save"

3. **Add Indexes**
   - Click "Indexes" tab
   - Click "Add Index"
   - Select the field to index
   - Choose "Queryable" or "Sortable" as specified
   - Click "Save"

4. **Set Permissions**
   - Click "Security" tab
   - For Public database records:
     - World: Check "Read" and "Write"
   - For Private database records:
     - User: Check "Read" and "Write"
   - Click "Save"

5. **Deploy to Production**
   - After setting up all record types in Development
   - Click "Deploy to Production" at the top
   - Confirm deployment

---

## Testing CloudKit Schema

After setting up the schema, test each record type:

### Test 1: AttackActivity
Run this in Xcode with your app:
```swift
Task {
    let activity = AttackActivity(
        type: .sent,
        userID: "test123",
        senderUsername: "TestUser",
        targetUserID: "target123",
        targetUsername: "TargetUser",
        attackID: "attack123"
    )
    
    let container = CKContainer.default()
    let db = container.publicCloudDatabase
    let record = activity.toCKRecord()
    
    do {
        _ = try await db.save(record)
        print("✅ AttackActivity saved successfully")
    } catch {
        print("❌ Error: \(error)")
    }
}
```

### Test 2: ReferralCredit
```swift
Task {
    let credit = ReferralCredit(
        referrerID: "referrer123",
        recipientID: "recipient123",
        rewardCount: 1
    )
    
    let container = CKContainer.default()
    let db = container.publicCloudDatabase
    let record = credit.toCKRecord()
    
    do {
        _ = try await db.save(record)
        print("✅ ReferralCredit saved successfully")
    } catch {
        print("❌ Error: \(error)")
    }
}
```

### Test 3: AnalyticsEvent
```swift
Task {
    AnalyticsManager.shared.trackInstall(source: "test", referrerID: "test123")
    print("✅ AnalyticsEvent tracked")
}
```

---

## Common Issues & Solutions

### Issue: "Unknown record type"
**Solution:** Make sure you deployed the schema from Development to Production.

### Issue: "Permission denied"
**Solution:** Check that "World" has Read + Write permissions for Public database records.

### Issue: "Field not found"
**Solution:** Verify all field names match exactly (case-sensitive).

### Issue: "Cannot query on this field"
**Solution:** Make sure the field has a Queryable index.

---

## Verification Checklist

Before launching, verify:

- [ ] All 3 new record types created: AttackActivity, ReferralCredit, AnalyticsEvent
- [ ] All fields added with correct types
- [ ] All indexes added (especially for query fields)
- [ ] Permissions set to World Read/Write for Public records
- [ ] Schema deployed to Production
- [ ] Test records saved successfully
- [ ] App can query records without errors
- [ ] User fields updated with new streak-related fields

---

## CloudKit Dashboard Access

**Development Environment:**
- Use for testing and schema changes
- Data is separate from Production

**Production Environment:**
- Use for live app
- Must deploy schema from Development first
- Cannot modify schema directly in Production

**Important:** Always test in Development first, then deploy to Production!

---

## Next Steps After CloudKit Setup

1. ✅ CloudKit schema deployed
2. Test end-to-end flow:
   - Send external attack
   - Recipient clicks link
   - Recipient installs app
   - Referral credit created
   - Credit claimed on next app open
3. Verify analytics events logging
4. Check leaderboard queries working
5. Test attack activity feed
6. Ready for App Store submission!

---

## Support

If you encounter issues:
1. Check CloudKit Dashboard Console for error logs
2. Verify container ID matches: `iCloud.com.poopdrop.app`
3. Ensure iCloud capability is enabled in Xcode
4. Check that device is signed into iCloud
5. Test on real device (simulator iCloud can be flaky)

**You're ready to deploy! 🚀**

