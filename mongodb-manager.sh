#!/bin/bash

# MongoDB Management Script for Container Environments
# Handles MongoDB without systemd

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# MongoDB configuration
MONGODB_DBPATH="/data/db"
MONGODB_LOGPATH="/var/log/mongodb.log"
MONGODB_CONFIGPATH="/etc/mongod.conf"

# Check if MongoDB is running
is_mongodb_running() {
    pgrep mongod >/dev/null 2>&1
}

# Start MongoDB
start_mongodb() {
    if is_mongodb_running; then
        print_status "MongoDB is already running (PID: $(pgrep mongod))"
        return 0
    fi
    
    print_step "Starting MongoDB..."
    
    # Ensure directories exist
    sudo mkdir -p "$MONGODB_DBPATH" "$(dirname "$MONGODB_LOGPATH")"
    sudo chown -R mongodb:mongodb "$MONGODB_DBPATH" "$(dirname "$MONGODB_LOGPATH")" 2>/dev/null || \
    sudo chown -R root:root "$MONGODB_DBPATH" "$(dirname "$MONGODB_LOGPATH")"
    
    # Start MongoDB manually (container-friendly)
    if sudo mongod --dbpath "$MONGODB_DBPATH" --logpath "$MONGODB_LOGPATH" --fork; then
        sleep 3
        if is_mongodb_running; then
            print_status "✅ MongoDB started successfully (PID: $(pgrep mongod))"
            return 0
        else
            print_error "❌ MongoDB failed to start"
            return 1
        fi
    else
        print_error "❌ MongoDB start command failed"
        return 1
    fi
}

# Stop MongoDB
stop_mongodb() {
    if ! is_mongodb_running; then
        print_status "MongoDB is not running"
        return 0
    fi
    
    print_step "Stopping MongoDB..."
    
    # Try graceful shutdown first
    if mongosh --eval "db.adminCommand('shutdown')" >/dev/null 2>&1; then
        sleep 3
        if ! is_mongodb_running; then
            print_status "✅ MongoDB stopped gracefully"
            return 0
        fi
    fi
    
    # Force kill if graceful shutdown failed
    print_warning "Graceful shutdown failed, force stopping..."
    sudo pkill -TERM mongod
    sleep 3
    
    if is_mongodb_running; then
        sudo pkill -KILL mongod
        sleep 2
    fi
    
    if ! is_mongodb_running; then
        print_status "✅ MongoDB stopped"
        return 0
    else
        print_error "❌ Failed to stop MongoDB"
        return 1
    fi
}

# Restart MongoDB
restart_mongodb() {
    print_step "Restarting MongoDB..."
    stop_mongodb
    sleep 2
    start_mongodb
}

# Check MongoDB status
status_mongodb() {
    if is_mongodb_running; then
        local pid=$(pgrep mongod)
        print_status "✅ MongoDB is running (PID: $pid)"
        
        # Test connectivity
        if mongosh --eval "db.runCommand('ping')" --quiet >/dev/null 2>&1; then
            print_status "✅ MongoDB is responding to connections"
        else
            print_warning "⚠️ MongoDB is running but not responding"
        fi
        
        # Show connection info
        print_step "Connection details:"
        echo "  Database path: $MONGODB_DBPATH"
        echo "  Log file: $MONGODB_LOGPATH"
        echo "  Connection: mongodb://localhost:27017"
        
        return 0
    else
        print_error "❌ MongoDB is not running"
        return 1
    fi
}

# Fix common MongoDB issues
fix_mongodb() {
    print_step "Running MongoDB diagnostics and fixes..."
    
    # Check and fix directory permissions
    if [[ ! -d "$MONGODB_DBPATH" ]]; then
        print_step "Creating MongoDB data directory..."
        sudo mkdir -p "$MONGODB_DBPATH"
    fi
    
    if [[ ! -w "$MONGODB_DBPATH" ]]; then
        print_step "Fixing MongoDB data directory permissions..."
        sudo chown -R mongodb:mongodb "$MONGODB_DBPATH" 2>/dev/null || \
        sudo chown -R root:root "$MONGODB_DBPATH"
        sudo chmod 755 "$MONGODB_DBPATH"
    fi
    
    # Check for lock files
    if [[ -f "$MONGODB_DBPATH/mongod.lock" ]]; then
        print_warning "Found stale lock file, removing..."
        sudo rm -f "$MONGODB_DBPATH/mongod.lock"
    fi
    
    # Check log file
    if [[ -f "$MONGODB_LOGPATH" ]]; then
        local log_size=$(du -h "$MONGODB_LOGPATH" | cut -f1)
        print_status "Log file size: $log_size"
        
        # Show recent errors if any
        if grep -i error "$MONGODB_LOGPATH" | tail -5 >/dev/null 2>&1; then
            print_warning "Recent errors in log:"
            grep -i error "$MONGODB_LOGPATH" | tail -5 | sed 's/^/  /'
        fi
    fi
    
    print_status "✅ MongoDB diagnostics completed"
}

# Main command handling
case "${1:-status}" in
    start)
        start_mongodb
        ;;
    stop)
        stop_mongodb
        ;;
    restart)
        restart_mongodb
        ;;
    status)
        status_mongodb
        ;;
    fix)
        fix_mongodb
        ;;
    logs)
        if [[ -f "$MONGODB_LOGPATH" ]]; then
            print_step "MongoDB logs (last 20 lines):"
            tail -20 "$MONGODB_LOGPATH"
        else
            print_error "Log file not found: $MONGODB_LOGPATH"
        fi
        ;;
    *)
        echo "🗄️ MongoDB Management Script for Container Environments"
        echo "====================================================="
        echo ""
        echo "Usage: $0 {start|stop|restart|status|fix|logs}"
        echo ""
        echo "Commands:"
        echo "  start    - Start MongoDB service"
        echo "  stop     - Stop MongoDB service"
        echo "  restart  - Restart MongoDB service"
        echo "  status   - Check MongoDB status and connectivity"
        echo "  fix      - Run diagnostics and fix common issues"
        echo "  logs     - Show recent MongoDB logs"
        echo ""
        echo "Note: This script is designed for container environments"
        echo "      where systemd is not available."
        ;;
esac