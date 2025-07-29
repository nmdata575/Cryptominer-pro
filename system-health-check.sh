#!/bin/bash

# Complete System Health Check for CryptoMiner Pro
# Tests MongoDB, Backend API, and Mining System readiness

echo "🔍 CryptoMiner Pro - Complete System Health Check"
echo "================================================="
echo ""

# Test 1: MongoDB Health
echo "1️⃣ MongoDB Health Check"
echo "----------------------"

if pgrep mongod >/dev/null; then
    echo "✅ MongoDB process: Running (PID: $(pgrep mongod))"
    
    # Check port with multiple methods
    if command -v lsof >/dev/null && sudo lsof -i :27017 >/dev/null 2>&1; then
        echo "✅ MongoDB port: Listening on 27017 (verified with lsof)"
    elif sudo netstat -tlnp 2>/dev/null | grep -q ":27017.*mongod"; then
        echo "✅ MongoDB port: Listening on 27017 (verified with netstat)"
    else
        echo "⚠️ MongoDB port: Cannot verify port 27017 is listening"
    fi
    
    # Test connection
    if mongosh --host 127.0.0.1 --port 27017 --eval "print('Connection test passed')" --quiet >/dev/null 2>&1; then
        echo "✅ MongoDB connection: Successful"
    else
        echo "❌ MongoDB connection: Failed"
    fi
else
    echo "❌ MongoDB process: Not running"
fi

echo ""

# Test 2: Backend API Health
echo "2️⃣ Backend API Health Check"
echo "---------------------------"

if curl -s http://localhost:8001/api/health >/dev/null 2>&1; then
    API_STATUS=$(curl -s http://localhost:8001/api/health | jq -r '.status' 2>/dev/null || echo "unknown")
    if [[ "$API_STATUS" == "healthy" ]]; then
        echo "✅ Backend API: Healthy and responding"
        
        # Test coin presets
        COIN_COUNT=$(curl -s http://localhost:8001/api/coins/presets | jq length 2>/dev/null || echo "0")
        if [[ "$COIN_COUNT" -ge 3 ]]; then
            echo "✅ Coin presets: $COIN_COUNT coins available"
        else
            echo "⚠️ Coin presets: Only $COIN_COUNT coins available"
        fi
        
        # Test CPU detection
        CPU_CORES=$(curl -s http://localhost:8001/api/system/cpu-info | jq -r '.cores.physical' 2>/dev/null || echo "unknown")
        if [[ "$CPU_CORES" != "unknown" ]] && [[ "$CPU_CORES" -gt 0 ]]; then
            echo "✅ CPU detection: $CPU_CORES cores detected"
            
            # Check for override
            CPU_OVERRIDE=$(curl -s http://localhost:8001/api/system/cpu-info | jq -r '.cores.override_active' 2>/dev/null || echo "false")
            if [[ "$CPU_OVERRIDE" == "true" ]]; then
                echo "✅ CPU override: Active (enhanced core detection)"
            fi
        else
            echo "❌ CPU detection: Failed"
        fi
        
    else
        echo "❌ Backend API: Unhealthy (status: $API_STATUS)"
    fi
else
    echo "❌ Backend API: Not responding on localhost:8001"
fi

echo ""

# Test 3: Frontend Accessibility
echo "3️⃣ Frontend Accessibility Check"
echo "-------------------------------"

if curl -s http://localhost:3000 >/dev/null 2>&1; then
    echo "✅ Frontend: Accessible on localhost:3000"
else
    echo "❌ Frontend: Not accessible on localhost:3000"
fi

echo ""

# Test 4: Mining System Readiness
echo "4️⃣ Mining System Readiness"
echo "--------------------------"

# Test mining status endpoint
if curl -s http://localhost:8001/api/mining/status >/dev/null 2>&1; then
    MINING_STATUS=$(curl -s http://localhost:8001/api/mining/status | jq -r '.is_mining' 2>/dev/null || echo "unknown")
    TEST_MODE=$(curl -s http://localhost:8001/api/mining/status | jq -r '.test_mode' 2>/dev/null || echo "unknown")
    
    echo "✅ Mining API: Responding"
    echo "   Currently mining: $MINING_STATUS"
    echo "   Test mode: $TEST_MODE"
    
    if [[ "$TEST_MODE" == "false" ]]; then
        echo "✅ Real mining: Enabled (not in test mode)"
    elif [[ "$TEST_MODE" == "true" ]]; then
        echo "⚠️ Test mode: Active (real mining not enabled)"
    fi
else
    echo "❌ Mining API: Not responding"
fi

# Test AI system
if curl -s http://localhost:8001/api/mining/ai-insights >/dev/null 2>&1; then
    echo "✅ AI system: Responding"
else
    echo "❌ AI system: Not responding"
fi

echo ""

# Test 5: System Summary
echo "📋 SYSTEM SUMMARY"
echo "=================="

MONGODB_OK=$(pgrep mongod >/dev/null && echo "true" || echo "false")
API_OK=$(curl -s http://localhost:8001/api/health | jq -r '.status' 2>/dev/null | grep -q "healthy" && echo "true" || echo "false")
FRONTEND_OK=$(curl -s http://localhost:3000 >/dev/null 2>&1 && echo "true" || echo "false")

if [[ "$MONGODB_OK" == "true" ]] && [[ "$API_OK" == "true" ]] && [[ "$FRONTEND_OK" == "true" ]]; then
    echo "🎉 SYSTEM STATUS: FULLY OPERATIONAL"
    echo ""
    echo "✅ All core components are working"
    echo "✅ Ready for cryptocurrency mining"
    echo "✅ Web interface accessible at: http://localhost:3000"
    echo "✅ API endpoints available at: http://localhost:8001"
    echo ""
    echo "🚀 Your mining system is ready to use!"
    
elif [[ "$MONGODB_OK" == "true" ]] && [[ "$API_OK" == "true" ]]; then
    echo "⚠️ SYSTEM STATUS: MOSTLY OPERATIONAL"
    echo ""
    echo "✅ Backend systems are working"
    echo "⚠️ Frontend may need attention"
    echo "✅ Mining functionality is available"
    
else
    echo "❌ SYSTEM STATUS: NEEDS ATTENTION"
    echo ""
    echo "Issues detected:"
    [[ "$MONGODB_OK" == "false" ]] && echo "  • MongoDB is not running"
    [[ "$API_OK" == "false" ]] && echo "  • Backend API is not healthy"
    [[ "$FRONTEND_OK" == "false" ]] && echo "  • Frontend is not accessible"
    echo ""
    echo "Please resolve these issues before mining."
fi

echo ""