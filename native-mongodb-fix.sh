#!/bin/bash

# Native System MongoDB Troubleshooter
# Specifically designed for native Linux systems (not containers)

echo "🔧 Native System MongoDB Troubleshooter"
echo "======================================="
echo "System: $(hostname)"
echo "User: $(whoami)"
echo "Date: $(date)"
echo ""

# Step 1: Check if MongoDB is installed
echo "1️⃣ MongoDB Installation Check"
echo "-----------------------------"

if command -v mongod >/dev/null; then
    MONGOD_VERSION=$(mongod --version | head -1)
    echo "✅ mongod found: $MONGOD_VERSION"
else
    echo "❌ mongod not found in PATH"
    echo "   Please install MongoDB first"
    exit 1
fi

if command -v mongosh >/dev/null; then
    MONGOSH_VERSION=$(mongosh --version)
    echo "✅ mongosh found: $MONGOSH_VERSION"
elif command -v mongo >/dev/null; then
    MONGO_VERSION=$(mongo --version | head -1)
    echo "✅ mongo (legacy) found: $MONGO_VERSION"
else
    echo "❌ MongoDB client not found"
fi

echo ""

# Step 2: Check MongoDB processes
echo "2️⃣ MongoDB Process Check"
echo "------------------------"

MONGOD_PIDS=$(pgrep mongod 2>/dev/null || echo "")
if [[ -n "$MONGOD_PIDS" ]]; then
    echo "✅ MongoDB processes found:"
    for pid in $MONGOD_PIDS; do
        CMD=$(ps -p $pid -o cmd --no-headers 2>/dev/null || echo "unknown")
        echo "   PID $pid: $CMD"
    done
else
    echo "❌ No MongoDB processes running"
    echo ""
    echo "🔧 Attempting to start MongoDB..."
    
    # Try to start MongoDB
    if [[ -f /etc/mongod.conf ]]; then
        echo "   Using config file: /etc/mongod.conf"
        if sudo mongod --config /etc/mongod.conf --fork; then
            echo "   ✅ MongoDB started successfully"
            sleep 3
        else
            echo "   ❌ Failed to start MongoDB with config file"
        fi
    else
        echo "   No config file found, using defaults"
        if sudo mongod --dbpath /var/lib/mongodb --logpath /var/log/mongodb/mongod.log --fork; then
            echo "   ✅ MongoDB started successfully"
            sleep 3
        else
            echo "   ❌ Failed to start MongoDB with defaults"
        fi
    fi
fi

echo ""

# Step 3: Check MongoDB ports
echo "3️⃣ MongoDB Port Check"
echo "---------------------"

# Check with lsof (most reliable)
if command -v lsof >/dev/null; then
    echo "Using lsof to check ports:"
    LSOF_RESULT=$(sudo lsof -i :27017 2>/dev/null)
    if [[ -n "$LSOF_RESULT" ]]; then
        echo "✅ Port 27017 is in use:"
        echo "$LSOF_RESULT"
    else
        echo "❌ Port 27017 is not in use (lsof)"
    fi
else
    echo "⚠️ lsof not available"
fi

# Check with netstat
if command -v netstat >/dev/null; then
    echo ""
    echo "Using netstat to check ports:"
    NETSTAT_RESULT=$(netstat -tlnp 2>/dev/null | grep ":27017")
    if [[ -n "$NETSTAT_RESULT" ]]; then
        echo "✅ Port 27017 is listening:"
        echo "$NETSTAT_RESULT"
    else
        echo "❌ Port 27017 is not listening (netstat)"
    fi
else
    echo "⚠️ netstat not available"
fi

# Check with ss
if command -v ss >/dev/null; then
    echo ""
    echo "Using ss to check ports:"
    SS_RESULT=$(ss -tlnp 2>/dev/null | grep ":27017")
    if [[ -n "$SS_RESULT" ]]; then
        echo "✅ Port 27017 is listening:"
        echo "$SS_RESULT"
    else
        echo "❌ Port 27017 is not listening (ss)"
    fi
else
    echo "⚠️ ss not available"
fi

echo ""

# Step 4: Test MongoDB connection
echo "4️⃣ MongoDB Connection Test"
echo "--------------------------"

# Test with mongosh
if command -v mongosh >/dev/null; then
    echo "Testing with mongosh:"
    if timeout 10 mongosh --host 127.0.0.1 --port 27017 --eval "print('Connection successful')" --quiet 2>/dev/null; then
        echo "✅ mongosh connection successful"
        MONGOSH_WORKS=true
    else
        echo "❌ mongosh connection failed"
        MONGOSH_WORKS=false
    fi
else
    MONGOSH_WORKS=false
fi

# Test with legacy mongo
if command -v mongo >/dev/null && [[ "$MONGOSH_WORKS" != true ]]; then
    echo "Testing with legacy mongo client:"
    if timeout 10 mongo 127.0.0.1:27017 --eval "print('Connection successful')" --quiet 2>/dev/null; then
        echo "✅ mongo connection successful"
        MONGO_WORKS=true
    else
        echo "❌ mongo connection failed"
        MONGO_WORKS=false
    fi
else
    MONGO_WORKS=false
fi

# Test with telnet/nc
if command -v nc >/dev/null; then
    echo "Testing with nc (netcat):"
    if echo "quit" | timeout 5 nc 127.0.0.1 27017 >/dev/null 2>&1; then
        echo "✅ Network connection to port 27017 successful"
        NC_WORKS=true
    else
        echo "❌ Network connection to port 27017 failed"
        NC_WORKS=false
    fi
else
    NC_WORKS=false
fi

echo ""

# Step 5: Analyze results and provide fixes
echo "5️⃣ Analysis and Recommendations"
echo "-------------------------------"

PROCESS_RUNNING=$(pgrep mongod >/dev/null && echo true || echo false)
PORT_LISTENING=$(sudo lsof -i :27017 >/dev/null 2>&1 && echo true || echo false)
CONNECTION_WORKING=$([[ "$MONGOSH_WORKS" == true ]] || [[ "$MONGO_WORKS" == true ]] && echo true || echo false)

echo "📊 Status Summary:"
echo "   MongoDB Process: $PROCESS_RUNNING"
echo "   Port 27017 Listening: $PORT_LISTENING"
echo "   Connection Working: $CONNECTION_WORKING"
echo ""

if [[ "$PROCESS_RUNNING" == true ]] && [[ "$PORT_LISTENING" == true ]] && [[ "$CONNECTION_WORKING" == true ]]; then
    echo "🎉 RESULT: MongoDB is working correctly!"
    echo ""
    echo "Your MongoDB setup is functional. If scripts are reporting issues,"
    echo "it may be due to script configuration or environment detection problems."
    
elif [[ "$PROCESS_RUNNING" == true ]] && [[ "$PORT_LISTENING" == false ]]; then
    echo "⚠️ RESULT: MongoDB is running but not listening on port 27017"
    echo ""
    echo "🔧 FIXES TO TRY:"
    echo "1. Check MongoDB configuration:"
    echo "   sudo cat /etc/mongod.conf | grep -E 'bindIp|port'"
    echo ""
    echo "2. Restart MongoDB with explicit port binding:"
    echo "   sudo pkill mongod"
    echo "   sudo mongod --bind_ip 127.0.0.1 --port 27017 --dbpath /var/lib/mongodb --logpath /var/log/mongodb/mongod.log --fork"
    echo ""
    echo "3. Check for port conflicts:"
    echo "   sudo lsof -i :27017"
    
elif [[ "$PROCESS_RUNNING" == false ]]; then
    echo "❌ RESULT: MongoDB is not running"
    echo ""
    echo "🔧 FIXES TO TRY:"
    echo "1. Start MongoDB manually:"
    echo "   sudo mkdir -p /var/lib/mongodb /var/log/mongodb"
    echo "   sudo chown mongodb:mongodb /var/lib/mongodb /var/log/mongodb"
    echo "   sudo mongod --dbpath /var/lib/mongodb --logpath /var/log/mongodb/mongod.log --fork"
    echo ""
    echo "2. Start with systemd (if available):"
    echo "   sudo systemctl start mongod"
    echo ""
    echo "3. Check MongoDB logs for errors:"
    echo "   sudo tail -20 /var/log/mongodb/mongod.log"

elif [[ "$CONNECTION_WORKING" == false ]]; then
    echo "⚠️ RESULT: MongoDB is running and listening but connections fail"
    echo ""
    echo "🔧 FIXES TO TRY:"
    echo "1. Check if MongoDB is binding to the correct interface:"
    echo "   sudo netstat -tlnp | grep mongod"
    echo ""
    echo "2. Test with different connection methods:"
    echo "   mongosh mongodb://127.0.0.1:27017"
    echo "   mongosh mongodb://localhost:27017"
    echo ""
    echo "3. Check firewall settings:"
    echo "   sudo ufw status"
    echo "   sudo iptables -L"
    echo ""
    echo "4. Check MongoDB authentication settings in /etc/mongod.conf"

else
    echo "🤔 RESULT: Mixed results - manual investigation needed"
fi

echo ""
echo "📝 Log Locations:"
echo "   MongoDB logs: /var/log/mongodb/mongod.log"
echo "   MongoDB data: /var/lib/mongodb"
echo "   MongoDB config: /etc/mongod.conf"
echo ""

# Check if this is the issue with script environment detection
if [[ "$PROCESS_RUNNING" == true ]] && [[ "$PORT_LISTENING" == true ]] && [[ "$CONNECTION_WORKING" == true ]]; then
    echo "💡 NOTE: Since MongoDB appears to be working correctly, the issue may be"
    echo "   with the detection scripts. The scripts might be designed for container"
    echo "   environments and may not work correctly on native systems."
    echo ""
    echo "   You can bypass the script checks and proceed with using your mining"
    echo "   system directly at: http://localhost:3000"
fi