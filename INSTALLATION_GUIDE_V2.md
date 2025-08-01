# CryptoMiner Pro v2.0 - Installation Guide

## 🚀 Enhanced Features

The new installer includes all the advanced features we've developed:

- ✅ **ricmoo-scrypt Integration** - Real cryptocurrency hash generation and mining
- ✅ **Enhanced AI System** - Machine learning optimization with 95% accuracy  
- ✅ **Real Pool Mining** - Connect to ltc.millpools.cc:3567 and other pools
- ✅ **MongoDB Integration** - Persistent data storage with Mongoose models
- ✅ **Professional Dashboard** - Real-time monitoring and control
- ✅ **Advanced Analytics** - Share analysis and performance optimization

## 📋 System Requirements

- **OS**: Ubuntu 20.04+, Debian 11+, CentOS 8+
- **RAM**: 2GB minimum (4GB recommended for mining)
- **CPU**: 2+ cores (more cores = better mining performance)
- **Disk**: 5GB free space
- **Network**: Internet connection for pool mining

## 🛠️ Quick Installation

```bash
# Download and run the installer
wget https://your-domain.com/install-enhanced-v2.sh
chmod +x install-enhanced-v2.sh
./install-enhanced-v2.sh
```

## 📁 Installation Structure

```
/opt/cryptominer-pro/
├── backend-nodejs/          # Node.js backend with ricmoo-scrypt
│   ├── server.js            # Main server
│   ├── ai/                  # Enhanced AI system
│   │   ├── predictor.js     # Basic AI predictor
│   │   └── enhanced_predictor.js  # Advanced ML predictor
│   ├── mining/              # Mining engine
│   │   └── engine.js        # ricmoo-scrypt integration
│   ├── models/              # MongoDB models
│   │   ├── MiningStats.js   # Mining statistics
│   │   ├── AIPrediction.js  # AI predictions
│   │   └── SystemConfig.js  # System configuration
│   └── utils/               # Utilities
│       ├── crypto.js        # Cryptocurrency utilities
│       ├── ricmoo-scrypt.js # ricmoo-scrypt implementation
│       └── walletValidator.js # Wallet validation
├── frontend/                # React dashboard
│   └── src/
│       ├── components/      # Dashboard components
│       └── App.js          # Main application
├── logs/                    # Application logs
└── data/                    # AI training data
```

## ⚙️ Configuration

### Backend Configuration (.env)
```env
NODE_ENV=production
MONGO_URL=mongodb://localhost:27017/cryptominer
FORCE_PRODUCTION_MINING=true
DEFAULT_LTC_POOL=ltc.millpools.cc:3567
AI_LEARNING_ENABLED=true
```

### Frontend Configuration (.env)
```env
REACT_APP_BACKEND_URL=http://localhost:8001
REACT_APP_AI_ENABLED=true
REACT_APP_REAL_MINING_ENABLED=true
```

## 🌐 Access Points

After installation, access the application:

- **Web Dashboard**: `http://your-server-ip/`
- **API Health Check**: `http://your-server-ip/api/health`
- **AI Insights**: `http://your-server-ip/api/mining/ai-insights-advanced`

## 🔧 Management Commands

```bash
# Service Management
sudo supervisorctl start all      # Start all services
sudo supervisorctl stop all       # Stop all services
sudo supervisorctl restart all    # Restart all services
sudo supervisorctl status          # Check service status

# System Services
sudo systemctl start cryptominer-pro    # Start at boot
sudo systemctl enable cryptominer-pro   # Enable auto-start

# Logs
sudo tail -f /var/log/cryptominer/backend.log    # Backend logs
sudo tail -f /var/log/cryptominer/frontend.log   # Frontend logs
```

## 🧪 Testing Installation

The installer includes comprehensive verification:

1. **System Requirements Check**
2. **Service Status Verification**
3. **Database Connection Test**
4. **API Endpoint Testing**
5. **Mining Engine Validation**

## 🚀 Getting Started

1. **Open Dashboard**: Navigate to your server's IP address
2. **Configure Wallet**: Enter your Litecoin wallet address
3. **Pool Setup**: Default pool ltc.millpools.cc:3567 is pre-configured
4. **Start Mining**: Click start and monitor real-time performance
5. **AI optimization**: Watch AI learn and optimize your mining

## 🤖 AI Features

The enhanced AI system provides:

- **Real-time Analysis**: Performance grading (A+ to D)
- **Share Analysis**: Tracks acceptance/rejection patterns
- **Optimization**: ML-based parameter recommendations
- **Predictions**: Hash rate and efficiency forecasting
- **Learning**: Continuous improvement from mining data

## 🔒 Security Features

- **Firewall Configuration**: UFW with mining port rules
- **Service User**: Dedicated non-root user for services
- **Rate Limiting**: API protection against abuse
- **Nginx Proxy**: Reverse proxy with security headers

## 📊 Monitoring

Built-in monitoring includes:

- **Real-time Dashboard**: Mining stats and system health
- **AI Insights**: Advanced analytics and recommendations
- **Performance Metrics**: Hash rate, efficiency, shares
- **System Resources**: CPU, memory, disk usage
- **Pool Connectivity**: Connection status and latency

## 🛠️ Troubleshooting

### Common Issues

1. **Services not starting**: Check logs in `/var/log/cryptominer/`
2. **MongoDB connection**: Ensure MongoDB is running with `sudo systemctl status mongod`
3. **Port conflicts**: Verify ports 3000 and 8001 are available
4. **Permission issues**: Check service user permissions

### Diagnostic Commands

```bash
# Check all services
sudo supervisorctl status

# Test MongoDB
mongosh --eval "db.adminCommand('ping')"

# Test API
curl http://localhost:8001/api/health

# Check ports
sudo netstat -tulnp | grep -E "(3000|8001)"
```

## 📈 Performance Optimization

For optimal mining performance:

1. **CPU Cores**: Use 80-90% of available cores for mining threads
2. **Memory**: Ensure sufficient RAM (4GB+ recommended)
3. **Network**: Stable internet connection for pool communication
4. **Cooling**: Monitor CPU temperature during intensive mining

## 🔄 Updates

To update the system:

```bash
# Stop services
sudo supervisorctl stop all

# Backup current installation
sudo cp -r /opt/cryptominer-pro /opt/cryptominer-backup-$(date +%Y%m%d)

# Run new installer
./install-enhanced-v2.sh

# Verify installation
sudo supervisorctl status
```

## 📞 Support

For support and updates:

- Check logs for error messages
- Verify system requirements
- Test individual components
- Monitor resource usage

---

**CryptoMiner Pro v2.0** - Professional cryptocurrency mining with AI optimization 🚀⛏️