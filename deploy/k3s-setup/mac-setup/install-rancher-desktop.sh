#!/bin/bash

# Rancher Desktop Installation for macOS (dev-mini)
# Provides k3s in a VM with external drive support

set -e

# Configuration
EXTERNAL_VOLUME="/Volumes/Extreme Pro"
RANCHER_VERSION="${RANCHER_VERSION:-latest}"
VM_CPUS="${VM_CPUS:-4}"
VM_MEMORY="${VM_MEMORY:-8192}"  # 8GB RAM for VM

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Rancher Desktop Setup for macOS${NC}"
echo -e "${BLUE}===================================${NC}"

# Function to check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}❌ This script is for macOS only${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Running on macOS${NC}"
}

# Function to check external drive
check_external_drive() {
    echo -e "\n${YELLOW}Checking for external drive...${NC}"

    if [ -d "$EXTERNAL_VOLUME" ]; then
        echo -e "${GREEN}✅ Found Extreme Pro at $EXTERNAL_VOLUME${NC}"

        # Show disk info
        DISK_INFO=$(diskutil info "$EXTERNAL_VOLUME" | grep -E "Volume Name:|File System:|Total Size:|Available:")
        echo -e "${BLUE}Disk Information:${NC}"
        echo "$DISK_INFO"
    else
        echo -e "${RED}❌ External drive not found at $EXTERNAL_VOLUME${NC}"
        echo -e "${YELLOW}Available volumes:${NC}"
        ls /Volumes/

        echo -e "\n${YELLOW}Please ensure your Extreme Pro drive is:${NC}"
        echo -e "  1. Connected to the Mac"
        echo -e "  2. Mounted (visible in Finder)"
        echo -e "  3. Named 'Extreme Pro' (or update EXTERNAL_VOLUME in this script)"
        exit 1
    fi
}

# Function to install Homebrew if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo -e "\n${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH for Apple Silicon Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        echo -e "${GREEN}✅ Homebrew installed${NC}"
    else
        echo -e "${GREEN}✅ Homebrew already installed${NC}"
        brew update
    fi
}

# Function to install Rancher Desktop
install_rancher_desktop() {
    echo -e "\n${YELLOW}Installing Rancher Desktop...${NC}"

    if [ -d "/Applications/Rancher Desktop.app" ]; then
        echo -e "${YELLOW}Rancher Desktop is already installed${NC}"

        # Check version
        INSTALLED_VERSION=$(/Applications/Rancher\ Desktop.app/Contents/MacOS/Rancher\ Desktop --version 2>/dev/null || echo "unknown")
        echo -e "Installed version: ${GREEN}$INSTALLED_VERSION${NC}"

        read -p "Do you want to reinstall/update? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Keeping existing installation${NC}"
            return
        fi
    fi

    # Install via Homebrew Cask
    brew install --cask rancher

    echo -e "${GREEN}✅ Rancher Desktop installed${NC}"
}

# Function to configure Rancher Desktop
configure_rancher_desktop() {
    echo -e "\n${YELLOW}Configuring Rancher Desktop...${NC}"

    # Create configuration directory
    CONFIG_DIR="$HOME/.config/rancher-desktop"
    mkdir -p "$CONFIG_DIR"

    # Create settings.json with optimized configuration
    cat > "$CONFIG_DIR/settings.json" << EOF
{
  "version": 6,
  "kubernetes": {
    "version": "1.28.5",
    "enabled": true,
    "options": {
      "traefik": false,
      "flannel": true
    },
    "ingress": {
      "localhostOnly": false
    }
  },
  "virtualMachine": {
    "cpus": $VM_CPUS,
    "memoryInGB": $(($VM_MEMORY / 1024)),
    "hostResolver": true
  },
  "containerEngine": {
    "name": "containerd",
    "customRootDir": ""
  },
  "application": {
    "debug": false,
    "telemetry": false,
    "autoStart": false,
    "startInBackground": false,
    "hideNotificationIcon": false
  },
  "pathManagementStrategy": "manual",
  "images": {
    "showAll": true,
    "namespaces": ["k8s.io", "default", "catalyst9"]
  }
}
EOF

    echo -e "${GREEN}✅ Configuration created${NC}"
}

# Function to setup persistent volumes on external drive
setup_external_storage() {
    echo -e "\n${YELLOW}Setting up external storage...${NC}"

    # Create directories on external drive
    STORAGE_ROOT="$EXTERNAL_VOLUME/rancher-desktop"

    echo -e "${YELLOW}Creating storage directories...${NC}"
    mkdir -p "$STORAGE_ROOT/persistent-volumes"
    mkdir -p "$STORAGE_ROOT/docker-images"
    mkdir -p "$STORAGE_ROOT/containerd"
    mkdir -p "$STORAGE_ROOT/k3s-data"

    # Create a symlink for easier access
    ln -sfn "$STORAGE_ROOT" "$HOME/rancher-storage" 2>/dev/null || true

    echo -e "${GREEN}✅ Storage directories created at $STORAGE_ROOT${NC}"

    # Show disk usage
    echo -e "\n${BLUE}Disk space on external drive:${NC}"
    df -h "$EXTERNAL_VOLUME"
}

# Function to start Rancher Desktop
start_rancher_desktop() {
    echo -e "\n${YELLOW}Starting Rancher Desktop...${NC}"

    # Check if already running
    if pgrep -f "Rancher Desktop" > /dev/null; then
        echo -e "${YELLOW}Rancher Desktop is already running${NC}"
        return
    fi

    # Start Rancher Desktop
    open -a "Rancher Desktop"

    echo -e "${YELLOW}Waiting for Rancher Desktop to initialize (this may take a few minutes)...${NC}"

    # Wait for kubectl context to be available
    TIMEOUT=300  # 5 minutes
    ELAPSED=0

    while [ $ELAPSED -lt $TIMEOUT ]; do
        if kubectl config current-context 2>/dev/null | grep -q "rancher-desktop"; then
            echo -e "\n${GREEN}✅ Rancher Desktop is ready${NC}"
            break
        fi

        echo -n "."
        sleep 5
        ELAPSED=$((ELAPSED + 5))
    done

    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo -e "\n${YELLOW}⚠️  Rancher Desktop is taking longer than expected to start${NC}"
        echo -e "Please check the Rancher Desktop UI for any issues"
    fi
}

# Function to configure kubectl
configure_kubectl() {
    echo -e "\n${YELLOW}Configuring kubectl...${NC}"

    # Rancher Desktop automatically configures kubectl
    if kubectl config current-context 2>/dev/null | grep -q "rancher-desktop"; then
        echo -e "${GREEN}✅ kubectl is configured for Rancher Desktop${NC}"

        # Show cluster info
        echo -e "\n${BLUE}Cluster information:${NC}"
        kubectl cluster-info

        echo -e "\n${BLUE}Nodes:${NC}"
        kubectl get nodes
    else
        echo -e "${YELLOW}⚠️  kubectl not configured yet${NC}"
        echo -e "Please wait for Rancher Desktop to fully start, then run:"
        echo -e "  ${GREEN}kubectl config use-context rancher-desktop${NC}"
    fi
}

# Function to create storage class for external drive
create_storage_class() {
    echo -e "\n${YELLOW}Creating storage class for external drive...${NC}"

    # Create a hostPath storage class that uses the external drive
    cat > /tmp/external-storage-class.yaml << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: extreme-pro-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: extreme-pro-pv-example
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: extreme-pro-storage
  hostPath:
    path: "$EXTERNAL_VOLUME/rancher-desktop/persistent-volumes"
    type: DirectoryOrCreate
EOF

    kubectl apply -f /tmp/external-storage-class.yaml 2>/dev/null || {
        echo -e "${YELLOW}Storage class will be created once cluster is ready${NC}"
        echo -e "You can apply it manually with:"
        echo -e "  ${GREEN}kubectl apply -f /tmp/external-storage-class.yaml${NC}"
    }
}

# Function to install additional tools
install_additional_tools() {
    echo -e "\n${YELLOW}Installing additional tools...${NC}"

    # Install kubectl if not present (Rancher Desktop includes it, but just in case)
    if ! command -v kubectl &> /dev/null; then
        brew install kubectl
        echo -e "${GREEN}✅ kubectl installed${NC}"
    fi

    # Install Helm
    if ! command -v helm &> /dev/null; then
        brew install helm
        echo -e "${GREEN}✅ Helm installed${NC}"
    else
        echo -e "${GREEN}✅ Helm already installed${NC}"
    fi

    # Install k9s (Kubernetes CLI UI)
    if ! command -v k9s &> /dev/null; then
        brew install k9s
        echo -e "${GREEN}✅ k9s installed${NC}"
    else
        echo -e "${GREEN}✅ k9s already installed${NC}"
    fi
}

# Function to create helper scripts
create_helper_scripts() {
    echo -e "\n${YELLOW}Creating helper scripts...${NC}"

    # Create start script
    cat > /usr/local/bin/rancher-start.sh << 'EOF'
#!/bin/bash
echo "Starting Rancher Desktop..."
open -a "Rancher Desktop"
echo "Waiting for cluster to be ready..."
while ! kubectl get nodes &> /dev/null; do
    sleep 5
done
echo "✅ Cluster is ready"
kubectl get nodes
EOF
    chmod +x /usr/local/bin/rancher-start.sh

    # Create stop script
    cat > /usr/local/bin/rancher-stop.sh << 'EOF'
#!/bin/bash
echo "Stopping Rancher Desktop..."
osascript -e 'quit app "Rancher Desktop"'
echo "✅ Rancher Desktop stopped"
EOF
    chmod +x /usr/local/bin/rancher-stop.sh

    echo -e "${GREEN}✅ Helper scripts created${NC}"
    echo -e "  • Start: ${GREEN}rancher-start.sh${NC}"
    echo -e "  • Stop: ${GREEN}rancher-stop.sh${NC}"
}

# Function to show next steps
show_next_steps() {
    echo -e "\n${GREEN}🎉 Rancher Desktop Setup Complete!${NC}"
    echo -e "${BLUE}=================================${NC}"

    echo -e "\n${BLUE}Configuration:${NC}"
    echo -e "• VM CPUs: ${GREEN}$VM_CPUS${NC}"
    echo -e "• VM Memory: ${GREEN}$VM_MEMORY MB${NC}"
    echo -e "• Storage: ${GREEN}$EXTERNAL_VOLUME${NC}"
    echo -e "• Kubernetes: ${GREEN}k3s (via Rancher Desktop)${NC}"

    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "1. Wait for Rancher Desktop to fully initialize"
    echo -e "2. Deploy Catalyst9:"
    echo -e "   ${GREEN}kubectl apply -f deploy/k3s/${NC}"
    echo -e "3. Access Rancher Desktop UI from menu bar icon"
    echo -e "4. Use k9s for CLI management:"
    echo -e "   ${GREEN}k9s${NC}"

    echo -e "\n${YELLOW}Useful Commands:${NC}"
    echo -e "• Check cluster: ${GREEN}kubectl cluster-info${NC}"
    echo -e "• View nodes: ${GREEN}kubectl get nodes${NC}"
    echo -e "• View all pods: ${GREEN}kubectl get pods -A${NC}"
    echo -e "• Start Rancher: ${GREEN}rancher-start.sh${NC}"
    echo -e "• Stop Rancher: ${GREEN}rancher-stop.sh${NC}"

    echo -e "\n${YELLOW}Storage Location:${NC}"
    echo -e "• External drive: ${GREEN}$EXTERNAL_VOLUME/rancher-desktop/${NC}"
    echo -e "• Symlink: ${GREEN}~/rancher-storage${NC}"

    echo -e "\n${BLUE}Note:${NC} Rancher Desktop provides a full k3s cluster in a VM,"
    echo -e "with all the features you need for production-like development."
}

# Main execution
main() {
    echo -e "${YELLOW}Starting Rancher Desktop setup on macOS${NC}"

    check_macos
    check_external_drive
    install_homebrew
    install_rancher_desktop
    configure_rancher_desktop
    setup_external_storage
    start_rancher_desktop
    configure_kubectl
    create_storage_class
    install_additional_tools
    create_helper_scripts
    show_next_steps
}

# Run main function
main "$@"