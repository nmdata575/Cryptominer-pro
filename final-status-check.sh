#!/bin/bash

# Final Status Check Script
# Comprehensive verification of CryptoMiner Pro installation

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎯 CryptoMiner Pro - Final Status Check${NC}"
echo "======================================="
echo ""

# System info
echo -e "${PURPLE}📋 System Information:${NC}"
echo "   User: $(whoami)"
echo "   Node.js: $(node --version)"
echo "   npm: $(npm --version)"
echo "   OS: $(lsb_release -d 2>/dev/null | cut -d: -f2 | xargs || echo "Unknown")"
echo ""

# Installation check
INSTALL_DIR="$HOME/Cryptominer-pro"
echo -e "${PURPLE}📂 Installation Check:${NC}"

if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "   ✅ Installation directory: $INSTALL_DIR"
    
    if [[ -f "$INSTALL_DIR/backend-nodejs/server.js" ]]; then
        echo -e "   ✅ Backend server.js exists"
    else
        echo -e "   ${RED}❌ Backend server.js missing${NC}"
    fi
    
    if [[ -f "$INSTALL_DIR/frontend/package.json" ]]; then
        echo -e "   ✅ Frontend package.json exists"
    else
        echo -e "   ${RED}❌ Frontend package.json missing${NC}"
    fi
    
    if [[ -f "$INSTALL_DIR/frontend/craco.config.js" ]]; then
        echo -e "   ✅ CRACO configuration exists"
    else
        echo -e "   ${RED}❌ CRACO configuration missing${NC}"
    fi
    
else
    echo -e "   ${RED}❌ Installation directory not found: $INSTALL_DIR${NC}"
fi
echo ""

# Dependencies check
echo -e "${PURPLE}📦 Dependencies Check:${NC}"
if [[ -d "$INSTALL_DIR/frontend/node_modules" ]]; then
    echo -e "   ✅ Frontend node_modules exists"
    
    if [[ -f "$INSTALL_DIR/frontend/node_modules/.bin/craco" ]]; then
        echo -e "   ✅ CRACO binary available"
    else
        echo -e "   ${RED}❌ CRACO binary missing${NC}"
    fi
else
    echo -e "   ${RED}❌ Frontend node_modules missing${NC}"
fi
echo ""

# Services check
echo -e "${PURPLE}🔧 Services Check:${NC}"
if command -v supervisorctl &> /dev/null; then
    echo "   Supervisor status:"
    sudo supervisorctl status | grep cryptominer | while read line; do
        if echo "$line" | grep -q "RUNNING"; then
            echo -e "   ${GREEN}✅ $line${NC}"
        else
            echo -e "   ${RED}❌ $line${NC}"
        fi
    done
else
    echo -e "   ${RED}❌ Supervisor not available${NC}"
fi
echo ""

# Port check
echo -e "${PURPLE}🔌 Port Check:${NC}"
if netstat -tulnp 2>/dev/null | grep ":8001" &> /dev/null; then
    backend_pid=$(netstat -tulnp 2>/dev/null | grep ":8001" | awk '{print $7}' | cut -d'/' -f1)
    echo -e "   ✅ Backend port 8001 (PID: $backend_pid)"
else
    echo -e "   ${RED}❌ Backend port 8001 not in use${NC}"
fi

if netstat -tulnp 2>/dev/null | grep ":3000" &> /dev/null; then
    frontend_pid=$(netstat -tulnp 2>/dev/null | grep ":3000" | awk '{print $7}' | cut -d'/' -f1)
    echo -e "   ✅ Frontend port 3000 (PID: $frontend_pid)"
else
    echo -e "   ${RED}❌ Frontend port 3000 not in use${NC}"
fi
echo ""

# Database check
echo -e "${PURPLE}🗄️  Database Check:${NC}"
if pgrep mongod &> /dev/null; then
    echo -e "   ✅ MongoDB is running"
else
    echo -e "   ${RED}❌ MongoDB is not running${NC}"
fi
echo ""

# Health check
echo -e "${PURPLE}🌐 Health Check:${NC}"

# Backend health
echo -n "   Backend API: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/health | grep -q "200"; then
    echo -e "${GREEN}✅ Responding${NC}"
    
    # Get API info
    api_response=$(curl -s http://localhost:8001/api/health 2>/dev/null || echo '{}')
    if echo "$api_response" | grep -q "healthy"; then
        uptime=$(echo "$api_response" | grep -o '"uptime":[^,]*' | cut -d':' -f2 || echo "unknown")
        echo -e "     Status: Healthy (uptime: ${uptime}s)"
    fi
else
    echo -e "${RED}❌ Not responding${NC}"
fi

# Frontend health
echo -n "   Frontend: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
    echo -e "${GREEN}✅ Responding${NC}"
else
    echo -e "${RED}❌ Not responding${NC}"
fi

echo ""

# Management commands info
echo -e "${PURPLE}🎮 Management Commands:${NC}"
if [[ -f "$HOME/.local/bin/cryptominer" ]]; then
    echo -e "   ✅ cryptominer command available"
    echo "     cryptominer status  - Check service status"
    echo "     cryptominer logs    - View recent logs"
    echo "     cryptominer restart - Restart services"
else
    echo -e "   ${YELLOW}⚠️  cryptominer command not found${NC}"
    echo "     Use: sudo supervisorctl status"
fi
echo ""

# Access URLs
echo -e "${PURPLE}🌐 Access URLs:${NC}"
echo "   Frontend Dashboard: http://localhost:3000"
echo "   Backend API Health: http://localhost:8001/api/health"
echo "   Backend API Base:   http://localhost:8001/api"
echo ""

# Overall status
backend_ok=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/health | grep -q "200" && echo "true" || echo "false")
frontend_ok=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200" && echo "true" || echo "false")
craco_ok=$([[ -f "$INSTALL_DIR/frontend/node_modules/.bin/craco" ]] && echo "true" || echo "false")

echo -e "${BLUE}📊 OVERALL STATUS:${NC}"
if [[ "$backend_ok" == "true" && "$frontend_ok" == "true" && "$craco_ok" == "true" ]]; then
    echo -e "${GREEN}🎉 ✅ ALL SYSTEMS OPERATIONAL!${NC}"
    echo ""
    echo "Your CryptoMiner Pro is fully functional and ready to use!"
    echo "Access your mining dashboard at: http://localhost:3000"
elif [[ "$backend_ok" == "true" && "$craco_ok" == "false" ]]; then
    echo -e "${YELLOW}⚠️  CRACO DEPENDENCIES MISSING${NC}"
    echo ""
    echo "Backend is working, but frontend needs dependency fix."
    echo "Run: ./fix-frontend-dependencies.sh"
elif [[ "$backend_ok" == "false" ]]; then
    echo -e "${RED}❌ BACKEND ISSUES DETECTED${NC}"
    echo ""
    echo "Backend is not responding. Check supervisor logs:"
    echo "sudo supervisorctl tail cryptominer-backend stderr"
else
    echo -e "${YELLOW}⚠️  PARTIAL FUNCTIONALITY${NC}"
    echo ""
    echo "Some components need attention. See details above."
fi