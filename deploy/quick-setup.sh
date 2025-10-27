#!/bin/bash

# Catalyst9 Quick Setup Script
# One-command setup for DNS, DDNS, and initial deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}⚡ Catalyst9 Quick Setup${NC}"
echo -e "${BLUE}======================${NC}"

# Check if running from correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Please run this script from the catalyst-core directory${NC}"
    exit 1
fi

# Make all scripts executable
echo -e "\n${YELLOW}Making scripts executable...${NC}"
chmod +x deploy/*.sh
chmod +x deploy/dns/*.sh
chmod +x deploy/ci/*.sh
echo -e "${GREEN}✅ Scripts ready${NC}"

# Step 1: Check Cloudflare credentials
echo -e "\n${BLUE}Step 1: Cloudflare Credentials${NC}"
echo -e "${BLUE}==============================${NC}"

if [ ! -f "$HOME/.credentials/.cloudflare/dns-api-token" ]; then
    echo -e "${YELLOW}Cloudflare DNS API token not found.${NC}"
    echo -e "\nTo generate a token:"
    echo -e "1. Go to ${GREEN}https://dash.cloudflare.com/profile/api-tokens${NC}"
    echo -e "2. Create token with permissions: Zone:DNS:Edit and Zone:Zone:Read"
    echo -e "3. Scope to: catalyst9.ai"

    read -p "Do you have your Cloudflare DNS API token ready? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$HOME/.credentials/.cloudflare"
        read -s -p "Enter Cloudflare DNS API Token: " TOKEN
        echo "$TOKEN" > "$HOME/.credentials/.cloudflare/dns-api-token"
        chmod 600 "$HOME/.credentials/.cloudflare/dns-api-token"
        echo -e "\n${GREEN}✅ Token saved${NC}"
    else
        echo -e "${YELLOW}Please get your token and run this script again${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Cloudflare credentials found${NC}"
fi

# Step 2: Setup DNS records
echo -e "\n${BLUE}Step 2: DNS Configuration${NC}"
echo -e "${BLUE}========================${NC}"

echo -e "${YELLOW}Setting up DNS records for catalyst9.ai...${NC}"
if deploy/dns/cloudflare-setup.sh; then
    echo -e "${GREEN}✅ DNS records configured${NC}"
else
    echo -e "${RED}❌ DNS setup failed. Check your token and try again.${NC}"
    exit 1
fi

# Step 3: Setup Dynamic DNS
echo -e "\n${BLUE}Step 3: Dynamic DNS Setup${NC}"
echo -e "${BLUE}========================${NC}"

read -p "Deploy DDNS to dev-mini server? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deploying DDNS to dev-mini...${NC}"
    deploy/dns/setup-ddns.sh --remote dev-mini
    echo -e "${GREEN}✅ DDNS service deployed${NC}"
else
    echo -e "${YELLOW}Skipping DDNS deployment (you can run it later)${NC}"
fi

# Step 4: Build Docker image
echo -e "\n${BLUE}Step 4: Docker Build${NC}"
echo -e "${BLUE}===================${NC}"

echo -e "${YELLOW}Building Docker image...${NC}"
if deploy/docker-build.sh; then
    echo -e "${GREEN}✅ Docker image built${NC}"
else
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

# Step 5: Local testing
echo -e "\n${BLUE}Step 5: Local Testing${NC}"
echo -e "${BLUE}====================${NC}"

read -p "Start local Docker environment for testing? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Starting Docker Compose...${NC}"
    docker-compose up -d

    echo -e "${YELLOW}Waiting for services to start...${NC}"
    sleep 10

    if curl -f http://localhost:8080/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Local environment is running${NC}"
        echo -e "  API: ${GREEN}http://localhost:8080${NC}"
        echo -e "  Logs: ${GREEN}docker-compose logs -f${NC}"
    else
        echo -e "${YELLOW}⚠️  Services starting, check logs: docker-compose logs${NC}"
    fi
fi

# Step 6: Production deployment
echo -e "\n${BLUE}Step 6: Production Deployment${NC}"
echo -e "${BLUE}============================${NC}"

read -p "Deploy to k3s on dev-mini? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deploying to k3s...${NC}"
    deploy/deploy-k3s.sh --server dev-mini
    echo -e "${GREEN}✅ Deployed to k3s${NC}"
fi

# Summary
echo -e "\n${GREEN}🎉 Catalyst9 Setup Complete!${NC}"
echo -e "${BLUE}===========================${NC}"

echo -e "\n${YELLOW}Your Catalyst9 platform is configured with:${NC}"
echo -e "  ✅ DNS records at catalyst9.ai"
echo -e "  ✅ Dynamic DNS updater (if deployed)"
echo -e "  ✅ Docker images built"
echo -e "  ✅ Local development environment (if started)"
echo -e "  ✅ Production k3s deployment (if deployed)"

echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Verify DNS propagation:"
echo -e "   ${GREEN}nslookup catalyst9.ai${NC}"
echo -e ""
echo -e "2. Test the deployment:"
echo -e "   ${GREEN}curl https://catalyst9.ai/health${NC}"
echo -e ""
echo -e "3. Setup CI/CD in GitHub:"
echo -e "   - Add secrets to repository settings"
echo -e "   - Push to main branch to trigger deployment"
echo -e ""
echo -e "4. Monitor services:"
echo -e "   - DDNS logs: ${GREEN}ssh dev-mini 'sudo journalctl -u catalyst9-ddns -f'${NC}"
echo -e "   - k3s pods: ${GREEN}kubectl get pods -n catalyst9${NC}"

echo -e "\n${YELLOW}Documentation:${NC}"
echo -e "  - Docker/k8s: ${GREEN}deploy/README.md${NC}"
echo -e "  - DNS/CI/CD: ${GREEN}deploy/DNS-CICD-SETUP.md${NC}"

echo -e "\n${BLUE}Happy coding! 🚀${NC}"