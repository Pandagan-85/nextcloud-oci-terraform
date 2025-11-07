#!/bin/bash
# Setup cron job for weekly Nextcloud backups
# Usage: ./scripts/setup-cron.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Nextcloud Backup Cron Setup ===${NC}"
echo ""

# Get absolute path to project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WEEKLY_BACKUP_SCRIPT="${PROJECT_DIR}/scripts/weekly-backup.sh"

# Verify script exists
if [ ! -f "$WEEKLY_BACKUP_SCRIPT" ]; then
    echo -e "${RED}Error: weekly-backup.sh not found at ${WEEKLY_BACKUP_SCRIPT}${NC}"
    exit 1
fi

# Verify script is executable
if [ ! -x "$WEEKLY_BACKUP_SCRIPT" ]; then
    echo -e "${YELLOW}Making weekly-backup.sh executable...${NC}"
    chmod +x "$WEEKLY_BACKUP_SCRIPT"
fi

echo -e "${GREEN}Configuration:${NC}"
echo -e "Script: ${YELLOW}${WEEKLY_BACKUP_SCRIPT}${NC}"
echo -e "Schedule: ${YELLOW}Every Sunday at 22:00 (10 PM)${NC}"
echo -e "Log file: ${YELLOW}/tmp/nextcloud-backup.log${NC}"
echo ""

# Create cron entry
CRON_ENTRY="0 22 * * 0 ${WEEKLY_BACKUP_SCRIPT} >> /tmp/nextcloud-backup.log 2>&1"

# Check if cron entry already exists
if crontab -l 2>/dev/null | grep -q "$WEEKLY_BACKUP_SCRIPT"; then
    echo -e "${YELLOW}Cron job already exists!${NC}"
    echo ""
    echo -e "${BLUE}Current crontab:${NC}"
    crontab -l | grep "$WEEKLY_BACKUP_SCRIPT" || true
    echo ""
    read -p "Do you want to update it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    # Remove old entry
    crontab -l | grep -v "$WEEKLY_BACKUP_SCRIPT" | crontab -
    echo -e "${GREEN}✓ Removed old cron entry${NC}"
fi

# Add new cron entry
(crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -

echo -e "${GREEN}✓ Cron job added successfully!${NC}"
echo ""

# Show current crontab
echo -e "${BLUE}Current crontab:${NC}"
crontab -l
echo ""

# Verify cron service is running
if systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null; then
    echo -e "${GREEN}✓ Cron service is running${NC}"
else
    echo -e "${YELLOW}Warning: Cron service may not be running${NC}"
    echo -e "Start it with: ${BLUE}sudo systemctl start cron${NC}"
fi

echo ""
echo -e "${BLUE}=== Setup Complete ===${NC}"
echo ""
echo -e "${GREEN}Next backup:${NC} Sunday at 22:00"
echo -e "${GREEN}Log file:${NC} /tmp/nextcloud-backup.log"
echo ""
echo -e "${YELLOW}Tip:${NC} To test the backup manually, run:"
echo -e "  ${BLUE}${WEEKLY_BACKUP_SCRIPT}${NC}"
echo ""
echo -e "${YELLOW}Tip:${NC} To view the log:"
echo -e "  ${BLUE}tail -f /tmp/nextcloud-backup.log${NC}"
echo ""
