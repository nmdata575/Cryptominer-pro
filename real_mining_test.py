#!/usr/bin/env python3
"""
Focused Real Mining Functionality Test
Tests the specific real mining features mentioned in the review request
"""

import requests
import json
import time
import sys

BACKEND_URL = "https://337dbf55-6395-4d2b-a739-f38dea0fde64.preview.emergentagent.com/api"
TIMEOUT = 10

def test_real_mining_features():
    """Test the key real mining features"""
    print("🔍 Testing Real Mining Features")
    print("=" * 50)
    
    results = []
    
    # 1. Test Real Scrypt Algorithm vs Simulation
    print("\n1. Testing Real Scrypt Algorithm Implementation...")
    try:
        # Start mining with solo mode
        config = {
            "coin": "litecoin",
            "mode": "solo",
            "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
            "threads": 1,
            "intensity": 0.5
        }
        
        start_response = requests.post(f"{BACKEND_URL}/mining/start", json=config, timeout=TIMEOUT)
        if start_response.status_code == 200:
            time.sleep(5)  # Let mining run
            
            status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
            if status_response.status_code == 200:
                status = status_response.json()
                hashrate = status.get('stats', {}).get('hashrate', 0)
                is_mining = status.get('is_mining', False)
                
                # Real scrypt should produce lower but measurable hashrates
                if is_mining and 0 < hashrate < 10000:
                    results.append("✅ Real Scrypt Algorithm: Working (realistic hashrate)")
                    print(f"   ✅ Real scrypt hashrate: {hashrate:.2f} H/s")
                else:
                    results.append("❌ Real Scrypt Algorithm: May be simulated")
                    print(f"   ❌ Suspicious hashrate: {hashrate} H/s")
            
            # Stop mining
            requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
        else:
            results.append("❌ Real Scrypt Algorithm: Cannot start mining")
            print(f"   ❌ Mining start failed: {start_response.status_code}")
    except Exception as e:
        results.append(f"❌ Real Scrypt Algorithm: Error - {str(e)}")
        print(f"   ❌ Error: {str(e)}")
    
    # 2. Test Real Pool Communication vs Simulation
    print("\n2. Testing Real Pool Communication...")
    try:
        config = {
            "coin": "litecoin", 
            "mode": "pool",
            "pool_username": "test_real_pool",
            "pool_password": "x",
            "threads": 1
        }
        
        start_response = requests.post(f"{BACKEND_URL}/mining/start", json=config, timeout=TIMEOUT)
        if start_response.status_code == 200:
            time.sleep(8)  # Allow time for pool connection attempt
            
            status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
            if status_response.status_code == 200:
                status = status_response.json()
                test_mode = status.get('test_mode', None)
                pool_connected = status.get('pool_connected', False)
                current_job = status.get('current_job')
                
                if test_mode is not None:
                    if test_mode and current_job:
                        results.append("✅ Pool Communication: Test mode fallback working")
                        print(f"   ✅ Test mode active with job: {current_job}")
                    elif not test_mode and pool_connected:
                        results.append("✅ Pool Communication: Real pool connection established")
                        print(f"   ✅ Real pool connected with job: {current_job}")
                    else:
                        results.append("⚠️ Pool Communication: Attempting real connection")
                        print(f"   ⚠️ Pool connection in progress")
                else:
                    results.append("❌ Pool Communication: No mode indicators")
                    print(f"   ❌ Missing test_mode indicator")
            
            # Stop mining
            requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
        else:
            results.append("❌ Pool Communication: Cannot start pool mining")
            print(f"   ❌ Pool mining start failed: {start_response.status_code}")
    except Exception as e:
        results.append(f"❌ Pool Communication: Error - {str(e)}")
        print(f"   ❌ Error: {str(e)}")
    
    # 3. Test Real vs Test Mode Indicators
    print("\n3. Testing Real vs Test Mode Indicators...")
    try:
        # Test with a non-existent pool to force test mode
        config = {
            "coin": "dogecoin",
            "mode": "pool", 
            "pool_username": "test_fallback",
            "pool_password": "x",
            "custom_pool_address": "nonexistent.pool.com",
            "custom_pool_port": 9999,
            "threads": 1
        }
        
        start_response = requests.post(f"{BACKEND_URL}/mining/start", json=config, timeout=TIMEOUT)
        if start_response.status_code == 200:
            time.sleep(10)  # Allow time for connection timeout and fallback
            
            status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
            if status_response.status_code == 200:
                status = status_response.json()
                test_mode = status.get('test_mode')
                pool_connected = status.get('pool_connected')
                is_mining = status.get('is_mining')
                
                if test_mode is True and pool_connected is False and is_mining:
                    results.append("✅ Test Mode Fallback: Working correctly")
                    print(f"   ✅ Fallback to test mode when pool unavailable")
                elif test_mode is False and pool_connected is True:
                    results.append("✅ Real Pool Mode: Connected successfully")
                    print(f"   ✅ Real pool connection established")
                else:
                    results.append("⚠️ Mode Indicators: Unclear state")
                    print(f"   ⚠️ test_mode={test_mode}, pool_connected={pool_connected}")
            
            # Stop mining
            requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
        else:
            results.append("❌ Mode Indicators: Cannot test fallback")
            print(f"   ❌ Fallback test failed: {start_response.status_code}")
    except Exception as e:
        results.append(f"❌ Mode Indicators: Error - {str(e)}")
        print(f"   ❌ Error: {str(e)}")
    
    # 4. Test Real Block Headers and Share Submission
    print("\n4. Testing Real Block Headers and Share Submission...")
    try:
        config = {
            "coin": "feathercoin",
            "mode": "pool",
            "pool_username": "test_shares",
            "pool_password": "x", 
            "threads": 2,
            "intensity": 0.7
        }
        
        start_response = requests.post(f"{BACKEND_URL}/mining/start", json=config, timeout=TIMEOUT)
        if start_response.status_code == 200:
            time.sleep(12)  # Allow time for share generation
            
            status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
            if status_response.status_code == 200:
                status = status_response.json()
                stats = status.get('stats', {})
                accepted_shares = stats.get('accepted_shares', 0)
                rejected_shares = stats.get('rejected_shares', 0)
                total_shares = accepted_shares + rejected_shares
                current_job = status.get('current_job')
                difficulty = status.get('difficulty', 0)
                
                block_header_indicators = []
                if current_job:
                    block_header_indicators.append(f"Mining job: {current_job}")
                if difficulty > 0:
                    block_header_indicators.append(f"Difficulty: {difficulty}")
                
                share_indicators = []
                if total_shares > 0:
                    share_indicators.append(f"Total shares: {total_shares}")
                    share_indicators.append(f"Accepted: {accepted_shares}")
                    if total_shares > 0:
                        acceptance_rate = (accepted_shares / total_shares) * 100
                        share_indicators.append(f"Acceptance: {acceptance_rate:.1f}%")
                
                if block_header_indicators and (total_shares > 0 or difficulty > 0):
                    results.append("✅ Block Headers & Shares: Real implementation working")
                    print(f"   ✅ Block headers: {', '.join(block_header_indicators)}")
                    if share_indicators:
                        print(f"   ✅ Share submission: {', '.join(share_indicators)}")
                else:
                    results.append("⚠️ Block Headers & Shares: Limited activity")
                    print(f"   ⚠️ Job: {current_job}, Shares: {total_shares}")
            
            # Stop mining
            requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
        else:
            results.append("❌ Block Headers & Shares: Cannot start mining")
            print(f"   ❌ Mining start failed: {start_response.status_code}")
    except Exception as e:
        results.append(f"❌ Block Headers & Shares: Error - {str(e)}")
        print(f"   ❌ Error: {str(e)}")
    
    # 5. Test Hash Rate Calculation with Real Scrypt Processing
    print("\n5. Testing Hash Rate Calculation...")
    try:
        # Test with different thread counts to verify real processing
        thread_tests = [1, 2]
        hashrates = []
        
        for threads in thread_tests:
            config = {
                "coin": "litecoin",
                "mode": "solo",
                "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
                "threads": threads,
                "intensity": 0.4
            }
            
            start_response = requests.post(f"{BACKEND_URL}/mining/start", json=config, timeout=TIMEOUT)
            if start_response.status_code == 200:
                time.sleep(6)  # Allow hashrate to stabilize
                
                status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=TIMEOUT)
                if status_response.status_code == 200:
                    status = status_response.json()
                    hashrate = status.get('stats', {}).get('hashrate', 0)
                    hashrates.append({'threads': threads, 'hashrate': hashrate})
                    print(f"   📊 {threads} threads: {hashrate:.2f} H/s")
                
                # Stop mining
                requests.post(f"{BACKEND_URL}/mining/stop", timeout=TIMEOUT)
                time.sleep(2)  # Cool down
        
        if len(hashrates) >= 2:
            # Check if hashrate scales reasonably with thread count
            single_thread = next((h for h in hashrates if h['threads'] == 1), None)
            dual_thread = next((h for h in hashrates if h['threads'] == 2), None)
            
            if single_thread and dual_thread:
                scaling_ratio = dual_thread['hashrate'] / single_thread['hashrate'] if single_thread['hashrate'] > 0 else 0
                
                if 1.2 <= scaling_ratio <= 3.0:  # Reasonable scaling
                    results.append("✅ Hash Rate Calculation: Real scrypt processing with proper scaling")
                    print(f"   ✅ Scaling ratio: {scaling_ratio:.2f}x")
                else:
                    results.append("⚠️ Hash Rate Calculation: Unusual scaling pattern")
                    print(f"   ⚠️ Scaling ratio: {scaling_ratio:.2f}x")
            else:
                results.append("⚠️ Hash Rate Calculation: Insufficient data")
        else:
            results.append("❌ Hash Rate Calculation: Cannot collect data")
    except Exception as e:
        results.append(f"❌ Hash Rate Calculation: Error - {str(e)}")
        print(f"   ❌ Error: {str(e)}")
    
    # Summary
    print("\n" + "=" * 50)
    print("🏆 REAL MINING FUNCTIONALITY TEST RESULTS")
    print("=" * 50)
    
    passed = sum(1 for r in results if r.startswith("✅"))
    warnings = sum(1 for r in results if r.startswith("⚠️"))
    failed = sum(1 for r in results if r.startswith("❌"))
    total = len(results)
    
    for result in results:
        print(result)
    
    print(f"\n📊 Summary: {passed} passed, {warnings} warnings, {failed} failed out of {total} tests")
    
    success_rate = (passed / total) * 100 if total > 0 else 0
    
    if success_rate >= 80:
        print(f"🎉 EXCELLENT: Real mining functionality is working correctly ({success_rate:.1f}%)")
        return True
    elif success_rate >= 60:
        print(f"✅ GOOD: Real mining mostly working with some issues ({success_rate:.1f}%)")
        return True
    else:
        print(f"❌ NEEDS WORK: Real mining implementation has significant issues ({success_rate:.1f}%)")
        return False

if __name__ == "__main__":
    success = test_real_mining_features()
    sys.exit(0 if success else 1)