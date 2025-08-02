#!/bin/bash

# CryptoMiner Pro - Configuration Verification & Fix Script
# Detects environment and fixes common configuration issues

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

echo "🔧 CryptoMiner Pro - Configuration Verification & Fix"
echo "===================================================="
echo ""

# Detect environment
print_step "Detecting environment..."

if [[ -f /.dockerenv ]]; then
    ENV_TYPE="docker"
    BACKEND_URL="https://b8a64dbe-314e-43b8-9274-f05e86511466.preview.emergentagent.com"
    print_status "🐳 Docker container detected"
elif [[ -n "${KUBERNETES_SERVICE_HOST}" ]]; then
    ENV_TYPE="kubernetes"
    BACKEND_URL="https://b8a64dbe-314e-43b8-9274-f05e86511466.preview.emergentagent.com"
    print_status "☸️ Kubernetes environment detected"
else
    ENV_TYPE="native"
    BACKEND_URL="http://localhost:8001"
    print_status "💻 Native system detected"
fi

# Check and fix frontend .env configuration
print_step "Checking frontend configuration..."

FRONTEND_ENV_FILE="/app/frontend/.env"
if [[ -f "$FRONTEND_ENV_FILE" ]]; then
    CURRENT_BACKEND_URL=$(grep "REACT_APP_BACKEND_URL" "$FRONTEND_ENV_FILE" | cut -d'=' -f2)
    
    if [[ "$CURRENT_BACKEND_URL" != "$BACKEND_URL" ]]; then
        print_warning "Backend URL mismatch detected:"
        echo "  Current: $CURRENT_BACKEND_URL"
        echo "  Expected: $BACKEND_URL"
        
        print_step "Fixing frontend configuration..."
        
        # Backup original
        cp "$FRONTEND_ENV_FILE" "${FRONTEND_ENV_FILE}.backup.$(date +%s)"
        
        # Update backend URL and fix file format
        sed -i "s|^REACT_APP_BACKEND_URL=.*|REACT_APP_BACKEND_URL=$BACKEND_URL|" "$FRONTEND_ENV_FILE"
        
        # Ensure proper file format
        chmod 644 "$FRONTEND_ENV_FILE"
        # Add final newline if missing
        if [[ -n "$(tail -c1 "$FRONTEND_ENV_FILE")" ]]; then
            echo "" >> "$FRONTEND_ENV_FILE"
        fi
        
        print_status "✅ Frontend configuration updated"
        FRONTEND_RESTART_NEEDED=true
    else
        print_status "✅ Frontend configuration is correct"
    fi
else
    print_error "Frontend .env file not found at $FRONTEND_ENV_FILE"
    print_step "Creating frontend .env file..."
    
    cat > "$FRONTEND_ENV_FILE" <<EOF
REACT_APP_BACKEND_URL=$BACKEND_URL
GENERATE_SOURCEMAP=false
FAST_REFRESH=true
ESLINT_NO_CACHE=true
EOF
    
    if [[ "$ENV_TYPE" != "native" ]]; then
        echo "DANGEROUSLY_DISABLE_HOST_CHECK=true" >> "$FRONTEND_ENV_FILE"
    fi
    
    print_status "✅ Frontend .env file created"
    FRONTEND_RESTART_NEEDED=true
fi

# Check backend .env configuration for native systems
if [[ "$ENV_TYPE" == "native" ]]; then
    print_step "Checking backend configuration for native system..."
    
    BACKEND_ENV_FILE="/app/backend-nodejs/.env"
    if [[ -f "$BACKEND_ENV_FILE" ]]; then
        # Check for CPU override settings
        if ! grep -q "ACTUAL_CPU_CORES" "$BACKEND_ENV_FILE"; then
            print_step "Adding CPU detection enhancements..."
            
            # Detect actual CPU cores
            ACTUAL_CORES=$(nproc --all)
            
            cat >> "$BACKEND_ENV_FILE" <<EOF

# Hardware Override (for systems with more cores than container allocation)
ACTUAL_CPU_CORES=$ACTUAL_CORES
FORCE_CPU_OVERRIDE=true
EOF
            
            print_status "✅ Added CPU override for $ACTUAL_CORES cores"
            BACKEND_RESTART_NEEDED=true
        fi
    fi
fi

# Check MongoDB status
print_step "Checking MongoDB status..."

if pgrep mongod > /dev/null; then
    print_status "✅ MongoDB is running"
    
    # Test connectivity
    if mongosh --eval "db.runCommand('ping')" --quiet >/dev/null 2>&1; then
        print_status "✅ MongoDB connectivity verified"
    elif mongo --eval "db.runCommand('ping')" --quiet >/dev/null 2>&1; then
        print_status "✅ MongoDB connectivity verified (legacy client)"
    else
        print_warning "MongoDB running but connectivity failed"
        MONGODB_RESTART_NEEDED=true
    fi
else
    print_warning "MongoDB not running"
    print_step "Starting MongoDB..."
    
    # Try systemd first (for native systems)
    if [[ "$ENV_TYPE" == "native" ]] && command -v systemctl >/dev/null 2>&1; then
        if sudo systemctl start mongod 2>/dev/null; then
            print_status "✅ MongoDB started via systemd"
        else
            # Fallback to manual start
            sudo mongod --dbpath /data/db --logpath /var/log/mongodb.log --fork
            print_status "✅ MongoDB started manually"
        fi
    else
        # For container environments
        sudo mongod --dbpath /data/db --logpath /var/log/mongodb.log --fork
        print_status "✅ MongoDB started manually"
    fi
    
    sleep 3
fi

# Check service status and restart if needed
print_step "Checking service status..."

if command -v supervisorctl >/dev/null 2>&1; then
    BACKEND_STATUS=$(sudo supervisorctl status mining_system:backend 2>/dev/null | grep -o "RUNNING" || echo "NOT_RUNNING")
    FRONTEND_STATUS=$(sudo supervisorctl status mining_system:frontend 2>/dev/null | grep -o "RUNNING" || echo "NOT_RUNNING")
    
    if [[ "$BACKEND_STATUS" != "RUNNING" ]] || [[ -n "$BACKEND_RESTART_NEEDED" ]]; then
        print_step "Restarting backend service..."
        sudo supervisorctl restart mining_system:backend || sudo supervisorctl start mining_system:backend
        sleep 5
    fi
    
    if [[ "$FRONTEND_STATUS" != "RUNNING" ]] || [[ -n "$FRONTEND_RESTART_NEEDED" ]]; then
        print_step "Restarting frontend service..."
        sudo supervisorctl restart mining_system:frontend || sudo supervisorctl start mining_system:frontend
        sleep 10
    fi
    
    # Final status check
    print_step "Final service verification..."
    
    # Test backend API
    if curl -s -f http://localhost:8001/api/health >/dev/null 2>&1; then
        print_status "✅ Backend API responding"
        
        # Test coin presets specifically
        COIN_COUNT=$(curl -s http://localhost:8001/api/coins/presets | jq length 2>/dev/null || echo "0")
        if [[ "$COIN_COUNT" -ge 3 ]]; then
            print_status "✅ Coin presets API working ($COIN_COUNT coins available)"
        else
            print_warning "⚠️ Coin presets API issue (only $COIN_COUNT coins found)"
        fi
        
        # Test CPU info
        CPU_CORES=$(curl -s http://localhost:8001/api/system/cpu-info | jq -r '.cores.physical' 2>/dev/null || echo "unknown")
        if [[ "$CPU_CORES" != "unknown" ]] && [[ "$CPU_CORES" -gt 0 ]]; then
            print_status "✅ CPU detection working ($CPU_CORES cores detected)"
        else
            print_warning "⚠️ CPU detection needs attention"
        fi
    else
        print_error "❌ Backend API not responding"
    fi
    
    # Test frontend
    if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
        print_status "✅ Frontend accessible"
    else
        print_warning "⚠️ Frontend not accessible"
    fi
else
    print_warning "Supervisor not available - cannot check service status"
fi

echo ""
echo "🎉 Configuration verification completed!"
echo ""
echo "📊 SYSTEM STATUS SUMMARY"
echo "========================"
echo "🌍 Environment: $ENV_TYPE"
echo "🔗 Backend URL: $BACKEND_URL"
echo "🖥️  CPU Cores: $(nproc --all) cores detected"
echo "💾 MongoDB: $(pgrep mongod >/dev/null && echo "✅ Running" || echo "❌ Not running")"
echo "🔙 Backend: $(curl -s http://localhost:8001/api/health >/dev/null && echo "✅ Responding" || echo "❌ Not responding")"
echo "🎨 Frontend: $(curl -s http://localhost:3000 >/dev/null && echo "✅ Accessible" || echo "❌ Not accessible")"
echo ""

if [[ "$ENV_TYPE" == "native" ]]; then
    echo "💡 NATIVE SYSTEM TIPS"
    echo "====================="
    echo "• Use 'sudo systemctl start mongod' to start MongoDB"
    echo "• Backend runs on http://localhost:8001"
    echo "• Frontend runs on http://localhost:3000"
    echo "• Logs: /var/log/supervisor/"
else
    echo "🐳 CONTAINER SYSTEM TIPS"
    echo "========================"
    echo "• Use external URLs for API access"
    echo "• MongoDB runs on allocated resources"
    echo "• Check container resource limits"
fi

echo ""
echo "🔧 If issues persist, run: ./startup-manager.sh full-reset"