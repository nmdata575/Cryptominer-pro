#!/bin/bash

# CryptoMiner Pro - Robust Startup Management Script
# Handles MongoDB connectivity, port conflicts, and service dependencies

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

# Check if MongoDB is running and start if needed
ensure_mongodb() {
    print_step "Checking MongoDB status..."
    
    if pgrep mongod > /dev/null; then
        print_status "✅ MongoDB is already running"
        return 0
    fi
    
    print_warning "MongoDB not running, attempting to start..."
    
    # Detect environment type
    if [[ -f /.dockerenv ]] || [[ -n "${KUBERNETES_SERVICE_HOST}" ]]; then
        # Container environment - use manual start
        print_status "Starting MongoDB manually (container environment)..."
        sudo mkdir -p /data/db /var/log/mongodb
        sudo chown -R mongodb:mongodb /data/db /var/log/mongodb 2>/dev/null || sudo chown -R root:root /data/db /var/log/mongodb
        
        if sudo mongod --dbpath /data/db --logpath /var/log/mongodb/mongod.log --fork; then
            print_status "✅ MongoDB started manually"
            sleep 5
            return 0
        else
            print_error "❌ Failed to start MongoDB manually"
            return 1
        fi
    else
        # Native environment - try systemd first
        if command -v systemctl >/dev/null 2>&1; then
            if sudo systemctl start mongod 2>/dev/null; then
                print_status "✅ MongoDB started via systemd"
                sleep 3
                return 0
            fi
        fi
        
        # Fallback to manual start
        print_status "Starting MongoDB manually..."
        sudo mkdir -p /data/db /var/log/mongodb
        sudo chown -R mongodb:mongodb /data/db /var/log/mongodb 2>/dev/null || sudo chown -R root:root /data/db /var/log/mongodb
        
        if sudo mongod --dbpath /data/db --logpath /var/log/mongodb/mongod.log --fork; then
            print_status "✅ MongoDB started manually"
            sleep 5
            return 0
        else
            print_error "❌ Failed to start MongoDB"
            return 1
        fi
    fi
}

# Clean up port conflicts
cleanup_ports() {
    print_step "Cleaning up potential port conflicts..."
    
    PORTS=(8001 3000)
    
    for PORT in "${PORTS[@]}"; do
        if sudo lsof -i :$PORT >/dev/null 2>&1; then
            print_warning "Port $PORT is in use, cleaning up..."
            
            # Get PIDs using the port
            PIDS=$(sudo lsof -t -i :$PORT 2>/dev/null || true)
            
            if [ -n "$PIDS" ]; then
                print_status "Terminating processes on port $PORT: $PIDS"
                # Graceful termination first
                sudo kill -TERM $PIDS 2>/dev/null || true
                sleep 2
                
                # Force kill if still running
                REMAINING=$(sudo lsof -t -i :$PORT 2>/dev/null || true)
                if [ -n "$REMAINING" ]; then
                    print_status "Force killing stubborn processes: $REMAINING"
                    sudo kill -KILL $REMAINING 2>/dev/null || true
                fi
            fi
        fi
    done
    
    # Clean up any orphaned node processes
    sudo pkill -f "node.*server.js" 2>/dev/null || true
    sudo pkill -f "npm.*start" 2>/dev/null || true
    
    sleep 2
    print_status "✅ Port cleanup completed"
}

# Verify MongoDB connectivity
verify_mongodb() {
    print_step "Verifying MongoDB connectivity..."
    
    MAX_RETRIES=10
    RETRY_COUNT=0
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if timeout 5 mongosh --eval "db.runCommand('ping')" --quiet --host 127.0.0.1:27017 >/dev/null 2>&1; then
            print_status "✅ MongoDB is accessible via mongosh"
            return 0
        elif timeout 5 mongo --eval "db.runCommand('ping')" --quiet --host 127.0.0.1:27017 >/dev/null 2>&1; then
            print_status "✅ MongoDB is accessible via legacy mongo client"
            return 0
        fi
        
        RETRY_COUNT=$((RETRY_COUNT + 1))
        print_status "MongoDB connection attempt $RETRY_COUNT/$MAX_RETRIES..."
        sleep 2
    done
    
    print_error "❌ MongoDB connectivity verification failed after $MAX_RETRIES attempts"
    print_warning "MongoDB may still be working - this could be a connection timeout issue"
    return 1
}

# Start services with proper dependency order
start_services() {
    print_step "Starting CryptoMiner Pro services..."
    
    # Ensure supervisor is running
    if ! pgrep supervisord > /dev/null; then
        print_status "Starting supervisor..."
        sudo supervisord -c /etc/supervisor/supervisord.conf || true
        sleep 3
    fi
    
    # Update supervisor configuration
    sudo supervisorctl reread >/dev/null 2>&1 || true
    sudo supervisorctl update >/dev/null 2>&1 || true
    
    # Start backend first
    print_step "Starting backend service..."
    if sudo supervisorctl start mining_system:backend >/dev/null 2>&1; then
        print_status "✅ Backend service started"
    else
        print_warning "Backend start command issued, checking status..."
    fi
    
    # Wait for backend to stabilize
    print_step "Waiting for backend to stabilize..."
    sleep 10
    
    # Verify backend API
    MAX_API_RETRIES=15
    API_RETRY_COUNT=0
    BACKEND_READY=false
    
    while [ $API_RETRY_COUNT -lt $MAX_API_RETRIES ] && [ "$BACKEND_READY" = false ]; do
        API_RETRY_COUNT=$((API_RETRY_COUNT + 1))
        
        if curl -s -f http://localhost:8001/api/health >/dev/null 2>&1; then
            BACKEND_READY=true
            print_status "✅ Backend API is responding"
        else
            print_status "Waiting for backend API (attempt $API_RETRY_COUNT/$MAX_API_RETRIES)..."
            sleep 2
        fi
    done
    
    if [ "$BACKEND_READY" = false ]; then
        print_error "❌ Backend API failed to respond"
        print_status "Backend logs:"
        sudo tail -10 /var/log/supervisor/backend.err.log 2>/dev/null || echo "No backend error logs found"
        return 1
    fi
    
    # Start frontend
    print_step "Starting frontend service..."
    if sudo supervisorctl start mining_system:frontend >/dev/null 2>&1; then
        print_status "✅ Frontend service started"
    else
        print_warning "Frontend start command issued, checking status..."
    fi
    
    sleep 5
    return 0
}

# Check overall system status
check_status() {
    print_step "Checking system status..."
    
    echo ""
    echo "📊 Service Status:"
    sudo supervisorctl status mining_system:* 2>/dev/null || echo "No mining services found in supervisor"
    
    echo ""
    echo "🔍 Process Status:"
    echo "MongoDB: $(pgrep mongod >/dev/null && echo "✅ Running (PID: $(pgrep mongod))" || echo "❌ Not running")"
    echo "Backend: $(pgrep -f "node.*server.js" >/dev/null && echo "✅ Running" || echo "❌ Not running")"
    echo "Frontend: $(pgrep -f "npm.*start" >/dev/null && echo "✅ Running" || echo "❌ Not running")"
    
    echo ""
    echo "🌐 Connectivity Status:"
    echo "Backend API: $(curl -s http://localhost:8001/api/health >/dev/null && echo "✅ Responding" || echo "❌ Not responding")"
    echo "Frontend: $(curl -s http://localhost:3000 >/dev/null && echo "✅ Accessible" || echo "❌ Not accessible")"
    echo "MongoDB: $(mongosh --eval "db.runCommand('ping')" --quiet >/dev/null 2>&1 && echo "✅ Connected" || echo "❌ Connection failed")"
}

# Main execution
case "${1:-start}" in
    start)
        echo "🚀 CryptoMiner Pro - Robust Startup"
        echo "===================================="
        
        ensure_mongodb || exit 1
        verify_mongodb || exit 1
        cleanup_ports
        start_services || exit 1
        
        echo ""
        print_status "🎉 Startup sequence completed successfully!"
        echo ""
        check_status
        ;;
        
    stop)
        echo "⏹️ Stopping CryptoMiner Pro services..."
        sudo supervisorctl stop mining_system:* 2>/dev/null || echo "No services to stop"
        ;;
        
    restart)
        echo "🔄 Restarting CryptoMiner Pro..."
        $0 stop
        sleep 3
        $0 start
        ;;
        
    status)
        check_status
        ;;
        
    fix-mongodb)
        echo "🔧 MongoDB Fix Sequence"
        echo "======================"
        
        # Stop services first
        sudo supervisorctl stop mining_system:* 2>/dev/null || true
        
        # Kill any existing MongoDB processes
        sudo pkill -f mongod 2>/dev/null || true
        sleep 3
        
        # Start MongoDB
        ensure_mongodb || exit 1
        verify_mongodb || exit 1
        
        print_status "✅ MongoDB fix completed"
        ;;
        
    fix-ports)
        echo "🔧 Port Conflict Fix"
        echo "==================="
        
        cleanup_ports
        print_status "✅ Port fix completed"
        ;;
        
    full-reset)
        echo "🔄 Full System Reset"
        echo "==================="
        
        # Stop all services
        sudo supervisorctl stop mining_system:* 2>/dev/null || true
        
        # Clean up processes and ports
        sudo pkill -f mongod 2>/dev/null || true
        sudo pkill -f "node.*server.js" 2>/dev/null || true
        sudo pkill -f "npm.*start" 2>/dev/null || true
        cleanup_ports
        
        sleep 5
        
        # Start everything fresh
        $0 start
        ;;
        
    *)
        echo "🔧 CryptoMiner Pro - Robust Startup Management"
        echo "=============================================="
        echo ""
        echo "Usage: $0 {start|stop|restart|status|fix-mongodb|fix-ports|full-reset}"
        echo ""
        echo "Commands:"
        echo "  start         - Start all services with dependency management"
        echo "  stop          - Stop all services"
        echo "  restart       - Restart all services"
        echo "  status        - Check detailed system status"
        echo "  fix-mongodb   - Fix MongoDB connectivity issues"
        echo "  fix-ports     - Clean up port conflicts"
        echo "  full-reset    - Complete system reset and restart"
        echo ""
        exit 1
        ;;
esac