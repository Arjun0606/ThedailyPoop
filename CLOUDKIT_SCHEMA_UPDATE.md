# 🔥 CloudKit Schema Update - Viral Features

## ⚠️ CRITICAL: Add These Fields to CloudKit

### 1. Update `User` Record Type

Add these new fields:

```
dailyPoints - Int64
dailyPointsResetDate - Date/Time
totalLifetimePoints - Int64
pointsBoostActive - Int64 (0 or 1)
pointsBoostExpiresAt - Date/Time
```

### 2. Update `FartAttack` Record Type

Add these new fields for ghost mode:

```
isGhost - Int64 (0 or 1)
ghostGuesses - String List
ghostRevealed - Int64 (0 or 1)
ghostHintPurchased - Int64 (0 or 1)
```

### 3. Update `FartAttackInventory` Record Type

Add this new field:

```
availableGhostAttacks - Int64
```

### 4. Create NEW `Poll` Record Type

```
creatorID - String (indexed)
creatorUsername - String
questionText - String
pollType - String
createdAt - Date/Time (indexed)
endsAt - Date/Time (indexed)
isActive - Int64 (0 or 1, indexed)
totalVotes - Int64
```

**Indexes:**
- creatorID (queryable)
- createdAt (sortable)
- endsAt (queryable)
- isActive (queryable)

### 5. Create NEW `PollVote` Record Type

```
pollID - String (indexed)
voterID - String (indexed)
voterUsername - String
votedForID - String (indexed)
votedForUsername - String
timestamp - Date/Time
```

**Indexes:**
- pollID (queryable) - find all votes for a poll
- voterID (queryable) - find all polls a user voted in
- votedForID (queryable) - find who voted for a specific user

### 6. Create NEW `PollRevealPurchase` Record Type

```
pollID - String (indexed)
userID - String (indexed)
purchaseDate - Date/Time
```

**Indexes:**
- pollID (queryable)
- userID (queryable)
- Compound index: (userID, pollID) - check if user purchased reveal for specific poll

---

## 📋 Setup Instructions

### Step 1: Go to CloudKit Dashboard
1. https://icloud.developer.apple.com/dashboard
2. Select your app: `iCloud.com.thedailypoop.app`
3. Go to "Schema" → "Production" (or Development for testing)

### Step 2: Update Existing Record Types

**For User:**
1. Click "User" record type
2. Click "Add Field" for each new field
3. Select correct data type
4. Save

**For FartAttack:**
1. Click "FartAttack" record type
2. Add the 4 ghost mode fields
3. Save

**For FartAttackInventory:**
1. Click "FartAttackInventory" record type
2. Add `availableGhostAttacks` as Int64
3. Save

### Step 3: Create New Record Types

**Poll:**
1. Click "+ Add Record Type"
2. Name: `Poll`
3. Add all 8 fields listed above
4. Create indexes on: `creatorID`, `createdAt`, `endsAt`, `isActive`

**PollVote:**
1. Click "+ Add Record Type"
2. Name: `PollVote`
3. Add all 6 fields listed above
4. Create indexes on: `pollID`, `voterID`, `votedForID`

**PollRevealPurchase:**
1. Click "+ Add Record Type"
2. Name: `PollRevealPurchase`
3. Add all 3 fields listed above
4. Create compound index on `userID` + `pollID`

### Step 4: Deploy to Production

1. Test in Development environment first
2. Click "Deploy Schema Changes"
3. Confirm deployment to Production

---

## ✅ Verification

After deployment, verify each record type has:
- ✅ All fields present
- ✅ Correct data types
- ✅ Indexes created
- ✅ Queryable/Sortable set correctly

---

## 🔍 Query Examples

### Fetch Active Polls
```swift
let predicate = NSPredicate(format: "isActive == 1 AND endsAt > %@", Date() as CVarArg)
```

### Get Poll Votes for User
```swift
let predicate = NSPredicate(format: "votedForID == %@", userID)
```

### Check Poll Reveal Purchase
```swift
let predicate = NSPredicate(format: "pollID == %@ AND userID == %@", pollID, userID)
```

---

## 🎯 Ready for Implementation

Once CloudKit schema is updated, the app code will:
- ✅ Save/load all new fields
- ✅ Create polls and votes
- ✅ Track purchases
- ✅ Award points correctly
- ✅ Handle ghost attacks

**Estimated Setup Time: 30 minutes**

