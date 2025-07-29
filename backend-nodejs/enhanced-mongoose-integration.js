/**
 * Enhanced Database Integration with Mongoose
 * Add this to your server.js to use the new models
 */

// Add these imports to your server.js
const MiningStats = require('./models/MiningStats');
const AIPrediction = require('./models/AIPrediction');
const SystemConfig = require('./models/SystemConfig');

// Enhanced API endpoints using Mongoose models

// Mining Statistics Endpoints
app.get('/api/mining/stats', async (req, res) => {
  try {
    const { limit = 50, hours = 24 } = req.query;
    const since = new Date(Date.now() - hours * 60 * 60 * 1000);
    
    const stats = await MiningStats.find({ createdAt: { $gte: since } })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));
    
    res.json(stats);
  } catch (error) {
    console.error('Mining stats error:', error);
    res.status(500).json({ error: 'Failed to get mining statistics' });
  }
});

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

app.get('/api/mining/stats/top', async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const topSessions = await MiningStats.getTopPerformingSessions(parseInt(limit));
    
    res.json(topSessions);
  } catch (error) {
    console.error('Top stats error:', error);
    res.status(500).json({ error: 'Failed to get top performing sessions' });
  }
});

// AI Predictions Endpoints
app.get('/api/ai/predictions', async (req, res) => {
  try {
    const { type } = req.query;
    const predictions = await AIPrediction.getActivePredictions(type);
    
    res.json(predictions);
  } catch (error) {
    console.error('AI predictions error:', error);
    res.status(500).json({ error: 'Failed to get AI predictions' });
  }
});

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

app.post('/api/ai/predictions/:id/validate', async (req, res) => {
  try {
    const { id } = req.params;
    const { actualValue } = req.body;
    
    const prediction = await AIPrediction.findById(id);
    if (!prediction) {
      return res.status(404).json({ error: 'Prediction not found' });
    }
    
    await prediction.validate(actualValue);
    
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

app.get('/api/ai/model-accuracy', async (req, res) => {
  try {
    const { algorithm, type } = req.query;
    const accuracy = await AIPrediction.getModelAccuracy(algorithm, type);
    
    res.json({
      algorithm,
      type,
      accuracy: accuracy[0] || { avgAccuracy: 0, count: 0 }
    });
  } catch (error) {
    console.error('Model accuracy error:', error);
    res.status(500).json({ error: 'Failed to get model accuracy' });
  }
});

// System Configuration Endpoints
app.get('/api/config/:type', async (req, res) => {
  try {
    const { type } = req.params;
    const { userId = 'default_user' } = req.query;
    
    const config = await SystemConfig.getConfig(type, userId);
    
    if (!config) {
      return res.status(404).json({ error: 'Configuration not found' });
    }
    
    res.json(config);
  } catch (error) {
    console.error('Get config error:', error);
    res.status(500).json({ error: 'Failed to get configuration' });
  }
});

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

app.get('/api/config/user/preferences', async (req, res) => {
  try {
    const { userId = 'default_user' } = req.query;
    const preferences = await SystemConfig.getUserPreferences(userId);
    
    res.json(preferences || { config: {} });
  } catch (error) {
    console.error('Get user preferences error:', error);
    res.status(500).json({ error: 'Failed to get user preferences' });
  }
});

app.get('/api/config/mining/defaults', async (req, res) => {
  try {
    const { userId = 'default_user' } = req.query;
    const defaults = await SystemConfig.getMiningDefaults(userId);
    
    res.json(defaults || { 
      config: {
        defaultCoin: 'litecoin',
        defaultThreads: 4,
        defaultIntensity: 0.8,
        defaultMode: 'pool'
      }
    });
  } catch (error) {
    console.error('Get mining defaults error:', error);
    res.status(500).json({ error: 'Failed to get mining defaults' });
  }
});

// Enhanced Mining Session Management
app.post('/api/mining/session/start', async (req, res) => {
  try {
    const sessionData = {
      sessionId: `session_${Date.now()}`,
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

app.post('/api/mining/session/:sessionId/end', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { finalStats } = req.body;
    
    const session = await MiningStats.findOne({ sessionId });
    if (!session) {
      return res.status(404).json({ error: 'Mining session not found' });
    }
    
    session.endTime = new Date();
    session.hashrate = finalStats.hashrate || session.hashrate;
    session.acceptedShares = finalStats.acceptedShares || session.acceptedShares;
    session.rejectedShares = finalStats.rejectedShares || session.rejectedShares;
    
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

// Database maintenance endpoints
app.post('/api/maintenance/cleanup', async (req, res) => {
  try {
    // Clean up expired AI predictions
    const expiredPredictions = await AIPrediction.cleanupExpired();
    
    // Clean up old mining stats (older than retention period)
    const config = await SystemConfig.getConfig('user_preferences');
    const retentionDays = config?.config?.dataRetentionDays || 30;
    const cutoffDate = new Date(Date.now() - retentionDays * 24 * 60 * 60 * 1000);
    
    const oldStats = await MiningStats.deleteMany({ createdAt: { $lt: cutoffDate } });
    
    res.json({
      success: true,
      cleaned: {
        expiredPredictions: expiredPredictions.deletedCount,
        oldMiningStats: oldStats.deletedCount
      }
    });
  } catch (error) {
    console.error('Database cleanup error:', error);
    res.status(500).json({ error: 'Failed to perform database cleanup' });
  }
});

module.exports = {
  MiningStats,
  AIPrediction,
  SystemConfig
};