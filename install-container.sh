#!/bin/bash

# CryptoMiner Pro - Container Installation Script
# Optimized for container environments

set -e

echo "🚀 CryptoMiner Pro - Container Installation"
echo "=========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Update system packages
print_step "Updating system packages..."
apt update

# Install Node.js and npm
print_step "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Verify Node.js installation
print_step "Verifying Node.js installation..."
node_version=$(node --version)
npm_version=$(npm --version)
print_status "Node.js version: $node_version"
print_status "npm version: $npm_version"

# Create application directory
print_step "Creating application directory..."
mkdir -p /opt/cryptominer-pro

# Copy application files
print_step "Copying application files..."
if [ -d "/app/backend-nodejs" ]; then
    cp -r /app/backend-nodejs /opt/cryptominer-pro/
    print_status "Backend copied successfully"
else
    print_error "Backend directory not found at /app/backend-nodejs"
    exit 1
fi

if [ -d "/app/frontend" ]; then
    cp -r /app/frontend /opt/cryptominer-pro/
    print_status "Frontend copied successfully"
else
    print_error "Frontend directory not found at /app/frontend"
    exit 1
fi

# Copy documentation
if [ -f "/app/REMOTE_API_GUIDE.md" ]; then
    cp /app/REMOTE_API_GUIDE.md /opt/cryptominer-pro/
fi

if [ -f "/app/MANUAL_INSTALL.md" ]; then
    cp /app/MANUAL_INSTALL.md /opt/cryptominer-pro/
fi

# Install backend dependencies
print_step "Installing backend dependencies..."
cd /opt/cryptominer-pro/backend-nodejs
npm install --production

# Install frontend dependencies
print_step "Installing frontend dependencies..."
cd /opt/cryptominer-pro/frontend
npm install --production

# Create startup script
print_step "Creating startup script..."
cat > /opt/cryptominer-pro/start.sh << 'EOF'
#!/bin/bash
# CryptoMiner Pro Startup Script

echo "🚀 Starting CryptoMiner Pro..."

# Start MongoDB if not already running
if ! pgrep mongod > /dev/null; then
    echo "📦 Starting MongoDB..."
    mongod --fork --logpath /var/log/mongodb/mongod.log --dbpath /var/lib/mongodb
    sleep 3
fi

# Start backend
echo "🔧 Starting backend..."
cd /opt/cryptominer-pro/backend-nodejs
npm start &
BACKEND_PID=$!

# Wait for backend to start
sleep 5

# Start frontend
echo "🌐 Starting frontend..."
cd /opt/cryptominer-pro/frontend
npm start &
FRONTEND_PID=$!

echo "✅ CryptoMiner Pro started successfully!"
echo "📊 Dashboard: http://localhost:3000"
echo "🔧 Backend API: http://localhost:8001"
echo ""
echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"
echo ""
echo "To stop the application, run: /opt/cryptominer-pro/stop.sh"

# Create PID files for easy stopping
echo $BACKEND_PID > /opt/cryptominer-pro/backend.pid
echo $FRONTEND_PID > /opt/cryptominer-pro/frontend.pid

# Keep script running
wait $BACKEND_PID $FRONTEND_PID
EOF

# Create stop script
cat > /opt/cryptominer-pro/stop.sh << 'EOF'
#!/bin/bash
# CryptoMiner Pro Stop Script

echo "🛑 Stopping CryptoMiner Pro..."

# Stop using PID files if they exist
if [ -f "/opt/cryptominer-pro/backend.pid" ]; then
    BACKEND_PID=$(cat /opt/cryptominer-pro/backend.pid)
    kill $BACKEND_PID 2>/dev/null || true
    rm -f /opt/cryptominer-pro/backend.pid
fi

if [ -f "/opt/cryptominer-pro/frontend.pid" ]; then
    FRONTEND_PID=$(cat /opt/cryptominer-pro/frontend.pid)
    kill $FRONTEND_PID 2>/dev/null || true
    rm -f /opt/cryptominer-pro/frontend.pid
fi

# Fallback: kill by process name
pkill -f "node.*server.js" || true
pkill -f "react-scripts start" || true

echo "✅ CryptoMiner Pro stopped"
EOF

# Create test script
cat > /opt/cryptominer-pro/test.sh << 'EOF'
#!/bin/bash
# CryptoMiner Pro Test Script

echo "🧪 Testing CryptoMiner Pro..."

# Test backend
echo "Testing backend API..."
cd /opt/cryptominer-pro/backend-nodejs
timeout 15s npm start &
BACKEND_PID=$!
sleep 8

# Test API endpoints
echo "Testing health endpoint..."
if curl -s http://localhost:8001/api/health > /dev/null; then
    echo "✅ Backend API is working"
else
    echo "❌ Backend API is not responding"
fi

# Stop test backend
kill $BACKEND_PID 2>/dev/null || true

echo "🧪 Test completed"
EOF

# Make scripts executable
chmod +x /opt/cryptominer-pro/start.sh
chmod +x /opt/cryptominer-pro/stop.sh
chmod +x /opt/cryptominer-pro/test.sh

# Create configuration directory
mkdir -p /root/.config/cryptominer-pro

# Create configuration file
cat > /root/.config/cryptominer-pro/config.env << EOF
# CryptoMiner Pro Configuration
CRYPTOMINER_HOME=/opt/cryptominer-pro
CRYPTOMINER_BACKEND_URL=http://localhost:8001
CRYPTOMINER_FRONTEND_URL=http://localhost:3000
CRYPTOMINER_LOG_LEVEL=info
EOF

# Test the installation
print_step "Testing installation..."
cd /opt/cryptominer-pro
./test.sh

# Display completion message
echo ""
echo "🎉 CryptoMiner Pro Container Installation Complete!"
echo "================================================="
echo ""
echo "🚀 To start CryptoMiner Pro:"
echo "   /opt/cryptominer-pro/start.sh"
echo ""
echo "🛑 To stop CryptoMiner Pro:"
echo "   /opt/cryptominer-pro/stop.sh"
echo ""
echo "📊 Once started, access the dashboard at:"
echo "   http://localhost:3000"
echo ""
echo "🔧 Backend API will be available at:"
echo "   http://localhost:8001"
echo ""
echo "📁 Installation Directory: /opt/cryptominer-pro"
echo "⚙️  Configuration: /root/.config/cryptominer-pro/"
echo ""
print_status "Installation completed successfully!"
echo ""
print_status "Note: This is a container-optimized installation"
print_status "For production deployment, use the full installation script"
echo ""
print_status "Happy mining! 🚀"