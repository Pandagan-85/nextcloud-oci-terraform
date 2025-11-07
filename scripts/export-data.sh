#!/bin/bash
# Export Nextcloud data in readable format (calendars, contacts, files)
# Usage: ./scripts/export-data.sh

# Removed set -e to prevent premature exit on calendar download errors
set -u  # Exit on undefined variables only

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Nextcloud Data Export ===${NC}"
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

if [ -z "$DUCKDNS_DOMAIN" ]; then
    echo -e "${RED}Error: DUCKDNS_DOMAIN not set in .env${NC}"
    exit 1
fi

# Configuration
NEXTCLOUD_URL="https://${DUCKDNS_DOMAIN}.duckdns.org"
LOCAL_EXPORT_DIR="${HOME}/nextcloud-exports"
DATE=$(date +%Y%m%d_%H%M%S)
EXPORT_DIR="${LOCAL_EXPORT_DIR}/${DATE}"

# Nextcloud credentials (from .env or prompt)
NEXTCLOUD_USER="${NEXTCLOUD_ADMIN_USER:-pandagan_admin}"

# Check if password is in .env, otherwise prompt
if [ -z "$NEXTCLOUD_ADMIN_PASSWORD" ]; then
    echo -e "${YELLOW}Nextcloud password not found in .env${NC}"
    read -sp "Enter Nextcloud password: " NEXTCLOUD_PASSWORD
    echo ""
else
    NEXTCLOUD_PASSWORD="$NEXTCLOUD_ADMIN_PASSWORD"
fi

# Create export directory
mkdir -p "$EXPORT_DIR"/{calendars,contacts,files}

echo -e "${GREEN}Configuration:${NC}"
echo -e "Nextcloud URL: ${YELLOW}${NEXTCLOUD_URL}${NC}"
echo -e "User: ${YELLOW}${NEXTCLOUD_USER}${NC}"
echo -e "Export to: ${YELLOW}${EXPORT_DIR}${NC}"
echo ""

# Test connection
echo -e "${BLUE}Testing connection to Nextcloud...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "${NEXTCLOUD_USER}:${NEXTCLOUD_PASSWORD}" \
    "${NEXTCLOUD_URL}/remote.php/dav/files/${NEXTCLOUD_USER}/")

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "207" ]; then
    echo -e "${RED}✗ Connection failed! HTTP code: ${HTTP_CODE}${NC}"
    echo -e "${YELLOW}Check username/password and Nextcloud URL${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Connection successful${NC}"
echo ""

# Export Calendars
echo -e "${BLUE}Exporting calendars...${NC}"

# Get list of calendars via CalDAV - save to array
mapfile -t CALENDAR_URLS < <(curl -s -X PROPFIND -u "${NEXTCLOUD_USER}:${NEXTCLOUD_PASSWORD}" \
    -H "Depth: 1" \
    "${NEXTCLOUD_URL}/remote.php/dav/calendars/${NEXTCLOUD_USER}/" \
    | grep -oP '(?<=<d:href>)/remote.php/dav/calendars/[^<]+')

if [ ${#CALENDAR_URLS[@]} -eq 0 ]; then
    echo -e "${YELLOW}No calendars found${NC}"
else
    CALENDAR_COUNT=0
    for cal_url in "${CALENDAR_URLS[@]}"; do
        if [[ "$cal_url" == *"/"* ]] && [[ "$cal_url" != *"${NEXTCLOUD_USER}/" ]]; then
            CAL_NAME=$(basename "$cal_url")

            # Skip system calendars
            if [[ "$CAL_NAME" == "inbox" ]] || [[ "$CAL_NAME" == "outbox" ]] || [[ "$CAL_NAME" == "trashbin" ]] || [[ "$CAL_NAME" == "contact_birthdays" ]] || [[ "$CAL_NAME" == "inbox-1" ]]; then
                continue
            fi

            echo -e "  Downloading: ${YELLOW}${CAL_NAME}${NC}"

            # Export calendar as ICS
            curl -s -u "${NEXTCLOUD_USER}:${NEXTCLOUD_PASSWORD}" \
                "${NEXTCLOUD_URL}${cal_url}?export" \
                -o "${EXPORT_DIR}/calendars/${CAL_NAME}.ics" || echo "    Warning: Failed to download ${CAL_NAME}"

            ((CALENDAR_COUNT++))
        fi
    done

    echo -e "${GREEN}✓ Exported ${CALENDAR_COUNT} calendars${NC}"
fi
echo ""

# Export Contacts
echo -e "${BLUE}Exporting contacts...${NC}"

# Get default addressbook
CONTACTS_URL="${NEXTCLOUD_URL}/remote.php/dav/addressbooks/users/${NEXTCLOUD_USER}/contacts/"

CONTACTS_VCF=$(curl -s -u "${NEXTCLOUD_USER}:${NEXTCLOUD_PASSWORD}" \
    -H "Depth: 1" \
    -X PROPFIND \
    "$CONTACTS_URL" \
    | grep -oP '(?<=<d:href>).*?\.vcf(?=</d:href>)' || echo "")

if [ -z "$CONTACTS_VCF" ]; then
    echo -e "${YELLOW}No contacts found${NC}"
else
    CONTACT_COUNT=0

    # Export all contacts in one VCF file
    echo "" > "${EXPORT_DIR}/contacts/all-contacts.vcf"

    while IFS= read -r vcf_path; do
        if [ -n "$vcf_path" ]; then
            curl -s -u "${NEXTCLOUD_USER}:${NEXTCLOUD_PASSWORD}" \
                "${NEXTCLOUD_URL}${vcf_path}" \
                >> "${EXPORT_DIR}/contacts/all-contacts.vcf" < /dev/null
            ((CONTACT_COUNT++))
        fi
    done <<< "$CONTACTS_VCF"

    echo -e "${GREEN}✓ Exported ${CONTACT_COUNT} contacts${NC}"
fi
echo ""

# Export Files (top-level only, to avoid huge downloads)
echo -e "${BLUE}Exporting files (top-level directory list)...${NC}"

# List files using WebDAV
FILES_LIST=$(curl -s -X PROPFIND -u "${NEXTCLOUD_USER}:${NEXTCLOUD_PASSWORD}" \
    -H "Depth: 1" \
    "${NEXTCLOUD_URL}/remote.php/dav/files/${NEXTCLOUD_USER}/" \
    | grep -oP '(?<=<d:href>)/remote.php/dav/files/[^<]+' || echo "")

# Save file list
echo "$FILES_LIST" > "${EXPORT_DIR}/files/file-list.txt"
echo -e "${YELLOW}Note: File list saved. To download files, use WebDAV or Nextcloud desktop client${NC}"
echo -e "${GREEN}✓ File list exported${NC}"
echo ""

# Create README
cat > "${EXPORT_DIR}/README.md" <<EOF
# Nextcloud Export - ${DATE}

Export eseguito: $(date)
Nextcloud URL: ${NEXTCLOUD_URL}
User: ${NEXTCLOUD_USER}

## Contenuto

### Calendari (calendars/)
File .ics pronti per import in:
- Google Calendar
- Apple Calendar
- Outlook
- Qualsiasi app compatibile CalDAV

### Contatti (contacts/)
File .vcf (vCard) pronto per import in:
- Google Contacts
- Apple Contacts
- Outlook
- Qualsiasi app compatibile CardDAV

### Files (files/)
Lista file disponibili su Nextcloud.

Per scaricare file:
- Via Web: ${NEXTCLOUD_URL}
- Via WebDAV: ${NEXTCLOUD_URL}/remote.php/dav/files/${NEXTCLOUD_USER}/
- Via Desktop Client: https://nextcloud.com/install/#install-clients

## Backup vs Export

Questo è un EXPORT (dati leggibili).
Per BACKUP completo sistema → vedi ~/nextcloud-backups/ (Borg)

EOF

# Summary
echo -e "${GREEN}=== Export Complete ===${NC}"
echo ""
echo -e "${BLUE}Export location:${NC} ${EXPORT_DIR}"
echo ""
echo -e "${GREEN}Exported:${NC}"
ls -lh "$EXPORT_DIR"
echo ""
echo -e "${BLUE}Directories:${NC}"
find "$EXPORT_DIR" -type d -exec echo "  {}" \;
echo ""
echo -e "${YELLOW}Tip:${NC} Import .ics files in any calendar app!"
echo -e "${YELLOW}Tip:${NC} Import .vcf file in any contacts app!"
echo ""

# Create latest symlink
ln -sfn "$EXPORT_DIR" "${LOCAL_EXPORT_DIR}/latest"
echo -e "${GREEN}✓ Created symlink: ${LOCAL_EXPORT_DIR}/latest → ${EXPORT_DIR}${NC}"
echo ""
