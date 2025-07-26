#!/bin/bash

# CryptoMiner Pro - Webpack Build Fix Script
# Fixes the html-webpack-plugin and dependency issues

set -e

echo "🔧 CryptoMiner Pro - Webpack Build Fix"
echo "====================================="

# Function to print colored output
print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

print_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

# Check if we're in the right location
if [[ ! -d "./frontend" ]] || [[ ! -d "./backend-nodejs" ]]; then
    print_error "This script must be run from the project root directory"
    exit 1
fi

print_info "Fixing webpack build issues..."

# Backup current frontend package.json
cp ./frontend/package.json ./frontend/package.json.backup

# Create a working package.json with compatible versions
cat > ./frontend/package.json << 'EOF'
{
  "name": "crypto-mining-dashboard",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@testing-library/jest-dom": "^5.17.0",
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^14.5.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1",
    "web-vitals": "^2.1.4",
    "axios": "^1.6.0",
    "chart.js": "^4.4.0",
    "react-chartjs-2": "^5.2.0",
    "socket.io-client": "^4.7.4",
    "tailwindcss": "^3.3.6",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32",
    "@heroicons/react": "^2.0.18",
    "classnames": "^2.3.2"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "proxy": "http://localhost:8001"
}
EOF

print_info "Cleaning up old dependencies..."
cd ./frontend
rm -rf node_modules package-lock.json

print_info "Clearing npm cache..."
npm cache clean --force

print_info "Installing dependencies with fixed versions..."
npm install --legacy-peer-deps

print_info "Building frontend..."
npm run build

if [[ -d "./build" ]]; then
    print_success "✅ Frontend build completed successfully!"
    print_info "Build directory created: ./frontend/build"
else
    print_error "❌ Frontend build failed"
    print_info "Restoring original package.json"
    cp ./frontend/package.json.backup ./frontend/package.json
    exit 1
fi

print_success "🎉 Webpack build issues have been resolved!"
print_info ""
print_info "The frontend can now be served with:"
print_info "  cd frontend && npx serve -s build -l 3000"