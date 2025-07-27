#!/bin/bash

# CryptoMiner Pro - Project Cleanup Script
# This script removes old, unused, and redundant files to condense the project

echo "🧹 Starting project cleanup and condensation..."

cd /app

# Remove old Python files and artifacts
echo "📦 Removing old Python backend files..."
rm -f backend_test.py
rm -f extended_mining_test.py
rm -f real_mining_test.py
rm -f backend-nodejs/backend_8002.log
rm -f backend-nodejs/backend.log

# Remove multiple redundant installation scripts
echo "📦 Removing redundant installation scripts..."
rm -f install-nodejs.sh
rm -f install-container.sh
rm -f install-github.sh
rm -f install-complete-v2.sh
rm -f quick-fix-install.sh
rm -f fix-installation.sh
rm -f fix-webpack-build.sh
rm -f test-installation.sh
rm -f github-file-list.sh
rm -f cleanup-unused-files.sh

# Keep only the modern installation script
mv install-modern.sh install.sh

# Remove excessive documentation files
echo "📦 Removing redundant documentation..."
rm -f CHANGELOG_V2.1.md
rm -f CPU_FREQUENCY_FIX.md
rm -f CPU_FREQUENCY_FINAL_FIX.md
rm -f VERSION_2.1_SUMMARY.md
rm -f FEATURES_V2.1.md
rm -f GITHUB_DEPLOYMENT_GUIDE.md
rm -f GITHUB_REPOSITORY_READY.md
rm -f REPOSITORY_STATUS.md
rm -f REPOSITORY_INFO.md
rm -f GITHUB_READY_FILES.md
rm -f READY_FOR_GITHUB.md
rm -f IMPROVEMENTS_SUMMARY.md
rm -f STREAMLINED_STRUCTURE.md
rm -f QUICK_REFERENCE.md

# Keep essential documentation, rename for clarity
mv README_GITHUB.md README.md
mv INSTALLATION_GITHUB.md INSTALLATION.md

# Remove root-level node_modules (should only be in subdirectories)
echo "📦 Removing root-level node_modules..."
rm -rf /app/node_modules
rm -f package.json
rm -f package-lock.json

# Clean frontend build artifacts and cache
echo "📦 Cleaning frontend build artifacts..."
rm -rf frontend/build
rm -rf frontend/node_modules/.cache
rm -f frontend/false

# Clean backend logs and temporary files
echo "📦 Cleaning backend temporary files..."
find backend-nodejs -name "*.log" -delete
find backend-nodejs -name "*.tmp" -delete

# Remove Git ignore file (keep only in project root)
rm -f GITIGNORE_GITHUB

# Create consolidated project structure file
echo "📦 Creating project structure documentation..."
cat > PROJECT_STRUCTURE.md << 'EOF'
# CryptoMiner Pro - Project Structure

## Core Application
```
/app/
├── backend-nodejs/          # Node.js/Express backend
│   ├── server.js           # Main server file
│   ├── mining/             # Mining engine
│   ├── models/             # Database models
│   ├── utils/              # Utility functions
│   └── ai/                 # AI prediction features
├── frontend/               # React frontend
│   ├── src/                # Source code
│   ├── public/             # Static assets
│   └── build/              # Production build (generated)
└── test_result.md          # Testing documentation
```

## Installation & Setup
- `install.sh` - Main installation script
- `INSTALLATION.md` - Installation guide
- `README.md` - Project overview

## Documentation
- `MANUAL_INSTALL.md` - Manual setup instructions
- `CUSTOM_COINS_GUIDE.md` - Custom cryptocurrency guide
- `REMOTE_API_GUIDE.md` - API documentation
EOF

# Create a consolidated .gitignore
echo "📦 Creating consolidated .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
/.pnp
.pnp.js

# Testing
/coverage

# Production
/build
/dist

# Environment
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Cache
.cache/
.eslintcache

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Mining data
*.dat
*.wallet

# Temporary files
*.tmp
*.temp
EOF

# Update package.json files to remove unused dependencies
echo "📦 Optimizing package.json files..."

# Create simplified root package.json for project info
cat > package.json << 'EOF'
{
  "name": "cryptominer-pro",
  "version": "2.1.0",
  "description": "Professional cryptocurrency mining application with real Scrypt algorithm support",
  "main": "backend-nodejs/server.js",
  "scripts": {
    "start": "cd backend-nodejs && npm start",
    "dev": "cd backend-nodejs && npm run dev",
    "build": "cd frontend && npm run build",
    "install-all": "cd backend-nodejs && npm install && cd ../frontend && npm install",
    "clean": "rm -rf */node_modules */build */.cache"
  },
  "keywords": ["cryptocurrency", "mining", "scrypt", "litecoin", "dogecoin"],
  "author": "CryptoMiner Pro Team",
  "license": "MIT",
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF

echo "✅ Project cleanup completed!"
echo ""
echo "📊 Cleanup Summary:"
echo "• Removed old Python backend files"
echo "• Consolidated installation scripts (kept install.sh)"
echo "• Removed redundant documentation (kept essential files)"
echo "• Cleaned build artifacts and cache files"
echo "• Created PROJECT_STRUCTURE.md for reference"
echo "• Generated consolidated .gitignore"
echo "• Created root package.json for project management"
echo ""
echo "🎯 Final Project Structure:"
echo "• backend-nodejs/ - Real mining backend"
echo "• frontend/ - React UI"
echo "• Documentation files (README.md, INSTALLATION.md, guides)"  
echo "• install.sh - Single installation script"