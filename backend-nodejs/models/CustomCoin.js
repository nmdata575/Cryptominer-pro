/**
 * Custom Coin Model - MongoDB Schema
 * Stores user-defined cryptocurrency configurations
 */

const mongoose = require('mongoose');

const CustomCoinSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^[a-z0-9_-]+$/, 'Coin ID must contain only lowercase letters, numbers, underscores, and hyphens']
  },
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50
  },
  symbol: {
    type: String,
    required: true,
    uppercase: true,
    trim: true,
    maxlength: 10
  },
  algorithm: {
    type: String,
    required: true,
    enum: ['scrypt', 'scrypt-n', 'scrypt-jane'],
    default: 'scrypt'
  },
  block_time_target: {
    type: Number,
    required: true,
    min: 1,
    max: 3600, // Max 1 hour
    default: 150
  },
  block_reward: {
    type: Number,
    required: true,
    min: 0.000001,
    max: 1000000
  },
  network_difficulty: {
    type: Number,
    required: true,
    min: 1,
    default: 1000000
  },
  scrypt_params: {
    N: {
      type: Number,
      required: true,
      min: 1,
      max: 65536,
      default: 1024
    },
    r: {
      type: Number,
      required: true,
      min: 1,
      max: 32,
      default: 1
    },
    p: {
      type: Number,
      required: true,
      min: 1,
      max: 32,
      default: 1
    }
  },
  pool_settings: {
    default_pool_address: {
      type: String,
      trim: true,
      maxlength: 255
    },
    default_pool_port: {
      type: Number,
      min: 1,
      max: 65535
    },
    default_pool_username: {
      type: String,
      trim: true,
      maxlength: 100
    }
  },
  rpc_settings: {
    default_rpc_host: {
      type: String,
      trim: true,
      maxlength: 255,
      default: 'localhost'
    },
    default_rpc_port: {
      type: Number,
      min: 1,
      max: 65535,
      default: 8332
    },
    default_rpc_username: {
      type: String,
      trim: true,
      maxlength: 100
    },
    default_rpc_password: {
      type: String,
      trim: true,
      maxlength: 100
    }
  },
  address_formats: [{
    type: {
      type: String,
      enum: ['legacy', 'segwit', 'multisig', 'standard'],
      required: true
    },
    prefix: {
      type: String,
      required: true,
      trim: true,
      maxlength: 10
    },
    description: {
      type: String,
      trim: true,
      maxlength: 100
    }
  }],
  created_by: {
    type: String,
    default: 'user'
  },
  created_at: {
    type: Date,
    default: Date.now
  },
  updated_at: {
    type: Date,
    default: Date.now
  },
  is_active: {
    type: Boolean,
    default: true
  },
  metadata: {
    description: {
      type: String,
      trim: true,
      maxlength: 500
    },
    website: {
      type: String,
      trim: true,
      maxlength: 200
    },
    blockchain_explorer: {
      type: String,
      trim: true,
      maxlength: 200
    },
    github_repository: {
      type: String,
      trim: true,
      maxlength: 200
    },
    total_supply: {
      type: Number,
      min: 0
    },
    market_cap: {
      type: Number,
      min: 0
    }
  }
}, {
  timestamps: true
});

// Indexes for better query performance
CustomCoinSchema.index({ id: 1 });
CustomCoinSchema.index({ symbol: 1 });
CustomCoinSchema.index({ is_active: 1 });
CustomCoinSchema.index({ created_at: -1 });

// Pre-save middleware to update timestamps
CustomCoinSchema.pre('save', function(next) {
  this.updated_at = Date.now();
  next();
});

// Instance methods
CustomCoinSchema.methods.toJSON = function() {
  const coin = this.toObject();
  // Remove sensitive information
  if (coin.rpc_settings && coin.rpc_settings.default_rpc_password) {
    coin.rpc_settings.default_rpc_password = '***';
  }
  return coin;
};

CustomCoinSchema.methods.validateScryptParams = function() {
  const { N, r, p } = this.scrypt_params;
  
  // Validate N is a power of 2
  if ((N & (N - 1)) !== 0) {
    throw new Error('Scrypt parameter N must be a power of 2');
  }
  
  // Validate memory usage (N * r * p should be reasonable)
  const memoryUsage = N * r * p;
  if (memoryUsage > 1000000) {
    throw new Error('Scrypt parameters result in too high memory usage');
  }
  
  return true;
};

CustomCoinSchema.methods.toCoinPreset = function() {
  return {
    name: this.name,
    symbol: this.symbol,
    algorithm: this.algorithm,
    block_time_target: this.block_time_target,
    block_reward: this.block_reward,
    network_difficulty: this.network_difficulty,
    scrypt_params: this.scrypt_params,
    pool_settings: this.pool_settings,
    rpc_settings: this.rpc_settings,
    address_formats: this.address_formats,
    is_custom: true,
    custom_id: this.id
  };
};

// Static methods
CustomCoinSchema.statics.findBySymbol = function(symbol) {
  return this.findOne({ symbol: symbol.toUpperCase(), is_active: true });
};

CustomCoinSchema.statics.findActive = function() {
  return this.find({ is_active: true }).sort({ created_at: -1 });
};

CustomCoinSchema.statics.validateCoinData = function(coinData) {
  const errors = [];
  
  // Required fields validation
  if (!coinData.id || typeof coinData.id !== 'string') {
    errors.push('Coin ID is required and must be a string');
  }
  
  if (!coinData.name || typeof coinData.name !== 'string') {
    errors.push('Coin name is required and must be a string');
  }
  
  if (!coinData.symbol || typeof coinData.symbol !== 'string') {
    errors.push('Coin symbol is required and must be a string');
  }
  
  if (!coinData.block_reward || typeof coinData.block_reward !== 'number') {
    errors.push('Block reward is required and must be a number');
  }
  
  // Scrypt parameters validation
  if (coinData.scrypt_params) {
    const { N, r, p } = coinData.scrypt_params;
    
    if (!N || !Number.isInteger(N) || N <= 0) {
      errors.push('Scrypt parameter N must be a positive integer');
    }
    
    if (!r || !Number.isInteger(r) || r <= 0) {
      errors.push('Scrypt parameter r must be a positive integer');
    }
    
    if (!p || !Number.isInteger(p) || p <= 0) {
      errors.push('Scrypt parameter p must be a positive integer');
    }
    
    // Check if N is power of 2
    if (N && (N & (N - 1)) !== 0) {
      errors.push('Scrypt parameter N must be a power of 2');
    }
  }
  
  // Address formats validation
  if (coinData.address_formats && Array.isArray(coinData.address_formats)) {
    coinData.address_formats.forEach((format, index) => {
      if (!format.type || !format.prefix) {
        errors.push(`Address format ${index + 1} must have type and prefix`);
      }
    });
  }
  
  return errors;
};

module.exports = mongoose.model('CustomCoin', CustomCoinSchema);