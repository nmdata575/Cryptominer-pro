import React from 'react';

const MiningDashboard = ({ miningStatus, highPerformanceMode }) => {
  const formatHashrate = (hashrate) => {
    if (hashrate >= 1000000) {
      return `${(hashrate / 1000000).toFixed(2)} MH/s`;
    } else if (hashrate >= 1000) {
      return `${(hashrate / 1000).toFixed(2)} KH/s`;
    } else {
      return `${hashrate.toFixed(2)} H/s`;
    }
  };

  const formatNumber = (num) => {
    return new Intl.NumberFormat().format(num || 0);
  };

  const getStatusColor = () => {
    if (!miningStatus.is_mining) return 'text-gray-400';
    if (miningStatus.high_performance) return 'text-red-400';
    return 'text-green-400';
  };

  const getStatusText = () => {
    if (!miningStatus.is_mining) return 'STOPPED';
    if (miningStatus.high_performance) return 'HIGH PERFORMANCE ACTIVE';
    return 'ACTIVE';
  };

  const currentHashrate = miningStatus.stats?.hashrate || 0;
  const isHighPerformance = miningStatus.high_performance || false;

  return (
    <div className="bg-gray-800 rounded-lg p-6">
      <h2 className="text-xl font-bold text-white mb-4 flex items-center">
        <span className="mr-2">📊</span>
        Mining Dashboard
      </h2>

      {/* High Performance Mode Indicator */}
      {isHighPerformance && (
        <div className="bg-gradient-to-r from-red-500 to-orange-500 p-4 rounded-lg mb-6 animate-pulse">
          <div className="flex items-center justify-between text-white">
            <div className="flex items-center space-x-3">
              <div className="text-3xl">🚀</div>
              <div>
                <h3 className="font-bold text-xl">HIGH PERFORMANCE MODE ACTIVE</h3>
                <p className="text-red-100">
                  {miningStatus.processes || 0} processes running • Expected: {formatNumber(miningStatus.expected_hashrate || 0)} H/s
                </p>
              </div>
            </div>
            <div className="text-right">
              <div className="text-3xl font-mono font-bold">{formatHashrate(currentHashrate)}</div>
              <div className="text-red-100 text-sm">Live Hashrate</div>
            </div>
          </div>
        </div>
      )}

      {/* Mining Status Banner */}
      <div className={`p-4 rounded-lg mb-6 ${
        miningStatus.is_mining 
          ? (isHighPerformance ? 'bg-gradient-to-r from-red-600 to-orange-600' : 'bg-green-600') 
          : 'bg-gray-700'
      }`}>
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-white font-bold text-lg">Mining Status</h3>
            <p className={`font-mono text-lg ${getStatusColor()}`}>
              {getStatusText()}
            </p>
          </div>
          <div className="text-right">
            <div className="text-white text-sm">Current Coin</div>
            <div className="text-white font-bold">
              Litecoin (LTC)
            </div>
          </div>
        </div>
      </div>

      {/* Hashrate Display */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="bg-gray-700 p-6 rounded-lg">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-white font-semibold flex items-center">
              <span className="mr-2">⚡</span>
              Hash Rate
            </h3>
            {isHighPerformance && (
              <span className="bg-red-500 text-white px-2 py-1 rounded text-xs font-bold">
                HIGH PERF
              </span>
            )}
          </div>
          <div className="text-center">
            <div className={`text-4xl font-mono font-bold mb-2 ${
              currentHashrate > 1000000 ? 'text-red-400' :
              currentHashrate > 10000 ? 'text-green-400' :
              currentHashrate > 1000 ? 'text-yellow-400' : 'text-gray-400'
            }`}>
              {formatHashrate(currentHashrate)}
            </div>
            <div className="text-gray-400 text-sm">
              {formatNumber(currentHashrate)} hashes per second
            </div>
            {isHighPerformance && (
              <div className="text-red-400 text-xs mt-2 font-semibold">
                Multi-Process Mining Active
              </div>
            )}
          </div>
        </div>

        <div className="bg-gray-700 p-6 rounded-lg">
          <h3 className="text-white font-semibold mb-4 flex items-center">
            <span className="mr-2">⏱️</span>
            Performance Stats
          </h3>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-400">Uptime:</span>
              <span className="text-white font-mono">
                {Math.floor((miningStatus.stats?.uptime || 0) / 60)}m {Math.floor((miningStatus.stats?.uptime || 0) % 60)}s
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Efficiency:</span>
              <span className="text-green-400 font-mono">
                {(miningStatus.stats?.efficiency || 0).toFixed(1)}%
              </span>
            </div>
            {isHighPerformance && (
              <div className="flex justify-between">
                <span className="text-gray-400">Processes:</span>
                <span className="text-red-400 font-mono">
                  {miningStatus.processes || 0}
                </span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Mining Statistics */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-gray-700 p-4 rounded-lg text-center">
          <h4 className="text-gray-400 text-sm mb-2">Accepted Shares</h4>
          <div className="text-green-400 text-2xl font-bold">
            {formatNumber(miningStatus.stats?.accepted_shares || 0)}
          </div>
        </div>

        <div className="bg-gray-700 p-4 rounded-lg text-center">
          <h4 className="text-gray-400 text-sm mb-2">Rejected Shares</h4>
          <div className="text-red-400 text-2xl font-bold">
            {formatNumber(miningStatus.stats?.rejected_shares || 0)}
          </div>
        </div>

        <div className="bg-gray-700 p-4 rounded-lg text-center">
          <h4 className="text-gray-400 text-sm mb-2">Blocks Found</h4>
          <div className="text-yellow-400 text-2xl font-bold">
            {formatNumber(miningStatus.stats?.blocks_found || 0)}
          </div>
        </div>

        <div className="bg-gray-700 p-4 rounded-lg text-center">
          <h4 className="text-gray-400 text-sm mb-2">CPU Usage</h4>
          <div className="text-blue-400 text-2xl font-bold">
            {(miningStatus.stats?.cpu_usage || 0).toFixed(1)}%
          </div>
        </div>
      </div>

      {/* Hash Rate Trend Chart Placeholder */}
      <div className="bg-gray-700 p-4 rounded-lg">
        <h4 className="text-white font-semibold mb-4 flex items-center">
          <span className="mr-2">📈</span>
          Hash Rate Trend
        </h4>
        <div className="h-32 bg-gray-600 rounded flex items-center justify-center">
          <div className="text-center text-gray-400">
            <div className="text-lg mb-2">📊</div>
            <div className="text-sm">
              {miningStatus.is_mining 
                ? `Live monitoring: ${formatHashrate(currentHashrate)}`
                : 'Start mining to see hash rate trends'
              }
            </div>
            {isHighPerformance && (
              <div className="text-red-400 text-xs mt-2">
                High Performance Mode: Maximum CPU Utilization
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Connection Status */}
      {miningStatus.is_mining && (
        <div className="mt-4 p-3 bg-gray-700 rounded-lg">
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center space-x-4">
              <div className="flex items-center">
                <div className={`w-2 h-2 rounded-full mr-2 ${
                  miningStatus.pool_connected ? 'bg-green-400' : 'bg-yellow-400'
                }`}></div>
                <span className="text-gray-400">
                  {isHighPerformance ? 'High Performance' : 'Pool'}: 
                </span>
                <span className="text-white ml-2">
                  {miningStatus.pool_connected ? 'Connected' : 'Connecting...'}
                </span>
              </div>
              <div className="flex items-center">
                <span className="text-gray-400">Mode:</span>
                <span className="text-white ml-2">
                  {isHighPerformance ? 'Multi-Process' : (miningStatus.test_mode ? 'Test' : 'Live')}
                </span>
              </div>
            </div>
            {miningStatus.current_job && (
              <div className="text-gray-400 text-xs font-mono">
                Job: {miningStatus.current_job.substring(0, 8)}...
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default MiningDashboard;