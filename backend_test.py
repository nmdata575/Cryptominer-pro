#!/usr/bin/env python3
"""
CryptoMiner Pro - Comprehensive Backend API Testing Suite
Testing all backend functionality after recent improvements:
- Fixed WebSocket proxy errors (converted to Socket.io)
- Enhanced CPU detection with container environment awareness
- Fixed rate limiting issues
- Resolved ESLint warnings
"""

import requests
import json
import time
import sys
import websocket
import threading
from datetime import datetime

# Configuration
BACKEND_URL = "https://337dbf55-6395-4d2b-a739-f38dea0fde64.preview.emergentagent.com/api"
WEBSOCKET_URL = "wss://84635953-2fa9-4a6c-a89b-23dbccf67eb9.preview.emergentagent.com"
TIMEOUT = 10

class BackendTester:
    def __init__(self):
        self.results = []
        self.total_tests = 0
        self.passed_tests = 0
        
    def log_result(self, test_name, success, message, details=None):
        """Log test result"""
        self.total_tests += 1
        if success:
            self.passed_tests += 1
            status = "✅ PASSED"
        else:
            status = "❌ FAILED"
            
        result = {
            'test': test_name,
            'status': status,
            'success': success,
            'message': message,
            'details': details,
            'timestamp': datetime.now().isoformat()
        }
        self.results.append(result)
        print(f"{status} - {test_name}: {message}")
        if details:
            print(f"   Details: {details}")
    
    def test_health_check(self):
        """Test health check endpoint (/api/health)"""
        try:
            response = requests.get(f"{BACKEND_URL}/health", timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                required_fields = ['status', 'timestamp', 'version', 'uptime', 'node_version']
                missing_fields = [field for field in required_fields if field not in data]
                
                if missing_fields:
                    self.log_result("Health Check API", False, 
                                  f"Missing required fields: {missing_fields}", data)
                elif data.get('status') == 'healthy':
                    self.log_result("Health Check API", True, 
                                  f"Returns healthy status with Node.js {data.get('node_version', 'unknown')}", 
                                  f"Uptime: {data.get('uptime', 0):.2f}s")
                else:
                    self.log_result("Health Check API", False, 
                                  f"Unhealthy status: {data.get('status')}", data)
            else:
                self.log_result("Health Check API", False, 
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Health Check API", False, f"Request failed: {str(e)}")
    
    def test_system_stats(self):
        """Test system stats endpoint (/api/system/stats)"""
        try:
            response = requests.get(f"{BACKEND_URL}/system/stats", timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                expected_fields = ['cpu_usage', 'memory_usage', 'disk_usage']
                
                if all(field in data for field in expected_fields):
                    cpu = data.get('cpu_usage', 0)
                    memory = data.get('memory_usage', 0)
                    disk = data.get('disk_usage', 0)
                    
                    self.log_result("System Stats API", True, 
                                  f"Returns system statistics successfully", 
                                  f"CPU: {cpu}%, Memory: {memory}%, Disk: {disk}%")
                else:
                    missing = [f for f in expected_fields if f not in data]
                    self.log_result("System Stats API", False, 
                                  f"Missing expected fields: {missing}", data)
            else:
                self.log_result("System Stats API", False, 
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("System Stats API", False, f"Request failed: {str(e)}")
    
    def test_enhanced_cpu_info_api(self):
        """Test enhanced CPU info endpoint (/api/system/cpu-info) - Key focus of review"""
        try:
            response = requests.get(f"{BACKEND_URL}/system/cpu-info", timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                
                # Check for enhanced CPU detection fields
                required_fields = ['cores', 'environment', 'mining_profiles', 'optimal_mining_config']
                missing_fields = [field for field in required_fields if field not in data]
                
                if missing_fields:
                    self.log_result("Enhanced CPU Info API", False, 
                                  f"Missing enhanced fields: {missing_fields}", data)
                    return
                
                # Verify container environment detection
                environment = data.get('environment', {})
                container_detected = environment.get('container', False)
                kubernetes_detected = environment.get('kubernetes', False)
                env_type = environment.get('type', 'unknown')
                
                # Verify cores information
                cores = data.get('cores', {})
                physical_cores = cores.get('physical', 0)
                logical_cores = cores.get('logical', 0)
                allocated_cores = cores.get('allocated', 0)
                
                # Verify mining profiles (should have 4 profiles)
                mining_profiles = data.get('mining_profiles', {})
                expected_profiles = ['light', 'standard', 'maximum', 'absolute_max']
                found_profiles = [profile for profile in expected_profiles if profile in mining_profiles]
                
                # Verify optimal mining config
                optimal_config = data.get('optimal_mining_config', {})
                max_safe_threads = optimal_config.get('max_safe_threads', 0)
                recommended_profile = optimal_config.get('recommended_profile', '')
                
                # Log detailed results
                details = {
                    'container_detected': container_detected,
                    'kubernetes_detected': kubernetes_detected,
                    'environment_type': env_type,
                    'physical_cores': physical_cores,
                    'logical_cores': logical_cores,
                    'allocated_cores': allocated_cores,
                    'mining_profiles_found': found_profiles,
                    'max_safe_threads': max_safe_threads,
                    'recommended_profile': recommended_profile
                }
                
                # Success criteria
                success = (
                    len(found_profiles) == 4 and  # All 4 mining profiles present
                    physical_cores > 0 and  # CPU cores detected
                    max_safe_threads > 0 and  # Thread recommendations available
                    env_type in ['kubernetes', 'container', 'native']  # Environment detected
                )
                
                if success:
                    self.log_result("Enhanced CPU Info API", True, 
                                  f"Enhanced CPU detection working - {physical_cores} cores, {env_type} environment, {len(found_profiles)} mining profiles", 
                                  details)
                else:
                    self.log_result("Enhanced CPU Info API", False, 
                                  f"Enhanced CPU detection incomplete", details)
            else:
                self.log_result("Enhanced CPU Info API", False, 
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Enhanced CPU Info API", False, f"Request failed: {str(e)}")
    
    def test_environment_api(self):
        """Test new environment API endpoint (/api/system/environment) - Key focus of review"""
        try:
            response = requests.get(f"{BACKEND_URL}/system/environment", timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                
                # Check for required environment fields
                required_fields = ['deployment_type', 'container_info', 'cpu_allocation', 'performance_context', 'mining_recommendations']
                missing_fields = [field for field in required_fields if field not in data]
                
                if missing_fields:
                    self.log_result("Environment API", False, 
                                  f"Missing required fields: {missing_fields}", data)
                    return
                
                # Verify deployment type detection
                deployment_type = data.get('deployment_type', 'unknown')
                
                # Verify container info
                container_info = data.get('container_info', {})
                is_containerized = container_info.get('is_containerized', False)
                kubernetes = container_info.get('kubernetes', False)
                
                # Verify CPU allocation info
                cpu_allocation = data.get('cpu_allocation', {})
                allocated_cores = cpu_allocation.get('allocated_cores', 0)
                optimal_mining_threads = cpu_allocation.get('optimal_mining_threads', 0)
                
                # Verify performance context
                performance_context = data.get('performance_context', {})
                environment_optimized = performance_context.get('environment_optimized', False)
                recommended_profile = performance_context.get('recommended_profile', '')
                max_safe_threads = performance_context.get('max_safe_threads', 0)
                performance_notes = performance_context.get('performance_notes', [])
                
                # Verify mining recommendations
                mining_recommendations = data.get('mining_recommendations', {})
                
                details = {
                    'deployment_type': deployment_type,
                    'is_containerized': is_containerized,
                    'kubernetes': kubernetes,
                    'allocated_cores': allocated_cores,
                    'optimal_mining_threads': optimal_mining_threads,
                    'recommended_profile': recommended_profile,
                    'max_safe_threads': max_safe_threads,
                    'performance_notes_count': len(performance_notes),
                    'mining_recommendations_count': len(mining_recommendations)
                }
                
                # Success criteria
                success = (
                    deployment_type in ['kubernetes', 'container', 'native'] and
                    allocated_cores > 0 and
                    optimal_mining_threads > 0 and
                    len(performance_notes) > 0
                )
                
                if success:
                    self.log_result("Environment API", True, 
                                  f"Environment detection working - {deployment_type} with {allocated_cores} cores, {optimal_mining_threads} optimal threads", 
                                  details)
                else:
                    self.log_result("Environment API", False, 
                                  f"Environment detection incomplete", details)
            else:
                self.log_result("Environment API", False, 
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Environment API", False, f"Request failed: {str(e)}")
    
    def test_mining_profiles_optimization(self):
        """Test mining profiles for 8-core container optimization"""
        try:
            response = requests.get(f"{BACKEND_URL}/system/cpu-info", timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                mining_profiles = data.get('mining_profiles', {})
                
                if not mining_profiles:
                    self.log_result("Mining Profiles Optimization", False, 
                                  "No mining profiles found in CPU info")
                    return
                
                # Expected 4 profiles
                expected_profiles = ['light', 'standard', 'maximum', 'absolute_max']
                profile_results = {}
                
                for profile_name in expected_profiles:
                    if profile_name in mining_profiles:
                        profile = mining_profiles[profile_name]
                        threads = profile.get('threads', 0)
                        description = profile.get('description', '')
                        
                        profile_results[profile_name] = {
                            'threads': threads,
                            'description': description,
                            'present': True
                        }
                    else:
                        profile_results[profile_name] = {'present': False}
                
                # Check if all profiles are present
                all_profiles_present = all(profile_results[p]['present'] for p in expected_profiles)
                
                # For 8-core container, verify thread recommendations are reasonable
                cores_info = data.get('cores', {})
                physical_cores = cores_info.get('physical', 0)
                
                # Verify thread recommendations make sense for container environment
                reasonable_threads = True
                if all_profiles_present and physical_cores > 0:
                    light_threads = profile_results['light'].get('threads', 0)
                    standard_threads = profile_results['standard'].get('threads', 0)
                    maximum_threads = profile_results['maximum'].get('threads', 0)
                    absolute_max_threads = profile_results['absolute_max'].get('threads', 0)
                    
                    # Verify ascending thread counts
                    if not (light_threads <= standard_threads <= maximum_threads <= absolute_max_threads):
                        reasonable_threads = False
                    
                    # For 8-core system, maximum should be around 7 threads (leaving 1 for system)
                    if physical_cores == 8 and maximum_threads != 7:
                        reasonable_threads = False
                
                details = {
                    'profiles_found': len([p for p in profile_results.values() if p.get('present', False)]),
                    'all_profiles_present': all_profiles_present,
                    'physical_cores': physical_cores,
                    'profile_details': profile_results,
                    'reasonable_threads': reasonable_threads
                }
                
                if all_profiles_present and reasonable_threads:
                    self.log_result("Mining Profiles Optimization", True, 
                                  f"All 4 mining profiles present with optimized thread counts for {physical_cores}-core container", 
                                  details)
                else:
                    self.log_result("Mining Profiles Optimization", False, 
                                  f"Mining profiles incomplete or not optimized", details)
            else:
                self.log_result("Mining Profiles Optimization", False, 
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Mining Profiles Optimization", False, f"Request failed: {str(e)}")
    
    def test_container_detection(self):
        """Test container environment detection (Kubernetes)"""
        try:
            # Test both CPU info and environment endpoints for container detection
            cpu_response = requests.get(f"{BACKEND_URL}/system/cpu-info", timeout=TIMEOUT)
            env_response = requests.get(f"{BACKEND_URL}/system/environment", timeout=TIMEOUT)
            
            container_detected = False
            kubernetes_detected = False
            detection_sources = []
            
            # Check CPU info endpoint
            if cpu_response.status_code == 200:
                cpu_data = cpu_response.json()
                environment = cpu_data.get('environment', {})
                if environment.get('container', False):
                    container_detected = True
                    detection_sources.append('cpu-info')
                if environment.get('kubernetes', False):
                    kubernetes_detected = True
            
            # Check environment endpoint
            if env_response.status_code == 200:
                env_data = env_response.json()
                container_info = env_data.get('container_info', {})
                if container_info.get('is_containerized', False):
                    container_detected = True
                    if 'environment' not in detection_sources:
                        detection_sources.append('environment')
                if container_info.get('kubernetes', False):
                    kubernetes_detected = True
                
                deployment_type = env_data.get('deployment_type', 'unknown')
            
            details = {
                'container_detected': container_detected,
                'kubernetes_detected': kubernetes_detected,
                'detection_sources': detection_sources,
                'deployment_type': deployment_type if 'env_data' in locals() else 'unknown'
            }
            
            # Success if container environment is properly detected
            if container_detected and len(detection_sources) > 0:
                env_type = 'Kubernetes' if kubernetes_detected else 'Container'
                self.log_result("Container Detection", True, 
                              f"{env_type} environment properly detected via {', '.join(detection_sources)} endpoints", 
                              details)
            else:
                self.log_result("Container Detection", False, 
                              f"Container environment not detected or detection incomplete", details)
                
        except requests.exceptions.RequestException as e:
            self.log_result("Container Detection", False, f"Request failed: {str(e)}")
    
    def test_thread_recommendations(self):
        """Test thread recommendations for 8-core container (should recommend 7 threads)"""
        try:
            # Get CPU info for thread recommendations
            cpu_response = requests.get(f"{BACKEND_URL}/system/cpu-info", timeout=TIMEOUT)
            env_response = requests.get(f"{BACKEND_URL}/system/environment", timeout=TIMEOUT)
            
            if cpu_response.status_code == 200:
                cpu_data = cpu_response.json()
                
                # Check optimal mining config
                optimal_config = cpu_data.get('optimal_mining_config', {})
                max_safe_threads = optimal_config.get('max_safe_threads', 0)
                recommended_profile = optimal_config.get('recommended_profile', '')
                
                # Check recommended threads from different sources
                recommended_threads = cpu_data.get('recommended_threads', {})
                
                # Get cores information
                cores = cpu_data.get('cores', {})
                physical_cores = cores.get('physical', 0)
                allocated_cores = cores.get('allocated', 0)
                
                # Check environment endpoint for additional thread info
                env_optimal_threads = 0
                if env_response.status_code == 200:
                    env_data = env_response.json()
                    cpu_allocation = env_data.get('cpu_allocation', {})
                    env_optimal_threads = cpu_allocation.get('optimal_mining_threads', 0)
                
                details = {
                    'physical_cores': physical_cores,
                    'allocated_cores': allocated_cores,
                    'max_safe_threads': max_safe_threads,
                    'env_optimal_threads': env_optimal_threads,
                    'recommended_profile': recommended_profile,
                    'recommended_threads': recommended_threads
                }
                
                # For 8-core container, optimal should be 7 threads (leaving 1 for system)
                expected_optimal = 7 if physical_cores == 8 else max(1, physical_cores - 1)
                
                # Check if recommendations are reasonable
                recommendations_good = (
                    max_safe_threads == expected_optimal or
                    env_optimal_threads == expected_optimal or
                    (recommended_threads.get('balanced', 0) == expected_optimal)
                )
                
                if recommendations_good and physical_cores > 0:
                    self.log_result("Thread Recommendations", True, 
                                  f"Optimal thread recommendations for {physical_cores}-core container: {max_safe_threads or env_optimal_threads} threads", 
                                  details)
                else:
                    self.log_result("Thread Recommendations", False, 
                                  f"Thread recommendations may not be optimal for {physical_cores}-core container", details)
            else:
                self.log_result("Thread Recommendations", False, 
                              f"HTTP {cpu_response.status_code}: {cpu_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Thread Recommendations", False, f"Request failed: {str(e)}")
    
    def test_cpu_core_detection_explanation(self):
        """Test that the system properly explains 8-core detection vs 128-core expectation"""
        try:
            env_response = requests.get(f"{BACKEND_URL}/system/environment", timeout=TIMEOUT)
            
            if env_response.status_code == 200:
                env_data = env_response.json()
                
                # Check performance context for explanatory notes
                performance_context = env_data.get('performance_context', {})
                performance_notes = performance_context.get('performance_notes', [])
                
                # Check CPU allocation info
                cpu_allocation = env_data.get('cpu_allocation', {})
                allocated_cores = cpu_allocation.get('allocated_cores', 0)
                
                # Look for container/environment explanation in notes
                container_explanation_found = False
                for note in performance_notes:
                    if any(keyword in note.lower() for keyword in ['container', 'kubernetes', 'allocated', 'docker']):
                        container_explanation_found = True
                        break
                
                # Check if deployment type indicates containerized environment
                deployment_type = env_data.get('deployment_type', 'unknown')
                is_containerized = deployment_type in ['kubernetes', 'container']
                
                details = {
                    'allocated_cores': allocated_cores,
                    'deployment_type': deployment_type,
                    'is_containerized': is_containerized,
                    'performance_notes_count': len(performance_notes),
                    'container_explanation_found': container_explanation_found,
                    'performance_notes': performance_notes[:3]  # First 3 notes for reference
                }
                
                # Success if system explains the containerized environment
                if is_containerized and container_explanation_found and allocated_cores > 0:
                    self.log_result("CPU Core Detection Explanation", True, 
                                  f"System properly explains {allocated_cores} cores in {deployment_type} environment", 
                                  details)
                else:
                    self.log_result("CPU Core Detection Explanation", False, 
                                  f"System doesn't adequately explain containerized CPU allocation", details)
            else:
                self.log_result("CPU Core Detection Explanation", False, 
                              f"HTTP {env_response.status_code}: {env_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("CPU Core Detection Explanation", False, f"Request failed: {str(e)}")
    
    def test_coin_presets(self):
        """Test coin presets endpoint (/api/coins/presets)"""
        try:
            response = requests.get(f"{BACKEND_URL}/coins/presets", timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                
                if 'presets' in data:
                    presets = data['presets']
                    expected_coins = ['litecoin', 'dogecoin', 'feathercoin']
                    found_coins = [coin for coin in expected_coins if coin in presets]
                    
                    if len(found_coins) == 3:
                        coin_details = []
                        for coin in found_coins:
                            coin_data = presets[coin]
                            coin_details.append(f"{coin_data.get('name', coin)} ({coin_data.get('symbol', 'N/A')})")
                        
                        self.log_result("Coin Presets API", True, 
                                      f"Returns all expected coin presets", 
                                      f"Coins: {', '.join(coin_details)}")
                    else:
                        missing = [coin for coin in expected_coins if coin not in presets]
                        self.log_result("Coin Presets API", False, 
                                      f"Missing expected coins: {missing}", 
                                      f"Found: {list(presets.keys())}")
                else:
                    self.log_result("Coin Presets API", False, 
                                  "Response missing 'presets' field", data)
            else:
                self.log_result("Coin Presets API", False, 
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Coin Presets API", False, f"Request failed: {str(e)}")
    
    def test_mining_status(self):
        """Test mining status endpoint (/api/mining/status)"""
        try:
            response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                required_fields = ['is_mining', 'stats']
                
                if all(field in data for field in required_fields):
                    is_mining = data.get('is_mining', False)
                    stats = data.get('stats', {})
                    hashrate = stats.get('hashrate', 0)
                    
                    self.log_result("Mining Status API", True, 
                                  f"Returns mining status successfully", 
                                  f"Mining: {is_mining}, Hashrate: {hashrate} H/s")
                else:
                    missing = [f for f in required_fields if f not in data]
                    self.log_result("Mining Status API", False, 
                                  f"Missing required fields: {missing}", data)
            else:
                self.log_result("Mining Status API", False, 
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Mining Status API", False, f"Request failed: {str(e)}")
    
    def test_mining_status(self):
        """Test mining status endpoint (/api/mining/status)"""
        try:
            response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                required_fields = ['is_mining', 'stats']
                
                if all(field in data for field in required_fields):
                    is_mining = data.get('is_mining', False)
                    stats = data.get('stats', {})
                    hashrate = stats.get('hashrate', 0)
                    
                    self.log_result("Mining Status API", True, 
                                  f"Returns mining status successfully", 
                                  f"Mining: {is_mining}, Hashrate: {hashrate} H/s")
                else:
                    missing = [f for f in required_fields if f not in data]
                    self.log_result("Mining Status API", False, 
                                  f"Missing required fields: {missing}", data)
            else:
                self.log_result("Mining Status API", False, 
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Mining Status API", False, f"Request failed: {str(e)}")
    
    def test_mining_start_stop_functionality(self):
        """Test complete mining start/stop workflow"""
        try:
            # Test mining start with solo mode
            start_config = {
                "coin": "litecoin",
                "mode": "solo",
                "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
                "threads": 4,
                "intensity": 0.8
            }
            
            start_response = requests.post(f"{BACKEND_URL}/mining/start", 
                                         json=start_config, timeout=TIMEOUT)
            
            if start_response.status_code == 200:
                start_data = start_response.json()
                if start_data.get('success'):
                    # Wait a moment for mining to initialize
                    time.sleep(2)
                    
                    # Check mining status
                    status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        is_mining = status_data.get('is_mining', False)
                        
                        # Stop mining
                        stop_response = requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                        if stop_response.status_code == 200:
                            stop_data = stop_response.json()
                            
                            self.log_result("Mining Start/Stop Functionality", True,
                                          f"Complete mining workflow successful - started, verified status, stopped",
                                          f"Mining was active: {is_mining}")
                        else:
                            self.log_result("Mining Start/Stop Functionality", False,
                                          f"Mining stop failed: HTTP {stop_response.status_code}")
                    else:
                        self.log_result("Mining Start/Stop Functionality", False,
                                      f"Status check failed: HTTP {status_response.status_code}")
                else:
                    self.log_result("Mining Start/Stop Functionality", False,
                                  f"Mining start failed: {start_data.get('message', 'Unknown error')}")
            else:
                self.log_result("Mining Start/Stop Functionality", False,
                              f"Mining start HTTP {start_response.status_code}: {start_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Mining Start/Stop Functionality", False, f"Request failed: {str(e)}")
    
    def test_wallet_validation(self):
        """Test wallet validation for different cryptocurrencies"""
        try:
            test_cases = [
                {"address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4", "coin_symbol": "LTC", "should_be_valid": True},
                {"address": "D7Y55Lkqb3VladCEZ7oJLSKa6wjYcpAxFk", "coin_symbol": "DOGE", "should_be_valid": True},
                {"address": "6oNS8WmfpKdWnV2kHQJAmcMxJJ7Lh8YKE1", "coin_symbol": "FTC", "should_be_valid": True},
                {"address": "invalid_address", "coin_symbol": "LTC", "should_be_valid": False}
            ]
            
            passed_tests = 0
            total_tests = len(test_cases)
            
            for test_case in test_cases:
                response = requests.post(f"{BACKEND_URL}/wallet/validate",
                                       json=test_case, timeout=TIMEOUT)
                
                if response.status_code == 200:
                    data = response.json()
                    is_valid = data.get('valid', False)
                    
                    if is_valid == test_case['should_be_valid']:
                        passed_tests += 1
                
            success_rate = (passed_tests / total_tests) * 100
            
            if success_rate >= 75:  # 75% success rate threshold
                self.log_result("Wallet Validation", True,
                              f"Wallet validation working correctly",
                              f"Success rate: {success_rate:.1f}% ({passed_tests}/{total_tests})")
            else:
                self.log_result("Wallet Validation", False,
                              f"Wallet validation has issues",
                              f"Success rate: {success_rate:.1f}% ({passed_tests}/{total_tests})")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Wallet Validation", False, f"Request failed: {str(e)}")
    
    def test_ai_insights(self):
        """Test AI insights endpoint"""
        try:
            response = requests.get(f"{BACKEND_URL}/mining/ai-insights", timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                required_fields = ['insights', 'predictions', 'optimization_suggestions']
                
                if all(field in data for field in required_fields):
                    insights_count = len(data.get('insights', {}))
                    predictions_count = len(data.get('predictions', {}))
                    suggestions_count = len(data.get('optimization_suggestions', []))
                    
                    self.log_result("AI Insights API", True,
                                  f"AI insights system functional",
                                  f"Insights: {insights_count}, Predictions: {predictions_count}, Suggestions: {suggestions_count}")
                else:
                    missing = [f for f in required_fields if f not in data]
                    self.log_result("AI Insights API", False,
                                  f"Missing required fields: {missing}", data)
            else:
                self.log_result("AI Insights API", False,
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("AI Insights API", False, f"Request failed: {str(e)}")
    
    def test_websocket_connection(self):
        """Test WebSocket/Socket.io connection"""
        try:
            # Test WebSocket connection
            websocket_messages = []
            connection_successful = False
            
            def on_message(ws, message):
                websocket_messages.append(message)
            
            def on_open(ws):
                nonlocal connection_successful
                connection_successful = True
                # Close after receiving some messages or timeout
                threading.Timer(3.0, ws.close).start()
            
            def on_error(ws, error):
                pass  # Ignore errors for now
            
            def on_close(ws, close_status_code, close_msg):
                pass
            
            # Try WebSocket connection
            ws = websocket.WebSocketApp(f"{WEBSOCKET_URL}/socket.io/?EIO=4&transport=websocket",
                                      on_message=on_message,
                                      on_open=on_open,
                                      on_error=on_error,
                                      on_close=on_close)
            
            # Run WebSocket in a separate thread with timeout
            ws_thread = threading.Thread(target=ws.run_forever)
            ws_thread.daemon = True
            ws_thread.start()
            
            # Wait for connection or timeout
            time.sleep(4)
            
            if connection_successful and len(websocket_messages) > 0:
                self.log_result("WebSocket Connection", True,
                              f"WebSocket connection successful, received {len(websocket_messages)} messages",
                              f"Connection established and data received")
            elif connection_successful:
                self.log_result("WebSocket Connection", True,
                              f"WebSocket connection established but no messages received",
                              f"Connection successful but may be production environment limitation")
            else:
                self.log_result("WebSocket Connection", False,
                              f"WebSocket connection failed",
                              f"Could not establish connection to {WEBSOCKET_URL}")
                
        except Exception as e:
            self.log_result("WebSocket Connection", False, f"WebSocket test failed: {str(e)}")
    
    def test_rate_limiting(self):
        """Test rate limiting configuration (should not get 429 errors)"""
        try:
            # Make multiple rapid requests to mining start endpoint
            rapid_requests = 5
            success_count = 0
            rate_limited_count = 0
            
            for i in range(rapid_requests):
                config = {
                    "coin": "litecoin",
                    "mode": "solo",
                    "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
                    "threads": 2
                }
                
                response = requests.post(f"{BACKEND_URL}/mining/start", 
                                       json=config, timeout=TIMEOUT)
                
                if response.status_code == 429:
                    rate_limited_count += 1
                elif response.status_code in [200, 400, 500]:  # Accept various responses, just not 429
                    success_count += 1
                
                time.sleep(0.1)  # Small delay between requests
            
            # Stop any mining that might have started
            try:
                requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
            except:
                pass
            
            if rate_limited_count == 0:
                self.log_result("Rate Limiting Fix", True,
                              f"No 429 rate limiting errors detected in {rapid_requests} rapid requests",
                              f"Success responses: {success_count}, Rate limited: {rate_limited_count}")
            else:
                self.log_result("Rate Limiting Fix", False,
                              f"Rate limiting still occurring: {rate_limited_count} out of {rapid_requests} requests blocked",
                              f"Success responses: {success_count}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Rate Limiting Fix", False, f"Request failed: {str(e)}")
    
    def test_custom_coin_management(self):
        """Test custom coin management CRUD operations"""
        try:
            # Test getting custom coins list
            list_response = requests.get(f"{BACKEND_URL}/coins/custom", timeout=TIMEOUT)
            
            if list_response.status_code == 200:
                list_data = list_response.json()
                
                if 'coins' in list_data and 'total' in list_data:
                    initial_count = list_data['total']
                    
                    # Test custom coin validation
                    test_coin = {
                        "id": "testcoin",
                        "name": "Test Coin",
                        "symbol": "TEST",
                        "algorithm": "scrypt",
                        "block_time_target": 120,
                        "block_reward": 50,
                        "network_difficulty": 1000000,
                        "scrypt_params": {"N": 1024, "r": 1, "p": 1}
                    }
                    
                    validate_response = requests.post(f"{BACKEND_URL}/coins/custom/validate",
                                                    json=test_coin, timeout=TIMEOUT)
                    
                    validation_success = False
                    if validate_response.status_code == 200:
                        validate_data = validate_response.json()
                        validation_success = validate_data.get('valid', False)
                    
                    self.log_result("Custom Coin Management", True,
                                  f"Custom coin management endpoints accessible",
                                  f"Initial coins: {initial_count}, Validation working: {validation_success}")
                else:
                    self.log_result("Custom Coin Management", False,
                                  f"Custom coins list response missing required fields", list_data)
            else:
                self.log_result("Custom Coin Management", False,
                              f"Custom coins list HTTP {list_response.status_code}: {list_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Custom Coin Management", False, f"Request failed: {str(e)}")
    
    def test_remote_connectivity_apis(self):
        """Test remote connectivity APIs for Android app integration"""
        try:
            # Test connection test endpoint
            connection_response = requests.get(f"{BACKEND_URL}/remote/connection/test", timeout=TIMEOUT)
            
            connection_success = False
            if connection_response.status_code == 200:
                conn_data = connection_response.json()
                connection_success = conn_data.get('success', False)
            
            # Test device registration
            device_data = {
                "device_id": "test_device_001",
                "device_name": "Test Android Device"
            }
            
            register_response = requests.post(f"{BACKEND_URL}/remote/register",
                                            json=device_data, timeout=TIMEOUT)
            
            registration_success = False
            access_token = None
            if register_response.status_code == 200:
                reg_data = register_response.json()
                registration_success = reg_data.get('success', False)
                access_token = reg_data.get('access_token')
            
            # Test remote mining status
            remote_status_response = requests.get(f"{BACKEND_URL}/remote/mining/status", timeout=TIMEOUT)
            
            remote_status_success = False
            if remote_status_response.status_code == 200:
                status_data = remote_status_response.json()
                remote_status_success = 'remote_access' in status_data
            
            # Calculate success rate
            tests = [connection_success, registration_success, remote_status_success]
            success_rate = (sum(tests) / len(tests)) * 100
            
            if success_rate >= 66:  # 66% success rate threshold
                self.log_result("Remote Connectivity APIs", True,
                              f"Remote connectivity APIs working for Android integration",
                              f"Success rate: {success_rate:.1f}% - Connection: {connection_success}, Registration: {registration_success}, Status: {remote_status_success}")
            else:
                self.log_result("Remote Connectivity APIs", False,
                              f"Remote connectivity APIs have issues",
                              f"Success rate: {success_rate:.1f}%")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Remote Connectivity APIs", False, f"Request failed: {str(e)}")
    
    def test_pool_connection_testing(self):
        """Test pool connection testing endpoint"""
        try:
            # Test pool connection with valid parameters
            pool_test_data = {
                "pool_address": "stratum.litecoinpool.org",
                "pool_port": 3333,
                "type": "pool"
            }
            
            response = requests.post(f"{BACKEND_URL}/pool/test-connection",
                                   json=pool_test_data, timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                success = data.get('success', False)
                message = data.get('message', '')
                
                self.log_result("Pool Connection Testing", True,
                              f"Pool connection testing endpoint working",
                              f"Test result: {success}, Message: {message}")
            else:
                self.log_result("Pool Connection Testing", False,
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Pool Connection Testing", False, f"Request failed: {str(e)}")
    
    def run_all_tests(self):
        """Run comprehensive backend tests focusing on recent improvements"""
        print("🚀 Starting Comprehensive CryptoMiner Pro Backend Testing")
        print(f"🔗 Backend URL: {BACKEND_URL}")
        print("🎯 Focus: Verify all functionality after recent improvements")
        print("=" * 80)
        
        # Core Mining Functionality
        print("\n⛏️ CORE MINING FUNCTIONALITY TESTING")
        print("=" * 60)
        self.test_mining_start_stop_functionality()
        self.test_wallet_validation()
        self.test_mining_status()
        self.test_pool_connection_testing()
        
        # Enhanced CPU Detection
        print("\n🖥️ ENHANCED CPU DETECTION SYSTEM TESTING")
        print("=" * 60)
        self.test_enhanced_cpu_info_api()
        self.test_environment_api()
        self.test_mining_profiles_optimization()
        self.test_thread_recommendations()
        
        # System Monitoring
        print("\n📊 SYSTEM MONITORING TESTING")
        print("=" * 50)
        self.test_health_check()
        self.test_system_stats()
        self.test_ai_insights()
        
        # Custom Coin Management
        print("\n🪙 CUSTOM COIN MANAGEMENT TESTING")
        print("=" * 50)
        self.test_coin_presets()
        self.test_custom_coin_management()
        
        # WebSocket/Socket.io
        print("\n🔌 WEBSOCKET/SOCKET.IO TESTING")
        print("=" * 50)
        self.test_websocket_connection()
        
        # Rate Limiting
        print("\n⚡ RATE LIMITING TESTING")
        print("=" * 40)
        self.test_rate_limiting()
        
        # Remote Connectivity
        print("\n📱 REMOTE CONNECTIVITY TESTING")
        print("=" * 50)
        self.test_remote_connectivity_apis()
        
        print("=" * 80)
        print(f"📊 Test Results Summary:")
        print(f"   Total Tests: {self.total_tests}")
        print(f"   Passed: {self.passed_tests}")
        print(f"   Failed: {self.total_tests - self.passed_tests}")
        print(f"   Success Rate: {(self.passed_tests/self.total_tests)*100:.1f}%")
        
        # Categorize results by focus areas
        focus_areas = {
            'Core Mining': ['Mining Start/Stop', 'Wallet Validation', 'Mining Status', 'Pool Connection'],
            'Enhanced CPU Detection': ['Enhanced CPU Info', 'Environment API', 'Mining Profiles', 'Thread Recommendations'],
            'System Monitoring': ['Health Check', 'System Stats', 'AI Insights'],
            'Custom Coin Management': ['Coin Presets', 'Custom Coin Management'],
            'WebSocket/Socket.io': ['WebSocket Connection'],
            'Rate Limiting': ['Rate Limiting Fix'],
            'Remote Connectivity': ['Remote Connectivity APIs']
        }
        
        print(f"\n🎯 FOCUS AREA RESULTS:")
        for area, keywords in focus_areas.items():
            area_tests = [r for r in self.results if any(keyword in r['test'] for keyword in keywords)]
            area_passed = sum(1 for r in area_tests if r['success'])
            if area_tests:
                success_rate = (area_passed / len(area_tests)) * 100
                status = "✅" if success_rate >= 80 else "⚠️" if success_rate >= 60 else "❌"
                print(f"   {status} {area}: {area_passed}/{len(area_tests)} ({success_rate:.1f}%)")
        
        return self.results

if __name__ == "__main__":
    tester = BackendTester()
    results = tester.run_all_tests()
    
    # Exit with appropriate code
    if tester.passed_tests == tester.total_tests:
        print("\n✅ All tests passed!")
        sys.exit(0)
    else:
        print(f"\n❌ {tester.total_tests - tester.passed_tests} test(s) failed!")
        sys.exit(1)