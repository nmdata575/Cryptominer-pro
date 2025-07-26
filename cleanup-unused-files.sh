#!/bin/bash

# CryptoMiner Pro - Cleanup Unused Files
# This script removes unused files after Node.js conversion

set -e

echo "🧹 CryptoMiner Pro - Cleanup Unused Files"
echo "========================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[REMOVED]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_info "Starting cleanup of unused files after Node.js conversion..."

# Track cleanup statistics
files_removed=0
dirs_removed=0
space_saved=0

# Function to remove file if it exists
remove_file() {
    if [ -f "$1" ]; then
        size=$(stat -c%s "$1" 2>/dev/null || echo "0")
        rm -f "$1"
        print_status "File: $1"
        files_removed=$((files_removed + 1))
        space_saved=$((space_saved + size))
    fi
}

# Function to remove directory if it exists
remove_dir() {
    if [ -d "$1" ]; then
        size=$(du -sb "$1" 2>/dev/null | cut -f1 || echo "0")
        rm -rf "$1"
        print_status "Directory: $1"
        dirs_removed=$((dirs_removed + 1))
        space_saved=$((space_saved + size))
    fi
}

echo ""
echo "🗑️  Removing Python Backend Files..."
echo "-----------------------------------"

# Remove entire Python backend directory
remove_dir "/app/backend"

# Remove Python-related files
remove_file "/app/backend_test.py"
remove_file "/app/working_backend_test.py"
remove_file "/app/custom_features_test.py"
remove_file "/app/detailed_installation_test.py"
remove_file "/app/nodejs_backend_test.py"
remove_file "/app/installation_test.py"
remove_file "/app/final_backend_test.py"
remove_file "/app/quick_backend_test.py"
remove_file "/app/remote_connectivity_test.py"
remove_file "/app/mining_test.py"
remove_file "/app/demo_verification.py"
remove_file "/app/verify_components.py"

echo ""
echo "🗑️  Removing Python Installation Scripts..."
echo "-------------------------------------------"

# Remove Python-specific installation scripts
remove_file "/app/install-python313.sh"
remove_file "/app/install-bulletproof.sh"
remove_file "/app/python-functions.sh"
remove_file "/app/fix-python-env.sh"
remove_file "/app/detect-python-env.sh"
remove_file "/app/check-python.sh"
remove_file "/app/fix-script.sh"
remove_file "/app/validate-script.sh"
remove_file "/app/check_components.sh"
remove_file "/app/test-install.sh"

echo ""
echo "🗑️  Removing Duplicate Installation Scripts..."
echo "---------------------------------------------"

# Keep only the working installation scripts
# Remove duplicates and old versions
remove_file "/app/install-ubuntu.sh"  # Keep install-container.sh and install-nodejs.sh
remove_file "/app/install-nodejs-simple.sh"  # Keep install-container.sh
remove_file "/app/uninstall-ubuntu.sh"  # Not needed for Node.js version

echo ""
echo "🗑️  Removing Obsolete Documentation..."
echo "-------------------------------------"

# Remove Python-specific documentation
remove_file "/app/COMPONENT_VERIFICATION.md"
remove_file "/app/INSTALL_GUIDE.md"
remove_file "/app/SETUP_GUIDE.md"

echo ""
echo "🗑️  Removing Temporary and Test Files..."
echo "---------------------------------------"

# Remove temporary files
remove_file "/app/start.sh"  # Old startup script, replaced by /opt/cryptominer-pro/start.sh

echo ""
echo "🗑️  Optimizing Installation Directory..."
echo "--------------------------------------"

# Clean up the installation directory
if [ -d "/opt/cryptominer-pro" ]; then
    # Remove old Python backend if it exists in installation
    remove_dir "/opt/cryptominer-pro/backend"
    
    # Remove duplicate documentation
    remove_file "/opt/cryptominer-pro/SETUP_GUIDE.md"
    remove_file "/opt/cryptominer-pro/INSTALL_GUIDE.md"
    
    print_info "Installation directory optimized"
fi

echo ""
echo "🗑️  Cleaning Node.js Dependencies..."
echo "-----------------------------------"

# Clean npm caches and unnecessary files
if [ -d "/app/backend-nodejs/node_modules" ]; then
    cd /app/backend-nodejs
    npm prune --production 2>/dev/null || true
    print_info "Backend Node.js dependencies optimized"
fi

if [ -d "/app/frontend/node_modules" ]; then
    cd /app/frontend
    npm prune --production 2>/dev/null || true
    print_info "Frontend Node.js dependencies optimized"
fi

# Clean npm cache
npm cache clean --force 2>/dev/null || true

echo ""
echo "🗑️  Final Cleanup..."
echo "------------------"

# Remove any remaining Python cache files
find /app -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find /app -name "*.pyc" -type f -delete 2>/dev/null || true

# Remove any temporary files
find /app -name "*.tmp" -type f -delete 2>/dev/null || true
find /app -name "*.log" -type f -delete 2>/dev/null || true

# Remove any backup files
find /app -name "*~" -type f -delete 2>/dev/null || true
find /app -name "*.bak" -type f -delete 2>/dev/null || true

print_info "Temporary files cleaned"

echo ""
echo "📊 Cleanup Summary"
echo "=================="
echo "Files removed: $files_removed"
echo "Directories removed: $dirs_removed"
echo "Space saved: $(($space_saved / 1024 / 1024)) MB"

echo ""
echo "✅ Remaining Core Files:"
echo "----------------------"
echo "📁 /app/backend-nodejs/          - Node.js backend"
echo "📁 /app/frontend/                - React frontend"
echo "📄 /app/README.md                - Main documentation"
echo "📄 /app/QUICK_REFERENCE.md       - Quick reference"
echo "📄 /app/REMOTE_API_GUIDE.md      - Remote API guide"
echo "📄 /app/CUSTOM_COINS_GUIDE.md    - Custom coins guide"
echo "📄 /app/MANUAL_INSTALL.md        - Manual installation"
echo "📄 /app/test_result.md           - Test results"
echo "🔧 /app/install-nodejs.sh        - Node.js installation"
echo "🔧 /app/install-container.sh     - Container installation"
echo "🔧 /app/cleanup-unused-files.sh  - This cleanup script"

echo ""
echo "✅ Installation Directory:"
echo "------------------------"
echo "📁 /opt/cryptominer-pro/backend-nodejs/  - Running backend"
echo "📁 /opt/cryptominer-pro/frontend/        - Running frontend"
echo "📄 /opt/cryptominer-pro/REMOTE_API_GUIDE.md"
echo "📄 /opt/cryptominer-pro/CUSTOM_COINS_GUIDE.md"
echo "📄 /opt/cryptominer-pro/MANUAL_INSTALL.md"
echo "🔧 /opt/cryptominer-pro/start.sh         - Startup script"
echo "🔧 /opt/cryptominer-pro/stop.sh          - Stop script"
echo "🔧 /opt/cryptominer-pro/test.sh          - Test script"

echo ""
echo "🎉 Cleanup Complete!"
echo "==================="
print_info "CryptoMiner Pro has been streamlined and optimized"
print_info "All Python dependencies removed"
print_info "Only Node.js components remain"
print_info "System is now cleaner and more efficient"

echo ""
echo "🚀 Next Steps:"
echo "- Application is running from /opt/cryptominer-pro/"
echo "- Access dashboard at: http://localhost:3000"
echo "- Use /opt/cryptominer-pro/start.sh to start services"
echo "- Check /opt/cryptominer-pro/test.sh for testing"

echo ""
print_info "Happy mining with your streamlined CryptoMiner Pro! 🚀"