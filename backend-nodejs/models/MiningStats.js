/**
 * Mining Stats Model - Enhanced Mongoose Schema
 * Stores mining performance and statistics data
 */

const mongoose = require('mongoose');

const MiningStatsSchema = new mongoose.Schema({
  sessionId: {
    type: String,
    required: true,
    index: true
  },
  
  // Mining Configuration
  coin: {
    type: String,
    required: true,
    enum: ['litecoin', 'dogecoin', 'feathercoin', 'custom']
  },
  
  mode: {
    type: String,
    required: true,
    enum: ['solo', 'pool']
  },
  
  threads: {
    type: Number,
    required: true,
    min: 1,
    max: 256
  },
  
  intensity: {
    type: Number,
    required: true,
    min: 0.1,
    max: 1.0
  },
  
  // Performance Metrics
  hashrate: {
    type: Number,
    default: 0,
    min: 0
  },
  
  acceptedShares: {
    type: Number,
    default: 0,
    min: 0
  },
  
  rejectedShares: {
    type: Number,
    default: 0,
    min: 0
  },
  
  difficulty: {
    type: Number,
    default: 1,
    min: 1
  },
  
  // System Metrics
  cpuUsage: {
    type: Number,
    min: 0,
    max: 100
  },
  
  memoryUsage: {
    type: Number,
    min: 0,
    max: 100
  },
  
  temperature: {
    type: Number,
    min: 0,
    max: 150
  },
  
  // Pool Information
  poolInfo: {
    address: String,
    port: Number,
    username: String,
    connected: {
      type: Boolean,
      default: false
    }
  },
  
  // Timing
  startTime: {
    type: Date,
    default: Date.now
  },
  
  endTime: {
    type: Date
  },
  
  duration: {
    type: Number, // in seconds
    min: 0
  },
  
  // Mining Results
  blocksFound: {
    type: Number,
    default: 0,
    min: 0
  },
  
  estimatedEarnings: {
    type: Number,
    default: 0,
    min: 0
  }
}, {
  timestamps: true, // Automatically adds createdAt and updatedAt
  collection: 'mining_stats'
});

// Indexes for better query performance
MiningStatsSchema.index({ sessionId: 1, createdAt: -1 });
MiningStatsSchema.index({ coin: 1, createdAt: -1 });
MiningStatsSchema.index({ createdAt: -1 });

// Pre-save middleware to calculate duration
MiningStatsSchema.pre('save', function(next) {
  if (this.endTime && this.startTime) {
    this.duration = Math.floor((this.endTime - this.startTime) / 1000);
  }
  next();
});

// Instance methods
MiningStatsSchema.methods.getEfficiency = function() {
  const totalShares = this.acceptedShares + this.rejectedShares;
  if (totalShares === 0) return 0;
  return (this.acceptedShares / totalShares) * 100;
};

MiningStatsSchema.methods.getAverageHashrate = function() {
  if (!this.duration || this.duration === 0) return this.hashrate;
  return this.hashrate; // Could be enhanced with historical data
};

// Static methods
MiningStatsSchema.statics.getTopPerformingSessions = function(limit = 10) {
  return this.find()
    .sort({ hashrate: -1 })
    .limit(limit)
    .select('sessionId coin hashrate acceptedShares createdAt');
};

MiningStatsSchema.statics.getRecentStats = function(hours = 24) {
  const since = new Date(Date.now() - hours * 60 * 60 * 1000);
  return this.find({ createdAt: { $gte: since } })
    .sort({ createdAt: -1 });
};

module.exports = mongoose.model('MiningStats', MiningStatsSchema);