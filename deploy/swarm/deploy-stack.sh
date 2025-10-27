#!/bin/bash

# Deploy Catalyst9 Stack to Docker Swarm
# Simple production deployment

set -e

# Configuration
STACK_NAME="catalyst9"
STORAGE_PATH="${STORAGE_PATH:-/Volumes/Extreme Pro}"
VERSION="${VERSION:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying Catalyst9 Stack${NC}"
echo -e "${BLUE}===========================${NC}"

# Check if Docker Swarm is initialized
if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo -e "${RED}❌ Docker Swarm is not initialized${NC}"
    echo -e "${YELLOW}Run ./setup-docker-swarm.sh first${NC}"
    exit 1
fi

# Build the image if needed
echo -e "\n${YELLOW}Building Docker image...${NC}"
if [ -f "Dockerfile" ]; then
    docker build -t catalyst9/api:$VERSION .
    echo -e "${GREEN}✅ Image built: catalyst9/api:$VERSION${NC}"
else
    echo -e "${YELLOW}No Dockerfile found, using existing image${NC}"
fi

# Create secrets if they don't exist
echo -e "\n${YELLOW}Setting up secrets...${NC}"

# Database password
if ! docker secret ls | grep -q "catalyst9_db_password"; then
    echo "catalyst9_prod_$(openssl rand -hex 12)" | docker secret create catalyst9_db_password -
    echo -e "${GREEN}✅ Created database password secret${NC}"
fi

# JWT secret
if ! docker secret ls | grep -q "catalyst9_jwt_secret"; then
    openssl rand -hex 32 | docker secret create catalyst9_jwt_secret -
    echo -e "${GREEN}✅ Created JWT secret${NC}"
fi

# SSL certificates
if [ -f "$HOME/.credentials/.catalyst9.ai/fullchain.pem" ]; then
    docker secret create catalyst9_ssl_cert "$HOME/.credentials/.catalyst9.ai/fullchain.pem" 2>/dev/null || true
    docker secret create catalyst9_ssl_key "$HOME/.credentials/.catalyst9.ai/privkey.pem" 2>/dev/null || true
    echo -e "${GREEN}✅ SSL certificates configured${NC}"
else
    echo -e "${YELLOW}⚠️  SSL certificates not found, HTTPS will not work${NC}"
fi

# Create volume directories
echo -e "\n${YELLOW}Creating volume directories...${NC}"
for dir in postgres redis ollama; do
    mkdir -p "$STORAGE_PATH/docker-swarm/volumes/$dir"
done
echo -e "${GREEN}✅ Volume directories created${NC}"

# Deploy the stack
echo -e "\n${YELLOW}Deploying stack...${NC}"
export STORAGE_PATH VERSION
docker stack deploy -c docker-stack.yml $STACK_NAME

echo -e "${GREEN}✅ Stack deployment initiated${NC}"

# Wait for services to be ready
echo -e "\n${YELLOW}Waiting for services to start...${NC}"
sleep 10

# Check service status
echo -e "\n${BLUE}Service Status:${NC}"
docker stack services $STACK_NAME

# Show logs command
echo -e "\n${YELLOW}To view logs:${NC}"
echo -e "  All services: ${GREEN}docker service logs -f ${STACK_NAME}_catalyst9-api${NC}"
echo -e "  Postgres: ${GREEN}docker service logs ${STACK_NAME}_postgres${NC}"
echo -e "  Redis: ${GREEN}docker service logs ${STACK_NAME}_redis${NC}"

# Test health endpoint
echo -e "\n${YELLOW}Testing health endpoint...${NC}"
sleep 5

if curl -f http://localhost:8080/health 2>/dev/null; then
    echo -e "${GREEN}✅ API is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  API not ready yet, check logs${NC}"
fi

echo -e "\n${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${BLUE}=====================${NC}"

echo -e "\n${YELLOW}Access your application:${NC}"
echo -e "  HTTP: ${GREEN}http://localhost${NC}"
echo -e "  HTTPS: ${GREEN}https://localhost${NC} (if SSL configured)"
echo -e "  Health: ${GREEN}http://localhost:8080/health${NC}"

echo -e "\n${YELLOW}Management commands:${NC}"
echo -e "• List services: ${GREEN}docker stack services $STACK_NAME${NC}"
echo -e "• Scale API: ${GREEN}docker service scale ${STACK_NAME}_catalyst9-api=3${NC}"
echo -e "• Update image: ${GREEN}docker service update --image catalyst9/api:new-version ${STACK_NAME}_catalyst9-api${NC}"
echo -e "• Remove stack: ${GREEN}docker stack rm $STACK_NAME${NC}"