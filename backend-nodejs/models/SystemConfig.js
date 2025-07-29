/**
 * System Configuration Model - Enhanced Mongoose Schema
 * Stores system settings and user preferences
 */

const mongoose = require('mongoose');

const SystemConfigSchema = new mongoose.Schema({
  // Configuration Type
  configType: {
    type: String,
    required: true,
    enum: ['user_preferences', 'mining_defaults', 'system_settings', 'ai_config', 'pool_settings'],
    index: true
  },
  
  // User ID (for multi-user support in future)
  userId: {
    type: String,
    default: 'default_user',
    index: true
  },
  
  // Configuration Data
  config: {
    // Mining Preferences
    defaultCoin: {
      type: String,
      default: 'litecoin'
    },
    
    defaultThreads: {
      type: Number,
      min: 1,
      max: 256,
      default: 4
    },
    
    defaultIntensity: {
      type: Number,
      min: 0.1,
      max: 1.0,
      default: 0.8
    },
    
    defaultMode: {
      type: String,
      enum: ['solo', 'pool'],
      default: 'pool'
    },
    
    // Performance Settings
    maxCpuUsage: {
      type: Number,
      min: 10,
      max: 100,
      default: 90
    },
    
    maxMemoryUsage: {
      type: Number,
      min: 10,
      max: 100,
      default: 85
    },
    
    temperatureThreshold: {
      type: Number,
      min: 60,
      max: 100,
      default: 85
    },
    
    // AI Settings
    aiEnabled: {
      type: Boolean,
      default: true
    },
    
    aiLearningRate: {
      type: Number,
      min: 0.001,
      max: 0.1,
      default: 0.01
    },
    
    aiPredictionInterval: {
      type: Number,
      min: 30000, // 30 seconds
      max: 3600000, // 1 hour
      default: 60000 // 1 minute
    },
    
    autoOptimization: {
      type: Boolean,
      default: false
    },
    
    // Pool Settings
    preferredPools: [{
      coin: String,
      address: String,
      port: Number,
      username: String,
      priority: {
        type: Number,
        min: 1,
        max: 10,
        default: 1
      }
    }],
    
    // UI Preferences
    theme: {
      type: String,
      enum: ['dark', 'light', 'auto'],
      default: 'dark'
    },
    
    refreshInterval: {
      type: Number,
      min: 1000, // 1 second
      max: 60000, // 1 minute
      default: 2000 // 2 seconds
    },
    
    showAdvancedOptions: {
      type: Boolean,
      default: false
    },
    
    // Notification Settings
    notifications: {
      enabled: {
        type: Boolean,
        default: true
      },
      
      hashrateDrop: {
        enabled: Boolean,
        threshold: Number // percentage drop
      },
      
      highTemperature: {
        enabled: Boolean,
        threshold: Number
      },
      
      newBlock: {
        enabled: Boolean
      },
      
      poolDisconnection: {
        enabled: Boolean
      }
    },
    
    // Security & Privacy
    allowRemoteAccess: {
      type: Boolean,
      default: false
    },
    
    dataRetentionDays: {
      type: Number,
      min: 1,
      max: 365,
      default: 30
    },
    
    // System Overrides
    overrides: {
      cpuCores: Number,
      memoryLimit: Number,
      forceMode: String
    }
  },
  
  // Metadata
  version: {
    type: String,
    default: '1.0'
  },
  
  lastModified: {
    type: Date,
    default: Date.now
  },
  
  active: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true,
  collection: 'system_config'
});

// Indexes
SystemConfigSchema.index({ configType: 1, userId: 1 }, { unique: true });
SystemConfigSchema.index({ active: 1, updatedAt: -1 });

// Pre-save middleware
SystemConfigSchema.pre('save', function(next) {
  this.lastModified = new Date();
  next();
});

// Instance methods
SystemConfigSchema.methods.updateConfig = function(newConfig) {
  // Deep merge configuration
  this.config = { ...this.config, ...newConfig };
  this.lastModified = new Date();
  return this.save();
};

SystemConfigSchema.methods.resetToDefaults = function() {
  const defaults = new this.constructor().config;
  this.config = defaults;
  this.lastModified = new Date();
  return this.save();
};

SystemConfigSchema.methods.validateConfig = function() {
  const errors = [];
  
  // Validate thread count against system capabilities
  if (this.config.defaultThreads > 256) {
    errors.push('Default threads cannot exceed 256');
  }
  
  // Validate intensity
  if (this.config.defaultIntensity < 0.1 || this.config.defaultIntensity > 1.0) {
    errors.push('Default intensity must be between 0.1 and 1.0');
  }
  
  // Validate thresholds
  if (this.config.maxCpuUsage > 100 || this.config.maxCpuUsage < 10) {
    errors.push('Max CPU usage must be between 10% and 100%');
  }
  
  return errors;
};

// Static methods
SystemConfigSchema.statics.getConfig = function(type, userId = 'default_user') {
  return this.findOne({ 
    configType: type, 
    userId: userId, 
    active: true 
  });
};

SystemConfigSchema.statics.setConfig = function(type, config, userId = 'default_user') {
  return this.findOneAndUpdate(
    { configType: type, userId: userId },
    { 
      config: config,
      lastModified: new Date(),
      active: true
    },
    { 
      upsert: true, 
      new: true,
      runValidators: true
    }
  );
};

SystemConfigSchema.statics.getUserPreferences = function(userId = 'default_user') {
  return this.findOne({
    configType: 'user_preferences',
    userId: userId,
    active: true
  });
};

SystemConfigSchema.statics.getMiningDefaults = function(userId = 'default_user') {
  return this.findOne({
    configType: 'mining_defaults',
    userId: userId,
    active: true
  });
};

SystemConfigSchema.statics.getActiveConfigs = function(userId = 'default_user') {
  return this.find({
    userId: userId,
    active: true
  }).sort({ configType: 1 });
};

module.exports = mongoose.model('SystemConfig', SystemConfigSchema);