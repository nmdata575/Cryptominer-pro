import React, { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import io from 'socket.io-client';
import './App.css';

// Import new role-based components
import DashboardSection from './components/DashboardSection';
import MiningControlCenter from './components/MiningControlCenter';
import CoinSelector from './components/CoinSelector';
import WalletConfig from './components/WalletConfig';
import MiningControls from './components/MiningControls';
import MiningPerformance from './components/MiningPerformance';
import SystemMonitoring from './components/SystemMonitoring';
import AIInsights from './components/AIInsights';

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL || 'http://localhost:8001';

function App() {
  // Core state
  const [miningStatus, setMiningStatus] = useState({
    is_mining: false,
    stats: {
      hashrate: 0.0,
      accepted_shares: 0,
      rejected_shares: 0,
      blocks_found: 0,
      cpu_usage: 0.0,
      memory_usage: 0.0,
      temperature: null,
      uptime: 0.0,
      efficiency: 0.0
    },
    config: null
  });
  
  const [systemStats, setSystemStats] = useState({
    cpu: { usage_percent: 0, count: 0 },
    memory: { total: 0, available: 0, percent: 0, used: 0 },
    disk: { total: 0, used: 0, free: 0, percent: 0 }
  });
  
  const [aiInsights, setAiInsights] = useState({
    insights: {
      hash_pattern_prediction: {},
      difficulty_forecast: {},
      coin_switching_recommendation: {},
      optimization_suggestions: []
    },
    predictions: {}
  });
  
  const [coinPresets, setCoinPresets] = useState({});
  const [selectedCoin, setSelectedCoin] = useState('litecoin');
  const [miningConfig, setMiningConfig] = useState({
    mode: 'solo',
    threads: 4,
    intensity: 1.0,
    auto_optimize: true,
    ai_enabled: true,
    wallet_address: '',
    pool_username: '',
    pool_password: 'x',
    // NEW: Custom pool/RPC configuration fields
    custom_pool_address: '',
    custom_pool_port: '',
    custom_rpc_host: '',
    custom_rpc_port: '',
    custom_rpc_username: '',
    custom_rpc_password: '',
    // NEW: Dynamic thread management
    auto_thread_detection: true,
    thread_profile: 'standard',
    // NEW: Real mining mode toggle
    real_mining: false
  });
  
  // Create stable callback functions
  const handleCoinChange = useCallback((coin) => {
    setSelectedCoin(coin);
  }, []);
  
  const handleConfigChange = useCallback((configUpdate) => {
    setMiningConfig(configUpdate);
  }, []);
  
  const [socket, setSocket] = useState(null);
  const [connectionStatus, setConnectionStatus] = useState('connecting');
  const [errorMessage, setErrorMessage] = useState('');

  // Socket.io connection management
  const connectSocket = useCallback(() => {
    if (socket) return;
    
    try {
      const newSocket = io(BACKEND_URL, {
        transports: ['websocket', 'polling'],
        timeout: 20000,
        reconnection: true,
        reconnectionAttempts: 3,
        reconnectionDelay: 3000,
        forceNew: true
      });
      
      // Set a timeout for connection attempt
      const connectionTimeout = setTimeout(() => {
        if (connectionStatus === 'connecting') {
          console.log('Socket.io connection timeout - falling back to HTTP polling');
          setConnectionStatus('polling');
          setErrorMessage('Real-time connection failed - using HTTP updates');
          newSocket.disconnect();
        }
      }, 15000);
      
      newSocket.on('connect', () => {
        console.log('Socket.io connected successfully');
        clearTimeout(connectionTimeout);
        setConnectionStatus('connected');
        setErrorMessage('');
        setSocket(newSocket);
      });
      
      newSocket.on('mining_update', (data) => {
        setMiningStatus(prev => ({
          ...prev,
          stats: data.stats || prev.stats,
          is_mining: data.is_mining
        }));
      });
      
      newSocket.on('system_update', (data) => {
        setSystemStats(data);
      });
      
      newSocket.on('disconnect', () => {
        console.log('Socket.io disconnected');
        clearTimeout(connectionTimeout);
        setConnectionStatus('disconnected');
        setSocket(null);
      });
      
      newSocket.on('connect_error', (error) => {
        console.error('Socket.io connection error:', error);
        clearTimeout(connectionTimeout);
        setConnectionStatus('error');
        setErrorMessage('Socket connection failed');
      });
      
    } catch (error) {
      console.error('Socket.io creation failed:', error);
      setConnectionStatus('error');
      setErrorMessage('Failed to create socket connection');
    }
  }, [socket, connectionStatus]);

  // Replace the useEffect that was using WebSocket
  useEffect(() => {
    connectSocket();

    return () => {
      if (socket) {
        socket.disconnect();
      }
    };
  }, [connectSocket, socket]);

  // API functions wrapped in useCallback to prevent infinite re-renders
  const fetchMiningStatus = useCallback(async () => {
    try {
      const response = await axios.get(`${BACKEND_URL}/api/mining/status`);
      setMiningStatus(response.data);
      setErrorMessage(''); // Clear error on success
    } catch (error) {
      console.error('Failed to fetch mining status:', error);
      setErrorMessage('Failed to fetch mining status');
    }
  }, []);

  const fetchAIInsights = useCallback(async () => {
    try {
      const response = await axios.get(`${BACKEND_URL}/api/mining/ai-insights`);
      if (!response.data.error) {
        setAiInsights(response.data);
      }
    } catch (error) {
      console.error('Failed to fetch AI insights:', error);
    }
  }, []);

  const fetchCoinPresets = useCallback(async () => {
    try {
      const response = await axios.get(`${BACKEND_URL}/api/coins/presets`);
      setCoinPresets(response.data.presets);
      setErrorMessage(''); // Clear error on success
    } catch (error) {
      console.error('Failed to fetch coin presets:', error);
      setErrorMessage('Failed to fetch coin presets');
    }
  }, []);

  const fetchSystemStats = useCallback(async () => {
    try {
      const response = await axios.get(`${BACKEND_URL}/api/system/stats`);
      if (!response.data.error) {
        setSystemStats(response.data);
      }
    } catch (error) {
      console.error('Failed to fetch system stats:', error);
    }
  }, []);

  const startMining = async () => {
    try {
      const coinConfig = coinPresets[selectedCoin];
      if (!coinConfig) {
        setErrorMessage('Please select a valid coin');
        return;
      }

      // Validate wallet address for solo mining
      if (miningConfig.mode === 'solo' && !miningConfig.wallet_address.trim()) {
        setErrorMessage('Wallet address is required for solo mining');
        return;
      }

      // Validate pool credentials for pool mining
      if (miningConfig.mode === 'pool' && !miningConfig.pool_username.trim()) {
        setErrorMessage('Pool username is required for pool mining');
        return;
      }

      const fullConfig = {
        coin: coinConfig,
        mode: miningConfig.mode,
        threads: miningConfig.threads,
        intensity: miningConfig.intensity,
        auto_optimize: miningConfig.auto_optimize,
        ai_enabled: miningConfig.ai_enabled,
        wallet_address: miningConfig.wallet_address.trim(),
        pool_username: miningConfig.pool_username.trim(),
        pool_password: miningConfig.pool_password || 'x',
        // Include custom connection fields
        custom_pool_address: miningConfig.custom_pool_address?.trim() || '',
        custom_pool_port: miningConfig.custom_pool_port?.trim() || '',
        custom_rpc_host: miningConfig.custom_rpc_host?.trim() || '',
        custom_rpc_port: miningConfig.custom_rpc_port?.trim() || '',
        custom_rpc_username: miningConfig.custom_rpc_username?.trim() || '',
        custom_rpc_password: miningConfig.custom_rpc_password?.trim() || '',
        // Include dynamic thread management
        auto_thread_detection: miningConfig.auto_thread_detection,
        thread_profile: miningConfig.thread_profile
      };

      const response = await axios.post(`${BACKEND_URL}/api/mining/start`, fullConfig);
      
      if (response.data.success) {
        setErrorMessage('');
        await fetchMiningStatus();
      } else {
        setErrorMessage('Failed to start mining');
      }
    } catch (error) {
      console.error('Failed to start mining:', error);
      setErrorMessage('Failed to start mining: ' + (error.response?.data?.detail || error.message));
    }
  };

  const stopMining = async () => {
    try {
      const response = await axios.post(`${BACKEND_URL}/api/mining/stop`);
      
      if (response.data.success) {
        setErrorMessage('');
        await fetchMiningStatus();
      } else {
        setErrorMessage('Failed to stop mining');
      }
    } catch (error) {
      console.error('Failed to stop mining:', error);
      setErrorMessage('Failed to stop mining: ' + (error.response?.data?.detail || error.message));
    }
  };

  // Effects
  useEffect(() => {
    // Initial data loading
    fetchCoinPresets();
    fetchMiningStatus();
    fetchSystemStats();
    fetchAIInsights();
    
    // Socket connection is handled separately
  }, [fetchCoinPresets, fetchMiningStatus, fetchSystemStats, fetchAIInsights]);

  // Periodic updates for non-Socket.io data and fallback polling
  useEffect(() => {
    let interval;
    
    if (connectionStatus === 'connected') {
      // Less frequent polling when Socket.io is connected
      interval = setInterval(() => {
        fetchAIInsights(); // AI insights still use HTTP
      }, 10000);
    } else {
      // More frequent polling when Socket.io is not connected
      const pollFrequency = connectionStatus === 'polling' ? 3000 : 5000;
      interval = setInterval(() => {
        fetchMiningStatus();
        fetchSystemStats();
        fetchAIInsights();
      }, pollFrequency);
    }

    return () => clearInterval(interval);
  }, [connectionStatus, fetchMiningStatus, fetchSystemStats, fetchAIInsights]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-crypto-dark via-crypto-blue to-crypto-accent">
      {/* Header */}
      <header className="bg-crypto-dark/90 backdrop-blur-sm border-b border-crypto-accent/30 sticky top-0 z-50">
        <div className="container mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-gradient-to-br from-crypto-gold to-yellow-600 rounded-xl flex items-center justify-center">
                <span className="text-2xl font-bold text-crypto-dark">₿</span>
              </div>
              <div>
                <h1 className="text-2xl font-bold text-white">CryptoMiner Pro</h1>
                <p className="text-crypto-gold text-sm">AI-Powered Mining Dashboard</p>
              </div>
            </div>
            
            {/* Connection Status */}
            <div className="flex items-center space-x-4">
              <div className={`flex items-center space-x-2 px-3 py-1 rounded-full text-sm ${
                connectionStatus === 'connected' 
                  ? 'bg-crypto-green/20 text-crypto-green' 
                  : connectionStatus === 'error'
                  ? 'bg-crypto-red/20 text-crypto-red'
                  : 'bg-yellow-500/20 text-yellow-500'
              }`}>
                <div className={`w-2 h-2 rounded-full ${
                  connectionStatus === 'connected' 
                    ? 'bg-crypto-green animate-pulse' 
                    : connectionStatus === 'error'
                    ? 'bg-crypto-red'
                    : 'bg-yellow-500 animate-pulse'
                }`}></div>
                <span className="capitalize">{connectionStatus}</span>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Error Message */}
      {errorMessage && (
        <div className="container mx-auto px-6 py-4">
          <div className="bg-crypto-red/20 border border-crypto-red/30 rounded-lg p-4 text-crypto-red">
            <p className="font-medium">⚠️ {errorMessage}</p>
          </div>
        </div>
      )}

      {/* Main Content - Role-Based Sections */}
      <main className="container mx-auto px-6 py-8">
        <div className="space-y-8">
          
          {/* Section 1: Mining Control Center */}
          <DashboardSection
            title="Mining Control Center"
            icon="🎛️"
            description="Quick actions, status overview, and mining controls"
            headerColor="text-crypto-gold"
            borderColor="border-crypto-gold/30"
          >
            <MiningControlCenter
              miningStatus={miningStatus}
              selectedCoin={selectedCoin}
              coinPresets={coinPresets}
              miningConfig={miningConfig}
              onStart={startMining}
              onStop={stopMining}
              errorMessage={errorMessage}
              systemMetrics={systemStats}
            />
          </DashboardSection>

          {/* Section 2: Miner Setup */}
          <DashboardSection
            title="Miner Setup"
            icon="⚙️"
            description="Cryptocurrency selection, wallet configuration, and performance settings"
            headerColor="text-crypto-blue"
            borderColor="border-crypto-blue/30"
            collapsible={true}
            defaultExpanded={!miningStatus.is_mining}
          >
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <CoinSelector
                coinPresets={coinPresets}
                selectedCoin={selectedCoin}
                onCoinChange={handleCoinChange}
              />
              
              <WalletConfig
                config={miningConfig}
                onConfigChange={handleConfigChange}
                selectedCoin={selectedCoin}
                coinPresets={coinPresets}
                isMining={miningStatus.is_mining}
              />
              
              <MiningControls
                config={miningConfig}
                onConfigChange={handleConfigChange}
                isMining={miningStatus.is_mining}
                onStart={startMining}
                onStop={stopMining}
              />
            </div>
          </DashboardSection>

          {/* Section 3: Mining Performance */}
          <DashboardSection
            title="Mining Performance"
            icon="📊"
            description="Real-time mining statistics, performance metrics, and efficiency analysis"
            headerColor="text-crypto-green"
            borderColor="border-crypto-green/30"
          >
            <MiningPerformance
              miningStatus={miningStatus}
              selectedCoin={selectedCoin}
              coinPresets={coinPresets}
            />
          </DashboardSection>

          {/* Section 4: System Monitoring */}
          <DashboardSection
            title="System Monitoring"
            icon="🖥️"
            description="Hardware statistics, resource usage, and system health monitoring"
            headerColor="text-purple-400"
            borderColor="border-purple-400/30"
            collapsible={true}
            defaultExpanded={true}
          >
            <SystemMonitoring
              systemMetrics={systemStats}
            />
          </DashboardSection>

          {/* Section 5: AI Assistant */}
          <DashboardSection
            title="AI Assistant"
            icon="🤖"
            description="Mining insights, optimization recommendations, and predictive analysis"
            headerColor="text-crypto-accent"
            borderColor="border-crypto-accent/30"
            collapsible={true}
            defaultExpanded={false}
          >
            <AIInsights
              insights={aiInsights.insights}
              predictions={aiInsights.predictions}
            />
          </DashboardSection>

        </div>
      </main>

      {/* Footer */}
      <footer className="bg-crypto-dark/50 border-t border-crypto-accent/30 mt-12">
        <div className="container mx-auto px-6 py-6">
          <div className="text-center text-gray-400">
            <p>&copy; 2025 CryptoMiner Pro - Advanced AI-Powered Mining System</p>
            <p className="text-sm mt-2">
              Featuring complete scrypt implementation with multi-coin support
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;