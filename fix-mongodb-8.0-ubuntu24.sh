#!/bin/bash

# =============================================================================
# CryptoMiner Pro - MongoDB 8.0 Fix for Ubuntu 24.04
# Quick fix for MongoDB repository issues
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo -e "${BLUE}"
echo "==============================================================================="
echo "  🔧 CryptoMiner Pro - MongoDB 8.0 Fix for Ubuntu 24.04"
echo "==============================================================================="
echo -e "${NC}"

log_info "Fixing MongoDB repository issue for Ubuntu 24.04..."

# Remove old MongoDB 7.0 repositories
log_info "Removing old MongoDB 7.0 repositories..."
sudo rm -f /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo rm -f /usr/share/keyrings/mongodb-server-7.0.gpg

# Clean package cache
sudo apt-get clean
sudo apt-get update -qq

# Install MongoDB 8.0 for Ubuntu 24.04
log_info "Installing MongoDB 8.0 for Ubuntu 24.04..."

# Import MongoDB 8.0 GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor

# For Ubuntu 24.04 (noble), we'll use jammy repository as fallback since noble might not be available yet
UBUNTU_CODENAME=$(lsb_release -cs)
if [[ "$UBUNTU_CODENAME" == "noble" ]]; then
    log_info "Using jammy repository for Ubuntu 24.04 compatibility..."
    REPO_CODENAME="jammy"
else
    REPO_CODENAME="$UBUNTU_CODENAME"
fi

# Add MongoDB 8.0 repository
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${REPO_CODENAME}/mongodb-org/8.0 multiverse" | \
    sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

# Update package list
log_info "Updating package lists..."
sudo apt-get update

# Install MongoDB 8.0
log_info "Installing MongoDB 8.0..."
sudo apt-get install -y mongodb-org

# Pin MongoDB version
log_info "Pinning MongoDB 8.0 version..."
echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-database hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-mongosh hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections

# Start and enable MongoDB
log_info "Starting MongoDB service..."
sudo systemctl start mongod
sudo systemctl enable mongod

# Create data directory
sudo mkdir -p /data/db
sudo chown mongodb:mongodb /data/db

# Test MongoDB installation
log_info "Testing MongoDB installation..."
sleep 3
if mongosh --eval "db.adminCommand('ping')" --quiet; then
    log "✅ MongoDB 8.0 installed and running successfully!"
    
    # Show MongoDB version
    MONGO_VERSION=$(mongosh --eval "db.version()" --quiet)
    log "📦 MongoDB Version: $MONGO_VERSION"
else
    log_error "❌ MongoDB installation test failed"
    exit 1
fi

# Clean up
log_info "Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get clean

echo -e "${GREEN}"
echo "==============================================================================="
echo "  ✅ MongoDB 8.0 Fix Completed Successfully!"
echo "==============================================================================="
echo -e "${NC}"

log "🎉 MongoDB 8.0 is now ready for CryptoMiner Pro!"
log "📝 You can now continue with the CryptoMiner Pro installation"

echo ""
log_info "Next steps:"
echo "  1. Run the updated CryptoMiner Pro installer"
echo "  2. Or continue with manual installation if preferred"
echo "  3. MongoDB 8.0 is now properly configured for Ubuntu 24.04"
echo ""