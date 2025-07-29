#!/bin/bash

# MongoDB Environment Debug Script
# Helps identify discrepancies between container and native environments

echo "🔍 MongoDB Environment Debug"
echo "============================"
echo ""

# Environment detection
echo "📍 Environment Detection:"
if [[ -f /.dockerenv ]]; then
    echo "  Environment: Docker container"
elif [[ -n "${KUBERNETES_SERVICE_HOST}" ]]; then
    echo "  Environment: Kubernetes container"
else
    echo "  Environment: Native system"
fi

echo "  Hostname: $(hostname)"
echo "  User: $(whoami)"
echo ""

# MongoDB process check
echo "🔍 MongoDB Process Analysis:"
if pgrep mongod >/dev/null; then
    echo "  ✅ MongoDB processes found:"
    ps aux | grep mongod | grep -v grep | while read line; do
        echo "    $line"
    done
    
    echo ""
    echo "  📊 Process details:"
    for pid in $(pgrep mongod); do
        echo "    PID $pid command: $(ps -p $pid -o cmd --no-headers)"
        echo "    PID $pid working directory: $(sudo pwdx $pid 2>/dev/null | cut -d' ' -f2- || echo 'unknown')"
    done
else
    echo "  ❌ No MongoDB processes found"
fi

echo ""

# Port analysis
echo "🔍 Port Analysis:"
echo "  Checking port 27017 with multiple methods:"

# Method 1: lsof
if command -v lsof >/dev/null; then
    echo "    lsof method:"
    if sudo lsof -i :27017 2>/dev/null; then
        echo "      ✅ lsof shows port 27017 in use"
    else
        echo "      ❌ lsof shows port 27017 not in use"
    fi
else
    echo "    ❌ lsof not available"
fi

# Method 2: netstat
if command -v netstat >/dev/null; then
    echo "    netstat method:"
    if netstat -tlnp 2>/dev/null | grep ":27017"; then
        echo "      ✅ netstat shows port 27017 listening"
    else
        echo "      ❌ netstat shows port 27017 not listening"
    fi
else
    echo "    ❌ netstat not available"
fi

# Method 3: ss
if command -v ss >/dev/null; then
    echo "    ss method:"
    if ss -tlnp 2>/dev/null | grep ":27017"; then
        echo "      ✅ ss shows port 27017 listening"
    else
        echo "      ❌ ss shows port 27017 not listening"
    fi
else
    echo "    ❌ ss not available"
fi

# Show all MongoDB-related ports
echo ""
echo "  🔍 All ports used by MongoDB processes:"
if command -v lsof >/dev/null; then
    MONGO_PORTS=$(sudo lsof -i -P 2>/dev/null | grep mongod | awk '{print $9}' | sort -u)
    if [[ -n "$MONGO_PORTS" ]]; then
        echo "$MONGO_PORTS" | while read port; do
            echo "    MongoDB using: $port"
        done
    else
        echo "    ❌ No ports found for MongoDB processes"
    fi
fi

echo ""

# Configuration check
echo "🔍 Configuration Analysis:"
if [[ -f /etc/mongod.conf ]]; then
    echo "  ✅ /etc/mongod.conf exists"
    echo "    Key settings:"
    echo "      bindIP: $(grep -E 'bindIp|bind_ip' /etc/mongod.conf | head -1 | awk '{print $2}' || echo 'not found')"
    echo "      port: $(grep -E '^[[:space:]]*port:' /etc/mongod.conf | awk '{print $2}' || echo 'default (27017)')"
    echo "      dbPath: $(grep -E 'dbPath|dbpath' /etc/mongod.conf | awk '{print $2}' || echo 'not found')"
else
    echo "  ❌ /etc/mongod.conf not found"
fi

if [[ -f /etc/default/mongod ]]; then
    echo "  ✅ /etc/default/mongod exists"
    echo "    Environment variables:"
    grep -E '^[A-Z]' /etc/default/mongod | head -5 | while read line; do
        echo "      $line"
    done
else
    echo "  ❌ /etc/default/mongod not found"
fi

echo ""

# Connection test
echo "🔍 Connection Test:"
echo "  Testing MongoDB connection methods:"

# Test 1: mongosh
if command -v mongosh >/dev/null; then
    echo "    mongosh test:"
    if timeout 5 mongosh --host 127.0.0.1 --port 27017 --eval "print('Connected')" --quiet 2>/dev/null; then
        echo "      ✅ mongosh connection successful"
    else
        echo "      ❌ mongosh connection failed"
    fi
else
    echo "    ❌ mongosh not available"
fi

# Test 2: telnet-style test
if command -v nc >/dev/null; then
    echo "    Network connectivity test:"
    if echo "quit" | timeout 3 nc 127.0.0.1 27017 >/dev/null 2>&1; then
        echo "      ✅ Network connection to port 27017 successful"
    else
        echo "      ❌ Network connection to port 27017 failed"
    fi
else
    echo "    ❌ nc (netcat) not available for network test"
fi

echo ""

# Log analysis
echo "🔍 Log Analysis:"
if [[ -f /var/log/mongodb/mongod.log ]]; then
    echo "  ✅ MongoDB log file exists"
    echo "    Recent log entries (last 5):"
    tail -5 /var/log/mongodb/mongod.log | while read line; do
        echo "      $line"
    done
    
    echo ""
    echo "    Looking for binding/network messages:"
    grep -i "waiting for connections\|bind\|listen\|port" /var/log/mongodb/mongod.log | tail -3 | while read line; do
        echo "      $line"
    done
else
    echo "  ❌ MongoDB log file not found"
fi

echo ""
echo "🎯 Summary:"
echo "============"

PROCESS_RUNNING=$(pgrep mongod >/dev/null && echo "true" || echo "false")
PORT_LISTENING=$(sudo lsof -i :27017 >/dev/null 2>&1 && echo "true" || echo "false")
CONNECTION_WORKS=$(timeout 5 mongosh --host 127.0.0.1 --port 27017 --eval "quit()" --quiet >/dev/null 2>&1 && echo "true" || echo "false")

echo "MongoDB Process Running: $PROCESS_RUNNING"
echo "Port 27017 Listening: $PORT_LISTENING"
echo "Connection Working: $CONNECTION_WORKS"

if [[ "$PROCESS_RUNNING" == "true" ]] && [[ "$PORT_LISTENING" == "true" ]] && [[ "$CONNECTION_WORKS" == "true" ]]; then
    echo ""
    echo "🎉 RESULT: MongoDB appears to be working correctly"
elif [[ "$PROCESS_RUNNING" == "true" ]] && [[ "$PORT_LISTENING" == "false" ]]; then
    echo ""
    echo "⚠️ RESULT: MongoDB is running but not listening on port 27017"
    echo "   This suggests a configuration or binding issue"
elif [[ "$PROCESS_RUNNING" == "false" ]]; then
    echo ""
    echo "❌ RESULT: MongoDB is not running"
else
    echo ""
    echo "🤔 RESULT: Mixed results - needs investigation"
fi