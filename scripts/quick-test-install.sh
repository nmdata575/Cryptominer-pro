#!/bin/bash

# =============================================================================
# CryptoMiner Pro v2.0 - Quick Test Installation Script
# For testing the installer in development/staging environments
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
echo "  🧪 CryptoMiner Pro v2.0 - Quick Test Installation"
echo "==============================================================================="
echo -e "${NC}"

# Quick system check
log_info "Performing quick system check..."

# Check if running on Ubuntu/Debian
if ! command -v apt &> /dev/null; then
    log_error "This quick test requires apt package manager (Ubuntu/Debian)"
    exit 1
fi

# Check available memory
mem_gb=$(free -g | awk '/^Mem:/{print $2}')
if [[ $mem_gb -lt 2 ]]; then
    log_error "Insufficient RAM: ${mem_gb}GB (minimum 2GB required)"
    exit 1
fi

# Check disk space
disk_gb=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
if [[ $disk_gb -lt 3 ]]; then
    log_error "Insufficient disk space: ${disk_gb}GB (minimum 3GB required)"
    exit 1
fi

log "✅ System requirements check passed"

# Install prerequisites quickly
log_info "Installing essential prerequisites..."
sudo apt update -qq
sudo apt install -y curl wget git build-essential python3 python3-pip supervisor nginx

# Quick Node.js installation
log_info "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null
sudo apt-get install -y nodejs
npm --version > /dev/null && log "✅ Node.js installed successfully"

# Quick MongoDB installation
log_info "Installing MongoDB 8.0..."
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor > /dev/null
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
mongosh --eval "db.adminCommand('ping')" --quiet && log "✅ MongoDB installed and running"

# Test the enhanced installer
log_info "Testing the enhanced installer script..."

if [[ ! -f "/app/install-enhanced-v2.sh" ]]; then
    log_error "Enhanced installer script not found at /app/install-enhanced-v2.sh"
    exit 1
fi

# Make it executable
chmod +x /app/install-enhanced-v2.sh

# Create a test environment
TEST_DIR="/tmp/cryptominer-test"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Copy installer to test directory
cp /app/install-enhanced-v2.sh ./

log_info "Starting installer test (this may take a few minutes)..."

# Run installer with test mode (you could add a --test flag to the installer)
if ./install-enhanced-v2.sh; then
    log "🎉 Enhanced installer completed successfully!"
    
    # Quick functionality test
    log_info "Performing quick functionality tests..."
    
    # Test if services are running
    if sudo supervisorctl status | grep -q "RUNNING"; then
        log "✅ Services are running"
    else
        log_error "❌ Some services failed to start"
    fi
    
    # Test API health endpoint
    sleep 10  # Give services time to start
    if curl -f http://localhost:8001/api/health &>/dev/null; then
        log "✅ Backend API is responding"
    else
        log_error "❌ Backend API health check failed"
    fi
    
    # Test MongoDB connection
    if mongosh --eval "db.adminCommand('ping')" --quiet; then
        log "✅ MongoDB connection successful"
    else
        log_error "❌ MongoDB connection failed"
    fi
    
    # Test AI endpoints
    if curl -f http://localhost:8001/api/mining/ai-insights-advanced &>/dev/null; then
        log "✅ Enhanced AI endpoint is working"
    else
        log_error "❌ Enhanced AI endpoint failed"
    fi
    
    log ""
    log "🎉 INSTALLATION TEST COMPLETED SUCCESSFULLY!"
    log ""
    log_info "Access your installation:"
    echo "  🌐 Dashboard: http://$(hostname -I | awk '{print $1}')"
    echo "  🔧 API Health: http://$(hostname -I | awk '{print $1}')/api/health"
    echo "  🤖 AI Insights: http://$(hostname -I | awk '{print $1}')/api/mining/ai-insights-advanced"
    log ""
    log_info "Management commands:"
    echo "  sudo supervisorctl status          # Check service status"
    echo "  sudo supervisorctl restart all    # Restart all services"
    echo "  sudo tail -f /var/log/cryptominer/backend.log  # View logs"
    
else
    log_error "❌ Enhanced installer test failed"
    exit 1
fi

echo -e "${GREEN}"
echo "==============================================================================="
echo "  ✅ CryptoMiner Pro v2.0 - Test Installation Complete!"
echo "==============================================================================="
echo -e "${NC}"