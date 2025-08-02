#!/bin/bash

# =============================================================================
# CryptoMiner Pro - Nginx Quick Fix
# Start Nginx service and configure properly
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
echo "  🌐 CryptoMiner Pro - Nginx Quick Fix"
echo "==============================================================================="
echo -e "${NC}"

log_info "Fixing Nginx service..."

# Check nginx status
log_info "Current Nginx status:"
sudo systemctl status nginx --no-pager -l || true

# Start Nginx service
log_info "Starting Nginx service..."
sudo systemctl start nginx

# Enable Nginx to start on boot
log_info "Enabling Nginx service..."
sudo systemctl enable nginx

# Wait a moment for service to fully start
sleep 2

# Check if Nginx is now running
if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx is now running successfully!"
    
    # Test configuration
    log_info "Testing Nginx configuration..."
    if sudo nginx -t; then
        log "✅ Nginx configuration is valid!"
        
        # Reload configuration
        log_info "Reloading Nginx configuration..."
        sudo systemctl reload nginx
        log "✅ Nginx configuration reloaded!"
    else
        log_error "❌ Nginx configuration has errors"
        exit 1
    fi
else
    log_error "❌ Failed to start Nginx"
    sudo systemctl status nginx --no-pager -l
    exit 1
fi

# Show Nginx status
log_info "Final Nginx status:"
sudo systemctl status nginx --no-pager -l

# Test web server
log_info "Testing web server..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301\|302"; then
    log "✅ Nginx web server is responding!"
else
    log_info "Nginx is running but default page might not be configured yet (this is normal)"
fi

echo -e "${GREEN}"
echo "==============================================================================="
echo "  ✅ Nginx Fix Completed Successfully!"
echo "==============================================================================="
echo -e "${NC}"

log "🎉 Nginx is now ready for CryptoMiner Pro!"
log "📝 You can now continue with the installation"

echo ""