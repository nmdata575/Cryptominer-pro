#!/bin/bash

echo "🔍 CryptoMiner Pro - Pre-Installation Check"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}❌ ERROR: Running as root${NC}"
    echo "   Please run as a regular user, not as root"
    echo "   Current user: $(whoami)"
    exit 1
else
    echo -e "${GREEN}✅ User Check: Running as regular user ($(whoami))${NC}"
fi

# Check system requirements
echo ""
echo "🖥️  System Requirements:"

# RAM check
ram_gb=$(free -g | awk 'NR==2{printf "%.0f", $2}')
if [[ $ram_gb -ge 2 ]]; then
    echo -e "${GREEN}✅ RAM: ${ram_gb}GB (minimum 2GB required)${NC}"
else
    echo -e "${RED}❌ RAM: ${ram_gb}GB (minimum 2GB required)${NC}"
fi

# Disk space check  
disk_gb=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
if [[ $disk_gb -ge 5 ]]; then
    echo -e "${GREEN}✅ Disk Space: ${disk_gb}GB available (minimum 5GB required)${NC}"
else
    echo -e "${RED}❌ Disk Space: ${disk_gb}GB available (minimum 5GB required)${NC}"
fi

# CPU cores check
cores=$(nproc)
if [[ $cores -ge 2 ]]; then
    echo -e "${GREEN}✅ CPU Cores: $cores (minimum 2 required)${NC}"
else
    echo -e "${RED}❌ CPU Cores: $cores (minimum 2 required)${NC}"
fi

# Check for application files
echo ""
echo "📂 Application Files Check:"

locations=("/app" "$(pwd)" "$(dirname "$0")")
found=false

for location in "${locations[@]}"; do
    if [[ -d "$location/backend-nodejs" && -d "$location/frontend" ]]; then
        echo -e "${GREEN}✅ Found application files in: $location${NC}"
        found=true
        break
    fi
done

if [[ "$found" = false ]]; then
    echo -e "${RED}❌ Application files not found${NC}"
    echo "   Searched locations:"
    for location in "${locations[@]}"; do
        echo "   - $location"
    done
    echo ""
    echo "   Please ensure backend-nodejs/ and frontend/ directories are available."
fi

# Check internet connectivity
echo ""
echo "🌐 Network Check:"
if ping -c 1 google.com &> /dev/null; then
    echo -e "${GREEN}✅ Internet connectivity available${NC}"
else
    echo -e "${YELLOW}⚠️  Internet connectivity test failed${NC}"
    echo "   Installation requires internet to download dependencies"
fi

# Check if MongoDB is already installed
echo ""
echo "🗄️  MongoDB Check:"
if command -v mongod &> /dev/null; then
    mongo_version=$(mongod --version | head -1 | awk '{print $3}')
    echo -e "${GREEN}✅ MongoDB already installed: $mongo_version${NC}"
else
    echo -e "${YELLOW}ℹ️  MongoDB not found (will be installed)${NC}"
fi

# Check if Node.js is already installed
echo ""
echo "📦 Node.js Check:"
if command -v node &> /dev/null; then
    node_version=$(node --version)
    echo -e "${GREEN}✅ Node.js already installed: $node_version${NC}"
else
    echo -e "${YELLOW}ℹ️  Node.js not found (will be installed)${NC}"
fi

# Final recommendation
echo ""
echo "🎯 Pre-Installation Check Complete"
echo "=================================="

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}❌ CANNOT PROCEED: Please run as regular user${NC}"
    exit 1
elif [[ $ram_gb -lt 2 || $disk_gb -lt 5 || $cores -lt 2 ]]; then
    echo -e "${RED}❌ SYSTEM REQUIREMENTS NOT MET${NC}"
    echo "   Please ensure your system meets the minimum requirements"
    exit 1
elif [[ "$found" = false ]]; then
    echo -e "${RED}❌ APPLICATION FILES NOT FOUND${NC}"
    echo "   Please copy the CryptoMiner Pro files to an accessible location"
    exit 1
else
    echo -e "${GREEN}✅ ALL CHECKS PASSED - Ready for installation!${NC}"
    echo ""
    echo "To install CryptoMiner Pro, run:"
    echo "   ./install-enhanced-v2-fixed.sh"
    echo ""
    echo "The installation will:"
    echo "   📂 Install to: $HOME/Cryptominer-pro"
    echo "   📋 Logs in: $HOME/.local/log/cryptominer"
    echo "   🎮 Management: ~/.local/bin/cryptominer"
    echo "   🌐 Dashboard: http://localhost/"
fi