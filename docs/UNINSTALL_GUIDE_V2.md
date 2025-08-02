# CryptoMiner Pro v2.0 - Uninstall Guide

## 🗑️ Enhanced Uninstall Script

The new `uninstall-enhanced-v2.sh` script provides complete removal of CryptoMiner Pro v2.0 installations created by `install-enhanced-v2.sh`.

## 🎯 What Gets Removed

### Core Application Components
- ✅ **Application Directory**: `/opt/cryptominer-pro/` (complete removal)
- ✅ **Service User**: `cryptominer` user account and home directory
- ✅ **Process Management**: Supervisor configuration files
- ✅ **Web Server**: Nginx reverse proxy configuration
- ✅ **System Service**: Systemd service for auto-start
- ✅ **Firewall Rules**: UFW rules for mining ports
- ✅ **Log Files**: Application logs in `/var/log/cryptominer/`

### Optional System Components
- 🔶 **MongoDB**: Database server (optional removal)
- 🔶 **Node.js**: Runtime environment (optional removal)  
- 🔶 **Nginx**: Web server (optional removal)
- 🔶 **Supervisor**: Process manager (optional removal)

## 📋 Usage Options

### Interactive Mode (Recommended)
```bash
# Download and run the uninstaller
chmod +x uninstall-enhanced-v2.sh
./uninstall-enhanced-v2.sh
```

The interactive mode will:
1. Detect the installation automatically
2. Ask what components to remove
3. Confirm each major action
4. Provide detailed feedback

### Command Line Options
```bash
# Force removal without prompts
./uninstall-enhanced-v2.sh --force

# Remove everything including MongoDB and data
./uninstall-enhanced-v2.sh --remove-mongodb --remove-all-data

# Remove only application, keep system packages
./uninstall-enhanced-v2.sh --non-interactive

# Complete system cleanup
./uninstall-enhanced-v2.sh --remove-mongodb --remove-nodejs --remove-nginx --remove-supervisor --remove-all-data --force
```

### Available Flags
- `--remove-mongodb` - Remove MongoDB (⚠️ deletes all mining data)
- `--remove-nodejs` - Remove Node.js (may affect other applications)
- `--remove-nginx` - Remove Nginx (may affect other websites)
- `--remove-supervisor` - Remove Supervisor (may affect other services)
- `--remove-all-data` - Remove all user data and logs permanently
- `--force` - Force removal without confirmations
- `--non-interactive` - Run without user prompts
- `--help` - Show help message

## 🛡️ Safety Features

### Data Protection
- **Automatic Backups**: User data and logs backed up to `/tmp/` before removal
- **Confirmation Prompts**: Multiple confirmations for destructive actions
- **Selective Removal**: Choose what to keep and what to remove
- **System Package Protection**: Optional removal of system-wide packages

### Installation Detection
- **Smart Detection**: Automatically finds v2.0 installations
- **Component Checking**: Verifies each component before removal
- **Safe Defaults**: Conservative approach to system package removal

## 📊 Uninstall Process

### Step-by-Step Process
1. **Pre-flight Checks**: Verify sudo access and detect installation
2. **Service Shutdown**: Stop all CryptoMiner Pro services gracefully
3. **Application Removal**: Remove application files and directories
4. **User Cleanup**: Remove service user and associated data
5. **Configuration Cleanup**: Remove supervisor, nginx, and systemd configs
6. **System Cleanup**: Remove firewall rules and optional packages
7. **Final Cleanup**: System package cleanup and verification

### Backup Strategy
Unless `--remove-all-data` is specified:
- User data backed up to `/tmp/cryptominer-backup-YYYYMMDD_HHMMSS/`
- Log files backed up to `/tmp/cryptominer-logs-YYYYMMDD_HHMMSS/`
- Backups include mining session data and AI training data

## 🔍 Verification

The script automatically verifies removal by checking:
- ✅ Installation directory removal
- ✅ Service user deletion
- ✅ Configuration file cleanup
- ✅ Service status confirmation
- ✅ System package status

## ⚠️ Important Warnings

### Data Loss Warnings
- **MongoDB Removal**: `--remove-mongodb` permanently deletes all mining data
- **Complete Data Removal**: `--remove-all-data` skips backup creation
- **System Package Removal**: May affect other applications using the same packages

### System Impact
- **Nginx Removal**: May affect other websites hosted on the same server
- **Node.js Removal**: May affect other Node.js applications
- **Supervisor Removal**: May affect other services managed by Supervisor

## 🔧 Manual Cleanup

If automatic uninstall fails, manual cleanup steps:

### Stop Services
```bash
sudo supervisorctl stop all
sudo systemctl stop cryptominer-pro.service
sudo systemctl stop mongod
```

### Remove Files
```bash
sudo rm -rf /opt/cryptominer-pro
sudo rm -rf /var/log/cryptominer
sudo userdel -r cryptominer
```

### Remove Configurations
```bash
sudo rm -f /etc/supervisor/conf.d/cryptominer-*.conf
sudo rm -f /etc/nginx/sites-*/cryptominer-pro
sudo rm -f /etc/systemd/system/cryptominer-pro.service
```

### System Cleanup
```bash
sudo supervisorctl reread && sudo supervisorctl update
sudo systemctl daemon-reload
sudo nginx -t && sudo systemctl reload nginx
```

## 🆘 Troubleshooting

### Common Issues

**Permission Denied**
```bash
# Ensure sudo access
sudo -v

# Check file permissions
ls -la uninstall-enhanced-v2.sh
chmod +x uninstall-enhanced-v2.sh
```

**Services Won't Stop**
```bash
# Force stop services
sudo pkill -f cryptominer
sudo systemctl stop mongod --force
```

**Configuration Conflicts**
```bash
# Check nginx configuration
sudo nginx -t

# Reload supervisor
sudo supervisorctl reread
sudo supervisorctl update
```

### Recovery Options

**Partial Uninstall Recovery**
- Backups are created in `/tmp/` with timestamps
- Restore from backups if needed
- Re-run uninstaller with different options

**System Package Recovery**
```bash
# Reinstall system packages if needed
sudo apt update
sudo apt install nginx supervisor mongodb-org nodejs
```

## 📈 Post-Uninstall Verification

### Check System Status
```bash
# Verify services removed
sudo systemctl status cryptominer-pro.service
sudo supervisorctl status

# Check current user (should still exist - we use current user)
whoami

# Verify file cleanup  
ls -la ~/Cryptominer-pro  # Should not exist after uninstall
ls -la ~/.local/log/cryptominer  # Should not exist after uninstall
```

### System Health Check
```bash
# Check nginx (if preserved)
sudo nginx -t
sudo systemctl status nginx

# Check supervisor (if preserved)
sudo supervisorctl status

# Check MongoDB (if preserved)
sudo systemctl status mongod
```

## 🔄 Reinstallation

After uninstallation, you can reinstall using:
```bash
# Fresh installation
./install-enhanced-v2.sh

# Or restore from backup
cp -r /tmp/cryptominer-backup-*/data /opt/cryptominer-pro/
```

---

**Safe uninstallation with data protection and system integrity! 🛡️🗑️**