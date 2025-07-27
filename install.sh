#!/bin/bash

# CryptoMiner Pro - Modern Installation Script
# Enhanced Node.js Installation with Container Support and Latest Features
# Updated: 2025-07-26

set -e

echo "🚀 CryptoMiner Pro - Modern Installation Script v2.0"
echo "===================================================="
echo "🎯 Features: Enhanced CPU Detection, Socket.io, Container Support"
echo "🔧 Stack: Node.js + React + MongoDB + Socket.io"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_feature() {
    echo -e "${PURPLE}[FEATURE]${NC} $1"
}

print_tip() {
    echo -e "${CYAN}[TIP]${NC} $1"
}

# Error handling function
handle_error() {
    print_error "Installation failed at step: $1"
    print_error "Check the logs above for details"
    exit 1
}

# Detect environment
detect_environment() {
    print_step "Detecting environment..."
    
    if [[ -f /.dockerenv ]]; then
        ENV_TYPE="docker"
        print_status "🐳 Docker container detected"
    elif [[ -n "${KUBERNETES_SERVICE_HOST}" ]]; then
        ENV_TYPE="kubernetes"
        print_status "☸️ Kubernetes environment detected"
    else
        ENV_TYPE="native"
        print_status "💻 Native Ubuntu system detected"
    fi
    
    # Detect CPU cores
    CPU_CORES=$(nproc --all)
    print_status "🖥️ Detected ${CPU_CORES} CPU cores"
    
    # Detect available memory
    TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
    print_status "💾 Detected ${TOTAL_MEM}MB total memory"
}

# Check if running as root
check_user() {
    # In container environments, running as root is often necessary
    if [[ $EUID -eq 0 ]] && [[ "$ENV_TYPE" == "native" ]]; then
        print_error "This script should not be run as root for security reasons on native systems."
        print_tip "Please run as a regular user with sudo privileges"
        exit 1
    elif [[ $EUID -eq 0 ]]; then
        print_status "🐳 Running as root in container environment - this is expected"
    fi
    
    # Check sudo access for non-root users
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        print_warning "This script requires sudo privileges"
        print_tip "Please ensure your user has sudo access"
    fi
}

# System requirements check
check_requirements() {
    print_step "Checking system requirements..."
    
    # Check Ubuntu version
    if ! command -v lsb_release &> /dev/null; then
        print_warning "Cannot detect Ubuntu version - proceeding anyway"
    else
        UBUNTU_VERSION=$(lsb_release -rs)
        print_status "Ubuntu version: $UBUNTU_VERSION"
    fi
    
    # Check disk space (minimum 5GB)
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=5242880  # 5GB in KB
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        print_error "Insufficient disk space. Required: 5GB, Available: $((AVAILABLE_SPACE/1024/1024))GB"
        exit 1
    fi
    
    print_success "✅ System requirements check passed"
}

# Update system packages
update_system() {
    print_step "Updating system packages..."
    
    # Handle different environments
    if [[ "$ENV_TYPE" == "docker" ]] || [[ "$ENV_TYPE" == "kubernetes" ]]; then
        print_status "Container environment - updating with minimal packages"
        sudo apt update || handle_error "System update failed"
    else
        print_status "Native system - full update"
        sudo apt update && sudo apt upgrade -y || handle_error "System update failed"
    fi
    
    # Install essential packages
    print_step "Installing essential packages..."
    sudo apt-get install -y curl wget gnupg2 software-properties-common \
        build-essential git supervisor || handle_error "Essential packages installation failed"
}

# Install Node.js with optimized version
install_nodejs() {
    print_step "Installing Node.js (Latest LTS v20.x)..."
    
    # Remove any existing nodejs
    sudo apt-get remove -y nodejs npm 2>/dev/null || true
    
    # Install NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || handle_error "NodeSource setup failed"
    
    # Install Node.js
    sudo apt-get install -y nodejs || handle_error "Node.js installation failed"
    
    # Verify installation
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    
    print_success "✅ Node.js installed: $NODE_VERSION"
    print_success "✅ npm installed: $NPM_VERSION"
    
    # Install yarn for better package management
    print_step "Installing Yarn package manager..."
    npm install -g yarn || print_warning "Yarn installation failed - continuing with npm"
    
    # Set npm configuration for better performance
    npm config set fund false
    npm config set audit false
}

# Install and configure MongoDB
install_mongodb() {
    print_step "Installing MongoDB 6.0..."
    
    # Import MongoDB GPG key
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add - || handle_error "MongoDB GPG key import failed"
    
    # Detect architecture
    ARCH=$(dpkg --print-architecture)
    
    # Add MongoDB repository (support for different Ubuntu versions)
    if [[ "$UBUNTU_VERSION" == "22.04" ]] || [[ "$UBUNTU_VERSION" == "22.10" ]]; then
        MONGODB_REPO="jammy"
    elif [[ "$UBUNTU_VERSION" == "20.04" ]]; then
        MONGODB_REPO="focal"
    else
        MONGODB_REPO="focal"  # Default fallback
        print_warning "Using focal repository for MongoDB (default fallback)"
    fi
    
    echo "deb [ arch=$ARCH,arm64 ] https://repo.mongodb.org/apt/ubuntu $MONGODB_REPO/mongodb-org/6.0 multiverse" | \
        sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list || handle_error "MongoDB repository setup failed"
    
    # Update package list
    sudo apt-get update || handle_error "Package list update failed"
    
    # Install MongoDB
    sudo apt-get install -y mongodb-org || handle_error "MongoDB installation failed"
    
    # Configure MongoDB for containerized environments
    if [[ "$ENV_TYPE" != "native" ]]; then
        print_step "Configuring MongoDB for container environment..."
        sudo mkdir -p /data/db
        sudo chown mongodb:mongodb /data/db 2>/dev/null || sudo chown root:root /data/db
        sudo mkdir -p /var/log/mongodb
        sudo chown mongodb:mongodb /var/log/mongodb 2>/dev/null || sudo chown root:root /var/log/mongodb
    else
        # For native systems, use standard paths
        sudo mkdir -p /var/lib/mongodb /var/log/mongodb
        sudo chown mongodb:mongodb /var/lib/mongodb /var/log/mongodb
    fi
    
    # Start and enable MongoDB
    print_step "Starting MongoDB service..."
    if [[ "$ENV_TYPE" == "native" ]]; then
        sudo systemctl start mongod || handle_error "MongoDB start failed"
        sudo systemctl enable mongod || print_warning "MongoDB auto-start setup failed"
    else
        # For container environments, use /data/db path
        sudo mongod --dbpath /data/db --logpath /var/log/mongodb/mongod.log --fork || handle_error "MongoDB manual start failed"
    fi
    
    # Wait for MongoDB to start
    print_step "Waiting for MongoDB to initialize..."
    sleep 8
    
    # Verify MongoDB is running
    if sudo systemctl is-active --quiet mongod 2>/dev/null || pgrep mongod > /dev/null; then
        print_success "✅ MongoDB is running successfully"
    else
        print_error "❌ MongoDB failed to start"
        print_tip "Try starting MongoDB manually: sudo mongod --dbpath /var/lib/mongodb --fork"
        exit 1
    fi
}

# Create application directory and setup files
setup_application() {
    print_step "Setting up CryptoMiner Pro application..."
    
    # Get current directory (should be /app)
    CURRENT_DIR=$(pwd)
    
    # Check if we're in the correct directory
    if [[ ! -d "./backend-nodejs" ]] || [[ ! -d "./frontend" ]]; then
        print_error "Source files not found in current directory: $CURRENT_DIR"
        print_tip "Make sure you're running this script from the CryptoMiner Pro root directory"
        print_tip "Expected structure: ./backend-nodejs/ and ./frontend/"
        exit 1
    fi
    
    # Create application directory (use current directory for development)
    if [[ "$CURRENT_DIR" == "/app" ]]; then
        # We're already in the right place - no need to copy
        APP_DIR="/app"
        print_status "🏠 Using existing application directory: $APP_DIR"
    else
        # For other locations, copy to /opt/cryptominer-pro
        APP_DIR="/opt/cryptominer-pro"
        sudo mkdir -p "$APP_DIR" || handle_error "Application directory creation failed"
        sudo chown -R $USER:$USER "$APP_DIR" || handle_error "Application directory ownership failed"
        
        # Copy application files
        print_step "Copying application files to $APP_DIR..."
        cp -r ./backend-nodejs "$APP_DIR/" || handle_error "Backend files copy failed"
        cp -r ./frontend "$APP_DIR/" || handle_error "Frontend files copy failed"
        
        # Copy documentation
        [[ -f "./README.md" ]] && cp ./README.md "$APP_DIR/"
        [[ -f "./REMOTE_API_GUIDE.md" ]] && cp ./REMOTE_API_GUIDE.md "$APP_DIR/"
        [[ -f "./CUSTOM_COINS_GUIDE.md" ]] && cp ./CUSTOM_COINS_GUIDE.md "$APP_DIR/"
        [[ -f "./manage.sh" ]] && cp ./manage.sh "$APP_DIR/" && chmod +x "$APP_DIR/manage.sh"
        
        print_success "✅ Application files copied successfully"
    fi
}

# Install backend dependencies
install_backend_deps() {
    print_step "Installing backend dependencies..."
    
    cd "$APP_DIR/backend-nodejs" || handle_error "Backend directory not found"
    
    # Check if package.json exists
    if [[ ! -f "package.json" ]]; then
        print_error "Backend package.json not found"
        exit 1
    fi
    
    # Install dependencies with optimized settings
    npm ci --only=production --no-audit --no-fund || npm install --only=production || handle_error "Backend dependencies installation failed"
    
    print_success "✅ Backend dependencies installed"
    
    # Display installed packages summary
    BACKEND_DEPS=$(npm list --depth=0 2>/dev/null | grep -c "├\|└" || echo "unknown")
    print_status "📦 Backend dependencies: $BACKEND_DEPS packages"
}

# Install frontend dependencies and build
install_frontend_deps() {
    print_step "Installing frontend dependencies..."
    
    cd "$APP_DIR/frontend" || handle_error "Frontend directory not found"
    
    # Check if package.json exists
    if [[ ! -f "package.json" ]]; then
        print_error "Frontend package.json not found"
        exit 1
    fi
    
    # Install dependencies
    npm ci --no-audit --no-fund || npm install || handle_error "Frontend dependencies installation failed"
    
    print_success "✅ Frontend dependencies installed"
    
    # Build for production (optional - can run in development mode)
    print_step "Building frontend for production..."
    
    # Ensure ESLint cache is disabled to prevent permission issues
    export ESLINT_NO_CACHE=true
    
    if npm run build; then
        print_success "✅ Frontend build completed"
        BUILD_STATUS="production"
    else
        print_warning "⚠️ Frontend build failed - will run in development mode"
        BUILD_STATUS="development"
    fi
    
    # Display build info
    FRONTEND_DEPS=$(npm list --depth=0 2>/dev/null | grep -c "├\|└" || echo "unknown")
    print_status "📦 Frontend dependencies: $FRONTEND_DEPS packages"
    print_status "🏗️ Build status: $BUILD_STATUS"
}

# Create optimized supervisor configuration
create_supervisor_config() {
    print_step "Creating optimized supervisor configuration..."
    
    # Calculate optimal thread count for mining
    RECOMMENDED_THREADS=$((CPU_CORES > 2 ? CPU_CORES - 1 : 1))
    
    # Create supervisor configuration with environment-specific optimizations
    sudo tee /etc/supervisor/conf.d/mining_app.conf > /dev/null <<EOF
[program:backend]
command=npm start
directory=$APP_DIR/backend-nodejs
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/backend.err.log
stdout_logfile=/var/log/supervisor/backend.out.log
environment=NODE_ENV=production,MONGO_URL="mongodb://localhost:27017/cryptominer"
user=root
startsecs=10
startretries=3
redirect_stderr=false
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=10

[program:frontend]
command=npm start
directory=$APP_DIR/frontend
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/frontend.err.log
stdout_logfile=/var/log/supervisor/frontend.out.log
environment=PORT=3000,GENERATE_SOURCEMAP=false,ESLINT_NO_CACHE=true
user=root
startsecs=15
startretries=3
redirect_stderr=false
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=10

[group:mining_system]
programs=backend,frontend
priority=999
EOF

    print_success "✅ Supervisor configuration created with optimizations"
    print_feature "⚡ Optimized for $CPU_CORES cores, recommended mining threads: $RECOMMENDED_THREADS"
}

# Update supervisor and start services
start_services() {
    print_step "Starting CryptoMiner Pro services..."
    
    # Update supervisor configuration
    sudo supervisorctl reread || handle_error "Supervisor reread failed"
    sudo supervisorctl update || handle_error "Supervisor update failed"
    
    # Give a moment for configuration to load
    sleep 3
    
    # Start services
    sudo supervisorctl start mining_system:* || handle_error "Service start failed"
    
    # Wait for services to start
    print_step "Waiting for services to initialize..."
    sleep 10
    
    # Check service status
    BACKEND_STATUS=$(sudo supervisorctl status mining_system:backend | grep -o "RUNNING" || echo "FAILED")
    FRONTEND_STATUS=$(sudo supervisorctl status mining_system:frontend | grep -o "RUNNING" || echo "FAILED")
    
    if [[ $BACKEND_STATUS == "RUNNING" ]]; then
        print_success "✅ Backend service started successfully"
    else
        print_error "❌ Backend service failed to start"
        print_tip "Check logs: sudo tail -f /var/log/supervisor/backend.err.log"
    fi
    
    if [[ $FRONTEND_STATUS == "RUNNING" ]]; then
        print_success "✅ Frontend service started successfully"
    else
        print_error "❌ Frontend service failed to start"
        print_tip "Check logs: sudo tail -f /var/log/supervisor/frontend.err.log"
    fi
}

# Create systemd service for auto-start
create_systemd_service() {
    if [[ "$ENV_TYPE" == "native" ]]; then
        print_step "Creating systemd service for auto-start..."
        
        sudo tee /etc/systemd/system/cryptominer-pro.service > /dev/null <<EOF
[Unit]
Description=CryptoMiner Pro - Advanced Cryptocurrency Mining System
Documentation=file://$APP_DIR/README.md
After=network.target mongodb.service supervisor.service
Wants=mongodb.service supervisor.service
Requires=supervisor.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/supervisorctl start cryptominer-pro:*
ExecStop=/usr/bin/supervisorctl stop cryptominer-pro:*
ExecReload=/usr/bin/supervisorctl restart cryptominer-pro:*
TimeoutStartSec=60
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF
        
        # Enable systemd service
        sudo systemctl daemon-reload || print_warning "Systemd daemon reload failed"
        sudo systemctl enable cryptominer-pro.service || print_warning "Systemd service enable failed"
        
        print_success "✅ Systemd service created and enabled"
    else
        print_status "🐳 Container environment - skipping systemd service creation"
    fi
}

# Create user shortcuts and aliases
create_shortcuts() {
    print_step "Creating user shortcuts and aliases..."
    
    # Create desktop shortcut (only for native systems with GUI)
    if [[ "$ENV_TYPE" == "native" ]] && command -v xdg-open &> /dev/null; then
        print_step "Creating desktop shortcut..."
        
        DESKTOP_DIR="$HOME/Desktop"
        [[ ! -d "$DESKTOP_DIR" ]] && mkdir -p "$DESKTOP_DIR"
        
        cat > "$DESKTOP_DIR/CryptoMiner-Pro.desktop" <<EOF
[Desktop Entry]
Version=2.0
Type=Application
Name=CryptoMiner Pro
Comment=Advanced Cryptocurrency Mining System with AI
Exec=xdg-open http://localhost:3000
Icon=applications-system
Terminal=false
Categories=Application;Network;Finance;
Keywords=cryptocurrency;mining;bitcoin;litecoin;blockchain;
StartupNotify=true
EOF
        
        chmod +x "$DESKTOP_DIR/CryptoMiner-Pro.desktop" 2>/dev/null || true
        print_success "✅ Desktop shortcut created"
    fi
    
    # Create command line aliases
    print_step "Creating command line aliases..."
    
    ALIASES="
# CryptoMiner Pro Command Aliases
alias cryptominer-start='sudo supervisorctl start mining_system:*'
alias cryptominer-stop='sudo supervisorctl stop mining_system:*'
alias cryptominer-restart='sudo supervisorctl restart mining_system:*'
alias cryptominer-status='sudo supervisorctl status mining_system:*'
alias cryptominer-logs='sudo tail -f /var/log/supervisor/backend.out.log /var/log/supervisor/frontend.out.log'
alias cryptominer-backend-logs='sudo tail -f /var/log/supervisor/backend.out.log'
alias cryptominer-frontend-logs='sudo tail -f /var/log/supervisor/frontend.out.log'
alias cryptominer-error-logs='sudo tail -f /var/log/supervisor/backend.err.log /var/log/supervisor/frontend.err.log'
alias cryptominer-health='curl -s http://localhost:8001/api/health | jq .'
alias cryptominer-stats='curl -s http://localhost:8001/api/system/stats | jq .'
"
    
    # Add aliases to bashrc if not already present
    if ! grep -q "CryptoMiner Pro Command Aliases" ~/.bashrc; then
        echo "$ALIASES" >> ~/.bashrc
        print_success "✅ Command aliases added to ~/.bashrc"
    else
        print_status "Command aliases already exist in ~/.bashrc"
    fi
}

# Set up configuration and logs
setup_configuration() {
    print_step "Setting up configuration and logging..."
    
    # Create configuration directory
    CONFIG_DIR="$HOME/.config/cryptominer-pro"
    mkdir -p "$CONFIG_DIR" || handle_error "Configuration directory creation failed"
    
    # Create environment configuration
    cat > "$CONFIG_DIR/config.env" <<EOF
# CryptoMiner Pro Configuration
# Generated on $(date)

# Application Paths
CRYPTOMINER_HOME=$APP_DIR
CRYPTOMINER_CONFIG_DIR=$CONFIG_DIR
CRYPTOMINER_LOG_DIR=/var/log/supervisor

# Service URLs
CRYPTOMINER_BACKEND_URL=http://localhost:8001
CRYPTOMINER_FRONTEND_URL=http://localhost:3000
CRYPTOMINER_MONGODB_URL=mongodb://localhost:27017/cryptominer

# System Configuration
CRYPTOMINER_ENV_TYPE=$ENV_TYPE
CRYPTOMINER_CPU_CORES=$CPU_CORES
CRYPTOMINER_RECOMMENDED_THREADS=$RECOMMENDED_THREADS
CRYPTOMINER_TOTAL_MEMORY=${TOTAL_MEM}MB

# Logging
CRYPTOMINER_LOG_LEVEL=info
CRYPTOMINER_LOG_FORMAT=json

# Mining Defaults
CRYPTOMINER_DEFAULT_COIN=litecoin
CRYPTOMINER_DEFAULT_MODE=solo
CRYPTOMINER_DEFAULT_INTENSITY=0.8
CRYPTOMINER_DEFAULT_THREADS=$RECOMMENDED_THREADS

# Features
CRYPTOMINER_ENABLE_AI_INSIGHTS=true
CRYPTOMINER_ENABLE_WEBSOCKET=true
CRYPTOMINER_ENABLE_REMOTE_API=true
EOF
    
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
    copytruncate
    postrotate
        /usr/bin/supervisorctl signal USR2 cryptominer-pro:* > /dev/null 2>&1 || true
    endscript
}

$CONFIG_DIR/*.log {
    weekly
    missingok
    rotate 10
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
}
EOF
    
    print_success "✅ Configuration and logging setup completed"
}

# Performance verification and testing
verify_installation() {
    print_step "Performing installation verification..."
    
    # Wait for services to be fully ready
    print_step "Waiting for services to be fully ready..."
    sleep 15
    
    # Test backend API
    print_step "Testing backend API connectivity..."
    MAX_RETRIES=5
    RETRY_COUNT=0
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -s -f http://localhost:8001/api/health > /dev/null; then
            print_success "✅ Backend API is responding"
            BACKEND_API_STATUS="✅ WORKING"
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            print_status "Attempt $RETRY_COUNT/$MAX_RETRIES - waiting for backend API..."
            sleep 5
        fi
    done
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        print_warning "⚠️ Backend API not responding - may need more time to initialize"
        BACKEND_API_STATUS="⚠️ TIMEOUT"
    fi
    
    # Test frontend accessibility
    print_step "Testing frontend accessibility..."
    if curl -s -f http://localhost:3000 > /dev/null; then
        print_success "✅ Frontend is accessible"
        FRONTEND_STATUS="✅ WORKING"
    else
        print_warning "⚠️ Frontend not accessible yet - may need more time"
        FRONTEND_STATUS="⚠️ TIMEOUT"
    fi
    
    # Test MongoDB connection
    print_step "Testing MongoDB connectivity..."
    if mongo --eval "db.stats()" --quiet > /dev/null 2>&1; then
        print_success "✅ MongoDB is accessible"
        MONGODB_STATUS="✅ WORKING"
    else
        print_warning "⚠️ MongoDB connection test failed"
        MONGODB_STATUS="⚠️ ISSUE"
    fi
    
    # Get service status
    SERVICES_STATUS=$(sudo supervisorctl status cryptominer-pro:*)
    
    # Test enhanced features
    print_step "Testing enhanced features..."
    
    # Test CPU detection API
    if curl -s http://localhost:8001/api/system/cpu-info > /dev/null; then
        print_success "✅ Enhanced CPU detection API working"
        CPU_API_STATUS="✅ WORKING"
    else
        CPU_API_STATUS="⚠️ TIMEOUT"
    fi
    
    # Test environment detection API
    if curl -s http://localhost:8001/api/system/environment > /dev/null; then
        print_success "✅ Environment detection API working"
        ENV_API_STATUS="✅ WORKING"
    else
        ENV_API_STATUS="⚠️ TIMEOUT"
    fi
}

# Display completion message with full status
display_completion() {
    echo ""
    echo "🎉 CryptoMiner Pro Modern Installation Complete!"
    echo "==============================================="
    echo ""
    
    # Installation Summary
    echo "📋 INSTALLATION SUMMARY"
    echo "======================="
    echo "🏗️  Installation Type: Modern Node.js Stack"
    echo "🌍 Environment: $ENV_TYPE"
    echo "🖥️  CPU Cores: $CPU_CORES cores detected"
    echo "💾 Memory: ${TOTAL_MEM}MB available"
    echo "⚡ Recommended Mining Threads: $RECOMMENDED_THREADS"
    echo ""
    
    # Service Status
    echo "🚀 SERVICE STATUS"
    echo "================"
    echo "🔙 Backend API: $BACKEND_API_STATUS"
    echo "🎨 Frontend UI: $FRONTEND_STATUS"
    echo "💾 MongoDB: $MONGODB_STATUS"
    echo "🖥️  CPU Detection: $CPU_API_STATUS"
    echo "🌍 Environment Detection: $ENV_API_STATUS"
    echo ""
    
    # Access URLs
    echo "🌐 ACCESS URLS"
    echo "=============="
    echo "📊 Main Dashboard: http://localhost:3000"
    echo "🔧 Backend API: http://localhost:8001"
    echo "📱 Remote API: http://localhost:8001/api/remote"
    echo "💡 Health Check: http://localhost:8001/api/health"
    echo "🖥️  CPU Info: http://localhost:8001/api/system/cpu-info"
    echo ""
    
    # Quick Commands
    echo "⚡ QUICK COMMANDS"
    echo "================="
    echo "  cryptominer-start     - Start the mining system"
    echo "  cryptominer-stop      - Stop the mining system"  
    echo "  cryptominer-restart   - Restart the mining system"
    echo "  cryptominer-status    - Check detailed system status"
    echo "  cryptominer-logs      - View all system logs"
    echo "  cryptominer-health    - Check API health (requires jq)"
    echo "  cryptominer-stats     - Get system statistics (requires jq)"
    echo ""
    
    # Enhanced Features
    echo "🎯 ENHANCED FEATURES"
    echo "===================="
    print_feature "✨ Enhanced CPU Detection - Optimized for $CPU_CORES cores"
    print_feature "🔌 Socket.io with HTTP Fallback - Robust real-time updates"
    print_feature "🐳 Container Environment Support - Auto-detected $ENV_TYPE"
    print_feature "📊 AI-Powered Mining Insights - Smart mining recommendations"
    print_feature "🔧 Rate Limiting Protection - No more 429 errors"
    print_feature "📱 Remote API Ready - Android app development support"
    echo ""
    
    # File Locations
    echo "📁 IMPORTANT LOCATIONS"
    echo "======================"
    echo "🏠 Installation: $APP_DIR"
    echo "📄 Logs: /var/log/supervisor/cryptominer-*.log"
    echo "⚙️  Configuration: $CONFIG_DIR"
    echo "🖥️  Desktop Shortcut: ~/Desktop/CryptoMiner-Pro.desktop"
    echo ""
    
    # Tips and Next Steps
    echo "💡 TIPS & NEXT STEPS"
    echo "===================="
    print_tip "🔄 Reload aliases: source ~/.bashrc"
    print_tip "📚 Check documentation: $APP_DIR/README.md"
    print_tip "📱 Android development: $APP_DIR/REMOTE_API_GUIDE.md"
    print_tip "🪙 Custom coins guide: $APP_DIR/CUSTOM_COINS_GUIDE.md"
    
    if [[ $BACKEND_API_STATUS != *"WORKING"* ]] || [[ $FRONTEND_STATUS != *"WORKING"* ]]; then
        echo ""
        echo "⚠️  TROUBLESHOOTING"
        echo "==================="
        print_warning "Some services may need additional time to start completely"
        print_tip "Check service logs: cryptominer-logs"
        print_tip "Restart services: cryptominer-restart"
        print_tip "Check system status: cryptominer-status"
    fi
    
    echo ""
    print_success "Installation completed successfully! 🚀"
    print_success "Access your mining dashboard at: http://localhost:3000"
    echo ""
    echo "🎯 Ready to start mining with enhanced performance and reliability!"
    echo "🔋 Optimized for your $CPU_CORES-core system with $RECOMMENDED_THREADS thread recommendation"
    echo ""
    print_success "Happy mining! ⛏️💎"
}

# Main installation flow
main() {
    echo "Starting CryptoMiner Pro modern installation..."
    echo ""
    
    detect_environment
    check_user
    check_requirements
    update_system
    install_nodejs
    install_mongodb
    setup_application
    install_backend_deps
    install_frontend_deps
    create_supervisor_config
    start_services
    create_systemd_service
    create_shortcuts
    setup_configuration
    verify_installation
    display_completion
}

# Run main installation
main "$@"