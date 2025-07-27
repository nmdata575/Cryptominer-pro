# MongoDB Installation Fix - Quick Setup Guide

## 🔧 Problem: MongoDB Package Not Available

The error you encountered is because MongoDB is no longer in default Ubuntu repositories.

## ✅ Solution: Updated Installation Methods

I've created **two installation methods** to fix this:

### Method 1: Official MongoDB Repository (Recommended)
```bash
tar -xzf cryptominer-pro-native-fixed.tar.gz
cd cryptominer-pro-native-fixed/
sudo ./install-native.sh
```

**What it does:**
- ✅ Adds MongoDB's official repository
- ✅ Installs MongoDB 7.0 from official source
- ✅ Supports Ubuntu 20.04+, Debian 11+, RHEL 8+
- ✅ Detects your OS version automatically

### Method 2: Simple Docker-based (If Method 1 Fails)
```bash
tar -xzf cryptominer-pro-native-fixed.tar.gz
cd cryptominer-pro-native-fixed/
sudo ./install-simple.sh
```

**What it does:**
- ✅ Uses Docker for MongoDB (no repository issues)
- ✅ Simpler installation process
- ✅ Works on any system with Docker support

## 🎯 Expected Results

Both methods will show your **real hardware**:

**4-core system:**
```
✅ REAL HARDWARE DETECTED:
  CPU Cores: 4
  CPU Model: [Your actual CPU]
  Architecture: x64
```

**128-core system:**
```
✅ REAL HARDWARE DETECTED:
  CPU Cores: 128
  CPU Model: AMD EPYC 7551 32-Core Processor
  Architecture: x64
```

## 🚀 Quick Test

After installation, verify at:
- **Web Interface**: http://localhost:3000 
- **API Test**: `curl http://localhost:8001/api/system/cpu-info`

The web interface will now show your actual CPU cores instead of the container-allocated 16!

## 🔧 Troubleshooting

**If MongoDB still fails:**
```bash
# Check MongoDB status
sudo systemctl status mongod

# Check Docker MongoDB (Method 2)
docker ps | grep cryptominer-mongodb

# Check service logs
sudo tail -f /var/log/supervisor/cryptominer-*.log
```

**Manual MongoDB installation:**
```bash
# Ubuntu/Debian
sudo apt install docker.io
docker run -d --name mongodb -p 27017:27017 mongo:7.0

# Then run the app installation without MongoDB step
```

Try **Method 1** first, then **Method 2** if you encounter any repository issues! 🎉