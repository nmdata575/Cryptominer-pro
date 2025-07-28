import React from 'react';

const RealtimeMetrics = ({ miningStatus, systemStats, socket }) => {
  const formatHashrate = (hashrate) => {
    if (hashrate >= 1000000) {
      return `${(hashrate / 1000000).toFixed(2)} MH/s`;
    } else if (hashrate >= 1000) {
      return `${(hashrate / 1000).toFixed(2)} KH/s`;
    } else {
      return `${hashrate.toFixed(2)} H/s`;
    }
  };

  const connectionStatus = socket ? 'Connected' : 'Disconnected';
  const currentHashrate = miningStatus?.stats?.hashrate || 0;

  return (
    <div className="bg-gray-800 rounded-lg p-6">
      <h2 className="text-xl font-bold text-white mb-4 flex items-center">
        <span className="mr-2">📊</span>
        Real-time Metrics
      </h2>

      {/* Connection Status */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
        <div className="bg-gray-700 p-4 rounded-lg">
          <h3 className="text-gray-400 text-sm mb-2">Connection Status</h3>
          <div className="flex items-center space-x-2">
            <div className={`w-3 h-3 rounded-full ${
              socket ? 'bg-green-400' : 'bg-red-400'
            }`}></div>
            <span className="text-white font-semibold">{connectionStatus}</span>
          </div>
        </div>

        <div className="bg-gray-700 p-4 rounded-lg">
          <h3 className="text-gray-400 text-sm mb-2">Current Hashrate</h3>
          <div className="text-green-400 text-xl font-bold">
            {formatHashrate(currentHashrate)}
          </div>
        </div>

        <div className="bg-gray-700 p-4 rounded-lg">
          <h3 className="text-gray-400 text-sm mb-2">Mining Status</h3>
          <div className={`font-semibold ${
            miningStatus?.is_mining ? 'text-green-400' : 'text-gray-400'
          }`}>
            {miningStatus?.is_mining ? 'ACTIVE' : 'STOPPED'}
          </div>
        </div>
      </div>

      {/* System Metrics */}
      {systemStats && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-gray-700 p-4 rounded-lg">
            <h3 className="text-gray-400 text-sm mb-2">CPU Usage</h3>
            <div className="text-blue-400 text-lg font-bold">
              {systemStats.cpu?.usage_percent?.toFixed(1) || '0.0'}%
            </div>
          </div>

          <div className="bg-gray-700 p-4 rounded-lg">
            <h3 className="text-gray-400 text-sm mb-2">Memory Usage</h3>
            <div className="text-yellow-400 text-lg font-bold">
              {systemStats.memory?.percent?.toFixed(1) || '0.0'}%
            </div>
          </div>

          <div className="bg-gray-700 p-4 rounded-lg">
            <h3 className="text-gray-400 text-sm mb-2">Disk Usage</h3>
            <div className="text-purple-400 text-lg font-bold">
              {systemStats.disk?.percent?.toFixed(1) || '0.0'}%
            </div>
          </div>
        </div>
      )}

      {/* Real-time Updates Indicator */}
      <div className="mt-4 p-3 bg-gray-700 rounded-lg">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-400">Real-time Updates:</span>
          <span className={`font-semibold ${
            socket ? 'text-green-400' : 'text-yellow-400'
          }`}>
            {socket ? 'WebSocket Active' : 'HTTP Polling'}
          </span>
        </div>
      </div>
    </div>
  );
};

export default RealtimeMetrics;