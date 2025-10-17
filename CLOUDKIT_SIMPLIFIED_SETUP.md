# ☁️ **CloudKit Setup - Simplified Version (Gossip Only)**

## 🎯 **What You Need**

For the simplified app with **only Gossip Reveal IAP**, you need:

1. ✅ **User** (already exists)
2. ✅ **Drop** (already exists)
3. ☁️ **GossipPost** (NEW)
4. ☁️ **GossipReply** (NEW)
5. ☁️ **GossipReveal** (NEW)

**That's it!** No FartAttack, no ReferralCredit, no complexity.

---

## 📝 **STEP-BY-STEP SETUP**

### **1. Open CloudKit Dashboard**
1. Go to: https://icloud.developer.apple.com/
2. Sign in with your Apple Developer account
3. Select your app: **TheDailyPoop** (iCloud.com.poopdrop.app)
4. Click **"Schema"** → **"Production"** (or Development for testing)

---

### **2. Create GossipPost Record Type**

#### **Click "+" to add new Record Type:**
**Record Type Name:** `GossipPost`

#### **Add these fields:**

| Field Name | Type | Settings |
|------------|------|----------|
| `id` | String | Required |
| `posterID` | String | Required, **Queryable** ✅ |
| `posterUsername` | String | Required |
| `text` | String | Required |
| `mentionedUserIDs` | String List | Optional |
| `mentionedUsernames` | String List | Optional |
| `createdAt` | Date/Time | Required, **Sortable** ✅ |
| `expiresAt` | Date/Time | Required |
| `isAnonymous` | Int64 | Required (1 or 0) |
| `reactions` | String | Optional (JSON) |
| `viewCount` | Int64 | Default: 0 |
| `replyCount` | Int64 | Default: 0 |
| `revealedBy` | String List | Optional |

#### **Indexes:**
- ✅ **Queryable:** `posterID`
- ✅ **Sortable:** `createdAt` (descending)

#### **Why These Fields:**
- `posterID`: Who posted it (hidden until revealed)
- `text`: The gossip content
- `mentionedUserIDs`: For notifications ("Someone mentioned you!")
- `createdAt`: Sort by newest first
- `expiresAt`: Gossip expires in 24 hours
- `revealedBy`: Track who paid to reveal (prevent double-charging)

---

### **3. Create GossipReply Record Type**

#### **Click "+" to add new Record Type:**
**Record Type Name:** `GossipReply`

#### **Add these fields:**

| Field Name | Type | Settings |
|------------|------|----------|
| `id` | String | Required |
| `originalGossipID` | String | Required, **Queryable** ✅ |
| `replyText` | String | Required |
| `replierID` | String | Required, **Queryable** ✅ |
| `replierUsername` | String | Required |
| `isAnonymous` | Int64 | Required (1 or 0) |
| `createdAt` | Date/Time | Required |

#### **Indexes:**
- ✅ **Queryable:** `originalGossipID` (to fetch replies for a gossip)
- ✅ **Queryable:** `replierID` (to track user's replies)

#### **Why These Fields:**
- `originalGossipID`: Links reply to parent gossip
- `replyText`: The reply content
- `replierID`: Who replied (can be anonymous)
- `createdAt`: Sort replies chronologically

---

### **4. Create GossipReveal Record Type**

#### **Click "+" to add new Record Type:**
**Record Type Name:** `GossipReveal`

#### **Add these fields:**

| Field Name | Type | Settings |
|------------|------|----------|
| `id` | String | Required |
| `gossipID` | String | Required, **Queryable** ✅ |
| `revealedToUserID` | String | Required, **Queryable** ✅ |
| `revealedPosterID` | String | Required |
| `revealedPosterUsername` | String | Required |
| `paidAmount` | Double | Required (1.99) |
| `revealedAt` | Date/Time | Required |

#### **Indexes:**
- ✅ **Queryable:** `gossipID` (check if already revealed)
- ✅ **Queryable:** `revealedToUserID` (user's reveals)

#### **Why These Fields:**
- `gossipID`: Which gossip was revealed
- `revealedToUserID`: Who paid to reveal
- `paidAmount`: Track revenue per reveal
- `revealedAt`: Analytics timestamp

---

## ✅ **VERIFICATION CHECKLIST**

After creating all 3 record types, verify:

### **GossipPost:**
- [ ] Record type exists
- [ ] `posterID` is **Queryable**
- [ ] `createdAt` is **Sortable**
- [ ] All required fields marked

### **GossipReply:**
- [ ] Record type exists
- [ ] `originalGossipID` is **Queryable**
- [ ] `replierID` is **Queryable**
- [ ] All required fields marked

### **GossipReveal:**
- [ ] Record type exists
- [ ] `gossipID` is **Queryable**
- [ ] `revealedToUserID` is **Queryable**
- [ ] All required fields marked

---

## 🧪 **TESTING IN DEVELOPMENT**

### **1. Switch to Development Schema:**
- In CloudKit Dashboard, switch from "Production" to "Development"
- Create the same 3 record types in Development
- Test all queries before deploying to Production

### **2. Test Queries:**
```swift
// Test 1: Post gossip
let gossip = GossipPost(
    posterID: currentUser.id,
    posterUsername: currentUser.username,
    text: "Test gossip",
    mentionedUserIDs: [],
    mentionedUsernames: [],
    isAnonymous: true
)
await GossipManager.shared.postGossip(gossip)

// Test 2: Load today's gossip
await GossipManager.shared.loadTodaysGossip()

// Test 3: Reveal sender (after IAP purchase)
await GossipManager.shared.revealSender(gossipID: "...", currentUser: user)
```

### **3. Verify Data:**
- Open CloudKit Dashboard
- Go to "Data" tab
- Select "GossipPost" record type
- Should see test records

---

## 🚨 **COMMON ERRORS & FIXES**

### **Error 1:** "Did not find record type: GossipPost"
**Fix:** You're in the wrong environment
- Check if you're in Development vs Production
- Make sure schema is deployed

### **Error 2:** "invalid attempt to set value type EMPTY_LIST"
**Fix:** Code tries to save empty arrays on new records
- Our code already handles this (only saves if not empty)
- If you see this, check `GossipPost.toCKRecord()`

### **Error 3:** "Cannot query field: posterID"
**Fix:** Field not marked as Queryable
- Go to CloudKit Dashboard
- Edit `GossipPost` record type
- Check "Queryable" for `posterID`
- Save and deploy

---

## 🔄 **DEPLOYING TO PRODUCTION**

### **When You're Ready:**
1. Test thoroughly in Development
2. Go to CloudKit Dashboard → Production
3. Create the same 3 record types
4. Set up indexes (Queryable/Sortable)
5. Deploy schema changes
6. **⚠️ WARNING:** Production schema changes are permanent!

### **Migration Note:**
- Existing `User` and `Drop` records are unaffected
- New gossip features work alongside existing drops
- No data migration needed

---

## 📊 **ANALYTICS QUERIES (Optional)**

Once you have data, you can query for analytics:

### **Total Gossip Posts:**
```sql
COUNT(GossipPost)
```

### **Total Reveals (Revenue):**
```sql
COUNT(GossipReveal) × $1.99 = Total Revenue
```

### **Top Gossip Creators:**
```sql
SELECT posterID, COUNT(*) 
FROM GossipPost 
GROUP BY posterID 
ORDER BY COUNT DESC
```

### **Reveal Conversion Rate:**
```sql
(COUNT(GossipReveal) / COUNT(GossipPost)) × 100 = % Conversion
```

---

## ✅ **YOU'RE DONE!**

Once you've:
1. ✅ Created all 3 record types
2. ✅ Set up indexes (Queryable/Sortable)
3. ✅ Tested in Development
4. ✅ Deployed to Production

**Your CloudKit is ready for launch!** 🚀

The simplified app with only Gossip Reveal is now fully operational.

---

## 📞 **NEED HELP?**

If you see any errors in the app:
1. Check Xcode console for exact error message
2. Verify record type names match exactly (case-sensitive)
3. Confirm indexes are set up
4. Test in Development first

**Most common fix:** Just check "Queryable" on the right fields! ✅

