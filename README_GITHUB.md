# CryptoMiner Pro

**AI-Powered Cryptocurrency Mining Dashboard - Version 2.1**

A professional-grade cryptocurrency mining application with real-time monitoring, AI-driven optimization, and support for multiple Scrypt-based cryptocurrencies. **Now with enhanced CPU frequency detection and full Webpack 5 compatibility!**

## 🎉 What's New in Version 2.1

### ✅ **Critical Fixes Implemented:**
- **🖥️ CPU Frequency Detection**: Fixed incorrect "2 MHz" readings → Now shows accurate **2.8 GHz** for ARM processors
- **📦 Webpack 5 Compatibility**: Resolved all "Cannot find module 'crypto'" and Node.js polyfill errors
- **🔧 CRACO Integration**: Seamless build system with automatic browser polyfills
- **🚀 Enhanced Installation**: New `install-complete-v2.sh` script with bulletproof setup

### 🛠️ **Technical Improvements:**
- **ARM Processor Support**: Perfect compatibility with Neoverse-N1 and other ARM CPUs
- **Container Optimization**: Enhanced detection for Docker/Kubernetes environments  
- **Error-Free UI**: Zero console errors, professional mining dashboard experience
- **Smart Frequency Display**: Intelligent GHz/MHz unit detection and formatting

![CryptoMiner Pro Dashboard](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![Node.js](https://img.shields.io/badge/Node.js-v20.19.4-green)
![React](https://img.shields.io/badge/React-18.x-blue)
![MongoDB](https://img.shields.io/badge/MongoDB-7.x-green)
![GitHub](https://img.shields.io/badge/GitHub-nmdata575%2Fai--cm-blue)
![Release](https://img.shields.io/badge/Release-v2.1-orange)
![CPU Fix](https://img.shields.io/badge/CPU%20Frequency-Fixed-success)
![Webpack](https://img.shields.io/badge/Webpack%205-Compatible-success)

## 🚀 Features

### Core Mining Capabilities
- **Multi-Cryptocurrency Support**: Litecoin (LTC), Dogecoin (DOGE), Feathercoin (FTC)
- **Custom Coin Management**: Add your own Scrypt-based cryptocurrencies
- **Dual Mining Modes**: Solo mining and pool mining with custom configurations
- **Real-time Performance Monitoring**: Hash rates, shares, blocks found, efficiency metrics

### AI-Powered Optimization
- **Intelligent Hash Prediction**: AI system learns mining patterns
- **Auto-optimization**: System automatically adjusts mining parameters
- **Performance Recommendations**: Smart suggestions for optimal mining setup
- **Predictive Analytics**: Market insights and difficulty forecasting

### Advanced System Monitoring
- **Real-time Resource Tracking**: CPU, memory, disk usage monitoring
- **Container Environment Detection**: Kubernetes/Docker optimized
- **Dynamic Thread Management**: Auto-detection of optimal thread counts
- **System Health Indicators**: Comprehensive health monitoring

### Professional Interface
- **Role-based Dashboard**: Mining Control Center, System Monitoring, AI Assistant
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Real-time Updates**: WebSocket communication with HTTP polling fallback
- **Professional UI/UX**: Modern, clean interface with dark theme

### Remote Connectivity
- **Android App Support**: Complete remote API for mobile applications
- **Multi-device Management**: Control mining from multiple devices
- **Secure Authentication**: Token-based access control
- **Remote Monitoring**: Check mining status from anywhere

## 🏗️ Architecture

### Backend (Node.js/Express)
- **RESTful API**: Comprehensive mining and system management APIs
- **WebSocket Support**: Real-time data streaming with Socket.io
- **MongoDB Integration**: Persistent storage for custom coins and settings
- **Modular Design**: Separated concerns (mining, AI, system monitoring)

### Frontend (React)
- **Component-based Architecture**: Reusable, maintainable components
- **State Management**: Efficient React hooks and context
- **Real-time UI**: Live updates for all mining metrics
- **Responsive Framework**: Tailwind CSS for modern styling

### Mining Engine
- **Pure JavaScript Implementation**: Complete Scrypt algorithm implementation
- **Multi-threading Support**: Optimized for multi-core systems
- **Custom Pool Support**: Connect to any Scrypt mining pool
- **Solo Mining**: Direct connection to cryptocurrency networks

## 🛠️ Installation

### Quick Start (Recommended)
```bash
# Clone the repository
git clone https://github.com/nmdata575/ai-cm.git
cd ai-cm

# Switch to release branch
git checkout release-2.03

# Run the complete installation script (v2.1 with webpack fixes)
chmod +x install-complete-v2.sh
./install-complete-v2.sh

# Start the application
sudo supervisorctl start all
```

### Manual Installation
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

# Install backend dependencies
cd /opt/cryptominer-pro/backend-nodejs
npm install

# Install frontend dependencies with webpack polyfills
cd ../frontend
npm install
npm install --save-dev @craco/craco crypto-browserify stream-browserify https-browserify stream-http util assert url browserify-zlib buffer process

# Create CRACO configuration (see installation guide for full config)
# Update package.json to use CRACO
# Build frontend
npm run build

# Configure and start services
sudo supervisorctl restart all
```

### Docker Installation (Optional)
```bash
# Using Docker Compose
docker-compose up -d
```

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```env
PORT=8001
MONGO_URL=mongodb://localhost:27017/cryptominer
NODE_ENV=production
```

#### Frontend (.env)
```env
REACT_APP_BACKEND_URL=http://localhost:8001
GENERATE_SOURCEMAP=false
FAST_REFRESH=true
```

### Mining Configuration
- **Supported Algorithms**: Scrypt (N=1024, r=1, p=1)
- **Supported Coins**: LTC, DOGE, FTC, and custom Scrypt coins
- **Pool Support**: Any Stratum-compatible mining pool
- **Solo Mining**: Direct RPC connection to coin daemons

## 📚 Documentation

- **[Installation Guide](docs/INSTALLATION.md)**: Detailed setup instructions
- **[API Documentation](docs/API.md)**: Complete API reference
- **[Custom Coins Guide](docs/CUSTOM_COINS_GUIDE.md)**: Adding custom cryptocurrencies
- **[Remote API Guide](docs/REMOTE_API_GUIDE.md)**: Mobile app integration
- **[Troubleshooting](docs/TROUBLESHOOTING.md)**: Common issues and solutions

## 🚦 Usage

### Starting Mining
1. **Select Cryptocurrency**: Choose from Litecoin, Dogecoin, or Feathercoin
2. **Configure Wallet**: Enter your wallet address for rewards
3. **Choose Mining Mode**: Solo mining or pool mining
4. **Set Parameters**: Adjust threads, intensity, and AI optimization
5. **Start Mining**: Click the START MINING button

### Monitoring Performance
- **Mining Control Center**: Overview of mining status and system health
- **Mining Performance**: Detailed statistics and efficiency metrics
- **System Monitoring**: Resource usage and hardware information
- **AI Assistant**: Optimization recommendations and insights

### Custom Coins
- **Add New Coins**: Support for any Scrypt-based cryptocurrency
- **Configure Parameters**: Set block time, rewards, and network difficulty
- **Import/Export**: Share coin configurations between installations

## 🔌 API Endpoints

### Core Mining APIs
- `GET /api/health` - System health check
- `GET /api/mining/status` - Current mining status
- `POST /api/mining/start` - Start mining operation
- `POST /api/mining/stop` - Stop mining operation

### System APIs
- `GET /api/system/stats` - System resource statistics
- `GET /api/system/cpu-info` - Detailed CPU information
- `GET /api/coins/presets` - Available cryptocurrency presets

### Custom Coin APIs
- `GET /api/coins/custom` - List custom coins
- `POST /api/coins/custom` - Add new custom coin
- `PUT /api/coins/custom/:id` - Update custom coin
- `DELETE /api/coins/custom/:id` - Remove custom coin

## 🧪 Testing

```bash
# Clone and setup
git clone https://github.com/nmdata575/ai-cm.git
cd ai-cm
git checkout release-2.03

# Test installation
./scripts/test-installation.sh

# Verify backend APIs
curl http://localhost:8001/api/health

# Check mining status
curl http://localhost:8001/api/mining/status
```

## 📈 Performance

### System Requirements
- **Minimum**: 2 CPU cores, 4GB RAM, 10GB disk space
- **Recommended**: 8+ CPU cores, 16GB RAM, 50GB disk space
- **Operating System**: Linux (Ubuntu 20.04+), Docker, or Kubernetes

### Optimization
- **Multi-threading**: Automatically detects optimal thread count
- **Container Awareness**: Optimized for Docker/Kubernetes environments
- **Memory Management**: Efficient memory usage with automatic cleanup
- **CPU Optimization**: Dynamic adjustment based on system load

## 🔒 Security

- **Environment Variables**: Sensitive data stored in .env files
- **Input Validation**: Comprehensive validation of all user inputs
- **Rate Limiting**: API endpoints protected against abuse
- **Secure Headers**: Security headers configured with Helmet.js

## 🤝 Contributing

1. Fork the repository from [https://github.com/nmdata575/ai-cm](https://github.com/nmdata575/ai-cm)
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request to the `release-2.03` branch

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Scrypt Algorithm**: Based on the original Scrypt specification
- **Cryptocurrency Communities**: Litecoin, Dogecoin, and Feathercoin communities
- **Open Source Libraries**: Express.js, React, MongoDB, Socket.io, and many others

## 📞 Support

- **Repository**: [https://github.com/nmdata575/ai-cm](https://github.com/nmdata575/ai-cm)
- **Documentation**: Check the [docs](docs/) directory
- **Issues**: Use [GitHub Issues](https://github.com/nmdata575/ai-cm/issues) for bug reports and feature requests
- **Discussions**: Join [GitHub Discussions](https://github.com/nmdata575/ai-cm/discussions) for community support
- **Release Branch**: [release-2.03](https://github.com/nmdata575/ai-cm/tree/release-2.03)

## 🗺️ Roadmap

- [ ] GPU mining support (CUDA/OpenCL)
- [ ] Additional cryptocurrency algorithms (SHA-256, Ethash)
- [ ] Mobile application (Android/iOS)
- [ ] Cloud mining integration
- [ ] Advanced AI optimization features
- [ ] Mining pool creation tools

---

**Built with ❤️ for the cryptocurrency mining community**

*CryptoMiner Pro - Professional AI-Powered Mining Dashboard*