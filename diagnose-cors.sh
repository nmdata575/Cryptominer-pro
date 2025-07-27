#!/bin/bash

# CryptoMiner Pro - CORS Diagnostic Script
# Helps diagnose and fix CORS connectivity issues

echo "🔍 CryptoMiner Pro - CORS Diagnostic"
echo "===================================="
echo ""

echo "📡 BACKEND CONNECTIVITY TEST:"
echo "-----------------------------"

# Test if backend is responding
if curl -s http://localhost:8001/api/health >/dev/null 2>&1; then
    echo "✅ Backend is responding on http://localhost:8001"
    
    # Test CORS headers
    echo ""
    echo "🌐 CORS HEADERS CHECK:"
    echo "---------------------"
    curl -I -H "Origin: http://localhost:3000" \
         -H "Access-Control-Request-Method: GET" \
         -H "Access-Control-Request-Headers: Content-Type" \
         http://localhost:8001/api/health 2>/dev/null | grep -i "access-control\|cors" || echo "❌ No CORS headers found"
    
    echo ""
    echo "📊 API ENDPOINT TEST:"
    echo "--------------------"
    echo "Health check response:"
    curl -s http://localhost:8001/api/health | head -1
    
else
    echo "❌ Backend is NOT responding on http://localhost:8001"
    echo ""
    echo "🔧 BACKEND SERVICE CHECK:"
    echo "-------------------------"
    
    # Check supervisor services
    echo "Supervisor services:"
    sudo supervisorctl status | grep -i crypto || echo "   No CryptoMiner supervisor services found"
    
    echo ""
    echo "Systemd services:"
    systemctl --user list-units --state=running | grep -i crypto || echo "   No user systemd services running"
    sudo systemctl list-units --state=running | grep -i crypto || echo "   No system systemd services running"
    
    echo ""
    echo "Process check:"
    ps aux | grep -i "node.*server.js" | grep -v grep || echo "   No Node.js server processes found"
    
    echo ""
    echo "Port 8001 usage:"
    sudo lsof -i :8001 || echo "   Port 8001 is not in use"
fi

echo ""
echo "🌐 FRONTEND CONNECTIVITY TEST:"
echo "------------------------------"

if curl -s http://localhost:3000 >/dev/null 2>&1; then
    echo "✅ Frontend is responding on http://localhost:3000"
    
    # Check if frontend .env has correct backend URL
    if [[ -f ~/cryptominer-pro/frontend/.env ]]; then
        echo ""
        echo "📁 Frontend Configuration:"
        echo "-------------------------"
        echo "Backend URL in .env:"
        grep REACT_APP_BACKEND_URL ~/cryptominer-pro/frontend/.env || echo "   REACT_APP_BACKEND_URL not found in .env"
    fi
else
    echo "❌ Frontend is NOT responding on http://localhost:3000"
    
    echo ""
    echo "Port 3000 usage:"
    sudo lsof -i :3000 || echo "   Port 3000 is not in use"
fi

echo ""
echo "🔧 QUICK FIXES:"
echo "===============" 

if ! curl -s http://localhost:8001/api/health >/dev/null 2>&1; then
    echo ""
    echo "💡 Backend not responding - Try these fixes:"
    echo ""
    echo "1. Start the backend service:"
    echo "   sudo supervisorctl start cryptominer-native:cryptominer-backend"
    echo "   # or"
    echo "   sudo supervisorctl start cryptominer-fixed:cryptominer-backend-fixed"
    echo ""
    echo "2. Check backend logs:"
    echo "   sudo tail -f /var/log/supervisor/cryptominer-backend*.log"
    echo ""
    echo "3. Restart MongoDB (if needed):"
    echo "   sudo systemctl restart mongod"
    echo ""
    echo "4. Manual backend start (for debugging):"
    echo "   cd ~/cryptominer-pro/backend-nodejs"
    echo "   npm start"
fi

if curl -s http://localhost:8001/api/health >/dev/null 2>&1; then
    echo ""
    echo "💡 Backend responding but CORS issue - Try these fixes:"
    echo ""
    echo "1. Hard refresh frontend (clear browser cache):"
    echo "   Ctrl+F5 or Cmd+Shift+R"
    echo ""
    echo "2. Check browser console (F12):"
    echo "   Look for detailed error messages"
    echo ""
    echo "3. Verify frontend .env file:"
    echo "   echo 'REACT_APP_BACKEND_URL=http://localhost:8001' > ~/cryptominer-pro/frontend/.env"
    echo "   sudo supervisorctl restart cryptominer-native:cryptominer-frontend"
    echo ""
    echo "4. Test direct API call in browser:"
    echo "   Open: http://localhost:8001/api/health"
fi

echo ""
echo "🆘 EMERGENCY RESTART:"
echo "===================="
echo "If nothing works, try a complete restart:"
echo ""
echo "cd ~/cryptominer-pro"
echo "sudo supervisorctl stop cryptominer-*:*"
echo "sudo systemctl restart mongod"
echo "sleep 5"
echo "sudo supervisorctl start cryptominer-*:*"
echo ""
echo "Then wait 30 seconds and refresh browser at http://localhost:3000"