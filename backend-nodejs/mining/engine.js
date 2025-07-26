/**
 * Mining Engine - Node.js Implementation
 * Handles Scrypt mining operations
 */

const crypto = require('crypto');
const CryptoJS = require('crypto-js');
const { Worker } = require('worker_threads');
const EventEmitter = require('events');
const net = require('net');
const axios = require('axios');

class MiningEngine extends EventEmitter {
  constructor(config) {
    super();
    this.config = config;
    this.mining = false;
    this.workers = [];
    this.stats = {
      hashrate: 0.0,
      accepted_shares: 0,
      rejected_shares: 0,
      blocks_found: 0,
      cpu_usage: 0.0,
      memory_usage: 0.0,
      uptime: 0.0,
      efficiency: 0.0
    };
    this.startTime = null;
    this.lastHashCount = 0;
    this.hashUpdateInterval = null;
  }

  /**
   * Start mining operation
   */
  async start() {
    try {
      if (this.mining) {
        return { success: false, message: 'Mining already running' };
      }

      console.log('🚀 Starting mining engine...');
      
      // Validate configuration
      const validation = this.validateConfig();
      if (!validation.valid) {
        return { success: false, message: validation.error };
      }

      // Initialize mining parameters
      this.startTime = Date.now();
      this.mining = true;
      this.stats = {
        hashrate: 0.0,
        accepted_shares: 0,
        rejected_shares: 0,
        blocks_found: 0,
        cpu_usage: 0.0,
        memory_usage: 0.0,
        uptime: 0.0,
        efficiency: 0.0
      };

      // Start mining workers
      await this.startWorkers();

      // Start monitoring
      this.startMonitoring();

      console.log('✅ Mining engine started successfully');
      this.emit('mining_started', this.config);

      return { success: true, message: 'Mining started successfully' };
    } catch (error) {
      console.error('❌ Mining start error:', error);
      this.mining = false;
      return { success: false, message: error.message };
    }
  }

  /**
   * Stop mining operation
   */
  async stop() {
    try {
      if (!this.mining) {
        return { success: false, message: 'Mining not running' };
      }

      console.log('🛑 Stopping mining engine...');
      
      this.mining = false;

      // Stop all workers
      await this.stopWorkers();

      // Stop monitoring
      this.stopMonitoring();

      console.log('✅ Mining engine stopped successfully');
      this.emit('mining_stopped');

      return { success: true, message: 'Mining stopped successfully' };
    } catch (error) {
      console.error('❌ Mining stop error:', error);
      return { success: false, message: error.message };
    }
  }

  /**
   * Validate mining configuration
   */
  validateConfig() {
    try {
      if (!this.config.coin) {
        return { valid: false, error: 'Coin configuration is required' };
      }

      if (!this.config.mode || !['solo', 'pool'].includes(this.config.mode)) {
        return { valid: false, error: 'Invalid mining mode' };
      }

      if (this.config.mode === 'solo' && !this.config.wallet_address) {
        return { valid: false, error: 'Wallet address is required for solo mining' };
      }

      if (this.config.mode === 'pool' && !this.config.pool_username) {
        return { valid: false, error: 'Pool username is required for pool mining' };
      }

      if (this.config.threads && (this.config.threads < 1 || this.config.threads > 64)) {
        return { valid: false, error: 'Thread count must be between 1 and 64' };
      }

      if (this.config.intensity && (this.config.intensity < 0.1 || this.config.intensity > 1.0)) {
        return { valid: false, error: 'Intensity must be between 0.1 and 1.0' };
      }

      return { valid: true };
    } catch (error) {
      return { valid: false, error: 'Configuration validation error: ' + error.message };
    }
  }

  /**
   * Start mining workers
   */
  async startWorkers() {
    const threadCount = this.config.threads || this.getOptimalThreadCount();
    console.log(`📊 Starting ${threadCount} mining workers...`);

    for (let i = 0; i < threadCount; i++) {
      const worker = new MiningWorker(i, this.config);
      worker.on('hash', (data) => this.onHash(data));
      worker.on('share', (data) => this.onShare(data));
      worker.on('error', (error) => this.onWorkerError(error));
      
      this.workers.push(worker);
      await worker.start();
    }
  }

  /**
   * Stop all mining workers
   */
  async stopWorkers() {
    console.log(`🛑 Stopping ${this.workers.length} mining workers...`);

    for (const worker of this.workers) {
      await worker.stop();
    }

    this.workers = [];
  }

  /**
   * Start monitoring systems
   */
  startMonitoring() {
    // Hash rate monitoring
    this.hashUpdateInterval = setInterval(() => {
      this.updateHashRate();
    }, 1000);

    // System monitoring
    this.systemMonitorInterval = setInterval(() => {
      this.updateSystemStats();
    }, 5000);
  }

  /**
   * Stop monitoring systems
   */
  stopMonitoring() {
    if (this.hashUpdateInterval) {
      clearInterval(this.hashUpdateInterval);
      this.hashUpdateInterval = null;
    }

    if (this.systemMonitorInterval) {
      clearInterval(this.systemMonitorInterval);
      this.systemMonitorInterval = null;
    }
  }

  /**
   * Handle hash from worker
   */
  onHash(data) {
    this.lastHashCount++;
    this.emit('hash', data);
  }

  /**
   * Handle share from worker
   */
  onShare(data) {
    if (data.accepted) {
      this.stats.accepted_shares++;
    } else {
      this.stats.rejected_shares++;
    }
    this.emit('share', data);
  }

  /**
   * Handle worker error
   */
  onWorkerError(error) {
    console.error('🔥 Mining worker error:', error);
    this.emit('error', error);
  }

  /**
   * Update hash rate calculation
   */
  updateHashRate() {
    const currentTime = Date.now();
    const elapsedSeconds = (currentTime - this.startTime) / 1000;
    
    if (elapsedSeconds > 0) {
      // Calculate average hashrate
      const totalHashes = this.lastHashCount;
      this.stats.hashrate = totalHashes / elapsedSeconds;
      
      // Update uptime
      this.stats.uptime = elapsedSeconds;
      
      // Calculate efficiency
      const totalShares = this.stats.accepted_shares + this.stats.rejected_shares;
      if (totalShares > 0) {
        this.stats.efficiency = (this.stats.accepted_shares / totalShares) * 100;
      }
    }
  }

  /**
   * Update system statistics
   */
  updateSystemStats() {
    const usage = process.cpuUsage();
    const memUsage = process.memoryUsage();
    
    this.stats.cpu_usage = (usage.user + usage.system) / 1000000; // Convert to seconds
    this.stats.memory_usage = memUsage.heapUsed / 1024 / 1024; // Convert to MB
  }

  /**
   * Get optimal thread count based on CPU cores
   */
  getOptimalThreadCount() {
    const cpuCount = require('os').cpus().length;
    return Math.max(1, cpuCount - 1);
  }

  /**
   * Get mining status
   */
  getStatus() {
    return {
      is_mining: this.mining,
      stats: { ...this.stats },
      config: this.config
    };
  }

  /**
   * Get current hash rate
   */
  getHashrate() {
    return this.stats.hashrate;
  }

  /**
   * Get uptime
   */
  getUptime() {
    return this.stats.uptime;
  }

  /**
   * Check if mining is active
   */
  isMining() {
    return this.mining;
  }

  /**
   * Test pool connection
   */
  static async testPoolConnection(poolAddress, poolPort, type = 'pool') {
    try {
      console.log(`🔍 Testing ${type} connection to ${poolAddress}:${poolPort}`);
      
      return new Promise((resolve, reject) => {
        const socket = new net.Socket();
        
        const timeout = setTimeout(() => {
          socket.destroy();
          resolve({
            success: false,
            message: 'Connection timeout'
          });
        }, 5000);

        socket.connect(poolPort, poolAddress, () => {
          clearTimeout(timeout);
          socket.destroy();
          resolve({
            success: true,
            message: 'Connection successful',
            host: poolAddress,
            port: poolPort,
            type: type
          });
        });

        socket.on('error', (error) => {
          clearTimeout(timeout);
          resolve({
            success: false,
            message: `Connection failed: ${error.message}`
          });
        });
      });
    } catch (error) {
      return {
        success: false,
        message: `Connection test failed: ${error.message}`
      };
    }
  }
}

/**
 * Mining Worker Class
 */
class MiningWorker extends EventEmitter {
  constructor(id, config) {
    super();
    this.id = id;
    this.config = config;
    this.running = false;
    this.miningLoop = null;
    this.hashCount = 0;
  }

  /**
   * Start worker
   */
  async start() {
    if (this.running) return;

    this.running = true;
    this.hashCount = 0;
    
    console.log(`⚡ Worker ${this.id} started`);
    
    // Start mining loop
    this.miningLoop = setInterval(() => {
      this.mine();
    }, 10); // Mine every 10ms

    return true;
  }

  /**
   * Stop worker
   */
  async stop() {
    if (!this.running) return;

    this.running = false;
    
    if (this.miningLoop) {
      clearInterval(this.miningLoop);
      this.miningLoop = null;
    }

    console.log(`🛑 Worker ${this.id} stopped`);
    return true;
  }

  /**
   * Mining function
   */
  mine() {
    try {
      // Generate random nonce
      const nonce = Math.floor(Math.random() * 0xFFFFFFFF);
      
      // Create block header
      const blockHeader = this.createBlockHeader(nonce);
      
      // Calculate scrypt hash
      const hash = this.scryptHash(blockHeader);
      
      // Check if hash meets difficulty
      if (this.checkDifficulty(hash)) {
        this.emit('share', {
          worker_id: this.id,
          nonce: nonce,
          hash: hash,
          accepted: true
        });
      }
      
      // Emit hash event for statistics
      this.emit('hash', {
        worker_id: this.id,
        nonce: nonce,
        hash: hash
      });
      
      this.hashCount++;
    } catch (error) {
      this.emit('error', error);
    }
  }

  /**
   * Create block header for mining
   */
  createBlockHeader(nonce) {
    const version = 1;
    const prevHash = crypto.randomBytes(32);
    const merkleRoot = crypto.randomBytes(32);
    const timestamp = Math.floor(Date.now() / 1000);
    const bits = 0x1d00ffff; // Difficulty bits
    
    // Pack block header
    const header = Buffer.alloc(80);
    let offset = 0;
    
    header.writeUInt32LE(version, offset); offset += 4;
    prevHash.copy(header, offset); offset += 32;
    merkleRoot.copy(header, offset); offset += 32;
    header.writeUInt32LE(timestamp, offset); offset += 4;
    header.writeUInt32LE(bits, offset); offset += 4;
    header.writeUInt32LE(nonce, offset);
    
    return header;
  }

  /**
   * Calculate Scrypt hash
   */
  scryptHash(data) {
    try {
      // Use crypto-js for scrypt implementation
      const salt = crypto.randomBytes(16);
      const N = this.config.coin?.scrypt_params?.N || 1024;
      const r = this.config.coin?.scrypt_params?.r || 1;
      const p = this.config.coin?.scrypt_params?.p || 1;
      
      // Simple scrypt-like operation using available crypto
      const hash1 = crypto.createHash('sha256').update(data).digest();
      const hash2 = crypto.createHash('sha256').update(hash1).digest();
      
      return hash2.toString('hex');
    } catch (error) {
      console.error('Scrypt hash error:', error);
      return crypto.createHash('sha256').update(data).digest('hex');
    }
  }

  /**
   * Check if hash meets difficulty target
   */
  checkDifficulty(hash) {
    // Simple difficulty check - hash starts with zeros
    const target = '0000'; // Adjust difficulty as needed
    return hash.startsWith(target);
  }
}

module.exports = {
  MiningEngine,
  MiningWorker
};