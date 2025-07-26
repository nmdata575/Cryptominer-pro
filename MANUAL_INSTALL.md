# Manual Installation Guide - CryptoMiner Pro (Node.js)

## Prerequisites

- Ubuntu 20.04+ or similar Linux distribution
- Internet connection
- User with sudo privileges

## Step 1: Install Node.js and npm

```bash
# Update system packages
sudo apt update

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

## Step 2: Install MongoDB

### Option A: Using Docker (Recommended)

```bash
# Install Docker
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Start MongoDB container
docker run -d \
    --name cryptominer-mongo \
    --restart unless-stopped \
    -p 27017:27017 \
    -v cryptominer-mongo-data:/data/db \
    mongo:6.0
```

### Option B: Install MongoDB Directly

```bash
# Import MongoDB GPG key
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Update package list
sudo apt-get update

# Install MongoDB
sudo apt-get install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
```

## Step 3: Set Up Application

```bash
# Create application directory
sudo mkdir -p /opt/cryptominer-pro
sudo chown -R $USER:$USER /opt/cryptominer-pro

# Copy application files (assuming you have the source)
cp -r backend-nodejs /opt/cryptominer-pro/
cp -r frontend /opt/cryptominer-pro/

# Install backend dependencies
cd /opt/cryptominer-pro/backend-nodejs
npm install

# Install frontend dependencies
cd /opt/cryptominer-pro/frontend
npm install
```

## Step 4: Configure Environment

```bash
# Configure backend environment
cd /opt/cryptominer-pro/backend-nodejs
cp .env.example .env  # if exists, or create .env with required variables

# Edit .env file with your configuration
nano .env
```

Example `.env` file:
```
PORT=8001
HOST=0.0.0.0
NODE_ENV=production
MONGO_URL=mongodb://localhost:27017/cryptominer
FRONTEND_URL=http://localhost:3000
```

## Step 5: Start the Application

### Manual Start

```bash
# Start backend
cd /opt/cryptominer-pro/backend-nodejs
npm start &

# Start frontend
cd /opt/cryptominer-pro/frontend
npm start &
```

### Using Supervisor (Recommended)

```bash
# Install supervisor
sudo apt-get install -y supervisor

# Create supervisor configuration
sudo tee /etc/supervisor/conf.d/cryptominer-pro.conf > /dev/null <<EOF
[program:cryptominer-backend]
command=npm start
directory=/opt/cryptominer-pro/backend-nodejs
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/cryptominer-backend.err.log
stdout_logfile=/var/log/supervisor/cryptominer-backend.out.log
environment=NODE_ENV=production

[program:cryptominer-frontend]
command=npm start
directory=/opt/cryptominer-pro/frontend
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/cryptominer-frontend.err.log
stdout_logfile=/var/log/supervisor/cryptominer-frontend.out.log
environment=PORT=3000

[group:cryptominer-pro]
programs=cryptominer-backend,cryptominer-frontend
priority=999
EOF

# Update supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start cryptominer-pro:*
```

## Step 6: Verify Installation

```bash
# Check if services are running
sudo supervisorctl status cryptominer-pro:*

# Test backend API
curl http://localhost:8001/api/health

# Test frontend
curl http://localhost:3000
```

## Step 7: Access the Application

- **Frontend Dashboard**: http://localhost:3000
- **Backend API**: http://localhost:8001
- **API Documentation**: http://localhost:8001/api/docs (if available)

## Troubleshooting

### Backend Won't Start

```bash
# Check logs
sudo tail -f /var/log/supervisor/cryptominer-backend.err.log

# Common issues:
# 1. MongoDB not running
docker ps  # Check if MongoDB container is running
sudo systemctl status mongod  # Check MongoDB service

# 2. Port already in use
sudo lsof -i :8001

# 3. Dependencies not installed
cd /opt/cryptominer-pro/backend-nodejs
npm install
```

### Frontend Won't Start

```bash
# Check logs
sudo tail -f /var/log/supervisor/cryptominer-frontend.err.log

# Common issues:
# 1. Port 3000 already in use
sudo lsof -i :3000

# 2. Dependencies not installed
cd /opt/cryptominer-pro/frontend
npm install

# 3. Build issues
npm run build
```

### MongoDB Connection Issues

```bash
# If using Docker:
docker logs cryptominer-mongo
docker restart cryptominer-mongo

# If using system installation:
sudo systemctl status mongod
sudo systemctl restart mongod
```

## Useful Commands

```bash
# Start/stop services
sudo supervisorctl start cryptominer-pro:*
sudo supervisorctl stop cryptominer-pro:*
sudo supervisorctl restart cryptominer-pro:*

# View logs
sudo supervisorctl tail -f cryptominer-pro:cryptominer-backend
sudo supervisorctl tail -f cryptominer-pro:cryptominer-frontend

# MongoDB (if using Docker)
docker exec -it cryptominer-mongo mongosh
docker logs cryptominer-mongo
```

## Uninstall

```bash
# Stop services
sudo supervisorctl stop cryptominer-pro:*

# Remove supervisor configuration
sudo rm /etc/supervisor/conf.d/cryptominer-pro.conf
sudo supervisorctl reread
sudo supervisorctl update

# Remove application files
sudo rm -rf /opt/cryptominer-pro

# Remove MongoDB (if using Docker)
docker stop cryptominer-mongo
docker rm cryptominer-mongo
docker volume rm cryptominer-mongo-data

# Remove MongoDB (if system installation)
sudo apt-get remove --purge mongodb-org*
sudo rm -rf /var/log/mongodb
sudo rm -rf /var/lib/mongodb
```

## Security Notes

1. **Change default passwords** in production
2. **Configure firewall** if exposing ports
3. **Use HTTPS** in production environments
4. **Regular updates** of dependencies

## Support

For issues or questions:
1. Check the logs first
2. Verify all dependencies are installed
3. Ensure MongoDB is running
4. Check port availability
5. Refer to the API documentation

---

**Happy Mining!** 🚀