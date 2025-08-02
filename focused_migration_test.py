#!/usr/bin/env python3
"""
CryptoMiner Pro Backend Testing Suite - Focused Migration Testing
Focus: Testing specific areas mentioned in review request after directory migration
"""

import requests
import json
import time
import sys

# Backend URL from frontend environment
BACKEND_URL = "https://b8a64dbe-314e-43b8-9274-f05e86511466.preview.emergentagent.com"
API_BASE = f"{BACKEND_URL}/api"

class FocusedTester:
    def __init__(self):
        self.test_results = []
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Origin': BACKEND_URL,
            'User-Agent': 'CryptoMiner-Pro-Focused-Test/1.0'
        })
        
    def log_test(self, test_name, success, details=""):
        """Log test results"""
        status = "✅ PASSED" if success else "❌ FAILED"
        result = {
            'test': test_name,
            'status': status,
            'success': success,
            'details': details
        }
        self.test_results.append(result)
        print(f"{status} - {test_name}")
        if details:
            print(f"   Details: {details}")
        print()

    def run_focused_tests(self):
        """Run focused tests based on review request"""
        print("🎯 CryptoMiner Pro - Focused Migration Testing")
        print("Testing specific areas after directory migration from /opt/cryptominer-pro to /root/Cryptominer-pro")
        print("=" * 80)
        print()
        
        # 1. Basic Health Checks
        print("1️⃣ BASIC HEALTH CHECKS")
        print("-" * 40)
        self.test_basic_health_checks()
        print()
        
        # 2. Mining Operations
        print("2️⃣ MINING OPERATIONS")
        print("-" * 40)
        self.test_mining_operations()
        print()
        
        # 3. Enhanced Mongoose Model Integration
        print("3️⃣ ENHANCED MONGOOSE MODEL INTEGRATION")
        print("-" * 40)
        self.test_mongoose_integration()
        print()
        
        # 4. Mining Session Management
        print("4️⃣ MINING SESSION MANAGEMENT")
        print("-" * 40)
        self.test_session_management()
        print()
        
        # 5. Database Operations
        print("5️⃣ DATABASE OPERATIONS")
        print("-" * 40)
        self.test_database_operations()
        print()
        
        # 6. MongoDB Connectivity
        print("6️⃣ MONGODB CONNECTIVITY")
        print("-" * 40)
        self.test_mongodb_connectivity()
        print()
        
        # 7. Thread Scaling (Basic Test)
        print("7️⃣ THREAD SCALING (BASIC)")
        print("-" * 40)
        self.test_thread_scaling_basic()
        print()
        
        # Summary
        self.print_summary()
        
        return self.get_success_rate() >= 80

    def test_basic_health_checks(self):
        """Test basic health check endpoints"""
        endpoints = [
            ("/health", "Health Check"),
            ("/system/stats", "System Stats"),
            ("/system/cpu-info", "CPU Info")
        ]
        
        for endpoint, name in endpoints:
            try:
                response = self.session.get(f"{API_BASE}{endpoint}", timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    if endpoint == "/health":
                        success = data.get('status') == 'healthy' and 'node_version' in data
                        details = f"Node.js {data.get('node_version')}, uptime: {data.get('uptime', 0):.1f}s"
                    elif endpoint == "/system/stats":
                        success = 'cpu' in data and 'memory' in data
                        details = f"CPU: {data.get('cpu', {}).get('usage', 0):.1f}%, Memory: {data.get('memory', {}).get('usage', 0):.1f}%"
                    else:  # cpu-info
                        success = 'cores' in data
                        details = f"Cores: {data.get('cores', 0)}, Profiles: {len(data.get('mining_profiles', []))}"
                    
                    self.log_test(f"{name} API Endpoint", success, details)
                else:
                    self.log_test(f"{name} API Endpoint", False, f"Status {response.status_code}")
            except Exception as e:
                self.log_test(f"{name} API Endpoint", False, f"Request failed: {str(e)}")

    def test_mining_operations(self):
        """Test mining operations endpoints"""
        # Test mining status
        try:
            response = self.session.get(f"{API_BASE}/mining/status", timeout=10)
            if response.status_code == 200:
                data = response.json()
                success = 'is_mining' in data and 'stats' in data
                details = f"Mining: {data.get('is_mining')}, Hashrate: {data.get('stats', {}).get('hashrate', 0):.2f} H/s"
                self.log_test("Mining Status API", success, details)
            else:
                self.log_test("Mining Status API", False, f"Status {response.status_code}")
        except Exception as e:
            self.log_test("Mining Status API", False, f"Request failed: {str(e)}")
        
        # Test basic mining start (solo mode)
        try:
            mining_config = {
                "coin": "litecoin",
                "mode": "solo",
                "threads": 2,
                "intensity": 0.5,
                "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
            }
            
            response = self.session.post(f"{API_BASE}/mining/start", json=mining_config, timeout=15)
            if response.status_code == 200:
                data = response.json()
                success = data.get('success', False)
                details = f"Start result: {data.get('message', 'Success')}"
                self.log_test("Mining Start Basic", success, details)
                
                if success:
                    # Wait and check status
                    time.sleep(3)
                    status_response = self.session.get(f"{API_BASE}/mining/status", timeout=10)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        is_mining = status_data.get('is_mining', False)
                        self.log_test("Mining Start Verification", is_mining, f"Mining active: {is_mining}")
                    
                    # Stop mining
                    stop_response = self.session.post(f"{API_BASE}/mining/stop", timeout=10)
                    if stop_response.status_code == 200:
                        stop_data = stop_response.json()
                        stop_success = stop_data.get('success', False) or 'No mining operation' in stop_data.get('message', '')
                        self.log_test("Mining Stop Basic", stop_success, f"Stop result: {stop_data.get('message', 'Success')}")
            else:
                self.log_test("Mining Start Basic", False, f"Status {response.status_code}")
        except Exception as e:
            self.log_test("Mining Start Basic", False, f"Request failed: {str(e)}")

    def test_mongoose_integration(self):
        """Test Enhanced Mongoose Model Integration endpoints"""
        # Test Mining Stats CRUD
        endpoints = [
            ("/mining/stats", "Mining Stats GET"),
            ("/mining/stats/top", "Mining Stats Top"),
            ("/ai/predictions", "AI Predictions GET"),
            ("/ai/model-accuracy", "AI Model Accuracy"),
            ("/config/user/preferences", "User Preferences GET"),
            ("/config/mining/defaults", "Mining Defaults GET")
        ]
        
        for endpoint, name in endpoints:
            try:
                response = self.session.get(f"{API_BASE}{endpoint}", timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    success = data.get('success', True) and ('data' in data or 'accuracy' in data or 'collections' in data)
                    if 'data' in data:
                        details = f"Retrieved {len(data.get('data', []))} items"
                    elif 'accuracy' in data:
                        details = f"Accuracy data available"
                    else:
                        details = "Response valid"
                    self.log_test(name, success, details)
                else:
                    self.log_test(name, False, f"Status {response.status_code}")
            except Exception as e:
                self.log_test(name, False, f"Request failed: {str(e)}")
        
        # Test POST endpoints
        self.test_mining_stats_post()
        self.test_ai_predictions_post()

    def test_mining_stats_post(self):
        """Test POST /api/mining/stats"""
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
                success = data.get('success', False)
                details = f"Stats saved for session: {test_stats['sessionId']}"
                self.log_test("Mining Stats POST", success, details)
            else:
                self.log_test("Mining Stats POST", False, f"Status {response.status_code}")
        except Exception as e:
            self.log_test("Mining Stats POST", False, f"Request failed: {str(e)}")

    def test_ai_predictions_post(self):
        """Test POST /api/ai/predictions"""
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
                success = data.get('success', False)
                details = f"Prediction saved with confidence: {data.get('confidencePercentage', 0)}%"
                self.log_test("AI Predictions POST", success, details)
            else:
                self.log_test("AI Predictions POST", False, f"Status {response.status_code}")
        except Exception as e:
            self.log_test("AI Predictions POST", False, f"Request failed: {str(e)}")

    def test_session_management(self):
        """Test Mining Session Management endpoints"""
        # Start a session
        session_id = None
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
                    self.log_test("Mining Session Start", True, f"Session ID: {session_id}")
                else:
                    self.log_test("Mining Session Start", False, "No session ID returned")
            else:
                self.log_test("Mining Session Start", False, f"Status {response.status_code}")
        except Exception as e:
            self.log_test("Mining Session Start", False, f"Request failed: {str(e)}")
        
        # Update session if we have an ID
        if session_id:
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
                    success = data.get('success', False)
                    details = f"Session updated, efficiency: {data.get('efficiency', 0)}%"
                    self.log_test("Mining Session Update", success, details)
                else:
                    self.log_test("Mining Session Update", False, f"Status {response.status_code}")
            except Exception as e:
                self.log_test("Mining Session Update", False, f"Request failed: {str(e)}")
            
            # End session
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
                    success = data.get('success', False)
                    details = f"Session ended, duration: {data.get('duration', 0)}s"
                    self.log_test("Mining Session End", success, details)
                else:
                    self.log_test("Mining Session End", False, f"Status {response.status_code}")
            except Exception as e:
                self.log_test("Mining Session End", False, f"Request failed: {str(e)}")

    def test_database_operations(self):
        """Test Database Operations endpoints"""
        endpoints = [
            ("/maintenance/stats", "Database Stats"),
            ("/maintenance/cleanup", "Database Cleanup", "POST")
        ]
        
        for endpoint_info in endpoints:
            endpoint = endpoint_info[0]
            name = endpoint_info[1]
            method = endpoint_info[2] if len(endpoint_info) > 2 else "GET"
            
            try:
                if method == "POST":
                    response = self.session.post(f"{API_BASE}{endpoint}", timeout=15)
                else:
                    response = self.session.get(f"{API_BASE}{endpoint}", timeout=10)
                
                if response.status_code == 200:
                    data = response.json()
                    success = data.get('success', True)
                    if 'collections' in data:
                        details = f"Total docs: {data.get('totalDocuments', 0)}"
                    elif 'cleaned' in data:
                        details = f"Cleanup completed, retention: {data.get('retentionPolicy', 'unknown')}"
                    else:
                        details = "Operation successful"
                    self.log_test(name, success, details)
                else:
                    self.log_test(name, False, f"Status {response.status_code}")
            except Exception as e:
                self.log_test(name, False, f"Request failed: {str(e)}")

    def test_mongodb_connectivity(self):
        """Test MongoDB connectivity through database-dependent endpoints"""
        db_endpoints = [
            "/mining/stats",
            "/ai/predictions", 
            "/config/user/preferences",
            "/maintenance/stats"
        ]
        
        successful = 0
        total = len(db_endpoints)
        
        for endpoint in db_endpoints:
            try:
                response = self.session.get(f"{API_BASE}{endpoint}", timeout=10)
                if response.status_code == 200:
                    successful += 1
            except:
                pass
        
        success_rate = (successful / total) * 100
        success = success_rate >= 75
        details = f"{successful}/{total} database endpoints accessible ({success_rate:.1f}%)"
        self.log_test("MongoDB Connectivity", success, details)

    def test_thread_scaling_basic(self):
        """Test basic thread scaling with different thread counts"""
        thread_counts = [4, 8, 16]
        successful_tests = 0
        
        for threads in thread_counts:
            try:
                mining_config = {
                    "coin": "litecoin",
                    "mode": "solo",
                    "threads": threads,
                    "intensity": 0.5,
                    "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
                }
                
                # Start mining
                response = self.session.post(f"{API_BASE}/mining/start", json=mining_config, timeout=15)
                if response.status_code == 200 and response.json().get('success'):
                    time.sleep(2)
                    
                    # Check status
                    status_response = self.session.get(f"{API_BASE}/mining/status", timeout=10)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        is_mining = status_data.get('is_mining', False)
                        if is_mining:
                            successful_tests += 1
                    
                    # Stop mining
                    self.session.post(f"{API_BASE}/mining/stop", timeout=10)
                    time.sleep(1)
                    
            except Exception as e:
                pass
        
        success = successful_tests >= 2  # At least 2 out of 3 thread counts should work
        details = f"{successful_tests}/{len(thread_counts)} thread configurations successful"
        self.log_test("Thread Scaling Basic Test", success, details)

    def get_success_rate(self):
        """Calculate success rate"""
        if not self.test_results:
            return 0
        passed = sum(1 for result in self.test_results if result['success'])
        return (passed / len(self.test_results)) * 100

    def print_summary(self):
        """Print test summary"""
        print("=" * 80)
        print("📊 TEST SUMMARY")
        print("=" * 80)
        
        passed_tests = sum(1 for result in self.test_results if result['success'])
        total_tests = len(self.test_results)
        success_rate = self.get_success_rate()
        
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {total_tests - passed_tests}")
        print(f"Success Rate: {success_rate:.1f}%")
        print()
        
        if success_rate >= 90:
            print("🎉 EXCELLENT: All systems operational after migration!")
        elif success_rate >= 80:
            print("✅ GOOD: Migration successful with minor issues!")
        elif success_rate >= 60:
            print("⚠️  ACCEPTABLE: Migration mostly successful!")
        else:
            print("❌ ISSUES: Migration has significant problems!")
        
        print()
        failed_tests = [result for result in self.test_results if not result['success']]
        if failed_tests:
            print("Failed Tests:")
            for result in failed_tests:
                print(f"  ❌ {result['test']}: {result['details']}")
        else:
            print("🎉 All tests passed!")

if __name__ == "__main__":
    tester = FocusedTester()
    success = tester.run_focused_tests()
    sys.exit(0 if success else 1)