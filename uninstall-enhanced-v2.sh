#!/bin/bash

# =============================================================================
# CryptoMiner Pro v2.0 - Enhanced Uninstall Script
# Complete removal of CryptoMiner Pro Enhanced Installation
# =============================================================================
# 
# This script removes all components installed by install-enhanced-v2.sh:
# ✅ Application files and directories
# ✅ Service user and configurations
# ✅ Supervisor process management
# ✅ Nginx reverse proxy setup
# ✅ MongoDB (optional)
# ✅ Systemd services
# ✅ Firewall rules
# ✅ Log files and data
# 
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration (must match install-enhanced-v2.sh)
SCRIPT_VERSION="2.0.0"
PROJECT_NAME="CryptoMiner Pro"
INSTALL_DIR="/opt/cryptominer-pro"
SERVICE_USER="cryptominer"
LOG_FILE="/var/log/cryptominer-uninstall.log"

# Uninstallation options
REMOVE_MONGODB=false
REMOVE_NODEJS=false
REMOVE_NGINX=false
REMOVE_SUPERVISOR=false
REMOVE_USER_DATA=false
FORCE_REMOVAL=false
INTERACTIVE_MODE=true

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

show_header() {
    clear
    echo -e "${PURPLE}"
    echo "==============================================================================="
    echo "  🗑️  $PROJECT_NAME - Enhanced Uninstall Script v$SCRIPT_VERSION"
    echo "==============================================================================="
    echo -e "${NC}"
    echo -e "${CYAN}This script will remove:${NC}"
    echo "  🗂️  Application files and directories"
    echo "  👤 Service user and configurations"
    echo "  ⚙️  Supervisor process management"
    echo "  🌐 Nginx reverse proxy setup"
    echo "  🗄️  MongoDB (optional)"
    echo "  🔧 Systemd services"
    echo "  🔥 Firewall rules"
    echo "  📋 Log files and data"
    echo ""
}

confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$FORCE_REMOVAL" == "true" ]]; then
        return 0
    fi
    
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        return 0
    fi
    
    local prompt="$message"
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        [nN][oO]|[nN])
            return 1
            ;;
        "")
            if [[ "$default" == "y" ]]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            echo "Please answer yes or no."
            confirm_action "$message" "$default"
            ;;
    esac
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons"
        log_info "Please run as a regular user with sudo privileges"
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges"
        log_info "Please ensure your user has sudo access"
        exit 1
    fi
}

detect_installation() {
    log_info "Detecting CryptoMiner Pro v2.0 installation..."
    
    local found=false
    
    # Check installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        log_success "Found installation directory: $INSTALL_DIR"
        found=true
    fi
    
    # Check service user
    if id "$SERVICE_USER" &>/dev/null; then
        log_success "Found service user: $SERVICE_USER"
        found=true
    fi
    
    # Check supervisor configs
    if [[ -f "/etc/supervisor/conf.d/cryptominer-backend.conf" ]] || [[ -f "/etc/supervisor/conf.d/cryptominer-frontend.conf" ]]; then
        log_success "Found supervisor configurations"
        found=true
    fi
    
    # Check nginx config
    if [[ -f "/etc/nginx/sites-available/cryptominer-pro" ]]; then
        log_success "Found nginx configuration"
        found=true
    fi
    
    # Check systemd service
    if [[ -f "/etc/systemd/system/cryptominer-pro.service" ]]; then
        log_success "Found systemd service"
        found=true
    fi
    
    if [[ "$found" == "false" ]]; then
        log_warning "No CryptoMiner Pro v2.0 installation detected"
        log_info "The system may already be clean or using a different installation method"
        
        if confirm_action "Continue with cleanup anyway?"; then
            return 0
        else
            exit 0
        fi
    fi
    
    return 0
}

configure_uninstall_options() {
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        return 0
    fi
    
    echo ""
    log_info "Configuring uninstall options..."
    echo ""
    
    if confirm_action "Remove MongoDB? (This will delete all mining data)"; then
        REMOVE_MONGODB=true
        log_warning "MongoDB will be removed - all data will be lost!"
    fi
    
    if confirm_action "Remove Node.js? (May affect other applications)"; then
        REMOVE_NODEJS=true
        log_warning "Node.js will be removed - may affect other applications!"
    fi
    
    if confirm_action "Remove Nginx? (May affect other websites)"; then
        REMOVE_NGINX=true
        log_warning "Nginx will be removed - may affect other websites!"
    fi
    
    if confirm_action "Remove Supervisor? (May affect other services)"; then
        REMOVE_SUPERVISOR=true
        log_warning "Supervisor will be removed - may affect other services!"
    fi
    
    if confirm_action "Remove user data and logs completely?"; then
        REMOVE_USER_DATA=true
        log_warning "All user data and logs will be permanently deleted!"
    fi
    
    echo ""
    log_info "Uninstall configuration complete"
}

stop_services() {
    log_info "Stopping CryptoMiner Pro services..."
    
    # Stop supervisor services
    sudo supervisorctl stop cryptominer-backend 2>/dev/null || true
    sudo supervisorctl stop cryptominer-frontend 2>/dev/null || true
    sudo supervisorctl stop all 2>/dev/null || true
    
    # Stop systemd service
    sudo systemctl stop cryptominer-pro.service 2>/dev/null || true
    sudo systemctl disable cryptominer-pro.service 2>/dev/null || true
    
    log_success "Services stopped ✅"
}

remove_application_files() {
    log_info "Removing application files..."
    
    # Remove main installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        if [[ "$REMOVE_USER_DATA" == "true" ]]; then
            sudo rm -rf "$INSTALL_DIR"
            log_success "Application directory removed: $INSTALL_DIR ✅"
        else
            # Create backup of user data
            local backup_dir="/tmp/cryptominer-backup-$(date +%Y%m%d_%H%M%S)"
            if [[ -d "$INSTALL_DIR/data" ]]; then
                sudo cp -r "$INSTALL_DIR/data" "$backup_dir" 2>/dev/null || true
                log_info "User data backed up to: $backup_dir"
            fi
            sudo rm -rf "$INSTALL_DIR"
            log_success "Application directory removed (data backed up) ✅"
        fi
    fi
    
    # Remove log files
    if [[ -d "/var/log/cryptominer" ]]; then
        if [[ "$REMOVE_USER_DATA" == "true" ]]; then
            sudo rm -rf /var/log/cryptominer
            log_success "Log files removed ✅"
        else
            local log_backup="/tmp/cryptominer-logs-$(date +%Y%m%d_%H%M%S)"
            sudo cp -r /var/log/cryptominer "$log_backup" 2>/dev/null || true
            sudo rm -rf /var/log/cryptominer
            log_info "Logs backed up to: $log_backup"
            log_success "Log files removed (backed up) ✅"
        fi
    fi
}

remove_service_user() {
    log_info "Removing service user..."
    
    if id "$SERVICE_USER" &>/dev/null; then
        # Stop any processes running as the service user
        sudo pkill -u "$SERVICE_USER" 2>/dev/null || true
        sleep 2
        
        # Remove user and home directory
        sudo userdel -r "$SERVICE_USER" 2>/dev/null || true
        log_success "Service user removed: $SERVICE_USER ✅"
    else
        log_info "Service user not found: $SERVICE_USER"
    fi
}

remove_supervisor_configs() {
    log_info "Removing supervisor configurations..."
    
    # Remove supervisor config files
    sudo rm -f /etc/supervisor/conf.d/cryptominer-backend.conf
    sudo rm -f /etc/supervisor/conf.d/cryptominer-frontend.conf
    
    # Reload supervisor
    sudo supervisorctl reread 2>/dev/null || true
    sudo supervisorctl update 2>/dev/null || true
    
    log_success "Supervisor configurations removed ✅"
    
    # Remove supervisor itself if requested
    if [[ "$REMOVE_SUPERVISOR" == "true" ]]; then
        sudo systemctl stop supervisor 2>/dev/null || true
        sudo systemctl disable supervisor 2>/dev/null || true
        sudo apt-get remove -y supervisor 2>/dev/null || true
        log_success "Supervisor package removed ✅"
    fi
}

remove_nginx_config() {
    log_info "Removing nginx configuration..."
    
    # Remove site configurations
    sudo rm -f /etc/nginx/sites-available/cryptominer-pro
    sudo rm -f /etc/nginx/sites-enabled/cryptominer-pro
    
    # Restore default site if it doesn't exist
    if [[ ! -f /etc/nginx/sites-enabled/default ]] && [[ -f /etc/nginx/sites-available/default ]]; then
        sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    fi
    
    # Test and reload nginx
    if sudo nginx -t 2>/dev/null; then
        sudo systemctl reload nginx 2>/dev/null || true
        log_success "Nginx configuration removed ✅"
    else
        log_warning "Nginx configuration test failed - manual intervention may be required"
    fi
    
    # Remove nginx itself if requested
    if [[ "$REMOVE_NGINX" == "true" ]]; then
        sudo systemctl stop nginx 2>/dev/null || true
        sudo systemctl disable nginx 2>/dev/null || true
        sudo apt-get remove -y nginx nginx-common 2>/dev/null || true
        log_success "Nginx package removed ✅"
    fi
}

remove_systemd_service() {
    log_info "Removing systemd service..."
    
    # Stop and disable service
    sudo systemctl stop cryptominer-pro.service 2>/dev/null || true
    sudo systemctl disable cryptominer-pro.service 2>/dev/null || true
    
    # Remove service file
    sudo rm -f /etc/systemd/system/cryptominer-pro.service
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    log_success "Systemd service removed ✅"
}

remove_firewall_rules() {
    log_info "Removing firewall rules..."
    
    # Remove UFW rules (if UFW is installed and active)
    if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
        # Remove mining port rules
        sudo ufw delete allow out 3567/tcp 2>/dev/null || true  # Litecoin
        sudo ufw delete allow out 9998/tcp 2>/dev/null || true  # Dogecoin
        sudo ufw delete allow out 8338/tcp 2>/dev/null || true  # Feathercoin
        
        log_success "Firewall rules removed ✅"
    else
        log_info "UFW not active or not installed"
    fi
}

remove_mongodb() {
    if [[ "$REMOVE_MONGODB" != "true" ]]; then
        return 0
    fi
    
    log_info "Removing MongoDB..."
    
    # Stop MongoDB service
    sudo systemctl stop mongod 2>/dev/null || true
    sudo systemctl disable mongod 2>/dev/null || true
    
    # Remove MongoDB packages
    sudo apt-get remove -y mongodb-org mongodb-org-server mongodb-org-shell mongodb-org-mongos mongodb-org-tools 2>/dev/null || true
    
    # Remove MongoDB data directory
    sudo rm -rf /var/lib/mongodb 2>/dev/null || true
    sudo rm -rf /var/log/mongodb 2>/dev/null || true
    sudo rm -rf /data/db 2>/dev/null || true
    
    # Remove MongoDB repository
    sudo rm -f /etc/apt/sources.list.d/mongodb-org-*.list
    sudo rm -f /usr/share/keyrings/mongodb-server-*.gpg
    
    log_success "MongoDB removed ✅"
}

remove_nodejs() {
    if [[ "$REMOVE_NODEJS" != "true" ]]; then
        return 0
    fi
    
    log_info "Removing Node.js..."
    
    # Remove Node.js and npm
    sudo apt-get remove -y nodejs npm 2>/dev/null || true
    
    # Remove NodeSource repository
    sudo rm -f /etc/apt/sources.list.d/nodesource.list
    
    # Remove global packages
    sudo rm -rf /usr/lib/node_modules 2>/dev/null || true
    
    log_success "Node.js removed ✅"
}

cleanup_system() {
    log_info "Performing system cleanup..."
    
    # Update package database
    sudo apt-get update -qq 2>/dev/null || true
    
    # Remove unused packages
    sudo apt-get autoremove -y 2>/dev/null || true
    sudo apt-get autoclean 2>/dev/null || true
    
    # Clear package cache
    sudo apt-get clean 2>/dev/null || true
    
    log_success "System cleanup completed ✅"
}

show_completion_info() {
    log_success "🎉 CryptoMiner Pro v2.0 uninstall completed successfully!"
    echo ""
    echo -e "${PURPLE}===============================================================================${NC}"
    echo -e "${GREEN}  🗑️  CryptoMiner Pro v$SCRIPT_VERSION - Uninstall Complete!${NC}"
    echo -e "${PURPLE}===============================================================================${NC}"
    echo ""
    echo -e "${CYAN}📋 Removal Summary:${NC}"
    echo "  🗂️  Application files: Removed from $INSTALL_DIR"
    echo "  👤 Service user: $SERVICE_USER removed"
    echo "  ⚙️  Supervisor configs: Removed"
    echo "  🌐 Nginx config: Removed"
    echo "  🔧 Systemd service: Removed"
    echo "  🔥 Firewall rules: Removed"
    echo "  📋 Log files: $([ "$REMOVE_USER_DATA" == "true" ] && echo "Permanently deleted" || echo "Backed up to /tmp/")"
    echo ""
    
    if [[ "$REMOVE_MONGODB" == "true" ]]; then
        echo -e "${YELLOW}  🗄️  MongoDB: Removed (all data deleted)${NC}"
    else
        echo -e "${GREEN}  🗄️  MongoDB: Preserved${NC}"
    fi
    
    if [[ "$REMOVE_NODEJS" == "true" ]]; then
        echo -e "${YELLOW}  📦 Node.js: Removed${NC}"
    else
        echo -e "${GREEN}  📦 Node.js: Preserved${NC}"
    fi
    
    if [[ "$REMOVE_NGINX" == "true" ]]; then
        echo -e "${YELLOW}  🌐 Nginx: Removed${NC}"
    else
        echo -e "${GREEN}  🌐 Nginx: Preserved${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}💡 Post-Uninstall Notes:${NC}"
    
    if [[ "$REMOVE_USER_DATA" != "true" ]]; then
        echo "  📁 Data backups created in /tmp/ (temporary location)"
        echo "  💾 Consider moving important data to permanent storage"
    fi
    
    if [[ "$REMOVE_MONGODB" != "true" ]] && [[ "$REMOVE_NODEJS" != "true" ]] && [[ "$REMOVE_NGINX" != "true" ]]; then
        echo "  🔄 System packages preserved for other applications"
    fi
    
    echo "  🧹 System cleanup completed - unused packages removed"
    echo "  🔍 Check for any remaining configuration files manually"
    echo ""
    echo -e "${GREEN}System successfully cleaned! 🧹✨${NC}"
    echo ""
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --remove-mongodb)
                REMOVE_MONGODB=true
                shift
                ;;
            --remove-nodejs)
                REMOVE_NODEJS=true
                shift
                ;;
            --remove-nginx)
                REMOVE_NGINX=true
                shift
                ;;
            --remove-supervisor)
                REMOVE_SUPERVISOR=true
                shift
                ;;
            --remove-all-data)
                REMOVE_USER_DATA=true
                shift
                ;;
            --force)
                FORCE_REMOVAL=true
                INTERACTIVE_MODE=false
                shift
                ;;
            --non-interactive)
                INTERACTIVE_MODE=false
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo "CryptoMiner Pro v2.0 - Enhanced Uninstall Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --remove-mongodb      Remove MongoDB (deletes all mining data)"
    echo "  --remove-nodejs       Remove Node.js (may affect other applications)"
    echo "  --remove-nginx        Remove Nginx (may affect other websites)"
    echo "  --remove-supervisor   Remove Supervisor (may affect other services)"
    echo "  --remove-all-data     Remove all user data and logs permanently"
    echo "  --force               Force removal without confirmations"
    echo "  --non-interactive     Run without user prompts"
    echo "  --help, -h            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive uninstall"
    echo "  $0 --force                           # Force uninstall without prompts"
    echo "  $0 --remove-mongodb --remove-all-data # Remove everything including data"
    echo ""
}

# =============================================================================
# MAIN UNINSTALL FLOW
# =============================================================================

main() {
    # Initialize log file
    sudo touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/cryptominer-uninstall.log"
    sudo chmod 666 "$LOG_FILE" 2>/dev/null || touch "$LOG_FILE"
    
    # Parse command line arguments
    parse_arguments "$@"
    
    show_header
    
    log "Starting CryptoMiner Pro v2.0 uninstall..."
    log "Uninstall log: $LOG_FILE"
    
    # Pre-uninstall checks
    check_root
    detect_installation
    
    # Configure uninstall options
    configure_uninstall_options
    
    # Final confirmation
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        echo ""
        log_warning "This will permanently remove CryptoMiner Pro v2.0 from your system"
        if ! confirm_action "Are you sure you want to continue?" "n"; then
            log_info "Uninstall cancelled by user"
            exit 0
        fi
        echo ""
    fi
    
    # Uninstall steps
    stop_services
    remove_application_files
    remove_service_user
    remove_supervisor_configs
    remove_nginx_config
    remove_systemd_service
    remove_firewall_rules
    remove_mongodb
    remove_nodejs
    cleanup_system
    
    # Completion
    show_completion_info
    log "Uninstall completed successfully at $(date)"
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi