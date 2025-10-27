#!/bin/bash

# Docker Desktop with Kubernetes for macOS (dev-mini)
# Alternative to Rancher Desktop with external drive support

set -e

# Configuration
EXTERNAL_VOLUME="/Volumes/Extreme Pro"
DOCKER_CPUS="${DOCKER_CPUS:-4}"
DOCKER_MEMORY="${DOCKER_MEMORY:-8}"  # GB

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Docker Desktop Setup for macOS${NC}"
echo -e "${BLUE}=================================${NC}"

# Function to check external drive
check_external_drive() {
    echo -e "\n${YELLOW}Checking for external drive...${NC}"

    if [ -d "$EXTERNAL_VOLUME" ]; then
        echo -e "${GREEN}✅ Found Extreme Pro at $EXTERNAL_VOLUME${NC}"
    else
        echo -e "${RED}❌ External drive not found at $EXTERNAL_VOLUME${NC}"
        echo -e "${YELLOW}Available volumes:${NC}"
        ls /Volumes/
        exit 1
    fi
}

# Function to install Docker Desktop
install_docker_desktop() {
    echo -e "\n${YELLOW}Installing Docker Desktop...${NC}"

    if [ -d "/Applications/Docker.app" ]; then
        echo -e "${YELLOW}Docker Desktop is already installed${NC}"

        read -p "Do you want to reinstall/update? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Keeping existing installation${NC}"
            return
        fi
    fi

    # Download and install Docker Desktop
    echo -e "${YELLOW}Downloading Docker Desktop...${NC}"

    # Detect architecture
    if [[ $(uname -m) == "arm64" ]]; then
        DOCKER_URL="https://desktop.docker.com/mac/main/arm64/Docker.dmg"
        echo -e "Detected Apple Silicon Mac"
    else
        DOCKER_URL="https://desktop.docker.com/mac/main/amd64/Docker.dmg"
        echo -e "Detected Intel Mac"
    fi

    curl -L -o /tmp/Docker.dmg "$DOCKER_URL"

    echo -e "${YELLOW}Installing Docker Desktop...${NC}"
    hdiutil attach /tmp/Docker.dmg
    cp -R "/Volumes/Docker/Docker.app" /Applications/
    hdiutil detach /Volumes/Docker
    rm /tmp/Docker.dmg

    echo -e "${GREEN}✅ Docker Desktop installed${NC}"
}

# Function to configure Docker Desktop
configure_docker_desktop() {
    echo -e "\n${YELLOW}Configuring Docker Desktop...${NC}"

    # Docker Desktop settings location
    DOCKER_SETTINGS="$HOME/Library/Group Containers/group.com.docker/settings.json"

    # Create configuration
    cat > /tmp/docker-settings.json << EOF
{
  "cpus": $DOCKER_CPUS,
  "memoryMiB": $((DOCKER_MEMORY * 1024)),
  "diskSizeMiB": 65536,
  "kubernetesEnabled": true,
  "kubernetesInitialInstallPerformed": false,
  "showKubernetesSystemContainers": false,
  "filesharingDirectories": [
    "/Users",
    "/Volumes",
    "/private",
    "/tmp",
    "$EXTERNAL_VOLUME"
  ]
}
EOF

    echo -e "${GREEN}✅ Configuration prepared${NC}"
    echo -e "${YELLOW}Note: You'll need to enable Kubernetes manually in Docker Desktop preferences${NC}"
}

# Function to start Docker Desktop
start_docker_desktop() {
    echo -e "\n${YELLOW}Starting Docker Desktop...${NC}"

    if pgrep -f "Docker Desktop" > /dev/null; then
        echo -e "${YELLOW}Docker Desktop is already running${NC}"
    else
        open -a Docker
        echo -e "${YELLOW}Waiting for Docker to start (this may take a minute)...${NC}"

        # Wait for Docker to be ready
        TIMEOUT=120
        ELAPSED=0

        while [ $ELAPSED -lt $TIMEOUT ]; do
            if docker system info &> /dev/null; then
                echo -e "\n${GREEN}✅ Docker is ready${NC}"
                break
            fi
            echo -n "."
            sleep 5
            ELAPSED=$((ELAPSED + 5))
        done
    fi
}

# Function to enable Kubernetes
enable_kubernetes() {
    echo -e "\n${YELLOW}Kubernetes Setup${NC}"
    echo -e "${BLUE}=================================${NC}"

    echo -e "\n${YELLOW}⚠️  Manual Step Required:${NC}"
    echo -e "1. Click the Docker icon in the menu bar"
    echo -e "2. Go to Preferences/Settings → Kubernetes"
    echo -e "3. Check 'Enable Kubernetes'"
    echo -e "4. Click 'Apply & Restart'"
    echo -e ""
    echo -e "This will take a few minutes to download Kubernetes images."

    read -p "Press Enter once you've enabled Kubernetes in Docker Desktop..." -r

    # Wait for Kubernetes to be ready
    echo -e "\n${YELLOW}Waiting for Kubernetes to be ready...${NC}"
    while ! kubectl get nodes &> /dev/null; do
        echo -n "."
        sleep 5
    done

    echo -e "\n${GREEN}✅ Kubernetes is ready${NC}"
}

# Function to setup external storage
setup_external_storage() {
    echo -e "\n${YELLOW}Setting up external storage...${NC}"

    # Create directories on external drive
    STORAGE_ROOT="$EXTERNAL_VOLUME/docker-desktop"

    mkdir -p "$STORAGE_ROOT/persistent-volumes"
    mkdir -p "$STORAGE_ROOT/docker-data"

    # Create symlink
    ln -sfn "$STORAGE_ROOT" "$HOME/docker-storage" 2>/dev/null || true

    echo -e "${GREEN}✅ Storage directories created at $STORAGE_ROOT${NC}"

    # Create PV for external storage
    cat > /tmp/docker-storage.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: extreme-pro-pv
spec:
  capacity:
    storage: 500Gi
  accessModes:
    - ReadWriteOnce
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: extreme-pro
  hostPath:
    path: "$EXTERNAL_VOLUME/docker-desktop/persistent-volumes"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: extreme-pro
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

    kubectl apply -f /tmp/docker-storage.yaml 2>/dev/null || {
        echo -e "${YELLOW}Storage configuration saved to /tmp/docker-storage.yaml${NC}"
        echo -e "Apply it after Kubernetes is enabled:"
        echo -e "  ${GREEN}kubectl apply -f /tmp/docker-storage.yaml${NC}"
    }
}

# Function to install additional tools
install_tools() {
    echo -e "\n${YELLOW}Installing additional tools...${NC}"

    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        brew install kubectl
        echo -e "${GREEN}✅ kubectl installed${NC}"
    fi

    # Install Helm
    if ! command -v helm &> /dev/null; then
        brew install helm
        echo -e "${GREEN}✅ Helm installed${NC}"
    fi
}

# Function to show summary
show_summary() {
    echo -e "\n${GREEN}🎉 Docker Desktop Setup Complete!${NC}"
    echo -e "${BLUE}================================${NC}"

    echo -e "\n${BLUE}Configuration:${NC}"
    echo -e "• CPUs: ${GREEN}$DOCKER_CPUS${NC}"
    echo -e "• Memory: ${GREEN}$DOCKER_MEMORY GB${NC}"
    echo -e "• Storage: ${GREEN}$EXTERNAL_VOLUME${NC}"

    echo -e "\n${YELLOW}Important:${NC}"
    echo -e "Docker Desktop requires a license for:"
    echo -e "• Large businesses (250+ employees OR $10M+ revenue)"
    echo -e "• Government entities"
    echo -e ""
    echo -e "Personal use and small businesses can use it for free."

    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "1. Enable Kubernetes in Docker Desktop settings"
    echo -e "2. Apply storage configuration:"
    echo -e "   ${GREEN}kubectl apply -f /tmp/docker-storage.yaml${NC}"
    echo -e "3. Deploy Catalyst9:"
    echo -e "   ${GREEN}kubectl apply -f deploy/k3s/${NC}"

    echo -e "\n${YELLOW}Useful Commands:${NC}"
    echo -e "• Check cluster: ${GREEN}kubectl cluster-info${NC}"
    echo -e "• View nodes: ${GREEN}kubectl get nodes${NC}"
    echo -e "• Docker context: ${GREEN}kubectl config use-context docker-desktop${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}Starting Docker Desktop setup on macOS${NC}"

    check_external_drive
    install_docker_desktop
    configure_docker_desktop
    start_docker_desktop
    enable_kubernetes
    setup_external_storage
    install_tools
    show_summary
}

# Run main function
main "$@"