import React, { useState, useEffect } from 'react';
import axios from 'axios';

const CustomCoinManager = ({ onCoinAdded }) => {
  const [customCoins, setCustomCoins] = useState([]);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingCoin, setEditingCoin] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [validationErrors, setValidationErrors] = useState([]);

  const [formData, setFormData] = useState({
    id: '',
    name: '',
    symbol: '',
    algorithm: 'scrypt',
    block_time_target: 150,
    block_reward: 1,
    network_difficulty: 1000000,
    scrypt_params: {
      N: 1024,
      r: 1,
      p: 1
    },
    address_formats: [{
      type: 'standard',
      prefix: '',
      description: ''
    }],
    metadata: {
      description: '',
      website: '',
      blockchain_explorer: '',
      github_repository: ''
    }
  });

  const BACKEND_URL = process.env.REACT_APP_BACKEND_URL || 'http://localhost:8001';

  const fetchCustomCoins = useCallback(async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${BACKEND_URL}/api/coins/custom`);
      if (response.data.success) {
        setCustomCoins(response.data.coins);
      }
    } catch (error) {
      console.error('Error fetching custom coins:', error);
      setError('Failed to fetch custom coins');
    } finally {
      setLoading(false);
    }
  }, [BACKEND_URL]);

  useEffect(() => {
    fetchCustomCoins();
  }, [fetchCustomCoins]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    
    if (name.includes('.')) {
      // Handle nested objects
      const [parent, child] = name.split('.');
      setFormData(prev => ({
        ...prev,
        [parent]: {
          ...prev[parent],
          [child]: value
        }
      }));
    } else {
      setFormData(prev => ({
        ...prev,
        [name]: value
      }));
    }
  };

  const handleScryptParamChange = (param, value) => {
    setFormData(prev => ({
      ...prev,
      scrypt_params: {
        ...prev.scrypt_params,
        [param]: parseInt(value) || 1
      }
    }));
  };

  const handleAddressFormatChange = (index, field, value) => {
    setFormData(prev => ({
      ...prev,
      address_formats: prev.address_formats.map((format, i) =>
        i === index ? { ...format, [field]: value } : format
      )
    }));
  };

  const addAddressFormat = () => {
    setFormData(prev => ({
      ...prev,
      address_formats: [
        ...prev.address_formats,
        { type: 'standard', prefix: '', description: '' }
      ]
    }));
  };

  const removeAddressFormat = (index) => {
    setFormData(prev => ({
      ...prev,
      address_formats: prev.address_formats.filter((_, i) => i !== index)
    }));
  };

  const validateForm = async () => {
    try {
      const response = await axios.post(`${BACKEND_URL}/api/coins/custom/validate`, formData);
      if (response.data.valid) {
        setValidationErrors([]);
        return true;
      } else {
        setValidationErrors(response.data.errors || []);
        return false;
      }
    } catch (error) {
      console.error('Validation error:', error);
      setValidationErrors(['Validation service failed']);
      return false;
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validate form
    const isValid = await validateForm();
    if (!isValid) {
      return;
    }

    try {
      setLoading(true);
      setError('');

      if (editingCoin) {
        // Update existing coin
        const response = await axios.put(`${BACKEND_URL}/api/coins/custom/${editingCoin.id}`, formData);
        if (response.data.success) {
          await fetchCustomCoins();
          setEditingCoin(null);
          setShowAddForm(false);
          if (onCoinAdded) onCoinAdded();
        } else {
          setError(response.data.message || 'Failed to update coin');
        }
      } else {
        // Add new coin
        const response = await axios.post(`${BACKEND_URL}/api/coins/custom`, formData);
        if (response.data.success) {
          await fetchCustomCoins();
          setShowAddForm(false);
          resetForm();
          if (onCoinAdded) onCoinAdded();
        } else {
          setError(response.data.message || 'Failed to add coin');
        }
      }
    } catch (error) {
      console.error('Error submitting form:', error);
      setError(error.response?.data?.message || 'Failed to save coin');
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (coin) => {
    setEditingCoin(coin);
    setFormData({
      id: coin.id,
      name: coin.name,
      symbol: coin.symbol,
      algorithm: coin.algorithm,
      block_time_target: coin.block_time_target,
      block_reward: coin.block_reward,
      network_difficulty: coin.network_difficulty,
      scrypt_params: coin.scrypt_params,
      address_formats: coin.address_formats || [{ type: 'standard', prefix: '', description: '' }],
      metadata: coin.metadata || { description: '', website: '', blockchain_explorer: '', github_repository: '' }
    });
    setShowAddForm(true);
    setValidationErrors([]);
  };

  const handleDelete = async (coinId) => {
    if (!window.confirm('Are you sure you want to delete this custom coin?')) {
      return;
    }

    try {
      setLoading(true);
      const response = await axios.delete(`${BACKEND_URL}/api/coins/custom/${coinId}`);
      if (response.data.success) {
        await fetchCustomCoins();
        if (onCoinAdded) onCoinAdded();
      } else {
        setError(response.data.message || 'Failed to delete coin');
      }
    } catch (error) {
      console.error('Error deleting coin:', error);
      setError('Failed to delete coin');
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setFormData({
      id: '',
      name: '',
      symbol: '',
      algorithm: 'scrypt',
      block_time_target: 150,
      block_reward: 1,
      network_difficulty: 1000000,
      scrypt_params: {
        N: 1024,
        r: 1,
        p: 1
      },
      address_formats: [{
        type: 'standard',
        prefix: '',
        description: ''
      }],
      metadata: {
        description: '',
        website: '',
        blockchain_explorer: '',
        github_repository: ''
      }
    });
    setValidationErrors([]);
    setError('');
  };

  const handleCancel = () => {
    setShowAddForm(false);
    setEditingCoin(null);
    resetForm();
  };

  const exportCoins = async () => {
    try {
      const response = await axios.get(`${BACKEND_URL}/api/coins/custom/export`);
      const dataStr = JSON.stringify(response.data, null, 2);
      const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
      
      const exportFileDefaultName = 'custom_coins_export.json';
      const linkElement = document.createElement('a');
      linkElement.setAttribute('href', dataUri);
      linkElement.setAttribute('download', exportFileDefaultName);
      linkElement.click();
    } catch (error) {
      console.error('Export error:', error);
      setError('Failed to export coins');
    }
  };

  return (
    <div className="custom-coin-manager">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-lg font-semibold text-gray-800">Custom Coins</h3>
        <div className="flex gap-2">
          <button
            onClick={exportCoins}
            className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
          >
            Export
          </button>
          <button
            onClick={() => setShowAddForm(true)}
            className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600 transition-colors"
          >
            Add Custom Coin
          </button>
        </div>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
          {error}
        </div>
      )}

      {loading && (
        <div className="flex items-center justify-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
        </div>
      )}

      {/* Custom Coins List */}
      <div className="mb-6">
        {customCoins.length === 0 ? (
          <p className="text-gray-500 text-center py-8">No custom coins added yet.</p>
        ) : (
          <div className="grid gap-4">
            {customCoins.map((coin) => (
              <div key={coin.id} className="bg-white p-4 rounded-lg border shadow-sm">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full flex items-center justify-center text-white font-bold">
                      {coin.symbol}
                    </div>
                    <div>
                      <h4 className="font-semibold text-gray-800">{coin.name}</h4>
                      <p className="text-sm text-gray-600">
                        {coin.symbol} • {coin.algorithm} • Block: {coin.block_time_target}s
                      </p>
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleEdit(coin)}
                      className="px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600 transition-colors"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => handleDelete(coin.id)}
                      className="px-3 py-1 bg-red-500 text-white rounded text-sm hover:bg-red-600 transition-colors"
                    >
                      Delete
                    </button>
                  </div>
                </div>
                
                <div className="mt-3 grid grid-cols-3 gap-4 text-sm">
                  <div>
                    <span className="font-medium text-gray-600">Block Reward:</span>
                    <span className="ml-2">{coin.block_reward}</span>
                  </div>
                  <div>
                    <span className="font-medium text-gray-600">Difficulty:</span>
                    <span className="ml-2">{coin.network_difficulty.toLocaleString()}</span>
                  </div>
                  <div>
                    <span className="font-medium text-gray-600">Scrypt N:</span>
                    <span className="ml-2">{coin.scrypt_params.N}</span>
                  </div>
                </div>
                
                {coin.metadata?.description && (
                  <div className="mt-2 text-sm text-gray-600">
                    {coin.metadata.description}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Add/Edit Form */}
      {showAddForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-4xl max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-semibold mb-4">
              {editingCoin ? 'Edit Custom Coin' : 'Add Custom Coin'}
            </h3>

            {validationErrors.length > 0 && (
              <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
                <h4 className="font-semibold">Validation Errors:</h4>
                <ul className="list-disc list-inside mt-1">
                  {validationErrors.map((error, index) => (
                    <li key={index}>{error}</li>
                  ))}
                </ul>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Basic Information */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Coin ID *
                  </label>
                  <input
                    type="text"
                    name="id"
                    value={formData.id}
                    onChange={handleInputChange}
                    required
                    disabled={editingCoin}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                    placeholder="e.g., mycoin"
                  />
                  <p className="text-xs text-gray-500 mt-1">Lowercase letters, numbers, underscores, and hyphens only</p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Name *
                  </label>
                  <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="e.g., My Coin"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Symbol *
                  </label>
                  <input
                    type="text"
                    name="symbol"
                    value={formData.symbol}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="e.g., MYC"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Algorithm *
                  </label>
                  <select
                    name="algorithm"
                    value={formData.algorithm}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="scrypt">Scrypt</option>
                    <option value="scrypt-n">Scrypt-N</option>
                    <option value="scrypt-jane">Scrypt-Jane</option>
                  </select>
                </div>
              </div>

              {/* Mining Parameters */}
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Block Time Target (seconds) *
                  </label>
                  <input
                    type="number"
                    name="block_time_target"
                    value={formData.block_time_target}
                    onChange={handleInputChange}
                    required
                    min="1"
                    max="3600"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Block Reward *
                  </label>
                  <input
                    type="number"
                    name="block_reward"
                    value={formData.block_reward}
                    onChange={handleInputChange}
                    required
                    min="0.000001"
                    step="0.000001"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Network Difficulty *
                  </label>
                  <input
                    type="number"
                    name="network_difficulty"
                    value={formData.network_difficulty}
                    onChange={handleInputChange}
                    required
                    min="1"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              {/* Scrypt Parameters */}
              <div>
                <h4 className="text-md font-semibold text-gray-800 mb-3">Scrypt Parameters</h4>
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      N (CPU/Memory Cost) *
                    </label>
                    <input
                      type="number"
                      value={formData.scrypt_params.N}
                      onChange={(e) => handleScryptParamChange('N', e.target.value)}
                      required
                      min="1"
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <p className="text-xs text-gray-500 mt-1">Must be a power of 2</p>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      r (Block Size) *
                    </label>
                    <input
                      type="number"
                      value={formData.scrypt_params.r}
                      onChange={(e) => handleScryptParamChange('r', e.target.value)}
                      required
                      min="1"
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      p (Parallelization) *
                    </label>
                    <input
                      type="number"
                      value={formData.scrypt_params.p}
                      onChange={(e) => handleScryptParamChange('p', e.target.value)}
                      required
                      min="1"
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
              </div>

              {/* Address Formats */}
              <div>
                <h4 className="text-md font-semibold text-gray-800 mb-3">Address Formats</h4>
                {formData.address_formats.map((format, index) => (
                  <div key={index} className="grid grid-cols-4 gap-2 mb-2">
                    <select
                      value={format.type}
                      onChange={(e) => handleAddressFormatChange(index, 'type', e.target.value)}
                      className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="standard">Standard</option>
                      <option value="legacy">Legacy</option>
                      <option value="segwit">Segwit</option>
                      <option value="multisig">Multisig</option>
                    </select>
                    <input
                      type="text"
                      placeholder="Prefix (e.g., L)"
                      value={format.prefix}
                      onChange={(e) => handleAddressFormatChange(index, 'prefix', e.target.value)}
                      className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <input
                      type="text"
                      placeholder="Description"
                      value={format.description}
                      onChange={(e) => handleAddressFormatChange(index, 'description', e.target.value)}
                      className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <button
                      type="button"
                      onClick={() => removeAddressFormat(index)}
                      className="px-3 py-2 bg-red-500 text-white rounded hover:bg-red-600 transition-colors"
                    >
                      Remove
                    </button>
                  </div>
                ))}
                <button
                  type="button"
                  onClick={addAddressFormat}
                  className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
                >
                  Add Address Format
                </button>
              </div>

              {/* Metadata */}
              <div>
                <h4 className="text-md font-semibold text-gray-800 mb-3">Metadata (Optional)</h4>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Description
                    </label>
                    <textarea
                      name="metadata.description"
                      value={formData.metadata.description}
                      onChange={handleInputChange}
                      rows={3}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Brief description of the cryptocurrency"
                    />
                  </div>

                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Website
                      </label>
                      <input
                        type="url"
                        name="metadata.website"
                        value={formData.metadata.website}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="https://example.com"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Blockchain Explorer
                      </label>
                      <input
                        type="url"
                        name="metadata.blockchain_explorer"
                        value={formData.metadata.blockchain_explorer}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="https://explorer.example.com"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        GitHub Repository
                      </label>
                      <input
                        type="url"
                        name="metadata.github_repository"
                        value={formData.metadata.github_repository}
                        onChange={handleInputChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="https://github.com/user/repo"
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Form Actions */}
              <div className="flex justify-end gap-4 pt-4 border-t">
                <button
                  type="button"
                  onClick={handleCancel}
                  className="px-6 py-2 bg-gray-500 text-white rounded hover:bg-gray-600 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="px-6 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors disabled:opacity-50"
                >
                  {loading ? 'Saving...' : (editingCoin ? 'Update Coin' : 'Add Coin')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default CustomCoinManager;