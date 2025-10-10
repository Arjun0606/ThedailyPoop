# ⭐ Premium Fart Pack - In-App Purchase Setup
## Version 1.02

---

## 🎯 Overview

**ONE premium fart pack** at **$1.99 USD** with professional studio quality sound from Epidemic Sound.

Simple, clean, focused.

---

## 📦 The Packs

### 1. Classic Pack (FREE - Default)
- Always unlocked
- 2 sounds included
- No IAP needed

### 2. Premium Pack ($1.99) 
- **Product ID**: `com.thedailypoop.fartpack.premium`
- **1 sound**: "The Epic Blast" (4 seconds of legendary audio)
- **Description**: Professional studio quality from Epidemic Sound
- **Type**: Consumable IAP

---

## 🚀 Step 1: Create IAP in App Store Connect (10 minutes)

### Go to App Store Connect

1. Visit [appstoreconnect.apple.com](https://appstoreconnect.apple.com/)
2. Click **"My Apps"**
3. Select **"TheDailyPoop"**
4. Click **"In-App Purchases"** in sidebar
5. Click **"+"** to create new

---

### Create Premium Pack Product

#### Type Selection
- Select: **Consumable**
- Click **"Create"**

#### Reference Name
```
Premium Fart Pack
```

#### Product ID
```
com.thedailypoop.fartpack.premium
```
⚠️ **CRITICAL**: Must match exactly (case-sensitive)

---

### Pricing

1. Click **"Add Pricing"**
2. Select **"All Territories"** (or choose specific ones)
3. Price: **Tier 3** ($1.99 USD)
4. Click **"Next"** and **"Confirm"**

---

### Localization (English - U.S.)

#### Display Name
```
Premium Pack
```

#### Description
```
Professional quality fart sound - Legendary and epic! ⭐

Includes:
• The Epic Blast - 4 seconds of professional studio quality

Recorded at Epidemic Sound's studios - this is the fart sound you've been waiting for. Long, dramatic, and absolutely unforgettable.

Perfect for making your drops legendary!
```

---

### Review Information

**Screenshot** (Optional):
- 640×920 pixels
- Show the Premium Pack card with the ⭐ emoji
- Or leave blank - not required

**Review Notes**:
```
Premium fart sound pack ($1.99) for comedic effect when users log bathroom activities. Professional quality audio from Epidemic Sound library.
```

---

### Save & Submit

1. Click **"Save"**
2. Status should show **"Ready to Submit"**
3. ✅ Done!

⏰ **Wait 2-3 hours** for Apple to process the IAP before testing

---

## 🗄️ Step 2: CloudKit Schema (10 minutes)

### Go to CloudKit Dashboard

1. Visit [icloud.developer.apple.com/dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container: `iCloud.com.poopdrop.app`
3. Click **"Schema"** → **"Record Types"**
4. Click **"+"** to add new type

---

### Create UserFartPackPurchases Record Type

**Record Type Name**: `UserFartPackPurchases`

**Database**: **Private Database**

#### Add 3 Fields:

| Field Name | Type | Indexed |
|------------|------|---------|
| userID | String | ✅ Yes |
| purchasedPackIDs | Bytes | ❌ No |
| lastUpdated | Date/Time | ✅ Yes |

---

### Set Permissions

**Security Roles**:
- **Creator**: Readable ✅, Writable ✅
- **World**: No access

This is a **Private Database** record, so only the user can read/write their own purchases.

---

### Save

1. Click **"Save"**
2. ✅ Record type created!

---

## 🧪 Step 3: Test in Xcode (20 minutes)

### Enable StoreKit Testing

1. In Xcode, click your scheme name
2. Select **"Edit Scheme..."**
3. Go to **"Run"** → **"Options"** tab
4. **StoreKit Configuration**: Select `Configuration.storekit`
5. Enable **"Debug StoreKit"**
6. Click **"Close"**

---

### Test the Flow

1. **Build & Run** in Simulator
2. Open the **Shop** tab (cart icon 🛒)
3. See Premium Pack with $1.99 price
4. Tap the card
5. Modal opens showing "The Epic Blast" sound
6. Tap play button to preview
7. Tap **"Purchase for $1.99"**
8. In sandbox, confirm (no real charge)
9. Pack should unlock instantly
10. Go to drop composer
11. Tap "Fart Sound" section
12. Select "The Epic Blast" from Premium Pack
13. Create a drop
14. **Listen for the epic 4-second blast!** 🔊

✅ If all works, you're ready for TestFlight!

---

## 📱 Step 4: TestFlight Testing (30 minutes)

### Create Sandbox Test Account

1. In App Store Connect: **Users and Access** → **Sandbox Testers**
2. Click **"+"**
3. Create test account:
   - Email: `test@yourdomain.com` (fake is fine)
   - Password: Something memorable
   - First/Last Name: Test User
   - Country: United States
4. Click **"Create"**

---

### Prepare TestFlight Build

1. In Xcode: **Product** → **Archive**
2. Wait for archive to complete
3. Click **"Distribute App"**
4. Select **"App Store Connect"**
5. Follow prompts to upload
6. Wait 10-30 minutes for processing

---

### Test on Real Device

1. On your iPhone/iPad:
   - **Settings** → **App Store** → Sign out
   - Sign in with sandbox test account
2. Install app from **TestFlight**
3. Open app
4. Go to Shop tab
5. Purchase Premium Pack
   - Uses sandbox account (no real charge)
6. Verify purchase completes
7. Verify sound plays
8. Test **"Restore Purchases"** button

---

## 🎯 Step 5: Production Checklist

### Before App Store Submission

- [ ] IAP product status: **"Ready to Submit"**
- [ ] Product ID matches code exactly
- [ ] Price set to $1.99 USD
- [ ] CloudKit record type created
- [ ] Tested in sandbox (Xcode)
- [ ] Tested in TestFlight
- [ ] Restore Purchases works
- [ ] Sound plays correctly
- [ ] No crashes or errors

---

### App Store Submission

1. In App Store Connect: **App Store** → **+ Version or Platform**
2. Version: **1.02**
3. **What's New**:
   ```
   🎵 NEW: Premium Fart Pack!
   
   Unlock legendary fart sound for your drops. Professional studio quality audio - make your bathroom moments epic!
   
   Also:
   • New Shop tab to browse sound packs
   • Improved drop composer
   • Bug fixes and performance improvements
   ```

4. Submit for review
5. **Review Notes**:
   ```
   Version 1.02 introduces Premium Fart Pack - a $1.99 in-app purchase 
   that unlocks professional quality fart sound for comedic effect. 
   Sounds are from Epidemic Sound's licensed library.
   
   Users can preview sounds before purchasing. Free Classic Pack 
   always available.
   ```

---

## 💰 Pricing Breakdown

**Retail Price**: $1.99 USD  
**Apple's Cut (30%)**: -$0.60  
**Your Revenue**: **$1.39 per purchase**

### Revenue Targets

| Users | 5% Conv. | Revenue |
|-------|----------|---------|
| 10K | 500 sales | $695 |
| 50K | 2,500 sales | $3,475 |
| 100K | 5,000 sales | $6,950 |

---

## 🐛 Troubleshooting

### "Product not found" error
**Solution**: Wait 2-3 hours after creating IAP in App Store Connect

### Purchase completes but doesn't unlock
**Solution**: 
1. Check CloudKit schema is correct
2. Verify `UserFartPackPurchases` record saves
3. Try "Restore Purchases"

### Sound doesn't play
**Solution**:
1. Check volume on device
2. Verify `fart_long_epidemic.wav` is in Sounds folder
3. Check file is added to Xcode target

### "Invalid Product ID"
**Solution**: 
1. Verify: `com.thedailypoop.fartpack.premium`
2. Check capitalization and spelling
3. Clean build folder (Cmd+Shift+K)
4. Wait for App Store Connect to sync

---

## 📊 Analytics (Recommended)

Track these events:

```swift
// Shop Events
"shop_opened"
"premium_pack_viewed"
"sound_previewed"

// Purchase Events
"purchase_initiated"
"purchase_completed" (revenue: 1.99)
"purchase_failed" (error: ...)

// Usage Events
"premium_sound_selected"
"premium_sound_played_in_drop"
```

---

## 🎉 Launch Strategy

### Week 1: Soft Launch
- Ship to existing users
- Don't announce yet
- Monitor conversion rate
- Fix any bugs

### Week 2: Announce
**Tweet**:
```
NEW: Premium Fart Pack ⭐

One legendary sound. 
4 seconds of professional studio quality.
$1.99.

Make your drops epic.

[App Store Link]
```

**TikTok**: 
- Record yourself using the sound
- "POV: You unlocked the Premium Fart Pack"
- Show reactions

---

## ✅ Quick Checklist

### Setup (40 minutes)
- [ ] Create IAP in App Store Connect (10 min)
- [ ] Create CloudKit record type (10 min)
- [ ] Test in Xcode sandbox (20 min)

### Testing (1 hour)
- [ ] Create sandbox test account
- [ ] Archive and upload to TestFlight
- [ ] Test on real device
- [ ] Verify purchase flow
- [ ] Verify sound playback

### Deploy
- [ ] Submit v1.02 to App Store
- [ ] Monitor first purchases
- [ ] Track conversion rate
- [ ] Respond to user feedback

---

## 🎯 Success Metrics

### Week 1 Goals
- 25+ purchases
- 3%+ conversion rate
- 0 critical bugs
- 4+ star rating maintained

### Month 1 Goals
- 200+ purchases
- $400+ revenue
- 5%+ conversion rate
- Consider adding Pack 2

---

**Ready to launch?** Follow this guide step-by-step and you'll be live in ~2 hours! 🚀⭐

---

**Last Updated**: October 7, 2025  
**Version**: 1.02 - Premium Pack  
**Status**: Ready for App Store Connect setup

