# CryptoMiner Pro - Uninstall Guide

## 🗑️ Two Uninstall Options Available

### Option 1: Interactive Uninstall (Recommended)
```bash
sudo ./uninstall.sh
```

**Features:**
- ✅ **Interactive prompts** - Choose what to remove/keep
- ✅ **Backup configurations** - Saves your .env files to /tmp
- ✅ **Selective removal** - Keep Node.js, MongoDB, or Docker if needed
- ✅ **Complete cleanup** - Services, files, logs, aliases, user accounts
- ✅ **System cleanup** - Removes orphaned packages

**What it can remove:**
1. **Services & Configuration** - Supervisor configs and running services
2. **Application Files** - All CryptoMiner Pro files and directories  
3. **Docker Containers** - MongoDB container and volumes (if using simple install)
4. **MongoDB Database** - Complete MongoDB removal or just CryptoMiner database
5. **Node.js Runtime** - Complete Node.js and npm removal
6. **Log Files** - All CryptoMiner Pro logs
7. **Shell Aliases** - Command shortcuts from .bashrc/.zshrc
8. **User Accounts** - cryptominer user account (if created)
9. **System Cleanup** - Package cache and orphaned dependencies

### Option 2: Quick Uninstall (Fast)
```bash
sudo ./quick-uninstall.sh
```

**Features:**
- ✅ **Fast removal** - Minimal prompts
- ✅ **Keeps system tools** - Preserves Node.js, MongoDB, Docker
- ✅ **Complete app removal** - Removes all CryptoMiner Pro components
- ✅ **Safe for servers** - Won't break other applications

**What it removes:**
- All CryptoMiner Pro services and configs
- Application files from all standard locations
- Docker containers (cryptominer-mongodb only)
- Log files and aliases
- CryptoMiner database (keeps MongoDB server)

## 🎯 Quick Reference

### Just Remove the App (Keep Everything Else)
```bash
sudo ./quick-uninstall.sh
```

### Complete System Cleanup  
```bash
sudo ./uninstall.sh
# Then choose 'y' for everything you want to remove
```

### Manual Service Stop (Emergency)
```bash
# Stop all CryptoMiner services immediately
sudo supervisorctl stop cryptominer-native:*
sudo supervisorctl stop cryptominer-simple:*
sudo supervisorctl stop cryptominer-fixed:*

# Stop systemd services
sudo systemctl stop cryptominer-pro.service
sudo systemctl disable cryptominer-pro.service

# Kill any remaining processes
sudo pkill -f "cryptominer"
sudo pkill -f "node.*server.js"
```

### Manual File Cleanup (Emergency)
```bash
# Remove application directories
rm -rf ~/cryptominer-pro
sudo rm -rf /opt/cryptominer-pro

# Remove supervisor configs
sudo rm -f /etc/supervisor/conf.d/cryptominer-*.conf
sudo supervisorctl reread && sudo supervisorctl update

# Remove systemd services
sudo rm -f /etc/systemd/system/cryptominer-pro.service
sudo rm -f /etc/systemd/system/cryptominer*.service
sudo systemctl daemon-reload
```

## ⚠️ Important Notes

### Before Uninstalling
- **Stop mining operations** - Ensure no active mining before removal
- **Backup wallet info** - Save wallet addresses and pool configurations
- **Note custom settings** - The uninstaller backs up .env files to /tmp

### What Gets Preserved (Interactive Mode)
- **System packages** - Only removes if you explicitly choose
- **Other applications** - Won't affect other Node.js or MongoDB apps
- **Configuration backups** - Saved to /tmp/cryptominer-*-env-backup
- **User data** - Home directory and personal files untouched

### What Gets Removed (Both Modes)
- All CryptoMiner Pro application files
- Supervisor service configurations  
- Application-specific log files
- Shell command aliases
- CryptoMiner database (not MongoDB server in quick mode)

## 🔄 After Uninstalling

### Complete the Removal
```bash
# Restart terminal to clear aliases
exit
# Then open new terminal

# Reboot system to ensure all processes stopped
sudo reboot
```

### Verify Clean Removal
```bash
# Check for remaining processes
ps aux | grep -i crypto

# Check for remaining files
find /home -name "*cryptominer*" 2>/dev/null
find /opt -name "*cryptominer*" 2>/dev/null

# Check supervisor configs
ls /etc/supervisor/conf.d/ | grep crypto

# Check systemd services
systemctl list-units --all | grep crypto
ls /etc/systemd/system/ | grep crypto
ls /lib/systemd/system/ | grep crypto
```

## 🔄 Reinstalling Later

If you want to reinstall CryptoMiner Pro later:
```bash
# If you kept the installation package
tar -xzf cryptominer-pro-native-fixed.tar.gz
cd cryptominer-pro-native-fixed/
sudo ./install-native.sh
# or
sudo ./install-simple.sh
```

## 📞 Troubleshooting

### Services Won't Stop
```bash
# Force kill all related processes
sudo pkill -9 -f "node.*server.js"
sudo pkill -9 -f "cryptominer"
sudo pkill -9 mongod
```

### Files Won't Delete
```bash
# Check file permissions and ownership
ls -la ~/cryptominer-pro/
sudo chown -R $(whoami):$(whoami) ~/cryptominer-pro/
rm -rf ~/cryptominer-pro/
```

### MongoDB Issues
```bash
# If MongoDB won't remove properly
sudo systemctl stop mongod
sudo systemctl disable mongod
sudo apt-get remove --purge mongodb-org*
sudo rm -rf /var/lib/mongodb /var/log/mongodb /data/db
```

Both uninstall scripts are designed to be safe and thorough. Use the **interactive script** for maximum control, or the **quick script** for fast removal while preserving system tools! 🎉