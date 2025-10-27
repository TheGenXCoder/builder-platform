#!/bin/bash

# Catalyst9 Cloudflare DNS Setup Script
# Sets up DNS records for catalyst9.ai domain

set -e

# Configuration
DOMAIN="catalyst9.ai"
CF_API_TOKEN_FILE="${CF_API_TOKEN_FILE:-$HOME/.credentials/.cloudflare/dns-api-token}"
CF_ZONE_ID_FILE="${CF_ZONE_ID_FILE:-$HOME/.credentials/.cloudflare/zone-id}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 Catalyst9 Cloudflare DNS Setup${NC}"
echo -e "${BLUE}=================================${NC}"

# Check for credentials
if [ ! -f "$CF_API_TOKEN_FILE" ]; then
    echo -e "${RED}❌ Cloudflare API token not found at: $CF_API_TOKEN_FILE${NC}"
    echo -e "${YELLOW}Please create the file with your Cloudflare API token${NC}"
    echo -e "${YELLOW}You can generate one at: https://dash.cloudflare.com/profile/api-tokens${NC}"
    echo -e "\nRequired permissions:"
    echo -e "  - Zone:DNS:Edit"
    echo -e "  - Zone:Zone:Read"
    exit 1
fi

# Read credentials
CF_API_TOKEN=$(cat "$CF_API_TOKEN_FILE" | tr -d '\n')

# Get Zone ID if not provided
if [ ! -f "$CF_ZONE_ID_FILE" ]; then
    echo -e "${YELLOW}Fetching Zone ID for $DOMAIN...${NC}"

    ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")

    ZONE_ID=$(echo "$ZONE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['result'][0]['id'])" 2>/dev/null)

    if [ -z "$ZONE_ID" ]; then
        echo -e "${RED}❌ Could not fetch Zone ID. Response:${NC}"
        echo "$ZONE_RESPONSE" | python3 -m json.tool
        exit 1
    fi

    # Save Zone ID for future use
    mkdir -p "$(dirname "$CF_ZONE_ID_FILE")"
    echo "$ZONE_ID" > "$CF_ZONE_ID_FILE"
    echo -e "${GREEN}✅ Zone ID saved to $CF_ZONE_ID_FILE${NC}"
else
    ZONE_ID=$(cat "$CF_ZONE_ID_FILE" | tr -d '\n')
fi

echo -e "${GREEN}✅ Using Zone ID: $ZONE_ID${NC}"

# Function to create/update DNS record
create_dns_record() {
    local TYPE=$1
    local NAME=$2
    local CONTENT=$3
    local PROXIED=${4:-true}
    local TTL=${5:-1}  # 1 = automatic

    echo -e "\n${YELLOW}Setting up $NAME ($TYPE record)...${NC}"

    # Check if record exists
    EXISTING=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=$TYPE&name=$NAME" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")

    RECORD_COUNT=$(echo "$EXISTING" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['result']))" 2>/dev/null || echo "0")

    if [ "$RECORD_COUNT" -gt "0" ]; then
        # Update existing record
        RECORD_ID=$(echo "$EXISTING" | python3 -c "import sys, json; print(json.load(sys.stdin)['result'][0]['id'])")

        RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"$TYPE\",\"name\":\"$NAME\",\"content\":\"$CONTENT\",\"ttl\":$TTL,\"proxied\":$PROXIED}")

        echo -e "${GREEN}✅ Updated $NAME${NC}"
    else
        # Create new record
        RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"$TYPE\",\"name\":\"$NAME\",\"content\":\"$CONTENT\",\"ttl\":$TTL,\"proxied\":$PROXIED}")

        echo -e "${GREEN}✅ Created $NAME${NC}"
    fi

    # Check for errors
    SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['success'])" 2>/dev/null || echo "false")
    if [ "$SUCCESS" != "True" ]; then
        echo -e "${RED}❌ Error creating/updating record:${NC}"
        echo "$RESPONSE" | python3 -m json.tool
    fi
}

# Get current public IP
echo -e "\n${YELLOW}Detecting public IP address...${NC}"
PUBLIC_IP=$(curl -s https://ipv4.icanhazip.com | tr -d '\n')

if [ -z "$PUBLIC_IP" ]; then
    echo -e "${RED}❌ Could not detect public IP${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Public IP: $PUBLIC_IP${NC}"

# Setup DNS records
echo -e "\n${BLUE}Creating DNS Records${NC}"
echo -e "${BLUE}===================${NC}"

# Main domain
create_dns_record "A" "$DOMAIN" "$PUBLIC_IP" false 300

# Subdomains
create_dns_record "A" "www.$DOMAIN" "$PUBLIC_IP" false 300
create_dns_record "A" "api.$DOMAIN" "$PUBLIC_IP" false 300
create_dns_record "A" "docs.$DOMAIN" "$PUBLIC_IP" false 300

# Optional: Mail records (if needed)
# create_dns_record "MX" "$DOMAIN" "mail.$DOMAIN" false 300 10

# Create CNAME for www (alternative to A record)
# create_dns_record "CNAME" "www.$DOMAIN" "$DOMAIN" false 300

# Summary
echo -e "\n${GREEN}🎉 DNS Setup Complete!${NC}"
echo -e "${BLUE}======================${NC}"
echo -e "\nDNS Records created for:"
echo -e "  • ${GREEN}$DOMAIN${NC} → $PUBLIC_IP"
echo -e "  • ${GREEN}www.$DOMAIN${NC} → $PUBLIC_IP"
echo -e "  • ${GREEN}api.$DOMAIN${NC} → $PUBLIC_IP"
echo -e "  • ${GREEN}docs.$DOMAIN${NC} → $PUBLIC_IP"

echo -e "\n${YELLOW}Note: DNS propagation may take up to 48 hours${NC}"
echo -e "You can check propagation status at: https://www.whatsmydns.net/#A/$DOMAIN"

# Save current IP for dynamic DNS
echo "$PUBLIC_IP" > ~/.catalyst9-current-ip

echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Set up dynamic DNS updater: ${GREEN}./setup-ddns.sh${NC}"
echo -e "2. Test DNS resolution: ${GREEN}nslookup $DOMAIN${NC}"
echo -e "3. Deploy application: ${GREEN}./deploy-k3s.sh${NC}"