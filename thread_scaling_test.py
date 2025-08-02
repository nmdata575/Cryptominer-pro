#!/usr/bin/env python3
"""
CryptoMiner Pro - Thread Scaling Testing
Focus: Testing mining with different thread counts for performance validation
"""

import requests
import json
import time
import sys

# Backend URL from frontend environment
BACKEND_URL = "https://b8a64dbe-314e-43b8-9274-f05e86511466.preview.emergentagent.com"
API_BASE = f"{BACKEND_URL}/api"

class ThreadScalingTester:
    def __init__(self):
        self.test_results = []
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Origin': BACKEND_URL,
            'User-Agent': 'CryptoMiner-Pro-ThreadScaling-Test/1.0'
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
        print()

    def test_cpu_info_endpoint(self):
        """Test Enhanced CPU Detection System"""
        try:
            response = self.session.get(f"{API_BASE}/system/cpu-info", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                
                cores = data.get('cores', 0)
                max_safe_threads = data.get('maxSafeThreads', 0)
                mining_profiles = data.get('miningProfiles', {})
                
                if cores > 0 and max_safe_threads > 0:
                    self.log_test(
                        "Enhanced CPU Detection System",
                        True,
                        f"CPU detection working. Cores: {cores}, Max safe threads: {max_safe_threads}, Profiles: {len(mining_profiles)}",
                        {"cores": cores, "max_safe_threads": max_safe_threads, "profiles": list(mining_profiles.keys())}
                    )
                    return cores, max_safe_threads, mining_profiles
                else:
                    self.log_test(
                        "Enhanced CPU Detection System",
                        False,
                        "Invalid CPU detection data",
                        data
                    )
                    return None, None, None
            else:
                self.log_test(
                    "Enhanced CPU Detection System",
                    False,
                    f"CPU info endpoint returned status {response.status_code}",
                    response.text
                )
                return None, None, None
                
        except Exception as e:
            self.log_test(
                "Enhanced CPU Detection System",
                False,
                f"CPU info test failed: {str(e)}"
            )
            return None, None, None

    def test_mining_with_thread_count(self, threads, test_name):
        """Test mining with specific thread count"""
        try:
            # Configure mining with specific thread count
            mining_config = {
                "coin": "litecoin",
                "mode": "solo",
                "threads": threads,
                "intensity": 0.5,
                "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
            }
            
            print(f"🎯 Testing mining with {threads} threads...")
            
            # Start mining
            start_response = self.session.post(f"{API_BASE}/mining/start", json=mining_config, timeout=15)
            
            if start_response.status_code == 200:
                start_data = start_response.json()
                if start_data.get('success'):
                    # Wait for mining to initialize
                    time.sleep(3)
                    
                    # Check mining status
                    status_response = self.session.get(f"{API_BASE}/mining/status", timeout=10)
                    if status_response.status_code == 200:
                        status_data = status_response.json()
                        
                        is_mining = status_data.get('is_mining', False)
                        hashrate = status_data.get('stats', {}).get('hashrate', 0)
                        
                        # Stop mining
                        stop_response = self.session.post(f"{API_BASE}/mining/stop", timeout=10)
                        
                        if is_mining:
                            self.log_test(
                                test_name,
                                True,
                                f"Mining successful with {threads} threads. Hashrate: {hashrate:.2f} H/s",
                                {"threads": threads, "hashrate": hashrate, "is_mining": is_mining}
                            )
                            return hashrate
                        else:
                            self.log_test(
                                test_name,
                                False,
                                f"Mining not active with {threads} threads",
                                {"threads": threads, "is_mining": is_mining}
                            )
                            return 0
                    else:
                        self.log_test(
                            test_name,
                            False,
                            f"Failed to get mining status for {threads} threads",
                            status_response.text
                        )
                        return 0
                else:
                    self.log_test(
                        test_name,
                        False,
                        f"Mining start failed for {threads} threads: {start_data.get('message', 'Unknown error')}",
                        start_data
                    )
                    return 0
            else:
                self.log_test(
                    test_name,
                    False,
                    f"Mining start request failed for {threads} threads with status {start_response.status_code}",
                    start_response.text
                )
                return 0
                
        except Exception as e:
            self.log_test(
                test_name,
                False,
                f"Thread scaling test failed for {threads} threads: {str(e)}"
            )
            return 0

    def test_mining_profiles(self, mining_profiles):
        """Test different mining profiles"""
        try:
            profile_results = {}
            
            for profile_name, profile_config in mining_profiles.items():
                threads = profile_config.get('threads', 1)
                intensity = profile_config.get('intensity', 0.5)
                
                mining_config = {
                    "coin": "litecoin",
                    "mode": "solo",
                    "threads": threads,
                    "intensity": intensity,
                    "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
                }
                
                print(f"🎯 Testing {profile_name} profile (threads: {threads}, intensity: {intensity})...")
                
                # Start mining with profile
                start_response = self.session.post(f"{API_BASE}/mining/start", json=mining_config, timeout=15)
                
                if start_response.status_code == 200:
                    start_data = start_response.json()
                    if start_data.get('success'):
                        # Wait for mining to initialize
                        time.sleep(2)
                        
                        # Check mining status
                        status_response = self.session.get(f"{API_BASE}/mining/status", timeout=10)
                        if status_response.status_code == 200:
                            status_data = status_response.json()
                            
                            is_mining = status_data.get('is_mining', False)
                            hashrate = status_data.get('stats', {}).get('hashrate', 0)
                            
                            # Stop mining
                            stop_response = self.session.post(f"{API_BASE}/mining/stop", timeout=10)
                            
                            profile_results[profile_name] = {
                                'threads': threads,
                                'intensity': intensity,
                                'hashrate': hashrate,
                                'success': is_mining
                            }
                            
                            time.sleep(1)  # Brief pause between profiles
                        else:
                            profile_results[profile_name] = {
                                'threads': threads,
                                'intensity': intensity,
                                'hashrate': 0,
                                'success': False
                            }
                    else:
                        profile_results[profile_name] = {
                            'threads': threads,
                            'intensity': intensity,
                            'hashrate': 0,
                            'success': False
                        }
                else:
                    profile_results[profile_name] = {
                        'threads': threads,
                        'intensity': intensity,
                        'hashrate': 0,
                        'success': False
                    }
            
            # Analyze results
            successful_profiles = [name for name, result in profile_results.items() if result['success']]
            total_profiles = len(profile_results)
            
            if len(successful_profiles) > 0:
                self.log_test(
                    "Mining Profiles Testing",
                    True,
                    f"Mining profiles tested successfully. {len(successful_profiles)}/{total_profiles} profiles working: {', '.join(successful_profiles)}",
                    profile_results
                )
                return True
            else:
                self.log_test(
                    "Mining Profiles Testing",
                    False,
                    f"No mining profiles working. {len(successful_profiles)}/{total_profiles} profiles successful",
                    profile_results
                )
                return False
                
        except Exception as e:
            self.log_test(
                "Mining Profiles Testing",
                False,
                f"Mining profiles test failed: {str(e)}"
            )
            return False

def run_thread_scaling_tests():
    """Run thread scaling tests"""
    print("🎯 CryptoMiner Pro - Thread Scaling Testing")
    print("Focus: Testing mining with different thread counts for performance validation")
    print("=" * 80)
    
    tester = ThreadScalingTester()
    
    # Test CPU detection first
    cores, max_safe_threads, mining_profiles = tester.test_cpu_info_endpoint()
    
    if cores and max_safe_threads and mining_profiles:
        print(f"\n🔍 System detected: {cores} cores, {max_safe_threads} max safe threads")
        print(f"Available mining profiles: {list(mining_profiles.keys())}")
        
        # Test mining profiles
        tester.test_mining_profiles(mining_profiles)
        
        # Test specific thread counts
        test_thread_counts = [1, 2, 4]
        if max_safe_threads > 4:
            test_thread_counts.append(max_safe_threads)
        
        print(f"\n🔍 Testing specific thread counts: {test_thread_counts}")
        print("-" * 60)
        
        hashrate_results = {}
        for thread_count in test_thread_counts:
            hashrate = tester.test_mining_with_thread_count(
                thread_count, 
                f"Mining with {thread_count} threads"
            )
            hashrate_results[thread_count] = hashrate
            time.sleep(1)  # Brief pause between tests
        
        # Analyze performance scaling
        working_tests = [threads for threads, hashrate in hashrate_results.items() if hashrate > 0]
        
        if len(working_tests) > 0:
            print(f"\n📊 Thread Scaling Results:")
            for threads, hashrate in hashrate_results.items():
                if hashrate > 0:
                    print(f"   {threads} threads: {hashrate:.2f} H/s")
                else:
                    print(f"   {threads} threads: Failed")
    
    # Overall results
    passed_tests = sum(1 for result in tester.test_results if result['success'])
    total_tests = len(tester.test_results)
    success_rate = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
    
    print("\n" + "=" * 80)
    print("🎉 THREAD SCALING TESTING COMPLETED!")
    print(f"📊 Results: {passed_tests}/{total_tests} tests passed ({success_rate:.1f}%)")
    
    # Print summary of results
    print("\n📋 Test Results Summary:")
    for result in tester.test_results:
        print(f"   {result['status']} - {result['test']}")
    
    return success_rate

def main():
    """Main function to run thread scaling tests"""
    try:
        success_rate = run_thread_scaling_tests()
        
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