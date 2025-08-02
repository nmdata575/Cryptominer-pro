#!/bin/bash

# =============================================================================
# CryptoMiner Pro - Supervisor Fix for Ubuntu 24.04
# Quick fix for Supervisor Python dependency issues
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
echo "  🔧 CryptoMiner Pro - Supervisor Fix for Ubuntu 24.04"
echo "==============================================================================="
echo -e "${NC}"

log_info "Fixing Supervisor installation issue..."

# Stop any running supervisor processes
log_info "Stopping existing supervisor processes..."
sudo pkill supervisord 2>/dev/null || true
sudo systemctl stop supervisor 2>/dev/null || true

# Remove broken supervisor installation
log_info "Removing broken supervisor installation..."
sudo apt-get remove -y supervisor 2>/dev/null || true
sudo apt-get purge -y supervisor 2>/dev/null || true

# Clean up supervisor files
sudo rm -rf /etc/supervisor
sudo rm -rf /var/log/supervisor
sudo rm -f /etc/systemd/system/supervisor.service
sudo rm -f /usr/lib/systemd/system/supervisor.service

# Update system
log_info "Updating system packages..."
sudo apt-get update

# Install Python dependencies for supervisor
log_info "Installing Python dependencies..."
sudo apt-get install -y python3-pip python3-setuptools python3-wheel python3-dev

# Install supervisor via pip (more reliable on Ubuntu 24.04)
log_info "Installing supervisor via pip..."
sudo pip3 install supervisor

# Create supervisor directories
log_info "Creating supervisor directories..."
sudo mkdir -p /etc/supervisor/conf.d
sudo mkdir -p /var/log/supervisor

# Create supervisor configuration file
log_info "Creating supervisor configuration..."
sudo tee /etc/supervisor/supervisord.conf > /dev/null << 'EOF'
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor
user=root

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf
EOF

# Create systemd service for supervisor
log_info "Creating systemd service..."
sudo tee /etc/systemd/system/supervisor.service > /dev/null << 'EOF'
[Unit]
Description=Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target

[Service]
ExecStart=/usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf
ExecStop=/usr/local/bin/supervisorctl $OPTIONS shutdown
ExecReload=/usr/local/bin/supervisorctl -c /etc/supervisor/supervisord.conf $OPTIONS reload
KillMode=process
Restart=on-failure
RestartSec=50s

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start supervisor
log_info "Starting supervisor service..."
sudo systemctl daemon-reload
sudo systemctl enable supervisor
sudo systemctl start supervisor

# Test supervisor installation
log_info "Testing supervisor installation..."
sleep 3

if sudo systemctl is-active --quiet supervisor; then
    log "✅ Supervisor installed and running successfully!"
    
    # Test supervisorctl commands
    if sudo supervisorctl status >/dev/null 2>&1; then
        log "✅ Supervisorctl commands working correctly!"
    else
        log_error "❌ Supervisorctl commands not working"
    fi
else
    log_error "❌ Supervisor service failed to start"
    sudo systemctl status supervisor --no-pager -l
    exit 1
fi

# Create symbolic link for easier access
sudo ln -sf /usr/local/bin/supervisorctl /usr/bin/supervisorctl 2>/dev/null || true
sudo ln -sf /usr/local/bin/supervisord /usr/bin/supervisord 2>/dev/null || true

echo -e "${GREEN}"
echo "==============================================================================="
echo "  ✅ Supervisor Fix Completed Successfully!"
echo "==============================================================================="
echo -e "${NC}"

log "🎉 Supervisor is now ready for CryptoMiner Pro!"
log "📝 You can now continue with the CryptoMiner Pro installation"

echo ""
log_info "Supervisor status:"
sudo supervisorctl status
echo ""
log_info "Next steps:"
echo "  1. Continue with the CryptoMiner Pro installation"
echo "  2. The installer will now be able to configure supervisor properly"
echo ""