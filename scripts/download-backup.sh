#!/bin/bash
# Download Nextcloud backups from OCI to local machine
# Usage: ./scripts/download-backup.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Nextcloud Backup Download ===${NC}"
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

# Default backup directory on local machine
LOCAL_BACKUP_DIR="${HOME}/nextcloud-backups"
REMOTE_BACKUP_DIR="/mnt/nextcloud-data/borg-backups"

# Create local backup directory
mkdir -p "$LOCAL_BACKUP_DIR"

echo -e "${GREEN}Configuration:${NC}"
echo -e "Remote: ${YELLOW}${OCI_SSH_USER}@${OCI_INSTANCE_IP}:${REMOTE_BACKUP_DIR}${NC}"
echo -e "Local: ${YELLOW}${LOCAL_BACKUP_DIR}${NC}"
echo ""

# Check available space locally
echo -e "${BLUE}Checking local disk space...${NC}"
AVAILABLE_SPACE=$(df -BG "$LOCAL_BACKUP_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
echo -e "Available space: ${GREEN}${AVAILABLE_SPACE}GB${NC}"

# Check remote backup size
echo -e "${BLUE}Checking remote backup size...${NC}"
REMOTE_SIZE=$(ssh -i "$SSH_KEY_PATH" "${OCI_SSH_USER}@${OCI_INSTANCE_IP}" \
    "sudo du -sh ${REMOTE_BACKUP_DIR} 2>/dev/null | cut -f1" || echo "Unknown")
echo -e "Remote backup size: ${YELLOW}${REMOTE_SIZE}${NC}"
echo ""

# Warning if low space
if [ "$AVAILABLE_SPACE" -lt 5 ]; then
    echo -e "${YELLOW}Warning: Low disk space! Consider freeing up space.${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Confirm download
echo -e "${YELLOW}This will download all backups from the OCI instance.${NC}"
echo -e "${YELLOW}Existing files will be preserved (rsync).${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting backup download...${NC}"
echo ""

# Use rsync to download backups
# -a: archive mode (preserves permissions, timestamps, etc.)
# -v: verbose
# -z: compress during transfer
# -h: human-readable
# --progress: show progress
# --stats: show statistics at the end

rsync -avzh --progress --stats \
    -e "ssh -i ${SSH_KEY_PATH}" \
    --rsync-path="sudo rsync" \
    "${OCI_SSH_USER}@${OCI_INSTANCE_IP}:${REMOTE_BACKUP_DIR}/" \
    "${LOCAL_BACKUP_DIR}/"

RSYNC_EXIT=$?

echo ""

if [ $RSYNC_EXIT -eq 0 ]; then
    echo -e "${GREEN}✓ Backup download completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Backup location:${NC} ${LOCAL_BACKUP_DIR}"
    echo ""

    # Show local backup size
    LOCAL_SIZE=$(du -sh "$LOCAL_BACKUP_DIR" | cut -f1)
    echo -e "${GREEN}Local backup size:${NC} ${LOCAL_SIZE}"

    # List backup archives
    echo ""
    echo -e "${BLUE}Backup archives:${NC}"
    ls -lh "$LOCAL_BACKUP_DIR" 2>/dev/null || echo "No files visible (encrypted)"

    echo ""
    echo -e "${YELLOW}Note:${NC} Backups are encrypted with Borg."
    echo -e "To restore, you'll need:"
    echo -e "  1. The backup password (saved in your password manager)"
    echo -e "  2. Borg installed: ${BLUE}sudo apt install borgbackup${NC}"

    # Create info file
    cat > "${LOCAL_BACKUP_DIR}/BACKUP_INFO.txt" <<EOF
Nextcloud Backup Information
============================
Downloaded from: ${OCI_INSTANCE_IP}
Downloaded on: $(date)
Remote path: ${REMOTE_BACKUP_DIR}
Local path: ${LOCAL_BACKUP_DIR}

Backup Details:
- Tool: BorgBackup
- Encryption: Yes (password required)
- Compression: Yes

To list backups:
  borg list ${LOCAL_BACKUP_DIR}

To restore:
  See: docs/BACKUP_RESTORE.md

Password location:
  - In your password manager
  - In .env file (NEXTCLOUD_BACKUP_PASSWORD)

KEEP THIS INFORMATION SAFE!
EOF

    echo ""
    echo -e "${GREEN}✓ Created ${LOCAL_BACKUP_DIR}/BACKUP_INFO.txt${NC}"

else
    echo -e "${RED}✗ Backup download failed!${NC}"
    echo -e "Exit code: $RSYNC_EXIT"
    exit 1
fi

echo ""
echo -e "${BLUE}=== Download Complete ===${NC}"
echo ""
