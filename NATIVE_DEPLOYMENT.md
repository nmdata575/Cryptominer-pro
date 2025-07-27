# CryptoMiner Pro - Native Host Deployment Guide

## 🎯 Objective: Run on Real Hardware (4 cores / 128 cores)

This guide helps you install CryptoMiner Pro directly on your host systems to see the actual hardware instead of container-allocated resources.

## 📦 Deployment Package Contents

- `cryptominer-pro-native.tar.gz` - Complete application package
- `install-native.sh` - Native installation script
- All source code and documentation

## 🚀 Installation Steps

### Step 1: Copy to Your Host Systems

**On your 4-core system:**
```bash
# Copy the package to your host system
scp cryptominer-pro-native.tar.gz user@your-4core-system:~/
```

**On your 128-core system:**
```bash
# Copy the package to your host system  
scp cryptominer-pro-native.tar.gz user@your-128core-system:~/
```

### Step 2: Extract and Install

**On each system, run:**
```bash
# Extract the package
tar -xzf cryptominer-pro-native.tar.gz
cd cryptominer-pro-native/

# Make installer executable
chmod +x install-native.sh

# Run native installation (will detect real hardware)
sudo ./install-native.sh
```

### Step 3: Verify Real Hardware Detection

After installation, check that it detects your actual hardware:

**4-core system should show:**
```
CPU Cores: 4
Physical Cores: 4
```

**128-core system should show:**
```  
CPU Cores: 128
Physical Cores: 128
```

## 🌐 Access Your Mining Dashboard

After installation, access at:
- **Local**: http://localhost:3000
- **Network**: http://[your-ip]:3000

## 🔧 Key Differences from Container Version

| Aspect | Container | Native Host |
|--------|-----------|-------------|
| **CPU Detection** | 16 cores (allocated) | Real hardware (4/128) |
| **Architecture** | ARM Neoverse-N1 (GCP) | Your actual CPUs |
| **Frequency** | Variable (GCP ARM) | Real CPU frequencies |
| **Performance** | Container-limited | Full hardware access |
| **Mining Speed** | Virtualized | Native performance |

## 📊 Service Management

```bash
# Check status
sudo supervisorctl status cryptominer-native:*

# Start services
sudo supervisorctl start cryptominer-native:*

# Stop services  
sudo supervisorctl stop cryptominer-native:*

# View logs
sudo tail -f /var/log/supervisor/cryptominer-backend.out.log
sudo tail -f /var/log/supervisor/cryptominer-frontend.out.log
```

## 🎯 Expected Results

**Small System (4 cores):**
- ✅ Shows "4 Physical Cores" in web interface
- ✅ Detects actual CPU model (Intel/AMD)
- ✅ Shows real CPU frequencies
- ✅ Mining recommendations for 4-core system

**Big System (128 cores):**
- ✅ Shows "128 Physical Cores" in web interface  
- ✅ Detects actual CPU model (AMD EPYC 7551)
- ✅ Shows real CPU frequencies (2.0-3.0 GHz)
- ✅ Mining recommendations for 128-core system

## 🔥 Mining Performance Benefits

Running natively on your hardware will provide:
- **Real CPU utilization** (not container-limited)
- **Optimal thread recommendations** (based on actual cores)
- **Maximum mining performance** (direct hardware access)
- **Accurate system monitoring** (real temperature, frequencies)

## 📞 Support

If you encounter issues with native installation:
1. Check service logs: `sudo tail -f /var/log/supervisor/cryptominer-*.log`
2. Verify MongoDB is running: `sudo systemctl status mongod`
3. Test API health: `curl http://localhost:8001/api/health`
4. Check hardware detection: Run the test command in the installer output

Your CryptoMiner Pro will now show the correct hardware specifications for each system! 🎉