#!/bin/bash

# Port Cleanup Script - Aggressively clears port conflicts
echo "🔧 Clearing port conflicts for CryptoMiner Pro..."

# Function to completely clear a port
clear_port() {
    local port=$1
    echo "🧹 Clearing port $port..."
    
    # Method 1: Kill by port using netstat
    local pids=$(sudo netstat -tulnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | sort -u)
    if [ ! -z "$pids" ]; then
        echo "  ⚡ Killing PIDs: $pids"
        echo "$pids" | xargs -r sudo kill -9
    fi
    
    # Method 2: Kill by process name pattern
    sudo pkill -9 -f "server.js"
    sudo pkill -9 -f ":$port"
    
    # Method 3: Wait and verify
    sleep 2
    
    # Check if port is still in use
    if sudo netstat -tulnp 2>/dev/null | grep -q ":$port "; then
        echo "  ⚠️  Port $port still in use, trying alternative method..."
        # Find and kill any remaining processes
        local remaining=$(sudo netstat -tulnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1)
        if [ ! -z "$remaining" ]; then
            echo "$remaining" | xargs -r sudo kill -SIGKILL
        fi
    fi
    
    # Final verification
    if ! sudo netstat -tulnp 2>/dev/null | grep -q ":$port "; then
        echo "  ✅ Port $port is now free"
    else
        echo "  ❌ Port $port is still in use"
        sudo netstat -tulnp | grep ":$port "
    fi
}

# Clear backend port
clear_port 8001

# Clear frontend port  
clear_port 3000

# Stop supervisor services to prevent conflicts
echo "🔄 Stopping supervisor services..."
sudo supervisorctl stop mining_system:backend mining_system:frontend

# Wait for clean shutdown
sleep 3

echo "✅ Port cleanup completed!"
echo ""
echo "Now you can safely restart services with:"
echo "  sudo supervisorctl start mining_system:backend"
echo "  sudo supervisorctl start mining_system:frontend"
echo ""
echo "Or run: ./manage.sh restart"