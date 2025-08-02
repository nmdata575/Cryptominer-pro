# CryptoMiner Pro - Fixed Installation Guide

## 🔧 Installation Script Fixes Applied

The installation script has been updated to resolve the permission errors and file detection issues.

### ✅ Issues Fixed:
1. **Permission Errors**: No more `chown: Operation not permitted` errors
2. **File Detection**: Script now automatically finds application files in multiple locations
3. **User-Specific Installation**: Installs to user's home directory instead of system-wide
4. **MongoDB 8.0**: Updated to latest MongoDB version

## 📋 Prerequisites

- Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- Regular user account (DO NOT run as root)
- At least 2GB RAM and 5GB disk space
- Internet connection for downloading dependencies

## 🚀 Installation Steps

### Option 1: Quick Installation (Recommended)

```bash
# Download the fixed installation script
curl -O https://your-server.com/install-enhanced-v2-fixed.sh

# Make it executable
chmod +x install-enhanced-v2-fixed.sh

# Run the installation (as regular user, NOT root)
./install-enhanced-v2-fixed.sh
```

### Option 2: Manual Installation from Source

```bash
# If you have the CryptoMiner Pro source files
cd /path/to/cryptominer-pro-source

# Copy the installation script to the source directory
cp /app/install-enhanced-v2-fixed.sh ./

# Make it executable and run
chmod +x install-enhanced-v2-fixed.sh
./install-enhanced-v2-fixed.sh
```

## 🔍 How File Detection Works

The installation script now automatically searches for application files in these locations:

1. **Script Directory**: Same directory as the installation script
2. **Development Location**: `/app/backend-nodejs` and `/app/frontend`
3. **Current Directory**: `./backend-nodejs` and `./frontend`
4. **Parent Directories**: `../backend-nodejs` and `../frontend`
5. **Previous Installations**: `/opt/cryptominer-pro` and `/root/Cryptominer-pro`

## 📍 Installation Locations

The script will install CryptoMiner Pro to:

- **Application**: `~/Cryptominer-pro/`
- **Logs**: `~/.local/log/cryptominer/`
- **Management Script**: `~/.local/bin/cryptominer`

## ✅ Verification

After installation, verify everything is working:

```bash
# Check service status
cryptominer status

# View recent logs
cryptominer logs

# Test the web interface
curl http://localhost:8001/api/health
```

Access the dashboard at: http://localhost/

## 🎮 Management Commands

```bash
cryptominer start    # Start all services
cryptominer stop     # Stop all services
cryptominer restart  # Restart all services
cryptominer status   # Check service status
cryptominer logs     # View recent logs
cryptominer update   # Update dependencies
```

## 🔧 Troubleshooting

### Common Issues and Solutions

**1. Permission Errors**
```bash
# Solution: Don't run as root
whoami  # Should NOT return 'root'
```

**2. Application Files Not Found**
```bash
# The script will show exactly where it looked:
[ERROR] Could not find application files. Searched in:
  - /home/user/Desktop (script directory)
  - /app (default development location)
  - /home/user/Desktop (current directory)
  # etc.

# Solution: Copy files to one of these locations or run from correct directory
```

**3. MongoDB Connection Issues**
```bash
# Check MongoDB status
sudo systemctl status mongod

# Start MongoDB if needed
sudo systemctl start mongod
```

**4. Services Not Starting**
```bash
# Check supervisor logs
sudo tail -f /var/log/supervisor/supervisord.log

# Check individual service logs
tail -f ~/.local/log/cryptominer/backend.log
tail -f ~/.local/log/cryptominer/frontend.log
```

**5. Port Already in Use**
```bash
# Check what's using ports 8001 and 3000
netstat -tlnp | grep -E ':(8001|3000)'

# Stop conflicting processes if needed
cryptominer stop
```

## 📊 System Requirements Check

The script automatically checks:
- ✅ Not running as root
- ✅ Supported operating system
- ✅ Minimum 2GB RAM
- ✅ Minimum 5GB disk space
- ✅ Minimum 2 CPU cores

## 🔄 Updating

To update an existing installation:

```bash
# Update dependencies
cryptominer update

# Or reinstall completely
./install-enhanced-v2-fixed.sh
```

## 📞 Support

If you encounter issues:

1. Check the installation log: `~/.local/log/cryptominer/install.log`
2. Verify system requirements are met
3. Ensure you're not running as root
4. Check that application files exist in one of the searched locations

## 🎉 Success Indicators

Installation is complete when you see:
- ✅ MongoDB 8.0 installed and running
- ✅ Service user configured
- ✅ Application files installed
- ✅ Backend dependencies installed
- ✅ Frontend dependencies installed
- ✅ Environment files configured
- ✅ Supervisor services configured
- ✅ Nginx configured
- ✅ Backend API is responding
- ✅ Frontend is responding

The dashboard will be available at: **http://localhost/**