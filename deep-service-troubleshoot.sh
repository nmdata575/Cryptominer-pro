#!/bin/bash

# Deep Service Troubleshooting Script
# Comprehensive diagnosis and fix for persistent service issues

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

INSTALL_DIR="$HOME/Cryptominer-pro"
LOG_DIR="$HOME/.local/log/cryptominer"

echo -e "${BLUE}🔬 CryptoMiner Pro - Deep Service Troubleshooting${NC}"
echo "=================================================="
echo ""

# Function to show running processes
show_processes() {
    echo -e "${PURPLE}📋 Current Node.js and related processes:${NC}"
    ps aux | grep -E "(node|craco|supervisor)" | grep -v grep || echo "No relevant processes found"
    echo ""
}

# Function to show port usage
show_ports() {
    echo -e "${PURPLE}🔌 Port usage (3000, 8001):${NC}"
    netstat -tulnp 2>/dev/null | grep -E ":(3000|8001)" || echo "Ports 3000 and 8001 are free"
    echo ""
}

# Function to check supervisor config
check_supervisor_config() {
    echo -e "${PURPLE}⚙️  Checking Supervisor Configuration:${NC}"
    
    # Backend config
    if [[ -f "/etc/supervisor/conf.d/cryptominer-backend.conf" ]]; then
        echo "✅ Backend config exists"
        echo "   Directory: $(grep "directory=" /etc/supervisor/conf.d/cryptominer-backend.conf | cut -d'=' -f2)"
        echo "   Command: $(grep "command=" /etc/supervisor/conf.d/cryptominer-backend.conf | cut -d'=' -f2)"
        echo "   User: $(grep "user=" /etc/supervisor/conf.d/cryptominer-backend.conf | cut -d'=' -f2)"
    else
        echo "❌ Backend config missing"
    fi
    
    # Frontend config
    if [[ -f "/etc/supervisor/conf.d/cryptominer-frontend.conf" ]]; then
        echo "✅ Frontend config exists"
        echo "   Directory: $(grep "directory=" /etc/supervisor/conf.d/cryptominer-frontend.conf | cut -d'=' -f2)"
        echo "   Command: $(grep "command=" /etc/supervisor/conf.d/cryptominer-frontend.conf | cut -d'=' -f2)"
        echo "   User: $(grep "user=" /etc/supervisor/conf.d/cryptominer-frontend.conf | cut -d'=' -f2)"
    else
        echo "❌ Frontend config missing"
    fi
    echo ""
}

# Function to check file permissions and existence
check_files() {
    echo -e "${PURPLE}📁 Checking Application Files:${NC}"
    
    if [[ -d "$INSTALL_DIR" ]]; then
        echo "✅ Install directory exists: $INSTALL_DIR"
        echo "   Owner: $(ls -ld "$INSTALL_DIR" | awk '{print $3":"$4}')"
    else
        echo "❌ Install directory missing: $INSTALL_DIR"
        return 1
    fi
    
    # Backend files
    if [[ -f "$INSTALL_DIR/backend-nodejs/server.js" ]]; then
        echo "✅ Backend server.js exists"
        echo "   Owner: $(ls -l "$INSTALL_DIR/backend-nodejs/server.js" | awk '{print $3":"$4}')"
    else
        echo "❌ Backend server.js missing"
    fi
    
    # Frontend files
    if [[ -f "$INSTALL_DIR/frontend/package.json" ]]; then
        echo "✅ Frontend package.json exists"
        echo "   Owner: $(ls -l "$INSTALL_DIR/frontend/package.json" | awk '{print $3":"$4}')"
    else
        echo "❌ Frontend package.json missing"
    fi
    
    # Log directory
    if [[ -d "$LOG_DIR" ]]; then
        echo "✅ Log directory exists: $LOG_DIR"
        echo "   Owner: $(ls -ld "$LOG_DIR" | awk '{print $3":"$4}')"
    else
        echo "⚠️  Log directory missing: $LOG_DIR"
        mkdir -p "$LOG_DIR"
        echo "✅ Created log directory"
    fi
    echo ""
}

# Function to test backend manually
test_backend_manual() {
    echo -e "${PURPLE}🧪 Testing Backend Manually:${NC}"
    
    cd "$INSTALL_DIR/backend-nodejs" || return 1
    
    # Check if we can run the server directly
    echo "Testing: cd $INSTALL_DIR/backend-nodejs && node server.js"
    
    timeout 10 node server.js > /tmp/backend-test.log 2>&1 &
    local test_pid=$!
    
    sleep 5
    
    if kill -0 $test_pid 2>/dev/null; then
        echo "✅ Backend can start manually"
        kill $test_pid 2>/dev/null || true
        
        # Test if it responds
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/health | grep -q "200"; then
            echo "✅ Backend API responds correctly"
        else
            echo "❌ Backend API not responding"
        fi
    else
        echo "❌ Backend fails to start manually"
        echo "Error log:"
        cat /tmp/backend-test.log | tail -5
    fi
    
    # Clean up any test processes
    pkill -f "node server.js" 2>/dev/null || true
    echo ""
}

# Function to test frontend manually
test_frontend_manual() {
    echo -e "${PURPLE}🧪 Testing Frontend Manually:${NC}"
    
    cd "$INSTALL_DIR/frontend" || return 1
    
    # Check node_modules
    if [[ -d "node_modules" ]]; then
        echo "✅ node_modules exists"
    else
        echo "❌ node_modules missing - running npm install"
        npm install
    fi
    
    # Check craco
    if [[ -f "node_modules/.bin/craco" ]]; then
        echo "✅ CRACO binary exists"
    else
        echo "❌ CRACO binary missing"
    fi
    
    # Test start command
    echo "Testing: cd $INSTALL_DIR/frontend && npm start"
    
    timeout 15 npm start > /tmp/frontend-test.log 2>&1 &
    local test_pid=$!
    
    sleep 10
    
    if kill -0 $test_pid 2>/dev/null; then
        echo "✅ Frontend can start manually"
        kill $test_pid 2>/dev/null || true
        
        # Test if it responds
        sleep 2
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
            echo "✅ Frontend responds correctly"
        else
            echo "❌ Frontend not responding"
        fi
    else
        echo "❌ Frontend fails to start manually"
        echo "Error log:"
        cat /tmp/frontend-test.log | tail -10
    fi
    
    # Clean up any test processes
    pkill -f "craco start" 2>/dev/null || true
    pkill -f "node.*3000" 2>/dev/null || true
    echo ""
}

# Function to fix permissions
fix_permissions() {
    echo -e "${PURPLE}🔧 Fixing Permissions:${NC}"
    
    local current_user=$(whoami)
    
    # Fix application directory ownership
    if [[ "$current_user" != "root" ]]; then
        echo "Setting ownership to $current_user..."
        sudo chown -R "$current_user:$current_user" "$INSTALL_DIR"
        sudo chown -R "$current_user:$current_user" "$LOG_DIR"
    fi
    
    # Set proper permissions
    chmod -R 755 "$INSTALL_DIR"
    chmod -R 755 "$LOG_DIR"
    
    echo "✅ Permissions fixed"
    echo ""
}

# Function to recreate supervisor configs
recreate_supervisor_configs() {
    echo -e "${PURPLE}🔧 Recreating Supervisor Configurations:${NC}"
    
    local current_user=$(whoami)
    
    # Backend config
    sudo tee "/etc/supervisor/conf.d/cryptominer-backend.conf" > /dev/null << EOF
[program:cryptominer-backend]
command=/usr/bin/node server.js
directory=$INSTALL_DIR/backend-nodejs
user=$current_user
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

    # Frontend config
    sudo tee "/etc/supervisor/conf.d/cryptominer-frontend.conf" > /dev/null << EOF
[program:cryptominer-frontend]
command=/usr/bin/npm start
directory=$INSTALL_DIR/frontend
user=$current_user
autostart=true
autorestart=true
stdout_logfile=$LOG_DIR/frontend.log
stderr_logfile=$LOG_DIR/frontend-error.log
environment=NODE_ENV=production,PORT=3000
priority=998
killasgroup=true
stopasgroup=true
startsecs=15
startretries=3
stopsignal=TERM
stopwaitsecs=10
EOF

    echo "✅ Supervisor configs recreated for user: $current_user"
    echo ""
}

# Main troubleshooting process
main() {
    echo "🔍 Starting comprehensive troubleshooting..."
    echo ""
    
    # Step 1: Show current state
    echo -e "${BLUE}=== STEP 1: CURRENT STATE ===${NC}"
    show_processes
    show_ports
    
    # Step 2: Check configurations
    echo -e "${BLUE}=== STEP 2: CONFIGURATION CHECK ===${NC}"
    check_supervisor_config
    check_files
    
    # Step 3: Stop everything cleanly
    echo -e "${BLUE}=== STEP 3: CLEAN SHUTDOWN ===${NC}"
    sudo supervisorctl stop all 2>/dev/null || echo "Services were not running"
    sudo pkill -f "node.*server.js" 2>/dev/null || echo "No backend processes to kill"
    sudo pkill -f "craco start" 2>/dev/null || echo "No frontend processes to kill"
    sleep 3
    
    # Step 4: Fix permissions and configs
    echo -e "${BLUE}=== STEP 4: FIXING ISSUES ===${NC}"
    fix_permissions
    recreate_supervisor_configs
    
    # Step 5: Test manually first
    echo -e "${BLUE}=== STEP 5: MANUAL TESTING ===${NC}"
    
    # Ensure MongoDB is running
    if ! pgrep mongod > /dev/null; then
        echo "Starting MongoDB..."
        mongod --dbpath /data/db --logpath /var/log/mongodb.log --fork
        sleep 3
    fi
    
    test_backend_manual
    test_frontend_manual
    
    # Step 6: Start with supervisor
    echo -e "${BLUE}=== STEP 6: SUPERVISOR STARTUP ===${NC}"
    
    # Reload supervisor
    sudo supervisorctl reread
    sudo supervisorctl update
    
    # Start backend first
    echo "Starting backend with supervisor..."
    sudo supervisorctl start cryptominer-backend
    sleep 5
    
    echo "Backend status:"
    sudo supervisorctl status cryptominer-backend
    
    # Start frontend
    echo "Starting frontend with supervisor..."
    sudo supervisorctl start cryptominer-frontend
    sleep 10
    
    echo "Frontend status:"
    sudo supervisorctl status cryptominer-frontend
    
    # Final status
    echo -e "${BLUE}=== FINAL STATUS ===${NC}"
    sudo supervisorctl status | grep cryptominer
    
    # Health check
    echo -e "\n🌐 Health Check:"
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/health | grep -q "200"; then
        echo -e "${GREEN}✅ Backend API: http://localhost:8001/api/health${NC}"
    else
        echo -e "${RED}❌ Backend API not responding${NC}"
        echo "Backend error log:"
        sudo supervisorctl tail cryptominer-backend stderr | tail -5
    fi
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
        echo -e "${GREEN}✅ Frontend: http://localhost:3000${NC}"
    else
        echo -e "${RED}❌ Frontend not responding${NC}"
        echo "Frontend error log:"
        sudo supervisorctl tail cryptominer-frontend stderr | tail -5
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Deep troubleshooting completed!${NC}"
    echo ""
    echo "If issues persist, check the manual testing results above."
}

# Run main function
main "$@"