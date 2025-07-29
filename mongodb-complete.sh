#!/bin/bash

# MongoDB Startup Script with Environment File Support
# Uses /etc/default/mongod for configuration

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

# Load MongoDB environment configuration
MONGODB_ENV_FILE="/etc/default/mongod"
if [[ -f "$MONGODB_ENV_FILE" ]]; then
    print_status "Loading MongoDB configuration from $MONGODB_ENV_FILE"
    source "$MONGODB_ENV_FILE"
else
    print_error "MongoDB environment file not found: $MONGODB_ENV_FILE"
    print_step "Creating default environment file..."
    
    # Create basic environment file if missing
    sudo tee "$MONGODB_ENV_FILE" > /dev/null <<'EOF'
# MongoDB environment configuration
DAEMON_USER="mongodb"
DAEMON_GROUP="mongodb"
MONGODB_DBPATH="/var/lib/mongodb"
MONGODB_LOGPATH="/var/log/mongodb"
MONGODB_CONFIG="/etc/mongod.conf"
MONGODB_PIDFILE="/var/run/mongodb/mongod.pid"
ENABLE_MONGOD="yes"
MONGODB_BIND_IP="127.0.0.1"
MONGODB_PORT="27017"
EOF
    
    source "$MONGODB_ENV_FILE"
    print_status "Created and loaded default environment file"
fi

# Set defaults if not defined in environment file
DAEMON_USER=${DAEMON_USER:-"mongodb"}
DAEMON_GROUP=${DAEMON_GROUP:-"mongodb"}
MONGODB_DBPATH=${MONGODB_DBPATH:-"/var/lib/mongodb"}
MONGODB_LOGPATH=${MONGODB_LOGPATH:-"/var/log/mongodb"}
MONGODB_CONFIG=${MONGODB_CONFIG:-"/etc/mongod.conf"}
MONGODB_PIDFILE=${MONGODB_PIDFILE:-"/var/run/mongodb/mongod.pid"}
MONGODB_BIND_IP=${MONGODB_BIND_IP:-"127.0.0.1"}
MONGODB_PORT=${MONGODB_PORT:-"27017"}
ENABLE_MONGOD=${ENABLE_MONGOD:-"yes"}

# Check if MongoDB should be enabled
if [[ "$ENABLE_MONGOD" != "yes" ]]; then
    print_warning "MongoDB is disabled in $MONGODB_ENV_FILE (ENABLE_MONGOD=$ENABLE_MONGOD)"
    exit 0
fi

# Function to check if MongoDB is running
is_mongodb_running() {
    if [[ -f "$MONGODB_PIDFILE" ]]; then
        local pid=$(cat "$MONGODB_PIDFILE" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            # Remove stale PID file
            sudo rm -f "$MONGODB_PIDFILE"
        fi
    fi
    
    # Also check by process name
    pgrep mongod >/dev/null 2>&1
}

# Function to prepare MongoDB directories
prepare_directories() {
    print_step "Preparing MongoDB directories..."
    
    # Create directories
    sudo mkdir -p "$(dirname "$MONGODB_DBPATH")" "$(dirname "$MONGODB_LOGPATH")" "$(dirname "$MONGODB_PIDFILE")"
    sudo mkdir -p "$MONGODB_DBPATH" "$MONGODB_LOGPATH"
    
    # Check if user exists and set ownership
    if id "$DAEMON_USER" >/dev/null 2>&1; then
        sudo chown -R "$DAEMON_USER:$DAEMON_GROUP" "$MONGODB_DBPATH" "$MONGODB_LOGPATH" "$(dirname "$MONGODB_PIDFILE")"
        print_status "Set ownership to $DAEMON_USER:$DAEMON_GROUP"
    else
        print_warning "User $DAEMON_USER not found, using root ownership"
        sudo chown -R root:root "$MONGODB_DBPATH" "$MONGODB_LOGPATH" "$(dirname "$MONGODB_PIDFILE")"
    fi
    
    # Set permissions
    sudo chmod 755 "$MONGODB_DBPATH" "$MONGODB_LOGPATH" "$(dirname "$MONGODB_PIDFILE")"
    
    # Remove any stale lock files
    if [[ -f "$MONGODB_DBPATH/mongod.lock" ]]; then
        print_warning "Removing stale lock file"
        sudo rm -f "$MONGODB_DBPATH/mongod.lock"
    fi
}

# Function to start MongoDB
start_mongodb() {
    if is_mongodb_running; then
        print_status "MongoDB is already running"
        return 0
    fi
    
    print_step "Starting MongoDB with environment configuration..."
    
    prepare_directories
    
    # Build MongoDB command
    local mongod_cmd="mongod"
    local mongod_args=""
    
    # Use config file if it exists
    if [[ -f "$MONGODB_CONFIG" ]]; then
        mongod_args="$mongod_args --config $MONGODB_CONFIG"
        print_status "Using config file: $MONGODB_CONFIG"
    else
        # Build args from environment variables
        mongod_args="$mongod_args --dbpath $MONGODB_DBPATH"
        mongod_args="$mongod_args --logpath $MONGODB_LOGPATH/mongod.log"
        mongod_args="$mongod_args --bind_ip $MONGODB_BIND_IP"
        mongod_args="$mongod_args --port $MONGODB_PORT"
        print_status "Using command-line arguments (no config file found)"
    fi
    
    # Add fork and PID file options
    mongod_args="$mongod_args --fork --pidfilepath $MONGODB_PIDFILE"
    
    # Start MongoDB
    print_step "Executing: $mongod_cmd $mongod_args"
    
    if sudo -u "$DAEMON_USER" $mongod_cmd $mongod_args 2>/dev/null || sudo $mongod_cmd $mongod_args; then
        # Wait for MongoDB to start
        local timeout=30
        local count=0
        
        while [[ $count -lt $timeout ]]; do
            if is_mongodb_running; then
                print_status "✅ MongoDB started successfully"
                
                # Test connectivity
                sleep 2
                if mongosh --eval "db.runCommand('ping')" --quiet >/dev/null 2>&1; then
                    print_status "✅ MongoDB is accepting connections"
                    return 0
                else
                    print_warning "MongoDB started but not yet accepting connections"
                fi
            fi
            
            sleep 1
            count=$((count + 1))
        done
        
        print_error "❌ MongoDB failed to start within $timeout seconds"
        return 1
    else
        print_error "❌ Failed to start MongoDB"
        return 1
    fi
}

# Function to stop MongoDB
stop_mongodb() {
    if ! is_mongodb_running; then
        print_status "MongoDB is not running"
        return 0
    fi
    
    print_step "Stopping MongoDB..."
    
    # Try graceful shutdown first
    if mongosh --eval "db.adminCommand('shutdown')" >/dev/null 2>&1; then
        sleep 5
        if ! is_mongodb_running; then
            print_status "✅ MongoDB stopped gracefully"
            sudo rm -f "$MONGODB_PIDFILE"
            return 0
        fi
    fi
    
    # Try using PID file
    if [[ -f "$MONGODB_PIDFILE" ]]; then
        local pid=$(cat "$MONGODB_PIDFILE")
        if [[ -n "$pid" ]]; then
            print_step "Stopping MongoDB process (PID: $pid)"
            sudo kill -TERM "$pid" 2>/dev/null || true
            sleep 5
            
            if ! kill -0 "$pid" 2>/dev/null; then
                print_status "✅ MongoDB stopped"
                sudo rm -f "$MONGODB_PIDFILE"
                return 0
            fi
            
            # Force kill if necessary
            sudo kill -KILL "$pid" 2>/dev/null || true
            sleep 2
        fi
    fi
    
    # Force kill any remaining mongod processes
    sudo pkill -f mongod 2>/dev/null || true
    sleep 2
    
    # Clean up PID file
    sudo rm -f "$MONGODB_PIDFILE"
    
    if ! is_mongodb_running; then
        print_status "✅ MongoDB stopped"
        return 0
    else
        print_error "❌ Failed to stop MongoDB"
        return 1
    fi
}

# Function to check MongoDB status
status_mongodb() {
    print_step "MongoDB Status Check"
    
    if is_mongodb_running; then
        local pid
        if [[ -f "$MONGODB_PIDFILE" ]]; then
            pid=$(cat "$MONGODB_PIDFILE")
            print_status "✅ MongoDB is running (PID: $pid from PID file)"
        else
            pid=$(pgrep mongod)
            print_status "✅ MongoDB is running (PID: $pid from process list)"
        fi
        
        # Test connectivity
        if timeout 10 mongosh --eval "db.runCommand('ping')" --quiet --host 127.0.0.1:27017 >/dev/null 2>&1; then
            print_status "✅ MongoDB is accepting connections"
        elif timeout 10 mongo --eval "db.runCommand('ping')" --quiet --host 127.0.0.1:27017 >/dev/null 2>&1; then
            print_status "✅ MongoDB is accepting connections (legacy client)"
        else
            print_warning "⚠️ MongoDB is running but connection tests failed (may still be working)"
        fi
        
        # Show configuration
        print_step "Configuration:"
        echo "  Database path: $MONGODB_DBPATH"
        echo "  Log path: $MONGODB_LOGPATH"
        echo "  Config file: $MONGODB_CONFIG"
        echo "  PID file: $MONGODB_PIDFILE"
        echo "  Bind IP: $MONGODB_BIND_IP"
        echo "  Port: $MONGODB_PORT"
        echo "  User: $DAEMON_USER"
        
        return 0
    else
        print_error "❌ MongoDB is not running"
        return 1
    fi
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
        stop_mongodb
        sleep 2
        start_mongodb
        ;;
    status)
        status_mongodb
        ;;
    *)
        echo "🗄️ MongoDB Management Script with Environment File Support"
        echo "========================================================="
        echo ""
        echo "Usage: $0 {start|stop|restart|status}"
        echo ""
        echo "Configuration is loaded from: $MONGODB_ENV_FILE"
        echo ""
        ;;
esac