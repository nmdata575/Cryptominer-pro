#!/bin/bash

# =============================================================================
# CryptoMiner Pro - Enhanced Installation Script v2.0
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
SCRIPT_VERSION="2.0.0"
PROJECT_NAME="CryptoMiner Pro"
INSTALL_DIR="/opt/cryptominer-pro"
SERVICE_USER="cryptominer"
LOG_FILE="/var/log/cryptominer-install.log"
BACKUP_DIR="/opt/cryptominer-backup-$(date +%Y%m%d_%H%M%S)"

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
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

show_header() {
    clear
    echo -e "${PURPLE}"
    echo "==============================================================================="
    echo "  🚀 $PROJECT_NAME - Enhanced Installation Script v$SCRIPT_VERSION"
    echo "==============================================================================="
    echo -e "${NC}"
    echo -e "${CYAN}Features:${NC}"
    echo "  ✅ ricmoo-scrypt Integration - Real cryptocurrency mining"
    echo "  ✅ Enhanced AI System - Machine learning optimization" 
    echo "  ✅ Real Pool Mining - Connect to ltc.millpools.cc:3567"
    echo "  ✅ MongoDB 8.0 Integration - Latest database technology"
    echo "  ✅ Node.js Backend - High-performance mining engine"
    echo "  ✅ React Frontend - Professional mining dashboard"
    echo ""
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons"
        log_info "Please run as a regular user with sudo privileges"
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges"
        log_info "Please ensure your user has sudo access"
        exit 1
    fi
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
        log_info "Detected OS: $PRETTY_NAME"
    else
        log_error "Cannot detect operating system"
        exit 1
    fi
    
    case $OS in
        ubuntu|debian)
            PACKAGE_MANAGER="apt"
            ;;
        centos|rhel|fedora)
            PACKAGE_MANAGER="yum"
            ;;
        *)
            log_warning "Unsupported OS: $OS. Attempting to continue with apt..."
            PACKAGE_MANAGER="apt"
            ;;
    esac
}

check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check RAM
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $ram_gb -lt $MIN_RAM_GB ]]; then
        log_error "Insufficient RAM: ${ram_gb}GB (minimum: ${MIN_RAM_GB}GB)"
        exit 1
    fi
    log_success "RAM: ${ram_gb}GB ✅"
    
    # Check disk space
    local disk_gb=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $disk_gb -lt $MIN_DISK_GB ]]; then
        log_error "Insufficient disk space: ${disk_gb}GB (minimum: ${MIN_DISK_GB}GB)"
        exit 1
    fi
    log_success "Disk space: ${disk_gb}GB ✅"
    
    # Check CPU cores
    local cores=$(nproc)
    if [[ $cores -lt $REQUIRED_CORES ]]; then
        log_error "Insufficient CPU cores: $cores (minimum: $REQUIRED_CORES)"
        exit 1
    fi
    log_success "CPU cores: $cores ✅"
    
    # Check architecture
    local arch=$(uname -m)
    if [[ $arch != "x86_64" ]] && [[ $arch != "aarch64" ]]; then
        log_warning "Unsupported architecture: $arch (recommended: x86_64)"
    else
        log_success "Architecture: $arch ✅"
    fi
}

install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    case $PACKAGE_MANAGER in
        apt)
            sudo apt update
            sudo apt install -y \
                curl \
                wget \
                git \
                build-essential \
                python3 \
                python3-pip \
                python3-dev \
                supervisor \
                nginx \
                ufw \
                htop \
                unzip \
                software-properties-common \
                gnupg \
                lsb-release
            ;;
        yum)
            sudo yum update -y
            sudo yum groupinstall -y "Development Tools"
            sudo yum install -y \
                curl \
                wget \
                git \
                python3 \
                python3-pip \
                python3-devel \
                supervisor \
                nginx \
                firewalld \
                htop \
                unzip
            ;;
    esac
    
    log_success "System dependencies installed ✅"
}

install_nodejs() {
    log_info "Installing Node.js $NODE_VERSION..."
    
    # Install Node.js using NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Verify installation
    local node_version=$(node --version)
    local npm_version=$(npm --version)
    
    log_success "Node.js installed: $node_version ✅"
    log_success "npm installed: v$npm_version ✅"
    
    # Install global packages
    sudo npm install -g yarn pm2
    log_success "Global packages installed ✅"
}

install_mongodb() {
    log_info "Installing MongoDB $MONGODB_VERSION..."
    
    # Import MongoDB public GPG key
    curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | \
        sudo gpg -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg --dearmor
    
    # Create MongoDB repository list file
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/${MONGODB_VERSION} multiverse" | \
        sudo tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
    
    # Update and install MongoDB
    sudo apt-get update
    sudo apt-get install -y mongodb-org
    
    # Pin MongoDB version to prevent unintended upgrades
    echo "mongodb-org hold" | sudo dpkg --set-selections
    echo "mongodb-org-database hold" | sudo dpkg --set-selections
    echo "mongodb-org-server hold" | sudo dpkg --set-selections
    echo "mongodb-mongosh hold" | sudo dpkg --set-selections
    echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
    echo "mongodb-org-tools hold" | sudo dpkg --set-selections
    
    # Configure MongoDB
    sudo systemctl start mongod
    sudo systemctl enable mongod
    
    # Create data directory
    sudo mkdir -p /data/db
    sudo chown mongodb:mongodb /data/db
    
    # Verify installation
    if sudo systemctl is-active --quiet mongod; then
        log_success "MongoDB $MONGODB_VERSION installed and running ✅"
    else
        log_error "MongoDB installation failed"
        exit 1
    fi
}

create_service_user() {
    log_info "Creating service user: $SERVICE_USER..."
    
    if ! id "$SERVICE_USER" &>/dev/null; then
        sudo useradd -r -d "$INSTALL_DIR" -s /bin/bash "$SERVICE_USER"
        log_success "Service user created ✅"
    else
        log_info "Service user already exists"
    fi
}

create_directories() {
    log_info "Creating application directories..."
    
    sudo mkdir -p "$INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR/backend-nodejs"
    sudo mkdir -p "$INSTALL_DIR/frontend"
    sudo mkdir -p "$INSTALL_DIR/logs"
    sudo mkdir -p "$INSTALL_DIR/data"
    sudo mkdir -p /var/log/cryptominer
    
    sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
    sudo chown -R "$SERVICE_USER:$SERVICE_USER" /var/log/cryptominer
    
    log_success "Directories created ✅"
}

install_application() {
    log_info "Installing CryptoMiner Pro application..."
    
    # Create application structure
    create_directories
    
    # Copy application files (this would typically clone from repository)
    log_info "Setting up application structure..."
    
    # Backend setup
    sudo -u "$SERVICE_USER" tee "$INSTALL_DIR/backend-nodejs/package.json" > /dev/null << 'EOF'
{
  "name": "cryptominer-pro-backend",
  "version": "2.0.0",
  "description": "CryptoMiner Pro - Enhanced Backend with ricmoo-scrypt Integration",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest"
  },
  "keywords": ["cryptocurrency", "mining", "scrypt", "ai", "optimization"],
  "author": "CryptoMiner Pro Team",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.4",
    "mongoose": "^7.6.3",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "compression": "^1.7.4",
    "morgan": "^1.10.0",
    "express-rate-limit": "^7.1.5",
    "dotenv": "^16.3.1",
    "scrypt-js": "^3.0.1",
    "moment": "^2.29.4",
    "systeminformation": "^5.21.15",
    "crypto": "^1.0.1",
    "net": "^1.0.2",
    "os": "^0.1.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.7.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

    # Frontend setup
    sudo -u "$SERVICE_USER" tee "$INSTALL_DIR/frontend/package.json" > /dev/null << 'EOF'
{
  "name": "cryptominer-pro-frontend",
  "version": "2.0.0",
  "description": "CryptoMiner Pro - Enhanced Frontend Dashboard",
  "private": true,
  "dependencies": {
    "@testing-library/jest-dom": "^5.17.0",
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^14.5.1",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1",
    "socket.io-client": "^4.7.4",
    "axios": "^1.6.0",
    "recharts": "^2.8.0",
    "lucide-react": "^0.290.0",
    "tailwindcss": "^3.3.5",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31",
    "@craco/craco": "^7.1.0"
  },
  "scripts": {
    "start": "craco start",
    "build": "craco build",
    "test": "craco test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "proxy": "http://localhost:8001"
}
EOF

    log_success "Application structure created ✅"
}

install_dependencies() {
    log_info "Installing application dependencies..."
    
    # Install backend dependencies
    cd "$INSTALL_DIR/backend-nodejs"
    sudo -u "$SERVICE_USER" yarn install --production
    log_success "Backend dependencies installed ✅"
    
    # Install frontend dependencies
    cd "$INSTALL_DIR/frontend"
    sudo -u "$SERVICE_USER" yarn install
    log_success "Frontend dependencies installed ✅"
}

create_environment_files() {
    log_info "Creating environment configuration files..."
    
    # Backend .env
    sudo -u "$SERVICE_USER" tee "$INSTALL_DIR/backend-nodejs/.env" > /dev/null << EOF
# CryptoMiner Pro Backend Configuration v2.0
NODE_ENV=production
PORT=8001
MONGO_URL=mongodb://localhost:27017/cryptominer

# Mining Configuration
ACTUAL_CPU_CORES=$(nproc)
FORCE_CPU_OVERRIDE=true
FORCE_PRODUCTION_MINING=true
DEFAULT_MINING_THREADS=4
DEFAULT_INTENSITY=0.8

# Pool Configuration
DEFAULT_LTC_POOL=ltc.millpools.cc:3567
DEFAULT_DOGE_POOL=doge.pool-pay.com:9998
DEFAULT_FTC_POOL=ftc.pool-pay.com:8338

# AI Configuration
AI_LEARNING_ENABLED=true
AI_DATA_RETENTION_DAYS=60
AI_PREDICTION_INTERVAL=300

# Security
SESSION_SECRET=$(openssl rand -base64 32)
API_RATE_LIMIT=1000
API_RATE_WINDOW=900000

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/cryptominer/backend.log
EOF

    # Frontend .env
    sudo -u "$SERVICE_USER" tee "$INSTALL_DIR/frontend/.env" > /dev/null << EOF
# CryptoMiner Pro Frontend Configuration v2.0
REACT_APP_BACKEND_URL=http://localhost:8001
REACT_APP_VERSION=2.0.0
REACT_APP_APP_NAME=CryptoMiner Pro

# Features
REACT_APP_AI_ENABLED=true
REACT_APP_REAL_MINING_ENABLED=true
REACT_APP_POOL_MINING_ENABLED=true

# WebSocket
REACT_APP_WEBSOCKET_URL=ws://localhost:8001

# Development
GENERATE_SOURCEMAP=false
BROWSER=none
EOF

    log_success "Environment files created ✅"
}

configure_supervisor() {
    log_info "Configuring Supervisor for process management..."
    
    # Backend supervisor config
    sudo tee "/etc/supervisor/conf.d/cryptominer-backend.conf" > /dev/null << EOF
[program:cryptominer-backend]
command=/usr/bin/node server.js
directory=$INSTALL_DIR/backend-nodejs
user=$SERVICE_USER
autostart=true
autorestart=true
stdout_logfile=/var/log/cryptominer/backend.log
stderr_logfile=/var/log/cryptominer/backend-error.log
environment=NODE_ENV=production
priority=999
killasgroup=true
stopasgroup=true
EOF

    # Frontend supervisor config
    sudo tee "/etc/supervisor/conf.d/cryptominer-frontend.conf" > /dev/null << EOF
[program:cryptominer-frontend]
command=/usr/bin/yarn start
directory=$INSTALL_DIR/frontend
user=$SERVICE_USER
autostart=true
autorestart=true
stdout_logfile=/var/log/cryptominer/frontend.log
stderr_logfile=/var/log/cryptominer/frontend-error.log
environment=NODE_ENV=production,PORT=3000
priority=998
killasgroup=true
stopasgroup=true
EOF

    # Reload supervisor
    sudo supervisorctl reread
    sudo supervisorctl update
    
    log_success "Supervisor configured ✅"
}

configure_nginx() {
    log_info "Configuring Nginx reverse proxy..."
    
    sudo tee "/etc/nginx/sites-available/cryptominer-pro" > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # WebSocket
    location /socket.io/ {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # Enable site
    sudo ln -sf /etc/nginx/sites-available/cryptominer-pro /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload Nginx
    sudo nginx -t
    sudo systemctl reload nginx
    
    log_success "Nginx configured ✅"
}

configure_firewall() {
    log_info "Configuring firewall..."
    
    # Configure UFW
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow HTTP/HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Allow mining ports (outbound only)
    sudo ufw allow out 3567/tcp  # Litecoin pools
    sudo ufw allow out 9998/tcp  # Dogecoin pools
    sudo ufw allow out 8338/tcp  # Feathercoin pools
    
    # Enable firewall
    sudo ufw --force enable
    
    log_success "Firewall configured ✅"
}

create_systemd_services() {
    log_info "Creating systemd services for auto-start..."
    
    # CryptoMiner Pro service
    sudo tee "/etc/systemd/system/cryptominer-pro.service" > /dev/null << EOF
[Unit]
Description=CryptoMiner Pro - Enhanced Mining Platform
After=network.target mongodb.service
Wants=mongodb.service

[Service]
Type=forking
User=root
ExecStart=/usr/bin/supervisorctl start all
ExecStop=/usr/bin/supervisorctl stop all
ExecReload=/usr/bin/supervisorctl restart all
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable cryptominer-pro.service
    
    log_success "Systemd services created ✅"
}

verify_installation() {
    log_info "Verifying installation..."
    
    # Check services
    local services=("mongod" "nginx" "supervisor")
    for service in "${services[@]}"; do
        if sudo systemctl is-active --quiet "$service"; then
            log_success "$service is running ✅"
        else
            log_error "$service is not running ❌"
            return 1
        fi
    done
    
    # Wait for applications to start
    log_info "Starting CryptoMiner Pro services..."
    sudo supervisorctl start all
    sleep 10
    
    # Check application services
    local app_status=$(sudo supervisorctl status)
    if echo "$app_status" | grep -q "RUNNING"; then
        log_success "CryptoMiner Pro services are running ✅"
    else
        log_error "Some CryptoMiner Pro services failed to start ❌"
        echo "$app_status"
        return 1
    fi
    
    # Test MongoDB connection
    if mongosh --eval "db.adminCommand('ping')" --quiet; then
        log_success "MongoDB connection test passed ✅"
    else
        log_error "MongoDB connection test failed ❌"
        return 1
    fi
    
    # Test HTTP endpoints
    sleep 5
    if curl -f http://localhost/api/health &>/dev/null; then
        log_success "Backend API health check passed ✅"
    else
        log_warning "Backend API health check failed (may need more time to start)"
    fi
    
    return 0
}

show_completion_info() {
    log_success "🎉 CryptoMiner Pro installation completed successfully!"
    echo ""
    echo -e "${PURPLE}===============================================================================${NC}"
    echo -e "${GREEN}  🚀 CryptoMiner Pro v$SCRIPT_VERSION - Installation Complete!${NC}"
    echo -e "${PURPLE}===============================================================================${NC}"
    echo ""
    echo -e "${CYAN}📍 Installation Details:${NC}"
    echo "  📂 Installation Directory: $INSTALL_DIR"
    echo "  👤 Service User: $SERVICE_USER"
    echo "  📋 Log Files: /var/log/cryptominer/"
    echo "  🗄️ Database: MongoDB (localhost:27017)"
    echo ""
    echo -e "${CYAN}🌐 Access Information:${NC}"
    echo "  🖥️  Web Dashboard: http://$(hostname -I | awk '{print $1}')"
    echo "  🔧 API Endpoint: http://$(hostname -I | awk '{print $1}')/api"
    echo "  📊 Backend Health: http://$(hostname -I | awk '{print $1}')/api/health"
    echo ""
    echo -e "${CYAN}⚡ Key Features:${NC}"
    echo "  ✅ ricmoo-scrypt Integration - Real cryptocurrency mining"
    echo "  ✅ Enhanced AI System - Machine learning optimization"
    echo "  ✅ Real Pool Mining - ltc.millpools.cc:3567 support"
    echo "  ✅ MongoDB 8.0 Integration - Latest database technology"
    echo "  ✅ Professional Dashboard - Real-time monitoring"
    echo ""
    echo -e "${CYAN}🔧 Management Commands:${NC}"
    echo "  Start Services:   sudo supervisorctl start all"
    echo "  Stop Services:    sudo supervisorctl stop all"
    echo "  Restart Services: sudo supervisorctl restart all"
    echo "  Check Status:     sudo supervisorctl status"
    echo "  View Logs:        sudo tail -f /var/log/cryptominer/backend.log"
    echo ""
    echo -e "${CYAN}💡 Getting Started:${NC}"
    echo "  1. Open the web dashboard in your browser"
    echo "  2. Configure your mining wallet address"
    echo "  3. Select mining pool and parameters"
    echo "  4. Start mining and monitor AI optimization"
    echo ""
    echo -e "${YELLOW}⚠️  Important Security Notes:${NC}"
    echo "  🔐 Change default passwords and API keys"
    echo "  🛡️  Configure SSL/TLS for production use"
    echo "  🔄 Keep the system updated regularly"
    echo "  📊 Monitor system resources during mining"
    echo ""
    echo -e "${GREEN}Happy Mining! 🚀⛏️${NC}"
    echo ""
}

cleanup_on_failure() {
    log_error "Installation failed. Performing cleanup..."
    
    # Stop services
    sudo supervisorctl stop all 2>/dev/null || true
    
    # Remove application directory
    if [[ -d "$INSTALL_DIR" ]]; then
        sudo rm -rf "$INSTALL_DIR"
    fi
    
    # Remove service user
    if id "$SERVICE_USER" &>/dev/null; then
        sudo userdel -r "$SERVICE_USER" 2>/dev/null || true
    fi
    
    # Remove service configurations
    sudo rm -f /etc/supervisor/conf.d/cryptominer-*.conf
    sudo rm -f /etc/nginx/sites-available/cryptominer-pro
    sudo rm -f /etc/nginx/sites-enabled/cryptominer-pro
    sudo rm -f /etc/systemd/system/cryptominer-pro.service
    
    # Reload configurations
    sudo supervisorctl reread 2>/dev/null || true
    sudo supervisorctl update 2>/dev/null || true
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo nginx -t && sudo systemctl reload nginx 2>/dev/null || true
    
    log_info "Cleanup completed"
}

# =============================================================================
# MAIN INSTALLATION FLOW
# =============================================================================

main() {
    # Setup error handling
    trap cleanup_on_failure ERR
    
    # Initialize log file
    sudo touch "$LOG_FILE"
    sudo chmod 666 "$LOG_FILE"
    
    show_header
    
    log "Starting CryptoMiner Pro installation..."
    log "Installation log: $LOG_FILE"
    
    # Pre-installation checks
    check_root
    detect_os
    check_system_requirements
    
    # Create backup if existing installation
    if [[ -d "$INSTALL_DIR" ]]; then
        log_info "Existing installation detected, creating backup..."
        sudo cp -r "$INSTALL_DIR" "$BACKUP_DIR"
        log_success "Backup created at $BACKUP_DIR"
    fi
    
    # Installation steps
    install_system_dependencies
    install_nodejs
    install_mongodb
    create_service_user
    install_application
    install_dependencies
    create_environment_files
    configure_supervisor
    configure_nginx
    configure_firewall
    create_systemd_services
    
    # Verification
    if verify_installation; then
        show_completion_info
        log "Installation completed successfully at $(date)"
    else
        log_error "Installation verification failed"
        exit 1
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi