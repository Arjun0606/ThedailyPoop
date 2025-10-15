# 📋 POLL FEATURE & FULL TESTING PLAN

## ✅ POLL FEATURE - 95% COMPLETE

### **What's Done:**
1. ✅ `PollManager.swift` - Created (handles poll creation, voting, results)
2. ✅ `DailyPollView.swift` - Created (UI for polls, voting, results)
3. ✅ Poll tab added to MainTabView (6 tabs now)
4. ✅ IAP for "Reveal Poll Voters" ($0.99) already exists
5. ✅ Poll model already exists (Poll.swift)

### **What Needs To Be Done:**
⚠️ **Add 2 files to Xcode manually:**

1. Open `PoopDrop.xcodeproj` in Xcode
2. Right-click on **"Managers"** folder
3. Select "Add Files to PoopDrop..."
4. Navigate to: `PoopDrop/Managers/PollManager.swift`
5. **UNCHECK** "Copy items if needed"
6. **CHECK** "Add to targets: PoopDrop"
7. Click "Add"

8. Repeat for **"Views"** folder with `PoopDrop/Views/DailyPollView.swift`

Then build (⌘B) - should work!

---

## 🧪 COMPREHENSIVE TESTING PLAN

### **Test 1: Ghost Attacks** ($2.99 for 3 attacks)
- [ ] Open app, go to Friends tab
- [ ] Tap friend → "Ghost Attack"
- [ ] Confirm attack sent
- [ ] **On victim's device:** Receive attack notification
- [ ] Victim opens attack → sees "Guess who sent this!"
- [ ] Victim guesses wrong
- [ ] **Test IAP:** Victim taps "Reveal for $0.99"
- [ ] ✅ Should show who sent it

**Expected Points:**
- Sender: +15 points
- Victim (if they guess): +5 points

---

### **Test 2: 24hr Points Boost** ($1.99)
- [ ] Go to Daily Leaderboard (Ranks tab)
- [ ] Tap "2X Points for 24 hours - $1.99"
- [ ] Purchase
- [ ] Drop a poop → Should get **+20 points** (instead of +10)
- [ ] Send attack → Should get **+30 points** (instead of +15)
- [ ] React to drop → Should get **+10 points** (instead of +5)
- [ ] Check profile → Should show "2X ACTIVE" badge
- [ ] Wait 24 hours → Boost should expire

---

### **Test 3: Daily Leaderboard (Points System)**
- [ ] Go to "Ranks" (Friends → Ranks button)
- [ ] Should see today's ranking
- [ ] **Do actions and verify points:**
  - Drop a poop: +10 points
  - Friend reacts to your drop: +5 points
  - Send ghost attack: +15 points
  - Receive attack (they care!): +20 points
  - Vote in poll: +25 points
- [ ] Check your rank updates in real-time
- [ ] Check resets at midnight

---

### **Test 4: Polls** ($0.99 reveal)
- [ ] Go to Poll tab (chart.bar icon)
- [ ] Should see today's poll question
- [ ] Select 3 friends to vote for
- [ ] Submit votes → Get +25 points
- [ ] Tap "See Results"
- [ ] Results are blurred
- [ ] **Test IAP:** Tap "Reveal Voters - $0.99"
- [ ] ✅ Should show who voted and vote counts

---

### **Test 5: All IAPs Work**
1. **$2.99 - Ghost Attack Pack (3 attacks)**
   - [ ] Go to Shop tab
   - [ ] Tap "Buy Now - $2.99"
   - [ ] Complete purchase
   - [ ] Check Friends tab → Should have +3 attacks

2. **$1.99 - 2X Points Boost (24h)**
   - [ ] Go to Shop tab  
   - [ ] Tap "Buy Now - $1.99"
   - [ ] Complete purchase
   - [ ] Do any action → Points should be doubled

3. **$0.99 - Reveal Ghost Sender**
   - [ ] Receive a ghost attack
   - [ ] Guess wrong
   - [ ] Tap "Reveal for $0.99"
   - [ ] Complete purchase
   - [ ] Should show sender

4. **$0.99 - Reveal Poll Voters**
   - [ ] Go to Poll tab
   - [ ] View results (blurred)
   - [ ] Tap "Reveal Voters - $0.99"
   - [ ] Complete purchase
   - [ ] Should show who voted

---

### **Test 6: Points Are Awarded Correctly**

| Action | Points | Boosted (2X) |
|--------|--------|--------------|
| Drop a poop | +10 | +20 |
| Friend reacts to your drop | +5 | +10 |
| Send ghost attack | +15 | +30 |
| Receive attack | +20 | +40 |
| Vote in poll (3 votes) | +25 | +50 |

**Test each action:**
1. [ ] Note current points
2. [ ] Do action
3. [ ] Check points increased correctly
4. [ ] Check leaderboard updated

---

### **Test 7: Remove Badges (NOT IMPLEMENTED YET)**

Search for any "badge" or "achievement" references and remove them:
```bash
cd /Users/arjun/poopdrop
grep -r "badge\|achievement" --include="*.swift" PoopDrop/
```

If found, remove those features.

---

## 🐛 KNOWN ISSUES TO FIX:

1. **Poll files need to be added to Xcode** (see instructions above)
2. **CloudKit schema** needs `Poll` and `PollVote` record types
3. **Test all IAPs** in sandbox mode before launch

---

## 📊 CloudKit Schema Updates Needed:

### **Poll Record Type:**
| Field Name | Type | Indexed |
|------------|------|---------|
| creatorID | String | Yes |
| creatorUsername | String | No |
| questionText | String | No |
| pollType | String | No |
| createdAt | Date/Time | Yes |
| endsAt | Date/Time | Yes |
| isActive | Int(64) | Yes |
| totalVotes | Int(64) | No |

### **PollVote Record Type:**
| Field Name | Type | Indexed |
|------------|------|---------|
| pollID | String | Yes |
| voterID | String | Yes |
| votedForUserID | String | Yes |
| createdAt | Date/Time | Yes |

---

## 🚀 LAUNCH CHECKLIST:

- [ ] Add Poll files to Xcode
- [ ] Build succeeds
- [ ] Test all Ghost Attacks (send, receive, guess, reveal)
- [ ] Test 2X Points Boost
- [ ] Test Daily Leaderboard
- [ ] Test all 4 IAPs
- [ ] Test Points awarded correctly
- [ ] Remove any badge/achievement code
- [ ] Update CloudKit schema (Poll, PollVote)
- [ ] Test on real device
- [ ] Submit to App Store! 🎉

---

**Once Poll files are added to Xcode, EVERYTHING should work!**

