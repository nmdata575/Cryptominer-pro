#!/bin/bash

# .env File Format Validator and Fixer
# Fixes common .env file format issues that prevent scripts from reading them

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

validate_and_fix_env() {
    local env_file="$1"
    local file_type="$2"
    
    print_step "Validating $file_type .env file: $env_file"
    
    if [[ ! -f "$env_file" ]]; then
        print_error "File not found: $env_file"
        return 1
    fi
    
    # Check file permissions
    local perms=$(stat -c "%a" "$env_file" 2>/dev/null || echo "unknown")
    if [[ "$perms" != "644" ]]; then
        print_warning "Fixing file permissions: $perms -> 644"
        chmod 644 "$env_file"
    fi
    
    # Create backup
    local backup="${env_file}.backup.$(date +%s)"
    cp "$env_file" "$backup"
    print_status "Created backup: $backup"
    
    # Check for missing final newline
    if [[ -n "$(tail -c1 "$env_file")" ]]; then
        print_warning "Missing final newline, adding it"
        echo "" >> "$env_file"
    fi
    
    # Remove Windows line endings if present
    if grep -q $'\r' "$env_file"; then
        print_warning "Found Windows line endings, converting to Unix"
        sed -i 's/\r$//' "$env_file"
    fi
    
    # Remove empty lines at the end (except one)
    sed -i -e :a -e '/^\s*$/N' -e '$!ba' -e 's/\n\+$/\n/' "$env_file"
    
    # Validate each line format
    local line_num=0
    local has_errors=false
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$((line_num + 1))
        
        # Skip empty lines and comments
        if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Check for valid variable assignment
        if [[ ! "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]].*$ ]]; then
            print_error "Line $line_num: Invalid format: '$line'"
            has_errors=true
        fi
    done < "$env_file"
    
    if [[ "$has_errors" == "true" ]]; then
        print_error "Found format errors in $env_file"
        return 1
    fi
    
    # Test if the file can be sourced
    if bash -c ". '$env_file'" >/dev/null 2>&1; then
        print_status "✅ $file_type .env file format is valid"
    else
        print_error "❌ $file_type .env file has sourcing issues"
        return 1
    fi
    
    # Display key variables for verification
    print_step "Key variables in $file_type .env:"
    if [[ "$file_type" == "Frontend" ]]; then
        grep "REACT_APP_BACKEND_URL" "$env_file" | sed 's/^/  /' || echo "  REACT_APP_BACKEND_URL not found"
    elif [[ "$file_type" == "Backend" ]]; then
        grep -E "(MONGO_URL|ACTUAL_CPU_CORES|MAX_THREADS)" "$env_file" | sed 's/^/  /' || echo "  Key variables not found"
    fi
    
    return 0
}

echo "🔧 .env File Format Validator and Fixer"
echo "======================================="
echo ""

# Validate frontend .env
if validate_and_fix_env "/app/frontend/.env" "Frontend"; then
    print_status "Frontend .env file is properly formatted"
else
    print_error "Frontend .env file needs manual review"
fi

echo ""

# Validate backend .env
if validate_and_fix_env "/app/backend-nodejs/.env" "Backend"; then
    print_status "Backend .env file is properly formatted"
else
    print_error "Backend .env file needs manual review"
fi

echo ""
echo "🎉 .env File Validation Complete!"
echo ""

# Test if environment variables can be loaded
print_step "Testing environment variable loading..."

# Test frontend env loading
if bash -c ". /app/frontend/.env && echo 'Frontend backend URL:' \$REACT_APP_BACKEND_URL" 2>/dev/null; then
    print_status "✅ Frontend environment variables load correctly"
else
    print_warning "⚠️ Frontend environment variables may have issues"
fi

# Test backend env loading  
if bash -c ". /app/backend-nodejs/.env && echo 'Backend MongoDB URL:' \$MONGO_URL" 2>/dev/null; then
    print_status "✅ Backend environment variables load correctly"
else
    print_warning "⚠️ Backend environment variables may have issues"
fi

echo ""
print_status "💡 If services still have issues, restart them:"
echo "  sudo supervisorctl restart mining_system:frontend"
echo "  sudo supervisorctl restart mining_system:backend"