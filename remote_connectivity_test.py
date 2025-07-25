#!/usr/bin/env python3
"""
Remote Connectivity API Testing for CryptoMiner Pro
Tests all remote connectivity endpoints for future Android app integration
"""

import requests
import json
import time
import sys
import os
from datetime import datetime
from typing import Dict, Any, Optional

class RemoteConnectivityTester:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.tests_run = 0
        self.tests_passed = 0
        self.device_id = "test-android-123"
        self.device_name = "Test Android Device"
        self.access_token = None
        
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
        except json.JSONDecodeError:
            return False, {"error": "Invalid JSON response"}

    def test_connection_test_endpoint(self) -> bool:
        """Test /api/remote/connection/test endpoint"""
        print("\n🔗 Testing Remote Connection Test Endpoint...")
        
        success, response = self.make_request('GET', '/api/remote/connection/test')
        
        if success:
            # Check required fields in response
            required_fields = ['success', 'message', 'server_time', 'system_health', 'api_version', 'features']
            missing_fields = [field for field in required_fields if field not in response]
            
            if not missing_fields:
                # Check features
                features = response.get('features', {})
                expected_features = ['remote_mining', 'real_time_monitoring', 'multi_device_support', 'secure_authentication']
                missing_features = [feat for feat in expected_features if not features.get(feat)]
                
                if not missing_features:
                    return self.log_test("Connection Test", True, 
                                       f"- API Version: {response.get('api_version')}, Features: {len(features)}")
                else:
                    return self.log_test("Connection Test", False, 
                                       f"- Missing features: {missing_features}")
            else:
                return self.log_test("Connection Test", False, 
                                   f"- Missing fields: {missing_fields}")
        else:
            return self.log_test("Connection Test", False, f"- Request failed: {response}")

    def test_device_registration(self) -> bool:
        """Test /api/remote/register endpoint"""
        print("\n📱 Testing Device Registration...")
        
        registration_data = {
            "device_id": self.device_id,
            "device_name": self.device_name
        }
        
        success, response = self.make_request('POST', '/api/remote/register', registration_data)
        
        if success:
            # Check required fields in response
            required_fields = ['success', 'access_token', 'device_id', 'message']
            missing_fields = [field for field in required_fields if field not in response]
            
            if not missing_fields:
                if response.get('success') and response.get('access_token'):
                    self.access_token = response['access_token']
                    return self.log_test("Device Registration", True, 
                                       f"- Device ID: {response.get('device_id')}, Token received")
                else:
                    return self.log_test("Device Registration", False, 
                                       "- Success=False or no access token")
            else:
                return self.log_test("Device Registration", False, 
                                   f"- Missing fields: {missing_fields}")
        else:
            return self.log_test("Device Registration", False, f"- Request failed: {response}")

    def test_remote_status(self) -> bool:
        """Test /api/remote/status/{device_id} endpoint"""
        print("\n📊 Testing Remote Status Retrieval...")
        
        if not self.device_id:
            return self.log_test("Remote Status", False, "- No device_id available")
        
        success, response = self.make_request('GET', f'/api/remote/status/{self.device_id}')
        
        if success:
            # Check required fields in response
            required_fields = ['device_id', 'device_name', 'is_mining', 'hashrate', 'uptime', 'last_seen', 'system_health']
            missing_fields = [field for field in required_fields if field not in response]
            
            if not missing_fields:
                return self.log_test("Remote Status", True, 
                                   f"- Device: {response.get('device_name')}, Mining: {response.get('is_mining')}")
            else:
                return self.log_test("Remote Status", False, 
                                   f"- Missing fields: {missing_fields}")
        else:
            return self.log_test("Remote Status", False, f"- Request failed: {response}")

    def test_list_remote_devices(self) -> bool:
        """Test /api/remote/devices endpoint"""
        print("\n📋 Testing Remote Devices List...")
        
        success, response = self.make_request('GET', '/api/remote/devices')
        
        if success:
            # Check required fields in response
            required_fields = ['devices', 'total']
            missing_fields = [field for field in required_fields if field not in response]
            
            if not missing_fields:
                devices = response.get('devices', [])
                total = response.get('total', 0)
                
                # Check if our registered device is in the list
                our_device = next((d for d in devices if d.get('device_id') == self.device_id), None)
                
                if our_device:
                    return self.log_test("List Remote Devices", True, 
                                       f"- Total devices: {total}, Our device found")
                else:
                    return self.log_test("List Remote Devices", False, 
                                       f"- Our device not found in list of {total} devices")
            else:
                return self.log_test("List Remote Devices", False, 
                                   f"- Missing fields: {missing_fields}")
        else:
            return self.log_test("List Remote Devices", False, f"- Request failed: {response}")

    def test_remote_mining_status(self) -> bool:
        """Test /api/remote/mining/status endpoint"""
        print("\n⛏️ Testing Remote Mining Status...")
        
        success, response = self.make_request('GET', '/api/remote/mining/status')
        
        if success:
            # Check required fields in response
            required_fields = ['is_mining', 'stats', 'remote_access', 'connected_devices', 'api_version']
            missing_fields = [field for field in required_fields if field not in response]
            
            if not missing_fields:
                if response.get('remote_access') and response.get('api_version'):
                    return self.log_test("Remote Mining Status", True, 
                                       f"- Mining: {response.get('is_mining')}, Connected devices: {response.get('connected_devices')}")
                else:
                    return self.log_test("Remote Mining Status", False, 
                                       "- Missing remote_access flag or api_version")
            else:
                return self.log_test("Remote Mining Status", False, 
                                   f"- Missing fields: {missing_fields}")
        else:
            return self.log_test("Remote Mining Status", False, f"- Request failed: {response}")

    def test_remote_mining_control(self) -> bool:
        """Test remote mining start and stop endpoints"""
        print("\n🎮 Testing Remote Mining Control...")
        
        # First get coin presets for mining configuration
        success, presets_response = self.make_request('GET', '/api/coins/presets')
        if not success:
            return self.log_test("Remote Mining Control", False, "- Failed to get coin presets")
        
        litecoin_config = presets_response['presets']['litecoin']
        
        # Test mining configuration for remote start
        mining_config = {
            "coin": litecoin_config,
            "mode": "solo",
            "threads": 2,
            "intensity": 0.5,
            "auto_optimize": True,
            "ai_enabled": True,
            "wallet_address": "LhK1Nk7QidqUBKLMBKVr8fWsNu4gp7rqLs"  # Valid Litecoin address
        }
        
        # Test remote mining start
        start_success, start_response = self.make_request('POST', f'/api/remote/mining/start?device_id={self.device_id}', mining_config)
        
        if not start_success:
            return self.log_test("Remote Mining Control", False, f"- Start failed: {start_response}")
        
        if not start_response.get('success'):
            return self.log_test("Remote Mining Control", False, f"- Start unsuccessful: {start_response}")
        
        # Check if response includes remote access information
        if not start_response.get('remote_access'):
            self.log_test("Remote Mining Start", False, "- Missing remote_access flag in response")
        else:
            self.log_test("Remote Mining Start", True, f"- Remote device: {start_response.get('remote_device_id')}")
        
        # Wait a moment for mining to initialize
        time.sleep(2)
        
        # Test remote mining stop
        stop_success, stop_response = self.make_request('POST', f'/api/remote/mining/stop?device_id={self.device_id}')
        
        if stop_success and stop_response.get('success'):
            if stop_response.get('remote_access'):
                return self.log_test("Remote Mining Control", True, "- Start and stop both successful with remote access")
            else:
                return self.log_test("Remote Mining Control", False, "- Stop missing remote_access flag")
        else:
            return self.log_test("Remote Mining Control", False, f"- Stop failed: {stop_response}")

    def test_error_handling(self) -> bool:
        """Test error handling for remote endpoints"""
        print("\n🚨 Testing Error Handling...")
        
        error_tests = [
            {
                "name": "Invalid Device ID Status",
                "method": "GET",
                "endpoint": "/api/remote/status/invalid-device-123",
                "should_fail": True
            },
            {
                "name": "Missing Registration Data",
                "method": "POST", 
                "endpoint": "/api/remote/register",
                "data": {},
                "should_fail": True
            },
            {
                "name": "Invalid Mining Config",
                "method": "POST",
                "endpoint": f"/api/remote/mining/start?device_id={self.device_id}",
                "data": {"invalid": "config"},
                "should_fail": True
            }
        ]
        
        passed_tests = 0
        total_tests = len(error_tests)
        
        for i, test in enumerate(error_tests):
            success, response = self.make_request(test["method"], test["endpoint"], test.get("data"))
            
            if test["should_fail"]:
                if not success or not response.get("success", True):
                    passed_tests += 1
                    print(f"  ✅ Test {i+1}: {test['name']} - Correctly handled error")
                else:
                    print(f"  ❌ Test {i+1}: {test['name']} - Should have failed but succeeded")
            else:
                if success and response.get("success"):
                    passed_tests += 1
                    print(f"  ✅ Test {i+1}: {test['name']} - Correctly succeeded")
                else:
                    print(f"  ❌ Test {i+1}: {test['name']} - Should have succeeded but failed")
        
        success_rate = (passed_tests / total_tests) * 100
        return self.log_test("Error Handling", passed_tests == total_tests,
                           f"- {passed_tests}/{total_tests} error tests passed ({success_rate:.1f}%)")

    def run_all_tests(self) -> bool:
        """Run all remote connectivity tests"""
        print("🚀 Starting Remote Connectivity API Tests")
        print("=" * 60)
        
        # Test all remote connectivity endpoints
        self.test_connection_test_endpoint()
        self.test_device_registration()
        self.test_remote_status()
        self.test_list_remote_devices()
        self.test_remote_mining_status()
        self.test_remote_mining_control()
        self.test_error_handling()
        
        # Results
        print("\n" + "=" * 60)
        print(f"📊 Remote Connectivity Test Results: {self.tests_passed}/{self.tests_run} tests passed")
        
        success_rate = (self.tests_passed / self.tests_run) * 100 if self.tests_run > 0 else 0
        print(f"📈 Success Rate: {success_rate:.1f}%")
        
        if success_rate >= 85:
            print("🎉 Overall Status: EXCELLENT - Remote connectivity fully functional")
            return True
        elif success_rate >= 70:
            print("✅ Overall Status: GOOD - Remote connectivity working well")
            return True
        elif success_rate >= 50:
            print("⚠️  Overall Status: FAIR - Some remote connectivity issues")
            return False
        else:
            print("🚨 Overall Status: POOR - Major remote connectivity issues")
            return False

def main():
    """Main test runner"""
    # Get backend URL from environment
    backend_url = os.getenv('REACT_APP_BACKEND_URL', 'http://localhost:8001')
    
    print(f"Testing remote connectivity at: {backend_url}")
    
    tester = RemoteConnectivityTester(backend_url)
    success = tester.run_all_tests()
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())