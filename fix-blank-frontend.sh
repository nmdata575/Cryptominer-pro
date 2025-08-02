#!/bin/bash

# Fix Blank Frontend Page
# Comprehensive solution for React app not loading

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

INSTALL_DIR="$HOME/Cryptominer-pro"
FRONTEND_DIR="$INSTALL_DIR/frontend"

echo -e "${BLUE}🔧 CryptoMiner Pro - Fix Blank Frontend Page${NC}"
echo "============================================="
echo ""

# Check if running as correct user
CURRENT_USER=$(whoami)
if [[ "$CURRENT_USER" != "chris" ]]; then
    echo -e "${RED}❌ Please run this script as user 'chris'${NC}"
    echo "   Current user: $CURRENT_USER"
    exit 1
fi

echo -e "👤 Running as user: ${GREEN}$CURRENT_USER${NC}"
echo ""

# Step 1: Stop conflicting services
echo -e "${BLUE}🛑 Step 1: Cleaning up processes${NC}"
sudo supervisorctl stop cryptominer-frontend 2>/dev/null || echo "Frontend service not running"

# Kill any processes using port 3000
if netstat -tulnp 2>/dev/null | grep ":3000" > /dev/null; then
    echo "🔄 Killing processes on port 3000..."
    sudo lsof -ti:3000 | xargs -r sudo kill -9
    sleep 3
fi

# Kill any CRACO processes
sudo pkill -f "craco start" 2>/dev/null || echo "No CRACO processes to kill"
sudo pkill -f "node.*3000" 2>/dev/null || echo "No Node processes on port 3000"

echo "✅ Port 3000 cleared"
echo ""

# Step 2: Check and fix the React app
echo -e "${BLUE}📋 Step 2: Checking React app files${NC}"

if [[ ! -d "$FRONTEND_DIR" ]]; then
    echo -e "${RED}❌ Frontend directory not found: $FRONTEND_DIR${NC}"
    exit 1
fi

cd "$FRONTEND_DIR"

# Check key React files
if [[ -f "src/index.js" ]]; then
    echo "✅ src/index.js exists"
else
    echo -e "${RED}❌ src/index.js missing${NC}"
fi

if [[ -f "src/App.js" ]]; then
    echo "✅ src/App.js exists"
else
    echo -e "${RED}❌ src/App.js missing${NC}"
fi

if [[ -f "public/index.html" ]]; then
    echo "✅ public/index.html exists"
else
    echo -e "${RED}❌ public/index.html missing${NC}"
fi

echo ""

# Step 3: Check for JavaScript errors in the React app
echo -e "${BLUE}🔍 Step 3: Testing React app compilation${NC}"

# Test compilation without starting server
echo "Testing React compilation..."
if npm run build > /tmp/react-build.log 2>&1; then
    echo "✅ React app compiles successfully"
    
    # Check if build directory was created
    if [[ -d "build" && -f "build/index.html" ]]; then
        echo "✅ Build files generated correctly"
    else
        echo -e "${YELLOW}⚠️ Build directory created but may be incomplete${NC}"
    fi
else
    echo -e "${RED}❌ React compilation failed${NC}"
    echo "Build error log:"
    cat /tmp/react-build.log | tail -10
    echo ""
    echo "🔧 Trying to fix compilation issues..."
    
    # Try to fix common React compilation issues
    echo "Clearing React build cache..."
    rm -rf build node_modules/.cache 2>/dev/null || true
    
    echo "Reinstalling dependencies..."
    npm install
    
    # Try build again
    if npm run build > /tmp/react-build-retry.log 2>&1; then
        echo "✅ React app compiles after fixing"
    else
        echo -e "${RED}❌ React compilation still failing${NC}"
        echo "Retry build error:"
        cat /tmp/react-build-retry.log | tail -10
    fi
fi

echo ""

# Step 4: Check environment configuration
echo -e "${BLUE}⚙️ Step 4: Checking environment configuration${NC}"

if [[ -f ".env" ]]; then
    echo "✅ .env file exists"
    
    # Check backend URL configuration
    if grep -q "REACT_APP_BACKEND_URL" .env; then
        backend_url=$(grep "REACT_APP_BACKEND_URL" .env | cut -d'=' -f2)
        echo "✅ Backend URL configured: $backend_url"
        
        # Test if backend is accessible
        if curl -s -o /dev/null -w "%{http_code}" "$backend_url/api/health" | grep -q "200"; then
            echo "✅ Backend is accessible from frontend"
        else
            echo -e "${YELLOW}⚠️ Backend may not be accessible: $backend_url/api/health${NC}"
            
            # Try localhost backend
            if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8001/api/health" | grep -q "200"; then
                echo "✅ Local backend is working, updating .env..."
                
                # Update .env to use localhost
                sed -i 's|REACT_APP_BACKEND_URL=.*|REACT_APP_BACKEND_URL=http://localhost:8001|' .env
                echo "✅ Updated backend URL to http://localhost:8001"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️ REACT_APP_BACKEND_URL not found in .env${NC}"
        echo "REACT_APP_BACKEND_URL=http://localhost:8001" >> .env
        echo "✅ Added backend URL to .env"
    fi
else
    echo -e "${YELLOW}⚠️ .env file missing, creating...${NC}"
    cat > .env << EOF
REACT_APP_BACKEND_URL=http://localhost:8001
GENERATE_SOURCEMAP=false
SKIP_PREFLIGHT_CHECK=true
EOF
    echo "✅ Created .env file"
fi

echo ""

# Step 5: Create/verify basic React app structure
echo -e "${BLUE}🏗️ Step 5: Verifying React app structure${NC}"

# Check if src/index.js has proper React mounting
if [[ -f "src/index.js" ]]; then
    if grep -q "ReactDOM.*render\|createRoot" src/index.js; then
        echo "✅ React mounting code found in src/index.js"
    else
        echo -e "${YELLOW}⚠️ React mounting code may be missing${NC}"
        echo "Checking src/index.js content..."
        head -10 src/index.js
    fi
fi

# Check if src/App.js exports a component
if [[ -f "src/App.js" ]]; then
    if grep -q "export.*App\|export default" src/App.js; then
        echo "✅ App component export found in src/App.js"
    else
        echo -e "${YELLOW}⚠️ App component export may be missing${NC}"
    fi
fi

echo ""

# Step 6: Start frontend in development mode with better error handling
echo -e "${BLUE}🚀 Step 6: Starting frontend service${NC}"

# Set environment variables to avoid conflicts
export NODE_ENV=development
export PORT=3000
export GENERATE_SOURCEMAP=false

# Clear any existing build artifacts
rm -rf build 2>/dev/null || true

echo "Starting frontend with supervisor..."
sudo supervisorctl start cryptominer-frontend

echo "Waiting for frontend to initialize..."
sleep 15

# Check if frontend is responding
frontend_status="unknown"
for i in {1..10}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
        frontend_status="working"
        break
    fi
    sleep 2
    echo "  Attempt $i/10: Waiting for frontend..."
done

if [[ "$frontend_status" == "working" ]]; then
    echo -e "${GREEN}✅ Frontend is now responding!${NC}"
    
    # Check if it's actually showing content (not blank)
    frontend_content=$(curl -s http://localhost:3000 2>/dev/null || echo "")
    if echo "$frontend_content" | grep -q "<div id=\"root\""; then
        echo "✅ React app root element found"
        
        if echo "$frontend_content" | grep -q -i "cryptominer\|mining\|dashboard"; then
            echo "✅ CryptoMiner content detected"
        else
            echo -e "${YELLOW}⚠️ Page may still be loading or blank${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ React root element not found - may still be blank${NC}"
    fi
else
    echo -e "${RED}❌ Frontend still not responding${NC}"
    echo ""
    echo "📋 Checking frontend logs for errors..."
    sudo supervisorctl tail cryptominer-frontend stderr | tail -10
fi

echo ""

# Final status
echo -e "${BLUE}📊 Final Status${NC}"
echo "Service status:"
sudo supervisorctl status cryptominer-frontend

echo ""
echo "Port check:"
if netstat -tulnp 2>/dev/null | grep ":3000" > /dev/null; then
    echo "✅ Port 3000 is in use"
else
    echo "❌ Port 3000 is not in use"
fi

echo ""
echo -e "${GREEN}🎯 Next Steps:${NC}"
echo "1. Open http://localhost:3000 in your browser"
echo "2. Press F12 to open browser developer tools"
echo "3. Check the Console tab for JavaScript errors"
echo "4. Check the Network tab to see if API calls are failing"
echo ""
echo "If the page is still blank:"
echo "- Look for JavaScript errors in browser console"
echo "- Refresh the page (Ctrl+F5 or Cmd+Shift+R)"
echo "- Check that backend is running: curl http://localhost:8001/api/health"