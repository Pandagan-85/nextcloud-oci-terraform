#!/bin/bash
# Deploy Nextcloud AIO to OCI instance
# Usage: ./scripts/deploy-nextcloud.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Nextcloud AIO Deployment ===${NC}"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Load environment variables
source .env

# Validate required variables
if [ -z "$OCI_INSTANCE_IP" ] || [ "$OCI_INSTANCE_IP" = "YOUR_PUBLIC_IP_HERE" ]; then
    echo -e "${RED}Error: OCI_INSTANCE_IP not set in .env${NC}"
    exit 1
fi

if [ -z "$OCI_SSH_KEY_PATH" ]; then
    echo -e "${RED}Error: OCI_SSH_KEY_PATH not set in .env${NC}"
    exit 1
fi

# Expand tilde in path
SSH_KEY_PATH="${OCI_SSH_KEY_PATH/#\~/$HOME}"

# Check docker-compose.yml exists
if [ ! -f docker/docker-compose.yml ]; then
    echo -e "${RED}Error: docker/docker-compose.yml not found${NC}"
    exit 1
fi

echo -e "${GREEN}Step 1: Copying docker-compose.yml to instance...${NC}"
scp -i "$SSH_KEY_PATH" docker/docker-compose.yml "${OCI_SSH_USER}@${OCI_INSTANCE_IP}:/home/${OCI_SSH_USER}/"

echo -e "${GREEN}Step 2: Setting up Nextcloud directory...${NC}"
ssh -i "$SSH_KEY_PATH" "${OCI_SSH_USER}@${OCI_INSTANCE_IP}" << 'EOF'
    # Create directory
    mkdir -p ~/nextcloud

    # Move docker-compose.yml
    mv ~/docker-compose.yml ~/nextcloud/

    # Create data directory
    sudo mkdir -p /opt/nextcloud
    sudo chown -R $(whoami):$(whoami) /opt/nextcloud

    echo "Directory setup complete"
EOF

echo ""
echo -e "${GREEN}Step 3: Starting Nextcloud AIO...${NC}"
ssh -i "$SSH_KEY_PATH" "${OCI_SSH_USER}@${OCI_INSTANCE_IP}" << 'EOF'
    cd ~/nextcloud

    # Pull latest image
    docker compose pull

    # Start containers
    docker compose up -d

    echo ""
    echo "Waiting for container to initialize (30 seconds)..."
    sleep 30

    # Show status
    docker compose ps
EOF

echo ""
echo -e "${GREEN}Step 4: Retrieving AIO admin password...${NC}"
ssh -i "$SSH_KEY_PATH" "${OCI_SSH_USER}@${OCI_INSTANCE_IP}" << 'EOF'
    echo ""
    echo "Waiting for configuration file..."
    for i in {1..10}; do
        if docker exec nextcloud-aio-mastercontainer test -f /mnt/docker-aio-config/data/configuration.json 2>/dev/null; then
            echo "Configuration ready!"
            PASSWORD=$(docker exec nextcloud-aio-mastercontainer grep -oP '"password":\s*"\K[^"]+' /mnt/docker-aio-config/data/configuration.json 2>/dev/null || echo "")
            if [ -n "$PASSWORD" ]; then
                echo ""
                echo "================================================"
                echo "AIO ADMIN PASSWORD: $PASSWORD"
                echo "================================================"
                echo ""
                echo "SAVE THIS PASSWORD!"
            else
                echo "Password not yet generated, check logs with:"
                echo "  docker compose logs nextcloud-aio-mastercontainer"
            fi
            break
        fi
        echo "Waiting... ($i/10)"
        sleep 3
    done
EOF

echo ""
echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Access AIO interface:"
echo -e "   ${BLUE}https://${DUCKDNS_DOMAIN}.duckdns.org:8443${NC}"
echo ""
echo "2. Login with the password shown above"
echo ""
echo "3. Configure your domain:"
echo -e "   ${BLUE}${DUCKDNS_DOMAIN}.duckdns.org${NC}"
echo ""
echo "4. Enable Let's Encrypt SSL"
echo ""
echo "5. Select optional components (Talk, Office, etc.)"
echo ""
echo "6. Start containers and wait for deployment"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "- Make sure OCI Security Lists allow ports 80, 443, 8080"
echo "- First access will show SSL warning (self-signed cert)"
echo "- Full deployment takes 10-15 minutes"
echo ""
echo -e "For troubleshooting, see: ${BLUE}docs/05-NEXTCLOUD-DEPLOYMENT.md${NC}"
echo ""
