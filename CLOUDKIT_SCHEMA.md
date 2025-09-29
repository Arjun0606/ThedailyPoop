# CloudKit Schema Configuration

This document outlines the CloudKit schema setup required for PoopDrop. **Updated to match current implementation.**

## Container Configuration

**Container Identifier**: `iCloud.com.poopdrop.app`

## Record Types

### 1. User Record Type

**Record Type Name**: `User`
**Database**: Private Database

| Field Name | Field Type | Indexed | Required | Notes |
|------------|------------|---------|----------|-------|
| username | String | Yes | Yes | Unique username (combines display name and username) |
| dateOfBirth | Date/Time | No | Yes | Required for age verification |
| gender | String | No | Yes | "Male", "Female", or "Custom" |
| appleUserID | String | Yes | Yes | Link to Apple ID authentication |
| avatarURL | String | No | No | Profile picture URL |
| streak | Int64 | Yes | No | Current consecutive days streak |
| createdAt | Date/Time | Yes | Yes | Account creation date |
| lastDropDate | Date/Time | No | No | Last poop logging date |
| totalDrops | Int64 | Yes | No | Total lifetime poops |
| maxDropsInDay | Int64 | No | No | Highest daily poop count |
| longestNoPoopStreak | Int64 | No | No | Longest constipation streak |
| friends | Bytes | No | No | JSON array of friend user IDs |
| friendRequests | Bytes | No | No | JSON array of pending requests |
| lastStreakDate | Date/Time | No | No | Last streak maintenance date |
| isActive | Int64 | No | No | Account status (1=active, 0=inactive) |
| lastSeen | Date/Time | No | No | Last app activity |

**Indexes**:
- `username` (Queryable)
- `appleUserID` (Queryable)
- `streak` (Sortable)
- `createdAt` (Sortable)
- `totalDrops` (Sortable)

### 2. Drop Record Type

**Record Type Name**: `Drop`
**Database**: Public Database

| Field Name | Field Type | Indexed | Required | Notes |
|------------|------------|---------|----------|-------|
| userID | String | Yes | Yes | Drop creator's user ID |
| username | String | Yes | Yes | Creator's username (denormalized) |
| timestamp | Date/Time | Yes | Yes | When drop was created |
| location | Location | Yes | No | GPS coordinates (optional for "no poop" entries) |
| city | String | Yes | No | City name from reverse geocoding |
| country | String | No | No | Country for badge tracking |
| continent | String | No | No | Continent for badge tracking |
| skinId | String | No | No | Custom emoji (default: 💩) |
| caption | String | No | No | User caption (200 words max) |
| sponsorCampaignID | String | Yes | No | Link to sponsor campaign |
| isNoPoop | Int64 | No | No | "No poop" streak entry (1=yes, 0=no) |
| isSponsored | Int64 | Yes | No | Sponsored content flag (1=yes, 0=no) |
| reactionCount | Int64 | Yes | No | Total reactions count |
| commentCount | Int64 | No | No | Total comments count |
| expiresAt | Date/Time | Yes | Yes | Map visibility expiry (15 days) |
| isVisible | Int64 | No | No | Soft delete flag (1=visible, 0=hidden) |

**Indexes**:
- `userID` (Queryable)
- `username` (Queryable)
- `timestamp` (Sortable)
- `location` (Queryable for nearby searches)
- `city` (Queryable)
- `sponsorCampaignID` (Queryable)
- `isSponsored` (Queryable)
- `expiresAt` (Sortable)

**Security Roles**:
- World readable
- Creator writable

### 3. SponsorCampaign Record Type

**Record Type Name**: `SponsorCampaign`
**Database**: Public Database

| Field Name | Field Type | Indexed | Required | Notes |
|------------|------------|---------|----------|-------|
| brandName | String | Yes | Yes | Sponsor brand name |
| assetName | String | No | No | Custom emoji or asset identifier |
| startDate | Date/Time | Yes | Yes | Campaign start date |
| endDate | Date/Time | Yes | No | Campaign end date (null = indefinite) |
| actionType | String | Yes | Yes | "coupon", "challenge", "badge", "reaction", "sponsored_drop" |
| actionPayload | Bytes | No | No | JSON data for campaign actions |
| targetAudience | String | Yes | No | Targeting criteria |

**Indexes**:
- `brandName` (Queryable)
- `startDate` (Sortable)
- `endDate` (Sortable)
- `actionType` (Queryable)
- `targetAudience` (Queryable)

**Security Roles**:
- World readable
- Admin writable only

### 4. Reaction Record Type ⭐ NEW

**Record Type Name**: `Reaction`
**Database**: Public Database

| Field Name | Field Type | Indexed | Required | Notes |
|------------|------------|---------|----------|-------|
| dropID | String | Yes | Yes | Target drop ID |
| userID | String | Yes | Yes | Reactor's user ID |
| username | String | Yes | Yes | Reactor's username (denormalized) |
| reactionType | String | Yes | Yes | "emoji" or "text" |
| emoji | String | No | No | Emoji reaction (all iOS emojis) |
| textContent | String | No | No | Text reaction (200 words max) |
| timestamp | Date/Time | Yes | Yes | Reaction creation date |
| isVisible | Int64 | No | No | Moderation flag (1=visible, 0=hidden) |

**Indexes**:
- `dropID` (Queryable)
- `userID` (Queryable)
- `reactionType` (Queryable)
- `timestamp` (Sortable)

**Security Roles**:
- World readable
- Creator writable

### 5. Friendship Record Type ⭐ NEW

**Record Type Name**: `Friendship`
**Database**: Private Database

| Field Name | Field Type | Indexed | Required | Notes |
|------------|------------|---------|----------|-------|
| requesterID | String | Yes | Yes | Who sent the friend request |
| recipientID | String | Yes | Yes | Who received the request |
| status | String | Yes | Yes | "pending", "accepted", "blocked", "declined" |
| createdAt | Date/Time | Yes | Yes | Request creation date |
| acceptedAt | Date/Time | No | No | Friendship establishment date |

**Indexes**:
- `requesterID` (Queryable)
- `recipientID` (Queryable)
- `status` (Queryable)
- `createdAt` (Sortable)

**Security Roles**:
- Creator readable/writable
- Friend readable (when accepted)

### 6. Notification Record Type ⭐ NEW

**Record Type Name**: `Notification`
**Database**: Private Database

| Field Name | Field Type | Indexed | Required | Notes |
|------------|------------|---------|----------|-------|
| recipientID | String | Yes | Yes | Notification recipient |
| senderID | String | Yes | Yes | Notification sender |
| dropID | String | No | No | Related drop (for poop notifications) |
| type | String | Yes | Yes | "poop_drop", "friend_request", "friend_accepted", "streak_break", "badge_earned", "reaction" |
| title | String | No | Yes | Notification title |
| body | String | No | Yes | Notification body text |
| soundFile | String | No | No | Random bathroom sound file name |
| isRead | Int64 | Yes | No | Read status (1=read, 0=unread) |
| timestamp | Date/Time | Yes | Yes | Notification creation date |
| deliveredAt | Date/Time | No | No | Delivery timestamp |

**Indexes**:
- `recipientID` (Queryable)
- `type` (Queryable)
- `isRead` (Queryable)
- `timestamp` (Sortable)

**Security Roles**:
- Creator readable/writable

### 7. UserSession Record Type ⭐ NEW

**Record Type Name**: `UserSession`
**Database**: Private Database

| Field Name | Field Type | Indexed | Required | Notes |
|------------|------------|---------|----------|-------|
| userID | String | Yes | Yes | Session owner |
| sessionStart | Date/Time | Yes | Yes | App open timestamp |
| sessionEnd | Date/Time | No | No | App close timestamp |
| dropsViewed | Int64 | No | No | Engagement metric |
| adsViewed | Int64 | No | No | Revenue tracking |
| mapInteractions | Int64 | No | No | Feature usage tracking |
| appVersion | String | Yes | Yes | Version tracking |
| deviceType | String | No | No | iOS device analytics |

**Indexes**:
- `userID` (Queryable)
- `sessionStart` (Sortable)
- `appVersion` (Queryable)

**Security Roles**:
- Creator readable/writable

## Subscriptions

### Drop Subscription
- **Record Type**: Drop
- **Predicate**: `TRUEPREDICATE`
- **Options**: Fires on record creation and update
- **Notification**: Silent push notification

### User Subscription (Private)
- **Record Type**: User
- **Predicate**: `TRUEPREDICATE`
- **Options**: Fires on record creation and update
- **Database**: Private

### SponsorCampaign Subscription
- **Record Type**: SponsorCampaign
- **Predicate**: `endDate == NIL OR endDate > CAST(CURRENT_TIMESTAMP, "Date")`
- **Options**: Fires on record creation and update

### Reaction Subscription ⭐ NEW
- **Record Type**: Reaction
- **Predicate**: `TRUEPREDICATE`
- **Options**: Fires on record creation
- **Notification**: Silent push notification

### Friendship Subscription ⭐ NEW
- **Record Type**: Friendship
- **Predicate**: `TRUEPREDICATE`
- **Options**: Fires on record creation and update
- **Database**: Private

### Notification Subscription ⭐ NEW
- **Record Type**: Notification
- **Predicate**: `TRUEPREDICATE`
- **Options**: Fires on record creation
- **Database**: Private

## Setup Instructions

### 1. CloudKit Dashboard Setup

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your app's container
3. Go to Schema → Record Types
4. Create all seven record types above with exact field names and types

### 2. Database Assignment

**Public Database**:
- Drop
- SponsorCampaign
- Reaction

**Private Database**:
- User
- Friendship
- Notification
- UserSession

### 3. Indexes Configuration

For each record type, configure the indexes as specified above:
- Queryable: For fields used in predicates
- Sortable: For fields used in sort descriptors

### 4. Security Configuration

#### Public Database Records
```
Drop, SponsorCampaign, Reaction:
- World: Readable
- Creator: Writable
```

#### Private Database Records
```
User, Friendship, Notification, UserSession:
- Creator: Readable, Writable
```

#### Special Cases
```
SponsorCampaign:
- Admin: Writable (only admins can create campaigns)

Friendship:
- Friend: Readable (when status = "accepted")
```

### 5. Subscription Setup

Create subscriptions in CloudKit Dashboard:
1. Go to Subscriptions
2. Create Query Subscriptions for each record type
3. Configure notification settings for silent push
4. Set up proper database targeting (Public vs Private)

## Key Changes from Original Schema

### Removed Fields
- `isPro` (Pro features removed)
- `displayName` (merged into `username`)
- `city` from User (now in Drop only)
- `creatorId`/`creatorName` from Drop (now `userID`/`username`)
- `createdAt` from Drop (now `timestamp`)
- `reactions` field from Drop (now separate Reaction records)

### Added Fields
- **User**: `dateOfBirth`, `gender`, `appleUserID`, `isActive`, `lastSeen`, `maxDropsInDay`, `longestNoPoopStreak`, `friends`, `friendRequests`, `lastStreakDate`
- **Drop**: `userID`, `username`, `timestamp`, `city`, `country`, `continent`, `reactionCount`, `commentCount`, `expiresAt`, `isVisible`, `isNoPoop`
- **SponsorCampaign**: Enhanced with proper action system

### New Record Types
- **Reaction**: Separate emoji and text reactions
- **Friendship**: Proper friend relationship management
- **Notification**: Comprehensive notification system
- **UserSession**: Analytics and session tracking

## Data Migration Strategy

### From Old Schema
1. **User Records**: Map `displayName` → `username`, add required `dateOfBirth`/`gender`
2. **Drop Records**: Map `creatorId` → `userID`, `createdAt` → `timestamp`, extract reactions to separate records
3. **Create New Records**: Migrate friend lists to Friendship records, create initial UserSession records

### Initial Data Seeding

#### Sample Sponsor Campaigns
```swift
let tacoBellCampaign = SponsorCampaign(
    brandName: "Taco Bell",
    assetName: "🌮💩",
    actionType: "sponsored_drop",
    actionPayload: [
        "emoji": "🌮💩",
        "discount": "20% off next order",
        "code": "POOP20"
    ]
)
```

## Performance Considerations

### Query Optimization
- Use location-based queries with radius limits
- Implement pagination for large result sets (especially Reactions)
- Cache frequently accessed data locally
- Index friend relationships for fast friend drop queries

### Rate Limiting
- Implement client-side rate limiting for drop creation
- Batch reaction updates to reduce API calls
- Limit notification creation to prevent spam

### Storage Optimization
- User Sessions: Batch upload, clean old sessions periodically
- Reactions: Implement reaction count caching on Drop records
- Notifications: Auto-expire old notifications (30 days)

## Monitoring and Analytics

### CloudKit Metrics to Track
- API request volume by record type
- Error rates by operation type
- Database storage usage
- Subscription delivery success rates

### Custom Metrics
- Drop creation frequency
- Reaction engagement rates
- Friend network growth
- Session duration and engagement
- Ad interaction rates

## Troubleshooting

### Common Issues

1. **CKErrorQuotaExceeded**
   - Implement local caching for User and Friend data
   - Reduce Reaction query frequency
   - Batch UserSession uploads

2. **CKErrorNetworkUnavailable**
   - Implement offline mode for core features
   - Queue operations for retry
   - Show appropriate user messaging

3. **CKErrorNotAuthenticated**
   - Check iCloud account status
   - Handle Apple ID authentication failures
   - Graceful account switching

### Debug Tools
- CloudKit Dashboard for data inspection
- Console app for CloudKit logs
- Xcode CloudKit debugging tools
- Custom analytics dashboard for UserSession data