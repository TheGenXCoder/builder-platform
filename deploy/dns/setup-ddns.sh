#!/bin/bash

# Setup script for Catalyst9 Dynamic DNS service
# Installs and configures the DDNS updater as a systemd service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📡 Catalyst9 Dynamic DNS Setup${NC}"
echo -e "${BLUE}===============================${NC}"

# Check if running on the target server
if [ "$1" = "--remote" ]; then
    SERVER="${2:-dev-mini}"
    echo -e "${YELLOW}Deploying to remote server: $SERVER${NC}"

    # Copy files to remote server
    echo -e "\n${YELLOW}Copying files to $SERVER...${NC}"
    ssh $SERVER "mkdir -p /opt/catalyst9/deploy/dns"
    scp ddns-updater.sh catalyst9-ddns.service $SERVER:/opt/catalyst9/deploy/dns/
    scp cloudflare-setup.sh $SERVER:/opt/catalyst9/deploy/dns/

    # Run setup on remote server
    ssh $SERVER "bash /opt/catalyst9/deploy/dns/setup-ddns.sh --local"

    echo -e "${GREEN}✅ DDNS setup complete on $SERVER${NC}"
    exit 0
fi

# Local installation
echo -e "\n${YELLOW}Installing DDNS updater locally...${NC}"

# Check for root/sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script needs sudo privileges for systemd setup${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

# Create directories
$SUDO mkdir -p /opt/catalyst9/deploy/dns
$SUDO mkdir -p /var/log

# Copy scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
$SUDO cp "$SCRIPT_DIR/ddns-updater.sh" /opt/catalyst9/deploy/dns/
$SUDO chmod +x /opt/catalyst9/deploy/dns/ddns-updater.sh

# Check for Cloudflare credentials
if [ ! -f "$HOME/.credentials/.cloudflare/dns-api-token" ]; then
    echo -e "${YELLOW}⚠️  Cloudflare DNS API token not found${NC}"
    echo -e "\n${YELLOW}Please create the following files:${NC}"
    echo -e "  1. ${GREEN}$HOME/.credentials/.cloudflare/dns-api-token${NC}"
    echo -e "     Your Cloudflare API token with DNS edit permissions"
    echo -e "\n  2. ${GREEN}$HOME/.credentials/.cloudflare/zone-id${NC} (optional)"
    echo -e "     Your Cloudflare Zone ID (will be fetched automatically if not provided)"
    echo -e "\n${YELLOW}Generate an API token at:${NC}"
    echo -e "  ${GREEN}https://dash.cloudflare.com/profile/api-tokens${NC}"
    echo -e "\nRequired permissions:"
    echo -e "  • Zone:DNS:Edit"
    echo -e "  • Zone:Zone:Read"

    read -p "Do you want to enter the API token now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$HOME/.credentials/.cloudflare"
        read -s -p "Enter Cloudflare API Token: " API_TOKEN
        echo "$API_TOKEN" > "$HOME/.credentials/.cloudflare/dns-api-token"
        chmod 600 "$HOME/.credentials/.cloudflare/dns-api-token"
        echo -e "\n${GREEN}✅ API token saved${NC}"
    else
        echo -e "${YELLOW}Please add credentials before starting the service${NC}"
    fi
fi

# Update systemd service file with current user
SERVICE_FILE="/opt/catalyst9/deploy/dns/catalyst9-ddns.service"
$SUDO cp "$SCRIPT_DIR/catalyst9-ddns.service" "$SERVICE_FILE"
$SUDO sed -i "s/User=BertSmith/User=$USER/g" "$SERVICE_FILE"
$SUDO sed -i "s/Group=BertSmith/Group=$USER/g" "$SERVICE_FILE"
$SUDO sed -i "s|/home/BertSmith|$HOME|g" "$SERVICE_FILE"

# Install systemd service
echo -e "\n${YELLOW}Installing systemd service...${NC}"
$SUDO cp "$SERVICE_FILE" /etc/systemd/system/catalyst9-ddns.service
$SUDO systemctl daemon-reload

# Create log file with proper permissions
$SUDO touch /var/log/catalyst9-ddns.log
$SUDO chown $USER:$USER /var/log/catalyst9-ddns.log

# Test the script once
echo -e "\n${YELLOW}Testing DDNS updater...${NC}"
if /opt/catalyst9/deploy/dns/ddns-updater.sh --once; then
    echo -e "${GREEN}✅ DDNS updater test successful${NC}"
else
    echo -e "${RED}❌ DDNS updater test failed${NC}"
    echo -e "${YELLOW}Please check your Cloudflare credentials and try again${NC}"
    exit 1
fi

# Enable and start service
echo -e "\n${YELLOW}Starting DDNS service...${NC}"
$SUDO systemctl enable catalyst9-ddns.service
$SUDO systemctl restart catalyst9-ddns.service

# Check service status
sleep 2
if $SUDO systemctl is-active --quiet catalyst9-ddns.service; then
    echo -e "${GREEN}✅ DDNS service is running${NC}"
else
    echo -e "${RED}❌ DDNS service failed to start${NC}"
    $SUDO journalctl -u catalyst9-ddns.service -n 20
    exit 1
fi

# Show status and logs
echo -e "\n${GREEN}🎉 Dynamic DNS Setup Complete!${NC}"
echo -e "${BLUE}=============================${NC}"

echo -e "\n${YELLOW}Service Status:${NC}"
$SUDO systemctl status catalyst9-ddns.service --no-pager | head -n 10

echo -e "\n${YELLOW}Useful commands:${NC}"
echo -e "  View logs:     ${GREEN}sudo journalctl -u catalyst9-ddns -f${NC}"
echo -e "  Check status:  ${GREEN}sudo systemctl status catalyst9-ddns${NC}"
echo -e "  Restart:       ${GREEN}sudo systemctl restart catalyst9-ddns${NC}"
echo -e "  Stop:          ${GREEN}sudo systemctl stop catalyst9-ddns${NC}"
echo -e "  Manual run:    ${GREEN}/opt/catalyst9/deploy/dns/ddns-updater.sh --once${NC}"

echo -e "\n${YELLOW}Current DNS Status:${NC}"
if [ -f "$HOME/.catalyst9-current-ip" ]; then
    CURRENT_IP=$(cat "$HOME/.catalyst9-current-ip")
    echo -e "  Current IP: ${GREEN}$CURRENT_IP${NC}"
    echo -e "  Check DNS: ${GREEN}nslookup catalyst9.ai${NC}"
fi