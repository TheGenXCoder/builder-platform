#!/bin/bash

# Remote Kubernetes Setup for macOS dev-mini
# Run this from your local Mac to set up Kubernetes on dev-mini

set -e

# Configuration
REMOTE_SERVER="${REMOTE_SERVER:-dev-mini}"
SETUP_TYPE="${SETUP_TYPE:-rancher}"  # rancher or docker

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Remote Kubernetes Setup for macOS${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "Target: ${GREEN}$REMOTE_SERVER${NC}"
echo -e "Type: ${GREEN}$SETUP_TYPE${NC}"
echo

# Check SSH connectivity
echo -e "${YELLOW}Checking SSH connectivity...${NC}"
if ssh -o ConnectTimeout=5 "$REMOTE_SERVER" "echo 'SSH connection successful'" &> /dev/null; then
    echo -e "${GREEN}✅ SSH connection successful${NC}"
else
    echo -e "${RED}❌ Cannot connect to $REMOTE_SERVER${NC}"
    exit 1
fi

# Check if dev-mini is macOS
echo -e "\n${YELLOW}Checking remote OS...${NC}"
REMOTE_OS=$(ssh "$REMOTE_SERVER" "uname -s")
if [ "$REMOTE_OS" != "Darwin" ]; then
    echo -e "${RED}❌ Remote server is not macOS (detected: $REMOTE_OS)${NC}"
    echo -e "${YELLOW}This script is for macOS servers only${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Remote server is running macOS${NC}"

# Check external drive on remote
echo -e "\n${YELLOW}Checking external drive on $REMOTE_SERVER...${NC}"
ssh "$REMOTE_SERVER" << 'EOF'
if [ -d "/Volumes/Extreme Pro" ]; then
    echo "✅ Extreme Pro drive found"
    df -h "/Volumes/Extreme Pro" | tail -1
else
    echo "⚠️  Extreme Pro drive not found"
    echo "Available volumes:"
    ls /Volumes/
fi
EOF

# Copy setup scripts
echo -e "\n${YELLOW}Copying setup scripts to $REMOTE_SERVER...${NC}"
ssh "$REMOTE_SERVER" "mkdir -p ~/k3s-setup"
scp install-rancher-desktop.sh install-docker-desktop.sh "$REMOTE_SERVER:~/k3s-setup/"
echo -e "${GREEN}✅ Scripts copied${NC}"

# Choose installation type
if [ "$SETUP_TYPE" = "rancher" ]; then
    echo -e "\n${BLUE}Installing Rancher Desktop on $REMOTE_SERVER...${NC}"

    # Install Rancher Desktop remotely
    ssh -t "$REMOTE_SERVER" << 'EOF'
    cd ~/k3s-setup
    chmod +x install-rancher-desktop.sh
    ./install-rancher-desktop.sh
EOF

elif [ "$SETUP_TYPE" = "docker" ]; then
    echo -e "\n${BLUE}Installing Docker Desktop on $REMOTE_SERVER...${NC}"

    # Install Docker Desktop remotely
    ssh -t "$REMOTE_SERVER" << 'EOF'
    cd ~/k3s-setup
    chmod +x install-docker-desktop.sh
    ./install-docker-desktop.sh
EOF

else
    echo -e "${RED}❌ Unknown setup type: $SETUP_TYPE${NC}"
    echo -e "Use: rancher or docker"
    exit 1
fi

# Get kubeconfig from remote
echo -e "\n${YELLOW}Retrieving kubeconfig from $REMOTE_SERVER...${NC}"

if [ "$SETUP_TYPE" = "rancher" ]; then
    # Wait for Rancher Desktop to create kubeconfig
    echo -e "${YELLOW}Waiting for kubeconfig to be available...${NC}"

    for i in {1..30}; do
        if ssh "$REMOTE_SERVER" "test -f ~/.kube/config" 2>/dev/null; then
            break
        fi
        echo -n "."
        sleep 10
    done
    echo

    # Copy kubeconfig
    mkdir -p ~/.kube
    ssh "$REMOTE_SERVER" "cat ~/.kube/config" > ~/.kube/config-dev-mini-rancher

    # Update server address
    SERVER_IP=$(ssh "$REMOTE_SERVER" "ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print \$2}'" 2>/dev/null)

    # For Rancher Desktop, the API server runs on port 6443
    sed -i.bak "s/127.0.0.1:6443/${SERVER_IP}:6443/g" ~/.kube/config-dev-mini-rancher
    sed -i.bak "s/localhost:6443/${SERVER_IP}:6443/g" ~/.kube/config-dev-mini-rancher
    rm ~/.kube/config-dev-mini-rancher.bak

    echo -e "${GREEN}✅ Kubeconfig saved to ~/.kube/config-dev-mini-rancher${NC}"

elif [ "$SETUP_TYPE" = "docker" ]; then
    # Docker Desktop kubeconfig
    mkdir -p ~/.kube
    ssh "$REMOTE_SERVER" "cat ~/.kube/config" > ~/.kube/config-dev-mini-docker

    # Update server address
    SERVER_IP=$(ssh "$REMOTE_SERVER" "ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print \$2}'" 2>/dev/null)

    # Docker Desktop uses port 6443
    sed -i.bak "s/127.0.0.1:6443/${SERVER_IP}:6443/g" ~/.kube/config-dev-mini-docker
    sed -i.bak "s/localhost:6443/${SERVER_IP}:6443/g" ~/.kube/config-dev-mini-docker
    rm ~/.kube/config-dev-mini-docker.bak

    echo -e "${GREEN}✅ Kubeconfig saved to ~/.kube/config-dev-mini-docker${NC}"
fi

# Test connection
echo -e "\n${YELLOW}Testing Kubernetes connection...${NC}"

if [ "$SETUP_TYPE" = "rancher" ]; then
    export KUBECONFIG=~/.kube/config-dev-mini-rancher
else
    export KUBECONFIG=~/.kube/config-dev-mini-docker
fi

if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✅ Successfully connected to Kubernetes cluster${NC}"

    echo -e "\n${BLUE}Cluster information:${NC}"
    kubectl cluster-info

    echo -e "\n${BLUE}Nodes:${NC}"
    kubectl get nodes
else
    echo -e "${YELLOW}⚠️  Cannot connect to Kubernetes cluster${NC}"
    echo -e "The cluster may still be initializing. Try again in a few minutes:"
    echo -e "  ${GREEN}export KUBECONFIG=~/.kube/config-dev-mini-$SETUP_TYPE${NC}"
    echo -e "  ${GREEN}kubectl cluster-info${NC}"
fi

# Create helper script
cat > ~/.kube/use-dev-mini-$SETUP_TYPE.sh << EOF
#!/bin/bash
# Quick script to switch to dev-mini Kubernetes cluster
export KUBECONFIG=~/.kube/config-dev-mini-$SETUP_TYPE
echo "Switched to dev-mini $SETUP_TYPE cluster"
kubectl cluster-info
EOF
chmod +x ~/.kube/use-dev-mini-$SETUP_TYPE.sh

# Show summary
echo -e "\n${GREEN}🎉 Remote Setup Complete!${NC}"
echo -e "${BLUE}========================${NC}"

echo -e "\n${YELLOW}To use the cluster from your Mac:${NC}"
echo -e "  ${GREEN}export KUBECONFIG=~/.kube/config-dev-mini-$SETUP_TYPE${NC}"
echo -e "  or"
echo -e "  ${GREEN}source ~/.kube/use-dev-mini-$SETUP_TYPE.sh${NC}"

echo -e "\n${YELLOW}Deploy Catalyst9:${NC}"
echo -e "  ${GREEN}cd /Users/BertSmith/personal/catalyst9/catalyst-core${NC}"
echo -e "  ${GREEN}kubectl apply -f deploy/k3s/${NC}"

echo -e "\n${YELLOW}Manage the cluster:${NC}"
echo -e "• Start: ${GREEN}ssh $REMOTE_SERVER 'open -a \"Rancher Desktop\"'${NC}"
echo -e "• Stop: ${GREEN}ssh $REMOTE_SERVER 'osascript -e \"quit app \\\"Rancher Desktop\\\"\"'${NC}"
echo -e "• Logs: ${GREEN}ssh $REMOTE_SERVER 'tail -f ~/Library/Logs/rancher-desktop/*.log'${NC}"

echo -e "\n${BLUE}Note:${NC} The Kubernetes cluster is running on $REMOTE_SERVER"
echo -e "Make sure the application stays running for cluster access."