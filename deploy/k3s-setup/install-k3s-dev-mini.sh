#!/bin/bash

# k3s Installation Script for dev-mini with External Storage
# Installs k3s with data on external drive (Extreme Pro)

set -e

# Configuration
EXTERNAL_DRIVE="/dev/disk5"
EXTERNAL_LABEL="Extreme Pro"
MOUNT_POINT="/mnt/extreme-pro"
K3S_DATA_DIR="$MOUNT_POINT/k3s"
K3S_VERSION="${K3S_VERSION:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 k3s Installation for dev-mini${NC}"
echo -e "${BLUE}=================================${NC}"

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script needs to run with sudo${NC}"
    exec sudo "$0" "$@"
fi

# Function to setup external drive
setup_external_drive() {
    echo -e "\n${YELLOW}Setting up external drive...${NC}"

    # Check if drive exists
    if ! lsblk | grep -q "disk5"; then
        # Try alternative methods for macOS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if ! diskutil list | grep -q "Extreme Pro"; then
                echo -e "${RED}❌ External drive not found${NC}"
                echo -e "Available drives:"
                diskutil list
                exit 1
            fi
            # For macOS, the mount point might be different
            MOUNT_POINT="/Volumes/Extreme Pro"
            if [ -d "$MOUNT_POINT" ]; then
                echo -e "${GREEN}✅ External drive already mounted at $MOUNT_POINT${NC}"
                return
            fi
        else
            # Linux system
            echo -e "${RED}❌ External drive /dev/disk5 not found${NC}"
            echo -e "Available block devices:"
            lsblk
            exit 1
        fi
    fi

    # Create mount point if it doesn't exist
    if [ ! -d "$MOUNT_POINT" ]; then
        mkdir -p "$MOUNT_POINT"
        echo -e "${GREEN}✅ Created mount point: $MOUNT_POINT${NC}"
    fi

    # Check if already mounted
    if mount | grep -q "$MOUNT_POINT"; then
        echo -e "${GREEN}✅ Drive already mounted at $MOUNT_POINT${NC}"
    else
        # Mount the drive (Linux)
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Find the partition (usually disk5s1 or similar)
            PARTITION=$(lsblk -ln -o NAME,LABEL | grep "Extreme Pro" | awk '{print "/dev/"$1}' | head -1)

            if [ -z "$PARTITION" ]; then
                # Try to find by device name
                if [ -b "${EXTERNAL_DRIVE}1" ]; then
                    PARTITION="${EXTERNAL_DRIVE}1"
                elif [ -b "${EXTERNAL_DRIVE}s1" ]; then
                    PARTITION="${EXTERNAL_DRIVE}s1"
                else
                    echo -e "${RED}❌ Could not find partition on $EXTERNAL_DRIVE${NC}"
                    exit 1
                fi
            fi

            # Get filesystem type
            FS_TYPE=$(blkid -o value -s TYPE "$PARTITION" 2>/dev/null || echo "ext4")

            # Mount the partition
            mount -t "$FS_TYPE" "$PARTITION" "$MOUNT_POINT"
            echo -e "${GREEN}✅ Mounted $PARTITION to $MOUNT_POINT${NC}"

            # Add to fstab for permanent mounting
            if ! grep -q "$MOUNT_POINT" /etc/fstab; then
                echo "$PARTITION $MOUNT_POINT $FS_TYPE defaults 0 2" >> /etc/fstab
                echo -e "${GREEN}✅ Added to /etc/fstab for automatic mounting${NC}"
            fi
        fi
    fi

    # Create k3s directories
    mkdir -p "$K3S_DATA_DIR"
    mkdir -p "$K3S_DATA_DIR/storage"
    mkdir -p "$K3S_DATA_DIR/manifests"
    echo -e "${GREEN}✅ Created k3s directories in $K3S_DATA_DIR${NC}"
}

# Function to install k3s
install_k3s() {
    echo -e "\n${YELLOW}Installing k3s...${NC}"

    # Check if k3s is already installed
    if command -v k3s &> /dev/null; then
        echo -e "${YELLOW}k3s is already installed${NC}"
        k3s --version
        read -p "Do you want to reinstall? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Skipping k3s installation${NC}"
            return
        fi

        # Stop existing k3s
        systemctl stop k3s || true
        systemctl disable k3s || true
    fi

    # Install k3s with custom data directory
    echo -e "${YELLOW}Downloading and installing k3s...${NC}"

    # Create k3s config directory
    mkdir -p /etc/rancher/k3s

    # Create k3s config file
    cat > /etc/rancher/k3s/config.yaml << EOF
# k3s configuration
data-dir: $K3S_DATA_DIR
default-local-storage-path: $K3S_DATA_DIR/storage
write-kubeconfig-mode: "0644"
tls-san:
  - "dev-mini"
  - "catalyst9.ai"
  - "api.catalyst9.ai"
disable:
  - traefik  # We'll use our own ingress controller if needed
cluster-init: true
node-label:
  - "storage=extreme-pro"
  - "node-role.kubernetes.io/master=true"
kubelet-arg:
  - "max-pods=250"
  - "eviction-hard=memory.available<500Mi"
  - "eviction-soft=memory.available<1Gi"
  - "eviction-soft-grace-period=memory.available=2m"
EOF

    # Install k3s
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" sh -

    echo -e "${GREEN}✅ k3s installed successfully${NC}"

    # Wait for k3s to be ready
    echo -e "${YELLOW}Waiting for k3s to be ready...${NC}"
    sleep 10

    # Check k3s status
    systemctl status k3s --no-pager | head -n 10

    # Setup kubeconfig
    mkdir -p ~/.kube
    cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    chmod 600 ~/.kube/config

    # For non-root users
    mkdir -p /home/$SUDO_USER/.kube
    cp /etc/rancher/k3s/k3s.yaml /home/$SUDO_USER/.kube/config
    chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.kube
    chmod 600 /home/$SUDO_USER/.kube/config

    echo -e "${GREEN}✅ Kubeconfig configured${NC}"
}

# Function to setup storage class
setup_storage_class() {
    echo -e "\n${YELLOW}Setting up storage class...${NC}"

    cat > "$K3S_DATA_DIR/manifests/local-storage.yaml" << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: extreme-pro-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
parameters:
  path: "$K3S_DATA_DIR/storage"
EOF

    echo -e "${GREEN}✅ Storage class configured${NC}"
}

# Function to install essential components
install_essentials() {
    echo -e "\n${YELLOW}Installing essential components...${NC}"

    # Install kubectl if not present
    if ! command -v kubectl &> /dev/null; then
        echo -e "${YELLOW}Installing kubectl...${NC}"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl /usr/local/bin/
        echo -e "${GREEN}✅ kubectl installed${NC}"
    fi

    # Install Helm
    if ! command -v helm &> /dev/null; then
        echo -e "${YELLOW}Installing Helm...${NC}"
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        echo -e "${GREEN}✅ Helm installed${NC}"
    fi

    # Install metrics server
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

    # Patch metrics server for self-signed certs
    kubectl patch deployment metrics-server -n kube-system --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' || true

    echo -e "${GREEN}✅ Essential components installed${NC}"
}

# Function to verify installation
verify_installation() {
    echo -e "\n${YELLOW}Verifying k3s installation...${NC}"

    # Check k3s service
    if systemctl is-active --quiet k3s; then
        echo -e "${GREEN}✅ k3s service is running${NC}"
    else
        echo -e "${RED}❌ k3s service is not running${NC}"
        journalctl -u k3s -n 50
        exit 1
    fi

    # Check kubectl access
    if kubectl cluster-info &> /dev/null; then
        echo -e "${GREEN}✅ kubectl can access cluster${NC}"
    else
        echo -e "${RED}❌ kubectl cannot access cluster${NC}"
        exit 1
    fi

    # Check nodes
    echo -e "\n${BLUE}Cluster nodes:${NC}"
    kubectl get nodes -o wide

    # Check storage
    echo -e "\n${BLUE}Storage classes:${NC}"
    kubectl get storageclass

    # Check system pods
    echo -e "\n${BLUE}System pods:${NC}"
    kubectl get pods -A

    # Show disk usage
    echo -e "\n${BLUE}Disk usage on external drive:${NC}"
    df -h "$MOUNT_POINT"
}

# Function to create uninstall script
create_uninstall_script() {
    cat > /usr/local/bin/k3s-uninstall-custom.sh << 'EOF'
#!/bin/bash
# k3s uninstall script with external drive cleanup

echo "Uninstalling k3s..."
/usr/local/bin/k3s-uninstall.sh

echo "Cleaning up external drive data..."
read -p "Remove all k3s data from external drive? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf /mnt/extreme-pro/k3s
    echo "✅ k3s data removed from external drive"
fi

echo "✅ k3s uninstalled"
EOF
    chmod +x /usr/local/bin/k3s-uninstall-custom.sh
    echo -e "${GREEN}✅ Uninstall script created at /usr/local/bin/k3s-uninstall-custom.sh${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}Starting k3s installation on dev-mini${NC}"
    echo -e "External drive: ${GREEN}$EXTERNAL_DRIVE ($EXTERNAL_LABEL)${NC}"
    echo -e "Mount point: ${GREEN}$MOUNT_POINT${NC}"
    echo -e "k3s data directory: ${GREEN}$K3S_DATA_DIR${NC}"
    echo

    read -p "Continue with installation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        exit 0
    fi

    # Run installation steps
    setup_external_drive
    install_k3s
    setup_storage_class
    install_essentials
    verify_installation
    create_uninstall_script

    echo -e "\n${GREEN}🎉 k3s installation complete!${NC}"
    echo -e "${BLUE}=================================${NC}"

    echo -e "\n${YELLOW}Important information:${NC}"
    echo -e "• k3s data directory: ${GREEN}$K3S_DATA_DIR${NC}"
    echo -e "• Kubeconfig: ${GREEN}~/.kube/config${NC}"
    echo -e "• Storage class: ${GREEN}extreme-pro-storage${NC}"

    echo -e "\n${YELLOW}Next steps:${NC}"
    echo -e "1. Deploy Catalyst9:"
    echo -e "   ${GREEN}kubectl apply -f deploy/k3s/${NC}"
    echo -e ""
    echo -e "2. Check deployment:"
    echo -e "   ${GREEN}kubectl get pods -n catalyst9${NC}"
    echo -e ""
    echo -e "3. Access from local machine:"
    echo -e "   ${GREEN}scp dev-mini:~/.kube/config ~/.kube/config-dev-mini${NC}"
    echo -e "   ${GREEN}export KUBECONFIG=~/.kube/config-dev-mini${NC}"

    echo -e "\n${YELLOW}Management commands:${NC}"
    echo -e "• Start k3s: ${GREEN}sudo systemctl start k3s${NC}"
    echo -e "• Stop k3s: ${GREEN}sudo systemctl stop k3s${NC}"
    echo -e "• View logs: ${GREEN}sudo journalctl -u k3s -f${NC}"
    echo -e "• Uninstall: ${GREEN}sudo k3s-uninstall-custom.sh${NC}"
}

# Run main function
main "$@"