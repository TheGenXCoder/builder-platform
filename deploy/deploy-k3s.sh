#!/bin/bash

# Catalyst9 k3s Deployment Script
# Deploy Catalyst9 to k3s cluster (local or remote)

set -e

# Configuration
K3S_SERVER="${K3S_SERVER:-dev-mini}"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-~/.kube/config}"
DEPLOY_LOCAL="${DEPLOY_LOCAL:-false}"
NAMESPACE="catalyst9"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Catalyst9 k3s Deployment${NC}"
echo -e "${BLUE}============================${NC}"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --local) DEPLOY_LOCAL="true";;
        --server) K3S_SERVER="$2"; shift;;
        --kubeconfig) KUBECONFIG_PATH="$2"; shift;;
        *) echo "Unknown parameter: $1"; exit 1;;
    esac
    shift
done

# Function to install k3s locally
install_k3s_local() {
    echo -e "\n${YELLOW}Installing k3s locally...${NC}"

    if command -v k3s &> /dev/null; then
        echo -e "${GREEN}✅ k3s already installed${NC}"
    else
        curl -sfL https://get.k3s.io | sh -
        echo -e "${GREEN}✅ k3s installed${NC}"
    fi

    # Wait for k3s to be ready
    echo -e "${YELLOW}Waiting for k3s to be ready...${NC}"
    sleep 10
    sudo k3s kubectl wait --for=condition=Ready nodes --all --timeout=300s

    # Copy kubeconfig
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $(whoami) ~/.kube/config
    export KUBECONFIG=~/.kube/config
}

# Function to setup remote k3s
setup_remote_k3s() {
    echo -e "\n${YELLOW}Setting up k3s on ${K3S_SERVER}...${NC}"

    # Install k3s on remote server
    ssh "${K3S_SERVER}" << 'EOF'
        if command -v k3s &> /dev/null; then
            echo "k3s already installed"
        else
            echo "Installing k3s..."
            curl -sfL https://get.k3s.io | sh -
        fi

        # Get kubeconfig
        sudo cat /etc/rancher/k3s/k3s.yaml
EOF
    > /tmp/k3s-kubeconfig.yaml

    # Update server address in kubeconfig
    sed -i "s/127.0.0.1/${K3S_SERVER}/g" /tmp/k3s-kubeconfig.yaml

    # Merge with local kubeconfig
    mkdir -p ~/.kube
    KUBECONFIG=~/.kube/config:/tmp/k3s-kubeconfig.yaml kubectl config view --flatten > ~/.kube/config.new
    mv ~/.kube/config.new ~/.kube/config

    echo -e "${GREEN}✅ Remote k3s configured${NC}"
}

# Setup k3s based on deployment type
if [ "${DEPLOY_LOCAL}" == "true" ]; then
    install_k3s_local
else
    setup_remote_k3s
fi

# Verify kubectl connection
echo -e "\n${YELLOW}Verifying kubectl connection...${NC}"
kubectl cluster-info

# Create namespace
echo -e "\n${YELLOW}Creating namespace...${NC}"
kubectl apply -f k3s/namespace.yaml

# Update SSL certificates
echo -e "\n${YELLOW}Updating SSL certificates...${NC}"
if [ -f "/Users/BertSmith/.credentials/.catalyst9.ai/fullchain.pem" ] && [ -f "/Users/BertSmith/.credentials/.catalyst9.ai/privkey.pem" ]; then
    kubectl create secret tls catalyst9-tls \
        --cert="/Users/BertSmith/.credentials/.catalyst9.ai/fullchain.pem" \
        --key="/Users/BertSmith/.credentials/.catalyst9.ai/privkey.pem" \
        -n catalyst9 \
        --dry-run=client -o yaml | kubectl apply -f -
    echo -e "${GREEN}✅ SSL certificates updated${NC}"
else
    echo -e "${YELLOW}⚠️  SSL certificates not found, using self-signed${NC}"
fi

# Deploy PostgreSQL
echo -e "\n${YELLOW}Deploying PostgreSQL with pgvector...${NC}"
kubectl apply -f k3s/postgres.yaml
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n catalyst9

# Deploy Redis
echo -e "\n${YELLOW}Deploying Redis...${NC}"
kubectl apply -f k3s/redis.yaml
kubectl wait --for=condition=available --timeout=300s deployment/redis -n catalyst9

# Deploy Ollama
echo -e "\n${YELLOW}Deploying Ollama...${NC}"
kubectl apply -f k3s/ollama.yaml
kubectl wait --for=condition=available --timeout=600s deployment/ollama -n catalyst9

# Deploy Catalyst9 API
echo -e "\n${YELLOW}Deploying Catalyst9 API...${NC}"
kubectl apply -f k3s/catalyst9-api.yaml
kubectl wait --for=condition=available --timeout=300s deployment/catalyst9-api -n catalyst9

# Deploy Ingress
echo -e "\n${YELLOW}Configuring Ingress...${NC}"
kubectl apply -f k3s/ingress.yaml

# Get service info
echo -e "\n${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${BLUE}======================${NC}"

# Get LoadBalancer IP or NodePort
if [ "${DEPLOY_LOCAL}" == "true" ]; then
    echo -e "\n${YELLOW}Local Access:${NC}"
    echo -e "  API: ${GREEN}http://localhost:8080${NC}"
    echo -e "  Ingress: ${GREEN}https://localhost${NC}"

    # Port forward for immediate access
    echo -e "\n${YELLOW}Setting up port forwarding...${NC}"
    kubectl port-forward -n catalyst9 service/catalyst9-api 8080:80 &
    echo -e "${GREEN}✅ Port forwarding active on :8080${NC}"
else
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || \
              kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

    echo -e "\n${YELLOW}Remote Access:${NC}"
    echo -e "  Server IP: ${GREEN}${NODE_IP}${NC}"
    echo -e "  API: ${GREEN}http://${NODE_IP}${NC}"
    echo -e "  HTTPS: ${GREEN}https://${NODE_IP}${NC}"

    if [ "${K3S_SERVER}" == "dev-mini" ]; then
        echo -e "\n${YELLOW}Add to /etc/hosts for testing:${NC}"
        echo -e "  ${GREEN}${NODE_IP} catalyst9.ai api.catalyst9.ai${NC}"
    fi
fi

# Show pod status
echo -e "\n${YELLOW}Pod Status:${NC}"
kubectl get pods -n catalyst9

# Show logs command
echo -e "\n${YELLOW}View logs with:${NC}"
echo -e "  ${GREEN}kubectl logs -f deployment/catalyst9-api -n catalyst9${NC}"

# Test health endpoint
echo -e "\n${YELLOW}Testing health endpoint...${NC}"
sleep 5
if [ "${DEPLOY_LOCAL}" == "true" ]; then
    curl -s http://localhost:8080/health | jq . || echo "Waiting for service to be ready..."
else
    curl -s http://${NODE_IP}/health | jq . || echo "Waiting for service to be ready..."
fi

echo -e "\n${GREEN}✨ Catalyst9 is deployed and running!${NC}"