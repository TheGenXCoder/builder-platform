#!/bin/bash

# One-command deployment to dev-mini
# Run this from your local Mac to deploy everything

set -e

# Configuration
REMOTE_SERVER="${REMOTE_SERVER:-dev-mini}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Deploying Catalyst9 to dev-mini${NC}"
echo -e "${BLUE}=================================${NC}"

# Build Docker image locally
echo -e "\n${YELLOW}Building Docker image...${NC}"
docker build -t catalyst9/api:latest .

# Save image to transfer
echo -e "${YELLOW}Saving Docker image...${NC}"
docker save catalyst9/api:latest | gzip > /tmp/catalyst9-api.tar.gz

# Transfer files to dev-mini
echo -e "\n${YELLOW}Transferring to dev-mini...${NC}"
ssh $REMOTE_SERVER "mkdir -p ~/catalyst9"
scp /tmp/catalyst9-api.tar.gz $REMOTE_SERVER:~/catalyst9/
scp -r deploy/swarm $REMOTE_SERVER:~/catalyst9/deploy/
scp docker-stack.yml $REMOTE_SERVER:~/catalyst9/

# Deploy on dev-mini
echo -e "\n${YELLOW}Deploying on dev-mini...${NC}"
ssh $REMOTE_SERVER << 'EOF'
cd ~/catalyst9

# Load Docker image
echo "Loading Docker image..."
docker load < catalyst9-api.tar.gz

# Setup Swarm (if not already)
if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "Initializing Docker Swarm..."
    chmod +x deploy/swarm/*.sh
    ./deploy/swarm/setup-docker-swarm.sh
fi

# Deploy stack
echo "Deploying stack..."
./deploy/swarm/deploy-stack.sh

# Cleanup
rm catalyst9-api.tar.gz
EOF

# Cleanup local
rm /tmp/catalyst9-api.tar.gz

echo -e "\n${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${BLUE}=====================${NC}"

echo -e "\n${YELLOW}Check deployment:${NC}"
echo -e "  ${GREEN}ssh $REMOTE_SERVER 'docker service ls'${NC}"
echo -e "  ${GREEN}ssh $REMOTE_SERVER 'docker service logs catalyst9_catalyst9-api'${NC}"

echo -e "\n${YELLOW}Access application:${NC}"
echo -e "  Local: ${GREEN}http://$REMOTE_SERVER${NC}"
echo -e "  Production: ${GREEN}https://catalyst9.ai${NC} (once DNS propagates)"

echo -e "\n${YELLOW}Your DDNS is already configured to update Cloudflare${NC}"
echo -e "Check DNS status: ${GREEN}nslookup catalyst9.ai${NC}"