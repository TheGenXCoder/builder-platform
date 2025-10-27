#!/bin/bash

# Catalyst9 Production Deployment Script
# Deploy the Catalyst9 platform to production

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="catalyst9.ai"
DEPLOY_USER="${DEPLOY_USER:-catalyst9}"
DEPLOY_HOST="${DEPLOY_HOST:-$DOMAIN}"
DEPLOY_PATH="/opt/catalyst9"
SSL_PATH="/Users/BertSmith/.credentials/.catalyst9.ai"

echo -e "${BLUE}🚀 Catalyst9 Production Deployment${NC}"
echo -e "${BLUE}=================================${NC}"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

# Check for SSL certificates
if [ ! -f "$SSL_PATH/fullchain.pem" ] || [ ! -f "$SSL_PATH/privkey.pem" ]; then
    echo -e "${RED}❌ SSL certificates not found at $SSL_PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✅ SSL certificates found${NC}"

# Check for required environment variables
if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}❌ DB_PASSWORD environment variable not set${NC}"
    exit 1
fi

if [ -z "$JWT_SECRET" ]; then
    echo -e "${RED}❌ JWT_SECRET environment variable not set${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Environment variables configured${NC}"

# Build the knowledge graph backend
echo -e "\n${YELLOW}Building Catalyst Core backend...${NC}"
cd /Users/BertSmith/personal/catalyst9/catalyst-core/projects/knowledge-graph-system

# Build Go binary
go build -o catalyst-core cmd/server/main.go
echo -e "${GREEN}✅ Backend built${NC}"

# Prepare deployment package
echo -e "\n${YELLOW}Preparing deployment package...${NC}"
TEMP_DIR=$(mktemp -d)
DEPLOY_PACKAGE="$TEMP_DIR/catalyst9-deploy.tar.gz"

# Copy necessary files
cp catalyst-core "$TEMP_DIR/"
cp -r internal "$TEMP_DIR/"
cp -r web "$TEMP_DIR/"
cp /Users/BertSmith/personal/catalyst9/catalyst-core/projects/neovim-kg-plugin/config/production.yaml "$TEMP_DIR/config.yaml"
cp /Users/BertSmith/personal/catalyst9/catalyst-core/deploy/nginx/catalyst9.conf "$TEMP_DIR/"

# Create deployment archive
tar -czf "$DEPLOY_PACKAGE" -C "$TEMP_DIR" .
echo -e "${GREEN}✅ Deployment package created${NC}"

# Deploy to server (if not local deployment)
if [ "$1" == "remote" ]; then
    echo -e "\n${YELLOW}Deploying to $DEPLOY_HOST...${NC}"

    # Copy package to server
    scp "$DEPLOY_PACKAGE" "$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH/"

    # Extract and configure on server
    ssh "$DEPLOY_USER@$DEPLOY_HOST" << EOF
        cd $DEPLOY_PATH
        tar -xzf catalyst9-deploy.tar.gz
        rm catalyst9-deploy.tar.gz

        # Set up systemd service
        sudo systemctl stop catalyst9 || true
        sudo cp catalyst-core /usr/local/bin/
        sudo systemctl start catalyst9

        # Update nginx configuration
        sudo cp catalyst9.conf /etc/nginx/sites-available/
        sudo ln -sf /etc/nginx/sites-available/catalyst9.conf /etc/nginx/sites-enabled/
        sudo nginx -t && sudo systemctl reload nginx
EOF

    echo -e "${GREEN}✅ Deployed to $DEPLOY_HOST${NC}"
else
    echo -e "\n${YELLOW}Local deployment mode${NC}"

    # Local deployment
    sudo mkdir -p "$DEPLOY_PATH"
    sudo tar -xzf "$DEPLOY_PACKAGE" -C "$DEPLOY_PATH"

    # Set up local nginx (Mac with Homebrew)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cp "$TEMP_DIR/catalyst9.conf" /usr/local/etc/nginx/servers/
        nginx -t && nginx -s reload
    else
        # Linux
        sudo cp "$TEMP_DIR/catalyst9.conf" /etc/nginx/sites-available/
        sudo ln -sf /etc/nginx/sites-available/catalyst9.conf /etc/nginx/sites-enabled/
        sudo nginx -t && sudo systemctl reload nginx
    fi

    echo -e "${GREEN}✅ Deployed locally${NC}"
fi

# Clean up
rm -rf "$TEMP_DIR"

# Create systemd service file (for reference)
cat > /tmp/catalyst9.service << EOF
[Unit]
Description=Catalyst9 Knowledge Graph API
After=network.target postgresql.service

[Service]
Type=simple
User=$DEPLOY_USER
WorkingDirectory=$DEPLOY_PATH
ExecStart=/usr/local/bin/catalyst-core -config $DEPLOY_PATH/config.yaml
Restart=always
RestartSec=10

Environment="DB_PASSWORD=$DB_PASSWORD"
Environment="JWT_SECRET=$JWT_SECRET"
Environment="REDIS_PASSWORD=$REDIS_PASSWORD"

[Install]
WantedBy=multi-user.target
EOF

echo -e "\n${YELLOW}Systemd service file created at /tmp/catalyst9.service${NC}"
echo -e "Copy it to /etc/systemd/system/ and enable with:"
echo -e "  sudo systemctl enable catalyst9"
echo -e "  sudo systemctl start catalyst9"

# Test the deployment
echo -e "\n${YELLOW}Testing deployment...${NC}"
sleep 2

# Test HTTPS
if curl -k https://localhost/health 2>/dev/null | grep -q "healthy"; then
    echo -e "${GREEN}✅ HTTPS endpoint is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS not responding yet${NC}"
fi

# Test API
if curl http://localhost:8080/health 2>/dev/null | grep -q "healthy"; then
    echo -e "${GREEN}✅ API backend is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  API backend not responding yet${NC}"
fi

echo -e "\n${GREEN}🎉 Catalyst9 Deployment Complete!${NC}"
echo -e "${BLUE}=================================${NC}"
echo -e "\nYour Catalyst9 platform is ready at:"
echo -e "  🌐 Main site: ${GREEN}https://catalyst9.ai${NC}"
echo -e "  🔌 API: ${GREEN}https://api.catalyst9.ai${NC}"
echo -e "  📚 Docs: ${GREEN}https://docs.catalyst9.ai${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Update DNS records to point to this server"
echo -e "  2. Test with: curl https://api.catalyst9.ai/health"
echo -e "  3. Configure monitoring and backups"
echo -e "  4. Launch! 🚀"