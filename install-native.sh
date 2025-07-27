#!/bin/bash

# CryptoMiner Pro - Native Host Installation Script
# Run this on your actual hardware (not in containers)

set -e

echo "🚀 CryptoMiner Pro - Native Host Installation"
echo "=============================================="
echo "This will install CryptoMiner Pro directly on your host system"
echo "to detect actual hardware (4 cores / 128 cores)"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "⚠️  Running as root. Creating cryptominer user..."
    if ! id "cryptominer" &>/dev/null; then
        useradd -m -s /bin/bash cryptominer
        usermod -aG sudo cryptominer
    fi
    USER_HOME="/home/cryptominer"
    INSTALL_USER="cryptominer"
else
    USER_HOME="$HOME"
    INSTALL_USER="$USER"
fi

INSTALL_DIR="$USER_HOME/cryptominer-pro"

echo "📁 Installation Directory: $INSTALL_DIR"
echo "👤 User: $INSTALL_USER"
echo ""

# Create installation directory
echo "📦 Creating installation directory..."
mkdir -p "$INSTALL_DIR"

# Copy application files (if running from extracted directory)
if [[ -f "./backend-nodejs/server.js" ]]; then
    echo "📂 Copying application files..."
    cp -r ./backend-nodejs "$INSTALL_DIR/"
    cp -r ./frontend "$INSTALL_DIR/"
    cp -r ./*.md "$INSTALL_DIR/" 2>/dev/null || true
    cp -r ./*.sh "$INSTALL_DIR/" 2>/dev/null || true
    cp -r ./.gitignore "$INSTALL_DIR/" 2>/dev/null || true
    cp -r ./package.json "$INSTALL_DIR/" 2>/dev/null || true
else
    echo "❌ Application files not found in current directory"
    echo "💡 Please extract cryptominer-pro-native.tar.gz first:"
    echo "   tar -xzf cryptominer-pro-native.tar.gz"
    echo "   cd cryptominer-pro-native"
    echo "   sudo ./install-native.sh"
    exit 1
fi

# Set proper ownership
if [[ $EUID -eq 0 ]] && [[ "$INSTALL_USER" != "root" ]]; then
    chown -R "$INSTALL_USER:$INSTALL_USER" "$INSTALL_DIR"
fi

echo "✅ Files copied successfully"
echo ""

# Check system information
echo "🔍 Detecting actual hardware..."
CPU_COUNT=$(nproc)
TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.1fGB", $2/1024}')
echo "  CPU Cores: $CPU_COUNT"
echo "  RAM: $TOTAL_RAM"
echo "  Architecture: $(uname -m)"
echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "$(uname -s) $(uname -r)")"
echo ""

# Install system dependencies
echo "📦 Installing system dependencies..."

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
    apt-get update
    apt-get install -y curl wget gnupg2 software-properties-common supervisor mongodb
elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
    yum update -y
    yum install -y curl wget gnupg2 supervisor mongodb-server
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf" 
    dnf update -y
    dnf install -y curl wget gnupg2 supervisor mongodb-server
else
    echo "❌ Unsupported package manager. Please install manually:"
    echo "  - Node.js 18+"
    echo "  - MongoDB"
    echo "  - Supervisor"
    exit 1
fi

# Install Node.js
echo "📦 Installing Node.js..."
if ! command -v node >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        apt-get install -y nodejs
    else
        yum install -y nodejs npm
    fi
fi

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
echo "  Node.js: $NODE_VERSION"
echo "  NPM: $NPM_VERSION"

# Start MongoDB
echo "🚀 Starting MongoDB..."
if command -v systemctl >/dev/null 2>&1; then
    systemctl start mongod
    systemctl enable mongod
else
    service mongod start
fi

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

# Create supervisor configuration for native installation
echo "⚙️  Creating supervisor configuration..."
cat > /etc/supervisor/conf.d/cryptominer-native.conf << EOF
[program:cryptominer-backend]
command=npm start
directory=$INSTALL_DIR/backend-nodejs
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/cryptominer-backend.err.log
stdout_logfile=/var/log/supervisor/cryptominer-backend.out.log
environment=NODE_ENV=production,MONGO_URL="mongodb://localhost:27017/cryptominer"
user=$INSTALL_USER
startsecs=10
startretries=3

[program:cryptominer-frontend]
command=npm start
directory=$INSTALL_DIR/frontend
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/cryptominer-frontend.err.log  
stdout_logfile=/var/log/supervisor/cryptominer-frontend.out.log
environment=PORT=3000,GENERATE_SOURCEMAP=false,ESLINT_NO_CACHE=true,REACT_APP_BACKEND_URL="http://localhost:8001"
user=$INSTALL_USER
startsecs=15
startretries=3

[group:cryptominer-native]
programs=cryptominer-backend,cryptominer-frontend
priority=999
EOF

# Reload supervisor
supervisorctl reread
supervisorctl update

# Start services
echo "🚀 Starting services..."
supervisorctl start cryptominer-native:*

# Wait for services to start
sleep 10

# Check status
echo ""
echo "📊 Service Status:"
supervisorctl status cryptominer-native:*

echo ""
echo "✅ Native installation completed!"
echo ""
echo "🌐 Access your mining dashboard at:"
echo "   http://localhost:3000"
echo "   http://$(hostname -I | awk '{print $1}'):3000"
echo ""
echo "📊 API endpoint:" 
echo "   http://localhost:8001/api/health"
echo ""
echo "🔧 Service management:"
echo "   Start:   sudo supervisorctl start cryptominer-native:*"
echo "   Stop:    sudo supervisorctl stop cryptominer-native:*"
echo "   Restart: sudo supervisorctl restart cryptominer-native:*"
echo "   Status:  sudo supervisorctl status cryptominer-native:*"
echo "   Logs:    sudo tail -f /var/log/supervisor/cryptominer-*.log"
echo ""

# Test actual hardware detection
echo "🔍 Testing actual hardware detection..."
cd "$INSTALL_DIR/backend-nodejs"
node -e "
const os = require('os');
console.log('✅ REAL HARDWARE DETECTED:');
console.log('  CPU Cores:', os.cpus().length);
console.log('  CPU Model:', os.cpus()[0].model);
console.log('  Architecture:', process.arch);
console.log('  Platform:', process.platform);
"

echo ""
echo "🎉 CryptoMiner Pro is now running natively on your hardware!"
echo "   The web interface will show your actual CPU cores (4 or 128)!"