# 🌐 GitHub Pages Setup - Web Fallback Hosting

## ✅ **Files Are Ready!**

I've already created and pushed the web fallback to your repo:
- `docs/index.html` - Main landing page
- `docs/fart/index.html` - Fart attack fallback page

---

## 🚀 **3-Minute Setup**

### **Step 1: Enable GitHub Pages**

1. Go to your GitHub repo:
   ```
   https://github.com/Arjun0606/ThedailyPoop
   ```

2. Click **Settings** (top menu)

3. Scroll down and click **Pages** (left sidebar)

4. Under "Build and deployment":
   - **Source**: Deploy from a branch
   - **Branch**: `main`
   - **Folder**: `/docs`
   - Click **Save**

5. Wait 1-2 minutes for deployment

### **Step 2: Get Your URL**

After deployment, GitHub will show:
```
Your site is live at https://arjun0606.github.io/ThedailyPoop/
```

Your fart attack page will be at:
```
https://arjun0606.github.io/ThedailyPoop/fart/
```

### **Step 3: Update Your App Code**

Open `PoopDrop/Managers/FartAttackManager.swift` and update line 198:

**Change from:**
```swift
if let shareURL = URL(string: "https://thedailypoop.app/fart/\(attackID)") {
```

**Change to:**
```swift
if let shareURL = URL(string: "https://arjun0606.github.io/ThedailyPoop/fart/?id=\(attackID)") {
```

### **Step 4: Update Universal Links (AppDelegate.swift)**

The Universal Links will work once you set up the domain properly (see below).

For now, the deep links will still work via custom URL scheme.

---

## 🎯 **How It Works**

### **When Someone Clicks the Link:**

1. **Link Format:**
   ```
   https://arjun0606.github.io/ThedailyPoop/fart/?id=[attackID]
   ```

2. **If App Installed:**
   - iOS tries to open the app via Universal Links
   - Falls back to opening the web page

3. **If App NOT Installed:**
   - Web page opens in browser
   - Fart plays automatically
   - Download button prompts install

4. **JavaScript on Page:**
   - Parses `?id=[attackID]` from URL
   - Displays sender's username
   - Plays fart sound
   - Shows download button

---

## 🔧 **Testing**

### **Test the Web Page:**
```
https://arjun0606.github.io/ThedailyPoop/fart/?id=test123&sender=testuser
```

You should see:
- 💨 emoji bouncing
- "FART ATTACKED! by @testuser"
- Fart sound plays
- Download button

### **Test Attack Flow:**
1. In your app, create a fart attack
2. Share the link via Messages
3. Open link on a device without the app
4. Verify fart plays + download prompt shows

---

## 🌐 **Optional: Custom Domain**

If you own `thedailypoop.app` and want to use it:

### **Step 1: In GitHub Pages Settings:**
1. Under "Custom domain", enter: `thedailypoop.app`
2. Click **Save**
3. Check "Enforce HTTPS"

### **Step 2: In Your Domain Registrar (GoDaddy, Namecheap, etc.):**

Add these DNS records:

```
Type    Name    Value
----    ----    -----
A       @       185.199.108.153
A       @       185.199.109.153
A       @       185.199.110.153
A       @       185.199.111.153
CNAME   www     arjun0606.github.io
```

### **Step 3: Update App Code:**
Once the domain is active, change the URL back to:
```swift
if let shareURL = URL(string: "https://thedailypoop.app/fart/?id=\(attackID)") {
```

### **Step 4: Universal Links Setup:**
Upload `.well-known/apple-app-site-association` to your domain root (GitHub Pages handles this automatically if configured correctly).

---

## 📊 **What's Next**

### **Now:**
1. ✅ Files are pushed to GitHub
2. ⏳ Enable GitHub Pages (2 minutes)
3. ⏳ Update app code with correct URL
4. ⏳ Test the flow

### **Later (Optional):**
1. Buy `thedailypoop.app` domain (if you don't own it)
2. Configure custom domain in GitHub Pages
3. Set up Universal Links properly
4. Update app code to use custom domain

---

## 🎯 **Quick Start Checklist**

- [ ] Enable GitHub Pages in repo settings
- [ ] Wait for deployment (1-2 min)
- [ ] Test the URL: https://arjun0606.github.io/ThedailyPoop/fart/
- [ ] Update FartAttackManager.swift with correct URL
- [ ] Build and test in app
- [ ] Send a test fart attack!

---

## 💡 **Pro Tips**

### **If You Want a Shorter URL:**
Use a URL shortener (bit.ly, tinyurl.com) for sharing:
```
bit.ly/fart-attack → https://arjun0606.github.io/ThedailyPoop/fart/?id=123
```

### **If GitHub Pages Doesn't Work:**
Alternative free hosting:
- **Netlify**: Drag & drop the `docs` folder
- **Vercel**: Connect GitHub repo
- **Firebase**: `firebase init hosting`

### **For Analytics:**
Add Google Analytics to `docs/fart/index.html` to track:
- How many people click fart attack links
- Conversion rate (clicks → installs)
- Geographic data

---

## 🚀 **You're Almost There!**

Just enable GitHub Pages and update the URL in your code. That's it! 🎉

