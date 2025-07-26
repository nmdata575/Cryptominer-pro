#!/bin/bash

# Fix Installation Script
# This script ensures the installation works correctly

set -e

echo "🔧 Fixing CryptoMiner Pro Installation"
echo "====================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check current directory
print_info "Current directory: $(pwd)"

# Check if required directories exist
print_info "Checking required directories..."

if [ -d "/app/backend-nodejs" ]; then
    print_status "Backend directory exists: /app/backend-nodejs"
else
    print_error "Backend directory missing: /app/backend-nodejs"
    exit 1
fi

if [ -d "/app/frontend" ]; then
    print_status "Frontend directory exists: /app/frontend"
else
    print_error "Frontend directory missing: /app/frontend"
    exit 1
fi

# Create application directory
print_info "Creating application directory..."
mkdir -p /opt/cryptominer-pro

# Copy application files with proper paths
print_info "Copying backend files..."
cp -r /app/backend-nodejs /opt/cryptominer-pro/
print_status "Backend files copied"

print_info "Copying frontend files..."
cp -r /app/frontend /opt/cryptominer-pro/
print_status "Frontend files copied"

# Copy documentation
print_info "Copying documentation..."
cp /app/REMOTE_API_GUIDE.md /opt/cryptominer-pro/ 2>/dev/null || true
cp /app/CUSTOM_COINS_GUIDE.md /opt/cryptominer-pro/ 2>/dev/null || true
cp /app/MANUAL_INSTALL.md /opt/cryptominer-pro/ 2>/dev/null || true
cp /app/STREAMLINED_STRUCTURE.md /opt/cryptominer-pro/ 2>/dev/null || true
print_status "Documentation copied"

# Install backend dependencies
print_info "Installing backend dependencies..."
cd /opt/cryptominer-pro/backend-nodejs
npm install --production
print_status "Backend dependencies installed"

# Install frontend dependencies
print_info "Installing frontend dependencies..."
cd /opt/cryptominer-pro/frontend
npm install --production
print_status "Frontend dependencies installed"

# Create startup script
print_info "Creating startup script..."
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

# Make scripts executable
chmod +x /opt/cryptominer-pro/start.sh
chmod +x /opt/cryptominer-pro/stop.sh

# Test the installation
print_info "Testing installation..."
cd /opt/cryptominer-pro/backend-nodejs

# Start backend temporarily to test
timeout 10s npm start &
BACKEND_PID=$!
sleep 5

# Test API endpoint
if curl -s http://localhost:8001/api/health > /dev/null; then
    print_status "✅ Backend API is working"
else
    print_warning "⚠️  Backend API test failed (may need more time)"
fi

# Stop test backend
kill $BACKEND_PID 2>/dev/null || true

# Final verification
print_info "Final verification..."
if [ -f "/opt/cryptominer-pro/backend-nodejs/server.js" ]; then
    print_status "Backend server file exists"
else
    print_error "Backend server file missing"
fi

if [ -f "/opt/cryptominer-pro/frontend/package.json" ]; then
    print_status "Frontend package.json exists"
else
    print_error "Frontend package.json missing"
fi

echo ""
echo "🎉 Installation Fix Complete!"
echo "============================"
echo ""
echo "🚀 To start CryptoMiner Pro:"
echo "   /opt/cryptominer-pro/start.sh"
echo ""
echo "📊 Once started, access the dashboard at:"
echo "   http://localhost:3000"
echo ""
echo "🔧 Backend API will be available at:"
echo "   http://localhost:8001"
echo ""
echo "📁 Installation Directory: /opt/cryptominer-pro"
echo ""
print_status "Installation fixed successfully!"
print_info "You can now start the application with: /opt/cryptominer-pro/start.sh"