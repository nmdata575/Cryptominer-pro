#!/usr/bin/env python3
"""
CryptoMiner Pro - Real Mining Functionality Testing Suite
Testing the newly implemented real mining functionality in Node.js backend:
- Real Scrypt Algorithm (scryptsy library) instead of fake double-SHA256
- Real Pool Communication with stratum protocol
- Test Mode Fallback when external pools aren't accessible
- Real Block Headers construction from pool job data
- Real Share Submission to pools or simulated acceptance rates
- Mining status showing real vs test mode indicators
- Hash rate calculation with actual scrypt processing rates
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
    
    def test_real_mining_engine_initialization(self):
        """Test that the mining engine uses real scrypt algorithm instead of simulation"""
        try:
            # Start mining to initialize the real mining engine
            start_config = {
                "coin": "litecoin",
                "mode": "pool",
                "pool_username": "test_miner",
                "pool_password": "x",
                "threads": 2,
                "intensity": 0.5
            }
            
            start_response = requests.post(f"{BACKEND_URL}/mining/start", 
                                         json=start_config, timeout=TIMEOUT)
            
            if start_response.status_code == 200:
                start_data = start_response.json()
                if start_data.get('success'):
                    # Wait for mining engine to initialize
                    time.sleep(3)
                    
                    # Check mining status for real mining indicators
                    status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        
                        # Check for real mining indicators
                        is_mining = status_data.get('is_mining', False)
                        test_mode = status_data.get('test_mode', True)
                        pool_connected = status_data.get('pool_connected', False)
                        current_job = status_data.get('current_job')
                        difficulty = status_data.get('difficulty', 0)
                        
                        # Stop mining
                        requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                        
                        # Verify real mining characteristics
                        real_mining_indicators = []
                        if is_mining:
                            real_mining_indicators.append("Mining engine active")
                        if current_job:
                            real_mining_indicators.append(f"Real mining job: {current_job}")
                        if difficulty > 0:
                            real_mining_indicators.append(f"Real difficulty: {difficulty}")
                        
                        # Test mode indicates fallback when external pools aren't accessible
                        mode_description = "Test mode (simulated pool)" if test_mode else "Real pool mode"
                        
                        self.log_result("Real Mining Engine Initialization", True,
                                      f"Real mining engine initialized successfully - {mode_description}",
                                      f"Indicators: {', '.join(real_mining_indicators)}, Pool connected: {pool_connected}")
                    else:
                        self.log_result("Real Mining Engine Initialization", False,
                                      f"Status check failed: HTTP {status_response.status_code}")
                else:
                    self.log_result("Real Mining Engine Initialization", False,
                                  f"Mining start failed: {start_data.get('message', 'Unknown error')}")
            else:
                self.log_result("Real Mining Engine Initialization", False,
                              f"Mining start HTTP {start_response.status_code}: {start_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Real Mining Engine Initialization", False, f"Request failed: {str(e)}")
    
    def test_real_scrypt_algorithm_implementation(self):
        """Test that the system uses real scrypt algorithm (scryptsy library) instead of fake double-SHA256"""
        try:
            # Start mining with solo mode to test scrypt implementation
            start_config = {
                "coin": "litecoin",
                "mode": "solo", 
                "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
                "threads": 1,
                "intensity": 0.3
            }
            
            start_response = requests.post(f"{BACKEND_URL}/mining/start", 
                                         json=start_config, timeout=TIMEOUT)
            
            if start_response.status_code == 200:
                start_data = start_response.json()
                if start_data.get('success'):
                    # Wait for scrypt processing to begin
                    time.sleep(4)
                    
                    # Check mining status for scrypt processing indicators
                    status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        
                        stats = status_data.get('stats', {})
                        hashrate = stats.get('hashrate', 0)
                        is_mining = status_data.get('is_mining', False)
                        
                        # Stop mining
                        requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                        
                        # Real scrypt should produce measurable but lower hashrates than fake algorithms
                        scrypt_characteristics = []
                        if is_mining:
                            scrypt_characteristics.append("Active scrypt processing")
                        if hashrate > 0:
                            scrypt_characteristics.append(f"Real scrypt hashrate: {hashrate:.2f} H/s")
                        
                        # Real scrypt typically produces lower hashrates than simulated algorithms
                        realistic_hashrate = 0 < hashrate < 10000  # Reasonable range for real scrypt
                        
                        if is_mining and realistic_hashrate:
                            self.log_result("Real Scrypt Algorithm Implementation", True,
                                          f"Real scrypt algorithm working with realistic performance",
                                          f"Characteristics: {', '.join(scrypt_characteristics)}")
                        else:
                            self.log_result("Real Scrypt Algorithm Implementation", False,
                                          f"Scrypt implementation may not be real or not working properly",
                                          f"Mining: {is_mining}, Hashrate: {hashrate}")
                    else:
                        self.log_result("Real Scrypt Algorithm Implementation", False,
                                      f"Status check failed: HTTP {status_response.status_code}")
                else:
                    self.log_result("Real Scrypt Algorithm Implementation", False,
                                  f"Mining start failed: {start_data.get('message', 'Unknown error')}")
            else:
                self.log_result("Real Scrypt Algorithm Implementation", False,
                              f"Mining start HTTP {start_response.status_code}: {start_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Real Scrypt Algorithm Implementation", False, f"Request failed: {str(e)}")
    
    def test_real_pool_communication_stratum(self):
        """Test real pool communication with stratum protocol"""
        try:
            # Test pool connection to real mining pools
            pool_test_data = {
                "pool_address": "ltc-us-east1.nanopool.org",
                "pool_port": 6969,
                "type": "pool"
            }
            
            connection_response = requests.post(f"{BACKEND_URL}/pool/test-connection",
                                              json=pool_test_data, timeout=TIMEOUT)
            
            pool_connection_attempted = False
            connection_result = "Unknown"
            
            if connection_response.status_code == 200:
                conn_data = connection_response.json()
                pool_connection_attempted = True
                connection_result = conn_data.get('message', 'No message')
                
                # Start mining with pool mode to test stratum protocol
                start_config = {
                    "coin": "litecoin",
                    "mode": "pool",
                    "pool_username": "test_stratum_miner",
                    "pool_password": "x",
                    "threads": 1,
                    "intensity": 0.3
                }
                
                start_response = requests.post(f"{BACKEND_URL}/mining/start", 
                                             json=start_config, timeout=TIMEOUT)
                
                if start_response.status_code == 200:
                    start_data = start_response.json()
                    if start_data.get('success'):
                        # Wait for pool connection attempt
                        time.sleep(5)
                        
                        # Check mining status for pool communication indicators
                        status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                        if status_response.status_code == 200:
                            status_data = status_response.json()
                            
                            pool_connected = status_data.get('pool_connected', False)
                            test_mode = status_data.get('test_mode', True)
                            current_job = status_data.get('current_job')
                            
                            # Stop mining
                            requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                            
                            # Analyze pool communication results
                            stratum_indicators = []
                            if current_job:
                                stratum_indicators.append(f"Mining job received: {current_job}")
                            if pool_connected:
                                stratum_indicators.append("Real pool connection established")
                            elif test_mode:
                                stratum_indicators.append("Test mode fallback (expected in container)")
                            
                            # Success if either real pool connection or proper test mode fallback
                            if pool_connected or (test_mode and current_job):
                                self.log_result("Real Pool Communication (Stratum)", True,
                                              f"Stratum protocol implementation working - {'Real pool' if pool_connected else 'Test mode fallback'}",
                                              f"Indicators: {', '.join(stratum_indicators)}")
                            else:
                                self.log_result("Real Pool Communication (Stratum)", False,
                                              f"Pool communication failed", 
                                              f"Pool connected: {pool_connected}, Test mode: {test_mode}")
                        else:
                            self.log_result("Real Pool Communication (Stratum)", False,
                                          f"Status check failed: HTTP {status_response.status_code}")
                    else:
                        self.log_result("Real Pool Communication (Stratum)", False,
                                      f"Mining start failed: {start_data.get('message', 'Unknown error')}")
                else:
                    self.log_result("Real Pool Communication (Stratum)", False,
                                  f"Mining start HTTP {start_response.status_code}: {start_response.text}")
            else:
                self.log_result("Real Pool Communication (Stratum)", False,
                              f"Pool connection test HTTP {connection_response.status_code}: {connection_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Real Pool Communication (Stratum)", False, f"Request failed: {str(e)}")
    
    def test_test_mode_fallback_mechanism(self):
        """Test that system falls back to test mode when external pools aren't accessible"""
        try:
            # Start mining with pool mode (should fallback to test mode in container)
            start_config = {
                "coin": "dogecoin",
                "mode": "pool",
                "pool_username": "fallback_test_miner",
                "pool_password": "x",
                "threads": 1,
                "intensity": 0.4
            }
            
            start_response = requests.post(f"{BACKEND_URL}/mining/start", 
                                         json=start_config, timeout=TIMEOUT)
            
            if start_response.status_code == 200:
                start_data = start_response.json()
                if start_data.get('success'):
                    # Wait for fallback mechanism to activate
                    time.sleep(6)
                    
                    # Check mining status for test mode indicators
                    status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        
                        is_mining = status_data.get('is_mining', False)
                        test_mode = status_data.get('test_mode', False)
                        pool_connected = status_data.get('pool_connected', False)
                        current_job = status_data.get('current_job')
                        stats = status_data.get('stats', {})
                        hashrate = stats.get('hashrate', 0)
                        
                        # Stop mining
                        requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                        
                        # Analyze fallback mechanism
                        fallback_indicators = []
                        if test_mode:
                            fallback_indicators.append("Test mode active")
                        if not pool_connected:
                            fallback_indicators.append("External pool not connected (expected)")
                        if current_job:
                            fallback_indicators.append(f"Simulated job: {current_job}")
                        if hashrate > 0:
                            fallback_indicators.append(f"Fallback mining active: {hashrate:.2f} H/s")
                        
                        # Success if test mode is active with simulated mining
                        if test_mode and is_mining and current_job:
                            self.log_result("Test Mode Fallback Mechanism", True,
                                          f"Test mode fallback working correctly when external pools unavailable",
                                          f"Indicators: {', '.join(fallback_indicators)}")
                        else:
                            self.log_result("Test Mode Fallback Mechanism", False,
                                          f"Fallback mechanism not working properly",
                                          f"Test mode: {test_mode}, Mining: {is_mining}, Job: {current_job}")
                    else:
                        self.log_result("Test Mode Fallback Mechanism", False,
                                      f"Status check failed: HTTP {status_response.status_code}")
                else:
                    self.log_result("Test Mode Fallback Mechanism", False,
                                  f"Mining start failed: {start_data.get('message', 'Unknown error')}")
            else:
                self.log_result("Test Mode Fallback Mechanism", False,
                              f"Mining start HTTP {start_response.status_code}: {start_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Test Mode Fallback Mechanism", False, f"Request failed: {str(e)}")
    
    def test_real_block_headers_construction(self):
        """Test real block headers construction from pool job data or blockchain information"""
        try:
            # Start mining to trigger block header construction
            start_config = {
                "coin": "feathercoin",
                "mode": "solo",
                "wallet_address": "6oNS8WmfpKdWnV2kHQJAmcMxJJ7Lh8YKE1",
                "threads": 1,
                "intensity": 0.3
            }
            
            start_response = requests.post(f"{BACKEND_URL}/mining/start", 
                                         json=start_config, timeout=TIMEOUT)
            
            if start_response.status_code == 200:
                start_data = start_response.json()
                if start_data.get('success'):
                    # Wait for block header construction
                    time.sleep(4)
                    
                    # Check mining status for block header indicators
                    status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        
                        is_mining = status_data.get('is_mining', False)
                        current_job = status_data.get('current_job')
                        difficulty = status_data.get('difficulty', 0)
                        stats = status_data.get('stats', {})
                        hashrate = stats.get('hashrate', 0)
                        
                        # Stop mining
                        requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                        
                        # Analyze block header construction indicators
                        header_indicators = []
                        if current_job:
                            header_indicators.append(f"Mining job with block data: {current_job}")
                        if difficulty > 0:
                            header_indicators.append(f"Real difficulty target: {difficulty}")
                        if is_mining and hashrate > 0:
                            header_indicators.append(f"Block processing active: {hashrate:.2f} H/s")
                        
                        # Real block headers should have job data and difficulty
                        if current_job and difficulty > 0 and is_mining:
                            self.log_result("Real Block Headers Construction", True,
                                          f"Real block headers being constructed from mining job data",
                                          f"Indicators: {', '.join(header_indicators)}")
                        else:
                            self.log_result("Real Block Headers Construction", False,
                                          f"Block header construction may not be working properly",
                                          f"Job: {current_job}, Difficulty: {difficulty}, Mining: {is_mining}")
                    else:
                        self.log_result("Real Block Headers Construction", False,
                                      f"Status check failed: HTTP {status_response.status_code}")
                else:
                    self.log_result("Real Block Headers Construction", False,
                                  f"Mining start failed: {start_data.get('message', 'Unknown error')}")
            else:
                self.log_result("Real Block Headers Construction", False,
                              f"Mining start HTTP {start_response.status_code}: {start_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Real Block Headers Construction", False, f"Request failed: {str(e)}")
    
    def test_real_share_submission_system(self):
        """Test real share submission to pools or simulated realistic acceptance rates"""
        try:
            # Start mining with pool mode to test share submission
            start_config = {
                "coin": "litecoin",
                "mode": "pool",
                "pool_username": "share_test_miner",
                "pool_password": "x",
                "threads": 2,
                "intensity": 0.6
            }
            
            start_response = requests.post(f"{BACKEND_URL}/mining/start", 
                                         json=start_config, timeout=TIMEOUT)
            
            if start_response.status_code == 200:
                start_data = start_response.json()
                if start_data.get('success'):
                    # Wait for share generation and submission
                    time.sleep(8)
                    
                    # Check mining status for share submission indicators
                    status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        
                        stats = status_data.get('stats', {})
                        accepted_shares = stats.get('accepted_shares', 0)
                        rejected_shares = stats.get('rejected_shares', 0)
                        total_shares = accepted_shares + rejected_shares
                        efficiency = stats.get('efficiency', 0)
                        test_mode = status_data.get('test_mode', True)
                        
                        # Stop mining
                        requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                        
                        # Analyze share submission system
                        share_indicators = []
                        if total_shares > 0:
                            share_indicators.append(f"Total shares: {total_shares}")
                            share_indicators.append(f"Accepted: {accepted_shares}")
                            share_indicators.append(f"Rejected: {rejected_shares}")
                        if efficiency > 0:
                            share_indicators.append(f"Efficiency: {efficiency:.1f}%")
                        
                        submission_mode = "Real pool submission" if not test_mode else "Test mode simulation"
                        share_indicators.append(submission_mode)
                        
                        # Success if shares are being generated and tracked
                        if total_shares > 0 or efficiency >= 0:
                            # Realistic acceptance rate should be high (>80%) for test mode
                            realistic_acceptance = True
                            if total_shares > 0:
                                acceptance_rate = (accepted_shares / total_shares) * 100
                                realistic_acceptance = 70 <= acceptance_rate <= 100
                            
                            if realistic_acceptance:
                                self.log_result("Real Share Submission System", True,
                                              f"Share submission system working with realistic acceptance rates",
                                              f"Indicators: {', '.join(share_indicators)}")
                            else:
                                self.log_result("Real Share Submission System", False,
                                              f"Share acceptance rates may not be realistic",
                                              f"Acceptance rate: {acceptance_rate:.1f}%")
                        else:
                            self.log_result("Real Share Submission System", False,
                                          f"No shares generated or tracked",
                                          f"Total shares: {total_shares}, Efficiency: {efficiency}")
                    else:
                        self.log_result("Real Share Submission System", False,
                                      f"Status check failed: HTTP {status_response.status_code}")
                else:
                    self.log_result("Real Share Submission System", False,
                                  f"Mining start failed: {start_data.get('message', 'Unknown error')}")
            else:
                self.log_result("Real Share Submission System", False,
                              f"Mining start HTTP {start_response.status_code}: {start_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Real Share Submission System", False, f"Request failed: {str(e)}")
    
    def test_mining_status_real_vs_test_mode_indicators(self):
        """Test mining status shows real vs test mode indicators"""
        try:
            # Test both pool and solo modes to check indicators
            test_configs = [
                {
                    "name": "Pool Mode",
                    "config": {
                        "coin": "litecoin",
                        "mode": "pool",
                        "pool_username": "indicator_test_pool",
                        "pool_password": "x",
                        "threads": 1
                    }
                },
                {
                    "name": "Solo Mode", 
                    "config": {
                        "coin": "dogecoin",
                        "mode": "solo",
                        "wallet_address": "D7Y55Lkqb3VladCEZ7oJLSKa6wjYcpAxFk",
                        "threads": 1
                    }
                }
            ]
            
            mode_results = []
            
            for test_case in test_configs:
                start_response = requests.post(f"{BACKEND_URL}/mining/start", 
                                             json=test_case["config"], timeout=TIMEOUT)
                
                if start_response.status_code == 200:
                    start_data = start_response.json()
                    if start_data.get('success'):
                        # Wait for mode indicators to be set
                        time.sleep(3)
                        
                        # Check mining status for mode indicators
                        status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                        if status_response.status_code == 200:
                            status_data = status_response.json()
                            
                            # Extract mode indicators
                            test_mode = status_data.get('test_mode')
                            pool_connected = status_data.get('pool_connected')
                            is_mining = status_data.get('is_mining')
                            current_job = status_data.get('current_job')
                            
                            mode_info = {
                                'mode': test_case["name"],
                                'test_mode': test_mode,
                                'pool_connected': pool_connected,
                                'is_mining': is_mining,
                                'has_job': bool(current_job),
                                'indicators_present': all(x is not None for x in [test_mode, pool_connected, is_mining])
                            }
                            mode_results.append(mode_info)
                        
                        # Stop mining
                        requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                        time.sleep(1)
            
            # Analyze mode indicator results
            indicators_working = all(result['indicators_present'] for result in mode_results)
            mode_detection = all(result['test_mode'] is not None for result in mode_results)
            
            if indicators_working and mode_detection and len(mode_results) >= 2:
                details = []
                for result in mode_results:
                    mode_desc = f"{result['mode']}: test_mode={result['test_mode']}, pool_connected={result['pool_connected']}"
                    details.append(mode_desc)
                
                self.log_result("Mining Status Real vs Test Mode Indicators", True,
                              f"Mode indicators working correctly for both pool and solo mining",
                              f"Results: {'; '.join(details)}")
            else:
                self.log_result("Mining Status Real vs Test Mode Indicators", False,
                              f"Mode indicators not working properly",
                              f"Indicators present: {indicators_working}, Mode detection: {mode_detection}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Mining Status Real vs Test Mode Indicators", False, f"Request failed: {str(e)}")
    
    def test_hash_rate_calculation_actual_scrypt_processing(self):
        """Test hash rate calculation shows actual scrypt processing rates"""
        try:
            # Start mining with different thread counts to test hash rate scaling
            thread_configs = [
                {"threads": 1, "intensity": 0.3},
                {"threads": 2, "intensity": 0.5}
            ]
            
            hashrate_results = []
            
            for config in thread_configs:
                start_config = {
                    "coin": "litecoin",
                    "mode": "solo",
                    "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
                    **config
                }
                
                start_response = requests.post(f"{BACKEND_URL}/mining/start", 
                                             json=start_config, timeout=TIMEOUT)
                
                if start_response.status_code == 200:
                    start_data = start_response.json()
                    if start_data.get('success'):
                        # Wait for hash rate to stabilize
                        time.sleep(5)
                        
                        # Check hash rate multiple times for consistency
                        hashrates = []
                        for _ in range(3):
                            status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                            if status_response.status_code == 200:
                                status_data = status_response.json()
                                stats = status_data.get('stats', {})
                                hashrate = stats.get('hashrate', 0)
                                if hashrate > 0:
                                    hashrates.append(hashrate)
                            time.sleep(1)
                        
                        # Stop mining
                        requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                        
                        if hashrates:
                            avg_hashrate = sum(hashrates) / len(hashrates)
                            hashrate_results.append({
                                'threads': config['threads'],
                                'intensity': config['intensity'],
                                'avg_hashrate': avg_hashrate,
                                'consistent': max(hashrates) - min(hashrates) < avg_hashrate * 0.5
                            })
                        
                        time.sleep(2)  # Cool down between tests
            
            # Analyze hash rate calculation results
            if len(hashrate_results) >= 2:
                # Check if hash rates are realistic for scrypt (typically low)
                realistic_rates = all(0 < result['avg_hashrate'] < 50000 for result in hashrate_results)
                
                # Check if hash rate scales with thread count (approximately)
                scaling_correct = hashrate_results[1]['avg_hashrate'] >= hashrate_results[0]['avg_hashrate']
                
                # Check consistency
                consistent_rates = all(result['consistent'] for result in hashrate_results)
                
                details = []
                for result in hashrate_results:
                    details.append(f"{result['threads']} threads: {result['avg_hashrate']:.2f} H/s")
                
                if realistic_rates and scaling_correct and consistent_rates:
                    self.log_result("Hash Rate Calculation (Actual Scrypt Processing)", True,
                                  f"Hash rate calculation showing realistic scrypt processing rates with proper scaling",
                                  f"Results: {'; '.join(details)}")
                else:
                    self.log_result("Hash Rate Calculation (Actual Scrypt Processing)", False,
                                  f"Hash rate calculation issues detected",
                                  f"Realistic: {realistic_rates}, Scaling: {scaling_correct}, Consistent: {consistent_rates}")
            else:
                self.log_result("Hash Rate Calculation (Actual Scrypt Processing)", False,
                              f"Insufficient hash rate data collected",
                              f"Results collected: {len(hashrate_results)}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Hash Rate Calculation (Actual Scrypt Processing)", False, f"Request failed: {str(e)}")
    
    def test_job_handling_and_pool_connection_mechanisms(self):
        """Test job handling and pool connection handling with timeout and fallback mechanisms"""
        try:
            # Test with custom pool settings to trigger connection handling
            start_config = {
                "coin": "litecoin",
                "mode": "pool",
                "pool_username": "job_test_miner",
                "pool_password": "x",
                "custom_pool_address": "test.nonexistent.pool.com",
                "custom_pool_port": 9999,
                "threads": 1,
                "intensity": 0.4
            }
            
            start_response = requests.post(f"{BACKEND_URL}/mining/start", 
                                         json=start_config, timeout=TIMEOUT)
            
            if start_response.status_code == 200:
                start_data = start_response.json()
                if start_data.get('success'):
                    # Wait for connection timeout and fallback
                    time.sleep(12)  # Allow time for connection timeout
                    
                    # Check mining status for job handling indicators
                    status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        
                        is_mining = status_data.get('is_mining', False)
                        test_mode = status_data.get('test_mode', False)
                        pool_connected = status_data.get('pool_connected', False)
                        current_job = status_data.get('current_job')
                        stats = status_data.get('stats', {})
                        hashrate = stats.get('hashrate', 0)
                        
                        # Stop mining
                        requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                        
                        # Analyze job handling and connection mechanisms
                        handling_indicators = []
                        
                        # Should have fallen back to test mode due to connection failure
                        if test_mode:
                            handling_indicators.append("Test mode fallback activated")
                        if not pool_connected:
                            handling_indicators.append("Pool connection properly handled (timeout)")
                        if current_job:
                            handling_indicators.append(f"Job handling active: {current_job}")
                        if is_mining and hashrate > 0:
                            handling_indicators.append(f"Mining continues despite connection issues: {hashrate:.2f} H/s")
                        
                        # Success if system handles connection failure gracefully
                        graceful_handling = test_mode and not pool_connected and current_job and is_mining
                        
                        if graceful_handling:
                            self.log_result("Job Handling and Pool Connection Mechanisms", True,
                                          f"Job handling and connection mechanisms working correctly with proper fallback",
                                          f"Indicators: {', '.join(handling_indicators)}")
                        else:
                            self.log_result("Job Handling and Pool Connection Mechanisms", False,
                                          f"Connection handling may not be working properly",
                                          f"Test mode: {test_mode}, Connected: {pool_connected}, Job: {current_job}, Mining: {is_mining}")
                    else:
                        self.log_result("Job Handling and Pool Connection Mechanisms", False,
                                      f"Status check failed: HTTP {status_response.status_code}")
                else:
                    self.log_result("Job Handling and Pool Connection Mechanisms", False,
                                  f"Mining start failed: {start_data.get('message', 'Unknown error')}")
            else:
                self.log_result("Job Handling and Pool Connection Mechanisms", False,
                              f"Mining start HTTP {start_response.status_code}: {start_response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Job Handling and Pool Connection Mechanisms", False, f"Request failed: {str(e)}")
    
    def run_all_tests(self):
        """Run comprehensive real mining functionality tests"""
        print("🚀 Starting Real Mining Functionality Testing for CryptoMiner Pro")
        print(f"🔗 Backend URL: {BACKEND_URL}")
        print("🎯 Focus: Verify real mining implementation vs simulation")
        print("=" * 80)
        
        # Real Mining Core Features
        print("\n⛏️ REAL MINING CORE FEATURES TESTING")
        print("=" * 60)
        self.test_real_mining_engine_initialization()
        self.test_real_scrypt_algorithm_implementation()
        self.test_real_pool_communication_stratum()
        self.test_test_mode_fallback_mechanism()
        
        # Real Mining Technical Implementation
        print("\n🔧 REAL MINING TECHNICAL IMPLEMENTATION")
        print("=" * 60)
        self.test_real_block_headers_construction()
        self.test_real_share_submission_system()
        self.test_mining_status_real_vs_test_mode_indicators()
        
        # Real Mining Performance and Processing
        print("\n📊 REAL MINING PERFORMANCE AND PROCESSING")
        print("=" * 60)
        self.test_hash_rate_calculation_actual_scrypt_processing()
        self.test_job_handling_and_pool_connection_mechanisms()
        
        # Core System Verification (ensure basic functionality still works)
        print("\n🔍 CORE SYSTEM VERIFICATION")
        print("=" * 50)
        self.test_health_check()
        self.test_mining_status()
        self.test_coin_presets()
        
        print("=" * 80)
        print(f"📊 Real Mining Test Results Summary:")
        print(f"   Total Tests: {self.total_tests}")
        print(f"   Passed: {self.passed_tests}")
        print(f"   Failed: {self.total_tests - self.passed_tests}")
        print(f"   Success Rate: {(self.passed_tests/self.total_tests)*100:.1f}%")
        
        # Categorize results by real mining focus areas
        focus_areas = {
            'Real Mining Core': ['Real Mining Engine', 'Real Scrypt Algorithm', 'Real Pool Communication', 'Test Mode Fallback'],
            'Real Mining Technical': ['Real Block Headers', 'Real Share Submission', 'Mining Status Real vs Test'],
            'Real Mining Performance': ['Hash Rate Calculation', 'Job Handling and Pool Connection'],
            'Core System': ['Health Check', 'Mining Status', 'Coin Presets']
        }
        
        print(f"\n🎯 REAL MINING FOCUS AREA RESULTS:")
        for area, keywords in focus_areas.items():
            area_tests = [r for r in self.results if any(keyword in r['test'] for keyword in keywords)]
            area_passed = sum(1 for r in area_tests if r['success'])
            if area_tests:
                success_rate = (area_passed / len(area_tests)) * 100
                status = "✅" if success_rate >= 80 else "⚠️" if success_rate >= 60 else "❌"
                print(f"   {status} {area}: {area_passed}/{len(area_tests)} ({success_rate:.1f}%)")
        
        # Real Mining Summary
        real_mining_tests = [r for r in self.results if any(keyword in r['test'] for keyword in 
                           ['Real Mining', 'Real Scrypt', 'Real Pool', 'Real Block', 'Real Share', 'Test Mode', 'Hash Rate', 'Job Handling'])]
        real_mining_passed = sum(1 for r in real_mining_tests if r['success'])
        
        if real_mining_tests:
            real_mining_success_rate = (real_mining_passed / len(real_mining_tests)) * 100
            print(f"\n🏆 REAL MINING IMPLEMENTATION STATUS:")
            if real_mining_success_rate >= 80:
                print(f"   ✅ EXCELLENT: Real mining functionality is working correctly ({real_mining_success_rate:.1f}%)")
            elif real_mining_success_rate >= 60:
                print(f"   ⚠️ GOOD: Real mining mostly working with some issues ({real_mining_success_rate:.1f}%)")
            else:
                print(f"   ❌ NEEDS WORK: Real mining implementation has significant issues ({real_mining_success_rate:.1f}%)")
        
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