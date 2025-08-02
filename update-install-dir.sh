#!/bin/bash

# =============================================================================
# CryptoMiner Pro - Updated Installation Directory Fix
# Update all services to use /home/$USER/Cryptominer-pro
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
echo "  🏠 CryptoMiner Pro - Updated Installation Directory"
echo "==============================================================================="
echo -e "${NC}"

# New configuration
OLD_INSTALL_DIR="/opt/cryptominer-pro"
NEW_INSTALL_DIR="$HOME/Cryptominer-pro"
SERVICE_USER="$(whoami)"
OLD_LOG_DIR="/var/log/cryptominer"
NEW_LOG_DIR="$HOME/.local/log/cryptominer"

log_info "Updating CryptoMiner Pro to use user home directory..."
log_info "Old location: $OLD_INSTALL_DIR"
log_info "New location: $NEW_INSTALL_DIR"

# Stop any running services
log_info "Stopping existing services..."
sudo supervisorctl stop all 2>/dev/null || true

# Create new directories
log_info "Creating new directory structure..."
mkdir -p "$NEW_INSTALL_DIR"
mkdir -p "$NEW_LOG_DIR"

# Move files if they exist in old location
if [[ -d "$OLD_INSTALL_DIR" ]]; then
    log_info "Moving files from old location..."
    
    if [[ -d "$OLD_INSTALL_DIR/backend-nodejs" ]]; then
        cp -r "$OLD_INSTALL_DIR/backend-nodejs" "$NEW_INSTALL_DIR/" 2>/dev/null || true
        log "✅ Backend files copied"
    fi
    
    if [[ -d "$OLD_INSTALL_DIR/frontend" ]]; then
        cp -r "$OLD_INSTALL_DIR/frontend" "$NEW_INSTALL_DIR/" 2>/dev/null || true
        log "✅ Frontend files copied"
    fi
    
    if [[ -d "$OLD_INSTALL_DIR/data" ]]; then
        cp -r "$OLD_INSTALL_DIR/data" "$NEW_INSTALL_DIR/" 2>/dev/null || true
        log "✅ Data files copied"
    fi
else
    log_info "Old installation directory not found, checking current directory..."
    
    # Check if files are in current directory (/app)
    if [[ -d "/app/backend-nodejs" ]]; then
        log_info "Copying from /app directory..."
        cp -r /app/backend-nodejs "$NEW_INSTALL_DIR/"
        cp -r /app/frontend "$NEW_INSTALL_DIR/"
        log "✅ Files copied from /app"
    fi
fi

# Copy old logs if they exist
if [[ -d "$OLD_LOG_DIR" ]]; then
    log_info "Copying old logs..."
    sudo cp -r "$OLD_LOG_DIR"/* "$NEW_LOG_DIR/" 2>/dev/null || true
    log "✅ Logs copied"
fi

# Set proper ownership
chown -R "$SERVICE_USER:$SERVICE_USER" "$NEW_INSTALL_DIR"
chown -R "$SERVICE_USER:$SERVICE_USER" "$NEW_LOG_DIR"

# Update supervisor configurations
log_info "Updating supervisor configurations..."

# Backend supervisor config
sudo tee "/etc/supervisor/conf.d/cryptominer-backend.conf" > /dev/null << EOF
[program:cryptominer-backend]
command=/usr/bin/node server.js
directory=$NEW_INSTALL_DIR/backend-nodejs
user=$SERVICE_USER
autostart=true
autorestart=true
stdout_logfile=$NEW_LOG_DIR/backend.log
stderr_logfile=$NEW_LOG_DIR/backend-error.log
environment=NODE_ENV=production,PORT=8001
priority=999
killasgroup=true
stopasgroup=true
startsecs=10
startretries=3
EOF

# Frontend supervisor config
sudo tee "/etc/supervisor/conf.d/cryptominer-frontend.conf" > /dev/null << EOF
[program:cryptominer-frontend]
command=/usr/bin/npm start
directory=$NEW_INSTALL_DIR/frontend
user=$SERVICE_USER
autostart=true
autorestart=true
stdout_logfile=$NEW_LOG_DIR/frontend.log
stderr_logfile=$NEW_LOG_DIR/frontend-error.log
environment=NODE_ENV=production,PORT=3000
priority=998
killasgroup=true
stopasgroup=true
startsecs=10
startretries=3
stopwaitsecs=10
EOF

# Update environment files
if [[ -f "$NEW_INSTALL_DIR/backend-nodejs/.env" ]]; then
    log_info "Updating backend .env file..."
    sed -i "s|LOG_FILE=.*|LOG_FILE=$NEW_LOG_DIR/backend.log|g" "$NEW_INSTALL_DIR/backend-nodejs/.env"
fi

# Install dependencies if needed
if [[ -f "$NEW_INSTALL_DIR/backend-nodejs/package.json" ]]; then
    if [[ ! -d "$NEW_INSTALL_DIR/backend-nodejs/node_modules" ]]; then
        log_info "Installing backend dependencies..."
        cd "$NEW_INSTALL_DIR/backend-nodejs"
        npm install
    fi
fi

if [[ -f "$NEW_INSTALL_DIR/frontend/package.json" ]]; then
    if [[ ! -d "$NEW_INSTALL_DIR/frontend/node_modules" ]]; then
        log_info "Installing frontend dependencies..."
        cd "$NEW_INSTALL_DIR/frontend"
        npm install
    fi
fi

# Make server.js executable
chmod +x "$NEW_INSTALL_DIR/backend-nodejs/server.js" 2>/dev/null || true

# Reload supervisor
log_info "Reloading supervisor configuration..."
sudo supervisorctl reread
sudo supervisorctl update

# Start services
log_info "Starting services with new configuration..."
sudo supervisorctl start cryptominer-backend
sleep 5
sudo supervisorctl start cryptominer-frontend
sleep 5

# Check status
log_info "Checking service status..."
sudo supervisorctl status

# Test services
log_info "Testing services..."
if curl -f http://localhost:8001/api/health &>/dev/null; then
    log "✅ Backend API is responding!"
else
    log_error "❌ Backend API not responding"
fi

if curl -f http://localhost:3000 &>/dev/null; then
    log "✅ Frontend is responding!"
else
    log_error "❌ Frontend not responding"
fi

# Clean up old installation (optional)
if [[ -d "$OLD_INSTALL_DIR" ]]; then
    log_info "Old installation directory still exists at: $OLD_INSTALL_DIR"
    echo "Would you like to remove it? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo rm -rf "$OLD_INSTALL_DIR"
        log "✅ Old installation directory removed"
    fi
fi

if [[ -d "$OLD_LOG_DIR" ]]; then
    log_info "Old log directory still exists at: $OLD_LOG_DIR" 
    echo "Would you like to remove it? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo rm -rf "$OLD_LOG_DIR"
        log "✅ Old log directory removed"  
    fi
fi

echo -e "${GREEN}"
echo "==============================================================================="
echo "  ✅ Installation Directory Update Complete!"
echo "==============================================================================="
echo -e "${NC}"

log "🎉 CryptoMiner Pro is now running from your home directory!"

echo ""
log_info "New locations:"
echo "  📂 Application: $NEW_INSTALL_DIR"
echo "  📋 Logs: $NEW_LOG_DIR"
echo "  👤 User: $SERVICE_USER"
echo ""
log_info "Access your application:"
echo "  🌐 Web Dashboard: http://localhost/"
echo "  🔧 Backend API: http://localhost:8001/api/health"
echo "  📱 Frontend: http://localhost:3000"
echo ""
log_info "View logs:"
echo "  📋 Backend: tail -f $NEW_LOG_DIR/backend.log"
echo "  📋 Frontend: tail -f $NEW_LOG_DIR/frontend.log"
echo ""