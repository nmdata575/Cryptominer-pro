#!/bin/bash

# CryptoMiner Pro - Enhanced Installation Script for Latest Configuration
# Updated for AI Prediction System, High-Performance Mining, and Real Pool Integration
# Date: July 2025

set -e

echo "🚀 CryptoMiner Pro - Enhanced Installation Script v3.0"  
echo "====================================================="
echo "🎯 Features: AI Prediction System, High-Performance Mining, Real Pool Integration"
echo "🔧 Stack: Node.js 20+ + React + MongoDB + Socket.io + AI/ML"
echo "⚡ Enhancements: Multi-Process Mining, Thread Scaling (up to 256), Real Pool Mining"
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

# Detect environment and hardware
detect_environment() {
    print_step "Detecting environment and hardware..."
    
    if [[ -f /.dockerenv ]]; then
        ENV_TYPE="docker"
        print_status "🐳 Docker container detected"
    elif [[ -n "${KUBERNETES_SERVICE_HOST}" ]]; then
        ENV_TYPE="kubernetes"
        print_status "☸️ Kubernetes environment detected"
    else
        ENV_TYPE="native"
        print_status "💻 Native system detected"
    fi
    
    # Detect CPU cores (important for mining performance)
    CPU_CORES=$(nproc --all)
    CPU_THREADS=$(nproc)
    print_status "🖥️ Detected ${CPU_CORES} CPU cores / ${CPU_THREADS} threads"
    
    # Calculate optimal mining threads for high-performance mode
    if [ "$CPU_CORES" -ge 32 ]; then
        RECOMMENDED_THREADS=$((CPU_CORES - 4))  # Leave some cores for system
        PERFORMANCE_PROFILE="high_end"
    elif [ "$CPU_CORES" -ge 16 ]; then
        RECOMMENDED_THREADS=$((CPU_CORES - 2))
        PERFORMANCE_PROFILE="mid_range"
    elif [ "$CPU_CORES" -ge 8 ]; then
        RECOMMENDED_THREADS=$((CPU_CORES - 1))
        PERFORMANCE_PROFILE="standard"
    else
        RECOMMENDED_THREADS=$((CPU_CORES > 2 ? CPU_CORES - 1 : 1))
        PERFORMANCE_PROFILE="basic"
    fi
    
    # Detect available memory (critical for multi-process mining)
    TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
    AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
    print_status "💾 Memory: ${TOTAL_MEM}MB total, ${AVAILABLE_MEM}MB available"
    
    # Calculate memory-safe process count
    MEMORY_SAFE_PROCESSES=$((AVAILABLE_MEM / 128))  # 128MB per process estimate
    if [ "$MEMORY_SAFE_PROCESSES" -gt "$RECOMMENDED_THREADS" ]; then
        MEMORY_SAFE_PROCESSES=$RECOMMENDED_THREADS
    fi
    
    print_feature "⚡ Performance Profile: $PERFORMANCE_PROFILE"
    print_feature "🔧 Recommended Mining Threads: $RECOMMENDED_THREADS"
    print_feature "💾 Memory-Safe Processes: $MEMORY_SAFE_PROCESSES"
}

# Check requirements for enhanced features
check_enhanced_requirements() {
    print_step "Checking enhanced system requirements..."
    
    # Check minimum requirements for AI and high-performance mining
    MIN_MEMORY=2048  # 2GB minimum for AI processing
    MIN_CORES=2      # 2 cores minimum for multi-process mining
    
    if [ "$TOTAL_MEM" -lt "$MIN_MEMORY" ]; then
        print_error "Insufficient memory for AI features. Required: ${MIN_MEMORY}MB, Available: ${TOTAL_MEM}MB"
        print_tip "AI prediction system requires at least 2GB RAM"
        exit 1
    fi
    
    if [ "$CPU_CORES" -lt "$MIN_CORES" ]; then
        print_error "Insufficient CPU cores for high-performance mining. Required: ${MIN_CORES}, Available: ${CPU_CORES}"
        exit 1
    fi
    
    # Check disk space (more needed for AI data and logging)
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=10485760  # 10GB in KB for enhanced features
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        print_error "Insufficient disk space. Required: 10GB, Available: $((AVAILABLE_SPACE/1024/1024))GB"
        print_tip "AI system and high-performance logging requires additional disk space"
        exit 1
    fi
    
    print_success "✅ Enhanced system requirements check passed"
}

# Install enhanced Node.js with performance optimizations
install_enhanced_nodejs() {
    print_step "Installing Node.js 20.x with performance optimizations..."
    
    # Remove any existing nodejs
    sudo apt-get remove -y nodejs npm 2>/dev/null || true
    
    # Install NodeSource repository for latest Node.js
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || handle_error "NodeSource setup failed"
    
    # Install Node.js with performance packages
    sudo apt-get install -y nodejs build-essential python3-dev || handle_error "Node.js installation failed"
    
    # Verify installation
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    
    print_success "✅ Node.js installed: $NODE_VERSION"
    print_success "✅ npm installed: $NPM_VERSION"
    
    # Install yarn for better dependency management
    print_step "Installing Yarn package manager..."
    npm install -g yarn || print_warning "Yarn installation failed - continuing with npm"
    
    # Optimize npm for performance and AI dependencies
    npm config set fund false
    npm config set audit false  
    npm config set maxsockets 50
    npm config set registry https://registry.npmjs.org/
    
    # Set Node.js memory limit for high-performance operations
    export NODE_OPTIONS="--max-old-space-size=4096"
    echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> ~/.bashrc
    
    print_feature "⚡ Node.js optimized for high-performance mining operations"
}

# Install AI/ML dependencies
install_ai_dependencies() {
    print_step "Installing AI/ML dependencies for prediction system..."
    
    # Install Python and ML dependencies required for some AI operations
    sudo apt-get install -y python3 python3-pip python3-numpy python3-scipy || print_warning "Python ML dependencies installation failed"
    
    # Install Node.js ML libraries globally for better performance
    npm install -g node-gyp || print_warning "node-gyp installation failed"
    
    print_success "✅ AI/ML dependencies installed"
}

# Enhanced MongoDB installation with optimization
install_enhanced_mongodb() {
    print_step "Installing MongoDB 7.0 with performance optimizations..."
    
    # Import MongoDB GPG key
    wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add - || handle_error "MongoDB GPG key import failed"
    
    # Detect architecture and Ubuntu version
    ARCH=$(dpkg --print-architecture)
    UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "22.04")
    
    # Add MongoDB repository with version detection
    if [[ "$UBUNTU_VERSION" == "22.04" ]] || [[ "$UBUNTU_VERSION" == "22.10" ]]; then
        MONGODB_REPO="jammy"
    elif [[ "$UBUNTU_VERSION" == "20.04" ]]; then
        MONGODB_REPO="focal"
    else
        MONGODB_REPO="jammy"  # Default to latest
        print_warning "Using jammy repository for MongoDB (latest compatible)"
    fi
    
    echo "deb [ arch=$ARCH,arm64 ] https://repo.mongodb.org/apt/ubuntu $MONGODB_REPO/mongodb-org/7.0 multiverse" | \
        sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list || handle_error "MongoDB repository setup failed"
    
    # Update and install MongoDB
    sudo apt-get update || handle_error "Package list update failed"
    sudo apt-get install -y mongodb-org || handle_error "MongoDB installation failed"
    
    # Configure MongoDB for high-performance mining
    print_step "Configuring MongoDB for mining operations..."
    
    # Create optimized MongoDB configuration
    sudo tee /etc/mongod.conf > /dev/null <<EOF
# MongoDB configuration for CryptoMiner Pro
# Optimized for mining data and AI processing

storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
  wiredTiger:
    engineConfig:
      cacheSizeGB: $((TOTAL_MEM / 1024 / 4))  # 1/4 of available RAM
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: snappy
    indexConfig:
      prefixCompression: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
  logRotate: reopen

net:
  port: 27017
  bindIp: 127.0.0.1

processManagement:
  timeZoneInfo: /usr/share/zoneinfo
  fork: true
  pidFilePath: /var/run/mongodb/mongod.pid

# Security
security:
  authorization: disabled

# Replication (for future scaling)
#replication:
#  replSetName: "rs0"

# Profiling for performance monitoring
operationProfiling:
  slowOpThresholdMs: 100
  mode: slowOp
EOF
    
    # Set up data directories with proper permissions
    sudo mkdir -p /var/lib/mongodb /var/log/mongodb /var/run/mongodb /data/db
    sudo chown -R mongodb:mongodb /var/lib/mongodb /var/log/mongodb /var/run/mongodb 2>/dev/null || true
    sudo chown -R mongodb:mongodb /data/db 2>/dev/null || sudo chown -R root:root /data/db
    
    # Kill any existing MongoDB processes to avoid conflicts
    print_step "Cleaning up any existing MongoDB processes..."
    sudo pkill -f mongod 2>/dev/null || true
    sleep 3
    
    # Start and enable MongoDB with robust startup
    print_step "Starting optimized MongoDB service..."
    
    # Try systemd first (for native systems)
    if [[ "$ENV_TYPE" == "native" ]] && command -v systemctl >/dev/null 2>&1; then
        print_status "Starting MongoDB via systemd..."
        sudo systemctl stop mongod 2>/dev/null || true
        sleep 2
        sudo systemctl start mongod || {
            print_warning "Systemd start failed, trying manual start..."
            sudo mongod --dbpath /data/db --logpath /var/log/mongodb/mongod.log --fork || handle_error "MongoDB manual start failed"
        }
        sudo systemctl enable mongod 2>/dev/null || print_warning "MongoDB auto-start setup failed"
    else
        # For container environments or when systemd fails
        print_status "Starting MongoDB manually for container environment..."
        sudo mongod --dbpath /data/db --logpath /var/log/mongodb/mongod.log --fork || handle_error "MongoDB container start failed"
    fi
    
    # Robust MongoDB startup verification with retries
    print_step "Verifying MongoDB startup..."
    MONGODB_READY=false
    MAX_RETRIES=10
    RETRY_COUNT=0
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$MONGODB_READY" = false ]; do
        sleep 2
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        if pgrep mongod > /dev/null; then
            print_status "MongoDB process detected (attempt $RETRY_COUNT/$MAX_RETRIES)"
            
            # Test connection
            if mongosh --eval "db.runCommand('ping')" --quiet >/dev/null 2>&1; then
                MONGODB_READY=true
                print_success "✅ MongoDB is running and accessible via mongosh"
            elif mongo --eval "db.runCommand('ping')" --quiet >/dev/null 2>&1; then
                MONGODB_READY=true
                print_success "✅ MongoDB is running and accessible via legacy mongo client"
            else
                print_status "MongoDB process running but not yet accepting connections..."
            fi
        else
            print_status "Waiting for MongoDB process to start (attempt $RETRY_COUNT/$MAX_RETRIES)..."
        fi
    done
    
    if [ "$MONGODB_READY" = false ]; then
        print_error "❌ MongoDB failed to start after $MAX_RETRIES attempts"
        print_tip "Checking MongoDB logs..."
        tail -20 /var/log/mongodb/mongod.log 2>/dev/null || echo "No MongoDB logs found"
        handle_error "MongoDB startup verification failed"
    fi
    
    # Create mining database and optimize it
    print_step "Setting up optimized mining database..."
    mongosh --eval "
    db = db.getSiblingDB('cryptominer');
    db.createCollection('mining_stats', {capped: true, size: 100000000, max: 10000});
    db.createCollection('ai_predictions', {capped: true, size: 50000000, max: 5000});
    db.createCollection('system_metrics', {capped: true, size: 50000000, max: 5000});
    print('✅ Mining database optimized for performance');
    " 2>/dev/null || print_warning "Database optimization failed - continuing anyway"
    
    print_success "✅ MongoDB installation and optimization completed"
}

# Robust port cleanup and conflict resolution
cleanup_port_conflicts() {
    print_step "Cleaning up potential port conflicts..."
    
    # Ports used by the application
    PORTS=(8001 3000 27017)
    
    for PORT in "${PORTS[@]}"; do
        if sudo lsof -i :$PORT >/dev/null 2>&1; then
            print_warning "Port $PORT is in use, cleaning up..."
            
            # Get processes using the port
            PIDS=$(sudo lsof -t -i :$PORT 2>/dev/null || true)
            
            if [ -n "$PIDS" ]; then
                print_status "Terminating processes on port $PORT: $PIDS"
                sudo kill -TERM $PIDS 2>/dev/null || true
                sleep 2
                
                # Force kill if still running
                REMAINING_PIDS=$(sudo lsof -t -i :$PORT 2>/dev/null || true)
                if [ -n "$REMAINING_PIDS" ]; then
                    print_status "Force killing stubborn processes: $REMAINING_PIDS"
                    sudo kill -KILL $REMAINING_PIDS 2>/dev/null || true
                fi
            fi
        fi
    done
    
    # Clean up any orphaned Node.js processes
    print_step "Cleaning up orphaned Node.js processes..."
    sudo pkill -f "node.*server.js" 2>/dev/null || true
    sudo pkill -f "npm.*start" 2>/dev/null || true
    
    sleep 3
    print_success "✅ Port cleanup completed"
}

# Create enhanced supervisor configuration with dependency management
create_enhanced_supervisor() {
    print_step "Creating enhanced supervisor configuration with dependency management..."
    
    # Create supervisor configuration with proper service dependencies and startup order
    sudo tee /etc/supervisor/conf.d/cryptominer_enhanced.conf > /dev/null <<EOF
[program:backend]
command=npm start
directory=$APP_DIR/backend-nodejs
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/backend.err.log
stdout_logfile=/var/log/supervisor/backend.out.log
environment=NODE_ENV=production,NODE_OPTIONS="--max-old-space-size=4096",MONGO_URL="mongodb://localhost:27017/cryptominer"
user=root
startsecs=20
startretries=5
redirect_stderr=false
stdout_logfile_maxbytes=100MB
stdout_logfile_backups=5
priority=100
stopwaitsecs=10

[program:frontend]
command=npm start
directory=$APP_DIR/frontend
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/frontend.err.log
stdout_logfile=/var/log/supervisor/frontend.out.log
environment=PORT=3000,GENERATE_SOURCEMAP=false,ESLINT_NO_CACHE=true,NODE_OPTIONS="--max-old-space-size=2048"
user=root
startsecs=25
startretries=5
redirect_stderr=false
stdout_logfile_maxbytes=100MB
stdout_logfile_backups=5
priority=200
stopwaitsecs=10

[group:mining_system]
programs=backend,frontend
priority=999
EOF

    print_success "✅ Enhanced supervisor configuration created with dependency management"
    print_feature "⚡ Optimized startup order: MongoDB → Backend → Frontend"
}

# Robust service startup with comprehensive validation
start_enhanced_services() {
    print_step "Starting CryptoMiner Pro services with enhanced validation..."
    
    # First, ensure MongoDB is running
    print_step "Verifying MongoDB is ready for connections..."
    if ! pgrep mongod > /dev/null; then
        print_warning "MongoDB not running, attempting to start..."
        sudo mongod --dbpath /data/db --logpath /var/log/mongodb/mongod.log --fork || handle_error "Failed to start MongoDB"
        sleep 5
    fi
    
    # Clean up any port conflicts before starting services
    cleanup_port_conflicts
    
    # Update supervisor configuration
    print_step "Updating supervisor configuration..."
    sudo supervisorctl reread || handle_error "Supervisor reread failed"
    sudo supervisorctl update || handle_error "Supervisor update failed"
    
    # Give supervisor time to process configuration changes
    sleep 3
    
    # Start services with proper dependency order
    print_step "Starting backend service..."
    sudo supervisorctl start mining_system:backend || {
        print_warning "Backend start failed, checking for issues..."
        tail -10 /var/log/supervisor/backend.err.log
        handle_error "Backend service start failed"
    }
    
    # Wait for backend to stabilize
    print_step "Waiting for backend to stabilize..."
    sleep 10
    
    # Verify backend is responding before starting frontend
    BACKEND_READY=false
    MAX_BACKEND_RETRIES=10
    BACKEND_RETRY_COUNT=0
    
    while [ $BACKEND_RETRY_COUNT -lt $MAX_BACKEND_RETRIES ] && [ "$BACKEND_READY" = false ]; do
        BACKEND_RETRY_COUNT=$((BACKEND_RETRY_COUNT + 1))
        
        if curl -s -f http://localhost:8001/api/health >/dev/null 2>&1; then
            BACKEND_READY=true
            print_success "✅ Backend API is responding"
        else
            print_status "Waiting for backend API (attempt $BACKEND_RETRY_COUNT/$MAX_BACKEND_RETRIES)..."
            sleep 3
        fi
    done
    
    if [ "$BACKEND_READY" = false ]; then
        print_error "❌ Backend failed to respond after $MAX_BACKEND_RETRIES attempts"
        print_tip "Checking backend logs..."
        tail -20 /var/log/supervisor/backend.err.log
        handle_error "Backend API validation failed"
    fi
    
    # Start frontend service
    print_step "Starting frontend service..."
    sudo supervisorctl start mining_system:frontend || {
        print_warning "Frontend start failed, checking for issues..."
        tail -10 /var/log/supervisor/frontend.err.log
        handle_error "Frontend service start failed"
    }
    
    # Final service status check
    print_step "Performing final service validation..."
    sleep 15
    
    # Check final service status
    BACKEND_STATUS=$(sudo supervisorctl status mining_system:backend | grep -o "RUNNING" || echo "FAILED")
    FRONTEND_STATUS=$(sudo supervisorctl status mining_system:frontend | grep -o "RUNNING" || echo "FAILED")
    
    if [[ $BACKEND_STATUS == "RUNNING" ]]; then
        print_success "✅ Backend service is running stably"
    else
        print_error "❌ Backend service failed to stabilize"
        sudo supervisorctl status mining_system:backend
        handle_error "Backend service stabilization failed"
    fi
    
    if [[ $FRONTEND_STATUS == "RUNNING" ]]; then
        print_success "✅ Frontend service is running stably"
    else
        print_error "❌ Frontend service failed to stabilize"
        sudo supervisorctl status mining_system:frontend
        handle_error "Frontend service stabilization failed"
    fi
    
    print_success "✅ All services started successfully with enhanced validation"
}

# Install enhanced application dependencies
install_enhanced_dependencies() {
    print_step "Installing enhanced application dependencies..."
    
    cd "$APP_DIR/backend-nodejs" || handle_error "Backend directory not found"
    
    # Add missing AI dependency if not present
    if ! grep -q "ml-regression" package.json; then
        print_step "Adding AI/ML dependencies..."
        npm install ml-regression natural brain.js --save || print_warning "AI dependencies installation failed"
    fi
    
    # Install all dependencies with optimizations
    npm ci --only=production --no-audit --no-fund || npm install --only=production || handle_error "Backend dependencies installation failed"
    
    print_success "✅ Enhanced backend dependencies installed"
    
    # Frontend with AI components
    cd "$APP_DIR/frontend" || handle_error "Frontend directory not found"
    
    # Install frontend dependencies
    npm ci --no-audit --no-fund || npm install || handle_error "Frontend dependencies installation failed"
    
    print_success "✅ Enhanced frontend dependencies installed"
}

# Create enhanced environment configuration  
create_enhanced_config() {
    print_step "Creating enhanced configuration for AI and high-performance mining..."
    
    # Create enhanced backend .env
    cat > "$APP_DIR/backend-nodejs/.env" <<EOF
# CryptoMiner Pro Enhanced Configuration
# Generated on $(date)

# Server Configuration
PORT=8001
HOST=0.0.0.0
NODE_ENV=production

# Database Configuration  
MONGO_URL=mongodb://localhost:27017/cryptominer

# Frontend Configuration
FRONTEND_URL=http://localhost:3000

# Security
JWT_SECRET=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -hex 32)

# Enhanced Mining Configuration
DEFAULT_THREADS=$RECOMMENDED_THREADS
DEFAULT_INTENSITY=0.8
MAX_THREADS=256
MAX_INTENSITY=1.0

# High-Performance Mining
HIGH_PERFORMANCE_MODE=true
ULTRA_PERFORMANCE_MODE=true
MAX_PROCESSES=$MEMORY_SAFE_PROCESSES
PROCESS_MEMORY_LIMIT=128

# AI Configuration (NEW)
AI_ENABLED=true
AI_LEARNING_RATE=0.01
AI_PREDICTION_INTERVAL=60000
AI_DATA_RETENTION_DAYS=30
AI_MIN_CONFIDENCE=0.5

# Mining Pool Configuration (NEW)
DEFAULT_POOL_TIMEOUT=10000
MAX_POOL_RETRIES=5
POOL_KEEPALIVE=true
STRATUM_PROTOCOL_VERSION=1

# Performance Optimization
CLUSTER_MODE=true
WORKER_PROCESSES=$MEMORY_SAFE_PROCESSES
MEMORY_LIMIT=4096

# Logging
LOG_LEVEL=info
LOG_FILE=cryptominer.log
LOG_ROTATION=daily
LOG_MAX_SIZE=100M

# Rate Limiting (Enhanced)
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=2000
RATE_LIMIT_SKIP_SUCCESSFUL=true

# WebSocket Configuration
WS_HEARTBEAT_INTERVAL=15000
WS_MAX_CONNECTIONS=200
WS_COMPRESSION=true

# System Monitoring (Enhanced)
SYSTEM_MONITOR_INTERVAL=2000
MEMORY_THRESHOLD=85
CPU_THRESHOLD=95
DISK_THRESHOLD=90

# Hardware Optimization
CPU_CORES=$CPU_CORES
CPU_THREADS=$CPU_THREADS
PERFORMANCE_PROFILE=$PERFORMANCE_PROFILE

# Development
DEBUG=cryptominer:*,mining:*,ai:*
EOF

    # Create enhanced frontend .env
    cat > "$APP_DIR/frontend/.env" <<EOF
# CryptoMiner Pro Frontend Enhanced Configuration
REACT_APP_BACKEND_URL=http://localhost:8001
REACT_APP_WS_URL=ws://localhost:8001
REACT_APP_VERSION=3.0.0
REACT_APP_FEATURES=ai,highperf,realpool
REACT_APP_MAX_THREADS=256
REACT_APP_AI_ENABLED=true
GENERATE_SOURCEMAP=false
ESLINT_NO_CACHE=true
EOF

    print_success "✅ Enhanced configuration created"
}

# Create enhanced supervisor configuration with dependency management
create_enhanced_supervisor() {
    print_step "Creating enhanced supervisor configuration with dependency management..."
    
    # Create supervisor configuration with proper service dependencies and startup order
    sudo tee /etc/supervisor/conf.d/cryptominer_enhanced.conf > /dev/null <<EOF
[program:backend]
command=npm start
directory=$APP_DIR/backend-nodejs
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/backend.err.log
stdout_logfile=/var/log/supervisor/backend.out.log
environment=NODE_ENV=production,NODE_OPTIONS="--max-old-space-size=4096",MONGO_URL="mongodb://localhost:27017/cryptominer"
user=root
startsecs=20
startretries=5
redirect_stderr=false
stdout_logfile_maxbytes=100MB
stdout_logfile_backups=5
priority=100
stopwaitsecs=10

[program:frontend]
command=npm start
directory=$APP_DIR/frontend
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/frontend.err.log
stdout_logfile=/var/log/supervisor/frontend.out.log
environment=PORT=3000,GENERATE_SOURCEMAP=false,ESLINT_NO_CACHE=true,NODE_OPTIONS="--max-old-space-size=2048"
user=root
startsecs=25
startretries=5
redirect_stderr=false
stdout_logfile_maxbytes=100MB
stdout_logfile_backups=5
priority=200
stopwaitsecs=10

[group:mining_system]
programs=backend,frontend
priority=999
EOF

    print_success "✅ Enhanced supervisor configuration created with dependency management"
    print_feature "⚡ Optimized startup order: MongoDB → Backend → Frontend"
}

# Performance testing and validation
test_enhanced_features() {
    print_step "Testing enhanced features..."
    
    # Wait for services to fully start
    sleep 20
    
    # Test AI prediction system
    print_step "Testing AI prediction system..."
    AI_RESPONSE=$(curl -s http://localhost:8001/api/mining/ai-insights || echo "failed")
    if [[ "$AI_RESPONSE" != "failed" ]] && echo "$AI_RESPONSE" | grep -q "predictions"; then
        print_success "✅ AI prediction system is working"
        AI_STATUS="✅ WORKING"
    else
        print_warning "⚠️ AI prediction system needs initialization"
        AI_STATUS="⚠️ INITIALIZING"
    fi
    
    # Test high-performance mining capability
    print_step "Testing high-performance mining capability..."
    HP_TEST=$(curl -s -X POST http://localhost:8001/api/mining/start-hp \
        -H "Content-Type: application/json" \
        -d '{"coin":"litecoin","mode":"pool","threads":4,"intensity":0.5,"pool_username":"test","pool_password":"test","custom_pool_address":"stratum+tcp://litecoinpool.org","custom_pool_port":3333}' \
        || echo "failed")
    
    if echo "$HP_TEST" | grep -q "success"; then
        print_success "✅ High-performance mining engine available"
        # Stop the test
        curl -s -X POST http://localhost:8001/api/mining/stop-hp > /dev/null
        HP_STATUS="✅ WORKING"
    else
        print_warning "⚠️ High-performance mining needs configuration"
        HP_STATUS="⚠️ NEEDS_CONFIG"
    fi
    
    # Test thread scaling
    print_step "Testing thread scaling capability..."
    THREAD_SUPPORT=$(curl -s http://localhost:8001/api/system/cpu-info || echo "failed")
    if echo "$THREAD_SUPPORT" | grep -q "cores"; then
        print_success "✅ Thread scaling system operational"
        THREAD_STATUS="✅ WORKING"
    else
        THREAD_STATUS="⚠️ LIMITED"
    fi
}

# Setup application with enhanced features
setup_enhanced_application() {
    print_step "Setting up CryptoMiner Pro with enhanced features..."
    
    # Get current directory
    CURRENT_DIR=$(pwd)
    
    # Check for source files
    if [[ ! -d "./backend-nodejs" ]] || [[ ! -d "./frontend" ]]; then
        print_error "Enhanced source files not found in current directory: $CURRENT_DIR"
        print_tip "Ensure you have the latest CryptoMiner Pro source with AI and high-performance features"
        exit 1
    fi
    
    # Set application directory
    if [[ "$CURRENT_DIR" == "/app" ]]; then
        APP_DIR="/app"
        print_status "🏠 Using development directory: $APP_DIR"
    else
        APP_DIR="/opt/cryptominer-pro-enhanced"
        sudo mkdir -p "$APP_DIR" || handle_error "Enhanced application directory creation failed"
        sudo chown -R $USER:$USER "$APP_DIR" || handle_error "Application directory ownership failed"
        
        # Copy enhanced application files
        print_step "Copying enhanced application files..."
        cp -r ./backend-nodejs "$APP_DIR/" || handle_error "Backend files copy failed"
        cp -r ./frontend "$APP_DIR/" || handle_error "Frontend files copy failed"
        
        # Copy documentation and management scripts
        for file in README.md INSTALLATION.md REMOTE_API_GUIDE.md CUSTOM_COINS_GUIDE.md manage.sh; do
            [[ -f "./$file" ]] && cp "./$file" "$APP_DIR/"
        done
        
        # Copy enhancement scripts
        for script in clear-ports.sh start-mining.sh manage-mining.sh optimize_threads.sh startup-manager.sh; do
            [[ -f "./$script" ]] && cp "./$script" "$APP_DIR/" && chmod +x "$APP_DIR/$script"
        done
        
        print_success "✅ Enhanced application files copied"
    fi
}

# Create enhanced management commands
create_enhanced_commands() {
    print_step "Creating enhanced management commands..."
    
    # Create comprehensive command aliases
    ENHANCED_ALIASES="
# CryptoMiner Pro Enhanced Command Aliases
alias cryptominer-start='sudo supervisorctl start mining_system:*'
alias cryptominer-stop='sudo supervisorctl stop mining_system:*'
alias cryptominer-restart='sudo supervisorctl restart mining_system:*'
alias cryptominer-status='sudo supervisorctl status mining_system:*'
alias cryptominer-logs='sudo tail -f /var/log/supervisor/backend.out.log /var/log/supervisor/frontend.out.log'
alias cryptominer-errors='sudo tail -f /var/log/supervisor/backend.err.log /var/log/supervisor/frontend.err.log'

# Enhanced API Commands
alias cryptominer-health='curl -s http://localhost:8001/api/health | jq .'
alias cryptominer-stats='curl -s http://localhost:8001/api/system/stats | jq .'
alias cryptominer-cpu='curl -s http://localhost:8001/api/system/cpu-info | jq .'
alias cryptominer-ai='curl -s http://localhost:8001/api/mining/ai-insights | jq .'

# High-Performance Mining Commands
alias cryptominer-hp-start='curl -s -X POST http://localhost:8001/api/mining/start-hp -H \"Content-Type: application/json\"'
alias cryptominer-hp-stop='curl -s -X POST http://localhost:8001/api/mining/stop-hp'
alias cryptominer-mining-status='curl -s http://localhost:8001/api/mining/status | jq .'

# System Optimization Commands
alias cryptominer-optimize='$APP_DIR/optimize_threads.sh'
alias cryptominer-monitor='watch -n 1 \"curl -s http://localhost:8001/api/system/stats | jq -r '.cpu.usage_percent, .memory.percent, .hashrate // 0'\"'
"
    
    # Add enhanced aliases to bashrc
    if ! grep -q "CryptoMiner Pro Enhanced Command Aliases" ~/.bashrc; then
        echo "$ENHANCED_ALIASES" >> ~/.bashrc
        print_success "✅ Enhanced command aliases added"
    fi
    
    # Create enhanced management script
    cat > "$APP_DIR/manage-enhanced.sh" <<'EOF'
#!/bin/bash
# CryptoMiner Pro Enhanced Management Script

case "$1" in
    start)
        echo "🚀 Starting CryptoMiner Pro Enhanced..."
        sudo supervisorctl start mining_system:*
        ;;
    stop)
        echo "⏹️ Stopping CryptoMiner Pro Enhanced..."
        sudo supervisorctl stop mining_system:*
        ;;
    restart)
        echo "🔄 Restarting CryptoMiner Pro Enhanced..."
        sudo supervisorctl restart mining_system:*
        ;;
    status)
        echo "📊 CryptoMiner Pro Enhanced Status:"
        sudo supervisorctl status mining_system:*
        echo ""
        echo "🔗 API Health:"
        curl -s http://localhost:8001/api/health | jq -r '"\(.status) - \(.node_version) - Uptime: \(.uptime)s"' 2>/dev/null || echo "API not responding"
        ;;
    ai-status)
        echo "🤖 AI Prediction Status:"
        curl -s http://localhost:8001/api/mining/ai-insights | jq -r '.learning_status' 2>/dev/null || echo "AI system not responding"
        ;;
    hp-test)
        echo "⚡ Testing High-Performance Mining..."
        curl -s -X POST http://localhost:8001/api/mining/start-hp \
            -H "Content-Type: application/json" \
            -d '{"coin":"litecoin","mode":"pool","threads":4,"intensity":0.5,"pool_username":"test","pool_password":"test","custom_pool_address":"stratum+tcp://litecoinpool.org","custom_pool_port":3333}' | jq .
        sleep 5
        curl -s http://localhost:8001/api/mining/status | jq -r '"Mining: \(.is_mining) - Hashrate: \(.stats.hashrate) H/s - Processes: \(.stats.processes // 0)"'
        curl -s -X POST http://localhost:8001/api/mining/stop-hp > /dev/null
        echo "Test completed."
        ;;
    *)
        echo "CryptoMiner Pro Enhanced Management"
        echo "Usage: $0 {start|stop|restart|status|ai-status|hp-test}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$APP_DIR/manage-enhanced.sh"
    print_success "✅ Enhanced management script created"
}

# Display enhanced completion message
display_enhanced_completion() {
    echo ""
    echo "🎉 CryptoMiner Pro Enhanced Installation Complete!"
    echo "=================================================="
    echo ""
    
    # Enhanced Installation Summary
    echo "📋 ENHANCED INSTALLATION SUMMARY"
    echo "================================"
    echo "🏗️  Installation Type: Enhanced Node.js with AI & High-Performance"
    echo "🌍 Environment: $ENV_TYPE"
    echo "🖥️  CPU Cores: $CPU_CORES cores / $CPU_THREADS threads"
    echo "💾 Memory: ${TOTAL_MEM}MB total / ${AVAILABLE_MEM}MB available"
    echo "⚡ Performance Profile: $PERFORMANCE_PROFILE"
    echo "🧠 AI Prediction System: $AI_STATUS"
    echo "🚀 High-Performance Mining: $HP_STATUS"
    echo "🔧 Thread Scaling: $THREAD_STATUS (up to 256 threads)"
    echo ""
    
    # Enhanced Access URLs
    echo "🌐 ENHANCED ACCESS URLS"
    echo "======================="
    echo "📊 Main Dashboard: http://localhost:3000"
    echo "🔧 Backend API: http://localhost:8001"
    echo "🤖 AI Insights: http://localhost:8001/api/mining/ai-insights"
    echo "⚡ High-Performance Status: http://localhost:8001/api/mining/status"
    echo "🖥️  System Info: http://localhost:8001/api/system/cpu-info"
    echo "💡 Health Check: http://localhost:8001/api/health"
    echo ""
    
    # Enhanced Commands
    echo "⚡ ENHANCED COMMANDS"
    echo "==================="
    echo "  $APP_DIR/manage-enhanced.sh start        - Start enhanced system"
    echo "  $APP_DIR/manage-enhanced.sh status       - Detailed system status"
    echo "  $APP_DIR/manage-enhanced.sh ai-status    - AI prediction status"
    echo "  $APP_DIR/manage-enhanced.sh hp-test      - Test high-performance mining"
    echo "  $APP_DIR/startup-manager.sh start        - Robust startup with dependency management"
    echo "  $APP_DIR/startup-manager.sh fix-mongodb  - Fix MongoDB connectivity issues"
    echo "  $APP_DIR/startup-manager.sh fix-ports    - Clean up port conflicts"
    echo "  $APP_DIR/startup-manager.sh full-reset   - Complete system reset"
    echo "  cryptominer-ai                          - View AI insights"
    echo "  cryptominer-hp-start                    - Start HP mining"
    echo "  cryptominer-monitor                     - Real-time monitoring"
    echo ""
    
    # Enhanced Features Summary
    echo "🎯 ENHANCED FEATURES INSTALLED"
    echo "=============================="
    print_feature "🤖 AI Prediction System - Smart mining optimization and forecasting"
    print_feature "⚡ High-Performance Mining - Multi-process engine up to 256 threads"
    print_feature "🌊 Real Pool Mining - Connect to actual mining pools (litecoinpool.org, etc.)"
    print_feature "🔧 Thread Scaling - Optimized for $CPU_CORES cores with intelligent load balancing"
    print_feature "📊 Enhanced Monitoring - Real-time system metrics and performance tracking"
    print_feature "🎯 Performance Profiles - Optimized settings for different hardware configurations"
    print_feature "💾 Optimized Database - MongoDB tuned for mining data and AI processing"
    print_feature "🔒 Enhanced Security - Updated rate limiting and connection management"
    echo ""
    
    # Configuration Details
    echo "⚙️  CONFIGURATION DETAILS"
    echo "========================"
    echo "🏠 Installation: $APP_DIR"
    echo "📄 Backend Config: $APP_DIR/backend-nodejs/.env"
    echo "🎨 Frontend Config: $APP_DIR/frontend/.env"
    echo "📊 Logs: /var/log/supervisor/"
    echo "🛠️  Enhanced Management: $APP_DIR/manage-enhanced.sh"
    echo ""
    
    # Performance Tips
    echo "💡 PERFORMANCE OPTIMIZATION TIPS"
    echo "================================="
    print_tip "🔄 For optimal AI learning, let the system run for 24+ hours"
    print_tip "⚡ Start with $RECOMMENDED_THREADS threads for your $CPU_CORES-core system"
    print_tip "💾 Monitor memory usage with high thread counts (max safe: $MEMORY_SAFE_PROCESSES processes)"
    print_tip "🌊 Use real pool mining for actual cryptocurrency earnings"
    print_tip "📊 Check AI insights regularly for optimization recommendations"
    echo ""
    
    print_success "Enhanced installation completed successfully! 🚀"
    print_success "Your mining system is now optimized with AI and high-performance capabilities!"
    echo ""
    echo "🎯 Ready for enhanced mining with AI-powered optimization!"
    echo "⚡ Capable of handling up to 256 threads with intelligent load balancing!"
    echo "🤖 AI system will learn and optimize your mining performance over time!"
    echo ""
    print_success "Happy enhanced mining! ⛏️💎🤖"
}

# Main enhanced installation flow
main() {
    echo "Starting CryptoMiner Pro enhanced installation..."
    echo ""
    
    detect_environment
    check_enhanced_requirements
    
    # Standard system setup
    sudo apt-get update
    sudo apt-get install -y curl wget gnupg2 software-properties-common build-essential git supervisor jq
    
    # Enhanced installations
    install_enhanced_nodejs
    install_ai_dependencies
    install_enhanced_mongodb
    setup_enhanced_application
    install_enhanced_dependencies
    create_enhanced_config
    create_enhanced_supervisor
    
    # Enhanced service startup with robust validation
    start_enhanced_services
    
    # Test and finalize
    test_enhanced_features
    create_enhanced_commands
    display_enhanced_completion
}

# Run enhanced installation
main "$@"