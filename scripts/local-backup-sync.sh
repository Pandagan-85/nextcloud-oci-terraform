#!/bin/bash
# ==============================================================================
# Nextcloud Backup Manager - Download ed Estrazione Backup Borg
# ==============================================================================
# Uso: ./nextcloud-backup-manager.sh [opzioni]
#
# Opzioni:
#   --sync-only     Solo sincronizza backup (no estrazione)
#   --extract-only  Solo estrai ultimo backup (no sync)
#   --help          Mostra questo help
#
# Senza opzioni: Esegue entrambi (sync + chiede se estrarre)
# ==============================================================================

set -e  # Exit on error

# ==============================================================================
# CONFIGURAZIONE - Modifica questi valori
# ==============================================================================

SERVER_USER="ubuntu"
SERVER_IP="<your-server-ip>"  # Replace with your OCI instance public IP
REMOTE_PATH="/mnt/nextcloud-data/borg-backups/"
LOCAL_BACKUP_DIR="$HOME/nextcloud-backup-local"
RESTORE_DIR="$HOME/restore-nextcloud"
LOG_FILE="$HOME/nextcloud-backup.log"

# Password Borg (se configurata in .bashrc non serve)
# export BORG_PASSPHRASE="your-password-here"

# ==============================================================================
# COLORI
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==============================================================================
# FUNZIONI
# ==============================================================================

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}Nextcloud Backup Manager${NC}                                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $1" >> "$LOG_FILE"
}

check_borg_installed() {
    if ! command -v borg &> /dev/null; then
        log_error "Borg non installato!"
        echo ""
        echo "Installa con: sudo dnf install borgbackup"
        exit 1
    fi
}

check_borg_password() {
    if [ -z "$BORG_PASSPHRASE" ]; then
        log_warning "BORG_PASSPHRASE non configurata!"
        echo ""
        echo "Configura la password nel file ~/.bashrc:"
        echo "export BORG_PASSPHRASE=\"your-borg-password\""
        echo ""
        read -p "Premi ENTER per continuare (ti verrà chiesta la password) o CTRL+C per uscire..."
    fi
}

sync_backups() {
    log "📥 Sincronizzazione backup da server..."
    echo ""

    # Fix permessi sul server (il container borgbackup esegue come root)
    log "🔓 Fix permessi backup sul server..."
    if ssh "${SERVER_USER}@${SERVER_IP}" 'sudo chown -R ubuntu:ubuntu /mnt/nextcloud-data/borg-backups/' 2>&1 | tee -a "$LOG_FILE"; then
        log "✅ Permessi sistemati!"
    else
        log_warning "⚠️  Impossibile sistemare permessi (richiede sudo passwordless)"
        echo ""
        read -p "Continuo comunque? [s/N]: " continue_choice
        if [[ ! "$continue_choice" =~ ^[sS]$ ]]; then
            return 1
        fi
    fi
    echo ""

    # Crea directory se non esiste
    mkdir -p "$LOCAL_BACKUP_DIR"

    # rsync con progress
    if rsync -avz --progress --delete \
        "${SERVER_USER}@${SERVER_IP}:${REMOTE_PATH}" \
        "${LOCAL_BACKUP_DIR}/"; then

        echo ""
        log "✅ Sincronizzazione completata!"

        # Verifica integrità
        log "🔍 Verifica integrità repository..."
        if borg check "$LOCAL_BACKUP_DIR/borg" 2>&1 | tee -a "$LOG_FILE"; then
            log "✅ Integrità verificata!"
        else
            log_error "❌ Verifica integrità fallita!"
            return 1
        fi
    else
        log_error "❌ Errore durante sincronizzazione!"
        return 1
    fi

    echo ""
}

list_backups() {
    log "📋 Backup disponibili:"
    echo ""

    borg list "$LOCAL_BACKUP_DIR/borg" | tee -a "$LOG_FILE"

    echo ""
}

get_latest_backup() {
    borg list "$LOCAL_BACKUP_DIR/borg" --short | tail -1
}

show_backup_info() {
    local backup_name="$1"

    log "ℹ️  Info backup: $backup_name"
    echo ""

    borg info "$LOCAL_BACKUP_DIR/borg::$backup_name" | tee -a "$LOG_FILE"

    echo ""
}

extract_backup() {
    local backup_name="$1"

    # Controlla se directory restore esiste già
    if [ -d "$RESTORE_DIR" ]; then
        echo ""
        log_warning "⚠️  Directory $RESTORE_DIR già esistente!"
        echo ""
        echo "Opzioni:"
        echo "  1) Sovrascrivi (elimina e ricrea)"
        echo "  2) Mantieni backup (crea directory con timestamp)"
        echo "  3) Annulla"
        echo ""
        read -p "Scelta [1/2/3]: " choice

        case $choice in
            1)
                log "🗑️  Eliminazione directory esistente..."
                rm -rf "$RESTORE_DIR"
                ;;
            2)
                RESTORE_DIR="${RESTORE_DIR}-$(date +%Y%m%d-%H%M%S)"
                log "📁 Nuova directory: $RESTORE_DIR"
                ;;
            3)
                log "❌ Estrazione annullata."
                return 0
                ;;
            *)
                log_error "Scelta non valida. Annullo."
                return 1
                ;;
        esac
    fi

    # Crea directory restore
    mkdir -p "$RESTORE_DIR"
    cd "$RESTORE_DIR"

    log "📦 Estrazione backup: $backup_name"
    echo ""
    echo "Destinazione: $RESTORE_DIR"
    echo ""

    # Estrai con progress
    if borg extract --progress "$LOCAL_BACKUP_DIR/borg::$backup_name" 2>&1 | tee -a "$LOG_FILE"; then
        echo ""
        log "✅ Estrazione completata!"

        # Fix permessi
        log "🔓 Fix permessi in corso..."
        if sudo chown -R "$USER:$USER" "$RESTORE_DIR"; then
            log "✅ Permessi corretti!"
        else
            log_warning "⚠️  Impossibile correggere permessi (richiede sudo)"
        fi

        # Statistiche
        echo ""
        log "📊 Statistiche directory estratta:"
        du -sh "$RESTORE_DIR"
        echo ""
        echo "File totali: $(find "$RESTORE_DIR" -type f | wc -l)"
        echo "Directory totali: $(find "$RESTORE_DIR" -type d | wc -l)"
        echo ""
        log "📂 Path completo: $RESTORE_DIR"

    else
        log_error "❌ Errore durante estrazione!"
        return 1
    fi
}

show_help() {
    cat << EOF
Nextcloud Backup Manager

USO:
    $0 [OPZIONI]

OPZIONI:
    --sync-only      Solo sincronizza backup dal server (no estrazione)
    --extract-only   Solo estrai ultimo backup (no sincronizzazione)
    --help           Mostra questo help

SENZA OPZIONI:
    Esegue sync dal server e chiede se estrarre l'ultimo backup

CONFIGURAZIONE:
    Server: ${SERVER_USER}@${SERVER_IP}
    Path remoto: ${REMOTE_PATH}
    Backup locali: ${LOCAL_BACKUP_DIR}
    Directory restore: ${RESTORE_DIR}
    Log file: ${LOG_FILE}

ESEMPI:
    # Sync + estrai interattivo
    $0

    # Solo sync
    $0 --sync-only

    # Solo estrai ultimo backup
    $0 --extract-only

PREREQUISITI:
    - borgbackup installato (sudo dnf install borgbackup)
    - BORG_PASSPHRASE configurata in ~/.bashrc
    - Accesso SSH al server Nextcloud

EOF
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    print_header

    # Check prerequisiti
    check_borg_installed
    check_borg_password

    # Parse arguments
    SYNC=true
    EXTRACT=false
    INTERACTIVE=true

    case "${1:-}" in
        --sync-only)
            SYNC=true
            EXTRACT=false
            INTERACTIVE=false
            ;;
        --extract-only)
            SYNC=false
            EXTRACT=true
            INTERACTIVE=false
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        "")
            SYNC=true
            EXTRACT=false
            INTERACTIVE=true
            ;;
        *)
            echo "Opzione non valida: $1"
            echo "Usa --help per vedere le opzioni disponibili"
            exit 1
            ;;
    esac

    # Sync backups
    if [ "$SYNC" = true ]; then
        if ! sync_backups; then
            log_error "Sincronizzazione fallita!"
            exit 1
        fi
    fi

    # Lista backups
    list_backups

    # Info repository
    log "📊 Statistiche repository:"
    borg info "$LOCAL_BACKUP_DIR/borg" | grep -E "Original size|Compressed size|Deduplicated size|All archives" | tee -a "$LOG_FILE"
    echo ""

    # Get latest backup
    LATEST_BACKUP=$(get_latest_backup)

    if [ -z "$LATEST_BACKUP" ]; then
        log_error "Nessun backup trovato nel repository!"
        exit 1
    fi

    log "🆕 Backup più recente: ${GREEN}$LATEST_BACKUP${NC}"
    echo ""

    # Chiedi se estrarre (se interattivo)
    if [ "$INTERACTIVE" = true ]; then
        read -p "Vuoi estrarre il backup più recente? [s/N]: " extract_choice
        if [[ "$extract_choice" =~ ^[sS]$ ]]; then
            EXTRACT=true
        fi
    fi

    # Estrai backup
    if [ "$EXTRACT" = true ]; then
        echo ""
        show_backup_info "$LATEST_BACKUP"
        extract_backup "$LATEST_BACKUP"

        echo ""
        log "🎉 Operazione completata!"
        echo ""
        echo "I file estratti sono in: ${GREEN}$RESTORE_DIR${NC}"
        echo ""
        echo "Apri con file manager:"
        echo "  nautilus $RESTORE_DIR"
        echo ""
    else
        log "ℹ️  Nessuna estrazione richiesta."
    fi

    log "📝 Log salvato in: $LOG_FILE"
    echo ""
}

# Esegui main
main "$@"
