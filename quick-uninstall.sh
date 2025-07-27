#!/bin/bash

# CryptoMiner Pro - Quick Uninstall Script
# Fast removal with minimal prompts

echo "🗑️  CryptoMiner Pro - Quick Uninstall"
echo "====================================="
echo "This will remove CryptoMiner Pro completely (keeping Node.js and MongoDB)"
echo ""

read -p "Are you sure you want to uninstall CryptoMiner Pro? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "🛑 Stopping all CryptoMiner services..."

# Stop supervisor services
sudo supervisorctl stop cryptominer-native:* 2>/dev/null || true
sudo supervisorctl stop cryptominer-simple:* 2>/dev/null || true
sudo supervisorctl stop cryptominer-pro:* 2>/dev/null || true
sudo supervisorctl stop cryptominer-fixed:* 2>/dev/null || true
sudo supervisorctl stop mining_system:* 2>/dev/null || true

# Stop and disable systemd services
sudo systemctl stop cryptominer-pro.service 2>/dev/null || true
sudo systemctl stop cryptominer.service 2>/dev/null || true
sudo systemctl stop cryptominer-backend.service 2>/dev/null || true
sudo systemctl stop cryptominer-frontend.service 2>/dev/null || true

sudo systemctl disable cryptominer-pro.service 2>/dev/null || true
sudo systemctl disable cryptominer.service 2>/dev/null || true
sudo systemctl disable cryptominer-backend.service 2>/dev/null || true
sudo systemctl disable cryptominer-frontend.service 2>/dev/null || true

echo "✅ Services stopped"

echo ""
echo "🗂️  Removing service configurations..."

# Remove systemd service files
sudo rm -f /etc/systemd/system/cryptominer-pro.service
sudo rm -f /etc/systemd/system/cryptominer.service
sudo rm -f /etc/systemd/system/cryptominer-backend.service
sudo rm -f /etc/systemd/system/cryptominer-frontend.service
sudo rm -f /lib/systemd/system/cryptominer-pro.service
sudo rm -f /lib/systemd/system/cryptominer.service

# Reload systemd daemon
sudo systemctl daemon-reload 2>/dev/null || true

# Remove supervisor configs
sudo rm -f /etc/supervisor/conf.d/cryptominer-*.conf
sudo rm -f /etc/supervisor/conf.d/mining_app.conf

# Reload supervisor
sudo supervisorctl reread 2>/dev/null || true
sudo supervisorctl update 2>/dev/null || true

echo "✅ Service configurations removed"

echo ""
echo "📂 Removing application files..."

# Remove common installation paths
for path in "/home/$(whoami)/cryptominer-pro" "/home/chris/cryptominer-pro" "/opt/cryptominer-pro" "/root/cryptominer-pro"; do
    if [[ -d "$path" ]]; then
        echo "   Removing: $path"
        rm -rf "$path"
    fi
done

# Remove from current directory if it looks like cryptominer-pro
if [[ -f "./backend-nodejs/server.js" ]] && [[ -f "./frontend/package.json" ]]; then
    echo "   Found installation in current directory"
    read -p "Remove current directory contents? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ./backend-nodejs ./frontend ./*.md ./*.sh ./*.json .gitignore 2>/dev/null || true
        echo "   Current directory cleaned"
    fi
fi

echo "✅ Application files removed"

echo ""
echo "🐳 Cleaning up Docker containers..."

# Remove Docker container if exists
if command -v docker >/dev/null 2>&1; then
    docker stop cryptominer-mongodb 2>/dev/null || true
    docker rm cryptominer-mongodb 2>/dev/null || true
    docker volume rm cryptominer-data 2>/dev/null || true
    echo "✅ Docker containers cleaned"
else
    echo "✅ Docker not found - skipping"
fi

echo ""
echo "📄 Removing log files..."

# Remove logs
sudo rm -f /var/log/supervisor/cryptominer-*.log
sudo rm -f /var/log/supervisor/mining_*.log

echo "✅ Log files removed"

echo ""
echo "🧹 Removing aliases..."

# Remove aliases from shell configs
for config_file in ~/.bashrc ~/.zshrc ~/.profile; do
    if [[ -f "$config_file" ]]; then
        sed -i '/# CryptoMiner Pro Command Aliases/,/^$/d' "$config_file" 2>/dev/null || true
    fi
done

echo "✅ Shell aliases removed"

echo ""
echo "🗄️  Cleaning database..."

# Remove only the cryptominer database (keep MongoDB)
if pgrep mongod >/dev/null; then
    if command -v mongosh >/dev/null 2>&1; then
        mongosh --eval "db.getSiblingDB('cryptominer').dropDatabase()" 2>/dev/null || true
    elif command -v mongo >/dev/null 2>&1; then
        mongo --eval "db.getSiblingDB('cryptominer').dropDatabase()" 2>/dev/null || true
    fi
    echo "✅ CryptoMiner database removed (MongoDB kept)"
else
    echo "✅ MongoDB not running - skipping"
fi

echo ""
echo "================================================================"
echo "✅ CryptoMiner Pro has been completely uninstalled!"
echo ""
echo "💾 What was KEPT (may be used by other applications):"
echo "   • Node.js and npm"
echo "   • MongoDB server"
echo "   • System packages (supervisor, etc.)"
echo ""
echo "🔄 To complete removal:"
echo "   • Restart your terminal (to clear aliases)"
echo "   • Reboot system (to ensure all processes stopped)"
echo ""
echo "🎉 Thank you for using CryptoMiner Pro!"
echo "================================================================"