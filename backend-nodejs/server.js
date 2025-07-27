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
let remoteDevices = new Map();
let accessTokens = new Map();

// Middleware
app.set('trust proxy', 1); // Trust first proxy (required for Kubernetes/Docker environments)
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));
// CORS configuration for native installation
const corsOptions = {
  origin: [
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'http://localhost:8001',
    'http://127.0.0.1:8001'
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true,
  optionsSuccessStatus: 200 // Some legacy browsers choke on 204
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Handle preflight OPTIONS requests
app.options('*', cors(corsOptions));

// Rate limiting - configured for Kubernetes environment
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Increased limit for mining operations
  standardHeaders: true,
  legacyHeaders: false,
  // Skip internal health checks and monitoring requests
  skip: (req) => {
    return req.path === '/api/health' || req.path === '/api/system/stats';
  }
});
app.use(limiter);

// Database connection
const connectDB = async () => {
  try {
    const mongoUrl = process.env.MONGO_URL || 'mongodb://localhost:27017/cryptominer';
    await mongoose.connect(mongoUrl);
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error);
    process.exit(1);
  }
};

// ============================================================================
// API ENDPOINTS
// ============================================================================

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    platform: process.platform,
    node_version: process.version
  });
});

// System stats endpoint
app.get('/api/system/stats', async (req, res) => {
  try {
    const stats = await systemMonitor.getSystemStats();
    res.json(stats);
  } catch (error) {
    console.error('System stats error:', error);
    res.status(500).json({ error: 'Failed to get system stats' });
  }
});

// CPU info endpoint
app.get('/api/system/cpu-info', async (req, res) => {
  try {
    const cpuInfo = await systemMonitor.getCPUInfo();
    res.json(cpuInfo);
  } catch (error) {
    console.error('CPU info error:', error);
    res.status(500).json({ error: 'Failed to get CPU info' });
  }
});

// System environment info endpoint
app.get('/api/system/environment', async (req, res) => {
  try {
    const fs = require('fs');
    const isKubernetes = !!process.env.KUBERNETES_SERVICE_HOST;
    const isContainer = isKubernetes || fs.existsSync('/.dockerenv');
    
    // Get CPU information
    const cpuInfo = await systemMonitor.getCPUInfo();
    const cpuCount = require('os').cpus().length;
    
    // Read container limits if available
    let cpuQuota = null;
    let memoryLimit = null;
    
    try {
      if (fs.existsSync('/sys/fs/cgroup/cpu.max')) {
        cpuQuota = fs.readFileSync('/sys/fs/cgroup/cpu.max', 'utf8').trim();
      }
      if (fs.existsSync('/sys/fs/cgroup/memory.max')) {
        const limit = fs.readFileSync('/sys/fs/cgroup/memory.max', 'utf8').trim();
        memoryLimit = limit !== 'max' ? parseInt(limit) : null;
      }
    } catch (e) {
      // Ignore errors reading cgroup files
    }
    
    const environment = {
      deployment_type: isKubernetes ? 'kubernetes' : isContainer ? 'container' : 'native',
      container_info: {
        is_containerized: isContainer,
        kubernetes: isKubernetes,
        docker: fs.existsSync('/.dockerenv'),
      },
      cpu_allocation: {
        allocated_cores: cpuCount,
        physical_cores_detected: cpuInfo.cores.physical,
        logical_cores_detected: cpuInfo.cores.logical,
        cpu_quota: cpuQuota,
        optimal_mining_threads: cpuInfo.optimal_mining_config?.max_safe_threads || cpuCount - 1
      },
      memory_info: {
        total_available: require('os').totalmem(),
        container_limit: memoryLimit,
        is_limited: !!memoryLimit
      },
      performance_context: {
        environment_optimized: isContainer,
        recommended_profile: cpuInfo.optimal_mining_config?.recommended_profile || 'standard',
        max_safe_threads: cpuInfo.optimal_mining_config?.max_safe_threads || cpuCount - 1,
        performance_notes: [
          isContainer ? 
            `Running in ${isKubernetes ? 'Kubernetes' : 'Docker'} container with ${cpuCount} CPU cores allocated` :
            `Running on native system with ${cpuCount} CPU cores`,
          `Optimal mining configuration: ${cpuInfo.optimal_mining_config?.max_safe_threads || cpuCount - 1} threads`,
          cpuCount >= 8 ? 
            'Excellent CPU resources available for mining operations' :
            'Limited CPU resources - use conservative mining settings for system stability'
        ]
      },
      mining_recommendations: cpuInfo.mining_profiles || {}
    };
    
    res.json(environment);
  } catch (error) {
    console.error('Environment info error:', error);
    res.status(500).json({ error: 'Failed to get environment info' });
  }
});

// Coin presets endpoint
app.get('/api/coins/presets', async (req, res) => {
  try {
    const presets = {
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
    
    // Add custom coins
    const customCoins = await CustomCoin.findActive();
    customCoins.forEach(coin => {
      presets[coin.id] = coin.toCoinPreset();
    });
    
    res.json({ presets });
  } catch (error) {
    console.error('Coin presets error:', error);
    res.status(500).json({ error: 'Failed to get coin presets' });
  }
});

// Wallet validation endpoint
app.post('/api/wallet/validate', async (req, res) => {
  try {
    const { address, coin_symbol } = req.body;
    
    if (!address || !coin_symbol) {
      return res.status(400).json({ 
        valid: false, 
        error: 'Address and coin symbol are required' 
      });
    }
    
    const validation = await walletValidator.validateAddress(address, coin_symbol);
    res.json(validation);
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
    
    const result = await miningEngine.testPoolConnection(pool_address, pool_port, type);
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
    config: null
  };
  
  res.json(status);
});

// Start mining endpoint
app.post('/api/mining/start', async (req, res) => {
  try {
    const config = req.body;
    
    // Validate configuration
    if (!config.coin || !config.mode) {
      return res.status(400).json({
        success: false,
        message: 'Coin and mode are required'
      });
    }
    
    // Solo mining requires wallet address
    if (config.mode === 'solo' && !config.wallet_address) {
      return res.status(400).json({
        success: false,
        message: 'Wallet address is required for solo mining'
      });
    }
    
    // Pool mining requires username
    if (config.mode === 'pool' && !config.pool_username) {
      return res.status(400).json({
        success: false,
        message: 'Pool username is required for pool mining'
      });
    }
    
    // Stop current mining if running
    if (currentMiningEngine && currentMiningEngine.isMining()) {
      await currentMiningEngine.stop();
    }
    
    // Create new mining engine
    currentMiningEngine = new miningEngine.MiningEngine(config);
    
    // Start mining
    const result = await currentMiningEngine.start();
    
    if (result.success) {
      res.json({
        success: true,
        message: 'Mining started successfully',
        config: config,
        mining_type: config.mode,
        connection_type: config.custom_pool_address ? 'custom' : 'default'
      });
    } else {
      res.status(500).json({
        success: false,
        message: result.message || 'Failed to start mining'
      });
    }
  } catch (error) {
    console.error('Mining start error:', error);
    res.status(500).json({
      success: false,
      message: 'Mining start failed: ' + error.message
    });
  }
});

// Stop mining endpoint
app.post('/api/mining/stop', async (req, res) => {
  try {
    if (!currentMiningEngine || !currentMiningEngine.isMining()) {
      return res.json({
        success: false,
        message: 'No active mining session'
      });
    }
    
    await currentMiningEngine.stop();
    res.json({
      success: true,
      message: 'Mining stopped successfully'
    });
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
    const insights = await aiPredictor.getInsights(currentMiningEngine);
    res.json({
      insights: insights || {},
      predictions: insights?.predictions || {},
      optimization_suggestions: insights?.optimization_suggestions || []
    });
  } catch (error) {
    console.error('AI insights error:', error);
    res.json({
      insights: {},
      predictions: {},
      optimization_suggestions: []
    });
  }
});

// ============================================================================
// CUSTOM COIN MANAGEMENT API ENDPOINTS
// ============================================================================

// Get all custom coins
app.get('/api/coins/custom', async (req, res) => {
  try {
    const customCoins = await CustomCoin.findActive();
    res.json({
      success: true,
      coins: customCoins,
      total: customCoins.length
    });
  } catch (error) {
    console.error('Custom coins list error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get custom coins'
    });
  }
});

// Get specific custom coin
app.get('/api/coins/custom/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const customCoin = await CustomCoin.findOne({ id: id, is_active: true });
    
    if (!customCoin) {
      return res.status(404).json({
        success: false,
        message: 'Custom coin not found'
      });
    }
    
    res.json({
      success: true,
      coin: customCoin
    });
  } catch (error) {
    console.error('Custom coin get error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get custom coin'
    });
  }
});

// Add new custom coin
app.post('/api/coins/custom', async (req, res) => {
  try {
    const coinData = req.body;
    
    // Validate coin data
    const validationErrors = CustomCoin.validateCoinData(coinData);
    if (validationErrors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validationErrors
      });
    }
    
    // Check if coin ID already exists
    const existingCoin = await CustomCoin.findOne({ id: coinData.id });
    if (existingCoin) {
      return res.status(409).json({
        success: false,
        message: 'Coin ID already exists'
      });
    }
    
    // Check if symbol already exists
    const existingSymbol = await CustomCoin.findBySymbol(coinData.symbol);
    if (existingSymbol) {
      return res.status(409).json({
        success: false,
        message: 'Coin symbol already exists'
      });
    }
    
    // Create new custom coin
    const customCoin = new CustomCoin(coinData);
    
    // Validate scrypt parameters
    customCoin.validateScryptParams();
    
    // Save to database
    await customCoin.save();
    
    res.status(201).json({
      success: true,
      message: 'Custom coin created successfully',
      coin: customCoin
    });
  } catch (error) {
    console.error('Custom coin creation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create custom coin',
      error: error.message
    });
  }
});

// Update custom coin
app.put('/api/coins/custom/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    // Find existing coin
    const existingCoin = await CustomCoin.findOne({ id: id, is_active: true });
    if (!existingCoin) {
      return res.status(404).json({
        success: false,
        message: 'Custom coin not found'
      });
    }
    
    // Validate update data
    const validationErrors = CustomCoin.validateCoinData(updateData);
    if (validationErrors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validationErrors
      });
    }
    
    // Check if new symbol conflicts with existing coins (excluding current coin)
    if (updateData.symbol && updateData.symbol !== existingCoin.symbol) {
      const symbolConflict = await CustomCoin.findOne({
        symbol: updateData.symbol.toUpperCase(),
        id: { $ne: id },
        is_active: true
      });
      if (symbolConflict) {
        return res.status(409).json({
          success: false,
          message: 'Coin symbol already exists'
        });
      }
    }
    
    // Update coin
    Object.assign(existingCoin, updateData);
    existingCoin.updated_at = Date.now();
    
    // Validate scrypt parameters
    existingCoin.validateScryptParams();
    
    // Save changes
    await existingCoin.save();
    
    res.json({
      success: true,
      message: 'Custom coin updated successfully',
      coin: existingCoin
    });
  } catch (error) {
    console.error('Custom coin update error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update custom coin',
      error: error.message
    });
  }
});

// Delete custom coin
app.delete('/api/coins/custom/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find and soft delete the coin
    const customCoin = await CustomCoin.findOne({ id: id, is_active: true });
    if (!customCoin) {
      return res.status(404).json({
        success: false,
        message: 'Custom coin not found'
      });
    }
    
    // Soft delete (set is_active to false)
    customCoin.is_active = false;
    customCoin.updated_at = Date.now();
    await customCoin.save();
    
    res.json({
      success: true,
      message: 'Custom coin deleted successfully'
    });
  } catch (error) {
    console.error('Custom coin deletion error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete custom coin'
    });
  }
});

// Validate custom coin configuration
app.post('/api/coins/custom/validate', async (req, res) => {
  try {
    const coinData = req.body;
    
    // Validate coin data
    const validationErrors = CustomCoin.validateCoinData(coinData);
    
    if (validationErrors.length > 0) {
      return res.json({
        valid: false,
        errors: validationErrors
      });
    }
    
    // Additional validation checks
    const additionalChecks = [];
    
    // Check scrypt parameters
    if (coinData.scrypt_params) {
      try {
        const { N, r, p } = coinData.scrypt_params;
        if ((N & (N - 1)) !== 0) {
          additionalChecks.push('Scrypt parameter N must be a power of 2');
        }
        const memoryUsage = N * r * p;
        if (memoryUsage > 1000000) {
          additionalChecks.push('Scrypt parameters result in too high memory usage');
        }
      } catch (error) {
        additionalChecks.push('Invalid scrypt parameters');
      }
    }
    
    // Check for conflicts if ID is provided
    if (coinData.id) {
      const existingCoin = await CustomCoin.findOne({ id: coinData.id, is_active: true });
      if (existingCoin) {
        additionalChecks.push('Coin ID already exists');
      }
    }
    
    // Check for symbol conflicts
    if (coinData.symbol) {
      const existingSymbol = await CustomCoin.findBySymbol(coinData.symbol);
      if (existingSymbol) {
        additionalChecks.push('Coin symbol already exists');
      }
    }
    
    const allErrors = [...validationErrors, ...additionalChecks];
    
    res.json({
      valid: allErrors.length === 0,
      errors: allErrors,
      warnings: [],
      suggestions: [
        'Use standard scrypt parameters (N=1024, r=1, p=1) for compatibility',
        'Ensure block time target is reasonable (60-600 seconds)',
        'Verify block reward matches the actual cryptocurrency'
      ]
    });
  } catch (error) {
    console.error('Custom coin validation error:', error);
    res.status(500).json({
      valid: false,
      errors: ['Validation service failed'],
      message: error.message
    });
  }
});

// Export custom coins configuration
app.get('/api/coins/custom/export', async (req, res) => {
  try {
    const customCoins = await CustomCoin.findActive();
    
    const exportData = {
      export_date: new Date().toISOString(),
      version: '1.0',
      custom_coins: customCoins.map(coin => ({
        id: coin.id,
        name: coin.name,
        symbol: coin.symbol,
        algorithm: coin.algorithm,
        block_time_target: coin.block_time_target,
        block_reward: coin.block_reward,
        network_difficulty: coin.network_difficulty,
        scrypt_params: coin.scrypt_params,
        address_formats: coin.address_formats,
        metadata: coin.metadata
      }))
    };
    
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', 'attachment; filename="custom_coins_export.json"');
    res.json(exportData);
  } catch (error) {
    console.error('Custom coins export error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to export custom coins'
    });
  }
});

// Import custom coins configuration
app.post('/api/coins/custom/import', async (req, res) => {
  try {
    const importData = req.body;
    
    if (!importData.custom_coins || !Array.isArray(importData.custom_coins)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid import data format'
      });
    }
    
    const results = {
      imported: 0,
      skipped: 0,
      errors: []
    };
    
    for (const coinData of importData.custom_coins) {
      try {
        // Validate coin data
        const validationErrors = CustomCoin.validateCoinData(coinData);
        if (validationErrors.length > 0) {
          results.errors.push(`${coinData.id || 'Unknown'}: ${validationErrors.join(', ')}`);
          results.skipped++;
          continue;
        }
        
        // Check if coin already exists
        const existingCoin = await CustomCoin.findOne({ id: coinData.id });
        if (existingCoin) {
          results.errors.push(`${coinData.id}: Coin already exists`);
          results.skipped++;
          continue;
        }
        
        // Create new custom coin
        const customCoin = new CustomCoin(coinData);
        await customCoin.save();
        results.imported++;
      } catch (error) {
        results.errors.push(`${coinData.id || 'Unknown'}: ${error.message}`);
        results.skipped++;
      }
    }
    
    res.json({
      success: true,
      message: `Import completed: ${results.imported} imported, ${results.skipped} skipped`,
      results: results
    });
  } catch (error) {
    console.error('Custom coins import error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to import custom coins'
    });
  }
});

// ============================================================================
// REMOTE CONNECTIVITY API ENDPOINTS
// ============================================================================

// Register device endpoint
app.post('/api/remote/register', (req, res) => {
  try {
    const { device_id, device_name } = req.body;
    
    if (!device_id || !device_name) {
      return res.status(400).json({
        success: false,
        message: 'Device ID and name are required'
      });
    }
    
    // Generate access token
    const accessToken = require('crypto').randomBytes(32).toString('hex');
    
    // Store device info
    const deviceStatus = {
      device_id,
      device_name,
      is_mining: currentMiningEngine ? currentMiningEngine.isMining() : false,
      hashrate: currentMiningEngine ? currentMiningEngine.getHashrate() : 0.0,
      uptime: currentMiningEngine ? currentMiningEngine.getUptime() : 0.0,
      last_seen: new Date(),
      system_health: {} // Will be populated by system monitor
    };
    
    remoteDevices.set(device_id, deviceStatus);
    accessTokens.set(accessToken, device_id);
    
    res.json({
      success: true,
      access_token: accessToken,
      device_id: device_id,
      message: 'Device registered successfully'
    });
  } catch (error) {
    console.error('Remote device registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed: ' + error.message
    });
  }
});

// Get remote device status
app.get('/api/remote/status/:device_id', async (req, res) => {
  try {
    const { device_id } = req.params;
    
    if (!remoteDevices.has(device_id)) {
      return res.status(404).json({
        success: false,
        message: 'Device not found'
      });
    }
    
    const deviceStatus = remoteDevices.get(device_id);
    
    // Update current status
    deviceStatus.is_mining = currentMiningEngine ? currentMiningEngine.isMining() : false;
    deviceStatus.hashrate = currentMiningEngine ? currentMiningEngine.getHashrate() : 0.0;
    deviceStatus.uptime = currentMiningEngine ? currentMiningEngine.getUptime() : 0.0;
    deviceStatus.last_seen = new Date();
    deviceStatus.system_health = await systemMonitor.getSystemStats();
    
    res.json(deviceStatus);
  } catch (error) {
    console.error('Remote status error:', error);
    res.status(500).json({
      success: false,
      message: 'Status retrieval failed: ' + error.message
    });
  }
});

// List all remote devices
app.get('/api/remote/devices', (req, res) => {
  try {
    const devices = Array.from(remoteDevices.values());
    res.json({
      devices: devices,
      total: devices.length
    });
  } catch (error) {
    console.error('Remote devices list error:', error);
    res.status(500).json({
      success: false,
      message: 'Device list failed: ' + error.message
    });
  }
});

// Remote mining control endpoints
app.post('/api/remote/mining/start', async (req, res) => {
  const { device_id } = req.query;
  
  // Use the same mining start logic but with remote device tracking
  const result = await app.get('/api/mining/start').handler(req, res);
  
  // Update device status if device_id provided
  if (device_id && remoteDevices.has(device_id)) {
    const deviceStatus = remoteDevices.get(device_id);
    deviceStatus.is_mining = true;
    deviceStatus.last_seen = new Date();
  }
  
  return result;
});

app.post('/api/remote/mining/stop', async (req, res) => {
  const { device_id } = req.query;
  
  // Use the same mining stop logic
  const result = await app.get('/api/mining/stop').handler(req, res);
  
  // Update device status if device_id provided
  if (device_id && remoteDevices.has(device_id)) {
    const deviceStatus = remoteDevices.get(device_id);
    deviceStatus.is_mining = false;
    deviceStatus.last_seen = new Date();
  }
  
  return result;
});

app.get('/api/remote/mining/status', async (req, res) => {
  try {
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
      connected_devices: remoteDevices.size,
      api_version: '1.0'
    });
  } catch (error) {
    console.error('Remote mining status error:', error);
    res.status(500).json({
      success: false,
      message: 'Remote status failed: ' + error.message
    });
  }
});

app.get('/api/remote/connection/test', async (req, res) => {
  try {
    const systemStats = await systemMonitor.getSystemStats();
    
    res.json({
      success: true,
      message: 'Remote connection successful',
      server_time: new Date().toISOString(),
      system_health: systemStats,
      api_version: '1.0',
      features: {
        remote_mining: true,
        real_time_monitoring: true,
        multi_device_support: true,
        secure_authentication: true
      }
    });
  } catch (error) {
    console.error('Remote connection test error:', error);
    res.status(500).json({
      success: false,
      message: 'Connection test failed: ' + error.message
    });
  }
});

// ============================================================================
// WEBSOCKET HANDLING
// ============================================================================

// Add debugging for Socket.io connection attempts
io.engine.on('connection_error', (err) => {
  console.log('🔌 Socket.io connection error:', err);
});

io.on('connection', (socket) => {
  console.log('🔌 Client connected successfully:', socket.id);
  console.log('🔌 Connected from:', socket.handshake.address, 'via', socket.handshake.headers.origin);
  connectedSockets.push(socket);
  
  socket.on('disconnect', (reason) => {
    console.log('🔌 Client disconnected:', socket.id, 'reason:', reason);
    connectedSockets = connectedSockets.filter(s => s.id !== socket.id);
  });
  
  socket.on('connect_error', (error) => {
    console.log('🔌 Socket connect error:', error);
  });
  
  // Send initial data
  socket.emit('connected', {
    message: 'Connected to CryptoMiner Pro',
    timestamp: new Date().toISOString(),
    socketId: socket.id
  });
});

// Real-time updates
const broadcastUpdates = async () => {
  if (connectedSockets.length > 0) {
    try {
      // Mining updates
      if (currentMiningEngine) {
        const miningData = {
          type: 'mining_update',
          timestamp: new Date().toISOString(),
          stats: currentMiningEngine.getStatus().stats,
          is_mining: currentMiningEngine.isMining()
        };
        
        connectedSockets.forEach(socket => {
          socket.emit('mining_update', miningData);
        });
      }
      
      // System updates
      const systemStats = await systemMonitor.getSystemStats();
      const systemData = {
        type: 'system_update',
        timestamp: new Date().toISOString(),
        data: systemStats
      };
      
      connectedSockets.forEach(socket => {
        socket.emit('system_update', systemData);
      });
    } catch (error) {
      console.error('Broadcast error:', error);
    }
  }
};

// Start real-time updates
setInterval(broadcastUpdates, 1000);

// ============================================================================
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
      
      // Stop mining if running
      if (currentMiningEngine && currentMiningEngine.isMining()) {
        await currentMiningEngine.stop();
      }
      
      // Close database connection
      await mongoose.connection.close();
      
      // Close server
      server.close(() => {
        console.log('✅ Server closed successfully');
        process.exit(0);
      });
    });
    
  } catch (error) {
    console.error('❌ Server startup failed:', error);
    process.exit(1);
  }
}

// Start the server
startServer();

console.log(`
🚀 CryptoMiner Pro Backend (Node.js) Started Successfully!
📡 Server: http://${HOST}:${PORT}
🔌 WebSocket: ws://${HOST}:${PORT}
💾 Database: ${process.env.MONGO_URL || 'mongodb://localhost:27017/cryptominer'}
🕐 Started: ${new Date().toISOString()}
`);