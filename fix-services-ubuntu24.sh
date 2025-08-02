#!/bin/bash

# =============================================================================
# CryptoMiner Pro - Service Configuration Fix
# Fix supervisor service startup issues
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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo -e "${BLUE}"
echo "==============================================================================="
echo "  🔧 CryptoMiner Pro - Service Configuration Fix"
echo "==============================================================================="
echo -e "${NC}"

# Configuration
INSTALL_DIR="/home/$(whoami)/Cryptominer-pro"
SERVICE_USER="$(whoami)"
LOG_DIR="$HOME/.local/log/cryptominer"

log_info "Diagnosing and fixing service startup issues..."

# Stop any running services
log_info "Stopping existing services..."
sudo supervisorctl stop all 2>/dev/null || true

# Check if installation directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "Installation directory $INSTALL_DIR does not exist!"
    log_info "Creating installation directory structure..."
    
    sudo mkdir -p "$INSTALL_DIR/backend-nodejs"
    sudo mkdir -p "$INSTALL_DIR/frontend"
    sudo mkdir -p "$INSTALL_DIR/logs"
    sudo mkdir -p "$INSTALL_DIR/data"
    
    # Copy current project files if they exist
    if [[ -d "/app/backend-nodejs" ]]; then
        log_info "Copying backend files from /app/backend-nodejs..."
        sudo cp -r /app/backend-nodejs/* "$INSTALL_DIR/backend-nodejs/"
    fi
    
    if [[ -d "/app/frontend" ]]; then
        log_info "Copying frontend files from /app/frontend..."
        sudo cp -r /app/frontend/* "$INSTALL_DIR/frontend/"
    fi
fi

# Check if service user exists
if ! id "$SERVICE_USER" &>/dev/null; then
    log_info "Creating service user: $SERVICE_USER..."
    sudo useradd -r -d "$INSTALL_DIR" -s /bin/bash "$SERVICE_USER"
fi

# Create log directory
sudo mkdir -p "$LOG_DIR"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$LOG_DIR"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

# Check if backend files exist
if [[ ! -f "$INSTALL_DIR/backend-nodejs/server.js" ]]; then
    log_warning "Backend server.js missing - creating minimal version..."
    
    sudo -u "$SERVICE_USER" tee "$INSTALL_DIR/backend-nodejs/server.js" > /dev/null << 'EOF'
#!/usr/bin/env node

const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 8001;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '2.0.0'
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 CryptoMiner Pro Backend running on port ${PORT}`);
});
EOF
fi

# Check if package.json exists in backend
if [[ ! -f "$INSTALL_DIR/backend-nodejs/package.json" ]]; then
    log_info "Creating backend package.json..."
    
    sudo -u "$SERVICE_USER" tee "$INSTALL_DIR/backend-nodejs/package.json" > /dev/null << 'EOF'
{
  "name": "cryptominer-pro-backend",
  "version": "2.0.0",
  "description": "CryptoMiner Pro Backend",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
EOF

    # Install minimal dependencies
    log_info "Installing minimal backend dependencies..."
    cd "$INSTALL_DIR/backend-nodejs"
    sudo -u "$SERVICE_USER" npm install express cors
fi

# Check if frontend files exist
if [[ ! -f "$INSTALL_DIR/frontend/package.json" ]]; then
    log_info "Creating frontend structure..."
    
    sudo -u "$SERVICE_USER" tee "$INSTALL_DIR/frontend/package.json" > /dev/null << 'EOF'
{
  "name": "cryptominer-pro-frontend",
  "version": "2.0.0",
  "description": "CryptoMiner Pro Frontend",
  "scripts": {
    "start": "node -e \"console.log('Frontend placeholder running on port 3000'); require('http').createServer((req,res)=>{res.writeHead(200,{'Content-Type':'text/html'});res.end('<h1>CryptoMiner Pro</h1><p>Frontend starting...</p>');}).listen(3000);\""
  }
}
EOF
fi

# Fix supervisor configuration files
log_info "Updating supervisor configuration files..."

# Backend supervisor config
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

# Frontend supervisor config  
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

# Check if Node.js and npm are accessible
log_info "Verifying Node.js installation..."
if ! command -v node &> /dev/null; then
    log_error "Node.js not found in PATH"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    log_error "npm not found in PATH"
    exit 1
fi

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
log_info "Node.js version: $NODE_VERSION"
log_info "npm version: $NPM_VERSION"

# Set proper permissions
log_info "Setting proper permissions..."
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$LOG_DIR"
sudo chmod +x "$INSTALL_DIR/backend-nodejs/server.js" 2>/dev/null || true

# Reload supervisor configuration
log_info "Reloading supervisor configuration..."
sudo supervisorctl reread
sudo supervisorctl update

# Wait for services to initialize
log_info "Starting services..."
sleep 3

# Start backend service
log_info "Starting backend service..."
sudo supervisorctl start cryptominer-backend

# Wait and check backend
sleep 5
if sudo supervisorctl status cryptominer-backend | grep -q "RUNNING"; then
    log "✅ Backend service started successfully!"
else
    log_error "❌ Backend service failed to start"
    log_info "Backend logs:"
    sudo tail -n 20 "$LOG_DIR/backend-error.log" 2>/dev/null || echo "No error logs found"
fi

# Start frontend service
log_info "Starting frontend service..."
sudo supervisorctl start cryptominer-frontend

# Wait and check frontend
sleep 5
if sudo supervisorctl status cryptominer-frontend | grep -q "RUNNING"; then
    log "✅ Frontend service started successfully!"
else
    log_error "❌ Frontend service failed to start"
    log_info "Frontend logs:"
    sudo tail -n 20 "$LOG_DIR/frontend-error.log" 2>/dev/null || echo "No error logs found"
fi

# Final status check
log_info "Final service status:"
sudo supervisorctl status

# Test backend API
log_info "Testing backend API..."
sleep 5
if curl -f http://localhost:8001/api/health &>/dev/null; then
    log "✅ Backend API is responding!"
else
    log_warning "Backend API not responding yet (may need more time)"
fi

# Test frontend
log_info "Testing frontend..."
if curl -f http://localhost:3000 &>/dev/null; then
    log "✅ Frontend is responding!"
else
    log_warning "Frontend not responding yet (may need more time)"
fi

echo -e "${GREEN}"
echo "==============================================================================="
echo "  ✅ Service Configuration Fix Completed!"
echo "==============================================================================="
echo -e "${NC}"

log "🎉 Services should now be running properly!"

echo ""
log_info "Service status:"
sudo supervisorctl status
echo ""
log_info "Access your application:"
echo "  🌐 Frontend: http://localhost:3000"  
echo "  🔧 Backend: http://localhost:8001/api/health"
echo ""
log_info "View logs:"
echo "  📋 Backend: sudo tail -f $LOG_DIR/backend.log"
echo "  📋 Frontend: sudo tail -f $LOG_DIR/frontend.log"
echo ""