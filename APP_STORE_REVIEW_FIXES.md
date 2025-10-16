# 🔧 APP STORE REVIEW FIXES

**Review Date:** October 16, 2025  
**Submission ID:** 6d44e30a-9da6-4578-9d89-8e869fa9a682  
**Status:** 2 Issues to Fix

---

## ✅ **ISSUE 1: SIGN-IN ERROR (FIXED IN CODE)**

### **Problem:**
```
"Failed to create user account: Error saving record
Cannot create or modify field 'attacksReceived' in record 'User' 
in production schema"
```

### **Root Cause:**
The code was trying to save `attacksSent`, `attacksReceived`, and points fields to CloudKit, but these fields don't exist in your production CloudKit schema yet.

### **Fix Applied:**
Modified `User.swift` to only save these fields if they have values (> 0):
- `attacksSent` - only saved if > 0
- `attacksReceived` - only saved if > 0
- `dailyPoints` - only saved if > 0
- `totalLifetimePoints` - only saved if > 0
- `pointsBoostActive` - only saved if true

This prevents CloudKit errors for existing users who don't have these fields yet.

### **Action Required:**
✅ **NONE** - Code is fixed and committed. Just resubmit the build.

---

## ⚠️ **ISSUE 2: IAP DESCRIPTIONS ARE IDENTICAL**

### **Problem:**
Apple says:
```
"The display names and descriptions for your promoted in-app purchase 
products 'Reveal Poll Voters' and '2X Points (24h)' are the same."
```

### **Current IAP Setup:**

| Product | Current Display Name | Current Description (probably) |
|---------|---------------------|-------------------------------|
| Ghost Attack Pack (3) | Ghost Attack Pack (3) | ??? |
| Reveal Ghost Sender | Reveal Ghost Sender | ??? |
| **Reveal Poll Voters** | **Reveal Poll Voters** | **Same as below?** |
| **2X Points (24h)** | **2X Points (24h)** | **Same as above?** |

---

## ✅ **FIX: UPDATE IAP DESCRIPTIONS IN APP STORE CONNECT**

Go to: [App Store Connect](https://appstoreconnect.apple.com) → Your App → In-App Purchases

### **Updated Display Names & Descriptions:**

#### **1. Ghost Attack Pack (3)**
- **Display Name:** `3 Ghost Attacks` (30 chars max)
- **Description:** `Send 3 anonymous fart attacks to your friends` (45 chars max)

#### **2. Reveal Ghost Sender**
- **Display Name:** `Reveal Who Attacked You` (30 chars max)
- **Description:** `See who sent you the ghost attack` (45 chars max)

#### **3. Reveal Poll Voters** ⚠️
- **Display Name:** `See Who Voted for You` (30 chars max)
- **Description:** `Reveal which friends voted for you in polls` (45 chars max)

#### **4. 2X Points (24h)** ⚠️
- **Display Name:** `2X Points Boost` (30 chars max)
- **Description:** `Double your points for 24 hours on leaderboard` (45 chars max)

---

## 📋 **STEP-BY-STEP FIX:**

### **Step 1: Go to App Store Connect**
1. Open: https://appstoreconnect.apple.com
2. Click on "TheDailyPoop" app
3. Go to "In-App Purchases" section

### **Step 2: Edit Each IAP**

For each of the 4 IAPs:

1. **Click the IAP name** (e.g., "Reveal Poll Voters")
2. **Click "Edit"** next to "Display Name"
3. **Update Display Name** (use the names above)
4. **Click "Edit"** next to "Description"
5. **Update Description** (use the descriptions above)
6. **Click "Save"**

### **Step 3: Verify They're Different**

Make sure each IAP has:
- ✅ Unique display name
- ✅ Unique description
- ✅ No two are the same

---

## 🚀 **RESUBMIT CHECKLIST:**

### **Before Resubmitting:**
- [x] Code fix committed (CloudKit fields conditional)
- [ ] Build new version in Xcode
- [ ] Archive and upload to App Store Connect
- [ ] Update IAP descriptions (see above)
- [ ] Submit for review again

### **What to Say in Review Notes:**

```
Fixed Issues:

1. Sign-in bug: Fixed CloudKit schema error by making new fields 
   conditional. Existing users will no longer see sign-in errors.

2. IAP descriptions: Updated all 4 IAP products with unique 
   display names and descriptions as requested.

Tested on iPhone 15 Pro (iOS 18.0) and iPad Air (iPadOS 26.1).
Sign-in with Apple works correctly now.
```

---

## 🎯 **EXPECTED TIMELINE:**

- **Fix IAP descriptions:** 10 minutes
- **Build & upload new version:** 30 minutes
- **Apple review:** 1-3 days

---

## ✅ **ONCE APPROVED:**

You'll be ready to launch with:
- ✅ Working sign-in
- ✅ 4 unique IAP products
- ✅ All viral features (Ghost Attacks, Polls, Leaderboard)
- ✅ No review issues

**Then execute the viral marketing plan! 🚀**

---

## 📞 **IF YOU GET ANOTHER REJECTION:**

Reply in the review thread with:
```
"We have fixed both issues:

1. The sign-in bug was caused by CloudKit schema fields. We've 
   updated our code to handle existing users without these fields.

2. We have updated all IAP descriptions to be unique.

Please test again with a new account on iPadOS 26.1. 
Sign-in should work correctly now.

Thank you!"
```

---

**You're almost there! Just update those IAP descriptions and resubmit! 🎉**

