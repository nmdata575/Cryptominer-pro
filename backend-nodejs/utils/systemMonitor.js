/**
 * System Monitor - Node.js Implementation
 * Replaces Python psutil functionality
 */

const si = require('systeminformation');
const os = require('os');
const osUtils = require('node-os-utils');

class SystemMonitor {
  constructor() {
    this.cpuUsage = osUtils.cpu;
    this.memoryUsage = osUtils.mem;
    this.driveUsage = osUtils.drive;
  }

  /**
   * Get comprehensive system statistics
   */
  async getSystemStats() {
    try {
      const [cpu, memory, disk] = await Promise.all([
        this.getCPUUsage(),
        this.getMemoryUsage(),
        this.getDiskUsage()
      ]);

      return {
        cpu: {
          usage_percent: cpu.usage,
          count: cpu.count,
          cores: cpu.cores,
          model: cpu.model,
          speed: cpu.speed
        },
        memory: {
          total: memory.total,
          available: memory.available,
          used: memory.used,
          percent: memory.percent,
          free: memory.free
        },
        disk: {
          total: disk.total,
          used: disk.used,
          free: disk.free,
          percent: disk.percent
        },
        uptime: os.uptime(),
        platform: os.platform(),
        hostname: os.hostname(),
        loadavg: os.loadavg()
      };
    } catch (error) {
      console.error('System stats error:', error);
      return {
        cpu: { usage_percent: 0, count: 0 },
        memory: { total: 0, available: 0, percent: 0, used: 0 },
        disk: { total: 0, used: 0, free: 0, percent: 0 },
        error: error.message
      };
    }
  }

  /**
   * Get CPU usage information
   */
  async getCPUUsage() {
    try {
      const cpuInfo = await si.cpu();
      const cpuUsage = await this.cpuUsage.usage();
      
      return {
        usage: cpuUsage,
        count: os.cpus().length,
        cores: cpuInfo.cores,
        model: cpuInfo.manufacturer + ' ' + cpuInfo.brand,
        speed: cpuInfo.speed
      };
    } catch (error) {
      return {
        usage: 0,
        count: os.cpus().length,
        cores: os.cpus().length,
        model: 'Unknown',
        speed: 0
      };
    }
  }

  /**
   * Get memory usage information
   */
  async getMemoryUsage() {
    try {
      const memInfo = await si.mem();
      
      return {
        total: memInfo.total,
        available: memInfo.available,
        used: memInfo.used,
        free: memInfo.free,
        percent: Math.round((memInfo.used / memInfo.total) * 100)
      };
    } catch (error) {
      const totalmem = os.totalmem();
      const freemem = os.freemem();
      const usedmem = totalmem - freemem;
      
      return {
        total: totalmem,
        available: freemem,
        used: usedmem,
        free: freemem,
        percent: Math.round((usedmem / totalmem) * 100)
      };
    }
  }

  /**
   * Get disk usage information
   */
  async getDiskUsage() {
    try {
      const diskInfo = await si.fsSize();
      
      if (diskInfo && diskInfo.length > 0) {
        const rootDisk = diskInfo[0];
        return {
          total: rootDisk.size,
          used: rootDisk.used,
          free: rootDisk.available,
          percent: Math.round((rootDisk.used / rootDisk.size) * 100)
        };
      }
      
      return {
        total: 0,
        used: 0,
        free: 0,
        percent: 0
      };
    } catch (error) {
      return {
        total: 0,
        used: 0,
        free: 0,
        percent: 0
      };
    }
  }

  /**
   * Get detailed CPU information for mining optimization
   */
  async getCPUInfo() {
    try {
      const cpuInfo = await si.cpu();
      const cpuCount = os.cpus().length;
      const physicalCores = cpuInfo.physicalCores || cpuCount;
      const logicalCores = cpuCount;
      
      // Calculate recommended threads for mining
      const recommendedThreads = {
        conservative: Math.max(1, physicalCores - 1),
        balanced: physicalCores,
        aggressive: logicalCores
      };
      
      // Mining profiles
      const miningProfiles = {
        light: {
          threads: Math.max(1, Math.floor(physicalCores / 2)),
          description: 'Light mining - minimal system impact'
        },
        standard: {
          threads: Math.max(1, physicalCores - 1),
          description: 'Standard mining - balanced performance'
        },
        maximum: {
          threads: physicalCores,
          description: 'Maximum mining - uses all physical cores'
        }
      };
      
      // Performance recommendations
      const recommendations = [
        `Detected ${physicalCores} physical cores and ${logicalCores} logical cores`,
        `Recommended: Use ${recommendedThreads.balanced} threads for optimal performance`,
        `Monitor CPU temperature during intensive mining`,
        `Consider using ${recommendedThreads.conservative} threads to maintain system responsiveness`
      ];
      
      return {
        cores: {
          physical: physicalCores,
          logical: logicalCores,
          hyperthreading: logicalCores > physicalCores
        },
        manufacturer: cpuInfo.manufacturer,
        brand: cpuInfo.brand,
        family: cpuInfo.family,
        model: cpuInfo.model,
        speed: cpuInfo.speed,
        frequency: {
          min: cpuInfo.speedMin,
          max: cpuInfo.speedMax,
          current: cpuInfo.speed
        },
        cache: {
          l1d: cpuInfo.cache?.l1d || 0,
          l1i: cpuInfo.cache?.l1i || 0,
          l2: cpuInfo.cache?.l2 || 0,
          l3: cpuInfo.cache?.l3 || 0
        },
        recommended_threads: recommendedThreads,
        mining_profiles: miningProfiles,
        recommendations: recommendations
      };
    } catch (error) {
      console.error('CPU info error:', error);
      
      // Fallback to basic OS info
      const cpuCount = os.cpus().length;
      return {
        cores: {
          physical: cpuCount,
          logical: cpuCount,
          hyperthreading: false
        },
        manufacturer: 'Unknown',
        brand: 'Unknown',
        family: 'Unknown',
        model: 'Unknown',
        speed: 0,
        frequency: { min: 0, max: 0, current: 0 },
        cache: { l1d: 0, l1i: 0, l2: 0, l3: 0 },
        recommended_threads: {
          conservative: Math.max(1, cpuCount - 1),
          balanced: cpuCount,
          aggressive: cpuCount
        },
        mining_profiles: {
          light: { threads: Math.max(1, Math.floor(cpuCount / 2)), description: 'Light mining' },
          standard: { threads: Math.max(1, cpuCount - 1), description: 'Standard mining' },
          maximum: { threads: cpuCount, description: 'Maximum mining' }
        },
        recommendations: [
          `Detected ${cpuCount} CPU cores`,
          'Unable to get detailed CPU information',
          'Use system monitoring to optimize performance'
        ]
      };
    }
  }

  /**
   * Get system temperature (if available)
   */
  async getTemperature() {
    try {
      const temp = await si.cpuTemperature();
      return {
        cpu: temp.main || 0,
        cores: temp.cores || []
      };
    } catch (error) {
      return {
        cpu: 0,
        cores: []
      };
    }
  }

  /**
   * Get network information
   */
  async getNetworkInfo() {
    try {
      const networkStats = await si.networkStats();
      return networkStats.map(stat => ({
        interface: stat.iface,
        rx_bytes: stat.rx_bytes,
        tx_bytes: stat.tx_bytes,
        rx_dropped: stat.rx_dropped,
        tx_dropped: stat.tx_dropped,
        rx_errors: stat.rx_errors,
        tx_errors: stat.tx_errors
      }));
    } catch (error) {
      return [];
    }
  }

  /**
   * Get process information
   */
  async getProcessInfo() {
    try {
      const processes = await si.processes();
      return {
        running: processes.running,
        sleeping: processes.sleeping,
        blocked: processes.blocked,
        zombie: processes.zombie,
        list: processes.list.slice(0, 10) // Top 10 processes
      };
    } catch (error) {
      return {
        running: 0,
        sleeping: 0,
        blocked: 0,
        zombie: 0,
        list: []
      };
    }
  }
}

module.exports = new SystemMonitor();