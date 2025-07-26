# 🚀 Installation Guide for AI-CM (CryptoMiner Pro)

## ✅ **Installation Fixed and Verified!**

The installation issue has been resolved. The script was looking for files in hardcoded paths, but now we have flexible installation options.

## 📋 **Prerequisites**

- Ubuntu 20.04+ or compatible Linux distribution
- Sudo privileges
- Internet connection for downloading dependencies

## 🛠️ **Installation Options**

### **Option 1: Quick Installation (Recommended)**

```bash
# Clone the repository
git clone https://github.com/nmdata575/ai-cm.git
cd ai-cm

# Switch to release branch
git checkout release-2.03

# Run the GitHub-compatible installer
chmod +x install-github.sh
./install-github.sh
```

### **Option 2: Manual Installation**

```bash
# Clone the repository
git clone https://github.com/nmdata575/ai-cm.git
cd ai-cm
git checkout release-2.03

# Install prerequisites
sudo apt-get update
sudo apt-get install -y curl software-properties-common

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
# OR for containers: sudo mongod --dbpath /data/db --logpath /var/log/mongodb.log --fork

# Install Supervisor
sudo apt-get install -y supervisor

# Setup application
sudo mkdir -p /opt/cryptominer-pro
sudo chown $(whoami):$(whoami) /opt/cryptominer-pro
cp -r backend-nodejs frontend /opt/cryptominer-pro/

# Install dependencies
cd /opt/cryptominer-pro/backend-nodejs
npm install

cd ../frontend
npm install
npm run build

# Configure services (see supervisor configuration below)
# Start services
sudo supervisorctl restart all
```

### **Option 3: Quick Fix for Existing Issues**

If you're having installation problems:

```bash
# Run from your project directory
chmod +x quick-fix-install.sh
./quick-fix-install.sh
```

## ⚙️ **Supervisor Configuration**

The installer automatically creates this configuration in `/etc/supervisor/conf.d/cryptominer.conf`:

```ini
[group:mining_system]
programs=backend,frontend

[program:backend]
command=node server.js
directory=/opt/cryptominer-pro/backend-nodejs
user=yourusername
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/backend.err.log
stdout_logfile=/var/log/supervisor/backend.out.log
environment=NODE_ENV=production

[program:frontend]
command=npx serve -s build -l 3000
directory=/opt/cryptominer-pro/frontend
user=yourusername
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/frontend.err.log
stdout_logfile=/var/log/supervisor/frontend.out.log
```

## 🔍 **Testing Installation**

```bash
# Check service status
sudo supervisorctl status

# Test backend API
curl http://localhost:8001/api/health

# Test frontend (in browser)
# http://localhost:3000
```

## 🌐 **Access Your Application**

- **Frontend Dashboard**: http://localhost:3000
- **Backend API**: http://localhost:8001
- **Health Check**: http://localhost:8001/api/health

## 📊 **Service Management**

```bash
# Check status
sudo supervisorctl status

# Restart all services
sudo supervisorctl restart all

# Stop all services
sudo supervisorctl stop all

# Start specific service
sudo supervisorctl start mining_system:backend

# View logs
sudo tail -f /var/log/supervisor/backend.out.log
sudo tail -f /var/log/supervisor/frontend.out.log
```

## 🚨 **Troubleshooting**

### **Common Issues:**

1. **"Cannot find module 'crypto'" / Webpack Polyfill Errors**
   - **Error**: `Module not found: Error: Can't resolve 'crypto'` or similar for http, https, stream, util
   - **Solution**: Use the updated installation script:
     ```bash
     chmod +x install-complete-v2.sh
     ./install-complete-v2.sh
     ```
   - **Manual Fix**: Install webpack polyfills:
     ```bash
     cd frontend
     npm install --save-dev @craco/craco crypto-browserify stream-browserify https-browserify stream-http util assert url browserify-zlib buffer process
     # Create craco.config.js with webpack polyfills (see fix-webpack-build.sh)
     ```

2. **"cp: cannot stat '/app/backend-nodejs'"**
   - **Solution**: Use the `install-github.sh` script instead of `install-modern.sh`
   - **Cause**: Original script was hardcoded for specific paths

3. **HTML Webpack Plugin Error / Module not found**
   - **Error**: `Can't resolve '/opt/cryptominer-pro/frontend/node_modules/html-webpack-plugin/lib/loader.js'`
   - **Solution**: Run the webpack fix script:
     ```bash
     chmod +x fix-webpack-build.sh
     ./fix-webpack-build.sh
     ```
   - **Alternative**: Use exact package versions from working configuration

4. **MongoDB Connection Issues**
   - **Solution**: Start MongoDB manually: `sudo mongod --dbpath /data/db --logpath /var/log/mongodb.log --fork`
   - **Check**: `mongosh --eval "db.adminCommand('ping')"`

5. **Frontend Build Errors / CRACO Issues**
   - **Solution**: Ensure Node.js version is 18+: `node --version`
   - **Fix**: Clear npm cache: `npm cache clean --force`
   - **Reset**: Delete node_modules and reinstall: `rm -rf node_modules package-lock.json && npm install`
   - **CRACO Fix**: Make sure craco.config.js exists and package.json uses CRACO scripts

6. **Port Already in Use**
   - **Solution**: Kill existing processes:
     ```bash
     sudo lsof -ti:8001 | xargs kill -9
     sudo lsof -ti:3000 | xargs kill -9
     ```

7. **Permission Issues**
   - **Solution**: Ensure proper ownership:
     ```bash
     sudo chown -R $(whoami):$(whoami) /opt/cryptominer-pro
     ```

### **Log Locations:**
- Installation: `/tmp/cryptominer-install.log`
- Backend: `/var/log/supervisor/backend.out.log`
- Frontend: `/var/log/supervisor/frontend.out.log`
- MongoDB: `/var/log/mongodb.log`

## ✅ **Installation Success Indicators**

You'll know the installation is successful when:

- ✅ `sudo supervisorctl status` shows all services as RUNNING
- ✅ `curl http://localhost:8001/api/health` returns `{"status":"healthy"}`
- ✅ Frontend loads at http://localhost:3000 without errors
- ✅ No "Failed to fetch" errors in browser console
- ✅ Mining Control Center shows system information

## 🎉 **You're Ready!**

Once installed, you can:
- 🏃‍♂️ **Start Mining**: Select a cryptocurrency and configure your wallet
- 📊 **Monitor Performance**: View real-time mining statistics
- 🤖 **Use AI Features**: Get optimization recommendations
- ⚙️ **Customize Settings**: Add custom coins and configure mining parameters

**Repository**: https://github.com/nmdata575/ai-cm/tree/release-2.03