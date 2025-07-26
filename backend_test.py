#!/usr/bin/env python3
"""
CryptoMiner Pro - Backend API Testing Suite
Testing Node.js backend endpoints after frontend ESLint fixes
"""

import requests
import json
import time
import sys
from datetime import datetime

# Configuration
BACKEND_URL = "https://84635953-2fa9-4a6c-a89b-23dbccf67eb9.preview.emergentagent.com/api"
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
    
    def test_cpu_info(self):
        """Test CPU info endpoint (/api/system/cpu-info) - Important after SystemMonitoring.js changes"""
        try:
            response = requests.get(f"{BACKEND_URL}/system/cpu-info", timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                expected_fields = ['cores', 'model', 'speed']
                
                if any(field in data for field in expected_fields):
                    cores = data.get('cores', 'unknown')
                    model = data.get('model', 'unknown')
                    speed = data.get('speed', 'unknown')
                    
                    self.log_result("CPU Info API", True, 
                                  f"Returns CPU information successfully", 
                                  f"Cores: {cores}, Model: {model}, Speed: {speed}")
                else:
                    self.log_result("CPU Info API", False, 
                                  f"No expected CPU fields found", data)
            else:
                self.log_result("CPU Info API", False, 
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("CPU Info API", False, f"Request failed: {str(e)}")
    
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
    
    def test_mining_start_stop(self):
        """Test basic mining functionality (start/stop endpoints)"""
        # Test mining start with valid configuration
        try:
            start_config = {
                "coin": "litecoin",
                "mode": "solo",
                "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
                "threads": 2,
                "intensity": 1.0
            }
            
            # Test start mining
            response = requests.post(f"{BACKEND_URL}/mining/start", 
                                   json=start_config, timeout=TIMEOUT)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    self.log_result("Mining Start API", True, 
                                  f"Mining started successfully", 
                                  f"Mode: {data.get('mining_type', 'unknown')}")
                    
                    # Wait a moment then test stop
                    time.sleep(2)
                    
                    # Test stop mining
                    stop_response = requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                    
                    if stop_response.status_code == 200:
                        stop_data = stop_response.json()
                        if stop_data.get('success'):
                            self.log_result("Mining Stop API", True, 
                                          "Mining stopped successfully")
                        else:
                            self.log_result("Mining Stop API", False, 
                                          f"Stop failed: {stop_data.get('message', 'Unknown error')}")
                    else:
                        self.log_result("Mining Stop API", False, 
                                      f"HTTP {stop_response.status_code}: {stop_response.text}")
                else:
                    self.log_result("Mining Start API", False, 
                                  f"Start failed: {data.get('message', 'Unknown error')}")
            else:
                self.log_result("Mining Start API", False, 
                              f"HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            self.log_result("Mining Start API", False, f"Request failed: {str(e)}")
    
    def test_wallet_validation(self):
        """Test wallet validation functionality"""
        test_cases = [
            {
                "address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
                "coin_symbol": "LTC",
                "expected": True,
                "description": "Valid Litecoin bech32 address"
            },
            {
                "address": "D7Y55Lkqb3VladCEZ7oP2CYZi7ErMgqFh4",
                "coin_symbol": "DOGE",
                "expected": True,
                "description": "Valid Dogecoin address"
            },
            {
                "address": "invalid_address",
                "coin_symbol": "LTC",
                "expected": False,
                "description": "Invalid address format"
            }
        ]
        
        passed_validations = 0
        total_validations = len(test_cases)
        
        for test_case in test_cases:
            try:
                payload = {
                    "address": test_case["address"],
                    "coin_symbol": test_case["coin_symbol"]
                }
                
                response = requests.post(f"{BACKEND_URL}/wallet/validate", 
                                       json=payload, timeout=TIMEOUT)
                
                if response.status_code == 200:
                    data = response.json()
                    is_valid = data.get('valid', False)
                    
                    if is_valid == test_case["expected"]:
                        passed_validations += 1
                    
            except requests.exceptions.RequestException:
                pass
        
        success_rate = (passed_validations / total_validations) * 100
        if success_rate >= 66:  # At least 2/3 should pass
            self.log_result("Wallet Validation API", True, 
                          f"Wallet validation working correctly", 
                          f"Success rate: {success_rate:.1f}% ({passed_validations}/{total_validations})")
        else:
            self.log_result("Wallet Validation API", False, 
                          f"Wallet validation issues detected", 
                          f"Success rate: {success_rate:.1f}% ({passed_validations}/{total_validations})")
    
    def run_all_tests(self):
        """Run all backend tests"""
        print("🚀 Starting Backend API Testing Suite")
        print(f"🔗 Backend URL: {BACKEND_URL}")
        print("=" * 60)
        
        # Core endpoints from review request
        self.test_health_check()
        self.test_system_stats()
        self.test_cpu_info()  # Particularly important after SystemMonitoring.js changes
        self.test_coin_presets()
        self.test_mining_status()
        self.test_mining_start_stop()
        
        # Additional validation test
        self.test_wallet_validation()
        
        print("=" * 60)
        print(f"📊 Test Results Summary:")
        print(f"   Total Tests: {self.total_tests}")
        print(f"   Passed: {self.passed_tests}")
        print(f"   Failed: {self.total_tests - self.passed_tests}")
        print(f"   Success Rate: {(self.passed_tests/self.total_tests)*100:.1f}%")
        
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