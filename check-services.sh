#!/bin/bash

# CryptoMiner Pro - Service Discovery Script
# Shows all CryptoMiner-related services and processes

echo "🔍 CryptoMiner Pro - Service Discovery"
echo "======================================"
echo ""

echo "📋 SUPERVISOR SERVICES:"
echo "------------------------"
sudo supervisorctl status | grep -i crypto || echo "   No CryptoMiner supervisor services found"

echo ""
echo "🔧 SYSTEMD SERVICES:" 
echo "--------------------"
systemctl list-units --all | grep -i crypto || echo "   No CryptoMiner systemd services found"

echo ""
echo "📁 SYSTEMD SERVICE FILES:"
echo "-------------------------"
ls /etc/systemd/system/ | grep -i crypto | sed 's/^/   /' || echo "   No service files in /etc/systemd/system/"
ls /lib/systemd/system/ | grep -i crypto | sed 's/^/   /' 2>/dev/null || echo "   No service files in /lib/systemd/system/"

echo ""
echo "📂 SUPERVISOR CONFIG FILES:"
echo "---------------------------"
ls /etc/supervisor/conf.d/ | grep -i crypto | sed 's/^/   /' || echo "   No supervisor configs found"

echo ""
echo "🔄 RUNNING PROCESSES:"
echo "--------------------"
ps aux | grep -i crypto | grep -v grep | sed 's/^/   /' || echo "   No CryptoMiner processes running"

echo ""
echo "🌐 NETWORK PORTS:"
echo "-----------------"
echo "   Port 8001 (Backend):"
sudo lsof -i :8001 | grep -v COMMAND | sed 's/^/      /' || echo "      Not in use"
echo "   Port 3000 (Frontend):"
sudo lsof -i :3000 | grep -v COMMAND | sed 's/^/      /' || echo "      Not in use"

echo ""
echo "📁 INSTALLATION DIRECTORIES:"
echo "----------------------------"
for path in "/home/$(whoami)/cryptominer-pro" "/home/chris/cryptominer-pro" "/opt/cryptominer-pro" "/root/cryptominer-pro"; do
    if [[ -d "$path" ]]; then
        echo "   ✅ Found: $path"
    fi
done

echo ""
echo "🐳 DOCKER CONTAINERS:"
echo "---------------------"
if command -v docker >/dev/null 2>&1; then
    docker ps -a | grep crypto | sed 's/^/   /' || echo "   No CryptoMiner containers found"
else
    echo "   Docker not installed"
fi

echo ""
echo "📄 LOG FILES:"
echo "-------------"
ls /var/log/supervisor/ | grep -i crypto | sed 's/^/   /' || echo "   No CryptoMiner log files found"

echo ""
echo "🎯 SUMMARY:"
echo "-----------"
if pgrep -f "cryptominer\|node.*server.js" >/dev/null; then
    echo "   ⚠️  CryptoMiner processes are currently RUNNING"
else
    echo "   ✅ No CryptoMiner processes detected"
fi

if [[ -f "/etc/systemd/system/cryptominer-pro.service" ]] || ls /etc/supervisor/conf.d/cryptominer-*.conf >/dev/null 2>&1; then
    echo "   ⚠️  CryptoMiner service configurations FOUND"
else
    echo "   ✅ No service configurations detected"
fi

echo ""
echo "💡 To remove all detected components, run:"
echo "   sudo ./uninstall.sh         # Interactive removal"
echo "   sudo ./quick-uninstall.sh   # Fast removal"