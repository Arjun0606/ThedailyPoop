# 💩 Poop Drop - iOS Social Lifestyle App

[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![CloudKit](https://img.shields.io/badge/CloudKit-Enabled-purple.svg)](https://developer.apple.com/icloud/cloudkit/)

> The most fun way to share your bathroom adventures with friends around the world! 🚽✨

SCREENSHOTS!!!!!
![Screenshot 2025-10-01 at 7 23 50 pm](https://github.com/user-attachments/assets/18f6a20f-f9d3-426a-b6fb-e723a8a5f3f9)


## 🎯 Overview

Poop Drop is a viral lifestyle/social app where users drop poops on a map, friends get notified, and culture drives monetization. Built with SwiftUI, CloudKit, and StoreKit 2 for a seamless iOS experience.

## ✨ Features

### 🆓 Free Features
- **Sign in with Apple** - Secure authentication
- **Drop Poops** - GPS-based poop dropping with 50-character captions
- **Interactive Feed** - See friends' drops with reactions
- **Map View** - Apple MapKit with custom poop pins
- **4 Emoji Reactions** - 😂 🤢 🔥 👏
- **Daily Streaks** - Track your consistency
- **Global Leaderboard** - City and global rankings
- **Social Sharing** - Share to TikTok/Instagram

### 👑 Pro Features ($3.99/month)
- **200-Word Captions** - Express yourself fully
- **Premium Poop Skins** - Rainbow 💩, disco 💩, gold 💩, seasonal skins
- **All Emoji Reactions** - Full emoji picker + custom packs
- **Animations** - Bounce, sparkle, flush effects
- **Sound Packs** - Fart packs, flush sounds
- **Exclusive Map Themes** - Dark luxury, cosmic galaxy, toilet-paper grid
- **Profile Flex** - Poop crown 👑, golden toilet badge 🏆
- **Monthly Drop Packs** - Exclusive content auto-delivered
- **Highlighted Leaderboard** - Stand out from the crowd

### 💰 Monetization
- **Sponsored Drops** - Seamless brand integration (Taco Bell 🌮💩 challenges)
- **Sponsored Reactions** - Brand-powered emojis ("🔥💩 by Hot Cheetos")
- **Seasonal Campaigns** - Limited-time brand collaborations
- **Sponsored Map Pins** - Optional coupon unlocks

## 🏗️ Architecture

### Tech Stack
- **Frontend**: SwiftUI + Combine
- **Backend**: CloudKit (iOS-native)
- **Authentication**: Sign in with Apple
- **Payments**: StoreKit 2
- **Maps**: Apple MapKit
- **Push Notifications**: APNs
- **Analytics**: Ready for Mixpanel/Firebase integration

### Project Structure
```
TheDailyPoop/
├── Models/
│   ├── User.swift              # User data model with CloudKit sync
│   ├── Drop.swift              # Poop drop model with location
│   └── SponsorCampaign.swift   # Sponsored content campaigns
├── Managers/
│   ├── AuthenticationManager.swift    # Sign in with Apple
│   ├── SubscriptionManager.swift      # StoreKit 2 Pro subscriptions
│   ├── CloudKitManager.swift          # Real-time data sync
│   └── LocationManager.swift          # GPS and location services
├── Views/
│   ├── OnboardingView.swift           # 3-screen playful intro
│   ├── AuthenticationView.swift       # Sign in with Apple UI
│   ├── MainTabView.swift              # Tab navigation with FAB
│   ├── DropComposerView.swift         # Free/Pro caption limits
│   ├── ReactionBarView.swift          # 4 emojis vs full picker
│   ├── DropCardView.swift             # Feed cards with sponsored content
│   ├── FeedView.swift                 # Main social feed
│   ├── MapView.swift                  # Custom poop pins + Pro themes
│   ├── LeaderboardView.swift          # Global/city rankings
│   └── ProfileView.swift              # Stats, achievements, Pro status
└── Extensions/
    └── StringExtensions.swift         # Caption limit utilities
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ deployment target
- Apple Developer Account (for CloudKit, Sign in with Apple, StoreKit)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/Arjun0606/poopdrop.git
   cd poopdrop
   ```

2. **Open in Xcode**
   ```bash
   open TheDailyPoop.xcodeproj
   ```

3. **Configure CloudKit**
   - Enable CloudKit capability in project settings
   - Set up CloudKit container: `iCloud.com.poopdrop.app`
   - Configure CloudKit schema with User, Drop, and SponsorCampaign record types

4. **Configure Sign in with Apple**
   - Enable Sign in with Apple capability
   - Add your Team ID to entitlements

5. **Configure StoreKit**
   - Set up subscription product: `com.poopdrop.pro.monthly`
   - Configure StoreKit testing in Xcode

6. **Update Bundle Identifier**
   - Change from `com.poopdrop.app` to your unique identifier
   - Update CloudKit container identifier accordingly

## 📱 App Flow

### User Journey
1. **Onboarding** - 3 playful screens introducing the concept
2. **Authentication** - Sign in with Apple for security
3. **Main App** - Tab-based navigation with floating poop FAB
4. **Drop Creation** - Location-based with Free/Pro limits
5. **Social Feed** - See friends' drops with reactions
6. **Map Exploration** - Discover nearby drops
7. **Leaderboards** - Compete globally and locally
8. **Pro Upgrade** - Unlock premium features

### Free vs Pro Logic
```swift
// Caption limits enforced throughout the app
let freeCharLimit = 50
let proWordLimit = 200

// Reaction system
let freeReactions = ["😂", "🤢", "🔥", "👏"]
let proReactions = "All emojis + custom packs"

// Server-side validation ensures limits are enforced
```

## 🎨 Design System

### Dark-Mode First
- Primary background: `Color.black`
- Cards: `Color.white.opacity(0.05)`
- Text: `Color.white` with opacity variants
- Accents: Brown, yellow (Pro), purple (sponsored)

### Typography
- Headlines: `.largeTitle`, `.title`, `.headline`
- Body: `.body`, `.subheadline`
- Captions: `.caption`, `.caption2`
- All text optimized for dark backgrounds

### Components
- **DropCardView**: Main content cards with reactions
- **ReactionBarView**: Free vs Pro emoji selection
- **ProUpsellView**: Conversion-optimized subscription flow
- **Custom Map Pins**: Animated poop pins with themes

## 🔐 Security & Privacy

### Data Protection
- **Sign in with Apple**: No email harvesting, privacy-first
- **CloudKit**: End-to-end encryption for user data
- **Location**: Only when-in-use permission, no background tracking
- **Minimal Data**: Only essential user information stored

### Content Moderation
- Report system for inappropriate drops
- Server-side content filtering
- Community guidelines enforcement

## 💳 Monetization Strategy

### Subscription Model
- **Freemium**: Core features free, premium features paid
- **$3.99/month**: Competitive pricing for social apps
- **High-value Pro features**: Significant feature differentiation

### Advertising Integration
- **Native sponsored content**: Seamless brand integration
- **Seasonal campaigns**: Limited-time brand partnerships
- **Optional interactions**: Users choose to engage with ads

## 📊 Analytics & Metrics

### Key Metrics to Track
- **DAU/MAU**: Daily/Monthly active users
- **Drop frequency**: Drops per user per day
- **Retention**: 1-day, 7-day, 30-day retention
- **Conversion**: Free to Pro subscription rate
- **Engagement**: Reactions, shares, time in app

### Conversion Funnels
1. **Onboarding completion rate**
2. **First drop creation**
3. **Social engagement** (reactions, shares)
4. **Pro feature discovery**
5. **Subscription conversion**

## 🚀 Deployment

### TestFlight Distribution
1. Archive the app in Xcode
2. Upload to App Store Connect
3. Configure TestFlight testing
4. Invite beta testers
5. Gather feedback and iterate

### App Store Submission
- Complete App Store metadata
- Prepare screenshots and app preview
- Submit for review
- Monitor for approval

## 🔮 Future Enhancements

### Phase 2 Features
- **Friends System**: Add/follow friends
- **Push Notifications**: Real-time drop alerts
- **Advanced Analytics**: User behavior insights
- **A/B Testing**: Optimize conversion flows

### Phase 3 Features
- **Android Version**: Cross-platform expansion
- **Web Dashboard**: Analytics for brands
- **API Integration**: Third-party partnerships
- **Advanced Monetization**: Premium brand features

## 🤝 Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests for any improvements.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Apple for SwiftUI, CloudKit, and StoreKit frameworks
- The iOS development community for inspiration and support
- Beta testers for valuable feedback

---

**Ready to drop it like it's hot?** 💩🔥

For questions, support, or business inquiries, contact us at karjunvarma2001@gmail.com

[Download on the App Store](https://apps.apple.com/app/poop-drop) (Coming Soon!)
