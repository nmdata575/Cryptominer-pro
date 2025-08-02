#!/usr/bin/env python3
"""
CryptoMiner Pro - Advanced CRUD API Testing
Focus: Testing new DELETE and PUT endpoints for enhanced CRUD operations
"""

import requests
import json
import time
import sys

# Backend URL from frontend environment
BACKEND_URL = "https://b8a64dbe-314e-43b8-9274-f05e86511466.preview.emergentagent.com"
API_BASE = f"{BACKEND_URL}/api"

class AdvancedCRUDTester:
    def __init__(self):
        self.test_results = []
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Origin': BACKEND_URL,
            'User-Agent': 'CryptoMiner-Pro-AdvancedCRUD-Test/1.0'
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

    def test_ai_predictions_delete_endpoint(self):
        """Test DELETE /api/ai/predictions/:id"""
        try:
            # First create a prediction to delete
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
            
            # Create prediction
            create_response = self.session.post(f"{API_BASE}/ai/predictions", json=test_prediction, timeout=10)
            if create_response.status_code != 200:
                self.log_test(
                    "AI Predictions DELETE Endpoint",
                    False,
                    "Failed to create prediction for deletion test",
                    create_response.text
                )
                return False
            
            prediction_id = create_response.json().get('data', {}).get('_id')
            if not prediction_id:
                self.log_test(
                    "AI Predictions DELETE Endpoint",
                    False,
                    "No prediction ID returned from creation",
                    create_response.json()
                )
                return False
            
            # Now delete the prediction
            delete_response = self.session.delete(f"{API_BASE}/ai/predictions/{prediction_id}", timeout=10)
            
            if delete_response.status_code == 200:
                data = delete_response.json()
                if data.get('success'):
                    self.log_test(
                        "AI Predictions DELETE Endpoint",
                        True,
                        f"AI prediction deleted successfully. ID: {prediction_id}",
                        {"deleted_id": prediction_id}
                    )
                    return True
                else:
                    self.log_test(
                        "AI Predictions DELETE Endpoint",
                        False,
                        "Delete response indicates failure",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "AI Predictions DELETE Endpoint",
                    False,
                    f"Delete endpoint returned status {delete_response.status_code}",
                    delete_response.text
                )
                return False
                
        except Exception as e:
            self.log_test(
                "AI Predictions DELETE Endpoint",
                False,
                f"AI prediction delete test failed: {str(e)}"
            )
            return False

    def test_ai_predictions_put_endpoint(self):
        """Test PUT /api/ai/predictions/:id"""
        try:
            # First create a prediction to update
            test_prediction = {
                "predictionType": "difficulty",
                "modelInfo": {
                    "algorithm": "neural_network",
                    "version": "2.0",
                    "trainingDataSize": 200
                },
                "prediction": {
                    "value": 2000.0,
                    "confidence": 0.75,
                    "timeframe": "2hour"
                },
                "inputData": {
                    "currentHashrate": 1800.0,
                    "threads": 6,
                    "intensity": 0.9,
                    "cpuUsage": 85,
                    "memoryUsage": 70,
                    "coin": "dogecoin"
                },
                "expiresAt": "2024-12-31T23:59:59.000Z"
            }
            
            # Create prediction
            create_response = self.session.post(f"{API_BASE}/ai/predictions", json=test_prediction, timeout=10)
            if create_response.status_code != 200:
                self.log_test(
                    "AI Predictions PUT Endpoint",
                    False,
                    "Failed to create prediction for update test",
                    create_response.text
                )
                return False
            
            prediction_id = create_response.json().get('data', {}).get('_id')
            if not prediction_id:
                self.log_test(
                    "AI Predictions PUT Endpoint",
                    False,
                    "No prediction ID returned from creation",
                    create_response.json()
                )
                return False
            
            # Update the prediction
            update_data = {
                "prediction": {
                    "value": 2500.0,
                    "confidence": 0.90,
                    "timeframe": "3hour"
                },
                "modelInfo": {
                    "algorithm": "neural_network",
                    "version": "2.1",
                    "trainingDataSize": 300
                }
            }
            
            put_response = self.session.put(f"{API_BASE}/ai/predictions/{prediction_id}", json=update_data, timeout=10)
            
            if put_response.status_code == 200:
                data = put_response.json()
                if data.get('success'):
                    updated_prediction = data.get('data', {})
                    confidence_percentage = data.get('confidencePercentage', 0)
                    
                    self.log_test(
                        "AI Predictions PUT Endpoint",
                        True,
                        f"AI prediction updated successfully. ID: {prediction_id}, New confidence: {confidence_percentage}%",
                        {"prediction_id": prediction_id, "confidence": confidence_percentage}
                    )
                    return True
                else:
                    self.log_test(
                        "AI Predictions PUT Endpoint",
                        False,
                        "Update response indicates failure",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "AI Predictions PUT Endpoint",
                    False,
                    f"PUT endpoint returned status {put_response.status_code}",
                    put_response.text
                )
                return False
                
        except Exception as e:
            self.log_test(
                "AI Predictions PUT Endpoint",
                False,
                f"AI prediction PUT test failed: {str(e)}"
            )
            return False

    def test_mining_stats_delete_endpoint(self):
        """Test DELETE /api/mining/stats/:sessionId"""
        try:
            # First create a mining stats entry to delete
            test_stats = {
                "sessionId": f"delete_test_session_{int(time.time())}",
                "coin": "feathercoin",
                "mode": "solo",
                "hashrate": 800.0,
                "acceptedShares": 10,
                "rejectedShares": 1,
                "blocksFound": 0,
                "cpuUsage": 65.0,
                "memoryUsage": 40.0,
                "threads": 3,
                "intensity": 0.7,
                "startTime": "2024-01-01T12:00:00.000Z"
            }
            
            # Create mining stats
            create_response = self.session.post(f"{API_BASE}/mining/stats", json=test_stats, timeout=10)
            if create_response.status_code != 200:
                self.log_test(
                    "Mining Stats DELETE Endpoint",
                    False,
                    "Failed to create mining stats for deletion test",
                    create_response.text
                )
                return False
            
            session_id = test_stats["sessionId"]
            
            # Now delete the mining stats
            delete_response = self.session.delete(f"{API_BASE}/mining/stats/{session_id}", timeout=10)
            
            if delete_response.status_code == 200:
                data = delete_response.json()
                if data.get('success'):
                    self.log_test(
                        "Mining Stats DELETE Endpoint",
                        True,
                        f"Mining stats deleted successfully. Session ID: {session_id}",
                        {"deleted_session_id": session_id}
                    )
                    return True
                else:
                    self.log_test(
                        "Mining Stats DELETE Endpoint",
                        False,
                        "Delete response indicates failure",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Mining Stats DELETE Endpoint",
                    False,
                    f"Delete endpoint returned status {delete_response.status_code}",
                    delete_response.text
                )
                return False
                
        except Exception as e:
            self.log_test(
                "Mining Stats DELETE Endpoint",
                False,
                f"Mining stats delete test failed: {str(e)}"
            )
            return False

    def test_mining_stats_put_endpoint(self):
        """Test PUT /api/mining/stats/:sessionId"""
        try:
            # First create a mining stats entry to update
            test_stats = {
                "sessionId": f"update_test_session_{int(time.time())}",
                "coin": "litecoin",
                "mode": "pool",
                "hashrate": 1200.0,
                "acceptedShares": 20,
                "rejectedShares": 2,
                "blocksFound": 1,
                "cpuUsage": 75.0,
                "memoryUsage": 50.0,
                "threads": 5,
                "intensity": 0.8,
                "startTime": "2024-01-01T14:00:00.000Z"
            }
            
            # Create mining stats
            create_response = self.session.post(f"{API_BASE}/mining/stats", json=test_stats, timeout=10)
            if create_response.status_code != 200:
                self.log_test(
                    "Mining Stats PUT Endpoint",
                    False,
                    "Failed to create mining stats for update test",
                    create_response.text
                )
                return False
            
            session_id = test_stats["sessionId"]
            
            # Update the mining stats
            update_data = {
                "hashrate": 1500.0,
                "acceptedShares": 35,
                "rejectedShares": 3,
                "blocksFound": 2,
                "cpuUsage": 80.0,
                "memoryUsage": 55.0
            }
            
            put_response = self.session.put(f"{API_BASE}/mining/stats/{session_id}", json=update_data, timeout=10)
            
            if put_response.status_code == 200:
                data = put_response.json()
                if data.get('success'):
                    updated_stats = data.get('data', {})
                    efficiency = data.get('efficiency', 0)
                    
                    self.log_test(
                        "Mining Stats PUT Endpoint",
                        True,
                        f"Mining stats updated successfully. Session ID: {session_id}, New hashrate: {updated_stats.get('hashrate')} H/s, Efficiency: {efficiency}%",
                        {"session_id": session_id, "hashrate": updated_stats.get('hashrate'), "efficiency": efficiency}
                    )
                    return True
                else:
                    self.log_test(
                        "Mining Stats PUT Endpoint",
                        False,
                        "Update response indicates failure",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Mining Stats PUT Endpoint",
                    False,
                    f"PUT endpoint returned status {put_response.status_code}",
                    put_response.text
                )
                return False
                
        except Exception as e:
            self.log_test(
                "Mining Stats PUT Endpoint",
                False,
                f"Mining stats PUT test failed: {str(e)}"
            )
            return False

    def test_bulk_delete_mining_stats(self):
        """Test POST /api/mining/stats/bulk-delete"""
        try:
            # First create multiple mining stats entries to bulk delete
            session_ids = []
            for i in range(3):
                test_stats = {
                    "sessionId": f"bulk_delete_test_{int(time.time())}_{i}",
                    "coin": "dogecoin",
                    "mode": "pool",
                    "hashrate": 900.0 + (i * 100),
                    "acceptedShares": 15 + i,
                    "rejectedShares": 1,
                    "blocksFound": 0,
                    "cpuUsage": 70.0,
                    "memoryUsage": 45.0,
                    "threads": 4,
                    "intensity": 0.75,
                    "startTime": "2024-01-01T16:00:00.000Z"
                }
                
                create_response = self.session.post(f"{API_BASE}/mining/stats", json=test_stats, timeout=10)
                if create_response.status_code == 200:
                    session_ids.append(test_stats["sessionId"])
                    time.sleep(0.1)  # Small delay to ensure different timestamps
            
            if len(session_ids) == 0:
                self.log_test(
                    "Bulk Delete Mining Stats",
                    False,
                    "Failed to create any mining stats for bulk delete test"
                )
                return False
            
            # Now bulk delete the mining stats
            bulk_delete_data = {
                "sessionIds": session_ids
            }
            
            bulk_response = self.session.post(f"{API_BASE}/mining/stats/bulk-delete", json=bulk_delete_data, timeout=10)
            
            if bulk_response.status_code == 200:
                data = bulk_response.json()
                if data.get('success'):
                    deleted_count = data.get('deletedCount', 0)
                    
                    self.log_test(
                        "Bulk Delete Mining Stats",
                        True,
                        f"Bulk delete successful. Deleted {deleted_count} mining stats records",
                        {"deleted_count": deleted_count, "session_ids": session_ids}
                    )
                    return True
                else:
                    self.log_test(
                        "Bulk Delete Mining Stats",
                        False,
                        "Bulk delete response indicates failure",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Bulk Delete Mining Stats",
                    False,
                    f"Bulk delete endpoint returned status {bulk_response.status_code}",
                    bulk_response.text
                )
                return False
                
        except Exception as e:
            self.log_test(
                "Bulk Delete Mining Stats",
                False,
                f"Bulk delete test failed: {str(e)}"
            )
            return False

    def test_mining_analytics_endpoint(self):
        """Test GET /api/mining/analytics"""
        try:
            # Test analytics endpoint
            response = self.session.get(f"{API_BASE}/mining/analytics?days=7&coin=litecoin", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'analytics' in data:
                    analytics = data.get('analytics', {})
                    period = data.get('period', 'Unknown')
                    
                    total_sessions = analytics.get('totalSessions', 0)
                    avg_hashrate = analytics.get('avgHashrate', 0)
                    overall_efficiency = analytics.get('overallEfficiency', 0)
                    
                    self.log_test(
                        "Mining Analytics Endpoint",
                        True,
                        f"Analytics retrieved successfully. Period: {period}, Sessions: {total_sessions}, Avg Hashrate: {avg_hashrate:.2f} H/s, Efficiency: {overall_efficiency:.2f}%",
                        {"period": period, "total_sessions": total_sessions, "avg_hashrate": avg_hashrate}
                    )
                    return True
                else:
                    self.log_test(
                        "Mining Analytics Endpoint",
                        False,
                        "Invalid response format for analytics",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "Mining Analytics Endpoint",
                    False,
                    f"Analytics endpoint returned status {response.status_code}",
                    response.text
                )
                return False
                
        except Exception as e:
            self.log_test(
                "Mining Analytics Endpoint",
                False,
                f"Analytics test failed: {str(e)}"
            )
            return False

    def test_system_config_delete_endpoint(self):
        """Test DELETE /api/config/:type"""
        try:
            # First create a config to delete
            test_config = {
                "config": {
                    "testSetting": "delete_test_value",
                    "enabled": True,
                    "priority": "high"
                }
            }
            
            # Create config
            create_response = self.session.post(f"{API_BASE}/config/test_config", json=test_config, timeout=10)
            if create_response.status_code != 200:
                self.log_test(
                    "System Config DELETE Endpoint",
                    False,
                    "Failed to create config for deletion test",
                    create_response.text
                )
                return False
            
            # Now delete the config
            delete_response = self.session.delete(f"{API_BASE}/config/test_config", timeout=10)
            
            if delete_response.status_code == 200:
                data = delete_response.json()
                if data.get('success'):
                    self.log_test(
                        "System Config DELETE Endpoint",
                        True,
                        f"System config deleted successfully. Type: test_config",
                        {"deleted_type": "test_config"}
                    )
                    return True
                else:
                    self.log_test(
                        "System Config DELETE Endpoint",
                        False,
                        "Delete response indicates failure",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "System Config DELETE Endpoint",
                    False,
                    f"Delete endpoint returned status {delete_response.status_code}",
                    delete_response.text
                )
                return False
                
        except Exception as e:
            self.log_test(
                "System Config DELETE Endpoint",
                False,
                f"System config delete test failed: {str(e)}"
            )
            return False

    def test_system_config_put_endpoint(self):
        """Test PUT /api/config/:type"""
        try:
            # First create a config to update
            test_config = {
                "config": {
                    "testSetting": "original_value",
                    "enabled": False,
                    "priority": "low"
                }
            }
            
            # Create config
            create_response = self.session.post(f"{API_BASE}/config/update_test_config", json=test_config, timeout=10)
            if create_response.status_code != 200:
                self.log_test(
                    "System Config PUT Endpoint",
                    False,
                    "Failed to create config for update test",
                    create_response.text
                )
                return False
            
            # Update the config
            update_data = {
                "config": {
                    "testSetting": "updated_value",
                    "enabled": True,
                    "priority": "high",
                    "newField": "added_field"
                }
            }
            
            put_response = self.session.put(f"{API_BASE}/config/update_test_config", json=update_data, timeout=10)
            
            if put_response.status_code == 200:
                data = put_response.json()
                if data.get('success'):
                    updated_config = data.get('data', {})
                    
                    self.log_test(
                        "System Config PUT Endpoint",
                        True,
                        f"System config updated successfully. Type: update_test_config",
                        {"config_type": updated_config.get('configType')}
                    )
                    return True
                else:
                    self.log_test(
                        "System Config PUT Endpoint",
                        False,
                        "Update response indicates failure",
                        data
                    )
                    return False
            else:
                self.log_test(
                    "System Config PUT Endpoint",
                    False,
                    f"PUT endpoint returned status {put_response.status_code}",
                    put_response.text
                )
                return False
                
        except Exception as e:
            self.log_test(
                "System Config PUT Endpoint",
                False,
                f"System config PUT test failed: {str(e)}"
            )
            return False

def run_advanced_crud_tests():
    """Run all advanced CRUD tests"""
    print("🎯 CryptoMiner Pro - Advanced CRUD API Testing")
    print("Focus: Testing new DELETE and PUT endpoints for enhanced CRUD operations")
    print("=" * 80)
    
    tester = AdvancedCRUDTester()
    
    # Test all advanced CRUD endpoints
    tests = [
        ("AI Predictions DELETE", tester.test_ai_predictions_delete_endpoint),
        ("AI Predictions PUT", tester.test_ai_predictions_put_endpoint),
        ("Mining Stats DELETE", tester.test_mining_stats_delete_endpoint),
        ("Mining Stats PUT", tester.test_mining_stats_put_endpoint),
        ("Bulk Delete Mining Stats", tester.test_bulk_delete_mining_stats),
        ("Mining Analytics", tester.test_mining_analytics_endpoint),
        ("System Config DELETE", tester.test_system_config_delete_endpoint),
        ("System Config PUT", tester.test_system_config_put_endpoint)
    ]
    
    passed_tests = 0
    total_tests = len(tests)
    
    print(f"\n🔍 Testing {total_tests} Advanced CRUD Endpoints")
    print("-" * 60)
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            if result:
                passed_tests += 1
        except Exception as e:
            print(f"❌ FAILED - {test_name}: {str(e)}")
    
    # Overall results
    success_rate = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
    
    print("\n" + "=" * 80)
    print("🎉 ADVANCED CRUD API TESTING COMPLETED!")
    print(f"📊 Results: {passed_tests}/{total_tests} tests passed ({success_rate:.1f}%)")
    
    # Print summary of results
    print("\n📋 Test Results Summary:")
    for result in tester.test_results:
        print(f"   {result['status']} - {result['test']}")
    
    return success_rate

def main():
    """Main function to run advanced CRUD tests"""
    try:
        success_rate = run_advanced_crud_tests()
        
        # Exit with appropriate code
        if success_rate >= 70:
            sys.exit(0)  # Success
        else:
            sys.exit(1)  # Failure
            
    except KeyboardInterrupt:
        print("\n🛑 Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Test suite crashed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()