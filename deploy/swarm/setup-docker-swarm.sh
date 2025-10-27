#!/bin/bash

# Simple Docker Swarm Setup for Catalyst9
# Works on Mac (dev-mini) with external drive

set -e

# Configuration
EXTERNAL_VOLUME="/Volumes/Extreme Pro"
SWARM_DATA_DIR="$EXTERNAL_VOLUME/docker-swarm"
NODE_NAME="${NODE_NAME:-dev-mini}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Docker Swarm Setup${NC}"
echo -e "${BLUE}====================${NC}"

# Check Docker installation
check_docker() {
    echo -e "\n${YELLOW}Checking Docker...${NC}"

    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker not found${NC}"
        echo -e "${YELLOW}Installing Docker...${NC}"

        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Mac installation
            brew install --cask docker
            open -a Docker
            echo -e "${YELLOW}Waiting for Docker to start...${NC}"
            sleep 30
        else
            # Linux installation
            curl -fsSL https://get.docker.com | sh
            sudo usermod -aG docker $USER
        fi
    fi

    # Check if Docker is running
    if docker info &> /dev/null; then
        echo -e "${GREEN}✅ Docker is running${NC}"
        docker --version
    else
        echo -e "${YELLOW}Starting Docker...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open -a Docker
            sleep 20
        else
            sudo systemctl start docker
        fi
    fi
}

# Setup external storage
setup_storage() {
    echo -e "\n${YELLOW}Setting up external storage...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac: Check if Extreme Pro is mounted
        if [ -d "$EXTERNAL_VOLUME" ]; then
            echo -e "${GREEN}✅ External drive found at $EXTERNAL_VOLUME${NC}"
        else
            echo -e "${YELLOW}⚠️  External drive not found, using local storage${NC}"
            SWARM_DATA_DIR="$HOME/docker-swarm"
        fi
    else
        # Linux: Mount external drive if needed
        if [ -d "$EXTERNAL_VOLUME" ]; then
            echo -e "${GREEN}✅ External drive found${NC}"
        else
            # Try to mount
            EXTERNAL_VOLUME="/mnt/extreme-pro"
            if [ ! -d "$EXTERNAL_VOLUME" ]; then
                sudo mkdir -p "$EXTERNAL_VOLUME"
            fi
            SWARM_DATA_DIR="$EXTERNAL_VOLUME/docker-swarm"
        fi
    fi

    # Create directory structure
    mkdir -p "$SWARM_DATA_DIR/volumes"
    mkdir -p "$SWARM_DATA_DIR/configs"
    mkdir -p "$SWARM_DATA_DIR/secrets"

    echo -e "${GREEN}✅ Storage configured at $SWARM_DATA_DIR${NC}"
}

# Initialize Docker Swarm
init_swarm() {
    echo -e "\n${YELLOW}Initializing Docker Swarm...${NC}"

    # Check if already in swarm mode
    if docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo -e "${GREEN}✅ Docker Swarm is already initialized${NC}"
        docker node ls
    else
        # Get IP address (prefer private network)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
        else
            IP=$(hostname -I | awk '{print $1}')
        fi

        echo -e "${YELLOW}Initializing swarm with IP: $IP${NC}"
        docker swarm init --advertise-addr "$IP" || true

        echo -e "${GREEN}✅ Docker Swarm initialized${NC}"
    fi

    # Save join token for future nodes
    docker swarm join-token worker > "$SWARM_DATA_DIR/worker-join-token.txt" 2>/dev/null || true
    docker swarm join-token manager > "$SWARM_DATA_DIR/manager-join-token.txt" 2>/dev/null || true
}

# Create Docker networks
create_networks() {
    echo -e "\n${YELLOW}Creating Docker networks...${NC}"

    # Create overlay network for services
    docker network create --driver overlay --attachable catalyst9-net 2>/dev/null || \
        echo -e "${YELLOW}Network catalyst9-net already exists${NC}"

    echo -e "${GREEN}✅ Networks configured${NC}"
}

# Create configs and secrets
setup_configs() {
    echo -e "\n${YELLOW}Setting up configs and secrets...${NC}"

    # Create SSL cert secrets (if they exist)
    if [ -f "$HOME/.credentials/.catalyst9.ai/fullchain.pem" ]; then
        docker secret create catalyst9_ssl_cert "$HOME/.credentials/.catalyst9.ai/fullchain.pem" 2>/dev/null || \
            echo "SSL cert secret already exists"

        docker secret create catalyst9_ssl_key "$HOME/.credentials/.catalyst9.ai/privkey.pem" 2>/dev/null || \
            echo "SSL key secret already exists"

        echo -e "${GREEN}✅ SSL certificates configured as secrets${NC}"
    fi

    # Create config for nginx
    if [ -f "deploy/nginx/catalyst9-docker.conf" ]; then
        docker config create nginx_config deploy/nginx/catalyst9-docker.conf 2>/dev/null || \
            echo "Nginx config already exists"
    fi
}

# Show helpful commands
show_commands() {
    echo -e "\n${GREEN}🎉 Docker Swarm Setup Complete!${NC}"
    echo -e "${BLUE}==============================${NC}"

    echo -e "\n${BLUE}Swarm Status:${NC}"
    docker node ls

    echo -e "\n${YELLOW}Storage Location:${NC}"
    echo -e "  ${GREEN}$SWARM_DATA_DIR${NC}"

    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "1. Deploy the stack:"
    echo -e "   ${GREEN}./deploy-stack.sh${NC}"
    echo -e ""
    echo -e "2. Or deploy manually:"
    echo -e "   ${GREEN}docker stack deploy -c docker-stack.yml catalyst9${NC}"

    echo -e "\n${YELLOW}Useful Commands:${NC}"
    echo -e "• List services: ${GREEN}docker service ls${NC}"
    echo -e "• List stacks: ${GREEN}docker stack ls${NC}"
    echo -e "• View logs: ${GREEN}docker service logs catalyst9_api${NC}"
    echo -e "• Scale service: ${GREEN}docker service scale catalyst9_api=3${NC}"
    echo -e "• Update service: ${GREEN}docker service update catalyst9_api${NC}"
    echo -e "• Remove stack: ${GREEN}docker stack rm catalyst9${NC}"
    echo -e "• Leave swarm: ${GREEN}docker swarm leave --force${NC}"

    echo -e "\n${YELLOW}Join other nodes (optional):${NC}"
    echo -e "On other machines, run the command from:"
    echo -e "  ${GREEN}$SWARM_DATA_DIR/worker-join-token.txt${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}Setting up Docker Swarm for Catalyst9${NC}"

    check_docker
    setup_storage
    init_swarm
    create_networks
    setup_configs
    show_commands
}

# Run main function
main "$@"