# CloudKit Schema Configuration

This document outlines the CloudKit schema setup required for Poop Drop.

## Container Configuration

**Container Identifier**: `iCloud.com.poopdrop.app`

## Record Types

### 1. User Record Type

**Record Type Name**: `User`
**Database**: Private Database

| Field Name | Field Type | Indexed | Required |
|------------|------------|---------|----------|
| displayName | String | Yes | Yes |
| avatarURL | String | No | No |
| isPro | Int64 | Yes | No |
| streak | Int64 | Yes | No |
| city | String | Yes | No |
| createdAt | Date/Time | Yes | Yes |
| lastDropDate | Date/Time | No | No |
| totalDrops | Int64 | Yes | No |

**Indexes**:
- `displayName` (Queryable)
- `isPro` (Queryable)
- `streak` (Sortable)
- `city` (Queryable)
- `createdAt` (Sortable)
- `totalDrops` (Sortable)

### 2. Drop Record Type

**Record Type Name**: `Drop`
**Database**: Public Database

| Field Name | Field Type | Indexed | Required |
|------------|------------|---------|----------|
| creatorId | String | Yes | Yes |
| creatorName | String | Yes | Yes |
| createdAt | Date/Time | Yes | Yes |
| location | Location | Yes | Yes |
| skinId | String | No | No |
| caption | String | No | No |
| reactions | Bytes | No | No |
| sponsorCampaignId | String | Yes | No |

**Indexes**:
- `creatorId` (Queryable)
- `creatorName` (Queryable)
- `createdAt` (Sortable)
- `location` (Queryable for nearby searches)
- `sponsorCampaignId` (Queryable)

**Security Roles**:
- World readable
- Creator writable (for reactions updates)

### 3. SponsorCampaign Record Type

**Record Type Name**: `SponsorCampaign`
**Database**: Public Database

| Field Name | Field Type | Indexed | Required |
|------------|------------|---------|----------|
| brandName | String | Yes | Yes |
| assetName | String | No | No |
| startDate | Date/Time | Yes | Yes |
| endDate | Date/Time | Yes | No |
| actionType | String | Yes | Yes |
| actionPayload | Bytes | No | No |
| targetAudience | String | Yes | No |

**Indexes**:
- `brandName` (Queryable)
- `startDate` (Sortable)
- `endDate` (Sortable)
- `actionType` (Queryable)
- `targetAudience` (Queryable)

**Security Roles**:
- World readable
- Admin writable only

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

## Setup Instructions

### 1. CloudKit Dashboard Setup

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your app's container
3. Go to Schema → Record Types
4. Create the three record types above with exact field names and types

### 2. Indexes Configuration

For each record type, configure the indexes as specified above:
- Queryable: For fields used in predicates
- Sortable: For fields used in sort descriptors

### 3. Security Configuration

#### Drop Record Type
```
World: Readable
Creator: Writable (for reactions)
```

#### SponsorCampaign Record Type
```
World: Readable
Admin: Writable
```

#### User Record Type
```
Creator: Readable, Writable (Private Database)
```

### 4. Subscription Setup

Create subscriptions in CloudKit Dashboard:
1. Go to Subscriptions
2. Create Query Subscriptions for each record type
3. Configure notification settings for silent push

## Data Migration

### Initial Data Seeding

For testing and initial launch, seed the database with:

#### Sample Sponsor Campaigns
```swift
// Taco Bell Campaign
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

// Starbucks Seasonal Campaign
let starbucksCampaign = SponsorCampaign(
    brandName: "Starbucks",
    assetName: "🎃💩",
    endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
    actionType: "challenge",
    actionPayload: [
        "challenge": "Drop 5 Pumpkin Spice Poops",
        "reward": "Free PSL",
        "emoji": "🎃💩"
    ]
)
```

## Performance Considerations

### Query Optimization
- Use location-based queries with radius limits
- Implement pagination for large result sets
- Cache frequently accessed data locally

### Rate Limiting
- Implement client-side rate limiting for drop creation
- Server-side validation for subscription status
- Batch reaction updates to reduce API calls

## Monitoring and Analytics

### CloudKit Metrics to Track
- API request volume
- Error rates by operation type
- Database storage usage
- Subscription delivery success rates

### Custom Metrics
- Drop creation frequency
- Reaction engagement rates
- Sponsored content interaction rates
- Pro feature usage patterns

## Troubleshooting

### Common Issues

1. **CKErrorQuotaExceeded**
   - Implement local caching
   - Reduce query frequency
   - Optimize data size

2. **CKErrorNetworkUnavailable**
   - Implement offline mode
   - Queue operations for retry
   - Show appropriate user messaging

3. **CKErrorNotAuthenticated**
   - Check iCloud account status
   - Prompt user to sign in to iCloud
   - Handle account changes gracefully

### Debug Tools
- CloudKit Dashboard for data inspection
- Console app for CloudKit logs
- Xcode CloudKit debugging tools
