#!/bin/bash

# CryptoMiner Pro - Service Management Script
# Handles common service issues including port conflicts

echo "🔧 CryptoMiner Pro Service Manager"
echo "=================================="

# Function to kill processes on specific ports
kill_port() {
    local port=$1
    echo "🔍 Checking for processes on port $port..."
    
    # Find processes using the port
    local pids=$(sudo netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1)
    
    if [ ! -z "$pids" ]; then
        echo "⚡ Killing processes on port $port: $pids"
        echo "$pids" | xargs -r sudo kill -9
        sleep 2
    else
        echo "✅ Port $port is free"
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
    if ps aux | grep -q "[m]ongod"; then
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
    "menu"|*)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  restart     - Clean restart of all services"
        echo "  health      - Check service health"
        echo "  kill-ports  - Kill processes on ports 8001 and 3000"
        echo "  mongodb     - Start MongoDB if not running"
        echo ""
        echo "Quick fixes:"
        echo "  ./manage.sh restart     # Fix port conflicts and restart"
        echo "  ./manage.sh health      # Check if everything is working"
        ;;
esac