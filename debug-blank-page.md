# Debug Blank Page - Step by Step Guide

## 🕵️ The blank page at localhost:3000 indicates a JavaScript error is preventing the React app from loading.

## 🔧 **IMMEDIATE SOLUTION:**

### **Step 1: Run the automated fix**
```bash
# Run this as user 'chris'
./fix-blank-frontend.sh
```

### **Step 2: Check browser console for errors**

1. **Open localhost:3000 in your browser**
2. **Press F12** (or right-click → Inspect Element)
3. **Click the "Console" tab**
4. **Look for RED error messages**

## 🚨 **Common JavaScript Errors & Solutions:**

### **Error 1: "Cannot read property of undefined"**
**Cause:** Backend API not responding
**Fix:** Ensure backend is running
```bash
curl http://localhost:8001/api/health
sudo supervisorctl status cryptominer-backend
```

### **Error 2: "Network Error" or "Failed to fetch"**
**Cause:** CORS or API connection issues
**Fix:** Check backend URL in .env file
```bash
# Should be: REACT_APP_BACKEND_URL=http://localhost:8001
cat ~/Cryptominer-pro/frontend/.env
```

### **Error 3: "Module not found" or "Cannot resolve module"**
**Cause:** Missing dependencies
**Fix:** Reinstall dependencies
```bash
cd ~/Cryptominer-pro/frontend
rm -rf node_modules package-lock.json
npm install
```

### **Error 4: "Uncaught SyntaxError"**
**Cause:** JavaScript compilation error
**Fix:** Check React build
```bash
cd ~/Cryptominer-pro/frontend
npm run build
```

## 🔍 **Advanced Debugging:**

### **Check if React is mounting:**
1. In browser console, type: `document.getElementById('root')`
2. Should show: `<div id="root">...</div>`
3. If empty: `<div id="root"></div>`, React isn't mounting

### **Check network requests:**
1. Open **Network** tab in browser developer tools
2. Refresh the page
3. Look for failed requests (RED status codes)
4. Check if `/api/health` or other API calls are failing

### **Check React error boundary:**
1. Look for white screen with error message
2. Check console for React component errors
3. Look for stack traces pointing to specific components

## 🛠️ **Manual Fix Steps:**

If the automated script doesn't work, try these manual steps:

```bash
# 1. Stop all services
sudo supervisorctl stop cryptominer-frontend

# 2. Clear port 3000
sudo lsof -ti:3000 | xargs -r sudo kill -9

# 3. Fix dependencies
cd ~/Cryptominer-pro/frontend
npm install

# 4. Test manual start
npm start
# (Press Ctrl+C after testing)

# 5. Restart service
sudo supervisorctl start cryptominer-frontend
```

## ✅ **Expected Result:**

After fixing, you should see:
- **CryptoMiner Pro Dashboard** loading
- **Navigation menu** on the left
- **Mining controls** and metrics
- **No JavaScript errors** in browser console

## 🌐 **If still blank:**

1. **Hard refresh**: Ctrl+F5 (Windows) or Cmd+Shift+R (Mac)
2. **Clear browser cache**: Settings → Clear browsing data
3. **Try different browser**: Chrome, Firefox, Edge
4. **Check if content is loading**: View page source (Ctrl+U)

## 📱 **Contact Support:**

If none of these steps work, share:
1. **Browser console errors** (screenshot of F12 Console tab)
2. **Network tab errors** (failed requests)
3. **Output of:** `sudo supervisorctl status`
4. **Output of:** `curl http://localhost:8001/api/health`