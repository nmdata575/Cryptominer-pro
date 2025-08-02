#!/bin/bash

# =============================================================================
# CryptoMiner Pro - Quick Service Fix
# Copy project files and start services properly
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
echo "  🚀 CryptoMiner Pro - Quick Service Fix"
echo "==============================================================================="
echo -e "${NC}"

# Configuration
INSTALL_DIR="/home/$(whoami)/Cryptominer-pro"
SERVICE_USER="$(whoami)"
LOG_DIR="$HOME/.local/log/cryptominer"
SOURCE_DIR="/app"

log_info "Fixing CryptoMiner Pro service startup issues..."

# Stop any running services
log_info "Stopping existing services..."
sudo supervisorctl stop all 2>/dev/null || true

# Create installation directory if it doesn't exist
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_info "Creating installation directory..."
    sudo mkdir -p "$INSTALL_DIR"
fi

# Create service user if it doesn't exist
if ! id "$SERVICE_USER" &>/dev/null; then
    log_info "Current user will be used for services: $SERVICE_USER"
else
    log_info "Using current user for services: $SERVICE_USER"
fi

# Create log directory
mkdir -p "$LOG_DIR"

# Copy backend files
log_info "Copying backend files from $SOURCE_DIR/backend-nodejs to $INSTALL_DIR/backend-nodejs..."
sudo rm -rf "$INSTALL_DIR/backend-nodejs"
sudo cp -r "$SOURCE_DIR/backend-nodejs" "$INSTALL_DIR/"

# Copy frontend files
log_info "Copying frontend files from $SOURCE_DIR/frontend to $INSTALL_DIR/frontend..."
sudo rm -rf "$INSTALL_DIR/frontend"
sudo cp -r "$SOURCE_DIR/frontend" "$INSTALL_DIR/"

# Set proper ownership
log_info "Setting proper file ownership..."
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$LOG_DIR"

# Make server.js executable
sudo chmod +x "$INSTALL_DIR/backend-nodejs/server.js"

# Verify files exist
log_info "Verifying critical files..."
if [[ -f "$INSTALL_DIR/backend-nodejs/server.js" ]]; then
    log "✅ Backend server.js found"
else
    log_error "❌ Backend server.js still missing!"
    exit 1
fi

if [[ -f "$INSTALL_DIR/frontend/package.json" ]]; then
    log "✅ Frontend package.json found"
else
    log_error "❌ Frontend package.json missing!"
    exit 1
fi

# Install backend dependencies if needed
if [[ ! -d "$INSTALL_DIR/backend-nodejs/node_modules" ]]; then
    log_info "Installing backend dependencies..."
    cd "$INSTALL_DIR/backend-nodejs"
    sudo -u "$SERVICE_USER" npm install
fi

# Install frontend dependencies if needed
if [[ ! -d "$INSTALL_DIR/frontend/node_modules" ]]; then
    log_info "Installing frontend dependencies..."
    cd "$INSTALL_DIR/frontend"
    sudo -u "$SERVICE_USER" npm install
fi

# Create or update backend supervisor config
log_info "Creating backend supervisor configuration..."
sudo tee "/etc/supervisor/conf.d/cryptominer-backend.conf" > /dev/null << EOF
[program:cryptominer-backend]
command=/usr/bin/node server.js
directory=$INSTALL_DIR/backend-nodejs
user=$SERVICE_USER
autostart=true
autorestart=true
stdout_logfile=$LOG_DIR/backend.log
stderr_logfile=$LOG_DIR/backend-error.log
environment=NODE_ENV=production,PORT=8001
priority=999
killasgroup=true
stopasgroup=true
startsecs=10
startretries=3
EOF

# Create or update frontend supervisor config
log_info "Creating frontend supervisor configuration..."
sudo tee "/etc/supervisor/conf.d/cryptominer-frontend.conf" > /dev/null << EOF
[program:cryptominer-frontend]
command=/usr/bin/npm start
directory=$INSTALL_DIR/frontend
user=$SERVICE_USER
autostart=true
autorestart=true
stdout_logfile=$LOG_DIR/frontend.log
stderr_logfile=$LOG_DIR/frontend-error.log
environment=NODE_ENV=production,PORT=3000
priority=998
killasgroup=true
stopasgroup=true
startsecs=10
startretries=3
stopwaitsecs=10
EOF

# Reload supervisor configuration
log_info "Reloading supervisor configuration..."
sudo supervisorctl reread
sudo supervisorctl update

# Test backend manually first
log_info "Testing backend manually..."
cd "$INSTALL_DIR/backend-nodejs"
if sudo -u "$SERVICE_USER" timeout 5 node server.js &>/dev/null; then
    log "✅ Backend can start manually"
else
    log_warning "Backend test had issues, but continuing..."
fi

# Start services
log_info "Starting backend service..."
sudo supervisorctl start cryptominer-backend
sleep 5

# Check backend status  
if sudo supervisorctl status cryptominer-backend | grep -q "RUNNING"; then
    log "✅ Backend service is running!"
else
    log_error "❌ Backend service failed to start"
    log_info "Backend error logs:"
    sudo tail -n 10 "$LOG_DIR/backend-error.log" 2>/dev/null || echo "No error logs yet"
fi

log_info "Starting frontend service..."
sudo supervisorctl start cryptominer-frontend
sleep 10

# Check frontend status
if sudo supervisorctl status cryptominer-frontend | grep -q "RUNNING"; then
    log "✅ Frontend service is running!"
else
    log_error "❌ Frontend service failed to start"
    log_info "Frontend error logs:"
    sudo tail -n 10 "$LOG_DIR/frontend-error.log" 2>/dev/null || echo "No error logs yet"
fi

# Final status
log_info "Final service status:"
sudo supervisorctl status

# Test API endpoints
log_info "Testing API endpoints..."
sleep 5

if curl -f http://localhost:8001/api/health &>/dev/null; then
    log "✅ Backend API is responding!"
else
    log_warning "Backend API not responding yet"
fi

if curl -f http://localhost:3000 &>/dev/null; then
    log "✅ Frontend is responding!"
else
    log_warning "Frontend not responding yet"
fi

echo -e "${GREEN}"
echo "==============================================================================="
echo "  ✅ Service Fix Completed!"
echo "==============================================================================="
echo -e "${NC}"

log "🎉 CryptoMiner Pro services should now be running!"

echo ""
log_info "Access your application:"
echo "  🌐 Web Dashboard: http://localhost/"
echo "  🔧 Backend API: http://localhost:8001/api/health"
echo "  📱 Frontend: http://localhost:3000"
echo ""
log_info "Monitor services:"
echo "  📊 Status: sudo supervisorctl status"
echo "  📋 Backend logs: sudo tail -f $LOG_DIR/backend.log"
echo "  📋 Frontend logs: sudo tail -f $LOG_DIR/frontend.log"
echo ""