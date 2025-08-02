# CryptoMiner Pro Installation Script - Permission Fix

## Problem Fixed

The original installation script was failing with permission errors:
```
chown: changing ownership of '/home/chris/.local/log/cryptominer/frontend.log': Operation not permitted
chown: changing ownership of '/home/chris/.local/log/cryptominer/backend.log': Operation not permitted
```

## Root Cause

1. **Unnecessary chown operations**: The script was trying to change ownership of files in the user's home directory
2. **Files created with sudo**: Log files were being created with root ownership, then chown was failing
3. **System-wide paths**: Original script used system-wide paths that required root privileges

## Solution Applied

### 1. Updated Configuration Variables
```bash
# OLD (system-wide)
INSTALL_DIR="/opt/cryptominer-pro"
SERVICE_USER="cryptominer"
LOG_FILE="/var/log/cryptominer-install.log"

# NEW (user-specific)
CURRENT_USER=$(whoami)
USER_HOME=$HOME
INSTALL_DIR="$USER_HOME/Cryptominer-pro"
LOG_DIR="$USER_HOME/.local/log/cryptominer"
SERVICE_USER="$CURRENT_USER"
```

### 2. Fixed Directory Creation Function
```bash
create_directories() {
    log_info "Creating application directories..."
    
    # Create directories (no sudo needed for user directory)
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$LOG_DIR"
    
    # Create log files with proper permissions (no chown needed)
    touch "$LOG_DIR/backend.log"
    touch "$LOG_DIR/frontend.log"
    touch "$LOG_DIR/backend-error.log"
    touch "$LOG_DIR/frontend-error.log"
    
    # Set proper permissions (user already owns these files)
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$LOG_DIR"
    chmod 644 "$LOG_DIR"/*.log
    
    log_success "Directories created ✅"
}
```

### 3. Updated Service User Configuration
```bash
configure_service_user() {
    log_info "Using current user for services: $CURRENT_USER..."
    
    # No need to create user since we're using current user
    if ! id "$CURRENT_USER" &>/dev/null; then
        error_exit "Current user $CURRENT_USER does not exist"
    fi
    
    log_success "Service user configured: $CURRENT_USER ✅"
}
```

### 4. Fixed Supervisor Configuration
```bash
# Updated to use user-specific log paths
stdout_logfile=$LOG_DIR/backend.log
stderr_logfile=$LOG_DIR/backend-error.log
```

### 5. Added Root Check
```bash
check_system_requirements() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root. Please run as a regular user."
    fi
    # ... other checks
}
```

## Key Improvements

1. **No More Permission Errors**: All files created in user's home directory with correct ownership
2. **No chown Operations**: Files are created with the right user from the start
3. **User-Specific Installation**: Everything installs to `~/Cryptominer-pro` instead of `/opt/`
4. **Proper Error Handling**: Script exits gracefully if run as root
5. **Updated MongoDB**: Changed from version 7.0 to 8.0 as requested

## Files Updated

1. **install-enhanced-v2-fixed.sh** - Complete new version with all fixes
2. **install-enhanced-v2.sh** - Original updated with key fixes

## Testing

To test the fixed installation:

```bash
# Make sure you're not root
whoami  # Should NOT return 'root'

# Run the fixed installation script
./install-enhanced-v2-fixed.sh
```

The script will now:
- ✅ Create directories without permission errors
- ✅ Install to user home directory
- ✅ Use current user for all services
- ✅ Create log files with correct ownership
- ✅ Set proper permissions without chown

## Result

No more "Operation not permitted" errors when creating log files or setting up the application directories.