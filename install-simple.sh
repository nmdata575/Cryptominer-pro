#!/bin/bash

# CryptoMiner Pro - Simple Native Installation
# Alternative method using Docker for MongoDB

echo "🚀 CryptoMiner Pro - Simple Native Installation"
echo "==============================================="
echo "This method uses Docker for MongoDB to avoid repository issues"
echo ""

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "⚠️  Please log out and log back in for Docker permissions to take effect"
    echo "Then run this script again."
    exit 0
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    USER_HOME="/root"
    INSTALL_USER="root"
else
    USER_HOME="$HOME"
    INSTALL_USER="$USER"
fi

INSTALL_DIR="$USER_HOME/cryptominer-pro"

echo "📁 Installation Directory: $INSTALL_DIR"
echo "👤 User: $INSTALL_USER"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy application files
if [[ -f "./backend-nodejs/server.js" ]]; then
    echo "📂 Copying application files..."
    cp -r ./backend-nodejs "$INSTALL_DIR/"
    cp -r ./frontend "$INSTALL_DIR/"
    cp -r ./*.md "$INSTALL_DIR/" 2>/dev/null || true
    cp -r ./*.sh "$INSTALL_DIR/" 2>/dev/null || true
    cp -r ./.gitignore "$INSTALL_DIR/" 2>/dev/null || true
    cp -r ./package.json "$INSTALL_DIR/" 2>/dev/null || true
else
    echo "❌ Application files not found. Extract the package first."
    exit 1
fi

# Install Node.js
echo "📦 Installing Node.js..."
if ! command -v node >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
    sudo apt-get install -y nodejs
fi

# Install supervisor
echo "📦 Installing supervisor..."
sudo apt-get update
sudo apt-get install -y supervisor

# Start MongoDB with Docker
echo "🚀 Starting MongoDB with Docker..."
docker run -d \
    --name cryptominer-mongodb \
    --restart unless-stopped \
    -p 27017:27017 \
    -v cryptominer-data:/data/db \
    mongo:7.0

# Wait for MongoDB to start
sleep 5

# Install application dependencies
echo "📦 Installing application dependencies..."
cd "$INSTALL_DIR"

# Backend dependencies
cd backend-nodejs
npm install
cd ..

# Frontend dependencies
cd frontend
npm install
npm run build
cd ..

# Create supervisor configuration
echo "⚙️  Creating supervisor configuration..."
sudo tee /etc/supervisor/conf.d/cryptominer-simple.conf > /dev/null << EOF
[program:cryptominer-backend-simple]
command=npm start
directory=$INSTALL_DIR/backend-nodejs
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/cryptominer-backend-simple.err.log
stdout_logfile=/var/log/supervisor/cryptominer-backend-simple.out.log
environment=NODE_ENV=production,MONGO_URL="mongodb://localhost:27017/cryptominer"
user=$INSTALL_USER
startsecs=10
startretries=3

[program:cryptominer-frontend-simple]
command=npm start
directory=$INSTALL_DIR/frontend
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/cryptominer-frontend-simple.err.log
stdout_logfile=/var/log/supervisor/cryptominer-frontend-simple.out.log
environment=PORT=3000,GENERATE_SOURCEMAP=false,ESLINT_NO_CACHE=true,REACT_APP_BACKEND_URL="http://localhost:8001"
user=$INSTALL_USER
startsecs=15
startretries=3

[group:cryptominer-simple]
programs=cryptominer-backend-simple,cryptominer-frontend-simple
priority=999
EOF

# Reload and start services
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start cryptominer-simple:*

# Wait and check status
sleep 10
echo ""
echo "📊 Service Status:"
sudo supervisorctl status cryptominer-simple:*

echo ""
echo "✅ Simple installation completed!"
echo ""
echo "🌐 Access your mining dashboard:"
echo "   http://localhost:3000"
echo ""
echo "🔧 Service management:"
echo "   sudo supervisorctl status cryptominer-simple:*"
echo "   sudo supervisorctl restart cryptominer-simple:*"
echo ""
echo "🐳 MongoDB management:"
echo "   docker ps | grep cryptominer-mongodb"
echo "   docker logs cryptominer-mongodb"
echo ""

# Test hardware detection
echo "🔍 Testing real hardware detection..."
cd "$INSTALL_DIR/backend-nodejs"
node -e "
const os = require('os');
console.log('✅ REAL HARDWARE DETECTED:');
console.log('  CPU Cores:', os.cpus().length);
console.log('  CPU Model:', os.cpus()[0].model);
console.log('  Architecture:', process.arch);
"

echo ""
echo "🎉 Your real hardware will now be displayed in the web interface!"