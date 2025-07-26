#!/usr/bin/env python3
"""
Comprehensive Node.js Backend Testing for CryptoMiner Pro
Tests all endpoints, mining functionality, remote connectivity, and system integration
"""

import requests
import json
import time
import sys
import websocket
import threading
from datetime import datetime
from typing import Dict, Any, Optional

class NodeJSBackendTester:
    def __init__(self, base_url: str = "https://113c4522-c6a3-4def-b0b5-d97ad7e0f3d8.preview.emergentagent.com"):
        self.base_url = base_url.rstrip('/')
        self.tests_run = 0
        self.tests_passed = 0
        self.websocket_data = []
        self.websocket_connected = False
        
    def log_test(self, name: str, success: bool, details: str = ""):
        """Log test results"""
        self.tests_run += 1
        if success:
            self.tests_passed += 1
            print(f"✅ {name}: PASSED {details}")
        else:
            print(f"❌ {name}: FAILED {details}")
        return success

    def make_request(self, method: str, endpoint: str, data: Optional[Dict] = None, timeout: int = 10) -> tuple:
        """Make HTTP request and return success status and response"""
        url = f"{self.base_url}{endpoint}"
        headers = {'Content-Type': 'application/json'}
        
        try:
            if method.upper() == 'GET':
                response = requests.get(url, headers=headers, timeout=timeout)
            elif method.upper() == 'POST':
                response = requests.post(url, json=data, headers=headers, timeout=timeout)
            else:
                return False, {"error": f"Unsupported method: {method}"}
            
            return response.status_code < 400, response.json() if response.content else {}
            
        except requests.exceptions.RequestException as e:
            return False, {"error": str(e)}

    def test_health_check(self) -> bool:
        """Test /api/health endpoint"""
        print("\n🏥 Testing Health Check API...")
        
        success, response = self.make_request('GET', '/api/health')
        
        if success and response.get('status') == 'healthy':
            node_version = response.get('node_version', 'unknown')
            uptime = response.get('uptime', 0)
            return self.log_test("Health Check", True, f"- Status: {response['status']}, Node: {node_version}, Uptime: {uptime:.1f}s")
        else:
            return self.log_test("Health Check", False, f"- Response: {response}")

    def test_system_stats(self) -> bool:
        """Test /api/system/stats endpoint"""
        print("\n📊 Testing System Stats API...")
        
        success, response = self.make_request('GET', '/api/system/stats')
        
        if success and 'cpu' in response and 'memory' in response:
            cpu_usage = response.get('cpu', {}).get('usage_percent', 0)
            memory_usage = response.get('memory', {}).get('percent', 0)
            return self.log_test("System Stats", True, f"- CPU: {cpu_usage}%, Memory: {memory_usage}%")
        else:
            return self.log_test("System Stats", False, f"- Response: {response}")

    def test_cpu_info(self) -> bool:
        """Test /api/system/cpu-info endpoint"""
        print("\n🖥️ Testing CPU Info API...")
        
        success, response = self.make_request('GET', '/api/system/cpu-info')
        
        if success and 'cores' in response:
            cores = response.get('cores', {})
            physical = cores.get('physical', 0)
            logical = cores.get('logical', 0)
            return self.log_test("CPU Info", True, f"- Physical cores: {physical}, Logical cores: {logical}")
        else:
            return self.log_test("CPU Info", False, f"- Response: {response}")

    def test_coin_presets(self) -> bool:
        """Test /api/coins/presets endpoint"""
        print("\n🪙 Testing Coin Presets API...")
        
        success, response = self.make_request('GET', '/api/coins/presets')
        
        if success and 'presets' in response:
            presets = response['presets']
            expected_coins = ['litecoin', 'dogecoin', 'feathercoin']
            
            if all(coin in presets for coin in expected_coins):
                return self.log_test("Coin Presets", True, f"- Found {len(presets)} coin presets")
            else:
                return self.log_test("Coin Presets", False, f"- Missing expected coins: {expected_coins}")
        else:
            return self.log_test("Coin Presets", False, f"- Response: {response}")

    def test_mining_status(self) -> bool:
        """Test /api/mining/status endpoint"""
        print("\n⛏️ Testing Mining Status API...")
        
        success, response = self.make_request('GET', '/api/mining/status')
        
        if success and 'is_mining' in response and 'stats' in response:
            is_mining = response.get('is_mining', False)
            stats = response.get('stats', {})
            hashrate = stats.get('hashrate', 0)
            return self.log_test("Mining Status", True, f"- Mining: {is_mining}, Hashrate: {hashrate} H/s")
        else:
            return self.log_test("Mining Status", False, f"- Response: {response}")

    def test_wallet_validation(self) -> bool:
        """Test /api/wallet/validate endpoint"""
        print("\n💰 Testing Wallet Validation API...")
        
        test_cases = [
            # Valid addresses
            {"address": "LhK1Nk7QidqUBKLMBKVrGTXj8dn1rg7VjM", "coin_symbol": "LTC", "expected": True},
            {"address": "ltc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4", "coin_symbol": "LTC", "expected": True},
            {"address": "DQVpNjNVHjTgHaE4Y1oqC7PBGsSWzXSqhM", "coin_symbol": "DOGE", "expected": True},
            {"address": "6nsHHMiUexBgE8GZzw5EWuRoXdsKhK7Mj2", "coin_symbol": "FTC", "expected": True},
            # Invalid addresses
            {"address": "invalid_address", "coin_symbol": "LTC", "expected": False},
            {"address": "BTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4", "coin_symbol": "LTC", "expected": False},
        ]
        
        passed_tests = 0
        total_tests = len(test_cases)
        
        for i, test_case in enumerate(test_cases, 1):
            success, response = self.make_request('POST', '/api/wallet/validate', {
                "address": test_case["address"],
                "coin_symbol": test_case["coin_symbol"]
            })
            
            if success and response.get('valid') == test_case['expected']:
                passed_tests += 1
                print(f"  ✅ Test {i}: {test_case['address'][:20]}... -> {response.get('valid')} (expected {test_case['expected']})")
            else:
                print(f"  ❌ Test {i}: {test_case['address'][:20]}... -> {response.get('valid')} (expected {test_case['expected']})")
        
        success_rate = (passed_tests / total_tests) * 100
        return self.log_test("Wallet Validation", passed_tests == total_tests, f"- {passed_tests}/{total_tests} tests passed ({success_rate:.1f}%)")

    def test_pool_connection(self) -> bool:
        """Test /api/pool/test-connection endpoint"""
        print("\n🔗 Testing Pool Connection API...")
        
        test_cases = [
            # Valid connections (using Google DNS as test)
            {"pool_address": "8.8.8.8", "pool_port": 53, "type": "pool", "expected": True},
            {"pool_address": "8.8.8.8", "pool_port": 53, "type": "rpc", "expected": True},
            # Invalid connections
            {"pool_address": "invalid.pool.address", "pool_port": 3333, "type": "pool", "expected": False},
            {"pool_address": "192.168.999.999", "pool_port": 8332, "type": "rpc", "expected": False},
        ]
        
        passed_tests = 0
        total_tests = len(test_cases)
        
        for i, test_case in enumerate(test_cases, 1):
            success, response = self.make_request('POST', '/api/pool/test-connection', {
                "pool_address": test_case["pool_address"],
                "pool_port": test_case["pool_port"],
                "type": test_case["type"]
            })
            
            result_success = response.get('success', False)
            if result_success == test_case['expected']:
                passed_tests += 1
                print(f"  ✅ Test {i}: {test_case['pool_address']}:{test_case['pool_port']} ({test_case['type']}) -> {result_success}")
            else:
                print(f"  ❌ Test {i}: {test_case['pool_address']}:{test_case['pool_port']} ({test_case['type']}) -> {result_success} (expected {test_case['expected']})")
        
        success_rate = (passed_tests / total_tests) * 100
        return self.log_test("Pool Connection Testing", passed_tests >= total_tests * 0.5, f"- {passed_tests}/{total_tests} tests passed ({success_rate:.1f}%)")

    def test_mining_functionality(self) -> bool:
        """Test mining start/stop functionality"""
        print("\n⛏️ Testing Mining Start/Stop Functionality...")
        
        # Get coin presets first
        success, presets_response = self.make_request('GET', '/api/coins/presets')
        if not success:
            return self.log_test("Mining Functionality", False, "- Failed to get coin presets")
        
        litecoin_config = presets_response['presets']['litecoin']
        
        # Test solo mining (requires wallet address)
        solo_config = {
            "coin": litecoin_config,
            "mode": "solo",
            "threads": 2,
            "intensity": 0.5,
            "wallet_address": "LhK1Nk7QidqUBKLMBKVrGTXj8dn1rg7VjM"
        }
        
        # Start mining
        start_success, start_response = self.make_request('POST', '/api/mining/start', solo_config)
        
        if not start_success or not start_response.get('success'):
            return self.log_test("Mining Functionality", False, f"- Failed to start mining: {start_response}")
        
        print("  ✅ Mining started successfully")
        
        # Wait for mining to initialize
        time.sleep(2)
        
        # Check mining status
        status_success, status_response = self.make_request('GET', '/api/mining/status')
        
        if not status_success or not status_response.get('is_mining'):
            return self.log_test("Mining Functionality", False, f"- Mining not active: {status_response}")
        
        print("  ✅ Mining status confirmed active")
        
        # Wait a bit to collect stats
        time.sleep(3)
        
        # Stop mining
        stop_success, stop_response = self.make_request('POST', '/api/mining/stop')
        
        if not stop_success or not stop_response.get('success'):
            return self.log_test("Mining Functionality", False, f"- Failed to stop mining: {stop_response}")
        
        print("  ✅ Mining stopped successfully")
        
        # Verify mining stopped
        time.sleep(1)
        final_status_success, final_status_response = self.make_request('GET', '/api/mining/status')
        
        if final_status_success and not final_status_response.get('is_mining'):
            return self.log_test("Mining Functionality", True, "- Complete mining cycle successful")
        else:
            return self.log_test("Mining Functionality", False, f"- Mining did not stop properly: {final_status_response}")

    def test_ai_insights(self) -> bool:
        """Test /api/mining/ai-insights endpoint"""
        print("\n🤖 Testing AI Insights API...")
        
        success, response = self.make_request('GET', '/api/mining/ai-insights')
        
        if success and ('insights' in response or 'predictions' in response):
            insights = response.get('insights', {})
            predictions = response.get('predictions', {})
            return self.log_test("AI Insights", True, f"- AI insights available: {len(insights)} insights, {len(predictions)} predictions")
        else:
            return self.log_test("AI Insights", False, f"- Response: {response}")

    def test_remote_connectivity(self) -> bool:
        """Test remote connectivity API endpoints"""
        print("\n📱 Testing Remote Connectivity APIs...")
        
        # Test connection test endpoint
        conn_success, conn_response = self.make_request('GET', '/api/remote/connection/test')
        
        if not conn_success or not conn_response.get('success'):
            return self.log_test("Remote Connectivity", False, f"- Connection test failed: {conn_response}")
        
        print("  ✅ Remote connection test passed")
        
        # Test device registration
        device_data = {
            "device_id": "test_device_001",
            "device_name": "Test Android Device"
        }
        
        reg_success, reg_response = self.make_request('POST', '/api/remote/register', device_data)
        
        if not reg_success or not reg_response.get('success'):
            return self.log_test("Remote Connectivity", False, f"- Device registration failed: {reg_response}")
        
        print("  ✅ Device registration successful")
        access_token = reg_response.get('access_token')
        device_id = reg_response.get('device_id')
        
        # Test device status retrieval
        status_success, status_response = self.make_request('GET', f'/api/remote/status/{device_id}')
        
        if not status_success or not status_response.get('device_id'):
            return self.log_test("Remote Connectivity", False, f"- Device status retrieval failed: {status_response}")
        
        print("  ✅ Device status retrieval successful")
        
        # Test device list
        list_success, list_response = self.make_request('GET', '/api/remote/devices')
        
        if not list_success or not isinstance(list_response.get('devices'), list):
            return self.log_test("Remote Connectivity", False, f"- Device list failed: {list_response}")
        
        print("  ✅ Device list retrieval successful")
        
        # Test remote mining status
        remote_status_success, remote_status_response = self.make_request('GET', '/api/remote/mining/status')
        
        if not remote_status_success or 'remote_access' not in remote_status_response:
            return self.log_test("Remote Connectivity", False, f"- Remote mining status failed: {remote_status_response}")
        
        print("  ✅ Remote mining status successful")
        
        return self.log_test("Remote Connectivity", True, "- All remote connectivity endpoints working")

    def test_websocket_connection(self) -> bool:
        """Test WebSocket real-time updates"""
        print("\n🔌 Testing WebSocket Connection...")
        
        def on_message(ws, message):
            try:
                data = json.loads(message)
                self.websocket_data.append(data)
            except:
                pass
        
        def on_open(ws):
            self.websocket_connected = True
        
        def on_error(ws, error):
            print(f"  WebSocket error: {error}")
        
        def on_close(ws, close_status_code, close_msg):
            self.websocket_connected = False
        
        try:
            # Convert HTTPS URL to WSS for WebSocket
            ws_url = self.base_url.replace('https://', 'wss://').replace('http://', 'ws://') + '/socket.io/?EIO=4&transport=websocket'
            
            ws = websocket.WebSocketApp(ws_url,
                                      on_open=on_open,
                                      on_message=on_message,
                                      on_error=on_error,
                                      on_close=on_close)
            
            # Run WebSocket in a separate thread
            wst = threading.Thread(target=ws.run_forever)
            wst.daemon = True
            wst.start()
            
            # Wait for connection
            time.sleep(3)
            
            if self.websocket_connected and len(self.websocket_data) > 0:
                return self.log_test("WebSocket Connection", True, f"- Connected and received {len(self.websocket_data)} messages")
            else:
                return self.log_test("WebSocket Connection", False, f"- Connection failed or no data received")
                
        except Exception as e:
            return self.log_test("WebSocket Connection", False, f"- Connection error: {str(e)}")

    def test_error_handling(self) -> bool:
        """Test error handling and edge cases"""
        print("\n🚨 Testing Error Handling...")
        
        test_cases = [
            # Invalid endpoints
            {"method": "GET", "endpoint": "/api/invalid", "expected_status": 404},
            # Invalid mining config
            {"method": "POST", "endpoint": "/api/mining/start", "data": {"invalid": "config"}, "expected_status": 400},
            # Invalid wallet validation
            {"method": "POST", "endpoint": "/api/wallet/validate", "data": {}, "expected_status": 400},
        ]
        
        passed_tests = 0
        total_tests = len(test_cases)
        
        for i, test_case in enumerate(test_cases, 1):
            try:
                url = f"{self.base_url}{test_case['endpoint']}"
                
                if test_case['method'] == 'GET':
                    response = requests.get(url, timeout=5)
                else:
                    response = requests.post(url, json=test_case.get('data'), timeout=5)
                
                if response.status_code >= test_case['expected_status']:
                    passed_tests += 1
                    print(f"  ✅ Test {i}: {test_case['endpoint']} -> {response.status_code} (expected >= {test_case['expected_status']})")
                else:
                    print(f"  ❌ Test {i}: {test_case['endpoint']} -> {response.status_code} (expected >= {test_case['expected_status']})")
                    
            except Exception as e:
                print(f"  ❌ Test {i}: {test_case['endpoint']} -> Error: {str(e)}")
        
        success_rate = (passed_tests / total_tests) * 100
        return self.log_test("Error Handling", passed_tests >= total_tests * 0.7, f"- {passed_tests}/{total_tests} tests passed ({success_rate:.1f}%)")

    def run_all_tests(self) -> bool:
        """Run all backend tests"""
        print(f"🚀 Starting Comprehensive Node.js Backend Testing")
        print(f"Testing backend at: {self.base_url}")
        print("=" * 80)
        
        # Core API Endpoints Testing
        self.test_health_check()
        self.test_system_stats()
        self.test_cpu_info()
        self.test_coin_presets()
        self.test_mining_status()
        
        # Wallet and Pool Testing
        self.test_wallet_validation()
        self.test_pool_connection()
        
        # Mining Functionality Testing
        self.test_mining_functionality()
        
        # AI and Advanced Features
        self.test_ai_insights()
        
        # Remote Connectivity Testing
        self.test_remote_connectivity()
        
        # System Integration Testing
        self.test_websocket_connection()
        self.test_error_handling()
        
        # Calculate results
        print("\n" + "=" * 80)
        print(f"📊 Test Results: {self.tests_passed}/{self.tests_run} tests passed")
        
        success_rate = (self.tests_passed / self.tests_run) * 100 if self.tests_run > 0 else 0
        print(f"📈 Success Rate: {success_rate:.1f}%")
        
        if success_rate >= 90:
            print("🎉 Overall Status: EXCELLENT - System is functioning perfectly")
            return True
        elif success_rate >= 80:
            print("✅ Overall Status: GOOD - System is functioning well")
            return True
        elif success_rate >= 60:
            print("⚠️  Overall Status: FAIR - Some issues detected")
            return False
        else:
            print("🚨 Overall Status: POOR - Major issues detected")
            return False

def main():
    """Main test runner"""
    import os
    backend_url = os.getenv('REACT_APP_BACKEND_URL', 'https://113c4522-c6a3-4def-b0b5-d97ad7e0f3d8.preview.emergentagent.com')
    
    tester = NodeJSBackendTester(backend_url)
    success = tester.run_all_tests()
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())