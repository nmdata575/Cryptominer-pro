# CryptoMiner Pro v2.0 - API Documentation

## 🔌 Backend API Reference

The CryptoMiner Pro backend provides comprehensive REST API endpoints for mining control, AI optimization, and system monitoring.

**Base URL**: `http://your-server:8001/api`

## 🏥 Health & System Endpoints

### GET /api/health
Returns system health status and basic information.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-08-01T23:27:13.444Z",
  "version": "1.0.0",
  "uptime": 146.507377849,
  "memory": {
    "rss": 70299648,
    "heapTotal": 23994368,
    "heapUsed": 21955016
  },
  "platform": "linux",
  "node_version": "v20.19.4"
}
```

### GET /api/system/stats
Returns detailed system resource usage.

**Response:**
```json
{
  "cpu": {
    "usage_percent": 27.6,
    "load_average": [1.2, 1.1, 0.9],
    "cores": 8
  },
  "memory": {
    "total": 8589934592,
    "used": 2684354560,
    "free": 5905580032,
    "usage_percent": 31.3
  },
  "disk": {
    "total": 100000000000,
    "used": 10200000000,
    "free": 89800000000,
    "usage_percent": 10.2
  }
}
```

### GET /api/system/cpu-info
Returns enhanced CPU information and mining recommendations.

**Response:**
```json
{
  "cpu": {
    "physical_cores": 8,
    "logical_cores": 8,
    "model": "ARM Neoverse-N1",
    "frequency": "2.8 GHz",
    "architecture": "aarch64"
  },
  "mining_profiles": {
    "light": { "threads": 2, "intensity": 0.3 },
    "standard": { "threads": 6, "intensity": 0.6 },
    "maximum": { "threads": 7, "intensity": 0.8 },
    "absolute_max": { "threads": 8, "intensity": 1.0 }
  },
  "recommendations": {
    "optimal_threads": 7,
    "recommended_profile": "standard"
  }
}
```

## ⛏️ Mining Control Endpoints

### POST /api/mining/start
Starts mining operations with specified configuration.

**Request Body:**
```json
{
  "coin": "litecoin",
  "mode": "pool",
  "threads": 4,
  "intensity": 0.8,
  "pool_username": "your_username",
  "pool_password": "your_password",
  "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
  "custom_pool_address": "ltc.millpools.cc",
  "custom_pool_port": 3567
}
```

**Response:**
```json
{
  "success": true,
  "message": "Real mining started successfully",
  "sessionId": "session_1754090750772_ouxxi9h81"
}
```

### POST /api/mining/stop
Stops all mining operations.

**Response:**
```json
{
  "success": true,
  "message": "Mining stopped successfully",
  "final_stats": {
    "runtime": 3600,
    "total_hashes": 1620000,
    "accepted_shares": 12,
    "rejected_shares": 2
  }
}
```

### GET /api/mining/status
Returns current mining status and statistics.

**Response:**
```json
{
  "is_mining": true,
  "stats": {
    "hashrate": 450.5,
    "accepted_shares": 12,
    "rejected_shares": 2,
    "blocks_found": 0,
    "efficiency": 85.7,
    "uptime": 3600
  },
  "config": {
    "coin": "litecoin",
    "mode": "pool",
    "threads": 4,
    "intensity": 0.8
  },
  "pool_connected": true,
  "current_job": "job_12345",
  "difficulty": 65536,
  "test_mode": false
}
```

## 🤖 AI Optimization Endpoints

### GET /api/mining/ai-insights
Returns basic AI predictions and optimization recommendations.

**Response:**
```json
{
  "optimization_suggestions": [
    "✅ POOL: Connected to real mining pool successfully",
    "📈 SHARES: 12 shares accepted - great progress!",
    "⚠️ SHARES: High rejection rate (14.3%) - check difficulty settings"
  ],
  "predictions": {
    "hashrate_trend": "stable",
    "efficiency_prediction": {
      "predicted_efficiency": 87,
      "trend": "stable",
      "recommendation": "excellent"
    },
    "optimal_settings": {
      "threads": 4,
      "intensity": 0.8,
      "optimization": "ml_optimized"
    }
  },
  "learning_status": {
    "enabled": true,
    "data_points": 25,
    "confidence": 0.9
  }
}
```

### GET /api/mining/ai-insights-advanced
Returns advanced ML analysis and optimization recommendations.

**Response:**
```json
{
  "realTimeAnalysis": {
    "performance_grade": {
      "numerical_score": 87,
      "letter_grade": "A",
      "performance_level": "Excellent"
    },
    "bottleneck_analysis": [],
    "optimization_potential": 75,
    "performance_score": 87
  },
  "machineLearningPredictions": {
    "hashrate_forecast": {
      "trend": "stable",
      "predicted_next_hashrate": 465,
      "confidence": 0.85
    },
    "efficiency_forecast": {
      "predicted_efficiency": 88,
      "contributing_factors": {
        "efficiency": 85.7,
        "hashrate_impact": 450.5,
        "shares_impact": 0.857
      }
    }
  },
  "performanceOptimization": {
    "recommended_config": {
      "threads": 4,
      "intensity": 0.8
    },
    "expected_improvement": 12,
    "optimization_confidence": 0.9
  }
}
```

## 🏪 Pool Connection Endpoints

### POST /api/pool/test-connection
Tests connection to a mining pool.

**Request Body:**
```json
{
  "connection_type": "pool",
  "address": "ltc.millpools.cc",
  "port": 3567
}
```

**Response:**
```json
{
  "success": true,
  "connection_type": "pool",
  "address": "ltc.millpools.cc",
  "port": 3567,
  "response_time": 45,
  "status": "connected"
}
```

## 💰 Wallet Validation Endpoints

### POST /api/wallet/validate
Validates cryptocurrency wallet addresses.

**Request Body:**
```json
{
  "coin": "litecoin",
  "address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
}
```

**Response:**
```json
{
  "valid": true,
  "coin": "litecoin",
  "address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
  "address_type": "bech32",
  "network": "mainnet"
}
```

## 🪙 Cryptocurrency Presets

### GET /api/coins/presets
Returns available cryptocurrency configurations.

**Response:**
```json
[
  {
    "id": "litecoin",
    "name": "Litecoin",
    "symbol": "LTC",
    "algorithm": "scrypt",
    "block_reward": 12.5,
    "block_time": 150,
    "difficulty": 1000000,
    "scrypt_params": {
      "N": 1024,
      "r": 1,
      "p": 1
    },
    "wallet_address_format": "^[LM3][a-km-zA-HJ-NP-Z1-9]{26,33}$|^ltc1[a-z0-9]{39,59}$"
  }
]
```

## 📊 Database & Statistics Endpoints

### GET /api/mining/stats
Returns mining statistics from database.

**Query Parameters:**
- `limit` (optional): Number of records to return
- `session_id` (optional): Filter by session ID

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "sessionId": "session_123",
      "startTime": "2025-08-01T20:00:00.000Z",
      "endTime": "2025-08-01T21:00:00.000Z",
      "hashrate": 450.5,
      "acceptedShares": 12,
      "rejectedShares": 2,
      "efficiency": 85.7,
      "config": {
        "threads": 4,
        "intensity": 0.8
      }
    }
  ]
}
```

### GET /api/ai/predictions
Returns AI predictions from database.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "predictionType": "hashrate_forecast",
      "timeframe": "1hour",
      "predictedValue": 465,
      "confidence": 0.85,
      "accuracy": 0.92,
      "createdAt": "2025-08-01T20:00:00.000Z"
    }
  ]
}
```

## 🔧 System Configuration Endpoints

### GET /api/config/user/preferences
Returns user preferences and settings.

**Response:**
```json
{
  "success": true,
  "data": {
    "config": {
      "theme": "dark",
      "refreshInterval": 2000,
      "showAdvancedOptions": false,
      "notifications": {
        "enabled": true
      }
    }
  }
}
```

## 🛠️ Maintenance Endpoints

### GET /api/maintenance/stats
Returns database statistics and health information.

**Response:**
```json
{
  "success": true,
  "stats": {
    "totalDocuments": 17,
    "miningStats": 14,
    "aiPredictions": 3,
    "systemConfigs": 2
  },
  "database": {
    "connected": true,
    "collections": 5,
    "indexes": 12
  }
}
```

### POST /api/maintenance/cleanup
Performs database cleanup based on retention policies.

**Response:**
```json
{
  "success": true,
  "message": "Database cleanup completed",
  "deleted": {
    "miningStats": 5,
    "aiPredictions": 2,
    "systemConfigs": 0
  }
}
```

## 🌐 WebSocket Events

The backend provides real-time updates via Socket.io WebSocket connection.

### Connection
```javascript
const socket = io('http://your-server:8001');
```

### Events

**mining_update** - Real-time mining statistics
```json
{
  "hashrate": 450.5,
  "accepted_shares": 12,
  "rejected_shares": 2,
  "efficiency": 85.7,
  "uptime": 3600
}
```

**system_update** - System resource updates
```json
{
  "cpu_usage": 27.6,
  "memory_usage": 31.3,
  "disk_usage": 10.2,
  "system_health": 77
}
```

**ai_update** - AI insights and recommendations
```json
{
  "optimization_suggestions": [
    "📈 SHARES: Performance improving",
    "🎯 EFFICIENCY: Optimal settings detected"
  ],
  "performance_score": 87
}
```

## 🔐 Authentication & Security

### Rate Limiting
- **Default Limit**: 1000 requests per 15 minutes
- **Mining Operations**: Higher limits for mining start/stop
- **Health Checks**: Excluded from rate limiting

### CORS Configuration
- **Origin**: Configurable via environment variables
- **Credentials**: Supported for authenticated requests
- **Methods**: GET, POST, PUT, DELETE

### Error Handling
All endpoints return consistent error responses:

```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE",
  "timestamp": "2025-08-01T20:00:00.000Z"
}
```

## 📝 Response Codes

- **200** - Success
- **400** - Bad Request (invalid parameters)
- **401** - Unauthorized
- **404** - Not Found
- **422** - Unprocessable Entity (validation errors)
- **429** - Too Many Requests (rate limited)
- **500** - Internal Server Error

---

**Happy Mining with AI Optimization! 🚀⛏️**