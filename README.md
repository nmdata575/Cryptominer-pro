# CryptoMiner Pro - Advanced Cryptocurrency Mining System

## 🚀 **Now with Custom Coin Support!**

CryptoMiner Pro is a powerful, AI-driven cryptocurrency mining system that supports **any Scrypt-based cryptocurrency**. The system has been completely converted to Node.js for better performance and easier installation.

## ✨ **Key Features**

### 🪙 **Mining Capabilities**
- **Built-in Coins**: Litecoin (LTC), Dogecoin (DOGE), Feathercoin (FTC)
- **Custom Coins**: Add any Scrypt-based cryptocurrency
- **Solo & Pool Mining**: Flexible mining modes
- **AI Optimization**: Intelligent mining optimization
- **Real-time Monitoring**: Live hashrate, shares, and system metrics

### 🎛️ **Advanced Controls**
- **Dynamic Threading**: Auto-detect optimal CPU cores
- **Custom Pool/RPC**: Configure custom mining pools
- **Wallet Integration**: Full wallet address validation
- **Performance Profiles**: Light, Standard, Maximum mining modes

### 📱 **Remote Connectivity**
- **Android App Ready**: Full remote API for mobile control
- **Multi-device Support**: Control from multiple devices
- **Secure Authentication**: Token-based remote access
- **Real-time Updates**: WebSocket connections for live data

### 🔧 **Custom Coin Management**
- **Add Any Scrypt Coin**: Support for custom cryptocurrencies
- **Real-time Validation**: Instant parameter validation
- **Import/Export**: Backup and share coin configurations
- **Rich Metadata**: Store comprehensive coin information

## 🛠️ **Installation**

### **Quick Installation (Recommended)**

```bash
# Download and run the container-optimized installer
wget https://github.com/your-repo/cryptominer-pro/raw/main/install-container.sh
chmod +x install-container.sh
./install-container.sh
```

### **Manual Installation**

If you prefer manual installation or encounter issues:

```bash
# 1. Navigate to the CryptoMiner Pro directory
cd /path/to/cryptominer-pro

# 2. Run the fix installation script
./fix-installation.sh

# 3. Start the application
/opt/cryptominer-pro/start.sh
```

### **Requirements**
- **Node.js**: 18.x or higher
- **MongoDB**: Running instance
- **Linux**: Ubuntu 20.04+ recommended
- **Memory**: 2GB+ RAM recommended
- **CPU**: Multi-core processor for optimal mining

## 🚀 **Getting Started**

### 1. **Start the Application**
```bash
/opt/cryptominer-pro/start.sh
```

### 2. **Access the Dashboard**
Open your browser to: `http://localhost:3000`

### 3. **Add Custom Coins**
- Click "Manage Custom Coins" in the coin selector
- Fill in the cryptocurrency parameters
- Start mining with your custom coin

### 4. **Configure Mining**
- Select your cryptocurrency
- Enter wallet address
- Configure mining parameters
- Click "START MINING"

## 📊 **Status & Management**

### **Check System Status**
```bash
/opt/cryptominer-pro/status.sh
```

### **Stop the Application**
```bash
/opt/cryptominer-pro/stop.sh
```

### **View Logs**
```bash
# Backend logs
tail -f /opt/cryptominer-pro/backend-nodejs/logs/app.log

# System logs
journalctl -u cryptominer-pro -f
```

## 🪙 **Adding Custom Coins**

### **Web Interface**
1. Click "Manage Custom Coins"
2. Fill in the coin parameters:
   - Name, Symbol, Algorithm
   - Block time, Block reward
   - Scrypt parameters (N, r, p)
   - Address formats
3. Click "Add Coin"

### **API Example**
```bash
curl -X POST http://localhost:8001/api/coins/custom \
  -H "Content-Type: application/json" \
  -d '{
    "id": "mycoin",
    "name": "My Custom Coin",
    "symbol": "MYC",
    "algorithm": "scrypt",
    "block_time_target": 150,
    "block_reward": 50,
    "scrypt_params": {"N": 1024, "r": 1, "p": 1}
  }'
```

## 📱 **Remote API for Android Apps**

### **Register Device**
```bash
curl -X POST http://localhost:8001/api/remote/register \
  -H "Content-Type: application/json" \
  -d '{"device_id": "android123", "device_name": "My Phone"}'
```

### **Start Mining Remotely**
```bash
curl -X POST http://localhost:8001/api/remote/mining/start \
  -H "Content-Type: application/json" \
  -d '{"coin": "litecoin", "mode": "pool", "threads": 4}'
```

## 🔧 **Configuration Files**

### **Backend Configuration**
```bash
# Edit backend settings
nano /opt/cryptominer-pro/backend-nodejs/.env
```

### **Frontend Configuration**
```bash
# Edit frontend settings
nano /opt/cryptominer-pro/frontend/.env
```

## 📚 **Documentation**

- **Custom Coins Guide**: `/opt/cryptominer-pro/CUSTOM_COINS_GUIDE.md`
- **Remote API Guide**: `/opt/cryptominer-pro/REMOTE_API_GUIDE.md`
- **Manual Installation**: `/opt/cryptominer-pro/MANUAL_INSTALL.md`
- **System Structure**: `/opt/cryptominer-pro/STREAMLINED_STRUCTURE.md`

## 🔍 **Troubleshooting**

### **Installation Issues**
```bash
# If installation fails, run the fix script
cd /path/to/cryptominer-pro
./fix-installation.sh
```

### **Service Issues**
```bash
# Check status
/opt/cryptominer-pro/status.sh

# Restart services
/opt/cryptominer-pro/stop.sh
/opt/cryptominer-pro/start.sh
```

### **API Issues**
```bash
# Test backend API
curl http://localhost:8001/api/health

# Check custom coins
curl http://localhost:8001/api/coins/custom
```

## 🛡️ **Security**

- **Wallet Security**: Never share private keys
- **Network Security**: Use firewall for production
- **API Security**: Secure remote access tokens
- **Pool Security**: Use reputable mining pools

## 🌟 **Features Highlights**

- **✅ Zero Python Dependencies**: Pure Node.js implementation
- **✅ Custom Coin Support**: Add any Scrypt-based cryptocurrency
- **✅ AI-Powered Optimization**: Intelligent mining optimization
- **✅ Real-time Monitoring**: Live system and mining metrics
- **✅ Remote Control**: Full Android app API support
- **✅ Easy Installation**: Simple one-script installation
- **✅ Professional UI**: Modern, responsive dashboard
- **✅ Multi-coin Support**: Built-in + unlimited custom coins

## 🎯 **Performance**

- **Fast Installation**: No compilation issues
- **Efficient Mining**: Optimized Scrypt implementation
- **Real-time Updates**: WebSocket-based live data
- **Resource Management**: Intelligent CPU and memory usage
- **Scalable Architecture**: Designed for production use

## 🔄 **Updates**

```bash
# Update Node.js dependencies
cd /opt/cryptominer-pro/backend-nodejs && npm update
cd /opt/cryptominer-pro/frontend && npm update

# Restart services
/opt/cryptominer-pro/stop.sh
/opt/cryptominer-pro/start.sh
```

## 🤝 **Contributing**

We welcome contributions! Please read our contribution guidelines and submit pull requests for any improvements.

## 📄 **License**

This project is licensed under the MIT License. See the LICENSE file for details.

## 🎉 **Support**

For support, please:
1. Check the documentation in `/opt/cryptominer-pro/`
2. Run the status check: `/opt/cryptominer-pro/status.sh`
3. Review the troubleshooting section above

---

**Happy Mining!** 🚀💰

*CryptoMiner Pro - The most versatile Scrypt mining system with custom coin support*