# 🚀 Quick Guide: Add Demo Mode Files to Xcode

## ⚡ **5-Minute Setup**

### **Option 1: Using Xcode (Recommended - 2 minutes)**

1. **Open Xcode**
   - Double-click `PoopDrop.xcodeproj`

2. **Add DemoModeManager.swift**
   - In left sidebar, find `Managers` folder
   - Right-click `Managers` → "Add Files to 'PoopDrop'"
   - Navigate to `PoopDrop/Managers/`
   - Select `DemoModeManager.swift`
   - ✅ Make sure "Copy items if needed" is checked
   - ✅ Make sure "Add to targets: PoopDrop" is checked
   - Click "Add"

3. **Add DemoModeView.swift**
   - In left sidebar, find `Views` folder
   - Right-click `Views` → "Add Files to 'PoopDrop'"
   - Navigate to `PoopDrop/Views/`
   - Select `DemoModeView.swift`
   - ✅ Make sure "Copy items if needed" is checked
   - ✅ Make sure "Add to targets: PoopDrop" is checked
   - Click "Add"

4. **Verify**
   - Press `Cmd + B` to build
   - Should build successfully!

---

### **Option 2: Using Terminal (Alternative - 30 seconds)**

Run these commands:

```bash
cd /Users/arjun/poopdrop

# This command will add the files to your Xcode project
open -a Xcode PoopDrop.xcodeproj

# Wait for Xcode to open, then:
# 1. In Xcode menu: File → Add Files to "PoopDrop"
# 2. Select both:
#    - PoopDrop/Managers/DemoModeManager.swift
#    - PoopDrop/Views/DemoModeView.swift
# 3. Click "Add"
```

---

## ✅ **Verification**

After adding the files, you should see:
- ✅ `DemoModeManager.swift` in `Managers` folder (left sidebar)
- ✅ `DemoModeView.swift` in `Views` folder (left sidebar)
- ✅ Build succeeds (`Cmd + B`)

---

## 🎯 **Next Steps After Adding Files:**

1. Edit `Info.plist` (remove tracking key)
2. Build & test demo mode
3. Archive & upload
4. Update App Store Connect
5. Submit for review

See `APPLE_REJECTION_FIX_DEMO_MODE.md` for complete instructions.

