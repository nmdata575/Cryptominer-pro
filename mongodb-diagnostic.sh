#!/bin/bash

# MongoDB Connection Test Script
# Quick diagnostic tool for MongoDB connectivity issues

echo "🔍 MongoDB Connection Diagnostic Tool"
echo "====================================="
echo ""

# Test 1: Check if MongoDB process is running
echo "1️⃣ Checking MongoDB process..."
if pgrep mongod >/dev/null; then
    echo "✅ MongoDB process is running (PID: $(pgrep mongod))"
else
    echo "❌ MongoDB process is not running"
    exit 1
fi

echo ""

# Test 2: Check if port 27017 is listening
echo "2️⃣ Checking MongoDB port..."
if netstat -tlnp 2>/dev/null | grep -q ":27017"; then
    echo "✅ MongoDB is listening on port 27017"
    netstat -tlnp 2>/dev/null | grep ":27017" || ss -tlnp | grep ":27017"
else
    echo "❌ MongoDB is not listening on port 27017"
fi

echo ""

# Test 3: Test connection with mongosh
echo "3️⃣ Testing mongosh connection..."
if command -v mongosh >/dev/null; then
    if timeout 10 mongosh --eval "print('Connected successfully')" --quiet --host 127.0.0.1:27017 2>/dev/null; then
        echo "✅ mongosh connection successful"
    else
        echo "❌ mongosh connection failed"
    fi
else
    echo "⚠️ mongosh not available"
fi

echo ""

# Test 4: Test connection with legacy mongo client
echo "4️⃣ Testing legacy mongo connection..."
if command -v mongo >/dev/null; then
    if timeout 10 mongo --eval "print('Connected successfully')" --quiet --host 127.0.0.1:27017 2>/dev/null; then
        echo "✅ Legacy mongo connection successful"
    else
        echo "❌ Legacy mongo connection failed"
    fi
else
    echo "⚠️ Legacy mongo client not available"
fi

echo ""

# Test 5: Test database operations
echo "5️⃣ Testing database operations..."
if timeout 10 mongosh --eval "
    try {
        db.test.insertOne({test: 'connection', timestamp: new Date()});
        const count = db.test.countDocuments({test: 'connection'});
        db.test.deleteMany({test: 'connection'});
        print('Database operations successful - inserted and deleted test document');
    } catch(e) {
        print('Database operations failed: ' + e);
    }
" --quiet --host 127.0.0.1:27017 2>/dev/null; then
    echo "✅ Database operations working"
else
    echo "❌ Database operations failed"
fi

echo ""

# Test 6: Check MongoDB status
echo "6️⃣ MongoDB server status..."
if timeout 10 mongosh --eval "
    try {
        const status = db.runCommand('serverStatus');
        print('MongoDB version: ' + status.version);
        print('Uptime: ' + Math.floor(status.uptime) + ' seconds');
        print('Connections current: ' + status.connections.current);
        print('Storage engine: ' + status.storageEngine.name);
    } catch(e) {
        print('Status check failed: ' + e);
    }
" --quiet --host 127.0.0.1:27017 2>/dev/null; then
    echo "✅ MongoDB status retrieved successfully"
else
    echo "❌ Failed to get MongoDB status"
fi

echo ""

# Test 7: Check for common issues
echo "7️⃣ Checking for common issues..."

# Check for lock files
if [[ -f /var/lib/mongodb/mongod.lock ]]; then
    echo "⚠️ Found lock file: /var/lib/mongodb/mongod.lock"
    echo "   Size: $(stat -c%s /var/lib/mongodb/mongod.lock) bytes"
else
    echo "✅ No stale lock files found"
fi

# Check disk space
available_space=$(df /var/lib/mongodb | awk 'NR==2 {print $4}')
if [[ $available_space -lt 1048576 ]]; then  # Less than 1GB
    echo "⚠️ Low disk space: $(df -h /var/lib/mongodb | awk 'NR==2 {print $4}') available"
else
    echo "✅ Sufficient disk space available"
fi

# Check permissions
if [[ -r /var/lib/mongodb ]] && [[ -w /var/lib/mongodb ]]; then
    echo "✅ MongoDB data directory permissions look good"
else
    echo "⚠️ MongoDB data directory permission issues detected"
fi

echo ""

# Summary
echo "📋 SUMMARY"
echo "=========="
if pgrep mongod >/dev/null && timeout 5 mongosh --eval "db.runCommand('ping')" --quiet --host 127.0.0.1:27017 >/dev/null 2>&1; then
    echo "🎉 MongoDB is running and accepting connections"
    echo ""
    echo "Connection strings:"
    echo "  mongodb://localhost:27017"
    echo "  mongodb://127.0.0.1:27017"
    echo ""
    echo "Test commands:"
    echo "  mongosh --host 127.0.0.1:27017"
    echo "  mongosh mongodb://localhost:27017"
else
    echo "❌ MongoDB has connectivity issues"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check MongoDB logs: tail /var/log/mongodb/mongod.log"
    echo "2. Restart MongoDB: /app/mongodb-complete.sh restart"
    echo "3. Check configuration: cat /etc/mongod.conf"
    echo "4. Check environment: cat /etc/default/mongod"
fi

echo ""