# 💨 Fart Packs In-App Purchase Setup Guide
## Version 1.02 Feature

---

## 📋 Overview

Fart Packs are consumable in-app purchases that unlock legendary fart sounds for users to play when dropping. Each pack costs **$1.99 USD** and contains 2-4 unique fart sounds.

### Available Fart Packs

1. **Classic Pack** (FREE - Default)
   - Quick Toot
   - The Long One

2. **Wet & Wild Pack** ($1.99)
   - Bubble Bath
   - Big Splash

3. **The Attacker Pack** ($1.99)
   - Fart Attack
   - The Epic Blast (Professional Epidemic Sound quality!)

4. **Silent But Deadly Pack** ($1.99)
   - The Whisper

---

## 🎯 Step 1: Create In-App Purchases in App Store Connect

### Log in to App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click on **"My Apps"**
3. Select **"TheDailyPoop"** (or your app name)
4. Click on **"In-App Purchases"** in the sidebar

### Create Each Fart Pack Product

You need to create **3 consumable IAP products** (one for each paid pack).

---

### Product 1: Wet & Wild Pack

#### Basic Information
1. Click **"+"** to create new IAP
2. Select **"Consumable"** (users can theoretically buy multiple times, though they only need one)
3. **Reference Name**: `Fart Pack - Wet & Wild`
4. **Product ID**: `com.thedailypoop.fartpack.wetandwild`
   - ⚠️ This MUST match the productID in `FartPack.swift`

#### Pricing
1. Click **"Add Pricing"**
2. Select all territories or specific ones
3. **Price**: Select **Tier 3** ($1.99 USD)
4. Save

#### Localization (English - U.S.)
1. **Display Name**: `Wet & Wild Pack`
2. **Description**:
   ```
   Dangerously moist fart sounds for the brave! 💦
   
   Includes:
   • Bubble Bath - Bubbly and suspicious
   • Big Splash - Houston, we have a problem
   
   Unlock these legendary sounds to play when you drop!
   ```

#### Review Information
1. **Screenshot**: Optional but recommended (640x920px showing the pack UI)
2. **Review Notes**: "Fart sound pack for comedic effect when users log bathroom activities"

---

### Product 2: The Attacker Pack

#### Basic Information
1. **Reference Name**: `Fart Pack - The Attacker`
2. **Product ID**: `com.thedailypoop.fartpack.attacker`

#### Pricing
- **Tier 3** ($1.99 USD)

#### Localization (English - U.S.)
1. **Display Name**: `The Attacker Pack`
2. **Description**:
   ```
   Weaponized fart sounds for maximum impact! ⚔️
   
   Includes:
   • Fart Attack - Lock and load!
   • The Epic Blast - Professional grade devastation
   
   Perfect for making a statement when you drop!
   ```

---

### Product 3: Silent But Deadly Pack

#### Basic Information
1. **Reference Name**: `Fart Pack - Silent But Deadly`
2. **Product ID**: `com.thedailypoop.fartpack.silentbutdeadly`

#### Pricing
- **Tier 3** ($1.99 USD)

#### Localization (English - U.S.)
1. **Display Name**: `Silent But Deadly Pack`
2. **Description**:
   ```
   Sneaky sounds for the stealthy pooper! 🤫
   
   Includes:
   • The Whisper - Barely audible, maximum damage
   
   More sounds coming in future updates!
   ```

---

## 🧪 Step 2: Testing with StoreKit Configuration

### Create StoreKit Configuration File (Already Done)

Your Xcode project should already have a `Configuration.storekit` file. If not:

1. In Xcode: **File** → **New** → **File**
2. Search for **"StoreKit Configuration File"**
3. Name it `Configuration.storekit`
4. Add your products:

```json
{
  "identifier" : "com.thedailypoop.fartpack.wetandwild",
  "type" : "Consumable",
  "reference_name" : "Fart Pack - Wet & Wild",
  "price" : 1.99,
  "family_shareable" : false
}
```

### Enable StoreKit Testing in Xcode

1. Select your scheme (e.g., **PoopDrop**)
2. **Edit Scheme** → **Run** → **Options**
3. **StoreKit Configuration**: Select `Configuration.storekit`
4. Enable **"Debug StoreKit"**

### Test Purchase Flow

1. Build and run on simulator or device
2. Navigate to **Shop** tab (new in v1.02)
3. Try purchasing a fart pack
4. Use sandbox test accounts (no real charges)

---

## 📱 Step 3: Verify Code Integration

### Check Product IDs Match

Open `PoopDrop/Models/FartPack.swift` and verify:

```swift
static let wetAndWildPack = FartPack(
    productID: "com.thedailypoop.fartpack.wetandwild", // ✅ Must match App Store Connect
    // ...
)
```

### Verify StoreKitManager Configuration

Open `PoopDrop/Managers/StoreKitManager.swift`:

```swift
private let fartPackProductIDs = [
    "com.thedailypoop.fartpack.wetandwild",
    "com.thedailypoop.fartpack.attacker",
    "com.thedailypoop.fartpack.silentbutdeadly"
]
```

### Test Sound Files Exist

Verify these files are in `PoopDrop/Sounds/`:
- ✅ `bubble_fart.wav`
- ✅ `big_splash.wav`
- ✅ `fart_attack.wav`
- ✅ `fart_long.wav`
- ✅ `fart_short.wav`

---

## 🔄 Step 4: CloudKit Schema Update

### Add New Record Type in CloudKit Dashboard

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container: `iCloud.com.poopdrop.app`
3. Go to **Schema** → **Record Types**
4. Click **"+"** to add new record type

#### Record Type: `UserFartPackPurchases`
- **Database**: Private Database

| Field Name | Field Type | Indexed | Required |
|------------|------------|---------|----------|
| userID | String | ✅ Yes | ✅ Yes |
| purchasedPackIDs | Bytes | ❌ No | ✅ Yes |
| lastUpdated | Date/Time | ✅ Yes | ✅ Yes |

**Security**:
- Creator: Readable, Writable

**Purpose**: Track which packs each user has purchased, synced across devices.

---

## 🚀 Step 5: TestFlight Testing

### Before Submitting to TestFlight

1. ✅ All IAP products created in App Store Connect
2. ✅ IAP products in "Ready to Submit" status
3. ✅ CloudKit schema updated with `UserFartPackPurchases`
4. ✅ Test purchases work in sandbox
5. ✅ Restore purchases works correctly
6. ✅ Sound files play correctly

### Create Sandbox Test Accounts

1. In App Store Connect: **Users and Access** → **Sandbox Testers**
2. Create 2-3 test accounts with different Apple IDs
3. Use these to test IAP on real devices

### TestFlight Build

1. Archive your app in Xcode
2. Upload to App Store Connect
3. Wait for processing
4. Add internal/external testers
5. Test purchases with sandbox accounts

---

## 📊 Step 6: Monitor After Launch

### Key Metrics to Track

1. **Conversion Rate**: % of users who purchase at least 1 pack
   - Target: 5-10% of active users
   
2. **Revenue Per User**: Average IAP revenue
   - Target: $0.15-0.30 per active user

3. **Most Popular Pack**: Which pack sells best
   - Helps guide future sound pack creation

4. **Restore Purchase Usage**: How many users restore
   - Indicates users switching devices

### Analytics Events to Track

```swift
// Add these to your analytics system
Analytics.logEvent("fart_pack_viewed", parameters: ["pack_id": pack.id])
Analytics.logEvent("fart_pack_purchased", parameters: ["pack_id": pack.id, "price": 1.99])
Analytics.logEvent("fart_sound_played", parameters: ["sound_name": sound.name])
```

---

## 🎨 Marketing Ideas

### Launch Announcement

**Twitter/X Post**:
```
NEW: Fart Packs 💨

Your poops can now have legendary sound effects!

• 💦 Wet & Wild Pack
• ⚔️ The Attacker Pack
• 🤫 Silent But Deadly Pack

$1.99 each. Your bathroom memories just got 10x better.

[App Store Link]
```

**TikTok Video Ideas**:
1. "POV: You just bought the Wet & Wild Pack" (show reaction)
2. "Rating every fart pack sound from 1-10"
3. "Which fart sound matches your personality?"

### In-App Promotion

1. **Banner in Feed**: "New! 💨 Fart Packs Available"
2. **After 3rd Drop**: Show fart pack shop modal
3. **Profile Badge**: "🎵 Sound Pack Collector" badge

---

## ⚠️ Common Issues & Solutions

### Issue 1: "Cannot connect to iTunes Store"
**Solution**: Ensure sandbox test account is signed in to device settings

### Issue 2: Purchase completes but pack not unlocked
**Solution**: Check `FartPackManager.swift` unlockPack logic, verify CloudKit save

### Issue 3: Sounds don't play
**Solution**: Verify sound files are in app bundle, check file names match exactly

### Issue 4: "Product not found"
**Solution**: 
- Verify product IDs match between code and App Store Connect
- Wait 2-3 hours after creating IAP products
- Clear Xcode DerivedData and rebuild

### Issue 5: Restore purchases doesn't work
**Solution**: Check `StoreKitManager.restorePurchases()` implementation

---

## 📝 Checklist Before App Store Submission

### Code
- [ ] All 3 IAP product IDs match App Store Connect exactly
- [ ] StoreKitManager properly loads products
- [ ] Purchase flow works end-to-end
- [ ] Restore purchases works
- [ ] Sound files play correctly
- [ ] Error handling for failed purchases
- [ ] Loading states for purchase process

### App Store Connect
- [ ] All 3 IAP products created
- [ ] All products in "Ready to Submit" status
- [ ] Pricing set to $1.99 USD (Tier 3)
- [ ] Descriptions and display names set
- [ ] All required territories selected

### CloudKit
- [ ] `UserFartPackPurchases` record type created
- [ ] Correct field types and indexes
- [ ] Security roles configured

### Testing
- [ ] Tested with sandbox accounts on real device
- [ ] Tested restore purchases
- [ ] Tested on multiple devices
- [ ] Tested with poor network connection
- [ ] Tested sound playback
- [ ] Tested UI in light/dark mode

### Legal/Policy
- [ ] Clear pricing displayed ($1.99)
- [ ] Purchase confirmation shown before charging
- [ ] "Restore Purchases" button visible
- [ ] No misleading descriptions

---

## 🎯 Success Criteria

### Week 1 Targets
- 100+ total purchases
- 3-5% conversion rate
- <1% refund rate
- No critical bugs

### Month 1 Targets
- 500+ total purchases
- $1,000+ revenue (before Apple's 30% cut)
- 5-8% conversion rate
- Average 1.5 packs per purchasing user

### Feature Expansion Ideas
If successful, consider:
1. **Bundle Pack** - All 3 packs for $4.99 (25% off)
2. **Seasonal Packs** - Halloween farts, Christmas sounds
3. **Premium Pack** - $2.99 with rare legendary sounds
4. **Subscription** - $5.99/month for all current + future packs

---

## 📞 Support

If users report IAP issues:
1. Direct them to "Restore Purchases" button
2. Check if purchase was charged (App Store receipt)
3. Verify CloudKit sync is working
4. Check device iCloud account status

---

**Ready to ship? Let's make those drops legendary!** 💨🚀

**Last Updated**: October 7, 2025
**Version**: 1.02 Fart Packs Release

