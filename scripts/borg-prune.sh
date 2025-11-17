#!/bin/bash
# ==============================================================================
# Borg Backup Pruning Script
# ==============================================================================
# Mantiene: 7 daily, 4 weekly, 6 monthly backups
# Eseguito automaticamente via cronjob ogni lunedì alle 06:00
# ==============================================================================

# Carica variabili d'ambiente (inclusa BORG_PASSPHRASE)
ENV_FILE="/home/ubuntu/nextcloud/.env"
if [ -f "$ENV_FILE" ]; then
    # shellcheck source=/dev/null
    source "$ENV_FILE"
else
    echo "ERROR: $ENV_FILE not found!" >> /var/log/borg-prune.log
    exit 1
fi

# Repository e log
BORG_REPO="/mnt/nextcloud-data/borg-backups/borg"
LOG_FILE="/var/log/borg-prune.log"

# Log inizio operazione
echo "=== Borg Pruning started at $(date) ===" >> "$LOG_FILE"

# Pruning: mantieni 7 daily, 4 weekly, 6 monthly
borg prune "$BORG_REPO" \
  --keep-daily=7 \
  --keep-weekly=4 \
  --keep-monthly=6 \
  --list --stats >> "$LOG_FILE" 2>&1

# Compatta repository per recuperare spazio
borg compact "$BORG_REPO" >> "$LOG_FILE" 2>&1

# Log fine operazione
echo "=== Borg Pruning completed at $(date) ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
