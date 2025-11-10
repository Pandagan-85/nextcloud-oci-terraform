#!/bin/bash
# SSH connection script for OCI instance
# Usage: ./scripts/ssh-connect.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo -e "${YELLOW}Please create .env from .env.example:${NC}"
    echo "  cp .env.example .env"
    echo "  # Then edit .env with your actual values"
    exit 1
fi

# Load environment variables
source .env

# Validate required variables
if [ -z "$OCI_INSTANCE_IP" ] || [ "$OCI_INSTANCE_IP" = "YOUR_PUBLIC_IP_HERE" ]; then
    echo -e "${RED}Error: OCI_INSTANCE_IP not set in .env${NC}"
    exit 1
fi

if [ -z "$OCI_SSH_KEY_PATH" ] || [ "$OCI_SSH_KEY_PATH" = "$HOME/.ssh/YOUR_KEY_NAME" ]; then
    echo -e "${RED}Error: OCI_SSH_KEY_PATH not set in .env${NC}"
    exit 1
fi

# Expand tilde in path
SSH_KEY_PATH="${OCI_SSH_KEY_PATH/#\~/$HOME}"

# Check if key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}Error: SSH key not found at $SSH_KEY_PATH${NC}"
    exit 1
fi

# Check key permissions
KEY_PERMS=$(stat -c %a "$SSH_KEY_PATH" 2>/dev/null || stat -f %A "$SSH_KEY_PATH" 2>/dev/null)
if [ "$KEY_PERMS" != "600" ] && [ "$KEY_PERMS" != "400" ]; then
    echo -e "${YELLOW}Warning: SSH key has incorrect permissions ($KEY_PERMS)${NC}"
    echo -e "${YELLOW}Fixing permissions to 600...${NC}"
    chmod 600 "$SSH_KEY_PATH"
fi

echo -e "${GREEN}Connecting to OCI instance...${NC}"
echo -e "IP: ${YELLOW}$OCI_INSTANCE_IP${NC}"
echo -e "User: ${YELLOW}$OCI_SSH_USER${NC}"
echo ""

# Connect
ssh -i "$SSH_KEY_PATH" "${OCI_SSH_USER}@${OCI_INSTANCE_IP}"
