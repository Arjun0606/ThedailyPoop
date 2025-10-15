# 🚀 TheDailyPoop: Viral Features Implementation Plan

## 📋 FINAL FEATURE SET

### ✅ Core Features (Free)
1. **Daily Points System** - Earn points for all activities
2. **Daily Leaderboard** - See top friends by points
3. **Daily Polls** - User-created questions, school-wide voting
4. **Fart Attacks** - Regular (announced) + Ghost (anonymous)
5. **Drops & Map** - Track & visualize bathroom drops

### 💰 Impulse IAP Only (9 Products)
1. Poll Reveal - $0.99
2. 3 Regular Attacks - $1.99
3. 10 Regular Attacks - $4.99
4. 1 Ghost Attack - $0.99
5. 3 Ghost Attacks - $2.99
6. 10 Ghost Attacks - $6.99
7. Ghost Hint (Narrow) - $0.99
8. Ghost Reveal - $1.99
9. 2X Points Boost - $1.99

**NO PRO, NO SUBSCRIPTIONS, NO STREAK FREEZE**

---

## 🎯 IMPLEMENTATION ORDER

### Phase 1: Points System (Day 1)
- [ ] Add `points` and `dailyPointsResetDate` to User model
- [ ] Create PointsManager to track point earning
- [ ] Award points for actions:
  - +10 Drop a poop
  - +5 React to friend's drop
  - +15 Send fart attack
  - +20 Receive fart attack
  - +25 Win poll
- [ ] Daily reset at midnight
- [ ] Create DailyLeaderboardView

### Phase 2: Polls System (Day 2-3)
- [ ] Create Poll CloudKit model
  - id, creatorID, questionText, pollType, votesReceived[], endsAt
- [ ] Create PollVote CloudKit model
- [ ] Create PollReveal CloudKit model
- [ ] Build poll creation UI
  - Pick format (Prediction/Battle)
  - Write question
  - Submit
- [ ] Build voting UI
  - Show active polls
  - Vote submission
- [ ] Results at midnight
- [ ] $0.99 reveal IAP

### Phase 3: Ghost Attacks (Day 4)
- [ ] Add `isGhost` field to FartAttack model
- [ ] Add `ghostGuesses` field (3 attempts)
- [ ] Build ghost attack sending UI
- [ ] Build guessing game UI
- [ ] Implement hint system:
  - Free hint: "Friend from your city"
  - $0.99: Narrow to 3 people
  - $1.99: Full reveal
- [ ] Ghost attack IAP packs

### Phase 4: Monetization (Day 5)
- [ ] Update StoreKitManager with 9 products
- [ ] Add poll reveal purchase flow
- [ ] Add ghost attack packs
- [ ] Add ghost hint purchases
- [ ] Add 2X points boost (24hr duration)
- [ ] Test all IAP flows

### Phase 5: Polish & Testing (Day 6)
- [ ] Remove PRO features
- [ ] Remove streak freeze
- [ ] Simplify streaks (just daily check-ins)
- [ ] Add milestone rewards (7/30/100 days)
- [ ] Test rotation logic
- [ ] Test all IAP purchases
- [ ] Push notification setup

---

## 📊 REVENUE PROJECTION (150K Users)

### Per-User Monthly Spending:
- Poll reveals: 8-10 × $0.99 = $8-10
- Ghost attacks: 2-3 packs × $2 avg = $4-6
- Points boost: 1 × $1.99 = $2
- Ghost hints: 2 × $1 avg = $2

**ARPU: $16-20/month** (industry-leading)

### Total Monthly Revenue:
- 150K users × $18 ARPU × 70% (Apple cut) = **$1.89M/month**

**Conservative estimate: $800K-1.2M/month at scale**

---

## 🔥 VIRAL MECHANICS

### K-Factor Drivers:
1. **School-wide polls** - Everyone sees, everyone votes
2. **Ghost attacks** - Mystery creates intrigue
3. **Leaderboard competition** - Friends recruit friends to compete
4. **Point system** - Gamification hook

**Target K-Factor: 1.5-2.0** (each user brings 1.5-2 friends)

---

## ⚡️ STICKINESS METRICS

### Daily Opens:
- Check leaderboard (1st open)
- Vote in poll (2nd open)
- Check poll results (3rd open)
- Send/receive attacks (4th open)
- React to drops (5th open)

**Target: 3-5 opens/day**

### Retention:
- D1: 65%+ (points + poll hook)
- D7: 50%+ (competitive dynamics)
- D30: 30%+ (social validation loop)

---

## 🚀 LAUNCH CHECKLIST

Before Product Hunt:
- [ ] All 9 IAP products live
- [ ] Poll system working (creation, voting, reveals)
- [ ] Ghost attacks working (guessing, hints)
- [ ] Points + leaderboard functional
- [ ] Daily reset cron jobs
- [ ] Push notifications configured
- [ ] CloudKit schema complete
- [ ] TestFlight with 20 users (72hr test)
- [ ] A/B test pricing on small group

---

**READY TO SHIP IN 6 DAYS** 🚀

