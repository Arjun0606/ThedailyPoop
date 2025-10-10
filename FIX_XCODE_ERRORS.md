# Fix Xcode "Cannot find in scope" Errors

The new files (`ReferralCredit.swift`, `AttackActivity.swift`, `AttackReactionSheet.swift`) have been added to the Xcode project, but Xcode needs to refresh its build cache.

## Quick Fix (2 minutes)

### Option 1: Clean Build Folder (Recommended)
1. Open Xcode
2. Go to **Product** menu → **Clean Build Folder** (or press `Cmd + Shift + K`)
3. Close Xcode completely (Cmd + Q)
4. Re-open Xcode
5. Build the project (Cmd + B)

### Option 2: Derived Data Clean (If Option 1 doesn't work)
1. Close Xcode completely
2. Run these commands in Terminal:
```bash
cd ~/Library/Developer/Xcode/DerivedData
rm -rf PoopDrop-*
```
3. Re-open Xcode
4. Build the project (Cmd + B)

### Option 3: Full Reset (Nuclear option)
1. Close Xcode
2. Delete derived data:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```
3. Clean your project folder:
```bash
cd /Users/arjun/poopdrop
rm -rf PoopDrop.xcodeproj/xcuserdata
rm -rf PoopDrop.xcodeproj/project.xcworkspace/xcuserdata
```
4. Re-open Xcode
5. Let Xcode re-index (may take 1-2 minutes)
6. Build the project

## Why This Happens

Xcode caches module information in "Derived Data". When files are added programmatically to the project file (not through Xcode's UI), the cache can get out of sync. Cleaning the build folder forces Xcode to rebuild the module map and recognize the new files.

## Verification

After cleaning and rebuilding, you should see:
- ✅ No "Cannot find in scope" errors
- ✅ All imports working correctly
- ✅ Autocomplete working for new types

## If Still Not Working

If the errors persist after all three options:

1. **Verify files exist:**
```bash
ls -la PoopDrop/Models/ReferralCredit.swift
ls -la PoopDrop/Models/AttackActivity.swift
ls -la PoopDrop/Views/Components/AttackReactionSheet.swift
```

2. **Check project file has them:**
```bash
grep "ReferralCredit.swift" PoopDrop.xcodeproj/project.pbxproj
grep "AttackActivity.swift" PoopDrop.xcodeproj/project.pbxproj
grep "AttackReactionSheet.swift" PoopDrop.xcodeproj/project.pbxproj
```

3. **Manual add (last resort):**
   - Right-click on `Models` folder in Xcode
   - "Add Files to PoopDrop..."
   - Select the missing files
   - Make sure "Copy items if needed" is UNCHECKED
   - Make sure target "PoopDrop" is checked
   - Click Add

## Expected Result

After cleaning, you should see **0 errors** and be ready to continue with CloudKit setup!

