# 🧪 COMPREHENSIVE TESTING GUIDE

## ✅ **BUILD STATUS: SUCCESS!**

All features are implemented and compiling. Now you need to test them!

---

## 📱 **WHAT'S IN THE APP:**

### **6 TABS:**
1. 🏠 **Feed** - Friend drops
2. 👥 **Friends** - Send attacks, see leaderboard
3. 📊 **Poll** - Daily voting (NEW!)
4. 🗺️ **Map** - See all drops
5. 🛒 **Shop** - Buy IAPs
6. 👤 **Profile** - Your stats

### **4 IAP PRODUCTS:**
1. $2.99 - Ghost Attack Pack (3 attacks)
2. $1.99 - 2X Points Boost (24h)
3. $0.99 - Reveal Ghost Sender
4. $0.99 - Reveal Poll Voters

---

## 🧪 **TEST 1: GHOST ATTACKS**

### **Send Attack:**
1. Go to **Friends** tab
2. Tap a friend
3. Tap **"Ghost Attack"** button
4. Confirm attack sent
5. ✅ Check: Attack count decreased by 1

### **Receive Attack (Need 2 devices):**
1. On victim's device: Should get push notification
2. Open app → Attack overlay appears
3. See: "👻 Someone sent you a fart!"
4. ✅ Check: Shows "Guess who? You get ONE guess!"

### **Guessing:**
1. Scroll through friends list
2. Tap a friend to guess
3. **If WRONG:** Shows "Wrong guess!"
4. **If RIGHT:** Shows "You guessed it!" with their name

### **Reveal IAP ($0.99):**
1. After wrong guess, tap **"Reveal Who Sent It - $0.99"**
2. Complete purchase
3. ✅ Check: Shows sender's name

### **Points Awarded:**
- Sender: **+15 points** (or +30 if 2X boost active)
- Receiver: **+20 points** (or +40 if boost active)

---

## 🧪 **TEST 2: 24HR POINTS BOOST**

### **Purchase ($1.99):**
1. Go to **Shop** tab
2. Find "2X Points for 24 Hours - $1.99"
3. Tap "Buy Now"
4. Complete purchase
5. ✅ Check: Points boost activated

### **Verify 2X Works:**
1. Go to **Ranks** (Friends → Ranks button)
2. Should see "2X ACTIVE" or similar indicator
3. **Do an action:** Drop a poop
4. Normal: +10 points
5. **With boost: +20 points** ✅
6. Send attack: +30 (instead of +15) ✅
7. React to drop: +10 (instead of +5) ✅

### **Check Expiry:**
1. Note when purchased
2. After 24 hours: Boost should expire
3. Points return to normal

---

## 🧪 **TEST 3: DAILY LEADERBOARD (RANKS)**

### **Access:**
1. Go to **Friends** tab
2. Tap **"🏆 Ranks"** button
3. Should see Daily Leaderboard

### **Check Rankings:**
- ✅ Shows today's top users
- ✅ Shows your rank
- ✅ Shows points

### **Earn Points & Verify:**

| Action | Points | Boosted (2X) |
|--------|--------|--------------|
| Drop a poop | +10 | +20 |
| Friend reacts to your drop | +5 | +10 |
| Send ghost attack | +15 | +30 |
| Receive attack | +20 | +40 |
| Vote in poll | +25 | +50 |

**Test Each:**
1. Note current points
2. Do action
3. ✅ Check points increased correctly
4. ✅ Check rank updated

---

## 🧪 **TEST 4: POLLS**

### **Daily Poll:**
1. Go to **Poll** tab (📊 chart icon)
2. Should see today's question
3. Example: "Who has the funniest bathroom stories?"

### **Voting:**
1. Select 3 friends
2. ✅ Check: Counter shows "3 / 3 selected"
3. Tap "Submit Votes"
4. ✅ Check: Got +25 points
5. ✅ Check: Can't vote again (shows "You've voted!")

### **Results:**
1. Tap "See Results"
2. Results are **blurred**
3. Shows: "??????" for usernames

### **Reveal IAP ($0.99):**
1. Tap "Reveal Voters - $0.99"
2. Complete purchase
3. ✅ Check: Shows real names and vote counts
4. ✅ Check: Shows top 3 winners

---

## 🧪 **TEST 5: ALL 4 IAPS**

### **$2.99 - Ghost Attack Pack:**
1. **Shop** → "3 Ghost Attacks - $2.99"
2. Purchase
3. ✅ Check: Friends tab shows +3 attacks

### **$1.99 - 2X Points Boost:**
1. **Shop** → "2X Points Boost - $1.99"
2. Purchase
3. ✅ Check: All points doubled for 24h

### **$0.99 - Reveal Ghost Sender:**
1. Receive attack → Guess wrong
2. Purchase reveal
3. ✅ Check: Shows sender

### **$0.99 - Reveal Poll Voters:**
1. Poll → See Results
2. Purchase reveal
3. ✅ Check: Shows who voted

---

## 🧪 **TEST 6: POINTS SYSTEM INTEGRATION**

### **Test Each Action:**

**1. Drop a Poop:**
- [ ] Open drop composer (floating button)
- [ ] Submit drop
- [ ] ✅ +10 points awarded

**2. Friend Reacts:**
- [ ] Friend reacts to your drop
- [ ] ✅ +5 points awarded

**3. Send Ghost Attack:**
- [ ] Send attack to friend
- [ ] ✅ +15 points awarded

**4. Receive Attack:**
- [ ] Get attacked by friend
- [ ] ✅ +20 points awarded

**5. Vote in Poll:**
- [ ] Vote for 3 friends
- [ ] ✅ +25 points awarded

**6. With 2X Boost:**
- [ ] Buy boost
- [ ] Do any action
- [ ] ✅ Points are doubled

---

## ⚠️ **CLOUDKIT SETUP NEEDED:**

Before testing, add these record types in CloudKit Dashboard:

### **Poll:**
| Field | Type | Indexed |
|-------|------|---------|
| creatorID | String | Yes |
| creatorUsername | String | No |
| questionText | String | No |
| pollType | String | No |
| createdAt | Date/Time | Yes |
| endsAt | Date/Time | Yes |
| isActive | Int(64) | Yes |
| totalVotes | Int(64) | No |

### **PollVote:**
| Field | Type | Indexed |
|-------|------|---------|
| pollID | String | Yes |
| voterID | String | Yes |
| voterUsername | String | No |
| votedForID | String | Yes |
| votedForUsername | String | No |
| timestamp | Date/Time | Yes |

---

## ✅ **TESTING CHECKLIST:**

- [ ] **Ghost Attacks:** Send, receive, guess, reveal
- [ ] **2X Points Boost:** Purchase, verify doubled points
- [ ] **Daily Leaderboard:** Check rankings, points update
- [ ] **Polls:** Vote, see results, reveal voters
- [ ] **All 4 IAPs:** Purchase each one
- [ ] **Points:** Verify all actions award correct points
- [ ] **CloudKit:** Add Poll & PollVote record types

---

## 🚀 **READY FOR LAUNCH WHEN:**

- ✅ All Ghost Attacks work
- ✅ Points are awarded correctly
- ✅ Leaderboard updates in real-time
- ✅ Polls work daily
- ✅ All 4 IAPs complete successfully
- ✅ CloudKit schema updated
- ✅ Tested on real device
- ✅ No crashes

---

**The app is fully built! Now test everything and ship it!** 🎉

