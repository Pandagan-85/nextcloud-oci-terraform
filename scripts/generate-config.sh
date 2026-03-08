#!/bin/bash
# Generate configuration files from .env template
# Usage: ./scripts/generate-config.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Generating Configuration Files ===${NC}"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please create .env file first"
    exit 1
fi

# Load environment variables (only lines with = and not comments)
set -a
# shellcheck disable=SC1090
source <(grep -E '^[A-Z_]+=.*' .env)
set +a

# Validate required variables
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: DOMAIN not set in .env${NC}"
    exit 1
fi

KOMGA_SUBDOMAIN="${KOMGA_SUBDOMAIN:-manga}"

# Generate Caddyfile
echo -e "${GREEN}Generating Caddyfile...${NC}"
sed -e "s/{\\\$DOMAIN}/${DOMAIN}/g" \
    -e "s/{\\\$KOMGA_SUBDOMAIN}/${KOMGA_SUBDOMAIN}/g" \
    docker/Caddyfile > docker/Caddyfile.generated

echo -e "${GREEN}✓ Caddyfile generated successfully${NC}"
echo -e "  Location: ${BLUE}docker/Caddyfile.generated${NC}"
echo -e "  Main domain: ${BLUE}${DOMAIN}${NC}"
echo -e "  Komga: ${BLUE}${KOMGA_SUBDOMAIN}.${DOMAIN}${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  1. Create DNS A records pointing to your server IP:"
echo "     - ${DOMAIN}"
echo "     - ${KOMGA_SUBDOMAIN}.${DOMAIN}"
echo "  2. Set GRAFANA_ADMIN_PASSWORD in .env before deployment"
echo ""
