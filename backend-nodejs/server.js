#!/usr/bin/env node
/**
 * CryptoMiner Pro - Advanced Cryptocurrency Mining System
 * Node.js Backend Implementation
 */

const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Import custom modules
const cryptoUtils = require('./utils/crypto');
const miningEngine = require('./mining/engine');
const systemMonitor = require('./utils/systemMonitor');
const walletValidator = require('./utils/walletValidator');
const aiPredictor = require('./ai/predictor');
const CustomCoin = require('./models/CustomCoin');
const HighPerformanceMiningEngine = require('./high_performance_engine');

// Initialize Express app
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*", // Allow all origins in container environment
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true
  },
  transports: ['websocket', 'polling'], // Support both transports
  pingTimeout: 60000,
  pingInterval: 25000
});

// Global variables
let connectedSockets = [];
let currentMiningEngine = null;
let highPerformanceEngine = new HighPerformanceMiningEngine();
let remoteDevices = new Map();
let accessTokens = new Map();

// Middleware
app.set('trust proxy', 1); // Trust first proxy (required for Kubernetes/Docker environments)
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));

// Rate limiting with higher limits for mining operations
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW) || 900000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX) || 1000, // Increased from 100 to 1000
  standardHeaders: true,
  legacyHeaders: false,
  // Skip rate limiting for health checks and system stats
  skip: (req, res) => {
    return req.path === '/api/health' || req.path === '/api/system/stats';
  }
});
app.use(limiter);

// CORS configuration
const corsOptions = {
  origin: ['http://localhost:3000', 'http://localhost:8001', '*'],
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true,
  optionsSuccessStatus: 200 // Some legacy browsers choke on 204
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Handle preflight OPTIONS requests
app.options('*', cors(corsOptions));

// Database connection
async function connectDB() {
  try {
    const mongoUrl = process.env.MONGO_URL || 'mongodb://localhost:27017/cryptominer';
    await mongoose.connect(mongoUrl);
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error);
    throw error;
  }
}

// Coin presets
const COIN_PRESETS = {
  litecoin: {
    name: 'Litecoin',
    symbol: 'LTC',
    algorithm: 'scrypt',
    block_time_target: 150,
    block_reward: 12.5,
    network_difficulty: 12345678,
    scrypt_params: { N: 1024, r: 1, p: 1 },
    is_custom: false
  },
  dogecoin: {
    name: 'Dogecoin',
    symbol: 'DOGE',
    algorithm: 'scrypt',
    block_time_target: 60,
    block_reward: 10000,
    network_difficulty: 9876543,
    scrypt_params: { N: 1024, r: 1, p: 1 },
    is_custom: false
  },
  feathercoin: {
    name: 'Feathercoin',
    symbol: 'FTC',
    algorithm: 'scrypt',
    block_time_target: 60,
    block_reward: 200,
    network_difficulty: 5432109,
    scrypt_params: { N: 1024, r: 1, p: 1 },
    is_custom: false
  }
};

// API ENDPOINTS
// ============================================================================

// Health check endpoint
app.get('/api/health', (req, res) => {
  const memUsage = process.memoryUsage();
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    uptime: process.uptime(),
    memory: memUsage,
    platform: process.platform,
    node_version: process.version
  });
});

// System statistics endpoint
app.get('/api/system/stats', async (req, res) => {
  try {
    const stats = await systemMonitor.getSystemStats();
    res.json(stats);
  } catch (error) {
    console.error('System stats error:', error);
    res.status(500).json({ error: 'Failed to get system statistics' });
  }
});

// Enhanced CPU info endpoint
app.get('/api/system/cpu-info', async (req, res) => {
  try {
    const cpuInfo = await systemMonitor.getEnhancedCPUInfo();
    res.json(cpuInfo);
  } catch (error) {
    console.error('CPU info error:', error);
    res.status(500).json({ error: 'Failed to get CPU information' });
  }
});

// Environment info endpoint
app.get('/api/system/environment', async (req, res) => {
  try {
    const envInfo = await systemMonitor.getEnvironmentInfo();
    res.json(envInfo);
  } catch (error) {
    console.error('Environment info error:', error);
    res.status(500).json({ error: 'Failed to get environment information' });
  }
});

// Coin presets endpoint
app.get('/api/coins/presets', (req, res) => {
  res.json(Object.values(COIN_PRESETS));
});

// Wallet validation endpoint
app.post('/api/wallet/validate', async (req, res) => {
  try {
    const { address, coin } = req.body;
    
    if (!address || !coin) {
      return res.status(400).json({ 
        valid: false, 
        error: 'Address and coin are required' 
      });
    }

    const result = await walletValidator.validateAddress(address, coin);
    res.json(result);
  } catch (error) {
    console.error('Wallet validation error:', error);
    res.status(500).json({ valid: false, error: 'Validation failed' });
  }
});

// Pool connection test endpoint
app.post('/api/pool/test-connection', async (req, res) => {
  try {
    const { pool_address, pool_port, type } = req.body;
    
    if (!pool_address || !pool_port) {
      return res.status(400).json({
        success: false,
        message: 'Pool address and port are required'
      });
    }
    
    const result = await miningEngine.constructor.testPoolConnection(pool_address, pool_port, type);
    res.json(result);
  } catch (error) {
    console.error('Pool connection test error:', error);
    res.status(500).json({
      success: false,
      message: 'Connection test failed: ' + error.message
    });
  }
});

// Mining status endpoint
app.get('/api/mining/status', (req, res) => {
  const status = currentMiningEngine ? currentMiningEngine.getStatus() : {
    is_mining: false,
    stats: {
      hashrate: 0.0,
      accepted_shares: 0,
      rejected_shares: 0,
      blocks_found: 0,
      cpu_usage: 0.0,
      memory_usage: 0.0,
      uptime: 0.0,
      efficiency: 0.0
    },
    config: {},
    pool_connected: false,
    current_job: null,
    difficulty: 1,
    test_mode: false
  };

  res.json(status);
});

// Regular mining start endpoint
app.post('/api/mining/start', async (req, res) => {
  try {
    const config = req.body;
    
    // Create new mining engine instance
    const engineClass = miningEngine.MiningEngine;
    currentMiningEngine = new engineClass(config);
    
    const result = await currentMiningEngine.start();
    
    if (result.success) {
      // Emit mining start event to connected sockets
      io.emit('mining_started', { config, timestamp: new Date().toISOString() });
    }
    
    res.json(result);
  } catch (error) {
    console.error('Mining start error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to start mining: ' + error.message
    });
  }
});

// High-performance mining start endpoint
app.post('/api/mining/start-hp', async (req, res) => {
  try {
    const config = req.body;
    const result = await highPerformanceEngine.start(config);
    
    if (result.success) {
      // Update global mining engine reference for status checks
      currentMiningEngine = highPerformanceEngine;
      
      // Emit high-performance mining start event
      io.emit('hp_mining_started', { 
        config, 
        processes: result.processes,
        expected_hashrate: result.expected_hashrate,
        timestamp: new Date().toISOString() 
      });
    }
    
    res.json(result);
  } catch (error) {
    console.error('High-performance mining start error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to start high-performance mining: ' + error.message
    });
  }
});

// High-performance mining stop endpoint  
app.post('/api/mining/stop-hp', async (req, res) => {
  try {
    const result = await highPerformanceEngine.stop();
    
    if (result.success) {
      currentMiningEngine = null;
      
      // Emit high-performance mining stop event
      io.emit('hp_mining_stopped', { 
        timestamp: new Date().toISOString() 
      });
    }
    
    res.json(result);
  } catch (error) {
    console.error('High-performance mining stop error:', error);
    res.status(500).json({
      success: false, 
      message: 'Failed to stop high-performance mining: ' + error.message
    });
  }
});

// Regular mining stop endpoint
app.post('/api/mining/stop', async (req, res) => {
  try {
    if (!currentMiningEngine) {
      return res.json({
        success: false,
        message: 'No mining operation in progress'
      });
    }

    const result = await currentMiningEngine.stop();
    
    if (result.success) {
      currentMiningEngine = null;
      
      // Emit mining stop event
      io.emit('mining_stopped', { timestamp: new Date().toISOString() });
    }
    
    res.json(result);
  } catch (error) {
    console.error('Mining stop error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to stop mining: ' + error.message
    });
  }
});

// AI insights endpoint
app.get('/api/mining/ai-insights', async (req, res) => {
  try {
    const insights = await aiPredictor.getInsights();
    const predictions = await aiPredictor.getPredictions();
    
    res.json({
      insights,
      predictions,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('AI insights error:', error);
    res.status(500).json({ error: 'Failed to get AI insights' });
  }
});

// Custom coins CRUD endpoints
app.get('/api/coins/custom', async (req, res) => {
  try {
    const customCoins = await CustomCoin.find().sort({ created_at: -1 });
    res.json(customCoins);
  } catch (error) {
    console.error('Custom coins fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch custom coins' });
  }
});

app.post('/api/coins/custom', async (req, res) => {
  try {
    const coinData = req.body;
    
    // Validate required fields
    const requiredFields = ['name', 'symbol', 'algorithm', 'block_reward'];
    const missingFields = requiredFields.filter(field => !coinData[field]);
    
    if (missingFields.length > 0) {
      return res.status(400).json({
        error: `Missing required fields: ${missingFields.join(', ')}`
      });
    }
    
    // Check for duplicate symbol
    const existingCoin = await CustomCoin.findOne({ symbol: coinData.symbol.toUpperCase() });
    if (existingCoin) {
      return res.status(400).json({
        error: `Coin with symbol ${coinData.symbol} already exists`
      });
    }
    
    const customCoin = new CustomCoin({
      ...coinData,
      symbol: coinData.symbol.toUpperCase(),
      is_custom: true,
      created_at: new Date()
    });
    
    await customCoin.save();
    res.status(201).json(customCoin);
  } catch (error) {
    console.error('Custom coin creation error:', error);
    res.status(500).json({ error: 'Failed to create custom coin' });
  }
});

app.put('/api/coins/custom/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const customCoin = await CustomCoin.findByIdAndUpdate(
      id, 
      { ...updates, updated_at: new Date() },
      { new: true, runValidators: true }
    );
    
    if (!customCoin) {
      return res.status(404).json({ error: 'Custom coin not found' });
    }
    
    res.json(customCoin);
  } catch (error) {
    console.error('Custom coin update error:', error);
    res.status(500).json({ error: 'Failed to update custom coin' });
  }
});

app.delete('/api/coins/custom/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const customCoin = await CustomCoin.findByIdAndDelete(id);
    
    if (!customCoin) {
      return res.status(404).json({ error: 'Custom coin not found' });
    }
    
    res.json({ message: 'Custom coin deleted successfully' });
  } catch (error) {
    console.error('Custom coin deletion error:', error);
    res.status(500).json({ error: 'Failed to delete custom coin' });
  }
});

// Export custom coins configuration
app.get('/api/coins/custom/export', async (req, res) => {
  try {
    const customCoins = await CustomCoin.find();
    
    const exportData = {
      export_date: new Date().toISOString(),
      version: '1.0',
      custom_coins: customCoins.map(coin => ({
        name: coin.name,
        symbol: coin.symbol,
        algorithm: coin.algorithm,
        block_time_target: coin.block_time_target,
        block_reward: coin.block_reward,
        network_difficulty: coin.network_difficulty,
        scrypt_params: coin.scrypt_params,
        pool_config: coin.pool_config,
        rpc_config: coin.rpc_config
      }))
    };
    
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', 'attachment; filename="custom_coins_export.json"');
    res.json(exportData);
  } catch (error) {
    console.error('Custom coins export error:', error);
    res.status(500).json({
      error: 'Failed to export custom coins'
    });
  }
});

// Import custom coins configuration
app.post('/api/coins/custom/import', async (req, res) => {
  try {
    const importData = req.body;
    
    if (!importData.custom_coins || !Array.isArray(importData.custom_coins)) {
      return res.status(400).json({
        error: 'Invalid import data format'
      });
    }
    
    const results = {
      imported: 0,
      skipped: 0,
      errors: []
    };
    
    for (const coinData of importData.custom_coins) {
      try {
        // Check if coin already exists
        const existingCoin = await CustomCoin.findOne({ symbol: coinData.symbol });
        if (existingCoin) {
          results.skipped++;
          continue;
        }
        
        const customCoin = new CustomCoin({
          ...coinData,
          is_custom: true,
          created_at: new Date()
        });
        
        await customCoin.save();
        results.imported++;
      } catch (error) {
        results.errors.push(`Error importing ${coinData.symbol}: ${error.message}`);
      }
    }
    
    res.json({
      message: `Import completed: ${results.imported} imported, ${results.skipped} skipped`,
      results
    });
  } catch (error) {
    console.error('Custom coins import error:', error);
    res.status(500).json({
      error: 'Failed to import custom coins'
    });
  }
});

// Remote connectivity endpoints for Android app
app.post('/api/remote/connection/test', (req, res) => {
  res.json({
    success: true,
    message: 'Connection successful',
    server_info: {
      name: 'CryptoMiner Pro',
      version: '1.0.0',
      api_version: '1.0',
      timestamp: new Date().toISOString(),
      features: {
        remote_mining: true,
        real_time_monitoring: true,
        multi_device_support: true,
        secure_authentication: true
      }
    }
  });
});

app.post('/api/remote/register', (req, res) => {
  const { device_name, device_type } = req.body;
  
  if (!device_name || !device_type) {
    return res.status(400).json({
      success: false,
      message: 'Device name and type are required'
    });
  }
  
  const deviceId = cryptoUtils.generateDeviceId();
  const accessToken = cryptoUtils.generateAccessToken();
  
  remoteDevices.set(deviceId, {
    device_name,
    device_type,
    registered_at: new Date().toISOString(),
    last_seen: new Date().toISOString(),
    status: 'active'
  });
  
  accessTokens.set(accessToken, deviceId);
  
  res.json({
    success: true,
    message: 'Device registered successfully',
    device_id: deviceId,
    access_token: accessToken
  });
});

app.get('/api/remote/status/:device_id', (req, res) => {
  const { device_id } = req.params;
  
  if (!remoteDevices.has(device_id)) {
    return res.status(404).json({
      success: false,
      message: 'Device not found'
    });
  }
  
  const device = remoteDevices.get(device_id);
  const miningStatus = currentMiningEngine ? currentMiningEngine.getStatus() : {
    is_mining: false,
    stats: { hashrate: 0, uptime: 0 }
  };
  
  res.json({
    success: true,
    device_info: device,
    mining_status: miningStatus,
    system_health: 'healthy'
  });
});

app.get('/api/remote/devices', (req, res) => {
  const devices = Array.from(remoteDevices.entries()).map(([id, device]) => ({
    device_id: id,
    ...device
  }));
  
  res.json({
    success: true,
    devices,
    total_count: devices.length
  });
});

app.get('/api/remote/mining/status', (req, res) => {
  const status = currentMiningEngine ? currentMiningEngine.getStatus() : {
    is_mining: false,
    stats: {
      hashrate: 0.0,
      accepted_shares: 0,
      rejected_shares: 0,
      blocks_found: 0,
      uptime: 0.0
    }
  };
  
  res.json({
    ...status,
    remote_access: true,
    connected_devices: remoteDevices.size
  });
});

app.post('/api/remote/mining/start', async (req, res) => {
  try {
    const config = req.body;
    
    if (!currentMiningEngine) {
      const engineClass = miningEngine.MiningEngine;
      currentMiningEngine = new engineClass(config);
    }
    
    const result = await currentMiningEngine.start();
    
    res.json({
      ...result,
      remote_controlled: true
    });
  } catch (error) {
    console.error('Remote mining start error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to start remote mining: ' + error.message
    });
  }
});

app.post('/api/remote/mining/stop', async (req, res) => {
  try {
    if (!currentMiningEngine) {
      return res.json({
        success: false,
        message: 'No mining operation in progress'
      });
    }

    const result = await currentMiningEngine.stop();
    
    if (result.success) {
      currentMiningEngine = null;
    }
    
    res.json({
      ...result,
      remote_controlled: true
    });
  } catch (error) {
    console.error('Remote mining stop error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to stop remote mining: ' + error.message
    });
  }
});

// WebSocket connection handling
io.on('connection', (socket) => {
  console.log(`🔌 Client connected: ${socket.id}`);
  connectedSockets.push(socket);

  // Send initial mining status
  const status = currentMiningEngine ? currentMiningEngine.getStatus() : {
    is_mining: false,
    stats: { hashrate: 0 }
  };
  socket.emit('mining_status', status);

  // Handle client disconnect
  socket.on('disconnect', () => {
    console.log(`📤 Client disconnected: ${socket.id}`);
    connectedSockets = connectedSockets.filter(s => s.id !== socket.id);
  });

  // Handle mining status requests
  socket.on('get_mining_status', () => {
    const status = currentMiningEngine ? currentMiningEngine.getStatus() : {
      is_mining: false,
      stats: { hashrate: 0 }
    };
    socket.emit('mining_status', status);
  });
});

// Real-time updates for connected clients
setInterval(() => {
  if (connectedSockets.length > 0 && currentMiningEngine) {
    const status = currentMiningEngine.getStatus();
    connectedSockets.forEach(socket => {
      try {
        socket.emit('mining_update', status);
      } catch (error) {
        console.error('WebSocket emit error:', error);
      }
    });
  }
}, 5000);

// System monitoring updates
setInterval(async () => {
  if (connectedSockets.length > 0) {
    try {
      const systemStats = await systemMonitor.getSystemStats();
      connectedSockets.forEach(socket => {
        try {
          socket.emit('system_update', systemStats);
        } catch (error) {
          console.error('WebSocket system update error:', error);
        }
      });
    } catch (error) {
      console.error('System stats error:', error);
    }
  }
}, 10000);

// High-performance mining hashrate updates
if (highPerformanceEngine) {
  highPerformanceEngine.on('hashrate_update', (data) => {
    if (connectedSockets.length > 0) {
      connectedSockets.forEach(socket => {
        try {
          socket.emit('hp_hashrate_update', data);
        } catch (error) {
          console.error('WebSocket HP hashrate update error:', error);
        }
      });
    }
  });
}

// Error handling
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// SERVER STARTUP
// ============================================================================

const PORT = process.env.PORT || 8001;
const HOST = process.env.HOST || '0.0.0.0';

async function startServer() {
  try {
    // Connect to database
    await connectDB();
    
    // Start server
    server.listen(PORT, HOST, () => {
      console.log(`
🚀 CryptoMiner Pro Backend (Node.js) Started Successfully!
📡 Server: http://${HOST}:${PORT}
🔌 WebSocket: ws://${HOST}:${PORT}
💾 Database: ${process.env.MONGO_URL || 'mongodb://localhost:27017/cryptominer'}
🕐 Started: ${new Date().toISOString()}
      `);
    });
    
    // Graceful shutdown
    process.on('SIGTERM', async () => {
      console.log('🛑 Received SIGTERM, shutting down gracefully...');
      
      if (currentMiningEngine) {
        await currentMiningEngine.stop();
      }
      
      if (highPerformanceEngine) {
        await highPerformanceEngine.stop();
      }
      
      server.close(() => {
        console.log('✅ Server closed');
        mongoose.connection.close(() => {
          console.log('✅ Database connection closed');
          process.exit(0);
        });
      });
    });

    process.on('SIGINT', async () => {
      console.log('\n🛑 Received SIGINT, shutting down gracefully...');
      
      if (currentMiningEngine) {
        await currentMiningEngine.stop();
      }
      
      if (highPerformanceEngine) {
        await highPerformanceEngine.stop();
      }
      
      server.close(() => {
        console.log('✅ Server closed');
        mongoose.connection.close(() => {
          console.log('✅ Database connection closed');
          process.exit(0);
        });
      });
    });
    
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Start the server
startServer();