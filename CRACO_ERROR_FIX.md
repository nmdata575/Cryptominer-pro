# CryptoMiner Pro - CRACO Configuration Error Fix

## 🚨 Problem Description

The frontend is failing to start with this error:
```
Error: craco: Config file not found. check if file exists at root (craco.config.ts, craco.config.js, .cracorc.js, .cracorc.json, .cracorc.yaml, .cracorc)
```

## 🔍 Root Cause

**CRACO** (Create React App Configuration Override) is used in the CryptoMiner Pro frontend to configure webpack polyfills for Node.js modules (crypto, buffer, stream, etc.) that are needed for cryptocurrency mining operations.

The error occurs because:
1. The `craco.config.js` file wasn't copied during installation
2. The frontend package.json uses `craco start` instead of `react-scripts start`
3. Without the CRACO config, the app can't start

## 🛠️ Quick Fix Solutions

### Option 1: Use the Fix Script (Recommended)

```bash
# Run the automated fix script
./fix-frontend-config.sh
```

This script will:
- ✅ Copy missing `craco.config.js` from source
- ✅ Copy other config files (`tailwind.config.js`, `postcss.config.js`, `.env`)
- ✅ Set proper permissions
- ✅ Restart the frontend service

### Option 2: Manual Fix

```bash
# Navigate to your installation directory
cd ~/Cryptominer-pro/frontend

# Copy the missing configuration file
cp /app/frontend/craco.config.js ./
cp /app/frontend/tailwind.config.js ./
cp /app/frontend/postcss.config.js ./
cp /app/frontend/.env ./

# Set permissions
chmod 644 *.js *.json

# Restart the frontend
sudo supervisorctl restart cryptominer-frontend
```

### Option 3: Verify and Diagnose

```bash
# Check what's missing
./check-frontend-setup.sh

# This will show you exactly what files are missing
```

## 📋 Required Configuration Files

The frontend needs these files to work properly:

### 1. **craco.config.js** (Critical)
```javascript
const webpack = require('webpack');

module.exports = {
  webpack: {
    configure: (webpackConfig) => {
      // Add polyfills for Node.js core modules
      webpackConfig.resolve.fallback = {
        "crypto": require.resolve("crypto-browserify"),
        "stream": require.resolve("stream-browserify"),
        // ... other polyfills
      };
      return webpackConfig;
    },
  },
};
```

### 2. **package.json scripts** should use CRACO:
```json
{
  "scripts": {
    "start": "craco start",
    "build": "craco build",
    "test": "craco test"
  }
}
```

### 3. **.env** file:
```bash
REACT_APP_BACKEND_URL=http://localhost:8001
GENERATE_SOURCEMAP=false
SKIP_PREFLIGHT_CHECK=true
```

## 🔧 Why CRACO is Needed

CryptoMiner Pro frontend uses Node.js modules for cryptocurrency operations:
- **crypto-browserify**: For hash calculations
- **buffer**: For binary data handling  
- **stream-browserify**: For data streams
- **process**: For environment variables

Modern React apps run in browsers that don't have these Node.js modules, so CRACO configures webpack to include browser-compatible versions.

## ✅ Verification Steps

After applying the fix:

1. **Check files exist:**
   ```bash
   ls -la ~/Cryptominer-pro/frontend/craco.config.js
   ls -la ~/Cryptominer-pro/frontend/tailwind.config.js  
   ls -la ~/Cryptominer-pro/frontend/.env
   ```

2. **Check service status:**
   ```bash
   cryptominer status
   # or
   sudo supervisorctl status cryptominer-frontend
   ```

3. **Check logs for errors:**
   ```bash
   tail -f ~/.local/log/cryptominer/frontend.log
   ```

4. **Test the web interface:**
   ```bash
   curl http://localhost:3000
   # Should return HTML, not error
   ```

## 🚀 Expected Results

After fixing:
- ✅ Frontend starts without CRACO errors
- ✅ Web dashboard loads at http://localhost:3000
- ✅ Mining controls and cryptocurrency features work
- ✅ No webpack compilation errors

## 📞 Troubleshooting

### If the fix script doesn't work:

1. **Check source files exist:**
   ```bash
   ls -la /app/frontend/craco.config.js
   ```

2. **Manual copy:**
   ```bash
   sudo cp /app/frontend/craco.config.js ~/Cryptominer-pro/frontend/
   sudo chown $(whoami):$(whoami) ~/Cryptominer-pro/frontend/craco.config.js
   ```

3. **Reinstall dependencies:**
   ```bash
   cd ~/Cryptominer-pro/frontend
   rm -rf node_modules package-lock.json
   npm install
   ```

### If you still get errors:

1. Check if you have the correct Node.js version (v20+)
2. Verify all dependencies are installed
3. Check file permissions (should be owned by your user)
4. Look for syntax errors in configuration files

## 🎯 Prevention for Future Installations

The updated installation script (`install-enhanced-v2-fixed.sh`) now includes:
- Enhanced file detection
- Explicit copying of configuration files
- Better error handling
- Validation of required files

This should prevent the CRACO error in future installations.