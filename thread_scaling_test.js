#!/usr/bin/env node

/**
 * CryptoMiner Pro - Thread Scaling Validation Test
 * Tests mining performance at different thread counts (up to 256)
 */

const http = require('http');
const querystring = require('querystring');

const API_BASE = 'http://localhost:8001/api';

function makeRequest(method, url, data = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || 80,
      path: urlObj.pathname,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    if (data && method !== 'GET') {
      const postData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(postData);
    }

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const response = {
            status: res.statusCode,
            data: JSON.parse(body)
          };
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(response);
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${body}`));
          }
        } catch (error) {
          reject(error);
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(15000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    if (data && method !== 'GET') {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

class ThreadScalingTester {
  constructor() {
    this.results = [];
    this.testConfig = {
      coin: 'litecoin',
      mode: 'solo',
      intensity: 0.8,
      wallet_address: 'LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4'
    };
  }

  async testThreadCount(threads) {
    console.log(`\n🧪 Testing ${threads} threads...`);
    
    try {
      const config = {
        ...this.testConfig,
        threads: threads
      };

      // Start mining
      const startResponse = await makeRequest('POST', `${API_BASE}/mining/start`, config);

      if (!startResponse.data.success) {
        throw new Error(`Failed to start mining: ${startResponse.data.message || 'Unknown error'}`);
      }

      console.log(`✅ Mining started with ${threads} threads`);

      // Wait for mining to stabilize
      await this.delay(8000);

      // Get mining status
      const statusResponse = await axios.get(`${API_BASE}/mining/status`, {
        timeout: 10000
      });

      const miningData = statusResponse.data;
      
      if (!miningData.is_mining) {
        throw new Error('Mining not active after start');
      }

      const hashrate = miningData.stats?.hashrate || 0;
      const cpuUsage = miningData.stats?.cpu_usage || 0;
      const memoryUsage = miningData.stats?.memory_usage || 0;

      console.log(`📊 Results: ${hashrate.toFixed(2)} H/s, CPU: ${cpuUsage.toFixed(1)}%, Memory: ${memoryUsage.toFixed(1)}%`);

      // Stop mining
      await axios.post(`${API_BASE}/mining/stop`, {}, { timeout: 10000 });
      console.log(`🛑 Mining stopped`);

      // Wait for cleanup
      await this.delay(3000);

      const result = {
        threads,
        hashrate,
        cpuUsage,
        memoryUsage,
        efficiency: hashrate / threads,
        success: true,
        timestamp: new Date().toISOString()
      };

      this.results.push(result);
      return result;

    } catch (error) {
      console.error(`❌ Error testing ${threads} threads:`, error.message);
      
      // Ensure mining is stopped
      try {
        await axios.post(`${API_BASE}/mining/stop`, {}, { timeout: 5000 });
      } catch (stopError) {
        // Ignore stop errors
      }

      const result = {
        threads,
        hashrate: 0,
        cpuUsage: 0,
        memoryUsage: 0,
        efficiency: 0,
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };

      this.results.push(result);
      return result;
    }
  }

  async testSystemLimits() {
    console.log(`\n🔧 Testing system limits...`);
    
    try {
      const systemResponse = await axios.get(`${API_BASE}/system/cpu-info`, {
        timeout: 10000
      });

      const systemData = systemResponse.data;
      console.log(`💻 System Info: ${systemData.cores} cores, ${systemData.mining_profiles?.length || 0} profiles`);
      
      if (systemData.mining_profiles) {
        for (const profile of systemData.mining_profiles) {
          console.log(`   ${profile.name}: ${profile.threads} threads (${profile.description})`);
        }
      }

      return systemData;
    } catch (error) {
      console.error(`❌ Error getting system info:`, error.message);
      return null;
    }
  }

  async runScalingTests() {
    console.log('🚀 CryptoMiner Pro - Thread Scaling Validation Test');
    console.log('=' * 60);

    // Test system limits first
    const systemInfo = await this.testSystemLimits();

    // Define thread counts to test
    const threadCounts = [1, 2, 4, 8, 16, 32, 64, 128, 256];
    
    console.log(`\n📋 Testing thread counts: ${threadCounts.join(', ')}`);
    console.log(`⏰ Each test runs for ~8 seconds with 3s cleanup`);

    // Run tests for each thread count
    for (const threads of threadCounts) {
      await this.testThreadCount(threads);
      
      // Short break between tests
      if (threads < threadCounts[threadCounts.length - 1]) {
        await this.delay(2000);
      }
    }

    // Analyze results
    this.analyzeResults();
  }

  analyzeResults() {
    console.log('\n📊 THREAD SCALING ANALYSIS');
    console.log('=' * 60);

    const successfulTests = this.results.filter(r => r.success);
    const failedTests = this.results.filter(r => !r.success);

    console.log(`✅ Successful tests: ${successfulTests.length}/${this.results.length}`);
    
    if (failedTests.length > 0) {
      console.log(`❌ Failed tests: ${failedTests.length}`);
      failedTests.forEach(test => {
        console.log(`   ${test.threads} threads: ${test.error}`);
      });
    }

    if (successfulTests.length > 0) {
      console.log('\n📈 Performance Results:');
      console.log('Threads | Hashrate (H/s) | Efficiency | CPU% | Memory%');
      console.log('-' * 58);

      successfulTests.forEach(result => {
        const hashrate = result.hashrate.toFixed(2).padStart(10);
        const efficiency = result.efficiency.toFixed(3).padStart(8);
        const cpu = result.cpuUsage.toFixed(1).padStart(4);
        const memory = result.memoryUsage.toFixed(1).padStart(6);
        
        console.log(`${result.threads.toString().padStart(7)} | ${hashrate}   | ${efficiency}  | ${cpu}  | ${memory}`);
      });

      // Find optimal configuration
      const bestEfficiency = successfulTests.reduce((best, current) => 
        current.efficiency > best.efficiency ? current : best
      );

      const bestHashrate = successfulTests.reduce((best, current) => 
        current.hashrate > best.hashrate ? current : best
      );

      console.log('\n🏆 OPTIMAL CONFIGURATIONS:');
      console.log(`📈 Best Efficiency: ${bestEfficiency.threads} threads (${bestEfficiency.efficiency.toFixed(3)} H/s per thread)`);
      console.log(`🚀 Best Hashrate: ${bestHashrate.threads} threads (${bestHashrate.hashrate.toFixed(2)} H/s total)`);

      // Performance scaling analysis
      if (successfulTests.length >= 2) {
        const baseResult = successfulTests[0];
        console.log('\n📊 SCALING ANALYSIS:');
        successfulTests.slice(1).forEach(result => {
          const scalingFactor = result.threads / baseResult.threads;
          const hashrateIncrease = result.hashrate / baseResult.hashrate;
          const efficiency = (hashrateIncrease / scalingFactor) * 100;
          
          console.log(`${result.threads} threads: ${efficiency.toFixed(1)}% scaling efficiency`);
        });
      }
    }

    // Save results to file
    this.saveResults();
  }

  saveResults() {
    const fs = require('fs');
    const resultsData = {
      testDate: new Date().toISOString(),
      totalTests: this.results.length,
      successfulTests: this.results.filter(r => r.success).length,
      results: this.results
    };

    fs.writeFileSync('/tmp/thread_scaling_results.json', JSON.stringify(resultsData, null, 2));
    console.log('\n💾 Results saved to /tmp/thread_scaling_results.json');
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Run the test
async function main() {
  const tester = new ThreadScalingTester();
  
  try {
    await tester.runScalingTests();
    console.log('\n✅ Thread scaling test completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Thread scaling test failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = ThreadScalingTester;