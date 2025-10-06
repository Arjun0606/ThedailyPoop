# 💨 Fart Attack Feature - Implementation Guide

## 🎯 Overview
Send a loud, unavoidable fart sound to any friend for $1.99 USD.

---

## 📋 What Needs to Be Done

### 1. **Create In-App Purchase in App Store Connect**

#### Go to App Store Connect:
1. Apps → TheDailyPoop → In-App Purchases
2. Click "+" to create new
3. Select **"Consumable"** (can buy multiple times)

#### Product Details:
- **Product ID**: `com.thedailypoop.fart_attack`
- **Reference Name**: Fart Attack
- **Price**: $1.99 USD (Tier 3)
- **Display Name** (English): Fart Attack 💨
- **Description** (English): 
  ```
  Send a loud, hilarious fart sound to any friend! 
  
  They can't escape it - the fart will play when they open the app, 
  even if they're in a quiet library or important meeting. 
  
  Perfect for pranking your friends and creating unforgettable moments!
  ```

#### Screenshot (Optional but Recommended):
- Create a simple graphic showing the fart emoji and text
- Size: 640x920 pixels
- Use in App Store preview

---

### 2. **Code Implementation** (I can help with this)

#### Files to Create/Modify:
1. **New:** `PoopDrop/Managers/StoreKitManager.swift`
   - Handle in-app purchase logic
   - Verify purchases
   - Track purchase state

2. **New:** `PoopDrop/Views/FartAttackView.swift`
   - UI to send fart attack
   - Friend selection
   - Purchase flow

3. **Modify:** `PoopDrop/Managers/NotificationManager.swift`
   - Add fart attack push notification
   - Play fart sound on receive

4. **Modify:** `PoopDrop/Views/FriendsView.swift`
   - Add "Fart Attack" button on friend profiles

5. **Modify:** `PoopDrop/Models/AppNotification.swift`
   - Add `.fartAttack` notification type

---

### 3. **Backend (CloudKit)**

#### New Record Type: `FartAttack`
Fields:
- `senderID` (String, indexed)
- `targetUserID` (String, indexed)
- `timestamp` (Date)
- `soundType` (String) - "long_fart" for now
- `wasPlayed` (Boolean)

---

### 4. **User Experience Flow**

#### Sending a Fart Attack:
1. User goes to Friends → Taps friend profile
2. Sees "💨 Fart Attack" button
3. Taps button → Shows purchase prompt ($1.99)
4. Confirms purchase
5. Push notification sent to friend
6. Success message: "Fart Attack launched! 💨"

#### Receiving a Fart Attack:
1. Friend gets push notification: "💨 Someone pranked you!"
2. Opens app → LOUD FART SOUND plays immediately
3. Full-screen overlay: "YOU'VE BEEN FART ATTACKED BY @username"
4. Can't dismiss for 5 seconds
5. After 5 seconds: "Revenge?" button (tap to buy fart attack back)

---

## 💰 Revenue Projections

### Conservative (10K users):
- 5% purchase rate = 500 buyers
- Average 1 fart attack each = 500 × $1.99 = **$995**
- Apple's 30% cut = -$299
- **Your earnings: ~$700/month**

### Moderate (10K users, 2 attacks each):
- 500 buyers × 2 attacks = 1,000 purchases
- 1,000 × $1.99 = **$1,990**
- Apple's 30% cut = -$597
- **Your earnings: ~$1,400/month**

### Viral (100K users):
- 5% = 5,000 buyers × 2 attacks = 10,000 purchases
- 10,000 × $1.99 = **$19,900**
- Apple's 30% cut = -$5,970
- **Your earnings: ~$14,000/month**

---

## 🚀 Launch Strategy

### Week 1: Soft Launch
- Add feature to app
- Don't announce publicly
- Let existing users discover it
- Monitor conversion rate

### Week 2: Social Media Blast
**Tweet:**
```
New: Fart Attack 💨

Send your friends a loud fart for $1.99.
They can't escape it.
They WILL hear it.

Best used in:
• Zoom meetings
• Libraries  
• First dates
• Funerals (jk don't)

[App Store Link]
```

**TikTok:**
- Film reactions to being fart attacked
- "POV: Your friend just fart attacked you in class"
- Potential for MASSIVE viral growth

### Week 3+: Optimize
- Track which friends prank each other most
- Add "Prank War" leaderboard
- Add more sound options ($1.99 each)
- Add "Prank Immunity" ($2.99/week - blocks all pranks)

---

## 🎨 Additional Prank Ideas (Future)

Once Fart Attack is successful, add:

1. **Constipation Curse** ($1.99)
   - Friend's streak shows 😵‍💫 for 24 hours
   - Everyone sees they're constipated

2. **Poop Emergency** ($1.99)
   - Sends urgent "YOU NEED TO POOP NOW!" alert
   - Countdown timer when opened

3. **Revenge Pack** ($4.99)
   - 3 fart attacks
   - 20% discount

4. **Unlimited Pranks** ($9.99/month)
   - Unlimited fart attacks
   - Access to all prank types
   - Prank immunity included

---

## ⚠️ Legal/Policy Considerations

### Apple's Guidelines:
✅ **Allowed:**
- Humorous/prank features
- Consumable in-app purchases
- Push notifications for pranks

❌ **Not Allowed:**
- Can't call it "harassment"
- Must allow users to block pranks
- Must have clear pricing
- Can't make it too disruptive

### Solution:
- Add "Block Pranks" toggle in settings (free)
- Clear warning before purchase: "This will send a loud sound"
- 5-second delay before dismissal (not permanent)
- Fun, not malicious

---

## 📊 Success Metrics

### Track These:
- Purchase conversion rate (target: 3-5%)
- Repeat purchase rate (target: 30%+)
- Retention after receiving prank (target: 80%+)
- Revenge prank rate (target: 40%+)
- Daily active users (should increase)

### If Successful:
- More users open app daily (to avoid being pranked)
- More friend invites (to prank new people)
- Higher engagement = more ad revenue
- Creates viral loops

---

## 🎯 Next Steps

1. **Create in-app purchase** in App Store Connect
2. **I'll code the feature** (StoreKit, notifications, UI)
3. **Test with TestFlight** users
4. **Launch** with next app update
5. **Monitor** and iterate

---

**Ready to implement this? Let me know and I'll start coding!** 🚀💨

