#!/bin/bash

# Remote k3s Installation Script
# Installs k3s on dev-mini from your local machine

set -e

# Configuration
REMOTE_SERVER="${REMOTE_SERVER:-dev-mini}"
REMOTE_USER="${REMOTE_USER:-$USER}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Remote k3s Installation${NC}"
echo -e "${BLUE}=========================${NC}"
echo -e "Target server: ${GREEN}$REMOTE_SERVER${NC}"
echo

# Check SSH connectivity
echo -e "${YELLOW}Checking SSH connectivity...${NC}"
if ssh -o ConnectTimeout=5 "$REMOTE_SERVER" "echo 'SSH connection successful'" &> /dev/null; then
    echo -e "${GREEN}✅ SSH connection successful${NC}"
else
    echo -e "${RED}❌ Cannot connect to $REMOTE_SERVER${NC}"
    echo -e "${YELLOW}Please check:${NC}"
    echo -e "  1. SSH keys are configured"
    echo -e "  2. Server is accessible"
    echo -e "  3. ~/.ssh/config has entry for $REMOTE_SERVER"
    exit 1
fi

# Copy installation script to remote server
echo -e "\n${YELLOW}Copying installation script to $REMOTE_SERVER...${NC}"
ssh "$REMOTE_SERVER" "mkdir -p ~/k3s-setup"
scp install-k3s-dev-mini.sh "$REMOTE_SERVER:~/k3s-setup/"
scp setup-k3s-storage.sh "$REMOTE_SERVER:~/k3s-setup/" 2>/dev/null || true
echo -e "${GREEN}✅ Scripts copied${NC}"

# Check external drive on remote server
echo -e "\n${YELLOW}Checking external drive on $REMOTE_SERVER...${NC}"
ssh "$REMOTE_SERVER" << 'EOF'
echo "Available block devices:"
lsblk 2>/dev/null || diskutil list 2>/dev/null || df -h

echo ""
echo "Looking for Extreme Pro drive..."
if mount | grep -q "Extreme Pro"; then
    echo "✅ Extreme Pro drive is mounted"
    mount | grep "Extreme Pro"
elif lsblk 2>/dev/null | grep -q "Extreme Pro"; then
    echo "✅ Extreme Pro drive found (not mounted)"
    lsblk | grep "Extreme Pro"
elif diskutil list 2>/dev/null | grep -q "Extreme Pro"; then
    echo "✅ Extreme Pro drive found (macOS)"
    diskutil list | grep "Extreme Pro"
else
    echo "⚠️  Extreme Pro drive not found"
    echo "Please ensure the external drive is connected"
fi
EOF

# Confirm installation
echo
read -p "Proceed with k3s installation on $REMOTE_SERVER? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

# Run installation on remote server
echo -e "\n${YELLOW}Running k3s installation on $REMOTE_SERVER...${NC}"
echo -e "${YELLOW}This will take a few minutes...${NC}"

ssh -t "$REMOTE_SERVER" "cd ~/k3s-setup && sudo bash install-k3s-dev-mini.sh"

# Check if installation was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ k3s installation completed on $REMOTE_SERVER${NC}"
else
    echo -e "${RED}❌ k3s installation failed${NC}"
    exit 1
fi

# Copy kubeconfig to local machine
echo -e "\n${YELLOW}Copying kubeconfig to local machine...${NC}"
mkdir -p ~/.kube

# Get kubeconfig from remote server
ssh "$REMOTE_SERVER" "sudo cat /etc/rancher/k3s/k3s.yaml" > ~/.kube/config-dev-mini

# Update server address in kubeconfig
SERVER_IP=$(ssh "$REMOTE_SERVER" "hostname -I | awk '{print \$1}'" 2>/dev/null || echo "$REMOTE_SERVER")
sed -i.bak "s/127.0.0.1/$SERVER_IP/g" ~/.kube/config-dev-mini
sed -i.bak "s/localhost/$SERVER_IP/g" ~/.kube/config-dev-mini
rm ~/.kube/config-dev-mini.bak

echo -e "${GREEN}✅ Kubeconfig saved to ~/.kube/config-dev-mini${NC}"

# Test connection
echo -e "\n${YELLOW}Testing k3s connection...${NC}"
export KUBECONFIG=~/.kube/config-dev-mini

if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✅ Successfully connected to k3s cluster${NC}"

    echo -e "\n${BLUE}Cluster information:${NC}"
    kubectl cluster-info

    echo -e "\n${BLUE}Nodes:${NC}"
    kubectl get nodes

    echo -e "\n${BLUE}Storage classes:${NC}"
    kubectl get storageclass
else
    echo -e "${YELLOW}⚠️  Cannot connect to k3s cluster${NC}"
    echo -e "You may need to:"
    echo -e "  1. Update firewall rules on $REMOTE_SERVER"
    echo -e "  2. Ensure k3s is running: ${GREEN}ssh $REMOTE_SERVER 'sudo systemctl status k3s'${NC}"
fi

# Create helper script for easy cluster access
cat > ~/.kube/use-dev-mini.sh << 'EOF'
#!/bin/bash
# Quick script to switch to dev-mini k3s cluster
export KUBECONFIG=~/.kube/config-dev-mini
echo "Switched to dev-mini k3s cluster"
kubectl cluster-info
EOF
chmod +x ~/.kube/use-dev-mini.sh

# Show next steps
echo -e "\n${GREEN}🎉 k3s Setup Complete!${NC}"
echo -e "${BLUE}=====================${NC}"

echo -e "\n${YELLOW}To use the k3s cluster:${NC}"
echo -e "  ${GREEN}export KUBECONFIG=~/.kube/config-dev-mini${NC}"
echo -e "  or"
echo -e "  ${GREEN}source ~/.kube/use-dev-mini.sh${NC}"

echo -e "\n${YELLOW}Deploy Catalyst9:${NC}"
echo -e "  ${GREEN}cd /Users/BertSmith/personal/catalyst9/catalyst-core${NC}"
echo -e "  ${GREEN}./deploy/deploy-k3s.sh --server dev-mini${NC}"

echo -e "\n${YELLOW}Management commands:${NC}"
echo -e "• View k3s status: ${GREEN}ssh $REMOTE_SERVER 'sudo systemctl status k3s'${NC}"
echo -e "• View k3s logs: ${GREEN}ssh $REMOTE_SERVER 'sudo journalctl -u k3s -f'${NC}"
echo -e "• Restart k3s: ${GREEN}ssh $REMOTE_SERVER 'sudo systemctl restart k3s'${NC}"
echo -e "• Check storage: ${GREEN}ssh $REMOTE_SERVER 'df -h /mnt/extreme-pro'${NC}"

echo -e "\n${YELLOW}Troubleshooting:${NC}"
echo -e "• If can't connect: Check firewall on $REMOTE_SERVER (port 6443)"
echo -e "• If storage issues: Check external drive is mounted"
echo -e "• View all pods: ${GREEN}kubectl get pods -A${NC}"