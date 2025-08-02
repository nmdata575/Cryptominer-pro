# CryptoMiner Pro v2.0 - Deployment Guide

This guide covers deployment strategies for CryptoMiner Pro v2.0 in various environments.

## 🚀 Deployment Options

### 1. **Single Server Deployment** (Recommended for most users)
- **Use Case**: Home mining, small-scale operations
- **Resources**: 2+ CPU cores, 4GB RAM, 10GB disk
- **Method**: Enhanced installer script
- **Complexity**: Low

### 2. **Multi-Server Deployment**
- **Use Case**: Large-scale mining operations
- **Resources**: Multiple servers with load balancing
- **Method**: Manual configuration with clustering
- **Complexity**: High

### 3. **Cloud Deployment**
- **Use Case**: Scalable mining operations
- **Resources**: AWS/GCP/Azure instances
- **Method**: Infrastructure as Code (planned)
- **Complexity**: Medium

### 4. **Container Deployment**
- **Use Case**: Development and testing
- **Resources**: Docker-compatible environment
- **Method**: Docker Compose (planned)
- **Complexity**: Medium

## 🛠️ Production Deployment

### Prerequisites Checklist
- [ ] Ubuntu 20.04+ or Debian 11+ server
- [ ] Root/sudo access
- [ ] Internet connectivity
- [ ] 2+ CPU cores (4+ recommended)
- [ ] 4GB+ RAM (8GB recommended)
- [ ] 10GB+ free disk space
- [ ] Firewall access for ports 80, 443, 3567

### Step-by-Step Production Setup

#### 1. **Server Preparation**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install basic tools
sudo apt install -y curl wget git htop

# Create deployment user (optional)
sudo adduser cryptodeploy
sudo usermod -aG sudo cryptodeploy
su - cryptodeploy
```

#### 2. **Download and Run Installer**
```bash
# Download enhanced installer
wget https://raw.githubusercontent.com/your-username/cryptominer-pro/main/scripts/install-enhanced-v2.sh

# Make executable and run
chmod +x install-enhanced-v2.sh
./install-enhanced-v2.sh
```

#### 3. **SSL/TLS Configuration** (Recommended)
```bash
# Install Certbot for Let's Encrypt
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

#### 4. **Post-Installation Security**
```bash
# Configure firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Secure SSH (recommended)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
# Set: PermitRootLogin no
sudo systemctl restart ssh

# Update system regularly
sudo apt update && sudo apt upgrade -y
```

## 🔧 Configuration Management

### Environment Configuration

**Production Environment Variables:**
```bash
# Backend Configuration (/opt/cryptominer-pro/backend-nodejs/.env)
NODE_ENV=production
PORT=8001
MONGO_URL=mongodb://localhost:27017/cryptominer

# Mining Configuration
FORCE_PRODUCTION_MINING=true
DEFAULT_MINING_THREADS=6
DEFAULT_INTENSITY=0.8

# Security
SESSION_SECRET=your-secure-session-secret
API_RATE_LIMIT=1000
API_RATE_WINDOW=900000

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/cryptominer/backend.log
```

**Frontend Configuration:**
```bash
# Frontend Configuration (/opt/cryptominer-pro/frontend/.env)
REACT_APP_BACKEND_URL=https://your-domain.com
REACT_APP_VERSION=2.0.0
REACT_APP_AI_ENABLED=true
GENERATE_SOURCEMAP=false
```

### Database Configuration

**MongoDB Production Settings:**
```yaml
# /etc/mongod.conf
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 127.0.0.1

processManagement:
  fork: true
  pidFilePath: /var/run/mongod.pid

# Enable authentication in production
security:
  authorization: enabled
```

**Create Database User:**
```bash
mongosh
use cryptominer
db.createUser({
  user: "cryptominer",
  pwd: "secure-password",
  roles: [{ role: "readWrite", db: "cryptominer" }]
})
```

## 📊 Monitoring & Maintenance

### System Monitoring

**Service Health Checks:**
```bash
# Check all services
sudo supervisorctl status

# Check individual services
sudo systemctl status mongod
sudo systemctl status nginx
sudo systemctl status cryptominer-pro

# Check logs
sudo tail -f /var/log/cryptominer/backend.log
sudo tail -f /var/log/cryptominer/frontend.log
sudo tail -f /var/log/mongodb/mongod.log
```

**Resource Monitoring:**
```bash
# System resources
htop
df -h
free -h

# Mining performance
curl http://localhost:8001/api/mining/status
curl http://localhost:8001/api/system/stats
```

### Automated Monitoring Setup

**Install Monitoring Tools:**
```bash
# Install Node Exporter for Prometheus (optional)
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
sudo cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
sudo chown root:root /usr/local/bin/node_exporter
```

**Health Check Script:**
```bash
#!/bin/bash
# /opt/cryptominer-pro/scripts/health-check.sh

# Check API health
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/health)
if [ "$API_STATUS" != "200" ]; then
    echo "API health check failed: $API_STATUS"
    # Send alert or restart service
    sudo supervisorctl restart cryptominer-backend
fi

# Check mining status
MINING_STATUS=$(curl -s http://localhost:8001/api/mining/status | jq -r '.is_mining')
if [ "$MINING_STATUS" = "false" ]; then
    echo "Mining is not active"
    # Log or alert
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo "Disk usage is high: ${DISK_USAGE}%"
    # Clean logs or alert
fi
```

### Maintenance Tasks

**Regular Maintenance Checklist:**
- [ ] **Weekly**: Update system packages
- [ ] **Weekly**: Check log file sizes
- [ ] **Monthly**: Review mining performance
- [ ] **Monthly**: Update SSL certificates (if manual)
- [ ] **Quarterly**: Review security settings
- [ ] **Quarterly**: Database cleanup and optimization

**Automated Maintenance:**
```bash
# Add to crontab (sudo crontab -e)
# System updates (weekly, Sunday 2 AM)
0 2 * * 0 apt update && apt upgrade -y

# Log rotation (daily)
0 0 * * * find /var/log/cryptominer -name "*.log" -size +100M -exec truncate -s 0 {} \;

# Database cleanup (weekly)
0 3 * * 0 /opt/cryptominer-pro/scripts/db-cleanup.sh

# Health check (every 5 minutes)
*/5 * * * * /opt/cryptominer-pro/scripts/health-check.sh
```

## 🔄 Backup & Recovery

### Backup Strategy

**What to Backup:**
- Application configuration files
- Database data (MongoDB)
- AI training data
- User preferences and mining statistics
- SSL certificates and keys

**Backup Script:**
```bash
#!/bin/bash
# /opt/cryptominer-pro/scripts/backup.sh

BACKUP_DIR="/backup/cryptominer-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup configuration
cp -r /opt/cryptominer-pro/backend-nodejs/.env "$BACKUP_DIR/"
cp -r /opt/cryptominer-pro/frontend/.env "$BACKUP_DIR/"

# Backup database
mongodump --db cryptominer --out "$BACKUP_DIR/mongodb"

# Backup AI data
cp -r /opt/cryptominer-pro/data "$BACKUP_DIR/"

# Backup logs (last 7 days)
find /var/log/cryptominer -name "*.log" -mtime -7 -exec cp {} "$BACKUP_DIR/logs/" \;

# Create archive
tar -czf "/backup/cryptominer-backup-$(date +%Y%m%d).tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo "Backup completed: cryptominer-backup-$(date +%Y%m%d).tar.gz"
```

### Recovery Procedures

**Full System Recovery:**
```bash
# Stop services
sudo supervisorctl stop all

# Restore application
tar -xzf cryptominer-backup-YYYYMMDD.tar.gz
sudo cp -r cryptominer-YYYYMMDD/data /opt/cryptominer-pro/

# Restore database
mongorestore --db cryptominer cryptominer-YYYYMMDD/mongodb/cryptominer

# Restart services
sudo supervisorctl start all
```

## 🌐 Scaling & Load Balancing

### Horizontal Scaling

**Multi-Server Setup:**
```bash
# Server 1: Web frontend + API
# Server 2: Mining engine
# Server 3: Database + AI processing
# Server 4: Load balancer (Nginx)
```

**Load Balancer Configuration:**
```nginx
# /etc/nginx/sites-available/cryptominer-lb
upstream cryptominer_backend {
    server server1.example.com:8001;
    server server2.example.com:8001;
    server server3.example.com:8001;
}

server {
    listen 80;
    server_name your-domain.com;
    
    location /api {
        proxy_pass http://cryptominer_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Vertical Scaling

**Resource Optimization:**
- **CPU**: Increase thread count for mining
- **RAM**: Allocate more memory for MongoDB
- **Storage**: Use SSD for faster database operations
- **Network**: Higher bandwidth for multiple pools

## 🔐 Security Hardening

### Production Security Checklist

- [ ] **SSL/TLS**: HTTPS enabled with valid certificates
- [ ] **Firewall**: UFW or iptables configured
- [ ] **SSH**: Key-based authentication only
- [ ] **Database**: Authentication enabled
- [ ] **Updates**: Automatic security updates
- [ ] **Monitoring**: Intrusion detection system
- [ ] **Backups**: Encrypted offsite backups
- [ ] **Access**: Principle of least privilege

### Security Monitoring

**Fail2Ban Configuration:**
```bash
# Install Fail2Ban
sudo apt install fail2ban

# Configure for SSH and Nginx
sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
```

## 📈 Performance Optimization

### System Tuning

**Kernel Parameters:**
```bash
# /etc/sysctl.conf
# Network optimization
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216

# File system optimization
fs.file-max = 100000
fs.inotify.max_user_watches = 524288
```

**MongoDB Optimization:**
```bash
# Increase MongoDB cache size
echo "never" | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo "never" | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
```

**Mining Optimization:**
```bash
# CPU governor for performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Disable CPU throttling
sudo cpupower frequency-set -g performance
```

---

**Ready for production deployment! 🚀🔧**