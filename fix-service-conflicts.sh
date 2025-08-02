#!/bin/bash

# Service Conflict Resolution Script
# Fixes port conflicts and service startup issues

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 CryptoMiner Pro - Service Conflict Fix${NC}"
echo "============================================="
echo ""

# Function to kill processes on specific ports
kill_port() {
    local port=$1
    local process_name=$2
    
    echo -e "🔍 Checking port $port for $process_name..."
    
    if netstat -tulnp | grep ":$port " > /dev/null; then
        echo -e "${YELLOW}⚠️  Port $port is in use. Clearing...${NC}"
        
        # Get PIDs using the port
        local pids=$(lsof -ti:$port 2>/dev/null || echo "")
        
        if [[ -n "$pids" ]]; then
            echo "   Killing processes: $pids"
            for pid in $pids; do
                sudo kill -9 $pid 2>/dev/null || echo "     Could not kill PID $pid"
            done
            sleep 2
        fi
        
        # Double-check the port is free
        if ! netstat -tulnp | grep ":$port " > /dev/null; then
            echo -e "${GREEN}   ✅ Port $port is now free${NC}"
        else
            echo -e "${RED}   ❌ Port $port is still in use${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}   ✅ Port $port is free${NC}"
    fi
}

# Function to check and start MongoDB
ensure_mongodb() {
    echo -e "\n🗄️  Checking MongoDB..."
    
    if pgrep mongod > /dev/null; then
        echo -e "${GREEN}✅ MongoDB is running${NC}"
    else
        echo -e "${YELLOW}⚠️  MongoDB not running. Starting...${NC}"
        
        # Ensure data directory exists
        sudo mkdir -p /data/db
        sudo chown mongodb:mongodb /data/db 2>/dev/null || sudo chown $(whoami):$(whoami) /data/db
        
        # Start MongoDB
        if mongod --dbpath /data/db --logpath /var/log/mongodb.log --fork; then
            echo -e "${GREEN}✅ MongoDB started successfully${NC}"
            sleep 3
        else
            echo -e "${RED}❌ Failed to start MongoDB${NC}"
            return 1
        fi
    fi
}

# Main cleanup process
main() {
    echo "🧹 Step 1: Stopping all CryptoMiner services..."
    sudo supervisorctl stop all 2>/dev/null || echo "Some services were already stopped"
    
    echo -e "\n🧹 Step 2: Clearing port conflicts..."
    kill_port 3000 "Frontend"
    kill_port 8001 "Backend"
    
    echo -e "\n🧹 Step 3: Cleaning up any remaining Node.js processes..."
    sudo pkill -f "node.*craco" 2>/dev/null || echo "No CRACO processes found"
    sudo pkill -f "node.*server.js" 2>/dev/null || echo "No backend server processes found"
    
    echo -e "\n🧹 Step 4: Ensuring MongoDB is running..."
    ensure_mongodb
    
    echo -e "\n🔄 Step 5: Restarting Supervisor..."
    sudo service supervisor stop
    sleep 3
    sudo service supervisor start
    sleep 5
    
    echo -e "\n🚀 Step 6: Starting CryptoMiner services..."
    
    # Start backend first
    echo "Starting backend..."
    sudo supervisorctl start cryptominer-backend
    sleep 5
    
    # Check if backend started successfully
    if sudo supervisorctl status cryptominer-backend | grep -q "RUNNING"; then
        echo -e "${GREEN}✅ Backend started successfully${NC}"
    else
        echo -e "${RED}❌ Backend failed to start${NC}"
        echo "Backend logs:"
        sudo supervisorctl tail cryptominer-backend stderr | tail -5
    fi
    
    # Start frontend
    echo "Starting frontend..."
    sudo supervisorctl start cryptominer-frontend
    sleep 10
    
    # Check if frontend started successfully
    if sudo supervisorctl status cryptominer-frontend | grep -q "RUNNING"; then
        echo -e "${GREEN}✅ Frontend started successfully${NC}"
    else
        echo -e "${RED}❌ Frontend failed to start${NC}"
        echo "Frontend logs:"
        sudo supervisorctl tail cryptominer-frontend stderr | tail -5
    fi
    
    echo -e "\n📊 Final Status Check..."
    sudo supervisorctl status | grep cryptominer
    
    echo -e "\n🌐 Service Health Check..."
    
    # Test backend
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/health | grep -q "200"; then
        echo -e "${GREEN}✅ Backend API responding (http://localhost:8001/api/health)${NC}"
    else
        echo -e "${RED}❌ Backend API not responding${NC}"
    fi
    
    # Test frontend
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
        echo -e "${GREEN}✅ Frontend responding (http://localhost:3000)${NC}"
    else
        echo -e "${RED}❌ Frontend not responding${NC}"
    fi
    
    echo -e "\n🎉 Service conflict resolution completed!"
    echo ""
    echo "🎮 Management commands:"
    echo "   cryptominer status  - Check service status"
    echo "   cryptominer logs    - View recent logs"
    echo "   cryptominer restart - Restart all services"
    echo ""
    echo "🌐 Access URLs:"
    echo "   Frontend: http://localhost:3000"
    echo "   Backend API: http://localhost:8001/api/health"
}

# Run the main function
main "$@"