import React, { useEffect, useState } from 'react';
import CustomCoinManager from './CustomCoinManager';

const CoinSelector = ({ coinPresets, selectedCoin, onCoinChange }) => {
  const [showCustomManager, setShowCustomManager] = useState(false);
  const [customCoins, setCustomCoins] = useState([]);
  
  // Load selected coin from localStorage on component mount
  useEffect(() => {
    const savedCoin = localStorage.getItem('cryptominer_selected_coin');
    if (savedCoin && coinPresets && Array.isArray(coinPresets)) {
      // Find the saved coin in the array
      const foundCoin = coinPresets.find(coin => coin.symbol === savedCoin || coin.name === savedCoin);
      if (foundCoin) {
        console.log('Loading saved coin:', foundCoin);
        onCoinChange(foundCoin);
      }
    }
  }, [coinPresets, onCoinChange]);

  // Save selected coin to localStorage whenever it changes
  useEffect(() => {
    if (selectedCoin) {
      console.log('Saving selected coin:', selectedCoin.symbol || selectedCoin.name);
      localStorage.setItem('cryptominer_selected_coin', selectedCoin.symbol || selectedCoin.name);
    }
  }, [selectedCoin]);

  // Extract custom coins from coinPresets array
  useEffect(() => {
    if (coinPresets && Array.isArray(coinPresets)) {
      const customs = coinPresets.filter(coin => coin.is_custom);
      setCustomCoins(customs);
    }
  }, [coinPresets]);

  const handleCoinChange = (coin) => {
    console.log('Coin changed to:', coin);
    onCoinChange(coin);
  };

  const handleCustomCoinAdded = () => {
    // This will trigger a refresh of coin presets in the parent component
    setShowCustomManager(false);
    // You might want to call a parent function to refresh coin presets
  };

  const getCoinIcon = (symbol) => {
    const icons = {
      'LTC': '₿',
      'DOGE': '🐕', 
      'FTC': '🪶',
    };
    return icons[symbol] || '💰';
  };

  const getCoinColor = (symbol) => {
    const colors = {
      'LTC': 'from-gray-400 to-gray-600',
      'DOGE': 'from-yellow-400 to-yellow-600',
      'FTC': 'from-blue-400 to-blue-600',
    };
    return colors[symbol] || 'from-crypto-gold to-yellow-600';
  };

  if (!coinPresets || !Array.isArray(coinPresets) || coinPresets.length === 0) {
    return (
      <div className="mining-card">
        <h3 className="text-xl font-bold text-white mb-4">Select Cryptocurrency</h3>
        <div className="text-center text-gray-400 py-8">
          <div className="loading-spinner mx-auto mb-4"></div>
          <p>Loading available coins...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="mining-card">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-xl font-bold text-white">Select Cryptocurrency</h3>
        <button
          onClick={() => setShowCustomManager(true)}
          className="px-3 py-1 bg-purple-500 text-white rounded text-sm hover:bg-purple-600 transition-colors"
        >
          Manage Custom Coins
        </button>
      </div>

      {/* Built-in Coins */}
      <div className="mb-6">
        <h4 className="text-md font-medium text-gray-300 mb-3">Built-in Coins</h4>
        <div className="space-y-3">
          {coinPresets
            .filter(coin => !coin.is_custom)
            .map((coin, index) => (
              <div
                key={coin.symbol || index}
                className={`coin-option ${selectedCoin && selectedCoin.symbol === coin.symbol ? 'selected' : ''}`}
                onClick={() => handleCoinChange(coin)}
              >
                <div className={`coin-icon bg-gradient-to-br ${getCoinColor(coin.symbol)}`}>
                  {getCoinIcon(coin.symbol)}
                </div>
                
                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-semibold text-white">{coin.name}</div>
                      <div className="text-sm text-gray-300">{coin.symbol}</div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-medium text-crypto-gold">
                        {coin.block_reward} {coin.symbol}
                      </div>
                      <div className="text-xs text-gray-400">Block Reward</div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
        </div>
      </div>

      {/* Custom Coins */}
      {customCoins.length > 0 && (
        <div className="mb-6">
          <h4 className="text-md font-medium text-gray-300 mb-3">Custom Coins ({customCoins.length})</h4>
          <div className="space-y-3">
            {customCoins.map((coin, index) => (
              <div
                key={coin.symbol || index}
                className={`coin-option ${selectedCoin && selectedCoin.symbol === coin.symbol ? 'selected' : ''}`}
                onClick={() => handleCoinChange(coin)}
              >
                <div className="coin-icon bg-gradient-to-br from-purple-500 to-pink-500">
                  {coin.symbol}
                </div>
                
                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-semibold text-white">{coin.name}</div>
                      <div className="text-sm text-gray-300">{coin.symbol}</div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-medium text-crypto-gold">
                        {coin.block_reward} {coin.symbol}
                      </div>
                      <div className="text-xs text-gray-400">Block Reward</div>
                      <div className="text-xs text-purple-400 font-medium">CUSTOM</div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Coin Details */}
      {selectedCoin && (
        <div className="mt-6 p-4 bg-crypto-accent/20 rounded-lg">
          <h4 className="font-semibold text-white mb-3">
            {selectedCoin.name} Details
          </h4>
          
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-300">Algorithm:</span>
              <span className="text-white font-medium">
                {selectedCoin.algorithm.toUpperCase()}
              </span>
            </div>
            
            <div className="flex justify-between">
              <span className="text-gray-300">Block Time:</span>
              <span className="text-white font-medium">
                {selectedCoin.block_time_target}s
              </span>
            </div>
            
            <div className="flex justify-between">
              <span className="text-gray-300">Network Difficulty:</span>
              <span className="text-white font-medium">
                {selectedCoin.network_difficulty.toLocaleString()}
              </span>
            </div>
            
            <div className="flex justify-between">
              <span className="text-gray-300">Scrypt N:</span>
              <span className="text-white font-medium">
                {selectedCoin.scrypt_params?.N || 1024}
              </span>
            </div>
          </div>
        </div>
      )}

      {/* Performance Hint */}
      <div className="mt-4 p-3 bg-blue-500/10 border border-blue-500/20 rounded-lg">
        <div className="flex items-start space-x-2">
          <span className="text-blue-400 text-sm">💡</span>
          <div className="text-blue-400 text-xs">
            <p className="font-medium mb-1">Mining Tip:</p>
            <p>Different coins have varying difficulty levels and profitability. 
               Custom coins allow you to mine any Scrypt-based cryptocurrency.
               The AI system will help optimize your selection based on current market conditions.</p>
          </div>
        </div>
      </div>

      {/* Custom Coin Manager Modal */}
      {showCustomManager && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-6xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">Custom Coin Manager</h3>
              <button
                onClick={() => setShowCustomManager(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            
            <CustomCoinManager onCoinAdded={handleCustomCoinAdded} />
          </div>
        </div>
      )}
    </div>
  );
};

export default CoinSelector;