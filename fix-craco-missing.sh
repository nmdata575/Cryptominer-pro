#!/bin/bash

# Fix Missing CRACO Issue
# Complete reinstallation of frontend dependencies

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FRONTEND_DIR="/home/chris/Cryptominer-pro/frontend"

echo -e "${BLUE}🔧 CryptoMiner Pro - Fix Missing CRACO${NC}"
echo "====================================="
echo ""

echo -e "👤 Current user: ${GREEN}$(whoami)${NC}"
echo -e "📂 Frontend directory: ${GREEN}$FRONTEND_DIR${NC}"

# Check if we're the right user
if [[ "$(whoami)" != "chris" ]]; then
    echo -e "${RED}❌ Please run this script as user 'chris'${NC}"
    exit 1
fi

cd "$FRONTEND_DIR"

echo ""
echo -e "${BLUE}🔍 Step 1: Diagnosing the issue${NC}"

# Check current state
echo "Current node_modules/.bin contents:"
if [[ -d "node_modules/.bin" ]]; then
    ls -la node_modules/.bin/ | head -10
    echo ""
    
    if [[ -f "node_modules/.bin/craco" ]]; then
        echo -e "✅ CRACO binary exists"
        echo "Testing CRACO directly:"
        node_modules/.bin/craco --version || echo "CRACO binary is corrupted"
    else
        echo -e "${RED}❌ CRACO binary missing from node_modules/.bin/${NC}"
    fi
else
    echo -e "${RED}❌ node_modules/.bin directory missing${NC}"
fi

echo ""
echo -e "${BLUE}🧹 Step 2: Clean installation${NC}"

# Stop any running processes
sudo supervisorctl stop cryptominer-frontend 2>/dev/null || echo "Service not running"
sudo lsof -ti:3000 | xargs -r sudo kill -9 2>/dev/null || true

echo "Removing corrupted node_modules and lock files..."
rm -rf node_modules package-lock.json yarn.lock 2>/dev/null || true

echo "Clearing npm cache..."
npm cache clean --force

echo ""
echo -e "${BLUE}📦 Step 3: Fresh installation${NC}"

echo "Installing dependencies with npm..."
if npm install; then
    echo -e "${GREEN}✅ Dependencies installed successfully${NC}"
else
    echo -e "${RED}❌ npm install failed${NC}"
    
    # Try with yarn if npm fails
    echo "Trying with yarn..."
    if command -v yarn >/dev/null 2>&1; then
        yarn install
    else
        echo "Installing yarn..."
        npm install -g yarn
        yarn install
    fi
fi

echo ""
echo -e "${BLUE}🔍 Step 4: Verification${NC}"

# Check if CRACO is now installed
if [[ -f "node_modules/.bin/craco" ]]; then
    echo -e "✅ CRACO binary exists"
    
    # Test CRACO
    echo "Testing CRACO version:"
    node_modules/.bin/craco --version
    
    echo ""
    echo "Testing CRACO directly:"
    if timeout 10 node_modules/.bin/craco start --help >/dev/null 2>&1; then
        echo -e "✅ CRACO command works"
    else
        echo -e "${YELLOW}⚠️ CRACO may have issues but binary exists${NC}"
    fi
else
    echo -e "${RED}❌ CRACO binary still missing${NC}"
    
    # Manual CRACO installation
    echo "Installing CRACO manually..."
    npm install --save-dev @craco/craco
    
    if [[ -f "node_modules/.bin/craco" ]]; then
        echo -e "✅ CRACO installed manually"
    else
        echo -e "${RED}❌ Manual CRACO installation failed${NC}"
        exit 1
    fi
fi

# Check other key dependencies
echo ""
echo "Checking key dependencies:"
KEY_DEPS=(
    "@craco/craco"
    "react"
    "react-dom"
    "react-scripts"
)

for dep in "${KEY_DEPS[@]}"; do
    if [[ -d "node_modules/$dep" ]]; then
        echo -e "   ✅ $dep"
    else
        echo -e "   ${RED}❌ $dep missing${NC}"
        npm install $dep
    fi
done

echo ""
echo -e "${BLUE}🧪 Step 5: Testing npm start${NC}"

# Test npm start
echo "Testing npm start..."
export NODE_ENV=development
export PORT=3000

timeout 15 npm start > /tmp/test-npm-start.log 2>&1 &
TEST_PID=$!

sleep 8

if kill -0 $TEST_PID 2>/dev/null; then
    echo -e "${GREEN}✅ npm start works with CRACO!${NC}"
    kill $TEST_PID 2>/dev/null || true
    
    # Wait for cleanup
    sleep 3
    sudo pkill -f "craco start" 2>/dev/null || true
    sudo lsof -ti:3000 | xargs -r sudo kill -9 2>/dev/null || true
else
    echo -e "${RED}❌ npm start still fails${NC}"
    echo "Error log:"
    cat /tmp/test-npm-start.log | tail -10
    exit 1
fi

echo ""
echo -e "${BLUE}⚙️ Step 6: Updating supervisor with working configuration${NC}"

# Create supervisor config that works
LOG_DIR="/home/chris/.local/log/cryptominer"
mkdir -p "$LOG_DIR"

sudo tee "/etc/supervisor/conf.d/cryptominer-frontend.conf" > /dev/null << EOF
[program:cryptominer-frontend]
command=/usr/bin/npm start
directory=$FRONTEND_DIR
user=chris
autostart=true
autorestart=true
stdout_logfile=$LOG_DIR/frontend.log
stderr_logfile=$LOG_DIR/frontend-error.log
environment=NODE_ENV=development,PORT=3000,PATH="/usr/local/bin:/usr/bin:/bin:/home/chris/.local/bin"
priority=998
killasgroup=true
stopasgroup=true
startsecs=20
startretries=3
stopsignal=TERM
stopwaitsecs=15
redirect_stderr=true
EOF

echo -e "✅ Supervisor configuration updated"

# Reload supervisor
sudo supervisorctl reread
sudo supervisorctl update

echo ""
echo -e "${BLUE}🚀 Step 7: Starting frontend service${NC}"

# Ensure port is clear
sudo lsof -ti:3000 | xargs -r sudo kill -9 2>/dev/null || true
sleep 3

# Start the service
sudo supervisorctl start cryptominer-frontend

echo "Waiting for service to start..."
sleep 15

# Check status
echo ""
echo -e "${BLUE}📊 Final Status${NC}"

echo "Service status:"
sudo supervisorctl status cryptominer-frontend

echo ""
echo "Port check:"
if netstat -tulnp 2>/dev/null | grep ":3000" >/dev/null; then
    echo -e "✅ Port 3000 is in use"
else
    echo -e "${RED}❌ Port 3000 not in use${NC}"
fi

echo ""
echo "Health check:"
sleep 5  # Give it more time
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
    echo -e "${GREEN}🎉 ✅ Frontend is working at http://localhost:3000${NC}"
else
    echo -e "${RED}❌ Frontend not responding${NC}"
    
    echo ""
    echo "Recent logs:"
    if [[ -f "$LOG_DIR/frontend-error.log" ]]; then
        echo "Error log:"
        tail -10 "$LOG_DIR/frontend-error.log"
    fi
    
    echo ""
    echo "Supervisor tail:"
    sudo supervisorctl tail cryptominer-frontend stderr | tail -10
fi

echo ""
echo -e "${GREEN}🎉 CRACO fix completed!${NC}"
echo ""
echo -e "${BLUE}🌐 Your CryptoMiner Pro:${NC}"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8001/api/health"
echo ""
echo -e "${YELLOW}To check status:${NC}"
echo "   sudo supervisorctl status"
echo "   curl http://localhost:3000"