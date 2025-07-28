import React, { useState, useEffect } from 'react';

const MiningControls = ({ 
  miningStatus, 
  miningConfig, 
  setMiningConfig, 
  startMining, 
  stopMining,
  systemStats,
  cpuInfo,
  highPerformanceMode,
  setHighPerformanceMode 
}) => {
  const [localConfig, setLocalConfig] = useState({
    threads: miningConfig.threads || 4,
    intensity: miningConfig.intensity || 0.8,
    auto_thread_detection: miningConfig.auto_thread_detection || true,
    ai_enabled: miningConfig.ai_enabled || false,
    auto_optimize: miningConfig.auto_optimize || false,
    thread_profile: miningConfig.thread_profile || 'standard'
  });

  const [isStarting, setIsStarting] = useState(false);
  const [isStopping, setIsStopping] = useState(false);

  // Get CPU info for optimal settings (use override-aware CPU detection)
  const cpuCores = cpuInfo?.cores?.physical || systemStats?.cpu?.cores || 16;
  const maxSafeThreads = Math.min(256, Math.max(1, cpuCores - 1)); // Respect MAX_THREADS limit
  const hasOverride = cpuInfo?.cores?.override_active || false;

  // Use backend-provided mining profiles if available, otherwise calculate
  const backendProfiles = cpuInfo?.mining_profiles;
  const miningProfiles = backendProfiles || {
    light: { threads: Math.max(1, Math.floor(cpuCores * 0.25)), intensity: 0.5, description: 'Light usage' },
    standard: { threads: Math.max(1, Math.floor(cpuCores * 0.75)), intensity: 0.8, description: 'Balanced performance' },
    maximum: { threads: maxSafeThreads, intensity: 0.9, description: 'High performance' },
    absolute_max: { threads: Math.min(256, cpuCores), intensity: 1.0, description: 'Maximum (may affect system)' }
  };

  // Update parent config when local config changes
  useEffect(() => {
    setMiningConfig(prevConfig => ({
      ...prevConfig,
      ...localConfig
    }));
  }, [localConfig, setMiningConfig]);

  const handleConfigChange = (key, value) => {
    setLocalConfig(prev => ({
      ...prev,
      [key]: value
    }));
  };

  const handleProfileChange = (profile) => {
    const profileConfig = miningProfiles[profile];
    setLocalConfig(prev => ({
      ...prev,
      threads: profileConfig.threads,
      intensity: profileConfig.intensity,
      thread_profile: profile,
      auto_thread_detection: false
    }));
  };

  const handleStartMining = async () => {
    setIsStarting(true);
    try {
      await startMining();
    } finally {
      setIsStarting(false);
    }
  };

  const handleStopMining = async () => {
    setIsStopping(true);
    try {
      await stopMining();
    } finally {
      setIsStopping(false);
    }
  };

  return (
    <div className="bg-gray-800 rounded-lg p-6">
      <h2 className="text-xl font-bold text-white mb-4 flex items-center">
        <span className="mr-2">⚙️</span>
        Mining Controls
      </h2>

      {/* High Performance Mode Toggle */}
      <div className="bg-gradient-to-r from-red-500 to-orange-500 p-4 rounded-lg mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="text-2xl">🚀</div>
            <div>
              <h3 className="text-white font-bold text-lg">High Performance Mode</h3>
              <p className="text-red-100 text-sm">
                Multi-process mining: 15,000,000+ H/s (Uses all CPU cores)
              </p>
            </div>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              className="sr-only"
              checked={highPerformanceMode}
              onChange={(e) => setHighPerformanceMode(e.target.checked)}
            />
            <div className="w-14 h-7 bg-red-800 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-6 after:w-6 after:transition-all peer-checked:bg-green-600"></div>
          </label>
        </div>
        {highPerformanceMode && (
          <div className="mt-3 text-red-100 text-sm">
            ⚠️ High Performance Mode will use maximum CPU resources and may affect system responsiveness.
          </div>
        )}
      </div>

      {/* Mining Profile Selection */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {Object.entries(miningProfiles).map(([key, profile]) => (
          <div
            key={key}
            className={`p-3 rounded-lg border-2 cursor-pointer transition-all ${
              localConfig.thread_profile === key
                ? 'border-blue-500 bg-blue-900/30'
                : 'border-gray-600 bg-gray-700 hover:border-gray-500'
            }`}
            onClick={() => handleProfileChange(key)}
          >
            <div className="text-white font-semibold capitalize">{key.replace('_', ' ')}</div>
            <div className="text-gray-300 text-sm">{profile.description}</div>
            <div className="text-blue-400 text-xs mt-1">
              {profile.threads} threads • {Math.round(profile.intensity * 100)}% intensity
            </div>
          </div>
        ))}
      </div>

      {/* Thread Control */}
      <div className="space-y-4">
        {/* Auto Thread Detection */}
        <div className="flex items-center justify-between">
          <label className="text-white font-medium">Auto Thread Detection</label>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              className="sr-only"
              checked={localConfig.auto_thread_detection}
              onChange={(e) => handleConfigChange('auto_thread_detection', e.target.checked)}
            />
            <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>

        {/* Manual Thread Count */}
        {!localConfig.auto_thread_detection && (
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-white font-medium">Thread Count</label>
              <span className="text-blue-400 font-mono">{localConfig.threads}</span>
            </div>
            <input
              type="range"
              min="1"
              max="256"
              value={localConfig.threads}
              onChange={(e) => handleConfigChange('threads', parseInt(e.target.value))}
              className="w-full h-2 bg-gray-600 rounded-lg appearance-none cursor-pointer slider"
            />
            <div className="flex justify-between text-xs text-gray-400 mt-1">
              <span>1</span>
              <span>Recommended: {maxSafeThreads}</span>
              <span>256</span>
            </div>
          </div>
        )}

        {/* Intensity Control */}
        <div>
          <div className="flex justify-between items-center mb-2">
            <label className="text-white font-medium">Mining Intensity</label>
            <span className="text-green-400 font-mono">{Math.round(localConfig.intensity * 100)}%</span>
          </div>
          <input
            type="range"
            min="0.1"
            max="1.0"
            step="0.1"
            value={localConfig.intensity}
            onChange={(e) => handleConfigChange('intensity', parseFloat(e.target.value))}
            className="w-full h-2 bg-gray-600 rounded-lg appearance-none cursor-pointer slider"
          />
          <div className="flex justify-between text-xs text-gray-400 mt-1">
            <span>10%</span>
            <span>Balanced: 80%</span>
            <span>100%</span>
          </div>
        </div>

        {/* AI Optimization */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <label className="text-white font-medium">AI-Powered Optimization</label>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                className="sr-only"
                checked={localConfig.ai_enabled}
                onChange={(e) => handleConfigChange('ai_enabled', e.target.checked)}
              />
              <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-purple-600"></div>
            </label>
          </div>

          {localConfig.ai_enabled && (
            <div className="flex items-center justify-between pl-4">
              <label className="text-white font-medium">Auto-Optimize Settings</label>
              <label className="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  className="sr-only"
                  checked={localConfig.auto_optimize}
                  onChange={(e) => handleConfigChange('auto_optimize', e.target.checked)}
                />
                <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-purple-600"></div>
              </label>
            </div>
          )}
        </div>

        {/* System Status */}
        <div className="bg-gray-700 p-4 rounded-lg">
          <h4 className="text-white font-medium mb-2">System Status</h4>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span className="text-gray-400">CPU Cores:</span>
              <span className="text-white ml-2">{cpuCores}</span>
            </div>
            <div>
              <span className="text-gray-400">Max Safe Threads:</span>
              <span className="text-green-400 ml-2">{maxSafeThreads}</span>
            </div>
          </div>
        </div>

        {/* Control Buttons */}
        <div className="flex space-x-4 pt-4">
          {!miningStatus.is_mining ? (
            <button
              onClick={handleStartMining}
              disabled={isStarting}
              className={`flex-1 py-3 px-6 rounded-lg font-bold text-white transition-all ${
                isStarting
                  ? 'bg-gray-600 cursor-not-allowed'
                  : 'bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 transform hover:scale-105'
              }`}
            >
              {isStarting ? (
                <span className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Starting...
                </span>
              ) : (
                `▶️ START ${highPerformanceMode ? 'HIGH PERFORMANCE ' : ''}MINING`
              )}
            </button>
          ) : (
            <button
              onClick={handleStopMining}
              disabled={isStopping}
              className={`flex-1 py-3 px-6 rounded-lg font-bold text-white transition-all ${
                isStopping
                  ? 'bg-gray-600 cursor-not-allowed'
                  : 'bg-gradient-to-r from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 transform hover:scale-105'
              }`}
            >
              {isStopping ? (
                <span className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Stopping...
                </span>
              ) : (
                '⏹️ STOP MINING'
              )}
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default MiningControls;