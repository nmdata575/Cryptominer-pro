#!/usr/bin/env node

/**
 * Quick Thread Scaling Test for CryptoMiner Pro
 */

const http = require('http');

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
          resolve(response);
        } catch (error) {
          reject(error);
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    if (data && method !== 'GET') {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

async function testThreads(threads) {
  console.log(`\n🧪 Testing ${threads} threads...`);
  
  try {
    const config = {
      coin: 'litecoin',
      mode: 'solo',
      intensity: 0.8,
      threads: threads,
      wallet_address: 'LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4'
    };

    // Start mining
    const startResponse = await makeRequest('POST', `${API_BASE}/mining/start`, config);
    if (!startResponse.data.success) {
      throw new Error(`Start failed: ${startResponse.data.message}`);
    }

    console.log(`✅ Mining started with ${threads} threads`);

    // Wait for stabilization
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Get status
    const statusResponse = await makeRequest('GET', `${API_BASE}/mining/status`);
    const hashrate = statusResponse.data.stats?.hashrate || 0;
    
    console.log(`📊 Hashrate: ${hashrate.toFixed(2)} H/s`);

    // Stop mining
    await makeRequest('POST', `${API_BASE}/mining/stop`, {});
    console.log(`🛑 Stopped`);

    // Cleanup delay
    await new Promise(resolve => setTimeout(resolve, 2000));

    return { threads, hashrate, success: true };

  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
    
    // Ensure stopped
    try {
      await makeRequest('POST', `${API_BASE}/mining/stop`, {});
    } catch (e) {}

    return { threads, hashrate: 0, success: false, error: error.message };
  }
}

async function main() {
  console.log('🚀 Quick Thread Scaling Test');
  console.log('=' * 40);

  // Test fewer thread counts for speed
  const threadCounts = [1, 4, 8, 16, 32, 64];
  const results = [];

  for (const threads of threadCounts) {
    const result = await testThreads(threads);
    results.push(result);
  }

  console.log('\n📊 RESULTS SUMMARY:');
  console.log('Threads | Hashrate | Status');
  console.log('-' * 30);

  results.forEach(result => {
    const status = result.success ? '✅ OK' : '❌ FAIL';
    console.log(`${result.threads.toString().padStart(7)} | ${result.hashrate.toFixed(2).padStart(8)} | ${status}`);
  });

  const successful = results.filter(r => r.success);
  if (successful.length > 0) {
    const best = successful.reduce((best, current) => 
      current.hashrate > best.hashrate ? current : best
    );
    console.log(`\n🏆 Best Performance: ${best.threads} threads at ${best.hashrate.toFixed(2)} H/s`);
  }

  console.log('\n✅ Quick test completed!');
}

main().catch(console.error);