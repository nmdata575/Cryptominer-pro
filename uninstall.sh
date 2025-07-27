#!/bin/bash

# CryptoMiner Pro - Complete Uninstall Script
# Safely removes CryptoMiner Pro from your system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. This script will work but consider running as regular user with sudo."
fi

print_header "🗑️  CryptoMiner Pro - Complete Uninstall Script"
echo "================================================================"
echo "This script will help you remove CryptoMiner Pro from your system."
echo "You can choose what to remove and what to keep."
echo ""

# Detect installation paths
POSSIBLE_PATHS=(
    "/home/$(whoami)/cryptominer-pro"
    "/home/chris/cryptominer-pro"
    "/opt/cryptominer-pro"
    "/root/cryptominer-pro"
    "$(pwd)"
)

INSTALL_PATH=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [[ -d "$path/backend-nodejs" ]] && [[ -d "$path/frontend" ]]; then
        INSTALL_PATH="$path"
        break
    fi
done

if [[ -n "$INSTALL_PATH" ]]; then
    print_success "Found installation at: $INSTALL_PATH"
else
    print_warning "Installation path not auto-detected"
    read -p "Enter the full path to your CryptoMiner Pro installation: " INSTALL_PATH
    if [[ ! -d "$INSTALL_PATH" ]]; then
        print_error "Directory not found: $INSTALL_PATH"
        exit 1
    fi
fi

echo ""
echo "🎯 What would you like to remove?"
echo ""

# Service removal
print_info "1. SERVICES & CONFIGURATION"
read -p "Remove CryptoMiner Pro services and supervisor configs? (y/N): " -n 1 -r REMOVE_SERVICES
echo
if [[ $REMOVE_SERVICES =~ ^[Yy]$ ]]; then
    print_header "🛑 Stopping and removing services..."
    
    # Stop all possible service configurations
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
    
    # Remove systemd service files
    sudo rm -f /etc/systemd/system/cryptominer-pro.service
    sudo rm -f /etc/systemd/system/cryptominer.service
    sudo rm -f /etc/systemd/system/cryptominer-backend.service
    sudo rm -f /etc/systemd/system/cryptominer-frontend.service
    sudo rm -f /lib/systemd/system/cryptominer-pro.service
    sudo rm -f /lib/systemd/system/cryptominer.service
    
    # Reload systemd daemon
    sudo systemctl daemon-reload 2>/dev/null || true
    
    # Remove supervisor configurations
    sudo rm -f /etc/supervisor/conf.d/cryptominer-*.conf
    sudo rm -f /etc/supervisor/conf.d/mining_app.conf
    
    # Reload supervisor
    sudo supervisorctl reread 2>/dev/null || true
    sudo supervisorctl update 2>/dev/null || true
    
    print_success "Services stopped and configurations removed"
fi

# Application files removal
echo ""
print_info "2. APPLICATION FILES"
read -p "Remove CryptoMiner Pro application files? (y/N): " -n 1 -r REMOVE_APP_FILES
echo
if [[ $REMOVE_APP_FILES =~ ^[Yy]$ ]]; then
    print_header "📂 Removing application files..."
    
    if [[ -d "$INSTALL_PATH" ]]; then
        # Backup any custom configurations
        if [[ -f "$INSTALL_PATH/frontend/.env" ]]; then
            print_info "Backing up frontend .env to /tmp/cryptominer-frontend-env-backup"
            cp "$INSTALL_PATH/frontend/.env" /tmp/cryptominer-frontend-env-backup 2>/dev/null || true
        fi
        
        if [[ -f "$INSTALL_PATH/backend-nodejs/.env" ]]; then
            print_info "Backing up backend .env to /tmp/cryptominer-backend-env-backup"
            cp "$INSTALL_PATH/backend-nodejs/.env" /tmp/cryptominer-backend-env-backup 2>/dev/null || true
        fi
        
        # Remove application directory
        rm -rf "$INSTALL_PATH"
        print_success "Application files removed from $INSTALL_PATH"
    else
        print_warning "Application directory not found: $INSTALL_PATH"
    fi
fi

# Docker containers (for simple installation)
echo ""
print_info "3. DOCKER CONTAINERS"
if command -v docker >/dev/null 2>&1; then
    MONGO_CONTAINER=$(docker ps -a --filter "name=cryptominer-mongodb" --format "{{.Names}}" 2>/dev/null || true)
    if [[ -n "$MONGO_CONTAINER" ]]; then
        read -p "Remove CryptoMiner MongoDB Docker container? (y/N): " -n 1 -r REMOVE_DOCKER
        echo
        if [[ $REMOVE_DOCKER =~ ^[Yy]$ ]]; then
            print_header "🐳 Removing Docker containers..."
            docker stop cryptominer-mongodb 2>/dev/null || true
            docker rm cryptominer-mongodb 2>/dev/null || true
            docker volume rm cryptominer-data 2>/dev/null || true
            print_success "Docker containers and volumes removed"
        fi
    else
        print_info "No CryptoMiner Docker containers found"
    fi
else
    print_info "Docker not installed - skipping container cleanup"
fi

# MongoDB removal
echo ""
print_info "4. MONGODB DATABASE"
if command -v mongod >/dev/null 2>&1 || command -v mongo >/dev/null 2>&1; then
    read -p "Remove MongoDB completely? (y/N): " -n 1 -r REMOVE_MONGODB
    echo
    if [[ $REMOVE_MONGODB =~ ^[Yy]$ ]]; then
        print_header "🗄️  Removing MongoDB..."
        
        # Stop MongoDB service
        sudo systemctl stop mongod 2>/dev/null || true
        sudo systemctl disable mongod 2>/dev/null || true
        
        # Remove MongoDB packages
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get remove --purge -y mongodb-org* 2>/dev/null || true
            sudo rm -f /etc/apt/sources.list.d/mongodb-org-*.list
            sudo rm -f /usr/share/keyrings/mongodb-server-*.gpg
        elif command -v yum >/dev/null 2>&1; then
            sudo yum remove -y mongodb-org* 2>/dev/null || true
            sudo rm -f /etc/yum.repos.d/mongodb-org-*.repo
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf remove -y mongodb-org* 2>/dev/null || true
            sudo rm -f /etc/yum.repos.d/mongodb-org-*.repo
        fi
        
        # Remove MongoDB data and logs
        sudo rm -rf /var/lib/mongodb
        sudo rm -rf /var/log/mongodb
        sudo rm -rf /data/db
        
        print_success "MongoDB completely removed"
    else
        print_info "Keeping MongoDB (only removing CryptoMiner database)"
        # Just remove the specific database
        if pgrep mongod >/dev/null; then
            if command -v mongosh >/dev/null 2>&1; then
                mongosh --eval "db.getSiblingDB('cryptominer').dropDatabase()" 2>/dev/null || true
            elif command -v mongo >/dev/null 2>&1; then
                mongo --eval "db.getSiblingDB('cryptominer').dropDatabase()" 2>/dev/null || true
            fi
            print_success "CryptoMiner database removed (MongoDB kept)"
        fi
    fi
else
    print_info "MongoDB not found - skipping database cleanup"
fi

# Node.js removal
echo ""
print_info "5. NODE.JS RUNTIME"
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version 2>/dev/null || echo "unknown")
    read -p "Remove Node.js $NODE_VERSION? (y/N): " -n 1 -r REMOVE_NODEJS
    echo
    if [[ $REMOVE_NODEJS =~ ^[Yy]$ ]]; then
        print_header "📦 Removing Node.js..."
        
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get remove --purge -y nodejs npm 2>/dev/null || true
            sudo rm -f /etc/apt/sources.list.d/nodesource.list
            sudo rm -f /usr/share/keyrings/nodesource.gpg
        elif command -v yum >/dev/null 2>&1; then
            sudo yum remove -y nodejs npm 2>/dev/null || true
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf remove -y nodejs npm 2>/dev/null || true
        fi
        
        # Remove global npm packages and cache
        rm -rf ~/.npm
        rm -rf ~/.nvm
        
        print_success "Node.js completely removed"
    else
        print_info "Keeping Node.js (may be used by other applications)"
    fi
else
    print_info "Node.js not found - skipping"
fi

# Log files removal
echo ""
print_info "6. LOG FILES"
read -p "Remove CryptoMiner Pro log files? (Y/n): " -n 1 -r REMOVE_LOGS
echo
if [[ ! $REMOVE_LOGS =~ ^[Nn]$ ]]; then
    print_header "📄 Removing log files..."
    
    sudo rm -f /var/log/supervisor/cryptominer-*.log
    sudo rm -f /var/log/supervisor/mining_*.log
    sudo rm -f /var/log/mongodb/mongod.log
    
    print_success "Log files removed"
fi

# Shell aliases removal
echo ""
print_info "7. SHELL ALIASES"
read -p "Remove CryptoMiner Pro shell aliases? (Y/n): " -n 1 -r REMOVE_ALIASES
echo
if [[ ! $REMOVE_ALIASES =~ ^[Nn]$ ]]; then
    print_header "🖥️  Removing shell aliases..."
    
    for config_file in ~/.bashrc ~/.zshrc ~/.profile; do
        if [[ -f "$config_file" ]]; then
            # Remove CryptoMiner aliases section
            sed -i '/# CryptoMiner Pro Command Aliases/,/^$/d' "$config_file" 2>/dev/null || true
            print_success "Aliases removed from $config_file"
        fi
    done
fi

# User account removal
echo ""
print_info "8. USER ACCOUNTS"
if id "cryptominer" >/dev/null 2>&1; then
    read -p "Remove 'cryptominer' user account? (y/N): " -n 1 -r REMOVE_USER
    echo
    if [[ $REMOVE_USER =~ ^[Yy]$ ]]; then
        print_header "👤 Removing user account..."
        sudo userdel -r cryptominer 2>/dev/null || true
        print_success "User 'cryptominer' removed"
    fi
else
    print_info "No 'cryptominer' user account found"
fi

# Final system cleanup
echo ""
print_info "9. SYSTEM CLEANUP"
read -p "Run system cleanup (update package cache, remove orphaned packages)? (Y/n): " -n 1 -r SYSTEM_CLEANUP
echo
if [[ ! $SYSTEM_CLEANUP =~ ^[Nn]$ ]]; then
    print_header "🧹 Running system cleanup..."
    
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get autoremove -y 2>/dev/null || true
        sudo apt-get autoclean 2>/dev/null || true
        sudo apt-get update 2>/dev/null || true
    elif command -v yum >/dev/null 2>&1; then
        sudo yum autoremove -y 2>/dev/null || true
        sudo yum clean all 2>/dev/null || true
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf autoremove -y 2>/dev/null || true
        sudo dnf clean all 2>/dev/null || true
    fi
    
    print_success "System cleanup completed"
fi

# Summary
echo ""
print_header "📋 UNINSTALL SUMMARY"
echo "================================================================"
print_success "CryptoMiner Pro uninstall completed!"
echo ""

if [[ -f "/tmp/cryptominer-frontend-env-backup" ]] || [[ -f "/tmp/cryptominer-backend-env-backup" ]]; then
    print_info "💾 Configuration backups saved to:"
    [[ -f "/tmp/cryptominer-frontend-env-backup" ]] && echo "   • /tmp/cryptominer-frontend-env-backup"
    [[ -f "/tmp/cryptominer-backend-env-backup" ]] && echo "   • /tmp/cryptominer-backend-env-backup"
    echo ""
fi

print_info "🔄 You may need to:"
echo "   • Restart your terminal to clear aliases"
echo "   • Reboot to ensure all services are stopped"
echo "   • Check for any remaining processes: ps aux | grep -i crypto"

echo ""
print_success "🎉 Thank you for using CryptoMiner Pro!"
print_info "If you need to reinstall, simply run the install script again."

echo ""
echo "================================================================"