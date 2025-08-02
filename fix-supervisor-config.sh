#!/bin/bash

# Fix Supervisor Configuration for User Installation
# Updates supervisor config to match actual installation paths

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 CryptoMiner Pro - Fix Supervisor Configuration${NC}"
echo "================================================="
echo ""

# Determine the correct paths
CURRENT_USER=$(whoami)
echo -e "👤 Current user: ${GREEN}$CURRENT_USER${NC}"

# Find the actual installation directory
INSTALL_DIRS=(
    "/home/$CURRENT_USER/Cryptominer-pro"
    "/home/$CURRENT_USER/Desktop/Cryptominer-pro"
    "/home/$CURRENT_USER/Desktop/Cryptominer-pro-3.5"
    "$HOME/Cryptominer-pro"
)

INSTALL_DIR=""
for dir in "${INSTALL_DIRS[@]}"; do
    if [[ -d "$dir/frontend" && -d "$dir/backend-nodejs" ]]; then
        INSTALL_DIR="$dir"
        echo -e "✅ Found installation at: ${GREEN}$INSTALL_DIR${NC}"
        break
    fi
done

if [[ -z "$INSTALL_DIR" ]]; then
    echo -e "${RED}❌ Could not find CryptoMiner Pro installation${NC}"
    echo "   Searched in:"
    for dir in "${INSTALL_DIRS[@]}"; do
        echo "   - $dir"
    done
    exit 1
fi

# Set correct paths
BACKEND_DIR="$INSTALL_DIR/backend-nodejs"
FRONTEND_DIR="$INSTALL_DIR/frontend"
LOG_DIR="/home/$CURRENT_USER/.local/log/cryptominer"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

echo -e "📂 Configuration paths:"
echo -e "   Install: ${YELLOW}$INSTALL_DIR${NC}"
echo -e "   Backend: ${YELLOW}$BACKEND_DIR${NC}"
echo -e "   Frontend: ${YELLOW}$FRONTEND_DIR${NC}"
echo -e "   Logs: ${YELLOW}$LOG_DIR${NC}"
echo ""

# Stop services before updating config
echo -e "${BLUE}🛑 Stopping services...${NC}"
sudo supervisorctl stop cryptominer-backend 2>/dev/null || echo "Backend not running"
sudo supervisorctl stop cryptominer-frontend 2>/dev/null || echo "Frontend not running"

echo ""

# Update backend supervisor config
echo -e "${BLUE}⚙️ Updating backend supervisor config...${NC}"
sudo tee "/etc/supervisor/conf.d/cryptominer-backend.conf" > /dev/null << EOF
[program:cryptominer-backend]
command=/usr/bin/node server.js
directory=$BACKEND_DIR
user=$CURRENT_USER
autostart=true
autorestart=true
stdout_logfile=$LOG_DIR/backend.log
stderr_logfile=$LOG_DIR/backend-error.log
environment=NODE_ENV=production,PORT=8001
priority=999
killasgroup=true
stopasgroup=true
startsecs=10
startretries=3
stopsignal=TERM
stopwaitsecs=10
EOF

echo -e "✅ Backend config updated for user: ${GREEN}$CURRENT_USER${NC}"

# Update frontend supervisor config
echo -e "${BLUE}⚙️ Updating frontend supervisor config...${NC}"
sudo tee "/etc/supervisor/conf.d/cryptominer-frontend.conf" > /dev/null << EOF
[program:cryptominer-frontend]
command=/usr/bin/npm start
directory=$FRONTEND_DIR
user=$CURRENT_USER
autostart=true
autorestart=true
stdout_logfile=$LOG_DIR/frontend.log
stderr_logfile=$LOG_DIR/frontend-error.log
environment=NODE_ENV=development,PORT=3000
priority=998
killasgroup=true
stopasgroup=true
startsecs=15
startretries=3
stopsignal=TERM
stopwaitsecs=10
EOF

echo -e "✅ Frontend config updated for user: ${GREEN}$CURRENT_USER${NC}"

# Set proper ownership of log files
echo -e "${BLUE}🔒 Setting log file permissions...${NC}"
sudo chown -R $CURRENT_USER:$CURRENT_USER "$LOG_DIR" 2>/dev/null || true
chmod -R 755 "$LOG_DIR" 2>/dev/null || true

# Reload supervisor configuration
echo -e "${BLUE}🔄 Reloading supervisor configuration...${NC}"
sudo supervisorctl reread
sudo supervisorctl update

echo ""

# Start services with new configuration
echo -e "${BLUE}🚀 Starting services with updated configuration...${NC}"

echo "Starting backend..."
sudo supervisorctl start cryptominer-backend
sleep 5

echo "Backend status:"
sudo supervisorctl status cryptominer-backend

echo ""
echo "Starting frontend..."
sudo supervisorctl start cryptominer-frontend
sleep 10

echo "Frontend status:"
sudo supervisorctl status cryptominer-frontend

echo ""

# Final status check
echo -e "${BLUE}📊 Final Status Check${NC}"
echo "All services:"
sudo supervisorctl status | grep cryptominer

echo ""

# Health check
echo -e "${BLUE}🌐 Health Check${NC}"

# Check backend
echo -n "Backend API: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/health | grep -q "200"; then
    echo -e "${GREEN}✅ Responding${NC}"
else
    echo -e "${RED}❌ Not responding${NC}"
    echo "Backend logs (last 5 lines):"
    sudo supervisorctl tail cryptominer-backend stderr | tail -5
fi

# Check frontend  
echo -n "Frontend: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
    echo -e "${GREEN}✅ Responding${NC}"
else
    echo -e "${RED}❌ Not responding${NC}"
    echo "Frontend logs (last 5 lines):"
    sudo supervisorctl tail cryptominer-frontend stderr | tail -5
fi

echo ""
echo -e "${GREEN}🎉 Supervisor configuration update completed!${NC}"
echo ""
echo -e "${BLUE}📋 Summary of changes:${NC}"
echo "✅ Updated paths to match your installation"
echo "✅ Set correct user ($CURRENT_USER) instead of root"
echo "✅ Fixed log file paths and permissions"  
echo "✅ Set appropriate environment variables"
echo ""
echo -e "${GREEN}🌐 Access your CryptoMiner Pro:${NC}"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8001/api/health"