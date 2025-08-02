#!/bin/bash

# Test script to verify file detection logic works
echo "🔍 Testing CryptoMiner Pro File Detection"
echo "========================================"

# Test locations
locations=(
    "$(pwd)"
    "/app"
    "$(dirname "$0")"
    "/opt/cryptominer-pro"
    "/root/Cryptominer-pro"
)

echo "Current working directory: $(pwd)"
echo "Script location: $(dirname "$0")"
echo ""

for location in "${locations[@]}"; do
    echo -n "Testing $location: "
    if [[ -d "$location/backend-nodejs" && -d "$location/frontend" ]]; then
        echo "✅ FOUND (backend-nodejs & frontend directories exist)"
        
        # Check for key files
        if [[ -f "$location/backend-nodejs/package.json" ]]; then
            echo "  📦 backend-nodejs/package.json ✓"
        else
            echo "  ❌ backend-nodejs/package.json missing"
        fi
        
        if [[ -f "$location/frontend/package.json" ]]; then
            echo "  📦 frontend/package.json ✓"
        else
            echo "  ❌ frontend/package.json missing"
        fi
        
        if [[ -f "$location/backend-nodejs/server.js" ]]; then
            echo "  🖥️  backend-nodejs/server.js ✓"
        else
            echo "  ❌ backend-nodejs/server.js missing"
        fi
        
        echo ""
    else
        echo "❌ NOT FOUND"
        if [[ ! -d "$location/backend-nodejs" ]]; then
            echo "  📂 backend-nodejs directory missing"
        fi
        if [[ ! -d "$location/frontend" ]]; then
            echo "  📂 frontend directory missing"
        fi
        echo ""
    fi
done

echo "✅ File detection test completed!"
echo ""
echo "💡 If files are found in /app, the installation script will automatically copy them."