# 🚀 Plopper TestFlight Deployment Guide

## 📋 Pre-Flight Checklist

### ✅ Current App Configuration
- **App Name:** Plopper
- **Bundle ID:** `com.plopperapp.app`
- **Version:** 1.0
- **Build:** 1
- **Team ID:** UDGYWMWVJS

---

## 🔧 Step 1: Configure Xcode Project

### 1.1 Open Xcode
```bash
cd /Users/arjun/plopperapp
open Plopper.xcodeproj
```

### 1.2 Configure Signing & Capabilities
1. Click on **Plopper** (blue icon) in the Project Navigator
2. Select **Plopper** target
3. Go to **Signing & Capabilities** tab
4. **Automatically manage signing:** ✅ Checked
5. **Team:** Select your Apple Developer account (UDGYWMWVJS)
6. Ensure these capabilities are enabled:
   - ✅ Push Notifications
   - ✅ iCloud (CloudKit)
   - ✅ Sign in with Apple
   - ✅ Background Modes (Remote notifications)

### 1.3 Set Build Configuration
1. Go to **Product** → **Scheme** → **Edit Scheme**
2. Select **Archive** on the left
3. Build Configuration: **Release**
4. Click **Close**

---

## 📱 Step 2: Create App in App Store Connect

### 2.1 Go to App Store Connect
1. Visit: https://appstoreconnect.apple.com
2. Click **My Apps**
3. Click the **+** button → **New App**

### 2.2 Fill in App Information
- **Platform:** iOS
- **Name:** Plopper
- **Primary Language:** English (U.S.)
- **Bundle ID:** `com.plopperapp.app` (select from dropdown)
- **SKU:** `plopperapp-2025` (or any unique identifier)
- **User Access:** Full Access

### 2.3 Create App Record
Click **Create** to finish setting up the app record.

---

## 🎨 Step 3: Prepare App Store Assets

### 3.1 App Icon (Already created! ✅)
- Located in: `Plopper/Assets.xcassets/AppIcon.appiconset/`
- Size: 1024×1024 PNG

### 3.2 Screenshots Required
You'll need screenshots for:
- **6.7" iPhone (iPhone 15 Pro Max):** 1290×2796
- **6.5" iPhone (iPhone 14 Plus):** 1242×2688

**How to generate:**
1. Run app on iPhone 15 Pro Max Simulator
2. Navigate to key screens:
   - Welcome/Login screen
   - Main feed with poop drops
   - Map view with pins
   - Profile with stats & badges
   - Friends leaderboard
3. Press `Cmd + S` to save screenshots
4. Screenshots saved to Desktop

### 3.3 App Privacy Details
**Privacy Policy URL:** https://plopperapp.app/privacy

**Data Collection:**
- ✅ Location (precise location for poop drops)
- ✅ Health & Fitness (bowel movement tracking)
- ✅ User Content (poop drops, reactions)
- ✅ Identifiers (Apple ID for Sign in with Apple)

---

## 🏗️ Step 4: Archive & Upload to TestFlight

### 4.1 Select Device (in Xcode)
1. In the top toolbar, click the device dropdown
2. Select **Any iOS Device (arm64)**

### 4.2 Archive the App
1. Go to **Product** → **Archive**
2. Wait for the build to complete (2-5 minutes)
3. The **Organizer** window will open automatically

### 4.3 Validate the Archive
1. In Organizer, select your archive
2. Click **Validate App**
3. Choose your Team: **UDGYWMWVJS**
4. App Store Distribution: **Automatic**
5. Click **Next** → **Validate**
6. Wait for validation (1-2 minutes)
7. ✅ Should see "Validation Successful"

### 4.4 Distribute to App Store Connect
1. Click **Distribute App**
2. Select **App Store Connect**
3. Click **Next**
4. Upload method: **Upload**
5. App Store distribution options:
   - ✅ Upload your app's symbols (recommended)
   - ✅ Manage Version and Build Number (Xcode will handle this)
6. Click **Next**
7. Re-sign: **Automatically manage signing**
8. Click **Upload**
9. Wait for upload (5-10 minutes depending on internet speed)

### 4.5 Confirm Upload
You'll see: **"Upload Successful - The build has been uploaded to App Store Connect"**

---

## 🧪 Step 5: Configure TestFlight

### 5.1 Go to TestFlight Tab
1. In App Store Connect, open your Plopper app
2. Click **TestFlight** tab (top navigation)
3. Wait for build to process (10-60 minutes)
   - You'll get an email when processing is complete
   - Status will change from "Processing" to "Ready to Submit"

### 5.2 Add Test Information
Once build is ready:

1. Click on your build (e.g., **1.0 (1)**)
2. Fill in **Test Information:**
   - **What to Test:**
     ```
     Welcome to Plopper Beta! 💩
     
     Please test:
     - Sign in with Apple
     - Log your first poop drop
     - View it on the map
     - Add friends and see their drops
     - React to poop drops with emojis
     - Check your stats & badges
     - Share your stats to social media
     
     Known features:
     - AdMob ads (you'll see test ads)
     - Map pins persist for 3 days
     - Streak tracking with constipation counter
     - Friend leaderboard
     
     Please report any bugs or issues!
     ```
   
   - **Feedback Email:** karjunvarma2001@gmail.com
   - **Marketing URL:** https://plopperapp.app (optional)
   - **Privacy Policy URL:** https://plopperapp.app/privacy

3. Click **Save**

### 5.3 Export Compliance
1. Under **Export Compliance**, click **Provide**
2. Answer questions:
   - **Does your app use encryption?** No (or Yes if using HTTPS only)
   - If Yes, select: **Only uses encryption for HTTPS**
3. Click **Start Internal Testing**

---

## 👥 Step 6: Add Testers

### 6.1 Internal Testers (You + Team)
1. Go to **TestFlight** → **Internal Testing**
2. Click **App Store Connect Users**
3. Click **+** to add testers
4. Add: karjunvarma2001@gmail.com
5. Click **Add**

### 6.2 Enable Testing
1. Toggle **Enable** next to your internal group
2. Testers will receive email invitation immediately

### 6.3 External Testers (Optional - for public beta)
1. Go to **TestFlight** → **External Testing**
2. Click **+** to create a new group
3. Name: "Public Beta"
4. Add testers via email or public link
5. Click **Submit for Review** (takes 1-2 days for Apple approval)

---

## 📲 Step 7: Install on Your Device

### 7.1 Install TestFlight App
1. On your iPhone, download **TestFlight** from App Store
2. Sign in with your Apple ID (karjunvarma2001@gmail.com)

### 7.2 Accept Invite
1. Check your email for TestFlight invite
2. Tap **View in TestFlight** or **Redeem**
3. TestFlight app opens → tap **Accept**
4. Tap **Install**

### 7.3 Test the App
Launch Plopper and test all features! 🎉

---

## 🔄 Step 8: Submitting Updates

### When you make changes:

1. **Increment Build Number** (in Xcode):
   - Select Plopper project → Target → General
   - Build: `1` → `2`, `3`, etc.
   - Keep Version at `1.0` for now

2. **Archive & Upload** (repeat Step 4):
   ```
   Product → Archive → Distribute App
   ```

3. **Update "What to Test"** in TestFlight with new features/fixes

4. **Testers auto-update** when they open TestFlight

---

## 🎯 Step 9: Prepare for Production Release

### When ready to launch on App Store:

1. **Complete App Information:**
   - Description (marketing copy)
   - Keywords
   - Screenshots for all device sizes
   - App category: Health & Fitness or Social Networking
   - Content rating
   - Copyright info

2. **Submit for Review:**
   - Go to **App Store** tab (not TestFlight)
   - Fill in all required fields
   - Click **Submit for Review**
   - Wait 1-3 days for Apple review

---

## 🐛 Common Issues & Fixes

### ❌ "Invalid Bundle" Error
**Solution:** Ensure Bundle ID matches App Store Connect exactly (`com.plopperapp.app`)

### ❌ "Missing Compliance" Error
**Solution:** Answer Export Compliance questions in TestFlight

### ❌ Code Signing Error
**Solution:** 
1. Delete all certificates in Xcode Preferences → Accounts
2. Re-download profiles
3. Clean Build Folder (`Cmd + Shift + K`)
4. Archive again

### ❌ Build Stuck in "Processing"
**Solution:** Wait up to 60 minutes. Check email for any issues from Apple.

### ❌ AdMob Not Working in TestFlight
**Expected:** Test ads will show. Real ads require:
1. App published to App Store
2. AdMob app linked to App Store listing
3. Payment info added in AdMob

---

## 📞 Support

### Apple Developer Support:
- https://developer.apple.com/support/
- Phone: 1-800-633-2152

### AdMob Support:
- https://support.google.com/admob

### App Issues:
- Email: karjunvarma2001@gmail.com
- Twitter: @Arjun06061

---

## ✅ Quick Command Summary

```bash
# Open Xcode
open Plopper.xcodeproj

# In Xcode:
# 1. Select "Any iOS Device (arm64)" from device dropdown
# 2. Product → Archive
# 3. Validate App
# 4. Distribute App → App Store Connect → Upload
# 5. Wait for email confirmation
# 6. Configure TestFlight in App Store Connect
# 7. Install on device via TestFlight app
```

---

## 🎉 You're Ready!

Your app is now:
- ✅ Code complete
- ✅ CloudKit integrated
- ✅ AdMob configured
- ✅ Notifications working
- ✅ Share feature working
- ✅ All bugs fixed

**Time to launch! 🚀💩**

---

**Version:** 1.0  
**Build:** 1  
**Last Updated:** September 30, 2025
