#!/bin/bash
# DuckDNS IP update script
# Usage: ./scripts/duckdns-update.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load environment variables
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

source .env

# Validate required variables
if [ -z "$DUCKDNS_DOMAIN" ]; then
    echo -e "${RED}Error: DUCKDNS_DOMAIN not set in .env${NC}"
    exit 1
fi

if [ -z "$DUCKDNS_TOKEN" ]; then
    echo -e "${RED}Error: DUCKDNS_TOKEN not set in .env${NC}"
    exit 1
fi

if [ -z "$OCI_INSTANCE_IP" ]; then
    echo -e "${RED}Error: OCI_INSTANCE_IP not set in .env${NC}"
    exit 1
fi

echo -e "${GREEN}Updating DuckDNS...${NC}"
echo -e "Domain: ${YELLOW}${DUCKDNS_DOMAIN}.duckdns.org${NC}"
echo -e "IP: ${YELLOW}${OCI_INSTANCE_IP}${NC}"

# Update DuckDNS
RESPONSE=$(curl -s "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=${OCI_INSTANCE_IP}")

if [ "$RESPONSE" = "OK" ]; then
    echo -e "${GREEN}✓ DuckDNS updated successfully!${NC}"
    exit 0
else
    echo -e "${RED}✗ DuckDNS update failed: $RESPONSE${NC}"
    exit 1
fi
