import React, { useState, useEffect, useCallback } from 'react';
import io from 'socket.io-client';
import './App.css';

// Import components
import MiningDashboard from './components/MiningDashboard';
import CoinSelector from './components/CoinSelector';
import WalletConfig from './components/WalletConfig';
import MiningControls from './components/MiningControls';
import SystemMonitoring from './components/SystemMonitoring';
import AIInsights from './components/AIInsights';
import RealtimeMetrics from './components/RealtimeMetrics';
import MiningPerformance from './components/MiningPerformance';

function App() {
  // State management
  const [selectedCoin, setSelectedCoin] = useState(null);
  const [coinPresets, setCoinPresets] = useState([]);
  const [miningStatus, setMiningStatus] = useState({
    is_mining: false,
    stats: {
      hashrate: 0,
      accepted_shares: 0,
      rejected_shares: 0,
      blocks_found: 0,
      cpu_usage: 0,
      memory_usage: 0,
      uptime: 0,
      efficiency: 0
    },
    high_performance: false,
    processes: 0,
    expected_hashrate: 0
  });
  const [miningConfig, setMiningConfig] = useState({
    coin: null,
    mode: 'pool',
    threads: 4,
    intensity: 0.8,
    auto_optimize: false,
    ai_enabled: false,
    wallet_address: '',
    pool_username: '',
    pool_password: 'x',
    custom_pool_address: '',
    custom_pool_port: '',
    custom_rpc_host: '',
    custom_rpc_port: '',
    custom_rpc_username: '',
    custom_rpc_password: '',
    auto_thread_detection: true,
    thread_profile: 'standard',
    real_mining: true
  });
  const [systemStats, setSystemStats] = useState(null);
  const [cpuInfo, setCpuInfo] = useState(null);
  const [socket, setSocket] = useState(null);
  const [connectionStatus, setConnectionStatus] = useState('Connecting...');
  const [aiInsights, setAiInsights] = useState(null);
  
  // High-performance mode state
  const [highPerformanceMode, setHighPerformanceMode] = useState(false);

  // Get backend URL from environment
  const backendUrl = process.env.REACT_APP_BACKEND_URL || 'http://localhost:8001';

  // API functions with useCallback to prevent infinite re-renders
  const fetchMiningStatus = useCallback(async () => {
    try {
      const response = await fetch(`${backendUrl}/api/mining/status`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      setMiningStatus(data);
    } catch (error) {
      console.error('Failed to fetch mining status:', error);
    }
  }, [backendUrl]);

  const fetchCoinPresets = useCallback(async () => {
    try {
      const response = await fetch(`${backendUrl}/api/coins/presets`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      setCoinPresets(data);
      // Set default coin if none selected
      if (!selectedCoin && data.length > 0) {
        setSelectedCoin(data[0]);
        setMiningConfig(prev => ({ ...prev, coin: data[0] }));
      }
    } catch (error) {
      console.error('Failed to fetch coin presets:', error);
    }
  }, [backendUrl, selectedCoin]);

  const fetchSystemStats = useCallback(async () => {
    try {
      const response = await fetch(`${backendUrl}/api/system/stats`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      setSystemStats(data);
    } catch (error) {
      console.error('Failed to fetch system stats:', error);
    }
  }, [backendUrl]);

  const fetchCpuInfo = useCallback(async () => {
    try {
      const response = await fetch(`${backendUrl}/api/system/cpu-info`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      setCpuInfo(data);
    } catch (error) {
      console.error('Failed to fetch CPU info:', error);
    }
  }, [backendUrl]);

  const fetchAiInsights = useCallback(async () => {
    try {
      const response = await fetch(`${backendUrl}/api/mining/ai-insights`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      setAiInsights(data);
    } catch (error) {
      console.error('Failed to fetch AI insights:', error);
    }
  }, [backendUrl]);

  // High-performance mining functions
  const startHighPerformanceMining = async (config) => {
    try {
      const response = await fetch(`${backendUrl}/api/mining/start-hp`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          threads: config.threads || 32,
          intensity: config.intensity || 1.0
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result = await response.json();
      
      if (result.success) {
        setMiningStatus(prev => ({
          ...prev,
          is_mining: true,
          high_performance: true,
          processes: result.processes,
          expected_hashrate: result.expected_hashrate
        }));
        
        console.log('🚀 High-performance mining started:', result.message);
        return { success: true, message: result.message };
      } else {
        throw new Error(result.message || 'Failed to start high-performance mining');
      }
    } catch (error) {
      console.error('High-performance mining start error:', error);
      return { success: false, message: error.message };
    }
  };

  const stopHighPerformanceMining = async () => {
    try {
      const response = await fetch(`${backendUrl}/api/mining/stop-hp`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result = await response.json();
      
      if (result.success) {
        setMiningStatus(prev => ({
          ...prev,
          is_mining: false,
          high_performance: false,
          processes: 0,
          expected_hashrate: 0
        }));
        
        console.log('🛑 High-performance mining stopped');
        return { success: true, message: result.message };
      } else {
        throw new Error(result.message || 'Failed to stop high-performance mining');
      }
    } catch (error) {
      console.error('High-performance mining stop error:', error);
      return { success: false, message: error.message };
    }
  };

  // Regular mining functions
  const startMining = async () => {
    try {
      if (highPerformanceMode) {
        // Use high-performance mining
        const result = await startHighPerformanceMining(miningConfig);
        return result;
      } else {
        // Use regular mining
        const response = await fetch(`${backendUrl}/api/mining/start`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(miningConfig),
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result = await response.json();
        
        if (result.success) {
          setMiningStatus(prev => ({ ...prev, is_mining: true }));
          fetchMiningStatus(); // Update status immediately
        }
        
        return result;
      }
    } catch (error) {
      console.error('Mining start error:', error);
      return { success: false, message: error.message };
    }
  };

  const stopMining = async () => {
    try {
      if (miningStatus.high_performance) {
        // Stop high-performance mining
        const result = await stopHighPerformanceMining();
        return result;
      } else {
        // Use regular stop mining
        const response = await fetch(`${backendUrl}/api/mining/stop`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result = await response.json();
        
        if (result.success) {
          setMiningStatus(prev => ({ ...prev, is_mining: false }));
          fetchMiningStatus(); // Update status immediately
        }
        
        return result;
      }
    } catch (error) {
      console.error('Mining stop error:', error);
      return { success: false, message: error.message };
    }
  };

  // Socket.io connection
  useEffect(() => {
    const socketConnection = io(backendUrl, {
      transports: ['websocket', 'polling'],
      timeout: 20000,
    });

    socketConnection.on('connect', () => {
      console.log('Connected to backend via WebSocket');
      setConnectionStatus('Connected');
      setSocket(socketConnection);
    });

    socketConnection.on('disconnect', () => {
      console.log('Disconnected from backend');
      setConnectionStatus('Disconnected');
    });

    socketConnection.on('connect_error', (error) => {
      console.log('WebSocket connection error:', error);
      setConnectionStatus('Polling'); // Fallback to HTTP polling
    });

    socketConnection.on('mining_update', (data) => {
      setMiningStatus(data);
    });

    socketConnection.on('system_update', (data) => {
      setSystemStats(data);
    });

    socketConnection.on('hp_hashrate_update', (data) => {
      console.log('High-performance hashrate update:', data);
    });

    return () => {
      socketConnection.disconnect();
    };
  }, [backendUrl]);

  // Initial data fetch
  useEffect(() => {
    fetchCoinPresets();
    fetchMiningStatus();
    fetchSystemStats();
    fetchCpuInfo();
    fetchAiInsights();
  }, [fetchCoinPresets, fetchMiningStatus, fetchSystemStats, fetchCpuInfo, fetchAiInsights]);

  // Periodic data updates with HTTP polling fallback
  useEffect(() => {
    const intervals = [];
    
    // If WebSocket connection failed, use HTTP polling
    if (connectionStatus === 'Polling' || connectionStatus === 'Disconnected') {
      intervals.push(setInterval(fetchMiningStatus, 5000));
      intervals.push(setInterval(fetchSystemStats, 10000));
    }
    
    // Always update AI insights periodically
    intervals.push(setInterval(fetchAiInsights, 30000));

    return () => {
      intervals.forEach(clearInterval);
    };
  }, [connectionStatus, fetchMiningStatus, fetchSystemStats, fetchAiInsights]);

  // Coin selection handler
  const handleCoinSelect = (coin) => {
    setSelectedCoin(coin);
    setMiningConfig(prev => ({ ...prev, coin }));
  };

  return (
    <div className="min-h-screen bg-gray-900">
      {/* Header */}
      <header className="bg-gray-800 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <h1 className="text-3xl font-bold text-white">
                  ⚡ CryptoMiner Pro
                </h1>
                <p className="text-sm text-gray-400 mt-1">
                  AI-Powered Mining Dashboard
                </p>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              {/* Connection Status */}
              <div className="flex items-center space-x-2">
                <div className={`w-3 h-3 rounded-full ${
                  connectionStatus === 'Connected' ? 'bg-green-400' :
                  connectionStatus === 'Polling' ? 'bg-yellow-400' : 'bg-red-400'
                }`}></div>
                <span className="text-sm text-gray-300">
                  {connectionStatus === 'Connected' ? 'Real-time' : 
                   connectionStatus === 'Polling' ? 'HTTP Updates' : 'Offline'}
                </span>
              </div>

              {/* System Health Indicator */}
              <div className="text-sm">
                <span className="text-gray-400">System: </span>
                <span className={`font-semibold ${
                  systemStats ? 'text-green-400' : 'text-yellow-400'
                }`}>
                  {systemStats ? 'HEALTHY' : 'LOADING'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column */}
          <div className="lg:col-span-2 space-y-8">
            {/* Mining Dashboard */}
            <MiningDashboard 
              miningStatus={miningStatus} 
              selectedCoin={selectedCoin}
              highPerformanceMode={highPerformanceMode}
            />

            {/* Coin Selection */}
            <CoinSelector
              coinPresets={coinPresets}
              selectedCoin={selectedCoin}
              onCoinChange={handleCoinSelect}
            />

            {/* Mining Performance */}
            <MiningPerformance
              miningStatus={miningStatus}
              selectedCoin={selectedCoin}
            />

            {/* Real-time Metrics */}
            <RealtimeMetrics
              miningStatus={miningStatus}
              systemStats={systemStats}
              socket={socket}
            />
          </div>

          {/* Right Column */}
          <div className="space-y-8">
            {/* Mining Controls */}
            <MiningControls
              miningStatus={miningStatus}
              miningConfig={miningConfig}
              setMiningConfig={setMiningConfig}
              startMining={startMining}
              stopMining={stopMining}
              systemStats={systemStats}
              cpuInfo={cpuInfo}
              highPerformanceMode={highPerformanceMode}
              setHighPerformanceMode={setHighPerformanceMode}
            />

            {/* Wallet Configuration */}
            <WalletConfig
              config={miningConfig}
              onConfigChange={setMiningConfig}
              selectedCoin={selectedCoin}
              coinPresets={coinPresets}
              isMining={miningStatus.is_mining}
            />

            {/* System Monitoring */}
            <SystemMonitoring
              systemStats={systemStats}
              cpuInfo={cpuInfo}
              fetchCpuInfo={fetchCpuInfo}
            />

            {/* AI Insights */}
            <AIInsights
              insights={aiInsights}
              miningStatus={miningStatus}
              selectedCoin={selectedCoin}
            />
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-gray-800 mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-gray-400 text-sm">
                CryptoMiner Pro v1.0 - Advanced Cryptocurrency Mining Platform
              </p>
              <p className="text-gray-500 text-xs mt-1">
                {connectionStatus === 'Polling' && 'Real-time connection failed - using HTTP updates'}
              </p>
            </div>
            <div className="flex items-center space-x-4 text-sm text-gray-400">
              <span>Mining: {miningStatus.is_mining ? 
                (miningStatus.high_performance ? 'HIGH PERFORMANCE' : 'ACTIVE') : 'STOPPED'}</span>
              <span>•</span>
              <span>Selected: {selectedCoin?.name || 'None'}</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;