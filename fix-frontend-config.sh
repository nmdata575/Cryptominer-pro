#!/bin/bash

# Fix Frontend Configuration Files
# This script copies missing configuration files for existing installations

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CURRENT_USER=$(whoami)
INSTALL_DIR="$HOME/Cryptominer-pro"

echo -e "${BLUE}🔧 CryptoMiner Pro - Frontend Configuration Fix${NC}"
echo "=============================================="
echo ""

# Check if installation directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo -e "${RED}❌ Installation directory not found: $INSTALL_DIR${NC}"
    echo "   Please run the installation script first."
    exit 1
fi

# Check if frontend directory exists
if [[ ! -d "$INSTALL_DIR/frontend" ]]; then
    echo -e "${RED}❌ Frontend directory not found: $INSTALL_DIR/frontend${NC}"
    exit 1
fi

# Source location (where the original files are)
SOURCE_DIR=""

# Look for source files
if [[ -d "/app/frontend" ]]; then
    SOURCE_DIR="/app/frontend"
    echo -e "${GREEN}✅ Found source files in: $SOURCE_DIR${NC}"
elif [[ -d "/root/Cryptominer-pro/frontend" ]]; then
    SOURCE_DIR="/root/Cryptominer-pro/frontend"
    echo -e "${GREEN}✅ Found source files in: $SOURCE_DIR${NC}"
else
    echo -e "${RED}❌ Could not find source frontend directory${NC}"
    echo "   Searched in: /app/frontend, /root/Cryptominer-pro/frontend"
    exit 1
fi

echo ""
echo "🔧 Copying missing configuration files..."

# Configuration files that need to be copied
CONFIG_FILES=(
    "craco.config.js"
    "tailwind.config.js"
    "postcss.config.js"
    ".env"
)

COPIED=0
MISSING=0

for file in "${CONFIG_FILES[@]}"; do
    if [[ -f "$SOURCE_DIR/$file" ]]; then
        if [[ -f "$INSTALL_DIR/frontend/$file" ]]; then
            echo -e "${YELLOW}ℹ️  $file already exists${NC}"
        else
            cp "$SOURCE_DIR/$file" "$INSTALL_DIR/frontend/"
            echo -e "${GREEN}✅ Copied: $file${NC}"
            ((COPIED++))
        fi
    else
        echo -e "${RED}❌ Missing from source: $file${NC}"
        ((MISSING++))
    fi
done

echo ""
echo "📊 Summary:"
echo "   Files copied: $COPIED"
echo "   Files already present: $((${#CONFIG_FILES[@]} - COPIED - MISSING))"
echo "   Files missing from source: $MISSING"

# Fix file permissions
echo ""
echo "🔒 Setting proper permissions..."
chmod 644 "$INSTALL_DIR/frontend"/*.js "$INSTALL_DIR/frontend"/*.json 2>/dev/null || true

# Check if craco.config.js is now present
if [[ -f "$INSTALL_DIR/frontend/craco.config.js" ]]; then
    echo -e "${GREEN}✅ craco.config.js is now present${NC}"
    
    # Restart frontend service
    echo ""
    echo "🔄 Restarting frontend service..."
    if command -v supervisorctl &> /dev/null; then
        sudo supervisorctl restart cryptominer-frontend
        echo -e "${GREEN}✅ Frontend service restarted${NC}"
    else
        echo -e "${YELLOW}⚠️  Please restart the frontend service manually${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Frontend configuration fix completed!${NC}"
    echo ""
    echo "The frontend should now start properly with CRACO configuration."
    echo "You can check the status with: cryptominer status"
    
else
    echo -e "${RED}❌ craco.config.js is still missing${NC}"
    echo "   Please check the source directory and try again."
    exit 1
fi