#!/usr/bin/env python3
"""
Extended Real Mining Test - Let mining run longer to accumulate hashrate
"""

import requests
import time

BACKEND_URL = "https://337dbf55-6395-4d2b-a739-f38dea0fde64.preview.emergentagent.com/api"

def test_extended_mining():
    print("🔍 Extended Real Mining Test")
    print("=" * 40)
    
    # Start mining
    config = {
        "coin": "litecoin",
        "mode": "solo",
        "wallet_address": "LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
        "threads": 2,
        "intensity": 0.8
    }
    
    print("🚀 Starting mining...")
    start_response = requests.post(f"{BACKEND_URL}/mining/start", json=config, timeout=10)
    
    if start_response.status_code == 200:
        print("✅ Mining started successfully")
        
        # Monitor for 30 seconds
        for i in range(6):
            time.sleep(5)
            
            status_response = requests.get(f"{BACKEND_URL}/mining/status", timeout=10)
            if status_response.status_code == 200:
                status = status_response.json()
                stats = status.get('stats', {})
                hashrate = stats.get('hashrate', 0)
                uptime = stats.get('uptime', 0)
                is_mining = status.get('is_mining', False)
                test_mode = status.get('test_mode', None)
                current_job = status.get('current_job')
                
                print(f"⏱️  {(i+1)*5}s: Mining={is_mining}, Hashrate={hashrate:.2f} H/s, Uptime={uptime:.1f}s, TestMode={test_mode}, Job={current_job}")
        
        # Stop mining
        print("\n🛑 Stopping mining...")
        stop_response = requests.post(f"{BACKEND_URL}/mining/stop", timeout=10)
        if stop_response.status_code == 200:
            print("✅ Mining stopped successfully")
        
        # Final status check
        final_status = requests.get(f"{BACKEND_URL}/mining/status", timeout=10)
        if final_status.status_code == 200:
            final_data = final_status.json()
            final_stats = final_data.get('stats', {})
            final_hashrate = final_stats.get('hashrate', 0)
            print(f"📊 Final hashrate: {final_hashrate:.2f} H/s")
            
            if final_hashrate > 0:
                print("✅ REAL MINING CONFIRMED: Hashrate detected!")
                return True
            else:
                print("⚠️  No hashrate detected - may need more time or debugging")
                return False
    else:
        print(f"❌ Failed to start mining: {start_response.status_code}")
        return False

if __name__ == "__main__":
    test_extended_mining()