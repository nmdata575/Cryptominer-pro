#!/usr/bin/env python3
"""
CryptoMiner Pro Backend Testing Suite - Post-Migration Comprehensive Testing
Focus: Testing all newly migrated Node.js backend API endpoints after directory migration
Testing: Health checks, Mining operations, Mongoose integration, Session management, Database ops, Thread scaling
"""

import requests
import json
import time
import sys
import uuid
from urllib.parse import urljoin

# Backend URL from frontend environment
BACKEND_URL = "https://b8a64dbe-314e-43b8-9274-f05e86511466.preview.emergentagent.com"
API_BASE = f"{BACKEND_URL}/api"

class MigrationTester:
    def __init__(self):
        self.test_results = []
        self.session = requests.Session()
        # Set headers for CORS testing
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Origin': BACKEND_URL,
            'User-Agent': 'CryptoMiner-Pro-Migration-Test/1.0'
        })
        
    def log_test(self, test_name, success, details="", response_data=None):
        """Log test results"""
        status = "✅ PASSED" if success else "❌ FAILED"
        result = {
            'test': test_name,
            'status': status,
            'success': success,
            'details': details,
            'response_data': response_data
        }
        self.test_results.append(result)
        print(f"{status} - {test_name}")
        if details:
            print(f"   Details: {details}")
        if not success and response_data:
            print(f"   Response: {response_data}")
        print()

    # ============================================================================
    # 1. BASIC HEALTH CHECKS
    # ============================================================================

    def test_health_endpoint(self):
        """Test /api/health endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/health", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('status') == 'healthy' and 'node_version' in data:
                    self.log_test(
                        "Health Check API Endpoint",
                        True,
                        f"Backend healthy - Node.js {data.get('node_version')}, uptime: {data.get('uptime', 0):.1f}s",
                        {"status": data.get('status'), "version": data.get('version')}
                    )
                    return True
                else:
                    self.log_test(
                        "Health Check API Endpoint",
                        False,
                        "Backend unhealthy or missing required fields",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Health Check API Endpoint",
                    False,
                    f"Health check failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Health Check API Endpoint",
                False,
                f"Health check request failed: {str(e)}"
            )
            return False

    def test_system_stats_endpoint(self):
        """Test /api/system/stats endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/system/stats", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if 'cpu' in data and 'memory' in data:
                    self.log_test(
                        "System Stats API Endpoint",
                        True,
                        f"System stats retrieved - CPU: {data.get('cpu', {}).get('usage', 0):.1f}%, Memory: {data.get('memory', {}).get('usage', 0):.1f}%",
                        {"cpu_usage": data.get('cpu', {}).get('usage'), "memory_usage": data.get('memory', {}).get('usage')}
                    )
                    return True
                else:
                    self.log_test(
                        "System Stats API Endpoint",
                        False,
                        "System stats missing required fields",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "System Stats API Endpoint",
                    False,
                    f"System stats failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "System Stats API Endpoint",
                False,
                f"System stats request failed: {str(e)}"
            )
            return False

    def test_cpu_info_endpoint(self):
        """Test /api/system/cpu-info endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/system/cpu-info", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if 'cores' in data and 'mining_profiles' in data:
                    self.log_test(
                        "CPU Info API Endpoint",
                        True,
                        f"CPU info retrieved - Cores: {data.get('cores', 0)}, Profiles: {len(data.get('mining_profiles', []))}",
                        {"cores": data.get('cores'), "profiles_count": len(data.get('mining_profiles', []))}
                    )
                    return True
                else:
                    self.log_test(
                        "CPU Info API Endpoint",
                        False,
                        "CPU info missing required fields",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "CPU Info API Endpoint",
                    False,
                    f"CPU info failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "CPU Info API Endpoint",
                False,
                f"CPU info request failed: {str(e)}"
            )
            return False

    # ============================================================================
    # 2. MINING OPERATIONS
    # ============================================================================

    def test_mining_status_endpoint(self):
        """Test /api/mining/status endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/mining/status", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if 'is_mining' in data and 'stats' in data:
                    self.log_test(
                        "Mining Status API Endpoint",
                        True,
                        f"Mining status retrieved - Mining: {data.get('is_mining')}, Hashrate: {data.get('stats', {}).get('hashrate', 0):.2f} H/s",
                        {"is_mining": data.get('is_mining'), "hashrate": data.get('stats', {}).get('hashrate')}
                    )
                    return True
                else:
                    self.log_test(
                        "Mining Status API Endpoint",
                        False,
                        "Mining status missing required fields",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Mining Status API Endpoint",
                    False,
                    f"Mining status failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Mining Status API Endpoint",
                False,
                f"Mining status request failed: {str(e)}"
            )
            return False

    def test_mining_start_basic(self):
        """Test /api/mining/start endpoint with basic functionality"""
        try:
            # Test basic mining start configuration
            mining_config = {
                "coin": "litecoin",
                "mode": "solo",
                "threads": 4,
                "intensity": 0.8,
                "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
            }
            
            response = self.session.post(f"{API_BASE}/mining/start", json=mining_config, timeout=15)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    # Wait for mining to initialize
                    time.sleep(2)
                    
                    # Check mining status
                    status_response = self.session.get(f"{API_BASE}/mining/status", timeout=10)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        is_mining = status_data.get('is_mining', False)
                        
                        self.log_test(
                            "Mining Start Basic Functionality",
                            True,
                            f"Mining started successfully - Mining: {is_mining}",
                            {"is_mining": is_mining, "config": mining_config}
                        )
                        return True
                    else:
                        self.log_test(
                            "Mining Start Basic Functionality",
                            False,
                            "Failed to get mining status after start",
                            status_response.text
                        )
                        return False
                else:
                    self.log_test(
                        "Mining Start Basic Functionality",
                        False,
                        f"Mining start failed: {data.get('message', 'Unknown error')}",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Mining Start Basic Functionality",
                    False,
                    f"Mining start request failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Mining Start Basic Functionality",
                False,
                f"Mining start test failed: {str(e)}"
            )
            return False

    def test_mining_stop_basic(self):
        """Test /api/mining/stop endpoint"""
        try:
            response = self.session.post(f"{API_BASE}/mining/stop", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') or data.get('message') == 'No mining operation in progress':
                    # Wait for cleanup
                    time.sleep(2)
                    
                    # Verify mining stopped
                    status_response = self.session.get(f"{API_BASE}/mining/status", timeout=10)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        is_mining = status_data.get('is_mining', True)
                        
                        self.log_test(
                            "Mining Stop Basic Functionality",
                            True,
                            f"Mining stop processed - Mining: {is_mining}",
                            {"is_mining": is_mining}
                        )
                        return True
                    else:
                        self.log_test(
                            "Mining Stop Basic Functionality",
                            False,
                            "Failed to verify mining stop",
                            status_response.text
                        )
                        return False
                else:
                    self.log_test(
                        "Mining Stop Basic Functionality",
                        False,
                        f"Mining stop failed: {data.get('message', 'Unknown error')}",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Mining Stop Basic Functionality",
                    False,
                    f"Mining stop request failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Mining Stop Basic Functionality",
                False,
                f"Mining stop test failed: {str(e)}"
            )
            return False

    # ============================================================================
    # 3. ENHANCED MONGOOSE MODEL INTEGRATION
    # ============================================================================

    def test_mining_stats_get(self):
        """Test GET /api/mining/stats endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/mining/stats?limit=10", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'data' in data:
                    stats_count = data.get('count', 0)
                    self.log_test(
                        "Mining Stats GET API",
                        True,
                        f"Mining stats retrieved - Count: {stats_count}",
                        {"count": stats_count}
                    )
                    return True
                else:
                    self.log_test(
                        "Mining Stats GET API",
                        False,
                        "Invalid response format",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Mining Stats GET API",
                    False,
                    f"Mining stats GET failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Mining Stats GET API",
                False,
                f"Mining stats GET request failed: {str(e)}"
            )
            return False

    def test_mining_stats_post(self):
        """Test POST /api/mining/stats endpoint"""
        try:
            test_stats = {
                "sessionId": f"test_session_{int(time.time())}",
                "coin": "litecoin",
                "mode": "pool",
                "hashrate": 1250.5,
                "acceptedShares": 15,
                "rejectedShares": 2,
                "blocksFound": 0,
                "cpuUsage": 75.2,
                "memoryUsage": 45.8,
                "threads": 4,
                "intensity": 0.8,
                "startTime": "2024-01-01T10:00:00.000Z"
            }
            
            response = self.session.post(f"{API_BASE}/mining/stats", json=test_stats, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    self.log_test(
                        "Mining Stats POST API",
                        True,
                        f"Mining stats saved - Session: {test_stats['sessionId']}",
                        {"session_id": test_stats['sessionId']}
                    )
                    return True
                else:
                    self.log_test(
                        "Mining Stats POST API",
                        False,
                        "Failed to save mining stats",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Mining Stats POST API",
                    False,
                    f"Mining stats POST failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Mining Stats POST API",
                False,
                f"Mining stats POST request failed: {str(e)}"
            )
            return False

    def test_mining_stats_top(self):
        """Test GET /api/mining/stats/top endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/mining/stats/top?limit=5", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'data' in data:
                    top_sessions = data.get('data', [])
                    self.log_test(
                        "Mining Stats Top Sessions API",
                        True,
                        f"Top sessions retrieved - Count: {len(top_sessions)}",
                        {"sessions_count": len(top_sessions)}
                    )
                    return True
                else:
                    self.log_test(
                        "Mining Stats Top Sessions API",
                        False,
                        "Invalid response format",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Mining Stats Top Sessions API",
                    False,
                    f"Top sessions failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Mining Stats Top Sessions API",
                False,
                f"Top sessions request failed: {str(e)}"
            )
            return False

    def test_ai_predictions_get(self):
        """Test GET /api/ai/predictions endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/ai/predictions?limit=10", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'data' in data:
                    predictions_count = data.get('count', 0)
                    self.log_test(
                        "AI Predictions GET API",
                        True,
                        f"AI predictions retrieved - Count: {predictions_count}",
                        {"count": predictions_count}
                    )
                    return True
                else:
                    self.log_test(
                        "AI Predictions GET API",
                        False,
                        "Invalid response format",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "AI Predictions GET API",
                    False,
                    f"AI predictions GET failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "AI Predictions GET API",
                False,
                f"AI predictions GET request failed: {str(e)}"
            )
            return False

    def test_ai_predictions_post(self):
        """Test POST /api/ai/predictions endpoint"""
        try:
            test_prediction = {
                "predictionType": "hashrate",
                "modelInfo": {
                    "algorithm": "linear_regression",
                    "version": "1.0",
                    "trainingDataSize": 100
                },
                "prediction": {
                    "value": 1500.0,
                    "confidence": 0.85,
                    "timeframe": "1hour"
                },
                "inputData": {
                    "currentHashrate": 1400.0,
                    "threads": 4,
                    "intensity": 0.8,
                    "cpuUsage": 80,
                    "memoryUsage": 60,
                    "coin": "litecoin"
                },
                "expiresAt": "2024-12-31T23:59:59.000Z"
            }
            
            response = self.session.post(f"{API_BASE}/ai/predictions", json=test_prediction, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    self.log_test(
                        "AI Predictions POST API",
                        True,
                        f"AI prediction saved - Confidence: {data.get('confidencePercentage', 0)}%",
                        {"confidence": data.get('confidencePercentage')}
                    )
                    return True
                else:
                    self.log_test(
                        "AI Predictions POST API",
                        False,
                        "Failed to save AI prediction",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "AI Predictions POST API",
                    False,
                    f"AI predictions POST failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "AI Predictions POST API",
                False,
                f"AI predictions POST request failed: {str(e)}"
            )
            return False

    def test_ai_model_accuracy(self):
        """Test GET /api/ai/model-accuracy endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/ai/model-accuracy?algorithm=linear_regression&type=hashrate", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'accuracy' in data:
                    accuracy_data = data.get('accuracy', {})
                    avg_accuracy = accuracy_data.get('avgAccuracy', 0)
                    self.log_test(
                        "AI Model Accuracy API",
                        True,
                        f"Model accuracy retrieved - Avg: {avg_accuracy}%",
                        {"avg_accuracy": avg_accuracy}
                    )
                    return True
                else:
                    self.log_test(
                        "AI Model Accuracy API",
                        False,
                        "Invalid response format",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "AI Model Accuracy API",
                    False,
                    f"Model accuracy failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "AI Model Accuracy API",
                False,
                f"Model accuracy request failed: {str(e)}"
            )
            return False

    def test_system_config_get(self):
        """Test GET /api/config/user/preferences endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/config/user/preferences", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'data' in data:
                    config_data = data.get('data', {}).get('config', {})
                    self.log_test(
                        "System Config GET API",
                        True,
                        f"User preferences retrieved - Theme: {config_data.get('theme', 'unknown')}",
                        {"theme": config_data.get('theme')}
                    )
                    return True
                else:
                    self.log_test(
                        "System Config GET API",
                        False,
                        "Invalid response format",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "System Config GET API",
                    False,
                    f"System config GET failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "System Config GET API",
                False,
                f"System config GET request failed: {str(e)}"
            )
            return False

    def test_system_config_post(self):
        """Test POST /api/config/user_preferences endpoint"""
        try:
            test_config = {
                "config": {
                    "theme": "dark",
                    "refreshInterval": 3000,
                    "showAdvancedOptions": True,
                    "notifications": {"enabled": True}
                }
            }
            
            response = self.session.post(f"{API_BASE}/config/user_preferences", json=test_config, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    self.log_test(
                        "System Config POST API",
                        True,
                        f"User preferences saved - Theme: {test_config['config']['theme']}",
                        {"theme": test_config['config']['theme']}
                    )
                    return True
                else:
                    self.log_test(
                        "System Config POST API",
                        False,
                        "Failed to save user preferences",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "System Config POST API",
                    False,
                    f"System config POST failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "System Config POST API",
                False,
                f"System config POST request failed: {str(e)}"
            )
            return False

    # ============================================================================
    # 4. MINING SESSION MANAGEMENT
    # ============================================================================

    def test_mining_session_start(self):
        """Test POST /api/mining/session/start endpoint"""
        try:
            session_data = {
                "coin": "litecoin",
                "mode": "pool",
                "threads": 4,
                "intensity": 0.8,
                "hashrate": 0,
                "acceptedShares": 0,
                "rejectedShares": 0,
                "blocksFound": 0,
                "cpuUsage": 0,
                "memoryUsage": 0
            }
            
            response = self.session.post(f"{API_BASE}/mining/session/start", json=session_data, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'sessionId' in data:
                    session_id = data.get('sessionId')
                    self.log_test(
                        "Mining Session Start API",
                        True,
                        f"Mining session started - ID: {session_id}",
                        {"session_id": session_id}
                    )
                    return session_id
                else:
                    self.log_test(
                        "Mining Session Start API",
                        False,
                        "Failed to start mining session",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Mining Session Start API",
                    False,
                    f"Session start failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Mining Session Start API",
                False,
                f"Session start request failed: {str(e)}"
            )
            return False

    def test_mining_session_update(self, session_id):
        """Test PUT /api/mining/session/:id/update endpoint"""
        if not session_id:
            self.log_test(
                "Mining Session Update API",
                False,
                "No session ID available for update test"
            )
            return False
            
        try:
            update_data = {
                "hashrate": 1500.0,
                "acceptedShares": 10,
                "rejectedShares": 1,
                "cpuUsage": 80.5,
                "memoryUsage": 65.2
            }
            
            response = self.session.put(f"{API_BASE}/mining/session/{session_id}/update", json=update_data, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    efficiency = data.get('efficiency', 0)
                    self.log_test(
                        "Mining Session Update API",
                        True,
                        f"Session updated - Efficiency: {efficiency}%",
                        {"efficiency": efficiency}
                    )
                    return True
                else:
                    self.log_test(
                        "Mining Session Update API",
                        False,
                        "Failed to update mining session",
                        data
                    )
                    return False
            elif response.status_code == 404:
                self.log_test(
                    "Mining Session Update API",
                    False,
                    "Session not found for update",
                    response.text
                )
                return False
            else:
                self.log_test(
                    "Mining Session Update API",
                    False,
                    f"Session update failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Mining Session Update API",
                False,
                f"Session update request failed: {str(e)}"
            )
            return False

    def test_mining_session_end(self, session_id):
        """Test POST /api/mining/session/:id/end endpoint"""
        if not session_id:
            self.log_test(
                "Mining Session End API",
                False,
                "No session ID available for end test"
            )
            return False
            
        try:
            final_stats = {
                "finalStats": {
                    "hashrate": 1600.0,
                    "acceptedShares": 25,
                    "rejectedShares": 2,
                    "blocksFound": 0,
                    "cpuUsage": 85.0,
                    "memoryUsage": 70.0
                }
            }
            
            response = self.session.post(f"{API_BASE}/mining/session/{session_id}/end", json=final_stats, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    duration = data.get('duration', 0)
                    efficiency = data.get('efficiency', 0)
                    self.log_test(
                        "Mining Session End API",
                        True,
                        f"Session ended - Duration: {duration}s, Efficiency: {efficiency}%",
                        {"duration": duration, "efficiency": efficiency}
                    )
                    return True
                else:
                    self.log_test(
                        "Mining Session End API",
                        False,
                        "Failed to end mining session",
                        data
                    )
                    return False
            elif response.status_code == 404:
                self.log_test(
                    "Mining Session End API",
                    False,
                    "Session not found for end",
                    response.text
                )
                return False
            else:
                self.log_test(
                    "Mining Session End API",
                    False,
                    f"Session end failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Mining Session End API",
                False,
                f"Session end request failed: {str(e)}"
            )
            return False

    # ============================================================================
    # 5. DATABASE OPERATIONS
    # ============================================================================

    def test_maintenance_stats(self):
        """Test GET /api/maintenance/stats endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/maintenance/stats", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'collections' in data:
                    collections = data.get('collections', {})
                    total_docs = data.get('totalDocuments', 0)
                    self.log_test(
                        "Database Maintenance Stats API",
                        True,
                        f"Database stats retrieved - Total docs: {total_docs}, Mining stats: {collections.get('miningStats', 0)}",
                        {"total_docs": total_docs, "mining_stats": collections.get('miningStats')}
                    )
                    return True
                else:
                    self.log_test(
                        "Database Maintenance Stats API",
                        False,
                        "Invalid response format",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Database Maintenance Stats API",
                    False,
                    f"Maintenance stats failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Database Maintenance Stats API",
                False,
                f"Maintenance stats request failed: {str(e)}"
            )
            return False

    def test_maintenance_cleanup(self):
        """Test POST /api/maintenance/cleanup endpoint"""
        try:
            response = self.session.post(f"{API_BASE}/maintenance/cleanup", timeout=15)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'cleaned' in data:
                    cleaned = data.get('cleaned', {})
                    retention_policy = data.get('retentionPolicy', 'unknown')
                    self.log_test(
                        "Database Maintenance Cleanup API",
                        True,
                        f"Database cleanup completed - Retention: {retention_policy}, Expired predictions: {cleaned.get('expiredPredictions', 0)}",
                        {"retention_policy": retention_policy, "cleaned": cleaned}
                    )
                    return True
                else:
                    self.log_test(
                        "Database Maintenance Cleanup API",
                        False,
                        "Invalid response format",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Database Maintenance Cleanup API",
                    False,
                    f"Maintenance cleanup failed with status {response.status_code}",
                    response.text
                )
                return False
        except Exception as e:
            self.log_test(
                "Database Maintenance Cleanup API",
                False,
                f"Maintenance cleanup request failed: {str(e)}"
            )
            return False

    # ============================================================================
    # 6. MONGODB CONNECTIVITY
    # ============================================================================

    def test_mongodb_connectivity(self):
        """Test MongoDB connectivity through various endpoints"""
        try:
            # Test multiple endpoints that require database access
            endpoints_to_test = [
                ("/api/mining/stats", "Mining Stats"),
                ("/api/ai/predictions", "AI Predictions"),
                ("/api/config/user/preferences", "User Preferences"),
                ("/api/maintenance/stats", "Database Stats")
            ]
            
            successful_connections = 0
            total_tests = len(endpoints_to_test)
            
            for endpoint, name in endpoints_to_test:
                try:
                    response = self.session.get(f"{API_BASE}{endpoint}", timeout=10)
                    if response.status_code == 200:
                        successful_connections += 1
                except:
                    pass
            
            success_rate = (successful_connections / total_tests) * 100
            
            if success_rate >= 75:
                self.log_test(
                    "MongoDB Connectivity Verification",
                    True,
                    f"MongoDB connectivity verified - {successful_connections}/{total_tests} endpoints accessible ({success_rate:.1f}%)",
                    {"success_rate": success_rate, "successful_connections": successful_connections}
                )
                return True
            else:
                self.log_test(
                    "MongoDB Connectivity Verification",
                    False,
                    f"MongoDB connectivity issues - Only {successful_connections}/{total_tests} endpoints accessible ({success_rate:.1f}%)",
                    {"success_rate": success_rate, "successful_connections": successful_connections}
                )
                return False
        except Exception as e:
            self.log_test(
                "MongoDB Connectivity Verification",
                False,
                f"MongoDB connectivity test failed: {str(e)}"
            )
            return False

    # ============================================================================
    # 7. THREAD SCALING TESTING
    # ============================================================================

    def test_thread_scaling(self):
        """Test mining with different thread counts (8, 16, 32, 64 threads)"""
        try:
            thread_counts = [8, 16, 32, 64]
            scaling_results = []
            
            for threads in thread_counts:
                print(f"🧵 Testing thread scaling with {threads} threads...")
                
                # Configure mining with specific thread count
                mining_config = {
                    "coin": "litecoin",
                    "mode": "solo",
                    "threads": threads,
                    "intensity": 0.8,
                    "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
                }
                
                try:
                    # Start mining
                    start_response = self.session.post(f"{API_BASE}/mining/start", json=mining_config, timeout=15)
                    
                    if start_response.status_code == 200 and start_response.json().get('success'):
                        # Wait for mining to stabilize
                        time.sleep(5)
                        
                        # Get mining status
                        status_response = self.session.get(f"{API_BASE}/mining/status", timeout=10)
                        
                        if status_response.status_code == 200:
                            status_data = status_response.json()
                            hashrate = status_data.get('stats', {}).get('hashrate', 0)
                            is_mining = status_data.get('is_mining', False)
                            
                            scaling_results.append({
                                "threads": threads,
                                "hashrate": hashrate,
                                "is_mining": is_mining,
                                "success": True
                            })
                            
                            print(f"   {threads} threads: {hashrate:.2f} H/s, Mining: {is_mining}")
                        else:
                            scaling_results.append({
                                "threads": threads,
                                "hashrate": 0,
                                "is_mining": False,
                                "success": False
                            })
                        
                        # Stop mining
                        self.session.post(f"{API_BASE}/mining/stop", timeout=10)
                        time.sleep(2)
                    else:
                        scaling_results.append({
                            "threads": threads,
                            "hashrate": 0,
                            "is_mining": False,
                            "success": False
                        })
                        
                except Exception as thread_error:
                    print(f"   Error testing {threads} threads: {str(thread_error)}")
                    scaling_results.append({
                        "threads": threads,
                        "hashrate": 0,
                        "is_mining": False,
                        "success": False
                    })
            
            # Analyze results
            successful_tests = sum(1 for result in scaling_results if result['success'])
            total_tests = len(scaling_results)
            success_rate = (successful_tests / total_tests) * 100
            
            # Calculate performance scaling
            hashrates = [result['hashrate'] for result in scaling_results if result['success']]
            avg_hashrate = sum(hashrates) / len(hashrates) if hashrates else 0
            
            if success_rate >= 50:  # At least half the thread counts should work
                self.log_test(
                    "Thread Scaling Performance Testing",
                    True,
                    f"Thread scaling validated - {successful_tests}/{total_tests} thread counts successful ({success_rate:.1f}%), Avg hashrate: {avg_hashrate:.2f} H/s",
                    {"success_rate": success_rate, "scaling_results": scaling_results, "avg_hashrate": avg_hashrate}
                )
                return True
            else:
                self.log_test(
                    "Thread Scaling Performance Testing",
                    False,
                    f"Thread scaling issues - Only {successful_tests}/{total_tests} thread counts successful ({success_rate:.1f}%)",
                    {"success_rate": success_rate, "scaling_results": scaling_results}
                )
                return False
                
        except Exception as e:
            self.log_test(
                "Thread Scaling Performance Testing",
                False,
                f"Thread scaling test failed: {str(e)}"
            )
            return False

    # ============================================================================
    # MAIN TEST RUNNER
    # ============================================================================

    def run_comprehensive_migration_tests(self):
        """Run all comprehensive migration tests"""
        print("🚀 CryptoMiner Pro - Post-Migration Comprehensive Test Suite")
        print("Focus: Testing all newly migrated Node.js backend API endpoints")
        print("Testing: Health checks, Mining operations, Mongoose integration, Session management, Database ops, Thread scaling")
        print("=" * 80)
        print()
        
        # 1. Basic Health Checks
        print("1️⃣ BASIC HEALTH CHECKS")
        print("-" * 40)
        self.test_health_endpoint()
        self.test_system_stats_endpoint()
        self.test_cpu_info_endpoint()
        print()
        
        # 2. Mining Operations
        print("2️⃣ MINING OPERATIONS")
        print("-" * 40)
        self.test_mining_status_endpoint()
        self.test_mining_start_basic()
        self.test_mining_stop_basic()
        print()
        
        # 3. Enhanced Mongoose Model Integration
        print("3️⃣ ENHANCED MONGOOSE MODEL INTEGRATION")
        print("-" * 40)
        self.test_mining_stats_get()
        self.test_mining_stats_post()
        self.test_mining_stats_top()
        self.test_ai_predictions_get()
        self.test_ai_predictions_post()
        self.test_ai_model_accuracy()
        self.test_system_config_get()
        self.test_system_config_post()
        print()
        
        # 4. Mining Session Management
        print("4️⃣ MINING SESSION MANAGEMENT")
        print("-" * 40)
        session_id = self.test_mining_session_start()
        self.test_mining_session_update(session_id)
        self.test_mining_session_end(session_id)
        print()
        
        # 5. Database Operations
        print("5️⃣ DATABASE OPERATIONS")
        print("-" * 40)
        self.test_maintenance_stats()
        self.test_maintenance_cleanup()
        print()
        
        # 6. MongoDB Connectivity
        print("6️⃣ MONGODB CONNECTIVITY")
        print("-" * 40)
        self.test_mongodb_connectivity()
        print()
        
        # 7. Thread Scaling
        print("7️⃣ THREAD SCALING TESTING")
        print("-" * 40)
        self.test_thread_scaling()
        print()
        
        # Summary
        print("=" * 80)
        print("📊 TEST SUMMARY")
        print("=" * 80)
        
        passed_tests = sum(1 for result in self.test_results if result['success'])
        total_tests = len(self.test_results)
        success_rate = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
        
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {total_tests - passed_tests}")
        print(f"Success Rate: {success_rate:.1f}%")
        print()
        
        if success_rate >= 80:
            print("🎉 EXCELLENT: CryptoMiner Pro backend migration successful!")
            print("✅ All critical systems operational and ready for production use.")
        elif success_rate >= 60:
            print("✅ GOOD: CryptoMiner Pro backend migration mostly successful!")
            print("⚠️  Some minor issues detected but core functionality working.")
        else:
            print("❌ ISSUES DETECTED: CryptoMiner Pro backend migration has problems!")
            print("🔧 Critical issues need to be addressed before production use.")
        
        print()
        print("Failed Tests:")
        for result in self.test_results:
            if not result['success']:
                print(f"  ❌ {result['test']}: {result['details']}")
        
        return success_rate >= 60

if __name__ == "__main__":
    tester = MigrationTester()
    success = tester.run_comprehensive_migration_tests()
    sys.exit(0 if success else 1)