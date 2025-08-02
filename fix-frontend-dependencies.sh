#!/bin/bash

# Fix Frontend Dependencies Script
# Installs missing Node.js dependencies including CRACO

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

INSTALL_DIR="$HOME/Cryptominer-pro"
FRONTEND_DIR="$INSTALL_DIR/frontend"

echo -e "${BLUE}🔧 CryptoMiner Pro - Frontend Dependencies Fix${NC}"
echo "=============================================="
echo ""

# Check if we're the right user
CURRENT_USER=$(whoami)
echo -e "👤 Running as user: ${YELLOW}$CURRENT_USER${NC}"

# Check if installation directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo -e "${RED}❌ Installation directory not found: $INSTALL_DIR${NC}"
    echo "   Please ensure CryptoMiner Pro is installed in your home directory."
    exit 1
fi

# Check if frontend directory exists
if [[ ! -d "$FRONTEND_DIR" ]]; then
    echo -e "${RED}❌ Frontend directory not found: $FRONTEND_DIR${NC}"
    exit 1
fi

echo -e "📂 Frontend directory: ${GREEN}$FRONTEND_DIR${NC}"
echo ""

cd "$FRONTEND_DIR"

# Check current state
echo "🔍 Checking current state..."

if [[ -f "package.json" ]]; then
    echo -e "   ✅ package.json exists"
else
    echo -e "   ${RED}❌ package.json missing${NC}"
    exit 1
fi

if [[ -d "node_modules" ]]; then
    echo -e "   ✅ node_modules directory exists"
    
    # Check if CRACO is installed
    if [[ -f "node_modules/.bin/craco" ]]; then
        echo -e "   ✅ CRACO binary exists"
    else
        echo -e "   ${RED}❌ CRACO binary missing${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  node_modules directory missing${NC}"
fi

echo ""

# Install/reinstall dependencies
echo -e "${BLUE}📦 Installing Frontend Dependencies...${NC}"

# Clean install to ensure all dependencies are properly installed
echo "🧹 Cleaning previous installation..."
rm -rf node_modules package-lock.json 2>/dev/null || true

echo "📦 Installing dependencies with npm..."
if npm install; then
    echo -e "${GREEN}✅ Dependencies installed successfully${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi

echo ""

# Verify installation
echo "🔍 Verifying installation..."

# Check key dependencies
KEY_DEPS=(
    "@craco/craco"
    "react"
    "react-dom"
    "react-scripts"
    "tailwindcss"
)

MISSING_DEPS=0

for dep in "${KEY_DEPS[@]}"; do
    if [[ -d "node_modules/$dep" ]]; then
        echo -e "   ✅ $dep"
    else
        echo -e "   ${RED}❌ $dep missing${NC}"
        ((MISSING_DEPS++))
    fi
done

# Check CRACO binary specifically
if [[ -f "node_modules/.bin/craco" ]]; then
    echo -e "   ✅ CRACO binary available"
else
    echo -e "   ${RED}❌ CRACO binary still missing${NC}"
    ((MISSING_DEPS++))
fi

echo ""

if [[ $MISSING_DEPS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All dependencies installed successfully!${NC}"
    
    # Test the start command
    echo ""
    echo "🧪 Testing frontend start command..."
    
    # Test in background with timeout
    timeout 15 npm start > /tmp/frontend-test.log 2>&1 &
    TEST_PID=$!
    
    sleep 8
    
    if kill -0 $TEST_PID 2>/dev/null; then
        echo -e "${GREEN}✅ Frontend starts successfully with CRACO${NC}"
        kill $TEST_PID 2>/dev/null || true
        
        # Wait for process to clean up
        sleep 2
        
        # Kill any remaining processes
        pkill -f "craco start" 2>/dev/null || true
        pkill -f "node.*3000" 2>/dev/null || true
    else
        echo -e "${RED}❌ Frontend still fails to start${NC}"
        echo "Error log:"
        cat /tmp/frontend-test.log | tail -5
        exit 1
    fi
    
    echo ""
    echo -e "${BLUE}🔄 Restarting Frontend Service...${NC}"
    
    # Restart the frontend service
    sudo supervisorctl restart cryptominer-frontend
    
    echo ""
    echo -e "${GREEN}✅ Frontend dependencies fix completed!${NC}"
    echo ""
    echo "📊 Service Status:"
    sudo supervisorctl status | grep cryptominer
    
    echo ""
    echo "🌐 You should now be able to access:"
    echo "   Frontend: http://localhost:3000"
    echo "   Backend:  http://localhost:8001/api/health"
    
else
    echo -e "${RED}❌ $MISSING_DEPS dependencies are still missing${NC}"
    echo ""
    echo "🔧 Try running this script again or manually install:"
    echo "   cd $FRONTEND_DIR"
    echo "   npm install --save @craco/craco"
    exit 1
fi