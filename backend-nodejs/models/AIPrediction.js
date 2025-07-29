/**
 * AI Predictions Model - Enhanced Mongoose Schema
 * Stores AI prediction data and learning insights
 */

const mongoose = require('mongoose');

const AIPredictionSchema = new mongoose.Schema({
  // Prediction Metadata
  predictionId: {
    type: String,
    required: true,
    unique: true,
    default: () => `pred_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  },
  
  predictionType: {
    type: String,
    required: true,
    enum: ['hashrate', 'difficulty', 'efficiency', 'earnings', 'optimal_threads']
  },
  
  // Input Data (what was used to make the prediction)
  inputData: {
    currentHashrate: Number,
    threads: Number,
    intensity: Number,
    cpuUsage: Number,
    memoryUsage: Number,
    temperature: Number,
    coin: String,
    difficulty: Number,
    historicalData: [{
      timestamp: Date,
      value: Number
    }]
  },
  
  // Prediction Results
  prediction: {
    value: {
      type: Number,
      required: true
    },
    
    confidence: {
      type: Number,
      required: true,
      min: 0,
      max: 1
    },
    
    timeframe: {
      type: String,
      enum: ['1min', '5min', '15min', '1hour', '6hour', '24hour'],
      default: '15min'
    },
    
    range: {
      min: Number,
      max: Number
    }
  },
  
  // Model Information
  modelInfo: {
    algorithm: {
      type: String,
      enum: ['linear_regression', 'polynomial', 'neural_network', 'time_series'],
      default: 'linear_regression'
    },
    
    version: {
      type: String,
      default: '1.0'
    },
    
    trainingDataSize: {
      type: Number,
      min: 0
    },
    
    accuracy: {
      type: Number,
      min: 0,
      max: 1
    }
  },
  
  // Validation (for checking prediction accuracy later)
  validation: {
    actualValue: Number,
    accuracyScore: Number,
    validated: {
      type: Boolean,
      default: false
    },
    validatedAt: Date
  },
  
  // Context
  systemContext: {
    totalCores: Number,
    availableMemory: Number,
    operatingSystem: String,
    nodeVersion: String
  },
  
  // Status
  status: {
    type: String,
    enum: ['pending', 'active', 'validated', 'expired'],
    default: 'active'
  },
  
  expiresAt: {
    type: Date,
    required: true,
    default: () => new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours from now
  }
}, {
  timestamps: true,
  collection: 'ai_predictions'
});

// Indexes
AIPredictionSchema.index({ predictionType: 1, createdAt: -1 });
AIPredictionSchema.index({ status: 1, expiresAt: 1 });
AIPredictionSchema.index({ 'prediction.confidence': -1 });
AIPredictionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL index

// Validation middleware
AIPredictionSchema.pre('save', function(next) {
  // Auto-expire old predictions
  if (!this.expiresAt) {
    const timeframes = {
      '1min': 1 * 60 * 1000,
      '5min': 5 * 60 * 1000,
      '15min': 15 * 60 * 1000,
      '1hour': 60 * 60 * 1000,
      '6hour': 6 * 60 * 60 * 1000,
      '24hour': 24 * 60 * 60 * 1000
    };
    
    const timeframe = this.prediction.timeframe || '15min';
    this.expiresAt = new Date(Date.now() + (timeframes[timeframe] * 2)); // Double the timeframe for expiry
  }
  
  next();
});

// Instance methods
AIPredictionSchema.methods.isExpired = function() {
  return new Date() > this.expiresAt;
};

AIPredictionSchema.methods.validate = function(actualValue) {
  this.validation.actualValue = actualValue;
  this.validation.validated = true;
  this.validation.validatedAt = new Date();
  
  // Calculate accuracy score (percentage)
  const predicted = this.prediction.value;
  const actual = actualValue;
  const error = Math.abs(predicted - actual);
  const accuracy = Math.max(0, 1 - (error / Math.max(predicted, actual)));
  
  this.validation.accuracyScore = accuracy;
  this.status = 'validated';
  
  return this.save();
};

AIPredictionSchema.methods.getAccuracyPercentage = function() {
  if (!this.validation.validated) return null;
  return Math.round(this.validation.accuracyScore * 100);
};

// Static methods
AIPredictionSchema.statics.getActivePredictions = function(type) {
  const query = { 
    status: 'active',
    expiresAt: { $gt: new Date() }
  };
  
  if (type) {
    query.predictionType = type;
  }
  
  return this.find(query).sort({ createdAt: -1 });
};

AIPredictionSchema.statics.getModelAccuracy = function(algorithm, type) {
  return this.aggregate([
    {
      $match: {
        'modelInfo.algorithm': algorithm,
        predictionType: type,
        'validation.validated': true
      }
    },
    {
      $group: {
        _id: null,
        avgAccuracy: { $avg: '$validation.accuracyScore' },
        count: { $sum: 1 },
        maxAccuracy: { $max: '$validation.accuracyScore' },
        minAccuracy: { $min: '$validation.accuracyScore' }
      }
    }
  ]);
};

AIPredictionSchema.statics.cleanupExpired = function() {
  return this.deleteMany({
    $or: [
      { expiresAt: { $lt: new Date() } },
      { status: 'expired' }
    ]
  });
};

module.exports = mongoose.model('AIPrediction', AIPredictionSchema);