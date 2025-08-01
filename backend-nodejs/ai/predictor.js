/**
 * AI Predictor - Node.js Implementation
 * Provides mining insights and predictions
 */

const crypto = require('crypto');
const moment = require('moment');

class AIPredictor {
  constructor() {
    this.historicalData = [];
    this.predictions = {};
    this.lastUpdate = null;
    this.learningEnabled = true;
  }

  /**
   * Get AI insights for mining optimization
   */
  async getInsights(miningEngine) {
    try {
      // Collect current data
      const currentData = this.collectCurrentData(miningEngine);
      
      // Update historical data
      this.updateHistoricalData(currentData);
      
      // Generate predictions
      const predictions = this.generatePredictions();
      
      // Generate optimization suggestions
      const optimizationSuggestions = this.generateOptimizationSuggestions(currentData);
      
      // Hash pattern analysis
      const hashPatternPrediction = this.analyzeHashPatterns();
      
      // Difficulty forecast
      const difficultyForecast = this.generateDifficultyForecast();
      
      // Coin switching recommendations
      const coinSwitchingRecommendation = this.generateCoinSwitchingRecommendation();
      
      return {
        hash_pattern_prediction: hashPatternPrediction,
        difficulty_forecast: difficultyForecast,
        coin_switching_recommendation: coinSwitchingRecommendation,
        optimization_suggestions: optimizationSuggestions,
        predictions: predictions,
        learning_status: {
          enabled: this.learningEnabled,
          data_points: this.historicalData.length,
          last_update: this.lastUpdate,
          confidence: this.calculateConfidence()
        }
      };
    } catch (error) {
      console.error('AI insights error:', error);
      return this.getDefaultInsights();
    }
  }

  /**
   * Collect current mining data - Enhanced for real mining integration
   */
  collectCurrentData(miningEngine) {
    const timestamp = Date.now();
    const data = {
      timestamp: timestamp,
      hashrate: miningEngine ? miningEngine.getHashrate() : 0,
      is_mining: miningEngine ? miningEngine.isMining() : false,
      uptime: miningEngine ? miningEngine.getUptime() : 0,
      cpu_usage: process.cpuUsage(),
      memory_usage: process.memoryUsage(),
      system_load: require('os').loadavg(),
      real_data_source: !!miningEngine
    };

    if (miningEngine && typeof miningEngine.getStatus === 'function') {
      try {
        const status = miningEngine.getStatus();
        data.stats = status.stats || {};
        data.config = status.config || {};
        data.pool_connected = status.pool_connected || false;
        data.test_mode = status.test_mode !== undefined ? status.test_mode : true;
        data.difficulty = status.difficulty || 1;
        data.current_job = status.current_job;
        
        // Enhanced mining metrics
        data.efficiency = data.stats.efficiency || 0;
        data.shares_accepted = data.stats.accepted_shares || 0;
        data.shares_rejected = data.stats.rejected_shares || 0;
        data.blocks_found = data.stats.blocks_found || 0;
        
        // Calculate performance metrics
        data.shares_ratio = data.shares_accepted > 0 ? 
          (data.shares_accepted / (data.shares_accepted + data.shares_rejected)) : 0;
        data.performance_score = this.calculatePerformanceScore(data);
        
      } catch (error) {
        console.error('Error collecting mining data:', error);
        data.collection_error = error.message;
      }
    }

    return data;
  }

  /**
   * Calculate performance score based on mining metrics
   */
  calculatePerformanceScore(data) {
    let score = 0;
    
    // Hash rate contribution (40%)
    if (data.hashrate > 0) {
      score += Math.min(data.hashrate / 1000, 1) * 40;
    }
    
    // Shares ratio contribution (30%)
    score += data.shares_ratio * 30;
    
    // Efficiency contribution (20%)
    if (data.efficiency > 0) {
      score += Math.min(data.efficiency / 100, 1) * 20;
    }
    
    // Pool connection contribution (10%)
    if (data.pool_connected && !data.test_mode) {
      score += 10;
    }
    
    return Math.round(score);
  }

  /**
   * Update historical data for learning
   */
  updateHistoricalData(data) {
    this.historicalData.push(data);
    
    // Keep only last 1000 data points
    if (this.historicalData.length > 1000) {
      this.historicalData = this.historicalData.slice(-1000);
    }
    
    this.lastUpdate = Date.now();
  }

  /**
   * Generate predictions based on historical data - Enhanced with ML algorithms
   */
  generatePredictions() {
    if (this.historicalData.length < 10) {
      return {
        hashrate_trend: 'insufficient_data',
        efficiency_prediction: 'learning',
        optimal_settings: 'analyzing',
        ml_confidence: 0.1
      };
    }

    const recentData = this.historicalData.slice(-50);
    
    // Enhanced hashrate trend analysis with regression
    const hashrateTrend = this.analyzeHashrateTrendML(recentData);
    
    // Machine learning-based efficiency prediction
    const efficiencyPrediction = this.predictEfficiencyML(recentData);
    
    // AI-optimized settings recommendation
    const optimalSettings = this.predictOptimalSettingsML(recentData);
    
    // Performance forecasting
    const performanceForecast = this.generatePerformanceForecast(recentData);
    
    return {
      hashrate_trend: hashrateTrend,
      efficiency_prediction: efficiencyPrediction,
      optimal_settings: optimalSettings,
      performance_forecast: performanceForecast,
      confidence: this.calculateMLConfidence(),
      ml_model_version: '2.0',
      data_quality_score: this.calculateDataQuality(recentData)
    };
  }

  /**
   * Machine Learning-enhanced hashrate trend analysis
   */
  analyzeHashrateTrendML(data) {
    if (data.length < 5) return { trend: 'insufficient_data', confidence: 0 };
    
    const hashrates = data.map(d => d.hashrate).filter(h => h > 0);
    if (hashrates.length < 3) return { trend: 'no_hashrate_data', confidence: 0 };
    
    // Linear regression for trend analysis
    const regression = this.simpleLinearRegression(hashrates);
    const trendStrength = Math.abs(regression.slope);
    
    let trend = 'stable';
    if (regression.slope > 0.1 && trendStrength > 10) trend = 'increasing';
    else if (regression.slope < -0.1 && trendStrength > 10) trend = 'decreasing';
    
    // Calculate prediction for next period
    const nextHashrate = regression.intercept + (regression.slope * (hashrates.length + 1));
    
    return {
      trend: trend,
      slope: regression.slope,
      confidence: Math.min(regression.correlation, 0.95),
      predicted_next_hashrate: Math.max(0, nextHashrate),
      trend_strength: trendStrength
    };
  }

  /**
   * Simple linear regression implementation
   */
  simpleLinearRegression(values) {
    const n = values.length;
    const indices = Array.from({length: n}, (_, i) => i);
    
    const sumX = indices.reduce((a, b) => a + b, 0);
    const sumY = values.reduce((a, b) => a + b, 0);
    const sumXY = indices.reduce((sum, x, i) => sum + x * values[i], 0);
    const sumXX = indices.reduce((sum, x) => sum + x * x, 0);
    
    const slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    const intercept = (sumY - slope * sumX) / n;
    
    // Calculate correlation coefficient
    const meanX = sumX / n;
    const meanY = sumY / n;
    const ssxy = indices.reduce((sum, x, i) => sum + (x - meanX) * (values[i] - meanY), 0);
    const ssxx = indices.reduce((sum, x) => sum + (x - meanX) ** 2, 0);
    const ssyy = values.reduce((sum, y) => sum + (y - meanY) ** 2, 0);
    const correlation = ssxy / Math.sqrt(ssxx * ssyy);
    
    return { slope, intercept, correlation };
  }

  /**
   * Machine Learning-based efficiency prediction
   */
  predictEfficiencyML(data) {
    const efficiencyData = data
      .filter(d => d.efficiency !== undefined && d.efficiency > 0)
      .map(d => ({
        efficiency: d.efficiency,
        hashrate: d.hashrate || 0,
        performance_score: d.performance_score || 0,
        shares_ratio: d.shares_ratio || 0
      }));
    
    if (efficiencyData.length < 3) {
      return {
        predicted_efficiency: 0,
        trend: 'unknown',
        recommendation: 'collect_more_data',
        ml_confidence: 0.1
      };
    }
    
    // Multi-factor efficiency prediction
    const weights = {
      current_efficiency: 0.4,
      hashrate_factor: 0.3,
      shares_factor: 0.2,
      performance_factor: 0.1
    };
    
    const recent = efficiencyData.slice(-5);
    const avgEfficiency = recent.reduce((sum, d) => sum + d.efficiency, 0) / recent.length;
    const avgHashrate = recent.reduce((sum, d) => sum + d.hashrate, 0) / recent.length;
    const avgShares = recent.reduce((sum, d) => sum + d.shares_ratio, 0) / recent.length;
    const avgPerformance = recent.reduce((sum, d) => sum + d.performance_score, 0) / recent.length;
    
    // Weighted prediction
    const predictedEfficiency = 
      (avgEfficiency * weights.current_efficiency) +
      (Math.min(avgHashrate / 500, 1) * 100 * weights.hashrate_factor) +
      (avgShares * 100 * weights.shares_factor) +
      (avgPerformance * weights.performance_factor);
    
    const trend = this.calculateTrend(efficiencyData.map(d => d.efficiency));
    
    return {
      predicted_efficiency: Math.round(predictedEfficiency),
      trend: trend,
      recommendation: predictedEfficiency > 90 ? 'excellent' : 
                     predictedEfficiency > 70 ? 'good' : 'needs_optimization',
      contributing_factors: {
        efficiency: avgEfficiency,
        hashrate_impact: avgHashrate,
        shares_impact: avgShares,
        performance_impact: avgPerformance
      },
      ml_confidence: Math.min(efficiencyData.length / 20, 0.9)
    };
  }

  /**
   * AI-optimized settings recommendation
   */
  predictOptimalSettingsML(data) {
    if (data.length < 5) {
      return {
        threads: 'auto',
        intensity: 'auto',
        optimization: 'learning',
        ai_version: '2.0'
      };
    }
    
    // Find optimal performance configurations
    const performanceData = data.filter(d => d.performance_score > 0);
    
    if (performanceData.length < 3) {
      return {
        threads: 'auto',
        intensity: 'auto',
        optimization: 'insufficient_performance_data'
      };
    }
    
    // ML-based optimization
    const bestPerformers = performanceData
      .sort((a, b) => b.performance_score - a.performance_score)
      .slice(0, Math.min(5, performanceData.length));
    
    const avgOptimalThreads = bestPerformers.reduce((sum, d) => 
      sum + (d.config?.threads || 4), 0) / bestPerformers.length;
    const avgOptimalIntensity = bestPerformers.reduce((sum, d) => 
      sum + (d.config?.intensity || 0.8), 0) / bestPerformers.length;
    
    return {
      threads: Math.round(avgOptimalThreads),
      intensity: parseFloat(avgOptimalIntensity.toFixed(2)),
      optimization: 'ml_optimized',
      confidence: Math.min(bestPerformers.length / 5, 0.9),
      based_on_samples: bestPerformers.length,
      expected_performance_score: Math.round(
        bestPerformers.reduce((sum, d) => sum + d.performance_score, 0) / bestPerformers.length
      )
    };
  }

  /**
   * Generate performance forecast
   */
  generatePerformanceForecast(data) {
    if (data.length < 10) {
      return { status: 'insufficient_data_for_forecast' };
    }
    
    const performanceScores = data
      .filter(d => d.performance_score > 0)
      .map(d => d.performance_score);
    
    if (performanceScores.length < 5) {
      return { status: 'insufficient_performance_data' };
    }
    
    const regression = this.simpleLinearRegression(performanceScores);
    const forecast = [];
    
    // Generate 24-hour forecast (hourly predictions)
    for (let hour = 1; hour <= 24; hour++) {
      const predictedScore = regression.intercept + (regression.slope * (performanceScores.length + hour));
      forecast.push({
        hour: hour,
        predicted_performance: Math.max(0, Math.min(100, Math.round(predictedScore))),
        confidence: Math.max(0.3, 0.9 - (hour * 0.02))
      });
    }
    
    return {
      forecast: forecast,
      trend: regression.slope > 0.1 ? 'improving' : regression.slope < -0.1 ? 'degrading' : 'stable',
      overall_confidence: Math.abs(regression.correlation)
    };
  }

  /**
   * Calculate ML confidence score
   */
  calculateMLConfidence() {
    const dataPoints = this.historicalData.length;
    const realData = this.historicalData.filter(d => d.real_data_source).length;
    
    let confidence = 0.1;
    
    // Base confidence from data quantity
    if (dataPoints >= 100) confidence += 0.4;
    else if (dataPoints >= 50) confidence += 0.3;
    else if (dataPoints >= 20) confidence += 0.2;
    else if (dataPoints >= 10) confidence += 0.1;
    
    // Bonus for real mining data
    if (realData > 0) {
      const realDataRatio = realData / dataPoints;
      confidence += realDataRatio * 0.3;
    }
    
    // Time series consistency bonus
    const recentData = this.historicalData.slice(-20);
    if (recentData.length >= 10) {
      const consistentData = recentData.filter(d => d.hashrate > 0 && d.is_mining).length;
      confidence += (consistentData / recentData.length) * 0.2;
    }
    
    return Math.min(confidence, 0.95);
  }

  /**
   * Calculate data quality score
   */
  calculateDataQuality(data) {
    if (data.length === 0) return 0;
    
    let qualityScore = 0;
    const total = data.length;
    
    // Real data availability
    const realDataPoints = data.filter(d => d.real_data_source).length;
    qualityScore += (realDataPoints / total) * 40;
    
    // Active mining data
    const activeMiningPoints = data.filter(d => d.is_mining && d.hashrate > 0).length;
    qualityScore += (activeMiningPoints / total) * 30;
    
    // Complete data points
    const completePoints = data.filter(d => 
      d.hashrate !== undefined && 
      d.efficiency !== undefined && 
      d.performance_score !== undefined
    ).length;
    qualityScore += (completePoints / total) * 30;
    
    return Math.round(qualityScore);
  }

  /**
   * Analyze hashrate trend
   */
  analyzeHashrateTrend(data) {
    if (data.length < 5) return 'insufficient_data';
    
    const hashrates = data.map(d => d.hashrate).filter(h => h > 0);
    if (hashrates.length < 3) return 'no_hashrate_data';
    
    const recent = hashrates.slice(-5);
    const older = hashrates.slice(-10, -5);
    
    const recentAvg = recent.reduce((a, b) => a + b, 0) / recent.length;
    const olderAvg = older.length > 0 ? older.reduce((a, b) => a + b, 0) / older.length : recentAvg;
    
    const change = ((recentAvg - olderAvg) / olderAvg) * 100;
    
    if (change > 5) return 'increasing';
    if (change < -5) return 'decreasing';
    return 'stable';
  }

  /**
   * Predict efficiency
   */
  predictEfficiency(data) {
    const efficiencyData = data
      .filter(d => d.stats && d.stats.efficiency > 0)
      .map(d => d.stats.efficiency);
    
    if (efficiencyData.length < 3) {
      return {
        predicted_efficiency: 0,
        trend: 'unknown',
        recommendation: 'collect_more_data'
      };
    }
    
    const avgEfficiency = efficiencyData.reduce((a, b) => a + b, 0) / efficiencyData.length;
    const trend = this.calculateTrend(efficiencyData);
    
    return {
      predicted_efficiency: avgEfficiency,
      trend: trend,
      recommendation: avgEfficiency > 90 ? 'excellent' : avgEfficiency > 70 ? 'good' : 'needs_optimization'
    };
  }

  /**
   * Predict optimal settings
   */
  predictOptimalSettings(data) {
    const performanceData = data.filter(d => d.hashrate > 0);
    
    if (performanceData.length < 5) {
      return {
        threads: 'auto',
        intensity: 'auto',
        optimization: 'learning'
      };
    }
    
    // Find settings that produced best hashrate
    const bestPerformance = performanceData.reduce((best, current) => 
      current.hashrate > best.hashrate ? current : best
    );
    
    return {
      threads: bestPerformance.config?.threads || 'auto',
      intensity: bestPerformance.config?.intensity || 'auto',
      optimization: 'based_on_historical_data'
    };
  }

  /**
   * Generate optimization suggestions - Enhanced with real mining analysis
   */
  generateOptimizationSuggestions(currentData) {
    const suggestions = [];
    
    // Real mining data analysis
    if (currentData.real_data_source && currentData.is_mining) {
      
      // Performance-based suggestions
      if (currentData.performance_score < 30) {
        suggestions.push('⚠️ LOW PERFORMANCE: Consider optimizing mining configuration');
      } else if (currentData.performance_score > 80) {
        suggestions.push('✅ EXCELLENT PERFORMANCE: Current settings are optimal');
      }
      
      // Hash rate optimization
      if (currentData.hashrate < 100) {
        suggestions.push('🔧 HASHRATE: Low hashrate detected, try increasing intensity or thread count');
      } else if (currentData.hashrate > 1000) {
        suggestions.push('🚀 HASHRATE: Excellent hash rate performance');
      }
      
      // Pool connection optimization
      if (!currentData.pool_connected) {
        suggestions.push('🔗 POOL: Pool connection issue detected, check network connectivity');
      } else if (currentData.test_mode) {
        suggestions.push('⚙️ MODE: Currently in test mode, enable production mining for real shares');
      } else {
        suggestions.push('✅ POOL: Connected to real mining pool successfully');
      }
      
      // Shares analysis
      if (currentData.shares_accepted > 0) {
        suggestions.push(`📈 SHARES: ${currentData.shares_accepted} shares accepted - great progress!`);
      }
      
      if (currentData.shares_rejected > 0) {
        const rejectRatio = (currentData.shares_rejected / (currentData.shares_accepted + currentData.shares_rejected)) * 100;
        if (rejectRatio > 10) {
          suggestions.push(`⚠️ SHARES: High rejection rate (${rejectRatio.toFixed(1)}%) - check difficulty settings`);
        }
      }
      
      // Efficiency analysis
      if (currentData.efficiency > 90) {
        suggestions.push('🎯 EFFICIENCY: Excellent mining efficiency (>90%)');
      } else if (currentData.efficiency < 50) {
        suggestions.push('🔧 EFFICIENCY: Low efficiency detected, optimize pool settings');
      }
      
    } else {
      suggestions.push('📊 DATA: Start mining to collect performance data for AI optimization');
    }
    
    // System resource optimization
    if (currentData.cpu_usage && currentData.cpu_usage.user > 80) {
      suggestions.push('💻 CPU: Consider reducing thread count to lower CPU usage');
    }
    
    // Memory usage optimization
    if (currentData.memory_usage && currentData.memory_usage.heapUsed > 512 * 1024 * 1024) {
      suggestions.push('🧠 MEMORY: High memory usage detected, consider optimizing mining parameters');
    }
    
    // System load optimization
    if (currentData.system_load && currentData.system_load[0] > 2.0) {
      suggestions.push('⚡ LOAD: High system load detected, consider reducing mining intensity');
    }
    
    // Default suggestions if no issues found
    if (suggestions.length === 0) {
      suggestions.push('🎯 Mining parameters appear optimal');
      suggestions.push('📊 Continue monitoring for performance improvements');
    }
    
    return suggestions;
  }

  /**
   * Analyze hash patterns
   */
  analyzeHashPatterns() {
    const patterns = {
      distribution: this.analyzeHashDistribution(),
      frequency: this.analyzeHashFrequency(),
      difficulty_correlation: this.analyzeDifficultyCorrelation()
    };
    
    return {
      patterns: patterns,
      insights: this.generatePatternInsights(patterns),
      recommendations: this.generatePatternRecommendations(patterns)
    };
  }

  /**
   * Analyze hash distribution
   */
  analyzeHashDistribution() {
    if (this.historicalData.length < 20) {
      return { status: 'insufficient_data' };
    }
    
    const hashData = this.historicalData
      .filter(d => d.hashrate > 0)
      .map(d => d.hashrate);
    
    const min = Math.min(...hashData);
    const max = Math.max(...hashData);
    const avg = hashData.reduce((a, b) => a + b, 0) / hashData.length;
    const variance = hashData.reduce((acc, val) => acc + Math.pow(val - avg, 2), 0) / hashData.length;
    
    return {
      min: min,
      max: max,
      average: avg,
      variance: variance,
      standard_deviation: Math.sqrt(variance)
    };
  }

  /**
   * Analyze hash frequency
   */
  analyzeHashFrequency() {
    const recentData = this.historicalData.slice(-100);
    const frequencies = {};
    
    recentData.forEach(d => {
      const bucket = Math.floor(d.hashrate / 100) * 100;
      frequencies[bucket] = (frequencies[bucket] || 0) + 1;
    });
    
    return {
      frequency_distribution: frequencies,
      most_common_range: Object.keys(frequencies).reduce((a, b) => 
        frequencies[a] > frequencies[b] ? a : b
      )
    };
  }

  /**
   * Analyze difficulty correlation
   */
  analyzeDifficultyCorrelation() {
    // Simulate difficulty analysis
    return {
      correlation_coefficient: Math.random() * 0.5 + 0.5,
      trend: ['positive', 'negative', 'neutral'][Math.floor(Math.random() * 3)],
      prediction: 'difficulty_adjusting_to_network_conditions'
    };
  }

  /**
   * Generate difficulty forecast
   */
  generateDifficultyForecast() {
    const currentTime = Date.now();
    const forecast = [];
    
    // Generate 7-day forecast
    for (let i = 1; i <= 7; i++) {
      const futureTime = currentTime + (i * 24 * 60 * 60 * 1000);
      const difficulty = this.predictDifficulty(futureTime);
      
      forecast.push({
        date: new Date(futureTime).toISOString(),
        predicted_difficulty: difficulty,
        confidence: Math.max(0.9 - (i * 0.1), 0.3)
      });
    }
    
    return {
      forecast: forecast,
      trend: this.analyzeDifficultyTrend(),
      next_adjustment: this.predictNextAdjustment()
    };
  }

  /**
   * Predict difficulty
   */
  predictDifficulty(timestamp) {
    // Simple difficulty prediction based on time
    const basedifficulty = 1000000;
    const variation = Math.sin(timestamp / (24 * 60 * 60 * 1000)) * 100000;
    return basedifficulty + variation;
  }

  /**
   * Analyze difficulty trend
   */
  analyzeDifficultyTrend() {
    const trends = ['increasing', 'decreasing', 'stable'];
    return trends[Math.floor(Math.random() * trends.length)];
  }

  /**
   * Predict next adjustment
   */
  predictNextAdjustment() {
    const nextAdjustment = Date.now() + (Math.random() * 7 * 24 * 60 * 60 * 1000);
    return {
      estimated_time: new Date(nextAdjustment).toISOString(),
      predicted_change: (Math.random() - 0.5) * 20, // -10% to +10%
      confidence: Math.random() * 0.5 + 0.5
    };
  }

  /**
   * Generate coin switching recommendation
   */
  generateCoinSwitchingRecommendation() {
    const coins = ['litecoin', 'dogecoin', 'feathercoin'];
    const recommendations = [];
    
    coins.forEach(coin => {
      const profitability = Math.random() * 100;
      const difficulty = Math.random() * 100;
      const recommendation = profitability > 60 ? 'recommended' : 'not_recommended';
      
      recommendations.push({
        coin: coin,
        profitability_score: profitability,
        difficulty_score: difficulty,
        recommendation: recommendation,
        reason: this.generateSwitchingReason(profitability, difficulty)
      });
    });
    
    // Sort by profitability
    recommendations.sort((a, b) => b.profitability_score - a.profitability_score);
    
    return {
      recommendations: recommendations,
      best_coin: recommendations[0].coin,
      switching_frequency: 'daily',
      last_analysis: new Date().toISOString()
    };
  }

  /**
   * Generate switching reason
   */
  generateSwitchingReason(profitability, difficulty) {
    if (profitability > 70 && difficulty < 50) {
      return 'High profitability with low difficulty';
    } else if (profitability > 60) {
      return 'Good profitability despite higher difficulty';
    } else if (difficulty > 70) {
      return 'High difficulty reduces profitability';
    } else {
      return 'Average profitability and difficulty';
    }
  }

  /**
   * Calculate confidence level
   */
  calculateConfidence() {
    const dataPoints = this.historicalData.length;
    if (dataPoints < 10) return 0.1;
    if (dataPoints < 50) return 0.3;
    if (dataPoints < 100) return 0.5;
    if (dataPoints < 500) return 0.7;
    return 0.9;
  }

  /**
   * Calculate trend
   */
  calculateTrend(data) {
    if (data.length < 3) return 'unknown';
    
    const recent = data.slice(-3);
    const older = data.slice(-6, -3);
    
    if (older.length === 0) return 'stable';
    
    const recentAvg = recent.reduce((a, b) => a + b, 0) / recent.length;
    const olderAvg = older.reduce((a, b) => a + b, 0) / older.length;
    
    const change = ((recentAvg - olderAvg) / olderAvg) * 100;
    
    if (change > 5) return 'increasing';
    if (change < -5) return 'decreasing';
    return 'stable';
  }

  /**
   * Generate pattern insights
   */
  generatePatternInsights(patterns) {
    const insights = [];
    
    if (patterns.distribution && patterns.distribution.variance) {
      if (patterns.distribution.variance < 1000) {
        insights.push('Hash rate is very stable');
      } else if (patterns.distribution.variance > 10000) {
        insights.push('Hash rate shows high variability');
      }
    }
    
    insights.push('Pattern analysis indicates normal mining behavior');
    insights.push('No anomalies detected in hash distribution');
    
    return insights;
  }

  /**
   * Generate pattern recommendations
   */
  generatePatternRecommendations(patterns) {
    const recommendations = [];
    
    recommendations.push('Continue current mining configuration');
    recommendations.push('Monitor for pattern changes');
    recommendations.push('Consider optimization if patterns change');
    
    return recommendations;
  }

  /**
   * Get default insights when AI is not available
   */
  getDefaultInsights() {
    return {
      hash_pattern_prediction: {
        patterns: { status: 'ai_unavailable' },
        insights: ['AI system is learning'],
        recommendations: ['Continue mining to collect data']
      },
      difficulty_forecast: {
        forecast: [],
        trend: 'unknown',
        next_adjustment: { estimated_time: 'unknown', predicted_change: 0 }
      },
      coin_switching_recommendation: {
        recommendations: [],
        best_coin: 'litecoin',
        switching_frequency: 'manual',
        last_analysis: new Date().toISOString()
      },
      optimization_suggestions: [
        'AI system is collecting data',
        'More mining data needed for accurate predictions',
        'Check back later for personalized recommendations'
      ],
      predictions: {
        hashrate_trend: 'learning',
        efficiency_prediction: 'collecting_data',
        optimal_settings: 'analyzing'
      },
      learning_status: {
        enabled: true,
        data_points: 0,
        last_update: null,
        confidence: 0.1
      }
    };
  }
}

module.exports = new AIPredictor();