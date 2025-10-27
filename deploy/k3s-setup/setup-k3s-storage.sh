#!/bin/bash

# k3s External Storage Setup Script
# Prepares the Extreme Pro drive for k3s data storage

set -e

# Configuration
DRIVE_LABEL="Extreme Pro"
MOUNT_POINT="/mnt/extreme-pro"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}💾 k3s External Storage Setup${NC}"
echo -e "${BLUE}============================${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script needs to run with sudo${NC}"
    exec sudo "$0" "$@"
fi

# Function to find the external drive
find_external_drive() {
    echo -e "\n${YELLOW}Searching for external drive...${NC}"

    # Try different methods to find the drive
    DEVICE=""

    # Method 1: Find by label
    if command -v blkid &> /dev/null; then
        DEVICE=$(blkid -L "Extreme Pro" 2>/dev/null | head -1)
        if [ -n "$DEVICE" ]; then
            echo -e "${GREEN}✅ Found drive by label: $DEVICE${NC}"
            return 0
        fi
    fi

    # Method 2: Find by size (assuming it's a large external drive)
    # Look for drives larger than 100GB that aren't the system drive
    if command -v lsblk &> /dev/null; then
        echo -e "\n${BLUE}Available block devices:${NC}"
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,LABEL

        # Find unmounted or externally mounted large drives
        CANDIDATES=$(lsblk -ndo NAME,SIZE,TYPE | grep disk | grep -E '[0-9]{3,}G|[0-9]+T' | grep -v "$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]$//')" | awk '{print "/dev/"$1}')

        if [ -n "$CANDIDATES" ]; then
            echo -e "\n${YELLOW}Found potential external drives:${NC}"
            for DRIVE in $CANDIDATES; do
                SIZE=$(lsblk -ndo SIZE "$DRIVE" 2>/dev/null)
                MODEL=$(lsblk -ndo MODEL "$DRIVE" 2>/dev/null | sed 's/[[:space:]]*$//')
                echo -e "  • ${GREEN}$DRIVE${NC} - $SIZE - $MODEL"
            done

            echo
            read -p "Enter the device path for Extreme Pro (e.g., /dev/sdb): " SELECTED_DEVICE

            if [ -b "$SELECTED_DEVICE" ]; then
                DEVICE="$SELECTED_DEVICE"
                echo -e "${GREEN}✅ Selected drive: $DEVICE${NC}"
            else
                echo -e "${RED}❌ Invalid device: $SELECTED_DEVICE${NC}"
                exit 1
            fi
        fi
    fi

    # Method 3: macOS specific
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "\n${BLUE}Available disks (macOS):${NC}"
        diskutil list

        DISK_ID=$(diskutil list | grep -B 3 "Extreme Pro" | grep "/dev/disk" | head -1 | awk '{print $1}')
        if [ -n "$DISK_ID" ]; then
            DEVICE="$DISK_ID"
            echo -e "${GREEN}✅ Found drive: $DEVICE${NC}"
        else
            echo
            read -p "Enter the disk identifier for Extreme Pro (e.g., /dev/disk5): " SELECTED_DEVICE
            DEVICE="$SELECTED_DEVICE"
        fi
    fi

    if [ -z "$DEVICE" ]; then
        echo -e "${RED}❌ Could not find external drive${NC}"
        echo -e "${YELLOW}Please ensure the Extreme Pro drive is connected${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Using device: $DEVICE${NC}"
}

# Function to prepare the drive
prepare_drive() {
    local DEVICE=$1

    echo -e "\n${YELLOW}Checking drive $DEVICE...${NC}"

    # Check if drive has partitions
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux: Check for existing partitions
        PARTITIONS=$(lsblk -ln -o NAME "$DEVICE" | tail -n +2)

        if [ -n "$PARTITIONS" ]; then
            echo -e "${GREEN}✅ Drive has existing partitions${NC}"
            PARTITION="${DEVICE}1"

            # Check filesystem
            FS_TYPE=$(blkid -o value -s TYPE "$PARTITION" 2>/dev/null || echo "unknown")
            echo -e "Filesystem type: ${GREEN}$FS_TYPE${NC}"

            # Check if mounted
            if mount | grep -q "$PARTITION"; then
                CURRENT_MOUNT=$(mount | grep "$PARTITION" | awk '{print $3}')
                echo -e "${YELLOW}Drive is mounted at: $CURRENT_MOUNT${NC}"

                if [ "$CURRENT_MOUNT" != "$MOUNT_POINT" ]; then
                    read -p "Unmount from $CURRENT_MOUNT and remount at $MOUNT_POINT? (y/n) " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        umount "$PARTITION"
                        echo -e "${GREEN}✅ Unmounted from $CURRENT_MOUNT${NC}"
                    else
                        MOUNT_POINT="$CURRENT_MOUNT"
                        echo -e "${YELLOW}Using existing mount point: $MOUNT_POINT${NC}"
                    fi
                fi
            fi
        else
            echo -e "${YELLOW}Drive has no partitions. Creating new partition...${NC}"

            # Create partition table and partition
            read -p "This will create a new partition table. All data will be lost. Continue? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Create GPT partition table
                parted -s "$DEVICE" mklabel gpt
                parted -s "$DEVICE" mkpart primary ext4 0% 100%

                # Format the partition
                PARTITION="${DEVICE}1"
                mkfs.ext4 -L "Extreme Pro" "$PARTITION"
                echo -e "${GREEN}✅ Created and formatted partition${NC}"
            else
                echo -e "${YELLOW}Cancelled partition creation${NC}"
                exit 1
            fi
        fi

        # Mount the partition
        mount_partition "$PARTITION"

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Different handling
        echo -e "${YELLOW}macOS detected. Drive should be formatted with Disk Utility${NC}"
        echo -e "Recommended format: APFS or ExFAT for compatibility"

        MOUNT_POINT="/Volumes/Extreme Pro"
        if [ -d "$MOUNT_POINT" ]; then
            echo -e "${GREEN}✅ Drive is mounted at $MOUNT_POINT${NC}"
        else
            echo -e "${RED}❌ Drive not mounted. Please mount it using Finder or diskutil${NC}"
            exit 1
        fi
    fi
}

# Function to mount partition
mount_partition() {
    local PARTITION=$1

    # Create mount point
    if [ ! -d "$MOUNT_POINT" ]; then
        mkdir -p "$MOUNT_POINT"
        echo -e "${GREEN}✅ Created mount point: $MOUNT_POINT${NC}"
    fi

    # Mount the partition
    if ! mount | grep -q "$PARTITION"; then
        mount "$PARTITION" "$MOUNT_POINT"
        echo -e "${GREEN}✅ Mounted $PARTITION to $MOUNT_POINT${NC}"

        # Add to fstab for automatic mounting
        if ! grep -q "$MOUNT_POINT" /etc/fstab; then
            FS_TYPE=$(blkid -o value -s TYPE "$PARTITION")
            UUID=$(blkid -o value -s UUID "$PARTITION")
            echo "UUID=$UUID $MOUNT_POINT $FS_TYPE defaults,nofail 0 2" >> /etc/fstab
            echo -e "${GREEN}✅ Added to /etc/fstab for automatic mounting${NC}"
        fi
    else
        echo -e "${GREEN}✅ Partition already mounted${NC}"
    fi
}

# Function to setup k3s directories
setup_k3s_directories() {
    echo -e "\n${YELLOW}Setting up k3s directories...${NC}"

    K3S_DATA_DIR="$MOUNT_POINT/k3s"

    # Create directory structure
    mkdir -p "$K3S_DATA_DIR"
    mkdir -p "$K3S_DATA_DIR/storage"
    mkdir -p "$K3S_DATA_DIR/manifests"
    mkdir -p "$K3S_DATA_DIR/server"
    mkdir -p "$K3S_DATA_DIR/agent"
    mkdir -p "$K3S_DATA_DIR/logs"

    # Set permissions
    chmod 755 "$K3S_DATA_DIR"

    # Create a test file to verify write access
    if touch "$K3S_DATA_DIR/test-write" 2>/dev/null; then
        rm "$K3S_DATA_DIR/test-write"
        echo -e "${GREEN}✅ Write access verified${NC}"
    else
        echo -e "${RED}❌ Cannot write to $K3S_DATA_DIR${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ k3s directories created${NC}"

    # Show disk space
    echo -e "\n${BLUE}Disk space on external drive:${NC}"
    df -h "$MOUNT_POINT"
}

# Function to create backup script
create_backup_script() {
    echo -e "\n${YELLOW}Creating backup script...${NC}"

    cat > /usr/local/bin/k3s-backup.sh << EOF
#!/bin/bash
# Backup k3s data from external drive

BACKUP_DIR="\$HOME/k3s-backups"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="\$BACKUP_DIR/k3s-backup-\$TIMESTAMP.tar.gz"

echo "Creating k3s backup..."
mkdir -p "\$BACKUP_DIR"

# Stop k3s for consistent backup
sudo systemctl stop k3s

# Create backup
sudo tar -czf "\$BACKUP_FILE" -C "$MOUNT_POINT" k3s

# Start k3s again
sudo systemctl start k3s

echo "✅ Backup created: \$BACKUP_FILE"
echo "Size: \$(du -h "\$BACKUP_FILE" | awk '{print \$1}')"
EOF

    chmod +x /usr/local/bin/k3s-backup.sh
    echo -e "${GREEN}✅ Backup script created at /usr/local/bin/k3s-backup.sh${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}Preparing external storage for k3s${NC}"

    # Find the external drive
    find_external_drive

    # Prepare and mount the drive
    if [ -n "$DEVICE" ]; then
        prepare_drive "$DEVICE"
    fi

    # Setup k3s directories
    setup_k3s_directories

    # Create backup script
    create_backup_script

    echo -e "\n${GREEN}🎉 Storage setup complete!${NC}"
    echo -e "${BLUE}========================${NC}"

    echo -e "\n${BLUE}Storage configuration:${NC}"
    echo -e "• Mount point: ${GREEN}$MOUNT_POINT${NC}"
    echo -e "• k3s data directory: ${GREEN}$MOUNT_POINT/k3s${NC}"
    echo -e "• Available space: ${GREEN}$(df -h "$MOUNT_POINT" | tail -1 | awk '{print $4}')${NC}"
    echo -e "• Total space: ${GREEN}$(df -h "$MOUNT_POINT" | tail -1 | awk '{print $2}')${NC}"

    echo -e "\n${YELLOW}Next steps:${NC}"
    echo -e "1. Install k3s: ${GREEN}sudo ./install-k3s-dev-mini.sh${NC}"
    echo -e "2. Backup data: ${GREEN}k3s-backup.sh${NC}"

    echo -e "\n${YELLOW}Important notes:${NC}"
    echo -e "• Drive will auto-mount on boot (added to /etc/fstab)"
    echo -e "• k3s data is stored on external drive for performance"
    echo -e "• Regular backups recommended: ${GREEN}k3s-backup.sh${NC}"
}

# Run main function
main "$@"