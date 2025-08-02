#!/bin/bash

# Fix Frontend Spawn Error
# Diagnose and fix supervisor spawn issues

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CURRENT_USER=$(whoami)
INSTALL_DIR="/home/chris/Cryptominer-pro"
FRONTEND_DIR="$INSTALL_DIR/frontend"
LOG_DIR="/home/chris/.local/log/cryptominer"

echo -e "${BLUE}🔧 CryptoMiner Pro - Fix Frontend Spawn Error${NC}"
echo "============================================="
echo ""

# Step 1: Create log directory
echo -e "${BLUE}📁 Step 1: Setting up log directory${NC}"
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"
echo -e "✅ Log directory created: $LOG_DIR"

# Step 2: Check installation directory
echo -e "${BLUE}📂 Step 2: Checking installation directory${NC}"
if [[ -d "$FRONTEND_DIR" ]]; then
    echo -e "✅ Frontend directory exists: $FRONTEND_DIR"
    echo -e "   Owner: $(ls -ld "$FRONTEND_DIR" | awk '{print $3":"$4}')"
    
    # Check key files
    if [[ -f "$FRONTEND_DIR/package.json" ]]; then
        echo -e "✅ package.json exists"
    else
        echo -e "${RED}❌ package.json missing${NC}"
        exit 1
    fi
    
    if [[ -d "$FRONTEND_DIR/node_modules" ]]; then
        echo -e "✅ node_modules exists"
    else
        echo -e "${YELLOW}⚠️ node_modules missing - installing${NC}"
        cd "$FRONTEND_DIR"
        npm install
    fi
else
    echo -e "${RED}❌ Frontend directory not found: $FRONTEND_DIR${NC}"
    exit 1
fi

echo ""

# Step 3: Test manual npm start to ensure it works
echo -e "${BLUE}🧪 Step 3: Testing manual npm start${NC}"
cd "$FRONTEND_DIR"

# Kill any existing processes on port 3000
sudo lsof -ti:3000 | xargs -r sudo kill -9 2>/dev/null || true
sleep 2

echo "Testing npm start in background..."
timeout 15 npm start > /tmp/npm-test.log 2>&1 &
NPM_PID=$!

sleep 10

if kill -0 $NPM_PID 2>/dev/null; then
    echo -e "✅ npm start works manually"
    kill $NPM_PID 2>/dev/null || true
    sleep 2
else
    echo -e "${RED}❌ npm start fails even manually${NC}"
    echo "Error log:"
    cat /tmp/npm-test.log | tail -5
    exit 1
fi

# Clean up any remaining processes
sudo pkill -f "craco start" 2>/dev/null || true
sudo lsof -ti:3000 | xargs -r sudo kill -9 2>/dev/null || true
sleep 2

echo ""

# Step 4: Check npm and node paths
echo -e "${BLUE}🔍 Step 4: Checking npm and node paths${NC}"
echo "   Node path: $(which node)"
echo "   Node version: $(node --version)"
echo "   npm path: $(which npm)"  
echo "   npm version: $(npm --version)"

# Check if /usr/bin/npm exists (what supervisor is trying to use)
if [[ -f "/usr/bin/npm" ]]; then
    echo -e "✅ /usr/bin/npm exists"
    echo "   /usr/bin/npm version: $(/usr/bin/npm --version)"
else
    echo -e "${YELLOW}⚠️ /usr/bin/npm not found${NC}"
    
    # Create symlink if needed
    npm_path=$(which npm)
    if [[ -n "$npm_path" ]]; then
        echo "Creating symlink: $npm_path -> /usr/bin/npm"
        sudo ln -sf "$npm_path" /usr/bin/npm
        echo -e "✅ Created npm symlink"
    fi
fi

echo ""

# Step 5: Update supervisor config with full paths and environment
echo -e "${BLUE}⚙️ Step 5: Creating robust supervisor configuration${NC}"

# Get full paths
NODE_PATH=$(which node)
NPM_PATH="/usr/bin/npm"

# Create enhanced supervisor config
sudo tee "/etc/supervisor/conf.d/cryptominer-frontend.conf" > /dev/null << EOF
[program:cryptominer-frontend]
command=$NPM_PATH start
directory=$FRONTEND_DIR
user=$CURRENT_USER
autostart=true
autorestart=true
stdout_logfile=$LOG_DIR/frontend.log
stderr_logfile=$LOG_DIR/frontend-error.log
environment=NODE_ENV=development,PORT=3000,PATH="/usr/local/bin:/usr/bin:/bin"
priority=998
killasgroup=true
stopasgroup=true
startsecs=20
startretries=5
stopsignal=TERM
stopwaitsecs=15
redirect_stderr=true
stdout_logfile_maxbytes=50MB
stderr_logfile_maxbytes=50MB
EOF

echo -e "✅ Enhanced supervisor config created"

# Step 6: Reload and start
echo -e "${BLUE}🔄 Step 6: Reloading supervisor and starting service${NC}"

sudo supervisorctl stop cryptominer-frontend 2>/dev/null || echo "Service not running"
sudo supervisorctl reread
sudo supervisorctl update

echo ""

# Clear any processes still using port 3000
echo "Clearing port 3000..."
sudo lsof -ti:3000 | xargs -r sudo kill -9 2>/dev/null || true
sleep 3

echo "Starting frontend service..."
sudo supervisorctl start cryptominer-frontend

echo ""
echo "Waiting for service to initialize..."
sleep 15

# Check status
echo -e "${BLUE}📊 Step 7: Status Check${NC}"
echo "Service status:"
sudo supervisorctl status cryptominer-frontend

echo ""
echo "Port check:"
if netstat -tulnp 2>/dev/null | grep ":3000" > /dev/null; then
    pid=$(netstat -tulnp 2>/dev/null | grep ":3000" | awk '{print $7}' | cut -d'/' -f1)
    echo -e "✅ Port 3000 in use by PID: $pid"
else
    echo -e "${RED}❌ Port 3000 not in use${NC}"
fi

echo ""
echo "Health check:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
    echo -e "${GREEN}✅ Frontend is responding at http://localhost:3000${NC}"
else
    echo -e "${RED}❌ Frontend not responding${NC}"
    
    echo ""
    echo "Recent frontend logs:"
    if [[ -f "$LOG_DIR/frontend-error.log" ]]; then
        tail -10 "$LOG_DIR/frontend-error.log"
    else
        echo "No error log found"
    fi
    
    echo ""
    echo "Supervisor logs:"
    sudo supervisorctl tail cryptominer-frontend stderr | tail -10
fi

echo ""
echo -e "${GREEN}🎉 Frontend spawn fix completed!${NC}"
echo ""
echo -e "${BLUE}🌐 Your CryptoMiner Pro should now be accessible at:${NC}"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8001/api/health"
echo ""
echo -e "${YELLOW}If issues persist:${NC}"
echo "1. Check logs: tail -f $LOG_DIR/frontend-error.log"
echo "2. Check supervisor: sudo supervisorctl status"
echo "3. Test manual start: cd $FRONTEND_DIR && npm start"