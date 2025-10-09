# 💨 Fart Attack Pack - IAP Setup Guide
## Version 1.02

---

## 🎯 Overview

**Product**: Fart Attack Pack  
**Price**: $1.99 USD  
**Type**: Consumable IAP  
**Contents**: 3 fart attacks per purchase  
**Users can**: Buy unlimited packs

---

## 📦 What Users Get

**Each $1.99 purchase gives**:
- 3 fart attacks to send
- Can send to 3 different friends (or same friend over multiple days)
- Each attack plays 4-second epic fart sound
- Attacks queue up if multiple friends prank same person
- 24-hour cooldown per friend pair

---

## 🛒 Step 1: Create IAP in App Store Connect (10 minutes)

### Navigate to IAP Section

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com/)
2. Click **"My Apps"**
3. Select **"TheDailyPoop"**
4. Click **"In-App Purchases"** in sidebar
5. Click **"+"** to create new product

---

### Product Configuration

#### Type
- Select: **Consumable**
- Click **"Create"**

#### Reference Name
```
Fart Attack Pack
```

#### Product ID
```
com.thedailypoop.fartattack.pack
```

⚠️ **CRITICAL**: Must match exactly (case-sensitive). This is hardcoded in `FartAttack.swift`:
```swift
static let productID = "com.thedailypoop.fartattack.pack"
```

---

#### Pricing

1. Click **"Add Pricing"**
2. Select **"All Territories"** (or choose specific ones)
3. Price: **Tier 3** ($1.99 USD)
4. Click **"Next"** → **"Confirm"**

---

#### Localization (English - U.S.)

**Display Name**:
```
Fart Attack Pack
```

**Description**:
```
Send 3 legendary fart attacks to your friends! 💨

Each attack:
• 4 seconds of epic audio quality
• Plays when friend opens app
• Surprise prank effect
• Professional Epidemic Sound recording

Buy as many packs as you want. Prank unlimited friends!

Perfect for:
• Pranking your best friends
• Starting prank wars
• Creating hilarious moments
• Getting revenge

3 attacks = $1.99 (just $0.66 per attack!)
```

---

#### Review Information

**Screenshot** (Optional but recommended):
- Size: 640×920 pixels
- Show the Fart Attack Shop UI
- Highlight "3 attacks for $1.99"

**Review Notes**:
```
Consumable in-app purchase for fart attack prank feature.

Users buy packs of 3 attacks ($1.99 per pack) to send to friends. 
When friend opens app, a 4-second fart sound plays with full-screen 
overlay showing who pranked them.

Features:
- 24-hour cooldown prevents spam
- No push notifications (only triggers on app open)
- Fun social feature between friends
- Professional sound quality from Epidemic Sound library

Users can buy unlimited packs. Each purchase adds 3 attacks to inventory.
```

---

### Save & Submit

1. Click **"Save"**
2. Status should show **"Ready to Submit"**
3. ✅ Done! Product is now created

⏰ **Important**: Wait 2-3 hours for Apple to process the IAP before testing

---

## 🗄️ Step 2: CloudKit Schema Setup (15 minutes)

See `CLOUDKIT_SCHEMA_FART_ATTACKS.md` for complete instructions.

### Quick Summary

**Create 2 record types**:

1. **FartAttack** (Public DB)
   - Stores individual attacks
   - 8 fields including senderID, targetUserID, wasPlayed
   - 5 indexes

2. **FartAttackInventory** (Private DB)
   - Stores user's available attacks and cooldowns
   - 4 fields including availableAttacks, cooldowns
   - 2 indexes

---

## 🧪 Step 3: Testing (30 minutes)

### Enable StoreKit Testing in Xcode

1. In Xcode, click your scheme name (top bar)
2. Select **"Edit Scheme..."**
3. Go to **"Run"** → **"Options"** tab
4. **StoreKit Configuration**: Create new or select existing
5. Enable **"Debug StoreKit"**
6. Click **"Close"**

---

### Create StoreKit Configuration File

1. **File** → **New** → **File**
2. Search for **"StoreKit Configuration File"**
3. Name it `FartAttacks.storekit`
4. Add product:

```json
{
  "identifier" : "com.thedailypoop.fartattack.pack",
  "type" : "Consumable",
  "reference_name" : "Fart Attack Pack",
  "price" : 1.99,
  "family_shareable" : false
}
```

---

### Test the Complete Flow

1. **Build & Run** in Simulator
2. Sign in to app
3. Go to **Friends** tab
4. Tap a friend
5. See **"Get Fart Attacks"** button (no inventory yet)
6. Tap button → Shop opens
7. Tap **"Buy 3 Attacks for $1.99"**
8. In sandbox: Confirm purchase (no real charge)
9. Inventory updates: "3 attacks available"
10. Return to friend's profile
11. Tap **"Send Fart Attack!"**
12. Attack sends successfully
13. Inventory: "2 attacks available"
14. See 24hr cooldown for that friend

✅ If all steps work, you're ready for TestFlight!

---

## 📱 Step 4: TestFlight Testing (1 hour)

### Create Sandbox Test Account

1. In App Store Connect: **Users and Access** → **Sandbox Testers**
2. Click **"+"**
3. Create test account:
   - Email: `farttest@yourdomain.com` (can be fake)
   - Password: Something memorable
   - First/Last Name: Test User
   - Country: United States
4. Click **"Create"**

---

### Upload TestFlight Build

1. In Xcode: **Product** → **Archive**
2. Wait for archive to complete
3. Click **"Distribute App"**
4. Select **"App Store Connect"**
5. Follow prompts to upload
6. Wait 10-30 minutes for processing

---

### Test on Real Device

1. On iPhone/iPad:
   - **Settings** → **App Store** → Sign out
   - Sign in with sandbox test account
2. Install app from **TestFlight**
3. Complete full test flow:
   - Buy fart attack pack
   - Send to friend (use 2nd test device or account)
   - Friend opens app → fart plays
   - Verify overlay shows correctly
   - Test cooldown (should block 2nd attack to same friend)
   - Buy 2nd pack → inventory adds 3 more

---

## 💰 Revenue Tracking

### Key Metrics to Track

```swift
// Purchase Events
"fart_attack_pack_purchased" (price: 1.99, attacks: 3)
"fart_attack_sent" (target_user, attacks_remaining)
"fart_attack_received" (sender_user, was_played)

// User Behavior
"shop_opened"
"friend_profile_viewed"
"revenge_button_tapped"

// Revenue Metrics
Total packs sold
Average packs per user
Repeat purchase rate
Revenge rate (% who buy back)
```

---

### Revenue Breakdown

**Price**: $1.99 USD per pack  
**Apple's Cut**: 30% = $0.60  
**Your Revenue**: 70% = **$1.39 per pack**

**Projections**:

| Users | 5% Buy | 2 Packs Avg | Your Revenue |
|-------|--------|-------------|--------------|
| 10K | 500 | 1,000 packs | **$1,390** |
| 50K | 2,500 | 5,000 packs | **$6,950** |
| 100K | 5,000 | 10,000 packs | **$13,900** |

**Prank War Scenario** (10K users, 15% buy, 4 packs avg):
- 1,500 buyers × 4 packs = 6,000 packs
- **$8,340 revenue** 💰

---

## 🚀 Launch Strategy

### Soft Launch (Week 1)

- Ship to existing users
- Don't announce externally yet
- Monitor metrics:
  - Purchase conversion rate (target: 5-8%)
  - Attacks sent per purchase (target: 2.5+)
  - Revenge rate (target: 30%+)
- Fix any bugs

---

### Public Launch (Week 2)

**Twitter/X**:
```
NEW: Fart Attack Packs 💨

$1.99 = 3 legendary fart attacks

Send to friends. They open app. 
4 seconds of epic audio. No escape.

Prank wars start NOW.

[App Store Link]
```

**TikTok**:
- Film friend's reaction to fart attack
- "POV: You got fart attacked in class"
- "The best $1.99 I ever spent"
- Tag #PoopDrop #FartAttack #Prank

**Instagram Stories**:
- Before/after of friend getting attacked
- "Rate your friend's reaction"
- "Who's getting fart attacked next?"

---

### Viral Loop Strategy

```
User A buys pack
    ↓
Attacks User B
    ↓
User B opens app → BOOM! 💨
    ↓
User B sees "Get Revenge?" button
    ↓
User B buys pack (revenge purchase!)
    ↓
Attacks User A back
    ↓
PRANK WAR = Recurring Revenue
```

**Key**: Make revenge easy and tempting!

---

## ⚠️ Common Issues & Solutions

### "Product not found" error

**Cause**: IAP not processed by Apple yet  
**Solution**: 
- Wait 2-3 hours after creating product
- Clear Xcode DerivedData: `~/Library/Developer/Xcode/DerivedData`
- Clean build: Cmd+Shift+K
- Restart Xcode

---

### Purchase completes but no attacks added

**Cause**: Transaction listener not firing  
**Solution**:
- Check `StoreKitManager.listenForTransactions()` is called
- Verify `FartAttackManager.addAttacksFromPurchase()` is called
- Check CloudKit `FartAttackInventory` record saves

---

### Attacks don't play when received

**Cause**: CloudKit query not finding attacks  
**Solution**:
- Verify CloudKit indexes are created (wait 10 min after creating)
- Check `targetUserID` and `wasPlayed` are indexed
- Verify Public Database permissions (World readable)

---

### Sound doesn't play

**Cause**: Audio file missing or wrong name  
**Solution**:
- Verify `fart_long_epidemic.wav` is in `PoopDrop/Sounds/`
- Check file is added to Xcode target (File Inspector)
- Test sound plays in simulator

---

### Inventory not syncing across devices

**Cause**: CloudKit Private DB not accessible  
**Solution**:
- Check user signed into iCloud on both devices
- Verify iCloud capability enabled in Xcode
- Check `FartAttackInventory` is in Private DB

---

### Cooldown not working

**Cause**: Cooldown data not persisting  
**Solution**:
- Check `cooldowns` field saves to CloudKit
- Verify JSON encoding/decoding works
- Test by sending 2 attacks to same friend quickly

---

## 📊 Success Metrics

### Week 1 Goals
- 50+ packs sold
- 3-5% conversion rate
- 2+ attacks sent per purchase
- 20%+ revenge rate
- 0 critical bugs

---

### Month 1 Goals
- 500+ packs sold
- $695+ revenue
- 5-8% conversion rate
- 30%+ revenge rate
- 10%+ repeat buyers

---

### If Successful, Consider

1. **Attack Bundles**
   - 10 attacks for $4.99 (save 25%)
   - 25 attacks for $9.99 (save 50%)

2. **Special Sounds**
   - "Ultra Legendary Pack" - $2.99 for 3 ultra sounds
   - Seasonal sounds (Halloween screamer, Christmas jingle fart)

3. **Subscription**
   - "Unlimited Pranks" - $4.99/month
   - Send unlimited attacks
   - Exclusive sounds

4. **Group Features**
   - "Group Attack" - 3 friends gang up on 1 victim
   - "Fart Bomb" - Send to all friends at once

---

## ✅ Pre-Launch Checklist

### App Store Connect
- [ ] IAP product created
- [ ] Product ID: `com.thedailypoop.fartattack.pack`
- [ ] Price: $1.99 (Tier 3)
- [ ] Type: Consumable
- [ ] Status: "Ready to Submit"
- [ ] Description complete
- [ ] Review notes added

### CloudKit
- [ ] `FartAttack` record type created (Public DB)
- [ ] `FartAttackInventory` record type created (Private DB)
- [ ] All fields configured correctly
- [ ] Indexes created (7 total across both types)
- [ ] Security roles set

### Code
- [ ] Product ID matches in code
- [ ] No linter errors
- [ ] `fart_long_epidemic.wav` file present
- [ ] Sound file in Xcode target
- [ ] All managers initialized
- [ ] Overlay shows on app launch

### Testing
- [ ] Sandbox testing complete
- [ ] Purchase flow works
- [ ] Inventory updates correctly
- [ ] Attacks send successfully
- [ ] Attacks play when received
- [ ] Cooldown enforced
- [ ] Multiple attacks queue properly
- [ ] TestFlight testing complete

### Launch
- [ ] Version bumped to 1.02
- [ ] Release notes written
- [ ] Marketing materials ready
- [ ] Social media posts scheduled
- [ ] Support documentation ready

---

## 🎉 You're Ready to Launch!

**Total Setup Time**: ~2 hours  
**Expected First Month Revenue**: $500-1,000  
**Growth Potential**: High (viral prank wars)  
**Fun Factor**: Maximum 💨

---

**Last Updated**: October 7, 2025  
**Version**: 1.02 - Fart Attack Pack  
**Status**: Ready for App Store Connect setup

Let's make those pranks legendary! 💨🚀

