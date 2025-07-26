#!/bin/bash

# Quick Fix Script for Installation Issue
# This script fixes the path issue in the installation

set -e

echo "🔧 CryptoMiner Pro - Quick Installation Fix"
echo "========================================="

# Get current directory
CURRENT_DIR=$(pwd)
echo "Current directory: $CURRENT_DIR"

# Check if we have the required directories
if [[ -d "./backend-nodejs" ]] && [[ -d "./frontend" ]]; then
    echo "✅ Found project structure in current directory"
    INSTALL_FROM="."
elif [[ -d "/app/backend-nodejs" ]] && [[ -d "/app/frontend" ]]; then
    echo "✅ Found project structure in /app directory"
    INSTALL_FROM="/app"
else
    echo "❌ Cannot find backend-nodejs and frontend directories"
    echo "Please ensure you're in the project root directory or /app"
    echo "Looking for:"
    echo "  - backend-nodejs/"
    echo "  - frontend/"
    exit 1
fi

echo "Installing from: $INSTALL_FROM"

# Create application directory
APP_DIR="/opt/cryptominer-pro"
echo "Creating application directory: $APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo chown $(whoami):$(whoami) "$APP_DIR"

# Copy files
echo "Copying backend files..."
cp -r "$INSTALL_FROM/backend-nodejs" "$APP_DIR/" || {
    echo "❌ Failed to copy backend files"
    exit 1
}

echo "Copying frontend files..."
cp -r "$INSTALL_FROM/frontend" "$APP_DIR/" || {
    echo "❌ Failed to copy frontend files"
    exit 1
}

# Copy documentation
echo "Copying documentation..."
[[ -f "$INSTALL_FROM/README.md" ]] && cp "$INSTALL_FROM/README.md" "$APP_DIR/"
[[ -f "$INSTALL_FROM/REMOTE_API_GUIDE.md" ]] && cp "$INSTALL_FROM/REMOTE_API_GUIDE.md" "$APP_DIR/"
[[ -f "$INSTALL_FROM/CUSTOM_COINS_GUIDE.md" ]] && cp "$INSTALL_FROM/CUSTOM_COINS_GUIDE.md" "$APP_DIR/"

echo "✅ Files copied successfully!"

# Install dependencies
echo "Installing backend dependencies..."
cd "$APP_DIR/backend-nodejs"
npm install || {
    echo "❌ Backend dependencies installation failed"
    exit 1
}

echo "Installing frontend dependencies..."
cd "$APP_DIR/frontend"
npm install || {
    echo "❌ Frontend dependencies installation failed"
    exit 1
}

echo "Building frontend..."
npm run build || {
    echo "❌ Frontend build failed"
    exit 1
}

# Configure supervisor
echo "Configuring supervisor..."
sudo tee /etc/supervisor/conf.d/cryptominer.conf > /dev/null << EOF
[group:mining_system]
programs=backend,frontend

[program:backend]
command=node server.js
directory=$APP_DIR/backend-nodejs
user=$(whoami)
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/backend.err.log
stdout_logfile=/var/log/supervisor/backend.out.log
environment=NODE_ENV=production

[program:frontend]
command=npx serve -s build -l 3000
directory=$APP_DIR/frontend
user=$(whoami)
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/frontend.err.log
stdout_logfile=/var/log/supervisor/frontend.out.log
EOF

sudo supervisorctl reread
sudo supervisorctl update

# Start services
echo "Starting services..."
sudo supervisorctl start mining_system:*

# Wait and check status
sleep 5
echo "Service status:"
sudo supervisorctl status mining_system:*

echo ""
echo "🎉 Installation completed successfully!"
echo "Frontend: http://localhost:3000"
echo "Backend API: http://localhost:8001"
echo ""
echo "Useful commands:"
echo "  sudo supervisorctl status      # Check status"
echo "  sudo supervisorctl restart all # Restart all"
echo "  sudo supervisorctl stop all    # Stop all"