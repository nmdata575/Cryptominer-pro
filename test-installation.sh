#!/bin/bash

# CryptoMiner Pro - Installation Test Script
# Quick verification of your CryptoMiner Pro installation

echo "🧪 CryptoMiner Pro Installation Test"
echo "====================================="

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass_count=0
fail_count=0

test_pass() {
    echo -e "${GREEN}✅ PASS${NC} - $1"
    ((pass_count++))
}

test_fail() {
    echo -e "${RED}❌ FAIL${NC} - $1"
    ((fail_count++))
}

test_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC} - $1"
}

echo ""
echo "🔍 Testing Core Services..."

# Test 1: Check if services are running
echo "1. Checking supervisor services..."
if sudo supervisorctl status | grep -q "cryptominer.*RUNNING"; then
    test_pass "CryptoMiner Pro services are running"
else
    test_fail "CryptoMiner Pro services are not running"
    echo "   Try: sudo supervisorctl restart cryptominer-pro:*"
fi

# Test 2: Test MongoDB
echo "2. Testing MongoDB connection..."
if mongo --eval "db.runCommand('ping').ok" --quiet 2>/dev/null | grep -q "1"; then
    test_pass "MongoDB is responsive"
else
    test_fail "MongoDB connection failed"
    echo "   Try: sudo systemctl restart mongod"
fi

# Test 3: Test Backend API
echo "3. Testing Backend API..."
if curl -s -f http://localhost:8001/api/health >/dev/null 2>&1; then
    test_pass "Backend API is responding"
    
    # Get API response for additional info
    HEALTH_RESPONSE=$(curl -s http://localhost:8001/api/health 2>/dev/null)
    if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
        test_pass "Backend reports healthy status"
    else
        test_warn "Backend API responding but status unclear"
    fi
else
    test_fail "Backend API is not responding"
    echo "   Try: sudo supervisorctl restart cryptominer-pro:cryptominer-backend"
fi

# Test 4: Test Frontend
echo "4. Testing Frontend accessibility..."
if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
    test_pass "Frontend is accessible"
else
    test_fail "Frontend is not accessible"
    echo "   Try: sudo supervisorctl restart cryptominer-pro:cryptominer-frontend"
fi

# Test 5: Enhanced CPU Detection API
echo "5. Testing Enhanced CPU Detection..."
CPU_RESPONSE=$(curl -s http://localhost:8001/api/system/cpu-info 2>/dev/null)
if [ $? -eq 0 ] && echo "$CPU_RESPONSE" | grep -q "cores"; then
    test_pass "Enhanced CPU detection API working"
    
    # Extract CPU info
    if command -v jq >/dev/null 2>&1; then
        CPU_CORES=$(echo "$CPU_RESPONSE" | jq -r '.cores.physical // .cores.allocated // "unknown"')
        ENV_TYPE=$(echo "$CPU_RESPONSE" | jq -r '.environment.type // "unknown"')
        RECOMMENDED_THREADS=$(echo "$CPU_RESPONSE" | jq -r '.optimal_mining_config.max_safe_threads // "unknown"')
        
        echo "   💻 Detected: $CPU_CORES cores, Environment: $ENV_TYPE"
        echo "   ⚡ Recommended threads: $RECOMMENDED_THREADS"
    fi
else
    test_fail "Enhanced CPU detection API not working"
fi

# Test 6: Environment Detection API
echo "6. Testing Environment Detection API..."
if curl -s -f http://localhost:8001/api/system/environment >/dev/null 2>&1; then
    test_pass "Environment detection API working"
else
    test_warn "Environment detection API not responding (non-critical)"
fi

# Test 7: Check Mining Functionality
echo "7. Testing Mining Status API..."
MINING_RESPONSE=$(curl -s http://localhost:8001/api/mining/status 2>/dev/null)
if [ $? -eq 0 ] && echo "$MINING_RESPONSE" | grep -q "is_mining"; then
    test_pass "Mining status API working"
    
    if command -v jq >/dev/null 2>&1; then
        IS_MINING=$(echo "$MINING_RESPONSE" | jq -r '.is_mining')
        echo "   ⛏️  Current mining status: $IS_MINING"
    fi
else
    test_fail "Mining status API not working"
fi

# Test 8: Check Coin Presets
echo "8. Testing Coin Presets API..."
COINS_RESPONSE=$(curl -s http://localhost:8001/api/coins/presets 2>/dev/null)
if [ $? -eq 0 ] && echo "$COINS_RESPONSE" | grep -q "litecoin\|dogecoin\|feathercoin"; then
    test_pass "Coin presets API working"
    
    if command -v jq >/dev/null 2>&1; then
        COIN_COUNT=$(echo "$COINS_RESPONSE" | jq -r '.presets | keys | length')
        echo "   🪙 Available coins: $COIN_COUNT"
    fi
else
    test_fail "Coin presets API not working"
fi

echo ""
echo "📊 Test Results Summary"
echo "======================"
echo -e "✅ Passed: ${GREEN}$pass_count${NC} tests"
echo -e "❌ Failed: ${RED}$fail_count${NC} tests"

TOTAL_TESTS=$((pass_count + fail_count))
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$(( (pass_count * 100) / TOTAL_TESTS ))
    echo "📈 Success Rate: $SUCCESS_RATE%"
fi

echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Your CryptoMiner Pro installation is working perfectly.${NC}"
    echo ""
    echo "🚀 Ready to start mining!"
    echo "📊 Access your dashboard: http://localhost:3000"
    echo "🔧 Check API health: http://localhost:8001/api/health"
elif [ $fail_count -lt 3 ]; then
    echo -e "${YELLOW}⚠️  Some tests failed, but the system may still be functional.${NC}"
    echo "🔧 Try restarting services: sudo supervisorctl restart cryptominer-pro:*"
else
    echo -e "${RED}❌ Multiple tests failed. Installation may need attention.${NC}"
    echo ""
    echo "🛠️  Troubleshooting steps:"
    echo "1. Check service logs: sudo tail -f /var/log/supervisor/cryptominer-*.log"
    echo "2. Restart services: sudo supervisorctl restart cryptominer-pro:*"
    echo "3. Check system requirements and run install script again"
fi

echo ""
echo "📚 Useful Commands:"
echo "  cryptominer-status  - Check service status"
echo "  cryptominer-logs    - View all logs"  
echo "  cryptominer-restart - Restart all services"
echo ""

# Additional system info
echo "💻 System Information:"
echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
echo "  CPU Cores: $(nproc)"
echo "  Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "  Node.js: $(node --version 2>/dev/null || echo 'Not found')"
echo "  MongoDB: $(mongo --version 2>/dev/null | head -1 | cut -d' ' -f4 || echo 'Not found')"

echo ""
echo "Installation test completed! 🏁"