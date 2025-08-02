#!/bin/bash

echo "🧪 Testing Thread Validation Limits for CryptoMiner Pro"
echo "=" * 50

# Test various thread counts to validate the system accepts up to 256 threads
thread_counts=(1 8 32 64 128 256 300)

for threads in "${thread_counts[@]}"; do
    echo "Testing $threads threads..."
    
    response=$(curl -s -X POST http://localhost:8001/api/mining/start \
        -H "Content-Type: application/json" \
        -d "{\"coin\":\"litecoin\",\"mode\":\"solo\",\"threads\":$threads,\"intensity\":0.8,\"wallet_address\":\"LTC1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4\"}" \
        --connect-timeout 5 --max-time 10)
    
    if echo "$response" | grep -q "success.*true"; then
        echo "✅ $threads threads: ACCEPTED"
    elif echo "$response" | grep -q "Thread count must be between"; then
        echo "❌ $threads threads: REJECTED (validation limit reached)"
    elif echo "$response" | grep -q "error"; then
        error_msg=$(echo "$response" | jq -r '.message // .error // "Unknown error"' 2>/dev/null)
        echo "⚠️  $threads threads: ERROR ($error_msg)"
    else
        echo "🔄 $threads threads: TIMEOUT (may have started successfully)"
    fi
    
    # Stop any mining that may have started
    curl -s -X POST http://localhost:8001/api/mining/stop >/dev/null 2>&1
    
    sleep 1
done

echo ""
echo "✅ Thread validation test completed!"