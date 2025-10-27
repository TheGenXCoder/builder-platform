#!/bin/bash

# Catalyst9 Dynamic DNS Updater for Cloudflare
# Monitors IP changes and updates DNS records automatically

# Configuration
DOMAIN="catalyst9.ai"
CF_API_TOKEN_FILE="${CF_API_TOKEN_FILE:-$HOME/.credentials/.cloudflare/dns-api-token}"
CF_ZONE_ID_FILE="${CF_ZONE_ID_FILE:-$HOME/.credentials/.cloudflare/zone-id}"
IP_CACHE_FILE="${IP_CACHE_FILE:-$HOME/.catalyst9-current-ip}"
LOG_FILE="${LOG_FILE:-/var/log/catalyst9-ddns.log}"
CHECK_INTERVAL=${CHECK_INTERVAL:-300}  # 5 minutes default

# Colors for output (only when interactive)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    BLUE=''
    YELLOW=''
    NC=''
fi

# Function to log messages
log_message() {
    local LEVEL=$1
    shift
    local MESSAGE="$@"
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] [$LEVEL] $MESSAGE" >> "$LOG_FILE"
    if [ "$LEVEL" = "ERROR" ]; then
        echo -e "${RED}[$LEVEL] $MESSAGE${NC}" >&2
    elif [ "$LEVEL" = "INFO" ]; then
        echo -e "${GREEN}[$LEVEL] $MESSAGE${NC}"
    else
        echo -e "${YELLOW}[$LEVEL] $MESSAGE${NC}"
    fi
}

# Check for required files
if [ ! -f "$CF_API_TOKEN_FILE" ]; then
    log_message "ERROR" "Cloudflare API token not found at: $CF_API_TOKEN_FILE"
    exit 1
fi

if [ ! -f "$CF_ZONE_ID_FILE" ]; then
    log_message "ERROR" "Cloudflare Zone ID not found at: $CF_ZONE_ID_FILE"
    log_message "INFO" "Run cloudflare-setup.sh first to initialize"
    exit 1
fi

# Read credentials
CF_API_TOKEN=$(cat "$CF_API_TOKEN_FILE" | tr -d '\n')
ZONE_ID=$(cat "$CF_ZONE_ID_FILE" | tr -d '\n')

# Function to get current public IP
get_public_ip() {
    # Try multiple services for redundancy
    local IP=""

    # Try ipv4.icanhazip.com
    IP=$(curl -s --max-time 10 https://ipv4.icanhazip.com 2>/dev/null | tr -d '\n')
    if [ -n "$IP" ] && [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$IP"
        return
    fi

    # Try api.ipify.org
    IP=$(curl -s --max-time 10 https://api.ipify.org 2>/dev/null | tr -d '\n')
    if [ -n "$IP" ] && [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$IP"
        return
    fi

    # Try ifconfig.me
    IP=$(curl -s --max-time 10 https://ifconfig.me 2>/dev/null | tr -d '\n')
    if [ -n "$IP" ] && [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$IP"
        return
    fi

    return 1
}

# Function to update DNS record
update_dns_record() {
    local NAME=$1
    local IP=$2

    log_message "INFO" "Updating $NAME to $IP"

    # Get existing record
    RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$NAME" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")

    RECORD_COUNT=$(echo "$RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(len(d.get('result', [])))" 2>/dev/null || echo "0")

    if [ "$RECORD_COUNT" -eq "0" ]; then
        # Create new record
        RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$NAME\",\"content\":\"$IP\",\"ttl\":300,\"proxied\":false}")

        log_message "INFO" "Created new DNS record for $NAME"
    else
        # Update existing record
        RECORD_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['result'][0]['id'])")

        RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$NAME\",\"content\":\"$IP\",\"ttl\":300,\"proxied\":false}")

        log_message "INFO" "Updated existing DNS record for $NAME"
    fi

    # Check for success
    SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('success', False))" 2>/dev/null || echo "false")
    if [ "$SUCCESS" != "True" ]; then
        log_message "ERROR" "Failed to update $NAME: $RESPONSE"
        return 1
    fi

    return 0
}

# Main update function
perform_update() {
    # Get current public IP
    CURRENT_IP=$(get_public_ip)

    if [ -z "$CURRENT_IP" ]; then
        log_message "ERROR" "Could not determine public IP"
        return 1
    fi

    # Check if IP has changed
    if [ -f "$IP_CACHE_FILE" ]; then
        CACHED_IP=$(cat "$IP_CACHE_FILE" | tr -d '\n')
        if [ "$CURRENT_IP" = "$CACHED_IP" ]; then
            log_message "DEBUG" "IP unchanged: $CURRENT_IP"
            return 0
        fi
    fi

    log_message "INFO" "IP change detected: ${CACHED_IP:-none} → $CURRENT_IP"

    # Update all DNS records
    local UPDATE_SUCCESS=true

    for SUBDOMAIN in "$DOMAIN" "www.$DOMAIN" "api.$DOMAIN" "docs.$DOMAIN"; do
        if ! update_dns_record "$SUBDOMAIN" "$CURRENT_IP"; then
            UPDATE_SUCCESS=false
        fi
    done

    if [ "$UPDATE_SUCCESS" = true ]; then
        # Save new IP
        echo "$CURRENT_IP" > "$IP_CACHE_FILE"
        log_message "INFO" "All DNS records updated successfully"

        # Send notification (optional)
        if command -v notify-send &> /dev/null; then
            notify-send "Catalyst9 DDNS" "IP updated to $CURRENT_IP"
        fi
    else
        log_message "ERROR" "Some DNS updates failed"
        return 1
    fi

    return 0
}

# Parse command line arguments
MODE="daemon"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --once)
            MODE="once"
            ;;
        --interval)
            CHECK_INTERVAL="$2"
            shift
            ;;
        --help)
            echo "Catalyst9 Dynamic DNS Updater"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --once              Run once and exit"
            echo "  --interval SECONDS  Check interval (default: 300)"
            echo "  --help             Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  CF_API_TOKEN_FILE  Path to Cloudflare API token file"
            echo "  CF_ZONE_ID_FILE    Path to Cloudflare Zone ID file"
            echo "  CHECK_INTERVAL     Check interval in seconds"
            echo "  LOG_FILE          Path to log file"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Main execution
log_message "INFO" "Catalyst9 DDNS Updater starting (mode: $MODE, interval: ${CHECK_INTERVAL}s)"

if [ "$MODE" = "once" ]; then
    # Run once and exit
    perform_update
    exit $?
else
    # Run as daemon
    while true; do
        perform_update
        sleep "$CHECK_INTERVAL"
    done
fi