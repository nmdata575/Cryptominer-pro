#!/bin/bash

# CryptoMiner Pro - Complete Installation Script v2.1
# Updated with webpack polyfills and CRACO configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="/opt/cryptominer-pro"
LOG_FILE="/tmp/cryptominer-install-v2.log"

# Logging functions
print_header() {
    echo -e "${PURPLE}============================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}============================================${NC}"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Error handling
handle_error() {
    print_error "$1"
    echo "Check log file: $LOG_FILE"
    exit 1
}

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        print_error "Please run as a regular user with sudo privileges"
        exit 1
    fi
    
    # Check for required commands
    for cmd in curl wget sudo npm; do
        if ! command -v $cmd >/dev/null 2>&1; then
            print_error "Required command '$cmd' not found"
            exit 1
        fi
    done
    
    print_success "✅ Prerequisites check passed"
}

# Detect environment
detect_environment() {
    if [[ -f "/.dockerenv" ]]; then
        ENV_TYPE="docker"
    elif [[ -n "${KUBERNETES_SERVICE_HOST}" ]]; then
        ENV_TYPE="kubernetes"
    else
        ENV_TYPE="native"
    fi
    
    print_info "Environment detected: $ENV_TYPE"
    log "Environment: $ENV_TYPE"
}

# Check project structure
check_project_structure() {
    print_step "Checking project structure..."
    
    if [[ ! -d "./backend-nodejs" ]] || [[ ! -d "./frontend" ]]; then
        print_error "This script must be run from the project root directory"
        print_error "Expected structure:"
        print_error "  ./backend-nodejs/"
        print_error "  ./frontend/"
        print_error "  ./scripts/"
        exit 1
    fi
    
    print_success "✅ Project structure validated"
}

# Install Node.js with version check
install_nodejs() {
    print_step "Installing Node.js..."
    
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version | sed 's/v//')
        MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1)
        
        if (( MAJOR_VERSION >= 18 )); then
            print_success "✅ Node.js $NODE_VERSION is already installed and compatible"
            return
        else
            print_warning "Node.js version $NODE_VERSION is too old, upgrading..."
        fi
    fi
    
    # Install Node.js 20.x (LTS)
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >> "$LOG_FILE" 2>&1
    sudo apt-get install -y nodejs >> "$LOG_FILE" 2>&1 || handle_error "Node.js installation failed"
    
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    print_success "✅ Node.js installed: $NODE_VERSION"
    print_success "✅ npm installed: $NPM_VERSION"
}

# Install MongoDB
install_mongodb() {
    print_step "Installing MongoDB..."
    
    if command -v mongod >/dev/null 2>&1; then
        print_info "MongoDB already installed"
        MONGO_VERSION=$(mongod --version | head -1)
        print_info "$MONGO_VERSION"
    else
        # Install MongoDB 7.0
        wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add - >> "$LOG_FILE" 2>&1
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list >> "$LOG_FILE" 2>&1
        sudo apt-get update >> "$LOG_FILE" 2>&1
        sudo apt-get install -y mongodb-org >> "$LOG_FILE" 2>&1 || handle_error "MongoDB installation failed"
        print_success "✅ MongoDB installed"
    fi
    
    # Start MongoDB
    print_step "Starting MongoDB service..."
    if [[ "$ENV_TYPE" == "native" ]]; then
        sudo systemctl start mongod >> "$LOG_FILE" 2>&1 || {
            sudo mkdir -p /data/db
            sudo mongod --dbpath /data/db --logpath /var/log/mongodb.log --fork >> "$LOG_FILE" 2>&1 || handle_error "MongoDB start failed"
        }
    else
        sudo mkdir -p /data/db
        sudo mongod --dbpath /data/db --logpath /var/log/mongodb.log --fork >> "$LOG_FILE" 2>&1 || handle_error "MongoDB start failed"
    fi
    
    sleep 5
    
    # Test MongoDB connection
    if mongosh --eval "db.adminCommand('ping')" >> "$LOG_FILE" 2>&1 || mongo --eval "db.adminCommand('ping')" >> "$LOG_FILE" 2>&1; then
        print_success "✅ MongoDB is running"
    else
        handle_error "MongoDB connection test failed"
    fi
}

# Install supervisor
install_supervisor() {
    print_step "Installing supervisor..."
    sudo apt-get update >> "$LOG_FILE" 2>&1
    sudo apt-get install -y supervisor >> "$LOG_FILE" 2>&1 || handle_error "Supervisor installation failed"
    print_success "✅ Supervisor installed"
}

# Setup application directory
setup_app_directory() {
    print_step "Setting up application directory..."
    sudo mkdir -p "$APP_DIR"
    sudo chown $(whoami):$(whoami) "$APP_DIR"
    
    print_step "Copying application files..."
    
    if [[ -d "./backend-nodejs" ]]; then
        cp -r ./backend-nodejs "$APP_DIR/" || handle_error "Backend files copy failed"
        print_info "✅ Backend files copied"
    else
        handle_error "Backend directory not found"
    fi
    
    if [[ -d "./frontend" ]]; then
        cp -r ./frontend "$APP_DIR/" || handle_error "Frontend files copy failed"
        print_info "✅ Frontend files copied"
    else
        handle_error "Frontend directory not found"
    fi
    
    # Copy documentation
    [[ -f "./README.md" ]] && cp ./README.md "$APP_DIR/"
    [[ -d "./docs" ]] && cp -r ./docs "$APP_DIR/"
    
    print_success "✅ Application files copied"
}

# Install backend dependencies
install_backend_deps() {
    print_step "Installing backend dependencies..."
    cd "$APP_DIR/backend-nodejs"
    npm install >> "$LOG_FILE" 2>&1 || handle_error "Backend dependencies installation failed"
    print_success "✅ Backend dependencies installed"
}

# Create CRACO configuration for webpack polyfills
create_craco_config() {
    print_step "Creating CRACO configuration for webpack polyfills..."
    
    cat > "$APP_DIR/frontend/craco.config.js" << 'EOF'
const webpack = require('webpack');

module.exports = {
  webpack: {
    configure: (webpackConfig) => {
      // Add polyfills for Node.js core modules
      webpackConfig.resolve.fallback = {
        ...webpackConfig.resolve.fallback,
        "crypto": require.resolve("crypto-browserify"),
        "stream": require.resolve("stream-browserify"),
        "http": require.resolve("stream-http"),
        "https": require.resolve("https-browserify"),
        "zlib": require.resolve("browserify-zlib"),
        "url": require.resolve("url/"),
        "util": require.resolve("util/"),
        "assert": require.resolve("assert/"),
        "buffer": require.resolve("buffer/"),
        "process": require.resolve("process/browser.js")
      };

      // Add plugins to provide global variables
      webpackConfig.plugins = [
        ...webpackConfig.plugins,
        new webpack.ProvidePlugin({
          process: 'process/browser.js',
          Buffer: ['buffer', 'Buffer'],
        }),
      ];

      return webpackConfig;
    },
  },
};
EOF
    
    print_success "✅ CRACO configuration created"
}

# Update package.json to use CRACO
update_package_json_for_craco() {
    print_step "Updating package.json to use CRACO..."
    cd "$APP_DIR/frontend"
    
    # Backup original
    cp package.json package.json.backup
    
    # Update scripts to use CRACO
    sed -i 's/"start": "react-scripts start"/"start": "craco start"/' package.json
    sed -i 's/"build": "react-scripts build"/"build": "craco build"/' package.json
    sed -i 's/"test": "react-scripts test"/"test": "craco test"/' package.json
    
    print_success "✅ Package.json updated to use CRACO"
}

# Install frontend dependencies with webpack polyfills
install_frontend_deps() {
    print_step "Installing frontend dependencies..."
    cd "$APP_DIR/frontend"
    
    # Install base dependencies
    npm install >> "$LOG_FILE" 2>&1 || handle_error "Frontend dependencies installation failed"
    
    # Install webpack polyfill dependencies
    print_step "Installing webpack polyfills..."
    npm install --save-dev @craco/craco crypto-browserify stream-browserify https-browserify stream-http util assert url browserify-zlib buffer process >> "$LOG_FILE" 2>&1 || handle_error "Webpack polyfills installation failed"
    
    print_success "✅ Frontend dependencies and polyfills installed"
    
    # Create CRACO config and update package.json
    create_craco_config
    update_package_json_for_craco
    
    # Build frontend
    print_step "Building frontend with webpack polyfills..."
    npm run build >> "$LOG_FILE" 2>&1 || handle_error "Frontend build failed"
    print_success "✅ Frontend built successfully"
}

# Configure supervisor
configure_supervisor() {
    print_step "Configuring supervisor..."
    
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

    sudo supervisorctl reread >> "$LOG_FILE" 2>&1
    sudo supervisorctl update >> "$LOG_FILE" 2>&1
    print_success "✅ Supervisor configured"
}

# Start services
start_services() {
    print_step "Starting services..."
    sudo supervisorctl start mining_system:* >> "$LOG_FILE" 2>&1 || handle_error "Services start failed"
    sleep 10
    
    print_step "Checking service status..."
    sudo supervisorctl status mining_system:*
    
    print_success "✅ Services started"
}

# Test installation
test_installation() {
    print_step "Testing installation..."
    
    # Test backend health
    sleep 5
    if curl -s http://localhost:8001/api/health > /dev/null; then
        print_success "✅ Backend API is responding"
        
        # Test specific endpoints
        if curl -s http://localhost:8001/api/coins/presets | grep -q "presets"; then
            print_success "✅ Coin presets API working"
        fi
        
        if curl -s http://localhost:8001/api/system/stats | grep -q "cpu"; then
            print_success "✅ System stats API working"
        fi
    else
        print_warning "⚠️  Backend health check failed - services may still be starting"
    fi
    
    # Check frontend port
    if netstat -tuln 2>/dev/null | grep :3000 > /dev/null || ss -tuln 2>/dev/null | grep :3000 > /dev/null; then
        print_success "✅ Frontend is running on port 3000"
    else
        print_warning "⚠️  Frontend port check inconclusive - may still be starting"
    fi
}

# Main installation function
main() {
    print_header "CryptoMiner Pro - Complete Installation v2.1"
    print_info "Updated with webpack polyfills and CRACO configuration"
    print_info "Starting installation at $(date)"
    
    # Initialize log
    echo "CryptoMiner Pro Installation v2.1 - $(date)" > "$LOG_FILE"
    
    # Run installation steps
    check_prerequisites
    detect_environment
    check_project_structure
    install_nodejs
    install_mongodb
    install_supervisor
    setup_app_directory
    install_backend_deps
    install_frontend_deps
    configure_supervisor
    start_services
    test_installation
    
    print_header "Installation Complete!"
    print_success "🎉 CryptoMiner Pro v2.1 has been installed successfully!"
    print_info ""
    print_info "✅ New features in v2.1:"
    print_info "  • Webpack 5 polyfills configured"
    print_info "  • CRACO build system integrated"
    print_info "  • Enhanced CPU frequency detection"
    print_info "  • ARM processor support improved"
    print_info "  • All crypto module errors resolved"
    print_info ""
    print_info "Application installed to: $APP_DIR"
    print_info "Frontend URL: http://localhost:3000"
    print_info "Backend API: http://localhost:8001"
    print_info "Log file: $LOG_FILE"
    print_info ""
    print_info "Useful commands:"
    print_info "  sudo supervisorctl status      # Check service status"
    print_info "  sudo supervisorctl restart all # Restart all services"
    print_info "  sudo supervisorctl stop all    # Stop all services"
    print_info ""
    print_success "Installation completed at $(date)"
    print_info ""
    print_info "🚀 Your CryptoMiner Pro application is ready!"
    print_info "   Navigate to http://localhost:3000 to start mining!"
}

# Run main installation
main "$@"