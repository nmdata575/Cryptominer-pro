#!/bin/bash

# Frontend Setup Validation Script
# Checks if all required files are present for the React frontend

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

INSTALL_DIR="$HOME/Cryptominer-pro"

echo -e "${BLUE}🔍 CryptoMiner Pro - Frontend Setup Check${NC}"
echo "=========================================="
echo ""

if [[ ! -d "$INSTALL_DIR/frontend" ]]; then
    echo -e "${RED}❌ Frontend directory not found: $INSTALL_DIR/frontend${NC}"
    exit 1
fi

cd "$INSTALL_DIR/frontend"

echo "📂 Checking frontend directory: $INSTALL_DIR/frontend"
echo ""

# Essential files check
echo "📄 Essential Files Check:"

ESSENTIAL_FILES=(
    "package.json"
    "craco.config.js"
    "tailwind.config.js"
    "postcss.config.js"
    "src/index.js"
    "src/App.js"
    "public/index.html"
)

MISSING_FILES=0

for file in "${ESSENTIAL_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "  ✅ $file"
    else
        echo -e "  ❌ $file ${RED}(MISSING)${NC}"
        ((MISSING_FILES++))
    fi
done

echo ""

# Node modules check
echo "📦 Dependencies Check:"
if [[ -d "node_modules" ]]; then
    echo -e "  ✅ node_modules directory exists"
    
    # Check key dependencies
    KEY_DEPS=(
        "@craco/craco"
        "react"
        "react-dom"
        "react-scripts"
        "tailwindcss"
    )
    
    for dep in "${KEY_DEPS[@]}"; do
        if [[ -d "node_modules/$dep" ]]; then
            echo -e "  ✅ $dep"
        else
            echo -e "  ❌ $dep ${RED}(MISSING)${NC}"
            ((MISSING_FILES++))
        fi
    done
else
    echo -e "  ❌ node_modules ${RED}(MISSING)${NC}"
    echo -e "  ${YELLOW}Run: cd $INSTALL_DIR/frontend && npm install${NC}"
    ((MISSING_FILES++))
fi

echo ""

# Package.json validation
echo "📋 Package.json Scripts Check:"
if [[ -f "package.json" ]]; then
    if grep -q "craco start" package.json; then
        echo -e "  ✅ start script uses craco"
    else
        echo -e "  ❌ start script doesn't use craco ${RED}(ISSUE)${NC}"
        ((MISSING_FILES++))
    fi
    
    if grep -q "craco build" package.json; then
        echo -e "  ✅ build script uses craco"
    else
        echo -e "  ❌ build script doesn't use craco ${RED}(ISSUE)${NC}"
    fi
else
    echo -e "  ❌ package.json missing"
fi

echo ""

# Environment file check
echo "🌍 Environment Configuration:"
if [[ -f ".env" ]]; then
    echo -e "  ✅ .env file exists"
    if grep -q "REACT_APP_BACKEND_URL" .env; then
        backend_url=$(grep "REACT_APP_BACKEND_URL" .env | cut -d'=' -f2)
        echo -e "  ✅ REACT_APP_BACKEND_URL: $backend_url"
    else
        echo -e "  ❌ REACT_APP_BACKEND_URL missing in .env ${RED}(CRITICAL)${NC}"
        ((MISSING_FILES++))
    fi
else
    echo -e "  ❌ .env file missing ${RED}(CRITICAL)${NC}"
    echo -e "  ${YELLOW}This file should contain REACT_APP_BACKEND_URL${NC}"
    ((MISSING_FILES++))
fi

echo ""

# CRACO config validation
echo "⚙️  CRACO Configuration:"
if [[ -f "craco.config.js" ]]; then
    echo -e "  ✅ craco.config.js exists"
    
    if grep -q "crypto-browserify" craco.config.js; then
        echo -e "  ✅ crypto-browserify polyfill configured"
    else
        echo -e "  ⚠️  crypto-browserify polyfill not found ${YELLOW}(WARNING)${NC}"
    fi
    
    if grep -q "webpack.ProvidePlugin" craco.config.js; then
        echo -e "  ✅ webpack ProvidePlugin configured"
    else
        echo -e "  ⚠️  webpack ProvidePlugin not found ${YELLOW}(WARNING)${NC}"
    fi
else
    echo -e "  ❌ craco.config.js missing ${RED}(CRITICAL)${NC}"
    echo -e "  ${YELLOW}This file is required for the React app to start${NC}"
    ((MISSING_FILES++))
fi

echo ""

# Summary
echo "📊 Summary:"
if [[ $MISSING_FILES -eq 0 ]]; then
    echo -e "${GREEN}✅ All checks passed! Frontend should work correctly.${NC}"
    echo ""
    echo "🚀 To start the frontend:"
    echo "   cd $INSTALL_DIR/frontend"
    echo "   npm start"
    echo ""
    echo "Or use the management command:"
    echo "   cryptominer restart"
else
    echo -e "${RED}❌ $MISSING_FILES issues found that need to be fixed.${NC}"
    echo ""
    echo "🔧 To fix missing configuration files:"
    echo "   ./fix-frontend-config.sh"
    echo ""
    echo "📦 To install missing dependencies:"
    echo "   cd $INSTALL_DIR/frontend && npm install"
fi

echo ""
echo "📋 Frontend directory contents:"
ls -la "$INSTALL_DIR/frontend" | head -20