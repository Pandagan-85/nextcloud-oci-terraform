#!/bin/bash
# Create a manual backup on OCI instance
# Usage: ./scripts/create-backup.sh [--download]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Nextcloud Manual Backup ===${NC}"
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

# Check for --download flag
DOWNLOAD_AFTER=false
if [ "$1" = "--download" ]; then
    DOWNLOAD_AFTER=true
fi

echo -e "${GREEN}Configuration:${NC}"
echo -e "Server: ${YELLOW}${OCI_SSH_USER}@${OCI_INSTANCE_IP}${NC}"
echo -e "Download after: ${YELLOW}${DOWNLOAD_AFTER}${NC}"
echo ""

# Confirm backup creation
echo -e "${YELLOW}This will create a new backup on the OCI instance.${NC}"
echo -e "${YELLOW}The backup process may take several minutes.${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting backup creation on server...${NC}"
echo ""

# Create backup on remote server
ssh -i "$SSH_KEY_PATH" "${OCI_SSH_USER}@${OCI_INSTANCE_IP}" << 'ENDSSH'
echo "=== Triggering Nextcloud AIO Backup ==="
echo ""

# Check if mastercontainer is running
if ! sudo docker ps | grep -q nextcloud-aio-mastercontainer; then
    echo "Error: nextcloud-aio-mastercontainer is not running"
    exit 1
fi

echo "Starting backup process..."
echo ""

# Trigger backup
sudo docker exec --env DAILY_BACKUP=1 nextcloud-aio-mastercontainer /daily-backup.sh

echo ""
echo "=== Backup command executed ==="
echo ""
echo "Note: The backup runs in background."
echo "Check progress with: sudo docker logs -f nextcloud-aio-borgbackup"
echo ""

# Wait a moment for backup to start
sleep 5

# Show initial backup logs
echo "=== Initial backup logs ==="
sudo docker logs --tail 50 nextcloud-aio-borgbackup 2>/dev/null || echo "Backup container not yet started"
echo ""

ENDSSH

SSH_EXIT=$?

if [ $SSH_EXIT -eq 0 ]; then
    echo -e "${GREEN}✓ Backup process started successfully!${NC}"
    echo ""

    echo -e "${BLUE}Monitor backup progress:${NC}"
    echo -e "  ssh -i ${SSH_KEY_PATH} ${OCI_SSH_USER}@${OCI_INSTANCE_IP}"
    echo -e "  sudo docker logs -f nextcloud-aio-borgbackup"
    echo ""

    echo -e "${YELLOW}Note:${NC} The backup runs asynchronously and may take 5-15 minutes."
    echo -e "${YELLOW}Wait for it to complete before downloading.${NC}"
    echo ""

    # Ask if user wants to wait and download
    if [ "$DOWNLOAD_AFTER" = true ]; then
        echo -e "${BLUE}Waiting for backup to complete...${NC}"
        echo -e "${YELLOW}This may take several minutes. Press Ctrl+C to cancel.${NC}"
        echo ""

        # Wait for backup to complete (check every 30 seconds)
        TIMEOUT=1200  # 20 minutes timeout
        ELAPSED=0
        INTERVAL=30

        while [ $ELAPSED -lt $TIMEOUT ]; do
            # Check if backup is still running
            BACKUP_STATUS=$(ssh -i "$SSH_KEY_PATH" "${OCI_SSH_USER}@${OCI_INSTANCE_IP}" \
                "sudo docker ps --filter 'name=nextcloud-aio-borgbackup' --format '{{.Status}}'" 2>/dev/null || echo "")

            if [ -z "$BACKUP_STATUS" ]; then
                echo -e "${GREEN}✓ Backup container finished!${NC}"
                echo ""

                # Show final logs
                echo -e "${BLUE}Final backup logs:${NC}"
                ssh -i "$SSH_KEY_PATH" "${OCI_SSH_USER}@${OCI_INSTANCE_IP}" \
                    "sudo docker logs --tail 20 nextcloud-aio-borgbackup"
                echo ""

                # Check and restart containers if needed
                echo -e "${BLUE}Checking Nextcloud containers status...${NC}"
                sleep 10  # Give time for AIO to restart containers

                CONTAINERS_STATUS=$(ssh -i "$SSH_KEY_PATH" "${OCI_SSH_USER}@${OCI_INSTANCE_IP}" \
                    "sudo docker ps --filter 'name=nextcloud-aio-apache' --format '{{.Status}}'" 2>/dev/null || echo "")

                if [ -z "$CONTAINERS_STATUS" ]; then
                    echo -e "${YELLOW}⚠ Containers not running. Restarting...${NC}"
                    ssh -i "$SSH_KEY_PATH" "${OCI_SSH_USER}@${OCI_INSTANCE_IP}" << 'RESTART_SSH'
echo "Restarting Nextcloud containers..."
sudo docker start nextcloud-aio-apache nextcloud-aio-nextcloud nextcloud-aio-database nextcloud-aio-redis nextcloud-aio-imaginary nextcloud-aio-collabora nextcloud-aio-notify-push 2>/dev/null
sleep 5
echo "Container status:"
sudo docker ps --filter 'name=nextcloud-aio' --format 'table {{.Names}}\t{{.Status}}'
RESTART_SSH
                    echo -e "${GREEN}✓ Containers restarted${NC}"
                else
                    echo -e "${GREEN}✓ Containers are running${NC}"
                fi
                echo ""

                # Download backup
                echo -e "${GREEN}Starting backup download...${NC}"
                echo ""

                SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                bash "$SCRIPT_DIR/download-backup.sh"

                break
            fi

            echo -e "${YELLOW}Backup still running... (${ELAPSED}s elapsed)${NC}"
            sleep $INTERVAL
            ELAPSED=$((ELAPSED + INTERVAL))
        done

        if [ $ELAPSED -ge $TIMEOUT ]; then
            echo -e "${RED}Timeout waiting for backup to complete${NC}"
            echo -e "${YELLOW}The backup may still be running. Check manually.${NC}"
        fi
    else
        echo -e "${BLUE}To download the backup when ready:${NC}"
        echo -e "  ./scripts/download-backup.sh"
        echo ""

        echo -e "${YELLOW}IMPORTANT:${NC} After backup completes (5-15 min), verify containers restarted:"
        echo -e "  ssh -i ${SSH_KEY_PATH} ${OCI_SSH_USER}@${OCI_INSTANCE_IP}"
        echo -e "  sudo docker ps | grep nextcloud-aio"
        echo ""
        echo -e "If containers are not running, restart them with:"
        echo -e "  sudo docker start nextcloud-aio-apache nextcloud-aio-nextcloud nextcloud-aio-database nextcloud-aio-redis"
        echo ""
    fi
else
    echo -e "${RED}✗ Failed to create backup!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}=== Backup Creation Complete ===${NC}"
echo ""
