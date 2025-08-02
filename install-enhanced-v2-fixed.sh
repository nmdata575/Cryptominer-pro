#!/bin/bash

# =============================================================================
# CryptoMiner Pro - Enhanced Installation Script v2.1 (Fixed)
# Advanced Scrypt Mining Platform with AI Optimization
# =============================================================================
# 
# Features:
# ✅ ricmoo-scrypt Integration - Real hash generation for cryptocurrency mining
# ✅ Enhanced AI System - Machine learning optimization and predictions
# ✅ Real Pool Mining - Connect to actual mining pools (ltc.millpools.cc:3567)
# ✅ MongoDB Integration - Persistent data storage with Mongoose
# ✅ Node.js Backend - High-performance mining engine
# ✅ React Frontend - Professional mining dashboard
# ✅ User-specific Installation - Installs to user home directory
# 
# Supported Systems: Ubuntu 20.04+, Debian 11+, CentOS 8+
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="2.1.0"
PROJECT_NAME="CryptoMiner Pro"
CURRENT_USER=$(whoami)
USER_HOME=$HOME
INSTALL_DIR="$USER_HOME/Cryptominer-pro"
LOG_DIR="$USER_HOME/.local/log/cryptominer"
SERVICE_USER="$CURRENT_USER"
INSTALL_LOG="$LOG_DIR/install.log"
BACKUP_DIR="$USER_HOME/.local/cryptominer-backup-$(date +%Y%m%d_%H%M%S)"

# System requirements
MIN_RAM_GB=2
MIN_DISK_GB=5
REQUIRED_CORES=2

# Node.js and package versions
NODE_VERSION="20"
MONGODB_VERSION="8.0"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $message"
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$INSTALL_LOG")" 2>/dev/null || true
    echo "[$timestamp] $message" >> "$INSTALL_LOG" 2>/dev/null || true
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $message" >&2
    echo "[$timestamp] ERROR: $message" >> "$INSTALL_LOG" 2>/dev/null || true
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARNING]${NC} $message"
    echo "[$timestamp] WARNING: $message" >> "$INSTALL_LOG" 2>/dev/null || true
}

log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[INFO]${NC} $message"
    echo "[$timestamp] INFO: $message" >> "$INSTALL_LOG" 2>/dev/null || true
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message ✅"
}

error_exit() {
    log_error "$1"
    echo -e "\n${RED}Installation failed!${NC} Check the log at: $INSTALL_LOG" >&2
    cleanup_on_error
    exit 1
}

cleanup_on_error() {
    log_info "Cleaning up after error..."
    
    # Stop any started services
    sudo supervisorctl stop all 2>/dev/null || true
    
    # Remove incomplete installation
    if [[ -d "$INSTALL_DIR" ]]; then
        log_info "Removing incomplete installation directory..."
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
    fi
}

check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root. Please run as a regular user."
    fi
    
    # Check operating system
    if [[ ! -f /etc/os-release ]]; then
        error_exit "Cannot determine operating system. /etc/os-release not found."
    fi
    
    source /etc/os-release
    case "$ID" in
        ubuntu|debian)
            log_info "Detected $PRETTY_NAME"
            PACKAGE_MANAGER="apt"
            ;;
        centos|rhel|fedora)
            log_info "Detected $PRETTY_NAME" 
            PACKAGE_MANAGER="yum"
            ;;
        *)
            error_exit "Unsupported operating system: $PRETTY_NAME"
            ;;
    esac
    
    # Check RAM
    local ram_gb=$(free -g | awk 'NR==2{printf "%.0f", $2}')
    if [[ $ram_gb -lt $MIN_RAM_GB ]]; then
        error_exit "Insufficient RAM: ${ram_gb}GB available, ${MIN_RAM_GB}GB required"
    fi
    log_info "RAM check passed: ${ram_gb}GB available"
    
    # Check disk space
    local disk_gb=$(df -BG "$USER_HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $disk_gb -lt $MIN_DISK_GB ]]; then
        error_exit "Insufficient disk space: ${disk_gb}GB available, ${MIN_DISK_GB}GB required"
    fi
    log_info "Disk space check passed: ${disk_gb}GB available"
    
    # Check CPU cores
    local cores=$(nproc)
    if [[ $cores -lt $REQUIRED_CORES ]]; then
        error_exit "Insufficient CPU cores: $cores available, $REQUIRED_CORES required"
    fi
    log_info "CPU check passed: $cores cores available"
    
    log_success "System requirements check passed"
}

create_directories() {
    log_info "Creating application directories..."
    
    # Create main directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$USER_HOME/.local/bin"
    mkdir -p "$USER_HOME/.local/share/cryptominer"
    
    # Create log files with proper permissions (no chown needed in user directory)
    touch "$LOG_DIR/install.log"
    touch "$LOG_DIR/backend.log"
    touch "$LOG_DIR/frontend.log" 
    touch "$LOG_DIR/backend-error.log"
    touch "$LOG_DIR/frontend-error.log"
    
    # Set proper permissions (user already owns these files)
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$LOG_DIR"
    chmod 644 "$LOG_DIR"/*.log
    
    log_success "Application directories created"
}

install_system_packages() {
    log_info "Installing system packages..."
    
    if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
        # Update package list
        sudo apt update
        
        # Install required packages
        sudo apt install -y \
            curl \
            wget \
            git \
            build-essential \
            python3 \
            python3-pip \
            supervisor \
            nginx \
            htop \
            unzip \
            software-properties-common \
            gnupg \
            lsb-release
            
        log_success "System packages installed"
        
    elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
        # Install required packages
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y \
            curl \
            wget \
            git \
            python3 \
            python3-pip \
            supervisor \
            nginx \
            htop \
            unzip \
            epel-release
            
        log_success "System packages installed"
    fi
}

install_nodejs() {
    log_info "Installing Node.js $NODE_VERSION..."
    
    # Install Node.js using NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
    sudo apt install -y nodejs
    
    # Verify installation
    local node_ver=$(node --version 2>/dev/null || echo "not installed")
    local npm_ver=$(npm --version 2>/dev/null || echo "not installed")
    
    log_info "Node.js version: $node_ver"
    log_info "npm version: $npm_ver"
    
    if [[ "$node_ver" == "not installed" ]]; then
        error_exit "Node.js installation failed"
    fi
    
    # Install global packages
    sudo npm install -g yarn pm2
    
    log_success "Node.js installation completed"
}

install_mongodb() {
    log_info "Installing MongoDB $MONGODB_VERSION..."
    
    # Install MongoDB 8.0
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
    
    sudo apt update
    sudo apt install -y mongodb-org
    
    # Start and enable MongoDB
    sudo systemctl start mongod
    sudo systemctl enable mongod
    
    # Wait for MongoDB to start
    sleep 5
    
    # Verify MongoDB is running
    if ! sudo systemctl is-active --quiet mongod; then
        error_exit "MongoDB failed to start"
    fi
    
    log_success "MongoDB $MONGODB_VERSION installed and running"
}

configure_service_user() {
    log_info "Using current user for services: $CURRENT_USER..."
    
    # No need to create user since we're using current user
    # Just verify current user exists and has proper permissions
    if ! id "$CURRENT_USER" &>/dev/null; then
        error_exit "Current user $CURRENT_USER does not exist"
    fi
    
    log_success "Service user configured: $CURRENT_USER"
}

install_application() {
    log_info "Installing CryptoMiner Pro application..."
    
    # Determine script location and find application files
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
    
    # Look for application files in multiple possible locations
    APP_SOURCE=""
    
    if [[ -d "$SCRIPT_DIR/backend-nodejs" && -d "$SCRIPT_DIR/frontend" ]]; then
        APP_SOURCE="$SCRIPT_DIR"
        log_info "Found application files in script directory: $SCRIPT_DIR"
    elif [[ -d "/app/backend-nodejs" && -d "/app/frontend" ]]; then
        APP_SOURCE="/app"
        log_info "Found application files in /app directory"
    elif [[ -d "$(pwd)/backend-nodejs" && -d "$(pwd)/frontend" ]]; then
        APP_SOURCE="$(pwd)"
        log_info "Found application files in current directory: $(pwd)"
    else
        # Try to find the files in parent directories
        for dir in "$SCRIPT_DIR/.." "$SCRIPT_DIR/../.." "/opt/cryptominer-pro" "/root/Cryptominer-pro"; do
            if [[ -d "$dir/backend-nodejs" && -d "$dir/frontend" ]]; then
                APP_SOURCE="$dir"
                log_info "Found application files in: $dir"
                break
            fi
        done
    fi
    
    if [[ -z "$APP_SOURCE" ]]; then
        log_error "Could not find application files. Searched in:"
        log_error "  - $SCRIPT_DIR (script directory)"
        log_error "  - /app (default development location)" 
        log_error "  - $(pwd) (current directory)"
        log_error "  - $SCRIPT_DIR/.. (parent directory)"
        log_error "  - /opt/cryptominer-pro (old installation)"
        log_error "  - /root/Cryptominer-pro (current installation)"
        error_exit "Application files not found. Please ensure backend-nodejs/ and frontend/ directories exist in one of the above locations."
    fi
    
    # Copy application files
    log_info "Copying application files from: $APP_SOURCE"
    cp -r "$APP_SOURCE/backend-nodejs" "$INSTALL_DIR/"
    cp -r "$APP_SOURCE/frontend" "$INSTALL_DIR/"
    
    # Copy additional files if they exist
    for file in package.json README.md *.md *.sh; do
        if [[ -f "$APP_SOURCE/$file" ]]; then
            cp "$APP_SOURCE/$file" "$INSTALL_DIR/" 2>/dev/null || true
        fi
    done
    
    # Set proper permissions (no chown needed for user directory)
    chmod -R 755 "$INSTALL_DIR"
    find "$INSTALL_DIR" -type f -name "*.js" -exec chmod 644 {} \;
    find "$INSTALL_DIR" -type f -name "*.json" -exec chmod 644 {} \;
    
    log_success "Application files installed from: $APP_SOURCE"
}

install_backend_dependencies() {
    log_info "Installing backend dependencies..."
    
    cd "$INSTALL_DIR/backend-nodejs"
    
    # Install dependencies
    if [[ -f "package.json" ]]; then
        npm install --production
        log_success "Backend dependencies installed"
    else
        error_exit "Backend package.json not found"
    fi
}

install_frontend_dependencies() {
    log_info "Installing frontend dependencies..."
    
    cd "$INSTALL_DIR/frontend"
    
    # Install dependencies
    if [[ -f "package.json" ]]; then
        npm install --production
        log_success "Frontend dependencies installed"
    else
        error_exit "Frontend package.json not found"
    fi
}

configure_environment() {
    log_info "Configuring environment files..."
    
    # Backend environment
    cat > "$INSTALL_DIR/backend-nodejs/.env" << EOF
# CryptoMiner Pro Backend Configuration
NODE_ENV=production
PORT=8001
HOST=0.0.0.0

# Database Configuration
MONGO_URL=mongodb://localhost:27017/cryptominer

# Mining Configuration
MAX_THREADS=256
ACTUAL_CPU_CORES=$(nproc)
FORCE_CPU_OVERRIDE=false
FORCE_PRODUCTION_MINING=true

# Logging
LOG_LEVEL=info
LOG_FILE=$LOG_DIR/backend.log

# Security
SECRET_KEY=$(openssl rand -hex 32)

# Performance
WORKER_PROCESSES=auto
MEMORY_LIMIT=1024
EOF

    # Frontend environment
    cat > "$INSTALL_DIR/frontend/.env" << EOF
# CryptoMiner Pro Frontend Configuration
REACT_APP_BACKEND_URL=http://localhost:8001
REACT_APP_API_BASE_URL=http://localhost:8001/api
GENERATE_SOURCEMAP=false
SKIP_PREFLIGHT_CHECK=true
EOF

    log_success "Environment files configured"
}

setup_supervisor() {
    log_info "Setting up Supervisor services..."
    
    # Backend service configuration
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

    # Frontend service configuration  
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
startsecs=15
startretries=3
stopwaitsecs=10
EOF

    # Reload supervisor configuration
    sudo supervisorctl reread
    sudo supervisorctl update
    
    log_success "Supervisor services configured"
}

configure_nginx() {
    log_info "Configuring Nginx reverse proxy..."
    
    # Create Nginx configuration
    sudo tee "/etc/nginx/sites-available/cryptominer" > /dev/null << EOF
server {
    listen 80;
    server_name localhost;
    
    # Frontend
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }
    
    # Backend API
    location /api {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }
    
    # WebSocket support
    location /socket.io/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Enable site
    sudo ln -sf /etc/nginx/sites-available/cryptominer /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload Nginx
    sudo nginx -t
    sudo systemctl reload nginx
    
    log_success "Nginx configured"
}

start_services() {
    log_info "Starting CryptoMiner Pro services..."
    
    # Start services
    sudo supervisorctl start cryptominer-backend
    sleep 5
    sudo supervisorctl start cryptominer-frontend
    sleep 5
    
    # Check service status
    local backend_status=$(sudo supervisorctl status cryptominer-backend | awk '{print $2}')
    local frontend_status=$(sudo supervisorctl status cryptominer-frontend | awk '{print $2}')
    
    if [[ "$backend_status" == "RUNNING" ]]; then
        log_success "Backend service started"
    else
        log_error "Backend service failed to start: $backend_status"
    fi
    
    if [[ "$frontend_status" == "RUNNING" ]]; then
        log_success "Frontend service started"
    else
        log_error "Frontend service failed to start: $frontend_status"
    fi
}

test_installation() {
    log_info "Testing installation..."
    
    # Test backend API
    local max_attempts=10
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f http://localhost:8001/api/health &>/dev/null; then
            log_success "Backend API is responding"
            break
        else
            log_info "Waiting for backend API... (attempt $attempt/$max_attempts)"
            sleep 5
            ((attempt++))
        fi
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        log_error "Backend API failed to respond after $max_attempts attempts"
        return 1
    fi
    
    # Test frontend
    if curl -f http://localhost:3000 &>/dev/null; then
        log_success "Frontend is responding"
    else
        log_warning "Frontend may take a few more minutes to fully load"
    fi
    
    # Test Nginx proxy
    if curl -f http://localhost/ &>/dev/null; then
        log_success "Nginx proxy is working"
    else
        log_warning "Nginx proxy may need additional configuration"
    fi
    
    return 0
}

create_management_scripts() {
    log_info "Creating management scripts..."
    
    # Main management script
    cat > "$USER_HOME/.local/bin/cryptominer" << 'EOF'
#!/bin/bash
# CryptoMiner Pro Management Script

INSTALL_DIR="$HOME/Cryptominer-pro"
LOG_DIR="$HOME/.local/log/cryptominer"

case "$1" in
    start)
        echo "Starting CryptoMiner Pro..."
        sudo supervisorctl start cryptominer-backend cryptominer-frontend
        ;;
    stop)
        echo "Stopping CryptoMiner Pro..."
        sudo supervisorctl stop cryptominer-backend cryptominer-frontend
        ;;
    restart)
        echo "Restarting CryptoMiner Pro..."
        sudo supervisorctl restart cryptominer-backend cryptominer-frontend
        ;;
    status)
        echo "CryptoMiner Pro Status:"
        sudo supervisorctl status cryptominer-backend cryptominer-frontend
        ;;
    logs)
        echo "Recent backend logs:"
        tail -50 "$LOG_DIR/backend.log"
        echo -e "\nRecent frontend logs:"
        tail -50 "$LOG_DIR/frontend.log"
        ;;
    update)
        echo "Updating CryptoMiner Pro..."
        cd "$INSTALL_DIR/backend-nodejs" && npm update
        cd "$INSTALL_DIR/frontend" && npm update
        sudo supervisorctl restart cryptominer-backend cryptominer-frontend
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|update}"
        echo "  start   - Start all services"
        echo "  stop    - Stop all services"  
        echo "  restart - Restart all services"
        echo "  status  - Show service status"
        echo "  logs    - Show recent logs"
        echo "  update  - Update dependencies and restart"
        exit 1
        ;;
esac
EOF

    chmod +x "$USER_HOME/.local/bin/cryptominer"
    
    # Add ~/.local/bin to PATH if not already there
    if ! echo "$PATH" | grep -q "$USER_HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.bashrc"
        log_info "Added ~/.local/bin to PATH in .bashrc"
    fi
    
    log_success "Management scripts created"
}

display_completion_info() {
    echo -e "\n${GREEN}===============================================================================${NC}"
    echo -e "${GREEN}  🎉 CryptoMiner Pro Installation Complete! 🎉${NC}"
    echo -e "${GREEN}===============================================================================${NC}\n"
    
    echo -e "${BLUE}📍 Installation Details:${NC}"
    echo -e "   📂 Installation Directory: ${CYAN}$INSTALL_DIR${NC}"
    echo -e "   📋 Log Directory: ${CYAN}$LOG_DIR${NC}"
    echo -e "   👤 Service User: ${CYAN}$SERVICE_USER${NC}"
    echo -e "   🔧 Management Script: ${CYAN}~/.local/bin/cryptominer${NC}"
    
    echo -e "\n${BLUE}🌐 Access URLs:${NC}"
    echo -e "   🖥️  Main Dashboard: ${CYAN}http://localhost/${NC}"
    echo -e "   📱 Frontend Only: ${CYAN}http://localhost:3000${NC}"
    echo -e "   🔧 Backend API: ${CYAN}http://localhost:8001/api/health${NC}"
    
    echo -e "\n${BLUE}🎮 Management Commands:${NC}"
    echo -e "   ${YELLOW}cryptominer start${NC}   - Start all services"
    echo -e "   ${YELLOW}cryptominer stop${NC}    - Stop all services"
    echo -e "   ${YELLOW}cryptominer restart${NC} - Restart all services"
    echo -e "   ${YELLOW}cryptominer status${NC}  - Check service status"
    echo -e "   ${YELLOW}cryptominer logs${NC}    - View recent logs"
    
    echo -e "\n${BLUE}📋 Log Files:${NC}"
    echo -e "   📄 Installation: ${CYAN}$INSTALL_LOG${NC}"
    echo -e "   📄 Backend: ${CYAN}$LOG_DIR/backend.log${NC}"
    echo -e "   📄 Frontend: ${CYAN}$LOG_DIR/frontend.log${NC}"
    
    echo -e "\n${PURPLE}🚀 Getting Started:${NC}"
    echo -e "1. Open your web browser and go to: ${CYAN}http://localhost/${NC}"
    echo -e "2. Configure your wallet address and mining preferences"
    echo -e "3. Start mining and monitor your hashrate and earnings"
    echo -e "4. Use the AI optimization features for better performance"
    
    echo -e "\n${GREEN}Installation completed successfully! Happy mining! ⛏️💰${NC}\n"
}

# =============================================================================
# MAIN INSTALLATION PROCESS
# =============================================================================

main() {
    # Display header
    echo -e "${BLUE}"
    echo "==============================================================================="
    echo "  🏗️  CryptoMiner Pro - Enhanced Installation Script v$SCRIPT_VERSION"
    echo "==============================================================================="
    echo -e "${NC}"
    
    # Run installation steps
    check_system_requirements
    create_directories
    install_system_packages
    install_nodejs
    install_mongodb
    configure_service_user
    install_application
    install_backend_dependencies
    install_frontend_dependencies
    configure_environment
    setup_supervisor
    configure_nginx
    start_services
    
    # Test installation
    if test_installation; then
        create_management_scripts
        display_completion_info
    else
        log_error "Installation test failed. Check logs for details."
        exit 1
    fi
}

# Handle script interruption
trap 'log_error "Installation interrupted by user"; cleanup_on_error; exit 1' INT TERM

# Run main installation
main "$@"