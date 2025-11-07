#!/bin/bash
# Weekly backup routine - Downloads Borg backups AND exports readable data
# Usage: ./scripts/weekly-backup.sh
# For cron: 0 22 * * 0 /path/to/scripts/weekly-backup.sh >> /tmp/nextcloud-backup.log 2>&1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Nextcloud Weekly Backup Routine         ║${NC}"
echo -e "${BLUE}║   $(date '+%Y-%m-%d %H:%M:%S')                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Change to project directory
cd "$PROJECT_DIR"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found in $PROJECT_DIR${NC}"
    exit 1
fi

# Step 1: Download Borg backups
echo -e "${YELLOW}[1/2] Downloading Borg backups from OCI...${NC}"
echo ""

if [ -f "$SCRIPT_DIR/download-backup.sh" ]; then
    bash "$SCRIPT_DIR/download-backup.sh"
    BACKUP_EXIT=$?

    if [ $BACKUP_EXIT -eq 0 ]; then
        echo -e "${GREEN}✓ Borg backup download completed${NC}"
    else
        echo -e "${RED}✗ Borg backup download failed!${NC}"
        echo -e "${YELLOW}Continuing with data export...${NC}"
    fi
else
    echo -e "${RED}Error: download-backup.sh not found${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}──────────────────────────────────────────${NC}"
echo ""

# Step 2: Export readable data
echo -e "${YELLOW}[2/2] Exporting readable data (calendars, contacts)...${NC}"
echo ""

if [ -f "$SCRIPT_DIR/export-data.sh" ]; then
    bash "$SCRIPT_DIR/export-data.sh"
    EXPORT_EXIT=$?

    if [ $EXPORT_EXIT -eq 0 ]; then
        echo -e "${GREEN}✓ Data export completed${NC}"
    else
        echo -e "${RED}✗ Data export failed!${NC}"
    fi
else
    echo -e "${RED}Error: export-data.sh not found${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Weekly Backup Routine Complete!         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Summary
echo -e "${GREEN}Summary:${NC}"
echo -e "  Borg backups: ${HOME}/nextcloud-backups/"
echo -e "  Data exports: ${HOME}/nextcloud-exports/"
echo -e "  Latest export: ${HOME}/nextcloud-exports/latest"
echo ""

# Disk usage
echo -e "${BLUE}Disk usage:${NC}"
if [ -d "${HOME}/nextcloud-backups" ]; then
    BACKUP_SIZE=$(du -sh "${HOME}/nextcloud-backups" 2>/dev/null | cut -f1 || echo "N/A")
    echo -e "  Backups: ${YELLOW}${BACKUP_SIZE}${NC}"
fi

if [ -d "${HOME}/nextcloud-exports" ]; then
    EXPORT_SIZE=$(du -sh "${HOME}/nextcloud-exports" 2>/dev/null | cut -f1 || echo "N/A")
    echo -e "  Exports: ${YELLOW}${EXPORT_SIZE}${NC}"
fi

echo ""
echo -e "${GREEN}✓ All done!${NC}"
echo ""
