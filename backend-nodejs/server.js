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
const enhancedAI = require('./ai/enhanced_predictor');

// Enhanced Mongoose Models
const CustomCoin = require('./models/CustomCoin');
const MiningStats = require('./models/MiningStats');
const AIPrediction = require('./models/AIPrediction');
const SystemConfig = require('./models/SystemConfig');
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
  origin: function (origin, callback) {
    // Allow requests from any origin in development and preview environments
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:8001', 
      'https://b8a64dbe-314e-43b8-9274-f05e86511466.preview.emergentagent.com'
    ];
    
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Allow all origins that match the preview domain pattern
    if (origin.includes('preview.emergentagent.com') || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    // Allow all origins in container environments
    return callback(null, true);
  },
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
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
    const cpuInfo = await systemMonitor.getCPUInfo();
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

// AI insights endpoint - Enhanced with real mining data
app.get('/api/mining/ai-insights', async (req, res) => {
  try {
    // Pass current mining engine to AI predictor for real data analysis
    const insights = await aiPredictor.getInsights(currentMiningEngine);
    
    res.json({
      ...insights,
      timestamp: new Date().toISOString(),
      mining_engine_connected: !!currentMiningEngine,
      real_data_available: currentMiningEngine ? currentMiningEngine.isMining() : false
    });
  } catch (error) {
    console.error('AI insights error:', error);
    res.status(500).json({ error: 'Failed to get AI insights' });
  }
});

// Enhanced AI insights with advanced ML - NEW ENDPOINT
app.get('/api/mining/ai-insights-advanced', async (req, res) => {
  try {
    // Get historical data from AI predictor
    const historicalData = aiPredictor.historicalData || [];
    
    // Get advanced optimization from enhanced AI
    const advancedAnalysis = await enhancedAI.getAdvancedOptimization(
      currentMiningEngine, 
      historicalData
    );
    
    res.json({
      ...advancedAnalysis,
      data_points: historicalData.length,
      mining_engine_status: currentMiningEngine ? 'connected' : 'disconnected',
      ai_version: '2.0_enhanced'
    });
  } catch (error) {
    console.error('Enhanced AI insights error:', error);
    res.status(500).json({ 
      error: 'Failed to get enhanced AI insights',
      fallback: await enhancedAI.getFailsafeRecommendations()
    });
  }
});

// ==============================
// Enhanced Mining Statistics API
// ==============================

// Get mining statistics
app.get('/api/mining/stats', async (req, res) => {
  try {
    const { limit = 50, hours = 24, coin } = req.query;
    const since = new Date(Date.now() - hours * 60 * 60 * 1000);
    
    const query = { createdAt: { $gte: since } };
    if (coin) query.coin = coin;
    
    const stats = await MiningStats.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));
    
    res.json({
      success: true,
      count: stats.length,
      data: stats
    });
  } catch (error) {
    console.error('Mining stats error:', error);
    res.status(500).json({ error: 'Failed to get mining statistics' });
  }
});

// Save mining statistics
app.post('/api/mining/stats', async (req, res) => {
  try {
    const statsData = new MiningStats(req.body);
    const savedStats = await statsData.save();
    
    res.json({
      success: true,
      data: savedStats,
      efficiency: savedStats.getEfficiency()
    });
  } catch (error) {
    console.error('Save mining stats error:', error);
    res.status(500).json({ error: 'Failed to save mining statistics' });
  }
});

// Get top performing mining sessions
app.get('/api/mining/stats/top', async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const topSessions = await MiningStats.getTopPerformingSessions(parseInt(limit));
    
    res.json({
      success: true,
      data: topSessions
    });
  } catch (error) {
    console.error('Top stats error:', error);
    res.status(500).json({ error: 'Failed to get top performing sessions' });
  }
});

// ==============================
// Enhanced AI Predictions API
// ==============================

// Get AI predictions
app.get('/api/ai/predictions', async (req, res) => {
  try {
    const { type, limit = 20 } = req.query;
    const predictions = await AIPrediction.getActivePredictions(type)
      .limit(parseInt(limit));
    
    res.json({
      success: true,
      count: predictions.length,
      data: predictions.map(p => ({
        ...p.toObject(),
        confidencePercentage: Math.round(p.prediction.confidence * 100),
        isExpired: p.isExpired()
      }))
    });
  } catch (error) {
    console.error('AI predictions error:', error);
    res.status(500).json({ error: 'Failed to get AI predictions' });
  }
});

// Store AI prediction
app.post('/api/ai/predictions', async (req, res) => {
  try {
    const predictionData = new AIPrediction(req.body);
    const savedPrediction = await predictionData.save();
    
    res.json({
      success: true,
      data: savedPrediction,
      confidencePercentage: Math.round(savedPrediction.prediction.confidence * 100)
    });
  } catch (error) {
    console.error('Save AI prediction error:', error);
    res.status(500).json({ error: 'Failed to save AI prediction' });
  }
});

// Validate AI prediction accuracy
app.post('/api/ai/predictions/:id/validate', async (req, res) => {
  try {
    const { id } = req.params;
    const { actualValue } = req.body;
    
    const prediction = await AIPrediction.findById(id);
    if (!prediction) {
      return res.status(404).json({ error: 'Prediction not found' });
    }
    
    await prediction.validatePrediction(actualValue);
    
    res.json({
      success: true,
      accuracy: prediction.getAccuracyPercentage(),
      data: prediction
    });
  } catch (error) {
    console.error('Validate prediction error:', error);
    res.status(500).json({ error: 'Failed to validate prediction' });
  }
});

// Get model accuracy stats
app.get('/api/ai/model-accuracy', async (req, res) => {
  try {
    const { algorithm = 'linear_regression', type = 'hashrate' } = req.query;
    const accuracy = await AIPrediction.getModelAccuracy(algorithm, type);
    
    res.json({
      success: true,
      algorithm,
      type,
      accuracy: accuracy[0] || { avgAccuracy: 0, count: 0, maxAccuracy: 0, minAccuracy: 0 }
    });
  } catch (error) {
    console.error('Model accuracy error:', error);
    res.status(500).json({ error: 'Failed to get model accuracy' });
  }
});

// ==============================
// Enhanced System Configuration API
// ==============================

// Get system configuration
app.get('/api/config/:type', async (req, res) => {
  try {
    const { type } = req.params;
    const { userId = 'default_user' } = req.query;
    
    const config = await SystemConfig.getConfig(type, userId);
    
    if (!config) {
      // Return default configuration if none exists
      const defaultConfig = new SystemConfig({ configType: type, userId });
      res.json({
        success: true,
        data: defaultConfig
      });
    } else {
      res.json({
        success: true,
        data: config
      });
    }
  } catch (error) {
    console.error('Get config error:', error);
    res.status(500).json({ error: 'Failed to get configuration' });
  }
});

// Set system configuration
app.post('/api/config/:type', async (req, res) => {
  try {
    const { type } = req.params;
    const { userId = 'default_user' } = req.query;
    const { config } = req.body;
    
    const savedConfig = await SystemConfig.setConfig(type, config, userId);
    
    // Validate the configuration
    const errors = savedConfig.validateConfig();
    if (errors.length > 0) {
      return res.status(400).json({ 
        error: 'Configuration validation failed',
        details: errors
      });
    }
    
    res.json({
      success: true,
      data: savedConfig
    });
  } catch (error) {
    console.error('Set config error:', error);
    res.status(500).json({ error: 'Failed to set configuration' });
  }
});

// Get user preferences
app.get('/api/config/user/preferences', async (req, res) => {
  try {
    const { userId = 'default_user' } = req.query;
    const preferences = await SystemConfig.getUserPreferences(userId);
    
    res.json({
      success: true,
      data: preferences || { 
        config: {
          theme: 'dark',
          refreshInterval: 2000,
          showAdvancedOptions: false,
          notifications: { enabled: true }
        }
      }
    });
  } catch (error) {
    console.error('Get user preferences error:', error);
    res.status(500).json({ error: 'Failed to get user preferences' });
  }
});

// Get mining defaults
app.get('/api/config/mining/defaults', async (req, res) => {
  try {
    const { userId = 'default_user' } = req.query;
    const defaults = await SystemConfig.getMiningDefaults(userId);
    
    res.json({
      success: true,
      data: defaults || { 
        config: {
          defaultCoin: 'litecoin',
          defaultThreads: 4,
          defaultIntensity: 0.8,
          defaultMode: 'pool',
          maxCpuUsage: 90,
          maxMemoryUsage: 85
        }
      }
    });
  } catch (error) {
    console.error('Get mining defaults error:', error);
    res.status(500).json({ error: 'Failed to get mining defaults' });
  }
});

// ==============================
// Enhanced Mining Session Management
// ==============================

// Start mining session with enhanced tracking
app.post('/api/mining/session/start', async (req, res) => {
  try {
    const sessionData = {
      sessionId: `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      ...req.body,
      startTime: new Date()
    };
    
    const miningSession = new MiningStats(sessionData);
    const savedSession = await miningSession.save();
    
    res.json({
      success: true,
      sessionId: savedSession.sessionId,
      data: savedSession
    });
  } catch (error) {
    console.error('Start mining session error:', error);
    res.status(500).json({ error: 'Failed to start mining session' });
  }
});

// End mining session with final stats
app.post('/api/mining/session/:sessionId/end', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { finalStats } = req.body;
    
    const session = await MiningStats.findOne({ sessionId });
    if (!session) {
      return res.status(404).json({ error: 'Mining session not found' });
    }
    
    // Update session with final statistics
    session.endTime = new Date();
    if (finalStats) {
      session.hashrate = finalStats.hashrate || session.hashrate;
      session.acceptedShares = finalStats.acceptedShares || session.acceptedShares;
      session.rejectedShares = finalStats.rejectedShares || session.rejectedShares;
      session.cpuUsage = finalStats.cpuUsage || session.cpuUsage;
      session.memoryUsage = finalStats.memoryUsage || session.memoryUsage;
      session.blocksFound = finalStats.blocksFound || session.blocksFound;
    }
    
    const savedSession = await session.save();
    
    res.json({
      success: true,
      duration: savedSession.duration,
      efficiency: savedSession.getEfficiency(),
      data: savedSession
    });
  } catch (error) {
    console.error('End mining session error:', error);
    res.status(500).json({ error: 'Failed to end mining session' });
  }
});

// Update mining session stats (for real-time updates)
app.put('/api/mining/session/:sessionId/update', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const updateData = req.body;
    
    const session = await MiningStats.findOneAndUpdate(
      { sessionId },
      { $set: updateData },
      { new: true, runValidators: true }
    );
    
    if (!session) {
      return res.status(404).json({ error: 'Mining session not found' });
    }
    
    res.json({
      success: true,
      data: session,
      efficiency: session.getEfficiency()
    });
  } catch (error) {
    console.error('Update mining session error:', error);
    res.status(500).json({ error: 'Failed to update mining session' });
  }
});

// ==============================
// Database Maintenance API
// ==============================

// Database cleanup and maintenance
app.post('/api/maintenance/cleanup', async (req, res) => {
  try {
    // Clean up expired AI predictions
    const expiredPredictions = await AIPrediction.cleanupExpired();
    
    // Clean up old mining stats based on retention policy
    const config = await SystemConfig.getConfig('user_preferences');
    const retentionDays = config?.config?.dataRetentionDays || 30;
    const cutoffDate = new Date(Date.now() - retentionDays * 24 * 60 * 60 * 1000);
    
    const oldStats = await MiningStats.deleteMany({ createdAt: { $lt: cutoffDate } });
    
    res.json({
      success: true,
      cleaned: {
        expiredPredictions: expiredPredictions.deletedCount || 0,
        oldMiningStats: oldStats.deletedCount || 0
      },
      retentionPolicy: `${retentionDays} days`
    });
  } catch (error) {
    console.error('Database cleanup error:', error);
    res.status(500).json({ error: 'Failed to perform database cleanup' });
  }
});

// Get database statistics
app.get('/api/maintenance/stats', async (req, res) => {
  try {
    const [miningStatsCount, aiPredictionsCount, customCoinsCount, configCount] = await Promise.all([
      MiningStats.countDocuments(),
      AIPrediction.countDocuments(),
      CustomCoin.countDocuments(),
      SystemConfig.countDocuments()
    ]);
    
    res.json({
      success: true,
      collections: {
        miningStats: miningStatsCount,
        aiPredictions: aiPredictionsCount,
        customCoins: customCoinsCount,
        systemConfigs: configCount
      },
      totalDocuments: miningStatsCount + aiPredictionsCount + customCoinsCount + configCount
    });
  } catch (error) {
    console.error('Database stats error:', error);
    res.status(500).json({ error: 'Failed to get database statistics' });
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

// ==============================
// Additional Advanced CRUD Endpoints
// ==============================

// Delete AI prediction
app.delete('/api/ai/predictions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const deleted = await AIPrediction.findByIdAndDelete(id);
    if (!deleted) {
      return res.status(404).json({ error: 'AI prediction not found' });
    }
    
    res.json({
      success: true,
      message: 'AI prediction deleted successfully',
      deletedId: id
    });
  } catch (error) {
    console.error('Delete AI prediction error:', error);
    res.status(500).json({ error: 'Failed to delete AI prediction' });
  }
});

// Update AI prediction
app.put('/api/ai/predictions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const updated = await AIPrediction.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );
    
    if (!updated) {
      return res.status(404).json({ error: 'AI prediction not found' });
    }
    
    res.json({
      success: true,
      data: updated,
      confidencePercentage: Math.round(updated.prediction.confidence * 100)
    });
  } catch (error) {
    console.error('Update AI prediction error:', error);
    res.status(500).json({ error: 'Failed to update AI prediction' });
  }
});

// Delete mining stats
app.delete('/api/mining/stats/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    
    const deleted = await MiningStats.findOneAndDelete({ sessionId });
    if (!deleted) {
      return res.status(404).json({ error: 'Mining session not found' });
    }
    
    res.json({
      success: true,
      message: 'Mining stats deleted successfully',
      deletedSessionId: sessionId
    });
  } catch (error) {
    console.error('Delete mining stats error:', error);
    res.status(500).json({ error: 'Failed to delete mining stats' });
  }
});

// Update mining stats
app.put('/api/mining/stats/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const updateData = req.body;
    
    const updated = await MiningStats.findOneAndUpdate(
      { sessionId },
      updateData,
      { new: true, runValidators: true }
    );
    
    if (!updated) {
      return res.status(404).json({ error: 'Mining session not found' });
    }
    
    res.json({
      success: true,
      data: updated,
      efficiency: updated.getEfficiency()
    });
  } catch (error) {
    console.error('Update mining stats error:', error);
    res.status(500).json({ error: 'Failed to update mining stats' });
  }
});

// Delete system config
app.delete('/api/config/:type', async (req, res) => {
  try {
    const { type } = req.params;
    const { userId = 'default_user' } = req.query;
    
    const deleted = await SystemConfig.findOneAndDelete({ configType: type, userId });
    if (!deleted) {
      return res.status(404).json({ error: 'Configuration not found' });
    }
    
    res.json({
      success: true,
      message: 'Configuration deleted successfully',
      deletedType: type
    });
  } catch (error) {
    console.error('Delete config error:', error);
    res.status(500).json({ error: 'Failed to delete configuration' });
  }
});

// Update system config (PUT method)
app.put('/api/config/:type', async (req, res) => {
  try {
    const { type } = req.params;
    const { userId = 'default_user' } = req.query;
    const { config } = req.body;
    
    const updated = await SystemConfig.findOneAndUpdate(
      { configType: type, userId },
      { 
        config: config,
        lastModified: new Date(),
        active: true
      },
      { 
        new: true,
        runValidators: true
      }
    );
    
    if (!updated) {
      return res.status(404).json({ error: 'Configuration not found' });
    }
    
    res.json({
      success: true,
      data: updated
    });
  } catch (error) {
    console.error('Update config error:', error);
    res.status(500).json({ error: 'Failed to update configuration' });
  }
});

// Bulk operations for mining stats
app.post('/api/mining/stats/bulk-delete', async (req, res) => {
  try {
    const { sessionIds, olderThan } = req.body;
    
    let filter = {};
    if (sessionIds && sessionIds.length > 0) {
      filter.sessionId = { $in: sessionIds };
    }
    if (olderThan) {
      filter.createdAt = { $lt: new Date(olderThan) };
    }
    
    const result = await MiningStats.deleteMany(filter);
    
    res.json({
      success: true,
      deletedCount: result.deletedCount,
      message: `Deleted ${result.deletedCount} mining stat records`
    });
  } catch (error) {
    console.error('Bulk delete mining stats error:', error);
    res.status(500).json({ error: 'Failed to bulk delete mining stats' });
  }
});

// Advanced analytics endpoint
app.get('/api/mining/analytics', async (req, res) => {
  try {
    const { days = 7, coin } = req.query;
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    
    const matchConditions = { createdAt: { $gte: since } };
    if (coin) matchConditions.coin = coin;
    
    const analytics = await MiningStats.aggregate([
      { $match: matchConditions },
      {
        $group: {
          _id: null,
          totalSessions: { $sum: 1 },
          avgHashrate: { $avg: '$hashrate' },
          maxHashrate: { $max: '$hashrate' },
          totalShares: { $sum: { $add: ['$acceptedShares', '$rejectedShares'] } },
          acceptedShares: { $sum: '$acceptedShares' },
          rejectedShares: { $sum: '$rejectedShares' },
          totalBlocks: { $sum: '$blocksFound' },
          avgCpuUsage: { $avg: '$cpuUsage' },
          avgMemoryUsage: { $avg: '$memoryUsage' }
        }
      }
    ]);
    
    const result = analytics[0] || {
      totalSessions: 0,
      avgHashrate: 0,
      maxHashrate: 0,
      totalShares: 0,
      acceptedShares: 0,
      rejectedShares: 0,
      totalBlocks: 0,
      avgCpuUsage: 0,
      avgMemoryUsage: 0
    };
    
    // Calculate efficiency
    result.overallEfficiency = result.totalShares > 0 ? 
      (result.acceptedShares / result.totalShares) * 100 : 0;
    
    res.json({
      success: true,
      period: `${days} days`,
      analytics: result
    });
  } catch (error) {
    console.error('Mining analytics error:', error);
    res.status(500).json({ error: 'Failed to get mining analytics' });
  }
});

// ==============================
// End Additional CRUD Endpoints
// ==============================

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