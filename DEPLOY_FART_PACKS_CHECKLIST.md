# 🚀 Deploy Fart Packs v1.02 - Quick Checklist

## ⏱️ Total Time: ~2 hours

---

## ✅ Step 1: App Store Connect (30 min)

Go to [App Store Connect](https://appstoreconnect.apple.com/) → Your App → In-App Purchases

### Create 3 Products:

#### Product 1: Wet & Wild
- [ ] Type: **Consumable**
- [ ] Product ID: `com.thedailypoop.fartpack.wetandwild`
- [ ] Price: **$1.99** (Tier 3)
- [ ] Display Name: `Wet & Wild Pack`
- [ ] Status: **Ready to Submit**

#### Product 2: The Attacker
- [ ] Type: **Consumable**
- [ ] Product ID: `com.thedailypoop.fartpack.attacker`
- [ ] Price: **$1.99** (Tier 3)
- [ ] Display Name: `The Attacker Pack`
- [ ] Status: **Ready to Submit**

#### Product 3: Silent But Deadly
- [ ] Type: **Consumable**
- [ ] Product ID: `com.thedailypoop.fartpack.silentbutdeadly`
- [ ] Price: **$1.99** (Tier 3)
- [ ] Display Name: `Silent But Deadly Pack`
- [ ] Status: **Ready to Submit**

📖 **Full details**: See `FART_PACKS_IAP_SETUP.md`

---

## ✅ Step 2: CloudKit Schema (10 min)

Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)

- [ ] Select container: `iCloud.com.poopdrop.app`
- [ ] Go to **Schema** → **Record Types**
- [ ] Click **"+"** to add new type
- [ ] Name: `UserFartPackPurchases`
- [ ] Database: **Private Database**

### Add 3 Fields:

| Field Name | Type | Indexed |
|------------|------|---------|
| userID | String | ✅ Yes |
| purchasedPackIDs | Bytes | ❌ No |
| lastUpdated | Date/Time | ✅ Yes |

- [ ] Security: Creator = Readable, Writable
- [ ] Click **Save**

📖 **Full details**: See `CLOUDKIT_SCHEMA.md` (line 206)

---

## ✅ Step 3: Test in Xcode (30 min)

### StoreKit Testing:
- [ ] Edit Scheme → Run → Options
- [ ] Enable StoreKit Configuration
- [ ] Build and run in Simulator
- [ ] Navigate to **Shop** tab
- [ ] Try "purchasing" a pack (no real charge in sandbox)
- [ ] Verify pack unlocks
- [ ] Open drop composer
- [ ] Tap "Fart Sound" section
- [ ] Select a sound
- [ ] Create drop
- [ ] Verify sound plays

---

## ✅ Step 4: TestFlight (1 hour)

### Build:
- [ ] Update version to **1.02** in Xcode
- [ ] Archive app: **Product** → **Archive**
- [ ] Upload to App Store Connect
- [ ] Wait for processing (10-30 min)

### Test:
- [ ] Add yourself as internal tester
- [ ] Install from TestFlight
- [ ] Test purchase with sandbox account
- [ ] Test restore purchases
- [ ] Test sound playback
- [ ] Verify no crashes

### Sandbox Account Setup:
1. App Store Connect → Users and Access → Sandbox Testers
2. Create test account (fake email)
3. On device: Settings → App Store → Sign Out
4. Sign in with sandbox account
5. Open TestFlight build
6. Try purchasing packs

---

## ✅ Step 5: Submit to App Store

- [ ] All TestFlight tests passed
- [ ] No critical bugs found
- [ ] Version 1.02 ready
- [ ] Submit for review

### In Review Notes:
```
Version 1.02 adds Fart Packs - comedic sound effects ($1.99 each) 
that users can purchase and play when logging bathroom activities. 
3 consumable IAP products included.
```

---

## 🎯 Quick Test Flow (5 minutes)

1. Open app
2. Tap **Shop** tab (new!)
3. See 3 locked packs
4. Tap a pack → View details
5. (In sandbox) Tap "Purchase"
6. Complete fake purchase
7. Pack unlocks ✅
8. Tap **+** to create drop
9. Scroll to "Fart Sound"
10. Tap to select sound
11. Pick a sound from unlocked pack
12. Create drop
13. **Sound plays!** 💨

---

## 📁 Files to Reference

- `FART_PACKS_IAP_SETUP.md` - Complete guide
- `VERSION_1.02_FART_PACKS_SUMMARY.md` - Full overview
- `CLOUDKIT_SCHEMA.md` - Database setup

---

## 🆘 If Something Goes Wrong

### "Product not found" error
- Wait 2-3 hours after creating IAP products
- Verify Product IDs match exactly (case-sensitive)
- Clean build folder in Xcode

### Sounds don't play
- Check device volume
- Verify sound files exist in `PoopDrop/Sounds/`
- Check file names match exactly (e.g., `fart_short.wav`)

### Purchase completes but pack not unlocked
- Check CloudKit schema is correct
- Verify `FartPackManager` is saving to UserDefaults
- Try "Restore Purchases" button

---

## 🎉 When Complete

You'll have:
- ✅ 3 purchasable fart packs at $1.99 each
- ✅ Beautiful shop UI
- ✅ Sound playback when dropping
- ✅ Cross-device sync via CloudKit
- ✅ Restore purchases functionality
- ✅ New revenue stream!

**Expected Revenue (conservative):**
- Month 1: $500-1,000
- Month 3: $1,500-3,000
- Month 6: $3,000-6,000

---

**Questions?** See detailed docs or test in sandbox first!

**Ready to launch?** Let's make it rain fart sounds! 💨💰

