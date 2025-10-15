# ☁️ CLOUDKIT SETUP GUIDE - STEP BY STEP

## 🎯 **WHAT YOU NEED TO ADD:**

You need to add **2 new record types** to CloudKit:
1. **Poll** - For daily poll questions
2. **PollVote** - For tracking votes

---

## 📋 **STEP-BY-STEP INSTRUCTIONS:**

### **Step 1: Open CloudKit Dashboard**

1. Go to: **https://icloud.developer.apple.com/**
2. Sign in with your Apple Developer account
3. Click on **CloudKit Dashboard**
4. Select your container: **`iCloud.com.poopdrop.app`**
   - (Or whatever your container ID is)

---

### **Step 2: Add "Poll" Record Type**

1. In the left sidebar, click **"Schema"**
2. In the **"Record Types"** section, click the **"+"** button (top right)
3. Enter record type name: **`Poll`**
4. Click **"Create"**

Now add the following fields by clicking **"Add Field"** for each:

#### **Poll Fields:**

| Field Name | Type | Indexed | Queryable | Sortable |
|------------|------|---------|-----------|----------|
| **creatorID** | String | ☑️ Yes | ☑️ Yes | ☐ No |
| **creatorUsername** | String | ☐ No | ☐ No | ☐ No |
| **questionText** | String | ☐ No | ☐ No | ☐ No |
| **pollType** | String | ☐ No | ☐ No | ☐ No |
| **createdAt** | Date/Time | ☑️ Yes | ☑️ Yes | ☑️ Yes |
| **endsAt** | Date/Time | ☑️ Yes | ☑️ Yes | ☑️ Yes |
| **isActive** | Int(64) | ☑️ Yes | ☑️ Yes | ☐ No |
| **totalVotes** | Int(64) | ☐ No | ☐ No | ☐ No |

**For each field:**
1. Click **"Add Field"**
2. Enter the **Field Name** (e.g., "creatorID")
3. Select the **Type** (e.g., "String")
4. Check **Indexed** if marked Yes above
5. Check **Queryable** if marked Yes above
6. Check **Sortable** if marked Yes above
7. Click **"Save"**

8. After adding all fields, click **"Save"** at the bottom

---

### **Step 3: Add "PollVote" Record Type**

1. Still in **"Schema"** → **"Record Types"**
2. Click the **"+"** button again
3. Enter record type name: **`PollVote`**
4. Click **"Create"**

Now add these fields:

#### **PollVote Fields:**

| Field Name | Type | Indexed | Queryable | Sortable |
|------------|------|---------|-----------|----------|
| **pollID** | String | ☑️ Yes | ☑️ Yes | ☐ No |
| **voterID** | String | ☑️ Yes | ☑️ Yes | ☐ No |
| **voterUsername** | String | ☐ No | ☐ No | ☐ No |
| **votedForID** | String | ☑️ Yes | ☑️ Yes | ☐ No |
| **votedForUsername** | String | ☐ No | ☐ No | ☐ No |
| **timestamp** | Date/Time | ☑️ Yes | ☑️ Yes | ☑️ Yes |

**For each field:**
1. Click **"Add Field"**
2. Enter the **Field Name**
3. Select the **Type**
4. Check **Indexed**, **Queryable**, **Sortable** as marked
5. Click **"Save"**

6. After adding all fields, click **"Save"** at the bottom

---

### **Step 4: Verify Existing Record Types**

While you're here, make sure these existing record types have the required fields:

#### **User Record Type - Add These If Missing:**

| Field Name | Type | Notes |
|------------|------|-------|
| invitedBy | String | *(Removed - skip this)* |
| referralRewarded | Int(64) | *(Removed - skip this)* |
| dailyPoints | Int(64) | Should exist |
| dailyPointsResetDate | Date/Time | Should exist |
| totalLifetimePoints | Int(64) | Should exist |
| pointsBoostActive | Int(64) | Should exist |
| pointsBoostExpiresAt | Date/Time | Should exist |

If any are missing, add them the same way (Add Field → Name → Type → Save).

---

### **Step 5: Deploy to Production**

1. After adding all record types and fields
2. At the top of the CloudKit Dashboard, you'll see a banner
3. Click **"Deploy Schema Changes"**
4. Select **"Production"**
5. Click **"Deploy"**
6. Wait for deployment to complete (usually 1-2 minutes)

---

## ✅ **VERIFICATION CHECKLIST:**

After setup, verify:

- [ ] **Poll** record type exists with 8 fields
- [ ] **PollVote** record type exists with 6 fields
- [ ] **User** record type has points-related fields
- [ ] Schema deployed to **Production**
- [ ] No error messages in CloudKit Dashboard

---

## 🧪 **TEST YOUR SETUP:**

After CloudKit is configured:

1. **Run the app**
2. **Go to Poll tab** (📊 icon)
3. Should see: "Loading today's poll..."
4. If no poll exists, app will create one automatically
5. **Vote for 3 friends**
6. **Submit**
7. ✅ Should see: "You've voted!"

**Check CloudKit Dashboard:**
1. Go to **"Data"** tab
2. Select **"Public Database"**
3. Select **"Poll"** record type
4. ✅ Should see 1 Poll record
5. Select **"PollVote"** record type
6. ✅ Should see 3 PollVote records (your votes)

---

## ⚠️ **COMMON ISSUES:**

### **Issue 1: "Record type not found"**
**Solution:** Make sure you deployed to Production, not just Development

### **Issue 2: "Permission denied"**
**Solution:** 
1. Go to **"Security Roles"**
2. Select **"Public"** database
3. Make sure **"World"** can:
   - ✅ Create records
   - ✅ Read records
   - ✅ Write records

### **Issue 3: "Field not found"**
**Solution:** Double-check field names match exactly (case-sensitive):
- `pollID` not `PollID` or `poll_id`
- `creatorID` not `CreatorID`

---

## 📱 **CONTAINER ID:**

Your app uses: **`iCloud.com.poopdrop.app`**

If you changed it, update these files:
- `PollManager.swift` (line 29)
- `CloudKitManager.swift`

Search for: `iCloud.com.poopdrop.app` and replace if needed.

---

## 🎯 **AFTER CLOUDKIT SETUP:**

Once CloudKit is configured, you can test:

1. ✅ **Polls** - Daily voting works
2. ✅ **Poll Results** - Shows vote counts
3. ✅ **Poll Reveal IAP** - Shows who voted
4. ✅ **Points** - +25 for voting
5. ✅ **Leaderboard** - Updates with poll points

---

## 🚀 **READY TO TEST!**

After CloudKit setup:
1. ✅ Build and run app
2. ✅ Test all features (see `COMPREHENSIVE_TESTING_GUIDE.md`)
3. ✅ Submit to App Store!

---

**Need help? Common questions:**

**Q: Do I need to do this for Development AND Production?**
A: Deploy to **Production** only (Development is optional for testing)

**Q: Can I edit these fields later?**
A: Yes, but you can only ADD fields, not remove them in Production

**Q: What if I make a mistake?**
A: In Development, you can delete and recreate. In Production, you can only add.

---

**Start here:** https://icloud.developer.apple.com/

**Good luck! The app is almost ready to launch!** 🚀

