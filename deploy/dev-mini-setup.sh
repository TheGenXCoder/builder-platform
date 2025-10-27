#!/bin/bash

# Catalyst9 Dev-Mini Server Setup
# Deploy Catalyst9 to dev-mini for testing before DNS propagation

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEV_SERVER="dev-mini"
CATALYST_HOME="/home/BertSmith/catalyst9"
GO_VERSION="1.21.5"

echo -e "${BLUE}🚀 Catalyst9 Dev-Mini Deployment${NC}"
echo -e "${BLUE}==================================${NC}"

# Step 1: Create deployment package locally
echo -e "\n${YELLOW}Step 1: Building deployment package...${NC}"

cd /Users/BertSmith/personal/catalyst9/catalyst-core/projects/knowledge-graph-system

# Build for Linux (assuming dev-mini is Linux)
echo "Building Go binary for Linux..."
GOOS=linux GOARCH=amd64 go build -o catalyst-api cmd/server/main.go

# Create deployment archive
TEMP_DIR=$(mktemp -d)
echo "Creating deployment package..."

# Copy core files
cp catalyst-api "$TEMP_DIR/"
cp -r internal "$TEMP_DIR/"
cp -r web "$TEMP_DIR/" 2>/dev/null || echo "No web directory yet"

# Copy configurations
mkdir -p "$TEMP_DIR/config"
cp /Users/BertSmith/personal/catalyst9/catalyst-core/projects/neovim-kg-plugin/config/production.yaml "$TEMP_DIR/config/"

# Copy nginx config
mkdir -p "$TEMP_DIR/nginx"
cp /Users/BertSmith/personal/catalyst9/catalyst-core/deploy/nginx/catalyst9.conf "$TEMP_DIR/nginx/"

# Copy SSL certificates
mkdir -p "$TEMP_DIR/ssl"
cp /Users/BertSmith/.credentials/.catalyst9.ai/*.pem "$TEMP_DIR/ssl/"

# Create the archive
tar -czf /tmp/catalyst9-deploy.tar.gz -C "$TEMP_DIR" .
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✅ Deployment package created${NC}"

# Step 2: Copy to dev-mini
echo -e "\n${YELLOW}Step 2: Copying to dev-mini...${NC}"
scp /tmp/catalyst9-deploy.tar.gz $DEV_SERVER:/tmp/
echo -e "${GREEN}✅ Package copied to dev-mini${NC}"

# Step 3: Setup on dev-mini
echo -e "\n${YELLOW}Step 3: Setting up on dev-mini...${NC}"

ssh $DEV_SERVER << 'ENDSSH'
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Setting up Catalyst9 on dev-mini...${NC}"

# Create catalyst9 directory
mkdir -p ~/catalyst9
cd ~/catalyst9

# Extract deployment package
tar -xzf /tmp/catalyst9-deploy.tar.gz
rm /tmp/catalyst9-deploy.tar.gz

# Install dependencies if needed
echo -e "${YELLOW}Checking dependencies...${NC}"

# Check for Go
if ! command -v go &> /dev/null; then
    echo "Installing Go..."
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    rm go1.21.5.linux-amd64.tar.gz
fi

# Check for PostgreSQL
if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL..."
    sudo apt-get update
    sudo apt-get install -y postgresql postgresql-contrib

    # Install pgvector extension
    sudo apt-get install -y postgresql-15-pgvector
fi

# Check for Redis
if ! command -v redis-cli &> /dev/null; then
    echo "Installing Redis..."
    sudo apt-get install -y redis-server
    sudo systemctl enable redis-server
    sudo systemctl start redis-server
fi

# Check for nginx
if ! command -v nginx &> /dev/null; then
    echo "Installing nginx..."
    sudo apt-get install -y nginx
fi

echo -e "${GREEN}✅ Dependencies installed${NC}"

# Setup PostgreSQL database
echo -e "${YELLOW}Setting up database...${NC}"
sudo -u postgres psql << EOF
CREATE DATABASE catalyst9_dev;
CREATE USER catalyst9 WITH PASSWORD 'catalyst9_dev_password';
GRANT ALL PRIVILEGES ON DATABASE catalyst9_dev TO catalyst9;
\c catalyst9_dev
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
EOF

echo -e "${GREEN}✅ Database configured${NC}"

# Configure SSL certificates
echo -e "${YELLOW}Setting up SSL certificates...${NC}"
sudo mkdir -p /etc/catalyst9/ssl
sudo cp ssl/*.pem /etc/catalyst9/ssl/
sudo chmod 600 /etc/catalyst9/ssl/*.pem
echo -e "${GREEN}✅ SSL certificates installed${NC}"

# Configure nginx
echo -e "${YELLOW}Configuring nginx...${NC}"

# Update nginx config for local testing
cat > nginx/catalyst9-dev.conf << 'NGINXEOF'
# Catalyst9 Dev-Mini Configuration

server {
    listen 80;
    server_name dev-mini localhost;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name dev-mini localhost;

    ssl_certificate /etc/catalyst9/ssl/fullchain.pem;
    ssl_certificate_key /etc/catalyst9/ssl/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # For streaming responses
        proxy_buffering off;
        proxy_read_timeout 300s;
    }

    location /health {
        proxy_pass http://localhost:8080/health;
        access_log off;
    }
}
NGINXEOF

sudo cp nginx/catalyst9-dev.conf /etc/nginx/sites-available/catalyst9
sudo ln -sf /etc/nginx/sites-available/catalyst9 /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

echo -e "${GREEN}✅ Nginx configured${NC}"

# Create systemd service
echo -e "${YELLOW}Creating systemd service...${NC}"

sudo tee /etc/systemd/system/catalyst9.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=Catalyst9 Knowledge Graph API
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=BertSmith
WorkingDirectory=/home/BertSmith/catalyst9
ExecStart=/home/BertSmith/catalyst9/catalyst-api
Restart=always
RestartSec=10

Environment="DB_HOST=localhost"
Environment="DB_NAME=catalyst9_dev"
Environment="DB_USER=catalyst9"
Environment="DB_PASSWORD=catalyst9_dev_password"
Environment="REDIS_HOST=localhost"
Environment="JWT_SECRET=dev_jwt_secret_change_in_production"
Environment="PORT=8080"

[Install]
WantedBy=multi-user.target
SERVICEEOF

sudo systemctl daemon-reload
sudo systemctl enable catalyst9
sudo systemctl restart catalyst9

echo -e "${GREEN}✅ Systemd service created and started${NC}"

# Wait for service to start
sleep 3

# Check if service is running
if systemctl is-active --quiet catalyst9; then
    echo -e "${GREEN}✅ Catalyst9 API is running${NC}"
else
    echo -e "${RED}❌ Catalyst9 API failed to start${NC}"
    sudo journalctl -u catalyst9 -n 50
fi

# Test endpoints
echo -e "${YELLOW}Testing endpoints...${NC}"

if curl -k https://localhost/health 2>/dev/null | grep -q "healthy"; then
    echo -e "${GREEN}✅ HTTPS endpoint is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS endpoint not responding${NC}"
fi

if curl http://localhost:8080/health 2>/dev/null | grep -q "healthy"; then
    echo -e "${GREEN}✅ API endpoint is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  API endpoint not responding${NC}"
fi

echo -e "\n${GREEN}🎉 Catalyst9 deployed on dev-mini!${NC}"
echo -e "${BLUE}====================================${NC}"

ENDSSH

# Step 4: Show access information
echo -e "\n${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${BLUE}========================${NC}"
echo -e "\n${YELLOW}Access your Catalyst9 dev server:${NC}"
echo -e "  Local:  ${GREEN}https://dev-mini${NC}"
echo -e "  API:    ${GREEN}https://dev-mini/health${NC}"
echo -e "  Logs:   ${GREEN}ssh dev-mini 'sudo journalctl -u catalyst9 -f'${NC}"
echo -e "\n${YELLOW}Test from your local machine:${NC}"
echo -e "  ${GREEN}curl -k https://dev-mini/health${NC}"
echo -e "\n${YELLOW}For plugin testing, update your Neovim config:${NC}"
echo -e "  ${GREEN}api = { endpoint = 'https://dev-mini' }${NC}"
echo -e "\n${BLUE}While DNS is being set up, you can:${NC}"
echo -e "  1. Add to /etc/hosts: ${GREEN}dev-mini-ip catalyst9.ai api.catalyst9.ai${NC}"
echo -e "  2. Or use the dev-mini hostname directly"
echo -e "\n${YELLOW}Monitor the service:${NC}"
echo -e "  ${GREEN}ssh dev-mini 'sudo systemctl status catalyst9'${NC}"
echo -e "  ${GREEN}ssh dev-mini 'sudo tail -f /var/log/nginx/access.log'${NC}"

# Clean up local temp file
rm -f /tmp/catalyst9-deploy.tar.gz