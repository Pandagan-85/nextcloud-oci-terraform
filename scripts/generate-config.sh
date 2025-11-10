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
source <(grep -E '^[A-Z_]+=.*' .env)
set +a

# Validate required variables
if [ -z "$DUCKDNS_DOMAIN" ]; then
    echo -e "${RED}Error: DUCKDNS_DOMAIN not set in .env${NC}"
    exit 1
fi

# Generate Caddyfile
echo -e "${GREEN}Generating Caddyfile...${NC}"
cat > docker/Caddyfile << EOF
# ==============================================================================
# Caddyfile - Nextcloud AIO Reverse Proxy Configuration
# ==============================================================================
# Auto-generated from .env configuration
# Domain: ${DUCKDNS_DOMAIN}.duckdns.org
# ==============================================================================

${DUCKDNS_DOMAIN}.duckdns.org {
    # Reverse proxy to Nextcloud AIO Apache
    reverse_proxy nextcloud-aio-apache:11000

    # Security headers
    header {
        # Enable HSTS
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

        # Prevent clickjacking
        X-Frame-Options "SAMEORIGIN"

        # Prevent MIME-type sniffing
        X-Content-Type-Options "nosniff"

        # XSS protection
        X-XSS-Protection "1; mode=block"

        # Referrer policy
        Referrer-Policy "no-referrer"
    }

    # Enable compression
    encode gzip

    # Logs
    log {
        output file /data/access.log
        level INFO
    }
}
EOF

echo -e "${GREEN}✓ Caddyfile generated successfully${NC}"
echo -e "  Location: ${BLUE}docker/Caddyfile${NC}"
echo -e "  Domain: ${BLUE}${DUCKDNS_DOMAIN}.duckdns.org${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} This file will be uploaded to your server during deployment"
echo ""
