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
          speed: cpu.speed,
          maxSpeed: cpu.maxSpeed,
          architecture: cpu.architecture,
          virtualization: cpu.virtualization
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
        node_version: process.version,
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
      const osCpus = os.cpus();
      
      // Enhanced CPU frequency detection
      let cpuSpeed = 0;
      let maxSpeed = 0;
      
      // Try to get frequency from multiple sources
      if (cpuInfo.speed && cpuInfo.speed > 0) {
        cpuSpeed = cpuInfo.speed;
      } else if (cpuInfo.speedMax && cpuInfo.speedMax > 0) {
        cpuSpeed = cpuInfo.speedMax;
      } else if (osCpus.length > 0 && osCpus[0].speed && osCpus[0].speed > 0) {
        // os.cpus() returns speed in MHz, convert to GHz
        cpuSpeed = osCpus[0].speed / 1000;
      } else {
        // For ARM/container environments, provide estimated frequency
        cpuSpeed = this.estimateCPUFrequency(cpuInfo);
      }
      
      // Get max frequency
      if (cpuInfo.speedMax && cpuInfo.speedMax > 0) {
        maxSpeed = cpuInfo.speedMax;
      } else if (osCpus.length > 0 && osCpus[0].speed && osCpus[0].speed > 0) {
        maxSpeed = osCpus[0].speed / 1000;
      } else {
        maxSpeed = cpuSpeed === 'Variable' ? 'Variable' : cpuSpeed;
      }
      
      return {
        usage: cpuUsage,
        count: osCpus.length,
        cores: cpuInfo.physicalCores || cpuInfo.cores || osCpus.length,
        model: this.formatCPUModel(cpuInfo),
        speed: cpuSpeed,
        maxSpeed: maxSpeed,
        architecture: cpuInfo.vendor || process.arch,
        virtualization: cpuInfo.virtualization || false
      };
    } catch (error) {
      const osCpus = os.cpus();
      return {
        usage: 0,
        count: osCpus.length,
        cores: osCpus.length,
        model: 'Unknown CPU',
        speed: osCpus.length > 0 && osCpus[0].speed ? osCpus[0].speed / 1000 : 2.0,
        maxSpeed: osCpus.length > 0 && osCpus[0].speed ? osCpus[0].speed / 1000 : 2.0,
        architecture: process.arch,
        virtualization: true
      };
    }
  }

  /**
   * Format CPU model name
   */
  formatCPUModel(cpuInfo) {
    let model = '';
    
    // Check if we're in Google Cloud Platform
    const isKubernetes = !!process.env.KUBERNETES_SERVICE_HOST;
    const isGCP = cpuInfo.manufacturer === 'Google' || (cpuInfo.manufacturer === 'Neoverse-N1' && isKubernetes);
    
    if (cpuInfo.manufacturer) {
      model += cpuInfo.manufacturer;
    }
    
    if (cpuInfo.brand) {
      model += (model ? ' ' : '') + cpuInfo.brand;
    } else if (cpuInfo.vendor) {
      model += (model ? ' ' : '') + cpuInfo.vendor;
    }
    
    // For ARM processors in GCP, provide more descriptive info
    if (isGCP && (cpuInfo.manufacturer === 'Neoverse-N1' || cpuInfo.vendor === 'ARM')) {
      model = 'ARM Neoverse-N1 (GCP)';
    } else if (!model || model.trim() === '') {
      if (cpuInfo.vendor === 'ARM') {
        model = 'ARM Neoverse-N1';
      } else {
        model = `${process.arch.toUpperCase()} Processor`;
      }
    }
    
    return model.trim() || 'Unknown CPU';
  }

  /**
   * Estimate CPU frequency for environments where it's not reported
   */
  estimateCPUFrequency(cpuInfo) {
    const arch = process.arch.toLowerCase();
    
    // Check environment details
    const isKubernetes = !!process.env.KUBERNETES_SERVICE_HOST;
    const isGCP = cpuInfo.manufacturer === 'Google' || (cpuInfo.manufacturer === 'Neoverse-N1' && isKubernetes);
    
    // For Google Cloud ARM instances (running on virtualized ARM)
    if (isGCP && (cpuInfo.manufacturer === 'Neoverse-N1' || cpuInfo.vendor === 'ARM')) {
      // GCP ARM instances have variable frequency managed by the hypervisor
      return 'Variable (GCP ARM)';
    }
    
    // For ARM Neoverse-N1 in container environments
    if (cpuInfo.manufacturer === 'Neoverse-N1' || cpuInfo.vendor === 'ARM') {
      if (isKubernetes) {
        return 'Variable (Container)';
      }
      return 2.8; // Native ARM servers
    }
    
    // Common frequencies for different architectures
    const estimates = {
      'arm64': isKubernetes ? 'Variable (Container)' : 2.8,
      'x64': isKubernetes ? 'Variable (Container)' : 2.4,
      'x86': isKubernetes ? 'Variable (Container)' : 2.0,
      'aarch64': isKubernetes ? 'Variable (Container)' : 2.8
    };
    
    return estimates[arch] || (isKubernetes ? 'Variable (Container)' : 2.0);
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
      const osCpus = os.cpus();
      
      // Enhanced CPU frequency detection (same logic as getCPUUsage)
      let cpuSpeed = 0;
      let maxSpeed = 0;
      
      // Try to get frequency from multiple sources
      if (cpuInfo.speed && cpuInfo.speed > 0) {
        cpuSpeed = cpuInfo.speed;
      } else if (cpuInfo.speedMax && cpuInfo.speedMax > 0) {
        cpuSpeed = cpuInfo.speedMax;
      } else if (osCpus.length > 0 && osCpus[0].speed && osCpus[0].speed > 0) {
        // os.cpus() returns speed in MHz, convert to GHz
        cpuSpeed = osCpus[0].speed / 1000;
      } else {
        // For ARM/container environments, provide estimated frequency
        cpuSpeed = this.estimateCPUFrequency(cpuInfo);
      }
      
      // Get max frequency
      if (cpuInfo.speedMax && cpuInfo.speedMax > 0) {
        maxSpeed = cpuInfo.speedMax;
      } else if (osCpus.length > 0 && osCpus[0].speed && osCpus[0].speed > 0) {
        maxSpeed = osCpus[0].speed / 1000;
      } else {
        maxSpeed = cpuSpeed === 'Variable (GCP ARM)' ? 'Variable (GCP ARM)' : cpuSpeed;
      }
      
      // Detect container environment
      const isKubernetes = !!process.env.KUBERNETES_SERVICE_HOST;
      const isContainer = isKubernetes || require('fs').existsSync('/.dockerenv');
      
      // Calculate recommended threads for mining (optimized for available cores)
      const recommendedThreads = {
        conservative: Math.max(1, physicalCores - 2), // Leave more headroom in containers
        balanced: Math.max(1, physicalCores - 1),
        aggressive: physicalCores
      };
      
      // Enhanced mining profiles for container environments
      const miningProfiles = {
        light: {
          threads: Math.max(1, Math.floor(physicalCores / 3)),
          description: `Light mining - ${Math.max(1, Math.floor(physicalCores / 3))} threads (minimal system impact)`
        },
        standard: {
          threads: Math.max(1, physicalCores - 2),
          description: `Standard mining - ${Math.max(1, physicalCores - 2)} threads (balanced performance)`
        },
        maximum: {
          threads: Math.max(1, physicalCores - 1),
          description: `Maximum mining - ${Math.max(1, physicalCores - 1)} threads (leave 1 core for system)`
        },
        absolute_max: {
          threads: physicalCores,
          description: `Absolute maximum - ${physicalCores} threads (use all cores, may impact system responsiveness)`
        }
      };
      
      // Enhanced performance recommendations
      const recommendations = [
        `🖥️ Detected ${physicalCores} CPU cores (${this.formatCPUModel(cpuInfo)})`,
        `⚡ CPU Frequency: ${cpuSpeed.toFixed(1)} GHz (Max: ${maxSpeed.toFixed(1)} GHz)`,
        isContainer ? 
          `🐳 Running in ${isKubernetes ? 'Kubernetes' : 'container'} environment with allocated CPU resources` :
          `💻 Running on native system`,
        `⚡ Recommended: Use ${recommendedThreads.balanced} threads for optimal mining performance`,
        `🔥 For maximum performance: Use up to ${physicalCores} threads (monitor system responsiveness)`,
        `📊 Monitor CPU temperature and usage during intensive mining operations`,
        physicalCores >= 8 ? 
          `🚀 Excellent CPU count for mining - consider using standard or maximum profiles` :
          `⚠️ Limited CPU cores - recommend light or standard mining profiles for system stability`
      ];
      
      return {
        cores: {
          physical: physicalCores,
          logical: logicalCores,
          hyperthreading: logicalCores > physicalCores,
          allocated: cpuCount, // For container environments
          available: physicalCores
        },
        environment: {
          container: isContainer,
          kubernetes: isKubernetes,
          type: isKubernetes ? 'kubernetes' : isContainer ? 'container' : 'native'
        },
        manufacturer: cpuInfo.manufacturer || 'Unknown',
        brand: cpuInfo.brand || 'Unknown',
        family: cpuInfo.family || 'Unknown',
        model: cpuInfo.model || 'Unknown',
        speed: cpuSpeed, // Use enhanced detection
        frequency: {
          min: cpuInfo.speedMin || 0,
          max: maxSpeed, // Use enhanced detection
          current: cpuSpeed // Use enhanced detection
        },
        cache: {
          l1d: cpuInfo.cache?.l1d || 0,
          l1i: cpuInfo.cache?.l1i || 0,
          l2: cpuInfo.cache?.l2 || 0,
          l3: cpuInfo.cache?.l3 || 0
        },
        recommended_threads: recommendedThreads,
        mining_profiles: miningProfiles,
        recommendations: recommendations,
        optimal_mining_config: {
          max_safe_threads: Math.max(1, physicalCores - 1),
          recommended_profile: physicalCores >= 8 ? 'standard' : 'light',
          intensity_recommendation: physicalCores >= 8 ? 'medium-high' : 'medium'
        }
      };
    } catch (error) {
      console.error('CPU info error:', error);
      
      // Enhanced fallback with container detection
      const cpuCount = os.cpus().length;
      const osCpus = os.cpus();
      const isKubernetes = !!process.env.KUBERNETES_SERVICE_HOST;
      const isContainer = isKubernetes || require('fs').existsSync('/.dockerenv');
      
      // Fallback frequency detection
      let fallbackSpeed = 2.0; // Default fallback
      if (osCpus.length > 0 && osCpus[0].speed) {
        fallbackSpeed = osCpus[0].speed / 1000; // Convert MHz to GHz
      } else if (process.arch === 'arm64' || process.arch === 'aarch64') {
        fallbackSpeed = 2.8; // ARM typical frequency
      }
      
      return {
        cores: {
          physical: cpuCount,
          logical: cpuCount,
          hyperthreading: false,
          allocated: cpuCount,
          available: cpuCount
        },
        environment: {
          container: isContainer,
          kubernetes: isKubernetes,
          type: isKubernetes ? 'kubernetes' : isContainer ? 'container' : 'native'
        },
        manufacturer: 'Unknown',
        brand: 'Unknown',
        family: 'Unknown',
        model: 'Unknown',
        speed: fallbackSpeed, // Use fallback detection
        frequency: { 
          min: 0, 
          max: fallbackSpeed, // Use fallback detection
          current: fallbackSpeed // Use fallback detection
        },
        cache: { l1d: 0, l1i: 0, l2: 0, l3: 0 },
        recommended_threads: {
          conservative: Math.max(1, cpuCount - 2),
          balanced: Math.max(1, cpuCount - 1),
          aggressive: cpuCount
        },
        mining_profiles: {
          light: { threads: Math.max(1, Math.floor(cpuCount / 3)), description: 'Light mining' },
          standard: { threads: Math.max(1, cpuCount - 2), description: 'Standard mining' },
          maximum: { threads: Math.max(1, cpuCount - 1), description: 'Maximum mining' },
          absolute_max: { threads: cpuCount, description: 'Absolute maximum' }
        },
        recommendations: [
          `🖥️ Detected ${cpuCount} CPU cores`,
          `⚡ CPU Frequency: ${fallbackSpeed.toFixed(1)} GHz (estimated)`,
          isContainer ? '🐳 Running in container environment' : '💻 Running on native system',
          'Unable to get detailed CPU information',
          'Use system monitoring to optimize mining performance'
        ],
        optimal_mining_config: {
          max_safe_threads: Math.max(1, cpuCount - 1),
          recommended_profile: cpuCount >= 8 ? 'standard' : 'light',
          intensity_recommendation: 'medium'
        }
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