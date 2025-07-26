#!/bin/bash

# CryptoMiner Pro - Node.js Installation Script
# This script installs the Node.js version of CryptoMiner Pro

set -e

echo "🚀 CryptoMiner Pro - Node.js Installation Script"
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user."
   exit 1
fi

# Update system packages
print_step "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js and npm
print_step "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
print_step "Verifying Node.js installation..."
node_version=$(node --version)
npm_version=$(npm --version)
print_status "Node.js version: $node_version"
print_status "npm version: $npm_version"

# Install MongoDB
print_step "Installing MongoDB..."
# Import MongoDB GPG key
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Update package list
sudo apt-get update

# Install MongoDB
sudo apt-get install -y mongodb-org

# Start MongoDB
print_step "Starting MongoDB service..."
sudo systemctl start mongod
sudo systemctl enable mongod

# Wait for MongoDB to start
print_step "Waiting for MongoDB to start..."
sleep 5

# Verify MongoDB is running
if sudo systemctl is-active --quiet mongod; then
    print_status "✅ MongoDB is running"
else
    print_warning "⚠️  MongoDB may need manual starting"
fi

# Install supervisor
print_step "Installing supervisor..."
sudo apt-get install -y supervisor

# Create application directory
print_step "Creating application directory..."
sudo mkdir -p /opt/cryptominer-pro
sudo chown -R $USER:$USER /opt/cryptominer-pro

# Copy application files
print_step "Copying application files..."
cp -r /app/backend-nodejs /opt/cryptominer-pro/
cp -r /app/frontend /opt/cryptominer-pro/
cp -r /app/REMOTE_API_GUIDE.md /opt/cryptominer-pro/

# Install backend dependencies
print_step "Installing backend dependencies..."
cd /opt/cryptominer-pro/backend-nodejs
npm install

# Install frontend dependencies
print_step "Installing frontend dependencies..."
cd /opt/cryptominer-pro/frontend
npm install

# Create supervisor configuration
print_step "Creating supervisor configuration..."
sudo tee /etc/supervisor/conf.d/cryptominer-pro.conf > /dev/null <<EOF
[program:cryptominer-backend]
command=npm start
directory=/opt/cryptominer-pro/backend-nodejs
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/cryptominer-backend.err.log
stdout_logfile=/var/log/supervisor/cryptominer-backend.out.log
environment=NODE_ENV=production

[program:cryptominer-frontend]
command=npm start
directory=/opt/cryptominer-pro/frontend
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/cryptominer-frontend.err.log
stdout_logfile=/var/log/supervisor/cryptominer-frontend.out.log
environment=PORT=3000

[group:cryptominer-pro]
programs=cryptominer-backend,cryptominer-frontend
priority=999
EOF

# Update supervisor
print_step "Updating supervisor configuration..."
sudo supervisorctl reread
sudo supervisorctl update

# Start services
print_step "Starting CryptoMiner Pro services..."
sudo supervisorctl start cryptominer-pro:*

# Create systemd service for auto-start
print_step "Creating systemd service..."
sudo tee /etc/systemd/system/cryptominer-pro.service > /dev/null <<EOF
[Unit]
Description=CryptoMiner Pro - Advanced Cryptocurrency Mining System
After=network.target mongodb.service

[Service]
Type=forking
ExecStart=/usr/bin/supervisorctl start cryptominer-pro:*
ExecStop=/usr/bin/supervisorctl stop cryptominer-pro:*
ExecReload=/usr/bin/supervisorctl restart cryptominer-pro:*
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

# Enable systemd service
sudo systemctl daemon-reload
sudo systemctl enable cryptominer-pro.service

# Create desktop shortcut
print_step "Creating desktop shortcut..."
cat > ~/Desktop/CryptoMiner-Pro.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=CryptoMiner Pro
Comment=Advanced Cryptocurrency Mining System
Exec=xdg-open http://localhost:3000
Icon=applications-system
Terminal=false
Categories=Application;Network;
EOF

chmod +x ~/Desktop/CryptoMiner-Pro.desktop

# Create command line shortcuts
print_step "Creating command line shortcuts..."
echo 'alias cryptominer-start="sudo supervisorctl start cryptominer-pro:*"' >> ~/.bashrc
echo 'alias cryptominer-stop="sudo supervisorctl stop cryptominer-pro:*"' >> ~/.bashrc
echo 'alias cryptominer-restart="sudo supervisorctl restart cryptominer-pro:*"' >> ~/.bashrc
echo 'alias cryptominer-status="sudo supervisorctl status cryptominer-pro:*"' >> ~/.bashrc
echo 'alias cryptominer-logs="sudo tail -f /var/log/supervisor/cryptominer-*.log"' >> ~/.bashrc

# Set up log rotation
print_step "Setting up log rotation..."
sudo tee /etc/logrotate.d/cryptominer-pro > /dev/null <<EOF
/var/log/supervisor/cryptominer-*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        /usr/bin/supervisorctl signal USR2 cryptominer-pro:*
    endscript
}
EOF

# Create configuration directory
print_step "Creating configuration directory..."
mkdir -p ~/.config/cryptominer-pro

# Set up environment variables
print_step "Setting up environment variables..."
cat > ~/.config/cryptominer-pro/config.env <<EOF
# CryptoMiner Pro Configuration
CRYPTOMINER_HOME=/opt/cryptominer-pro
CRYPTOMINER_BACKEND_URL=http://localhost:8001
CRYPTOMINER_FRONTEND_URL=http://localhost:3000
CRYPTOMINER_LOG_LEVEL=info
EOF

# Final verification
print_step "Performing final verification..."
sleep 5

# Check if services are running
backend_status=$(sudo supervisorctl status cryptominer-pro:cryptominer-backend | grep RUNNING || echo "FAILED")
frontend_status=$(sudo supervisorctl status cryptominer-pro:cryptominer-frontend | grep RUNNING || echo "FAILED")

if [[ $backend_status == *"RUNNING"* ]]; then
    print_status "✅ Backend service is running"
else
    print_error "❌ Backend service failed to start"
fi

if [[ $frontend_status == *"RUNNING"* ]]; then
    print_status "✅ Frontend service is running"
else
    print_error "❌ Frontend service failed to start"
fi

# Test API endpoint
print_step "Testing API endpoint..."
if curl -s http://localhost:8001/api/health > /dev/null; then
    print_status "✅ Backend API is responding"
else
    print_warning "⚠️  Backend API is not responding yet (may need more time)"
fi

# Display completion message
echo ""
echo "🎉 CryptoMiner Pro Installation Complete!"
echo "========================================"
echo ""
echo "📊 Dashboard: http://localhost:3000"
echo "🔧 Backend API: http://localhost:8001"
echo "📱 Remote API: http://localhost:8001/api/remote"
echo ""
echo "📋 Quick Commands:"
echo "  cryptominer-start    - Start the mining system"
echo "  cryptominer-stop     - Stop the mining system"
echo "  cryptominer-restart  - Restart the mining system"
echo "  cryptominer-status   - Check system status"
echo "  cryptominer-logs     - View system logs"
echo ""
echo "📁 Installation Directory: /opt/cryptominer-pro"
echo "📄 Logs Directory: /var/log/supervisor/"
echo "⚙️  Configuration: ~/.config/cryptominer-pro/"
echo ""
print_status "Installation completed successfully!"
print_status "You can now access the CryptoMiner Pro dashboard at: http://localhost:3000"
echo ""
echo "🔄 To reload command aliases, run: source ~/.bashrc"
echo "🖥️  Desktop shortcut created: ~/Desktop/CryptoMiner-Pro.desktop"
echo ""
echo "For Android app development, see: /opt/cryptominer-pro/REMOTE_API_GUIDE.md"
echo ""
print_status "Happy mining! 🚀"