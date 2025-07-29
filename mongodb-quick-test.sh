#!/bin/bash

# Quick MongoDB Connection Test
# Simple alternative for testing MongoDB connectivity

echo "🧪 Quick MongoDB Connection Test"
echo "================================"
echo ""

# Test 1: Process check
if pgrep mongod >/dev/null; then
    echo "✅ MongoDB process is running (PID: $(pgrep mongod))"
else
    echo "❌ MongoDB process is not running"
    exit 1
fi

# Test 2: Port check
if netstat -tln | grep -q ":27017"; then
    echo "✅ MongoDB is listening on port 27017"
else
    echo "❌ MongoDB is not listening on port 27017"
    exit 1
fi

# Test 3: Simple connection test
echo "🔗 Testing connection..."

# Method 1: mongosh
if command -v mongosh >/dev/null; then
    if mongosh --host 127.0.0.1 --port 27017 --eval "print('Connection successful')" --quiet 2>/dev/null; then
        echo "✅ mongosh connection successful"
        exit 0
    fi
fi

# Method 2: mongo (legacy)
if command -v mongo >/dev/null; then
    if mongo 127.0.0.1:27017 --eval "print('Connection successful')" --quiet 2>/dev/null; then
        echo "✅ mongo (legacy) connection successful"
        exit 0
    fi
fi

# Method 3: Basic network test
if command -v nc >/dev/null; then
    if echo "quit" | timeout 3 nc 127.0.0.1 27017 >/dev/null 2>&1; then
        echo "✅ Network connection to MongoDB port successful"
        echo "   (Client tools may have configuration issues)"
        exit 0
    fi
fi

echo "⚠️ All connection methods failed"
echo "   MongoDB appears to be running but clients cannot connect"
echo ""
echo "Troubleshooting:"
echo "1. Check MongoDB logs: sudo tail /var/log/mongodb/mongod.log"
echo "2. Verify config: cat /etc/mongod.conf"
echo "3. Try manual connection: mongosh --host 127.0.0.1 --port 27017"