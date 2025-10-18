# 📋 CloudKit Schema Update Guide

## Changes Needed for Integration Features

### Drop Record Type

Add the following fields to support @mention integration:

```
Record Type: Drop

NEW FIELDS:
1. mentionedUserIDs
   - Type: String List
   - Optional: Yes
   - Description: Array of user IDs mentioned in this drop

2. mentionedUsernames  
   - Type: String List
   - Optional: Yes
   - Description: Array of usernames (for display) mentioned in this drop
```

---

## Step-by-Step Instructions

### For Development Schema:

1. Open https://icloud.developer.apple.com
2. Sign in with your Apple ID
3. Select "CloudKit Console"
4. Choose your app: "iCloud.com.poopdrop.app"
5. Select "Development" environment
6. Click on "Schema" tab
7. Find "Drop" record type
8. Click "Edit Fields"
9. Add new field:
   - Field Name: `mentionedUserIDs`
   - Field Type: `String List`
   - Check "Optional"
   - Click "Save"
10. Add second field:
    - Field Name: `mentionedUsernames`
    - Field Type: `String List`
    - Check "Optional"
    - Click "Save"
11. Click "Save Schema"

### For Production Schema:

**IMPORTANT:** Test in Development first!

Once tested and working:
1. Go to "Schema" tab
2. Click "Deploy to Production"
3. Review changes
4. Confirm deployment

---

## Code Changes (Already Complete ✅)

The following code changes have been implemented:

### Drop Model (`Drop.swift`)
```swift
// NEW fields added:
var mentionedUserIDs: [String] = []
var mentionedUsernames: [String] = []

// CloudKit serialization updated:
init?(from record: CKRecord) {
    self.mentionedUserIDs = record["mentionedUserIDs"] as? [String] ?? []
    self.mentionedUsernames = record["mentionedUsernames"] as? [String] ?? []
}

func toCKRecord() -> CKRecord {
    if !mentionedUserIDs.isEmpty {
        record["mentionedUserIDs"] = mentionedUserIDs
        record["mentionedUsernames"] = mentionedUsernames
    }
    return record
}
```

### GossipPost Model (`Gossip.swift`)
Already had mention support:
```swift
let mentionedUserIDs: [String]
let mentionedUsernames: [String]
var mentionedDropIDs: [String]
```

---

## Testing Checklist

After updating CloudKit schema:

1. ✅ Create a new drop with @mentions in caption
2. ✅ Verify mentions are saved to CloudKit
3. ✅ Verify mentions load correctly from CloudKit
4. ✅ Test cross-tab navigation (Drop → Gossip)
5. ✅ Test hot user badges on map pins
6. ✅ Deploy to Production schema

---

## Notes

- The code uses conditional saving (`if !mentionedUserIDs.isEmpty`) to avoid CloudKit errors on empty arrays
- Both fields are optional to maintain backward compatibility with existing drops
- Existing drops will have empty arrays by default

---

## Status

- ✅ Code implementation complete
- ⏳ CloudKit schema update (manual step required)
- ⏳ Testing in Development
- ⏳ Deployment to Production
