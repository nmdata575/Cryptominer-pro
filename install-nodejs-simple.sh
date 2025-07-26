#!/bin/bash

# CryptoMiner Pro - Node.js Simple Installation Script
# This script installs the Node.js version with minimal dependencies

set -e

echo "🚀 CryptoMiner Pro - Node.js Simple Installation"
echo "==============================================="

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

# Check if running as root and handle appropriately
if [[ $EUID -eq 0 ]]; then
   print_warning "Running as root - creating user 'cryptominer' for application..."
   
   # Create user if doesn't exist
   if ! id "cryptominer" &>/dev/null; then
       useradd -m -s /bin/bash cryptominer
       usermod -aG sudo cryptominer
       print_status "Created user 'cryptominer'"
   fi
   
   # Copy script to user directory and run as user
   cp "$0" /home/cryptominer/
   chown cryptominer:cryptominer /home/cryptominer/install-nodejs-simple.sh
   chmod +x /home/cryptominer/install-nodejs-simple.sh
   
   print_status "Switching to user 'cryptominer' to continue installation..."
   su - cryptominer -c "/home/cryptominer/install-nodejs-simple.sh"
   exit 0
fi

# Update system packages
print_step "Updating system packages..."
sudo apt update

# Install Node.js and npm (using NodeSource repository)
print_step "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
print_step "Verifying Node.js installation..."
node_version=$(node --version)
npm_version=$(npm --version)
print_status "Node.js version: $node_version"
print_status "npm version: $npm_version"

# Install MongoDB using Docker (more reliable)
print_step "Installing Docker for MongoDB..."
if ! command -v docker &> /dev/null; then
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    print_status "Docker installed successfully"
else
    print_status "Docker is already installed"
fi

# Start MongoDB container
print_step "Starting MongoDB container..."
if ! docker ps -q -f name=cryptominer-mongo > /dev/null 2>&1; then
    docker run -d \
        --name cryptominer-mongo \
        --restart unless-stopped \
        -p 27017:27017 \
        -v cryptominer-mongo-data:/data/db \
        mongo:6.0
    print_status "MongoDB container started"
else
    print_status "MongoDB container is already running"
fi

# Wait for MongoDB to be ready
print_step "Waiting for MongoDB to be ready..."
sleep 10

# Install supervisor
print_step "Installing supervisor..."
sudo apt-get install -y supervisor

# Create application directory
print_step "Creating application directory..."
sudo mkdir -p /opt/cryptominer-pro
sudo chown -R $USER:$USER /opt/cryptominer-pro

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

# Update MongoDB URL in backend .env
print_step "Configuring MongoDB connection..."
sed -i 's|mongodb://localhost:27017/cryptominer|mongodb://localhost:27017/cryptominer|g' /opt/cryptominer-pro/backend-nodejs/.env

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

# Start MongoDB container if not running
if ! docker ps -q -f name=cryptominer-mongo > /dev/null 2>&1; then
    echo "📦 Starting MongoDB container..."
    docker start cryptominer-mongo
    sleep 5
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
echo "To stop the application, run: /opt/cryptominer-pro/stop.sh"

# Keep script running
wait $BACKEND_PID $FRONTEND_PID
EOF

# Create stop script
cat > /opt/cryptominer-pro/stop.sh << 'EOF'
#!/bin/bash
# CryptoMiner Pro Stop Script

echo "🛑 Stopping CryptoMiner Pro..."

# Stop Node.js processes
pkill -f "node.*server.js"
pkill -f "react-scripts start"

# Stop MongoDB container
docker stop cryptominer-mongo

echo "✅ CryptoMiner Pro stopped"
EOF

# Make scripts executable
chmod +x /opt/cryptominer-pro/start.sh
chmod +x /opt/cryptominer-pro/stop.sh

# Create desktop shortcut
print_step "Creating desktop shortcut..."
if [ -d "$HOME/Desktop" ]; then
    cat > $HOME/Desktop/CryptoMiner-Pro.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=CryptoMiner Pro
Comment=Advanced Cryptocurrency Mining System
Exec=/opt/cryptominer-pro/start.sh
Icon=applications-system
Terminal=true
Categories=Application;Network;
EOF
    chmod +x $HOME/Desktop/CryptoMiner-Pro.desktop
    print_status "Desktop shortcut created"
fi

# Create command line shortcuts
print_step "Creating command line shortcuts..."
echo 'alias cryptominer-start="/opt/cryptominer-pro/start.sh"' >> ~/.bashrc
echo 'alias cryptominer-stop="/opt/cryptominer-pro/stop.sh"' >> ~/.bashrc
echo 'alias cryptominer-mongo="docker exec -it cryptominer-mongo mongo"' >> ~/.bashrc

# Test the installation
print_step "Testing installation..."
cd /opt/cryptominer-pro/backend-nodejs

# Start backend temporarily to test
timeout 10s npm start &
BACKEND_PID=$!
sleep 5

# Test API endpoint
if curl -s http://localhost:8001/api/health > /dev/null; then
    print_status "✅ Backend API is working"
else
    print_warning "⚠️  Backend API test failed (may need manual verification)"
fi

# Stop test backend
kill $BACKEND_PID 2>/dev/null || true

# Display completion message
echo ""
echo "🎉 CryptoMiner Pro Simple Installation Complete!"
echo "================================================"
echo ""
echo "📋 Quick Commands:"
echo "  cryptominer-start    - Start the mining system"
echo "  cryptominer-stop     - Stop the mining system"
echo "  cryptominer-mongo    - Access MongoDB console"
echo ""
echo "🚀 To start CryptoMiner Pro:"
echo "   /opt/cryptominer-pro/start.sh"
echo ""
echo "📊 Once started, access the dashboard at:"
echo "   http://localhost:3000"
echo ""
echo "📁 Installation Directory: /opt/cryptominer-pro"
echo "🐳 MongoDB: Docker container 'cryptominer-mongo'"
echo ""
print_status "Installation completed successfully!"
echo ""
echo "🔄 To reload command aliases, run: source ~/.bashrc"
echo "🖥️  Desktop shortcut: ~/Desktop/CryptoMiner-Pro.desktop"
echo ""
print_status "Happy mining! 🚀"