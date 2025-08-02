# CryptoMiner Pro Tests

This directory contains testing utilities and scripts for validating the CryptoMiner Pro v2.0 system.

## 🧪 Available Tests

### AI Share Analysis Test (`test_ai_shares.js`)

Comprehensive test suite that validates the AI system's ability to analyze and learn from cryptocurrency share submission data.

**Features Tested:**
- ✅ Real share data collection from mining engine
- ✅ AI analysis of acceptance/rejection patterns  
- ✅ Machine learning accuracy and confidence scoring
- ✅ Optimization recommendations based on share performance
- ✅ Historical data pattern analysis

**Usage:**
```bash
# Run from backend directory
cd /opt/cryptominer-pro/backend-nodejs
node test_ai_shares.js

# Or run directly
node /home/$USER/Cryptominer-pro/tests/test_ai_shares.js
```

**Sample Output:**
```
🧪 TESTING AI SHARE ANALYSIS CAPABILITIES

✅ AI modules loaded successfully

📊 MOCK MINING ENGINE DATA:
   Accepted Shares: 12
   Rejected Shares: 2
   Efficiency: 85.7%
   Hash Rate: 450.5 H/s
   Pool Connected: true
   Test Mode: false

🔍 TEST 1: BASIC AI PREDICTOR SHARE ANALYSIS
==================================================
✅ BASIC AI INSIGHTS:
   Data Points: 1
   Confidence: 0.9
   3. 📈 SHARES: 12 shares accepted - great progress!

🚀 TEST 2: ENHANCED AI PREDICTOR SHARE ANALYSIS
==================================================
📈 GENERATED 25 HISTORICAL DATA POINTS
✅ ENHANCED AI ANALYSIS RESULTS:
   Performance Grade: A (87/100)
   Performance Level: Excellent

📊 TEST 3: SHARE PATTERN ANALYSIS
==================================================
✅ SHARE PATTERN RESULTS:
   Average Acceptance Rate: 87.84%
   Best Acceptance Rate: 100.00%
   Performance Trend: improving
   Optimal Configuration Found: {"threads":2,"intensity":0.76}

🧠 TEST 4: AI LEARNING FROM SHARE DATA
==================================================
✅ AI LEARNING RESULTS:
   Learning Accuracy: 95.00%
   Prediction Confidence: 0.90
   Recommended Threads: 2
   Recommended Intensity: 0.76
   Expected Share Rate: 912.00 shares/hour

🎉 AI SHARE ANALYSIS TEST COMPLETED SUCCESSFULLY!
```

## 🛠️ Test Categories

### Unit Tests
- **AI Predictor Tests**: Validation of AI analysis algorithms
- **Mining Engine Tests**: Hash generation and pool communication
- **Database Tests**: MongoDB model validation and CRUD operations
- **Utility Tests**: Cryptocurrency address validation and system monitoring

### Integration Tests
- **API Endpoint Tests**: REST API functionality and response validation
- **WebSocket Tests**: Real-time communication and event handling
- **Database Integration**: End-to-end data persistence and retrieval
- **Mining Flow Tests**: Complete mining start/stop/monitor cycles

### Performance Tests
- **Hash Rate Benchmarks**: Mining performance under various configurations
- **AI Performance**: ML analysis speed and accuracy measurement
- **System Resource Tests**: CPU, memory, and disk usage validation
- **Concurrent User Tests**: Multi-user dashboard and API access

### Security Tests
- **Input Validation**: Parameter sanitization and injection prevention
- **Authentication Tests**: API security and rate limiting validation
- **Permission Tests**: Service user isolation and file access controls
- **Network Security**: Firewall rules and connection security

## 🚀 Running Tests

### Prerequisites
```bash
# Ensure system is installed and running
sudo supervisorctl status

# Verify database connectivity
mongosh --eval "db.adminCommand('ping')"

# Check API health
curl http://localhost:8001/api/health
```

### Test Execution

**Individual Test:**
```bash
# AI Share Analysis
node tests/test_ai_shares.js

# API Endpoint Tests
curl -X GET http://localhost:8001/api/mining/ai-insights-advanced

# Mining Status Test
curl -X GET http://localhost:8001/api/mining/status
```

**Comprehensive Testing:**
```bash
# Backend testing (automated)
deep_testing_backend_v2

# Frontend testing (manual)
# Open browser and navigate to dashboard
firefox http://localhost:3000
```

## 📊 Test Results Interpretation

### AI Share Analysis Results

**Performance Grades:**
- **A+ (95-100)**: Exceptional mining performance
- **A (85-94)**: Excellent performance
- **B+ (75-84)**: Good performance with optimization potential
- **B (65-74)**: Adequate performance
- **C+ (55-64)**: Below average, needs optimization
- **C (45-54)**: Poor performance
- **D (0-44)**: Critical issues requiring immediate attention

**Learning Accuracy:**
- **95%+**: Excellent AI learning capability
- **85-94%**: Good learning with reliable predictions
- **75-84%**: Adequate learning, may need more data
- **<75%**: Insufficient data or system issues

**Share Acceptance Rates:**
- **90%+**: Excellent pool connectivity and hash quality
- **80-89%**: Good performance, minor optimization possible
- **70-79%**: Average performance, consider pool settings
- **<70%**: Poor performance, requires configuration review

## 🔧 Test Configuration

### Environment Variables
```bash
# Test mode configuration
TEST_MODE=true
AI_LEARNING_ENABLED=true
MOCK_MINING_DATA=true

# Database test settings
TEST_DB_URL=mongodb://localhost:27017/cryptominer_test
TEST_DATA_RETENTION=24h

# API test settings
TEST_API_BASE_URL=http://localhost:8001/api
TEST_RATE_LIMIT=false
```

### Mock Data Generation
The test suite includes sophisticated mock data generation for:
- **Mining Statistics**: Realistic hash rates, share data, efficiency metrics
- **Historical Data**: Time-series data with configurable trends and patterns
- **AI Predictions**: Machine learning model outputs and confidence scores
- **System Metrics**: CPU, memory, and disk usage simulation

## 🐛 Troubleshooting Tests

### Common Test Issues

**AI Test Failures:**
```bash
# Check AI module loading
node -e "console.log(require('./backend-nodejs/ai/predictor.js'))"

# Verify enhanced AI system
node -e "console.log(require('./backend-nodejs/ai/enhanced_predictor.js'))"
```

**Database Test Issues:**
```bash
# Test MongoDB connection
mongosh --eval "db.adminCommand('ismaster')"

# Check model validation
node -e "const MiningStats = require('./backend-nodejs/models/MiningStats.js'); console.log('Models loaded')"
```

**API Test Failures:**
```bash
# Check service status
sudo supervisorctl status

# Test API endpoints manually
curl -v http://localhost:8001/api/health
curl -v http://localhost:8001/api/mining/status
```

### Performance Issues
- **High CPU Usage**: Reduce test thread count or intensity
- **Memory Leaks**: Monitor test execution and restart services if needed
- **Database Performance**: Check MongoDB indexing and query optimization
- **Network Latency**: Verify pool connectivity and firewall settings

## 📈 Continuous Testing

### Automated Testing Schedule
- **Unit Tests**: Run on every code change
- **Integration Tests**: Daily automated execution
- **Performance Tests**: Weekly benchmarking
- **Security Tests**: Monthly comprehensive scans

### Test Reporting
Results are logged to:
- **Console Output**: Real-time test progress and results
- **Log Files**: `/var/log/cryptominer/test-results.log`
- **Database**: Test results stored in MongoDB for analysis
- **Dashboard**: Test status available in web interface

---

**Happy Testing! Ensure your mining operations are optimized and secure! 🧪🚀**