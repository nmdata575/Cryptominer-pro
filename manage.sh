#!/bin/bash

# CryptoMiner Pro - Service Management Script
# Handles common service issues including port conflicts

echo "🔧 CryptoMiner Pro Service Manager"
echo "=================================="

# Function to kill processes on specific ports
kill_port() {
    local port=$1
    echo "🔍 Aggressively clearing port $port..."
    
    # Method 1: Kill by netstat
    local pids=$(sudo netstat -tulnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | sort -u)
    if [ ! -z "$pids" ]; then
        echo "⚡ Killing PIDs: $pids"
        echo "$pids" | xargs -r sudo kill -9
    fi
    
    # Method 2: Kill by process pattern
    sudo pkill -9 -f "server.js" 2>/dev/null || true
    sudo pkill -9 -f ":$port" 2>/dev/null || true
    
    # Method 3: Wait and double-check
    sleep 2
    local remaining=$(sudo netstat -tulnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1)
    if [ ! -z "$remaining" ]; then
        echo "⚡ Final cleanup: $remaining"
        echo "$remaining" | xargs -r sudo kill -SIGKILL
    fi
    
    # Verification
    if ! sudo netstat -tulnp 2>/dev/null | grep -q ":$port "; then
        echo "✅ Port $port is free"
    else
        echo "❌ Port $port still in use:"
        sudo netstat -tulnp | grep ":$port "
    fi
}

# Function to start MongoDB if not running
start_mongodb() {
    if ! ps aux | grep -q "[m]ongod"; then
        echo "🚀 Starting MongoDB..."
        sudo mongod --dbpath /data/db --logpath /var/log/mongodb.log --fork
        sleep 3
    else
        echo "✅ MongoDB is already running"
    fi
}

# Function to restart services cleanly
restart_services() {
    echo "🔄 Restarting services..."
    
    # Kill any processes on our ports
    kill_port 8001  # Backend
    kill_port 3000  # Frontend
    
    # Ensure MongoDB is running
    start_mongodb
    
    # Stop all services
    sudo supervisorctl stop mining_system:backend mining_system:frontend
    sleep 3
    
    # Start services
    sudo supervisorctl start mining_system:backend
    sleep 5
    sudo supervisorctl start mining_system:frontend
    sleep 5
    
    # Check status
    sudo supervisorctl status
}

# Function to check service health
check_health() {
    echo "🩺 Checking service health..."
    
    # Check backend
    if curl -s http://localhost:8001/api/health > /dev/null; then
        echo "✅ Backend: Healthy"
        
        # Test CORS
        cors_test=$(curl -s -I -H "Origin: http://localhost:3000" http://localhost:8001/api/health | grep -i "access-control-allow-origin" || echo "")
        if [[ -n "$cors_test" ]]; then
            echo "✅ CORS: Configured"
        else
            echo "⚠️  CORS: May have issues"
        fi
    else
        echo "❌ Backend: Not responding"
    fi
    
    # Check frontend
    if curl -s http://localhost:3000 > /dev/null; then
        echo "✅ Frontend: Healthy"
    else
        echo "❌ Frontend: Not responding"
    fi
    
    # Check MongoDB
    if pgrep mongod > /dev/null; then
        echo "✅ MongoDB: Running"
    else
        echo "❌ MongoDB: Not running"
    fi
}

# Main menu
case "${1:-menu}" in
    "restart")
        restart_services
        check_health
        ;;
    "health")
        check_health
        ;;
    "kill-ports")
        kill_port 8001
        kill_port 3000
        ;;
    "mongodb")
        start_mongodb
        ;;
    "cors")
        echo "🌐 Testing and fixing CORS issues..."
        
        # Test backend connectivity
        if curl -s http://localhost:8001/api/health > /dev/null; then
            echo "✅ Backend is responding"
            
            # Test CORS headers
            echo "🔍 Testing CORS headers..."
            cors_response=$(curl -s -I -H "Origin: http://localhost:3000" \
                         -H "Access-Control-Request-Method: GET" \
                         http://localhost:8001/api/health)
            
            if echo "$cors_response" | grep -i "access-control-allow-origin" > /dev/null; then
                echo "✅ CORS headers are present"
            else
                echo "❌ CORS headers missing - restarting backend..."
                kill_port 8001
                sleep 3
                start_mongodb
                sudo supervisorctl restart mining_system:backend 2>/dev/null || \
                sudo supervisorctl restart cryptominer-native:cryptominer-backend 2>/dev/null || \
                sudo supervisorctl restart cryptominer-fixed:cryptominer-backend-fixed
            fi
        else
            echo "❌ Backend not responding - starting services..."
            restart_services
        fi
        
        check_health
        ;;
    "menu"|*)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  restart     - Clean restart of all services"
        echo "  health      - Check service health"
        echo "  kill-ports  - Kill processes on ports 8001 and 3000"
        echo "  mongodb     - Start MongoDB if not running"
        echo "  cors        - Test and fix CORS connectivity issues"
        echo ""
        echo "Quick fixes:"
        echo "  ./manage.sh restart     # Fix port conflicts and restart"
        echo "  ./manage.sh health      # Check if everything is working"
        echo "  ./manage.sh cors        # Fix CORS and connectivity issues"
        ;;
esac