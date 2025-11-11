# 💾 Local Backup Management

Guida completa per gestire i backup Nextcloud Borg sul PC locale - dall'automazione al controllo manuale avanzato.

**Ultimo aggiornamento**: 11 Novembre 2025

---

## 📋 Indice

### Quick Start

1. [Overview](#-overview)
2. [Prerequisites](#-prerequisites)
3. [Setup Iniziale (5 minuti)](#-setup-iniziale)

### Automated Backup Sync

4. [Script Automatico](#-script-automatico)
5. [Uso Script](#-uso-script)
6. [Automazione Cron](#-automazione-cron)
7. [Monitoring e Logging](#-monitoring-e-logging)

### Advanced Manual Operations

8. [Comandi Borg Manuali](#-comandi-borg-manuali)
9. [Esplorare Backup](#-esplorare-backup)
10. [Estrazione Avanzata](#-estrazione-avanzata)
11. [Mount come Filesystem](#%EF%B8%8F-mount-backup)
12. [Verifica Integrità](#-verifica-integrità)

### Reference

13. [Best Practices](#-best-practices)
14. [Troubleshooting](#-troubleshooting)
15. [Quick Reference](#-quick-reference)

---

## 🎯 Overview

Il progetto include lo script `local-backup-sync.sh` che automatizza completamente la gestione dei backup locali.

### Cosa Fa lo Script

✅ **Sincronizzazione automatica** dal server OCI via rsync (solo differenze)
✅ **Verifica integrità** con `borg check` automatico
✅ **Estrazione interattiva** dell'ultimo backup con gestione conflitti
✅ **Fix permessi automatico** (`chown` per accesso file)
✅ **Logging completo** di tutte le operazioni
✅ **Statistiche repository** (spazio, compressione, deduplica)

### Modalità Disponibili

```bash
nextcloud-backup                  # Interattivo (sync + chiede se estrarre)
nextcloud-backup --sync-only      # Solo sincronizza (perfetto per cron)
nextcloud-backup --extract-only   # Solo estrai ultimo backup
nextcloud-backup --help           # Mostra help completo
```

### Vantaggi Automazione

- 📦 **Backup locale sempre aggiornato** per disaster recovery offline
- 🔄 **Sincronizzazione periodica automatica** (settimanale/giornaliera via cron)
- 📊 **Statistiche dettagliate** automatiche
- 🛡️ **Verifica integrità automatica** dopo ogni sync
- ⚡ **Operazioni batch** non supervisionate

---

## 🔧 Prerequisites

### Software Necessario

```bash
# 1. Borg Backup
sudo dnf install borgbackup

# Verifica installazione
borg --version
# Output: borg 1.2.x
```

**Note:**

- Versione 1.x è compatibile con Nextcloud AIO
- NON installare borgbackup2 (ancora in beta)

### Accesso SSH al Server

```bash
# Test connessione SSH
ssh ubuntu@<server-ip>

# Se richiede password ogni volta, configura chiavi SSH:
ssh-copy-id ubuntu@<server-ip>
```

### Password Borg

Recupera password Borg dal server:

```bash
# Sul server
ssh ubuntu@<server-ip>
docker exec nextcloud-aio-mastercontainer env | grep BORG_PASSWORD

# Output esempio:
# BORG_PASSWORD=your-borg-password-here

# Salvala al sicuro (es. password manager)
```

**Alternativa**: Vai su `https://<your-domain>:8080` → Backup and Restore → mostra password Borg

---

## 🚀 Setup Iniziale

### 1. Crea Link Simbolico allo Script

```bash
# Lo script è già nella repo
# ~/Projects/nextcloud-oci-terraform/scripts/local-backup-sync.sh

# Crea link simbolico in ~/bin per accesso facile
mkdir -p ~/bin
ln -s ~/Projects/nextcloud-oci-terraform/scripts/local-backup-sync.sh ~/bin/nextcloud-backup

# Rendi eseguibile
chmod +x ~/Projects/nextcloud-oci-terraform/scripts/local-backup-sync.sh

# Ora puoi lanciarlo da qualsiasi directory
nextcloud-backup --help
```

### 2. Configura Password Borg

**Metodo A: ~/.bash_profile (Raccomandato)**

```bash
# Aggiungi password a .bash_profile
echo 'export BORG_PASSPHRASE="your-borg-password-here"' >> ~/.bash_profile

# Ricarica
source ~/.bash_profile

# Verifica
echo $BORG_PASSPHRASE
# Output: your-borg-password-here
```

**Metodo B: File Dedicato (Più Sicuro)**

```bash
# Crea directory config Borg
mkdir -p ~/.config/borg

# Crea file con password (protetto)
cat > ~/.config/borg/env << 'EOF'
export BORG_PASSPHRASE="your-borg-password-here"
EOF

# Limita permessi (solo il tuo utente può leggere)
chmod 600 ~/.config/borg/env

# Source da .bash_profile
echo 'source ~/.config/borg/env' >> ~/.bash_profile

# Ricarica
source ~/.bash_profile
```

### 3. Personalizza Configurazione Script (Opzionale)

Apri lo script e verifica/modifica configurazione se necessario:

```bash
nano ~/Projects/nextcloud-oci-terraform/scripts/local-backup-sync.sh

# Variabili configurabili (righe 20-26):
SERVER_USER="ubuntu"                              # ← Username SSH
SERVER_IP="<your-server-ip>"                     # ← IP server OCI
REMOTE_PATH="/mnt/nextcloud-data/borg-backups/"  # ← Path backup sul server
LOCAL_BACKUP_DIR="$HOME/nextcloud-backup-local"  # ← Directory locale backup
RESTORE_DIR="$HOME/restore-nextcloud"            # ← Directory estrazione
LOG_FILE="$HOME/nextcloud-backup.log"            # ← File log
```

**Nota:** I valori di default vanno bene per la maggior parte degli utenti!

### 4. Test Iniziale

```bash
# Test manuale (solo sync, no estrazione)
nextcloud-backup --sync-only

# Output atteso:
# ╔════════════════════════════════════════════════════════════════╗
# ║  Nextcloud Backup Manager                                      ║
# ╚════════════════════════════════════════════════════════════════╝
#
# [2025-11-11 10:00:00] 📥 Sincronizzazione backup da server...
# ...
# [2025-11-11 10:02:30] ✅ Sincronizzazione completata!
# [2025-11-11 10:02:31] 🔍 Verifica integrità repository...
# [2025-11-11 10:03:45] ✅ Integrità verificata!
```

Se funziona, il setup è completo! ✅

---

## 🤖 Script Automatico

### Architettura Script

Lo script `local-backup-sync.sh` gestisce l'intero workflow:

```
┌─────────────────────────────────────────────────────────────┐
│                  nextcloud-backup WORKFLOW                  │
├─────────────────────────────────────────────────────────────┤
│ 1. Check Prerequisites                                      │
│    ├─ Borg installed?                                       │
│    ├─ BORG_PASSPHRASE configured?                          │
│    └─ SSH access working?                                   │
├─────────────────────────────────────────────────────────────┤
│ 2. Sync Backups (rsync)                                    │
│    ├─ Download only differences (fast!)                    │
│    ├─ Progress bar real-time                               │
│    └─ Log all operations                                    │
├─────────────────────────────────────────────────────────────┤
│ 3. Verify Integrity (borg check)                           │
│    ├─ Automatic repository check                           │
│    ├─ Detect corruption                                     │
│    └─ Log results                                           │
├─────────────────────────────────────────────────────────────┤
│ 4. List Backups (borg list)                                │
│    ├─ Show all available backups                           │
│    ├─ Dates and sizes                                       │
│    └─ Identify latest backup                               │
├─────────────────────────────────────────────────────────────┤
│ 5. Repository Statistics                                    │
│    ├─ Original size                                         │
│    ├─ Compressed size                                       │
│    └─ Deduplicated size ⭐                                  │
├─────────────────────────────────────────────────────────────┤
│ 6. Extract Backup (interactive/automatic)                  │
│    ├─ Prompt user (interactive mode)                       │
│    ├─ Handle existing directories                          │
│    ├─ Extract with progress bar                            │
│    ├─ Fix permissions automatically (chown)                │
│    └─ Show statistics (files/dirs count)                   │
└─────────────────────────────────────────────────────────────┘
```

### Funzioni Principali

**check_borg_installed()** - Verifica borgbackup installato
**check_borg_password()** - Verifica BORG_PASSPHRASE configurata
**sync_backups()** - Sincronizza da server con rsync + verifica integrità
**list_backups()** - Lista tutti i backup disponibili
**get_latest_backup()** - Identifica backup più recente
**show_backup_info()** - Mostra dettagli backup specifico
**extract_backup()** - Estrae backup con gestione conflitti + fix permessi

---

## 📱 Uso Script

### Modalità 1: Interattiva (Default)

```bash
# Lancia senza opzioni
nextcloud-backup

# Workflow:
# 1. Sincronizza backup dal server
# 2. Verifica integrità
# 3. Lista backup disponibili
# 4. Mostra statistiche repository
# 5. Chiede: "Vuoi estrarre il backup più recente? [s/N]"
#    → Se sì: estrae + fix permessi
#    → Se directory esiste, chiede:
#       1) Sovrascrivi (elimina e ricrea)
#       2) Mantieni backup (crea directory con timestamp)
#       3) Annulla
```

**Output Esempio:**

```
╔════════════════════════════════════════════════════════════════╗
║  Nextcloud Backup Manager                                      ║
╚════════════════════════════════════════════════════════════════╝

[2025-11-11 10:00:00] 📥 Sincronizzazione backup da server...

receiving incremental file list
borg/data/0/123
...
sent 1,234 bytes  received 12.34 MB bytes  2.45 MB/s

[2025-11-11 10:02:30] ✅ Sincronizzazione completata!
[2025-11-11 10:02:31] 🔍 Verifica integrità repository...
[2025-11-11 10:03:45] ✅ Integrità verificata!

[2025-11-11 10:03:45] 📋 Backup disponibili:

20251110_040122-nextcloud-aio  Mon, 2025-11-10 04:01:22
20251111_040133-nextcloud-aio  Tue, 2025-11-11 04:01:33

[2025-11-11 10:03:48] 📊 Statistiche repository:
All archives:               12.83 GB       4.44 GB     517.24 MB

[2025-11-11 10:03:48] 🆕 Backup più recente: 20251111_040133-nextcloud-aio

Vuoi estrarre il backup più recente? [s/N]: s

ℹ️  Info backup: 20251111_040133-nextcloud-aio
Archive name: 20251111_040133-nextcloud-aio
Duration: 10.91 seconds
Number of files: 33934
...

[2025-11-11 10:04:00] 📦 Estrazione backup: 20251111_040133-nextcloud-aio

Destinazione: $HOME/restore-nextcloud

Extracting: 33934/33934 files (100.0%)

[2025-11-11 10:05:23] ✅ Estrazione completata!
[2025-11-11 10:05:23] 🔓 Fix permessi in corso...
[2025-11-11 10:05:25] ✅ Permessi corretti!

[2025-11-11 10:05:25] 📊 Statistiche directory estratta:
1.4G    $HOME/restore-nextcloud

File totali: 33934
Directory totali: 1245

[2025-11-11 10:05:25] 📂 Path completo: $HOME/restore-nextcloud

[2025-11-11 10:05:25] 🎉 Operazione completata!

I file estratti sono in: $HOME/restore-nextcloud

Apri con file manager:
  nautilus $HOME/restore-nextcloud

[2025-11-11 10:05:25] 📝 Log salvato in: $HOME/nextcloud-backup.log
```

### Modalità 2: Solo Sincronizzazione

```bash
# Solo download/aggiornamento backup (no estrazione)
nextcloud-backup --sync-only

# Uso tipico:
# - Cron job automatico
# - Aggiornamento rapido backup locale
# - Verifiche periodiche
# - Prima di estrazione manuale successiva
```

**Tempo:** ~2-3 minuti (solo differenze dopo primo sync)

### Modalità 3: Solo Estrazione

```bash
# Estrai solo ultimo backup (assume sync già fatto)
nextcloud-backup --extract-only

# Uso tipico:
# - Hai già sincronizzato prima
# - Vuoi solo estrarre l'ultimo backup
# - Test restore veloce
```

### Help

```bash
# Mostra tutte le opzioni disponibili
nextcloud-backup --help

# Output:
# Nextcloud Backup Manager
#
# USO:
#     nextcloud-backup [OPZIONI]
#
# OPZIONI:
#     --sync-only      Solo sincronizza backup dal server
#     --extract-only   Solo estrai ultimo backup
#     --help           Mostra questo help
#
# CONFIGURAZIONE:
#     Server: ubuntu@<your-server-ip>
#     Path remoto: /mnt/nextcloud-data/borg-backups/
#     Backup locali: $HOME/nextcloud-backup-local
#     Directory restore: $HOME/restore-nextcloud
#     Log file: $HOME/nextcloud-backup.log
```

---

## ⏰ Automazione Cron

### Setup Backup Settimanale Automatico

**Schedulazione Raccomandata:** Ogni domenica sera alle 22:00

```bash
# Apri crontab
crontab -e

# Aggiungi questa riga:
0 22 * * 0 $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1

# Spiegazione sintassi:
# 0 22 * * 0    = Domenica (0) ore 22:00
# --sync-only   = Solo sincronizza (no estrazione automatica)
# >> log 2>&1   = Salva output e errori in log
```

**Formato Cron:**

```
┌───────────── minuto (0-59)
│ ┌───────────── ora (0-23)
│ │ ┌───────────── giorno mese (1-31)
│ │ │ ┌───────────── mese (1-12)
│ │ │ │ ┌───────────── giorno settimana (0-6, 0=domenica)
│ │ │ │ │
* * * * * comando-da-eseguire
```

### Esempi Schedulazioni Alternative

```bash
# Ogni giorno alle 3:00 AM
0 3 * * * $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1

# Ogni lunedì alle 9:00 AM
0 9 * * 1 $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1

# Ogni 12 ore
0 */12 * * * $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1

# Primo giorno del mese alle 2:00 AM
0 2 1 * * $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1
```

### Verifica Cron Configurato

```bash
# Lista cron jobs attivi
crontab -l

# Output atteso:
# 0 22 * * 0 $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1

# Verifica servizio cron attivo
systemctl status cronie

# Test manuale come farebbe cron
$HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1
```

### Notifiche Desktop (Opzionale)

Aggiungi notifiche desktop al cron:

```bash
# Crea wrapper script con notifica
cat > ~/bin/nextcloud-backup-notify.sh << 'EOF'
#!/bin/bash
if $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1; then
    notify-send "Nextcloud Backup" "✅ Sincronizzazione completata con successo!"
else
    notify-send "Nextcloud Backup" "❌ Errore durante sincronizzazione!" -u critical
fi
EOF

chmod +x ~/bin/nextcloud-backup-notify.sh

# Usa questo nel cron invece
crontab -e
# 0 22 * * 0 $HOME/bin/nextcloud-backup-notify.sh
```

---

## 📊 Monitoring e Logging

### Log Files

Lo script genera **due** file di log:

1. **Log Principale**: `~/nextcloud-backup.log`
   - Tutte le operazioni dello script
   - Timestamp dettagliati
   - Errori e warning

2. **Log Cron**: `~/nextcloud-backup-cron.log` (se configurato cron)
   - Output delle esecuzioni automatiche
   - Utile per debug schedulazioni

### Visualizza Log

```bash
# Log principale (ultimi 50 righe)
tail -50 ~/nextcloud-backup.log

# Log cron
tail -50 ~/nextcloud-backup-cron.log

# Segui log in real-time (durante esecuzione)
tail -f ~/nextcloud-backup.log

# Cerca errori
grep -i error ~/nextcloud-backup.log
grep -i warning ~/nextcloud-backup.log

# Log di oggi
grep "$(date +%Y-%m-%d)" ~/nextcloud-backup.log

# Log ultima settimana
grep -A 20 "$(date -d '7 days ago' +%Y-%m-%d)" ~/nextcloud-backup.log
```

### Statistiche Repository

```bash
# Dopo sync, verifica statistiche dettagliate
borg info ~/nextcloud-backup-local/borg

# Output mostra:
# - Repository ID e location
# - Encryption status
# - Numero archive totali
# - Spazio occupato (original/compressed/deduplicated)
# - Chunk statistics

# Esempio output:
# Repository ID: 1234567890abcdef...
# Location: $HOME/nextcloud-backup-local/borg
# Encrypted: Yes (repokey)
#
# ------------------------------------------------------------------------------
#                        Original size      Compressed size    Deduplicated size
# All archives:               12.83 GB              4.44 GB            517.24 MB
#
#                        Unique chunks         Total chunks
# Chunk index:                   30194               300949
```

### Spazio Disco Monitoring

```bash
# Verifica spazio occupato
du -sh ~/nextcloud-backup-local
du -sh ~/restore-nextcloud

# Spazio disponibile
df -h ~

# Lista dimensioni per backup
borg info ~/nextcloud-backup-local/borg | grep "All archives"
```

---

## 🔧 Comandi Borg Manuali

Per utenti avanzati che vogliono controllo completo oltre lo script automatico.

### Download Manuale con rsync

```bash
# Download completo repository (prima volta)
rsync -avz --progress ubuntu@<server-ip>:/mnt/nextcloud-data/borg-backups/ ~/nextcloud-backup-local/

# Opzioni spiegate:
# -a = archive mode (preserva permessi, timestamp)
# -v = verbose (mostra file copiati)
# -z = compress (comprime durante trasferimento)
# --progress = barra progresso

# Download incrementale (aggiornamenti)
rsync -avz --progress --delete ubuntu@<server-ip>:/mnt/nextcloud-data/borg-backups/ ~/nextcloud-backup-local/

# --delete rimuove file locali non più presenti sul server
```

**Dimensione Download:** ~517 MB (repository completo con deduplica)
**Tempo Stimato:** 3-5 minuti (dipende dalla connessione)

---

## 🔍 Esplorare Backup

### Lista Tutti i Backup

```bash
# Lista backup nel repository
borg list ~/nextcloud-backup-local/borg
```

**Output Esempio:**

```
20251111_040133-nextcloud-aio  Tue, 2025-11-11 04:01:33 [6b8aea4e1a66...]
20251110_040122-nextcloud-aio  Mon, 2025-11-10 04:01:22 [abc123def456...]
20251109_040115-nextcloud-aio  Sun, 2025-11-09 04:01:15 [def789ghi012...]
...
```

### Informazioni Repository

```bash
# Statistiche globali repository
borg info ~/nextcloud-backup-local/borg

# Output mostra:
# - Repository ID, location, encryption
# - Original size (dati totali salvati)
# - Compressed size (dopo compressione)
# - Deduplicated size (spazio reale su disco) ⭐
```

### Informazioni Backup Specifico

```bash
# Info dettagliate singolo backup
borg info ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio

# Output:
# - Archive name e fingerprint
# - Time (start/end) e duration
# - Number of files
# - Size statistics (original/compressed/deduplicated)
```

### Lista Contenuto Backup

```bash
# Lista TUTTI i file in un backup
borg list ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio

# Output:
# drwxr-xr-x ubuntu ubuntu        0 Tue, 2025-11-11 04:01:34 nextcloud-aio-nextcloud
# -rw-r--r-- ubuntu ubuntu   524288 Tue, 2025-11-11 04:01:34 nextcloud-aio-nextcloud/data/admin/files/doc.pdf
# ...
```

### Cerca File Specifici

```bash
# Cerca per nome
borg list ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio | grep "rubrica.vcf"

# Cerca per estensione
borg list ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio | grep "\.pdf$"

# Cerca in directory specifica
borg list ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio | grep "calendari/"

# Cerca file modificati in data specifica
borg list ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio | grep "2025-11-10"
```

---

## 📦 Estrazione Avanzata

### Estrazione Completa

```bash
# Crea directory per restore
mkdir -p ~/restore-nextcloud
cd ~/restore-nextcloud

# Estrai TUTTO il backup più recente
borg extract ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio

# Con progress bar
borg extract --progress ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio

# Fix permessi (se estratto come root)
sudo chown -R $USER:$USER ~/restore-nextcloud
```

**Dimensione Estratta:** ~1.43 GB
**Tempo:** 1-2 minuti

### Estrazione Directory Specifica

```bash
# Estrai solo i file utente (non database)
mkdir -p ~/restore-files-only
cd ~/restore-files-only

borg extract ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio \
  nextcloud-aio-nextcloud/data/admin/files
```

### Estrazione File Singolo

```bash
mkdir -p ~/restore-specific
cd ~/restore-specific

# Estrai file specifico (usa path completo da borg list)
borg extract ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio \
  nextcloud-aio-nextcloud/data/admin/files/Documents/rubrica.vcf

# File estratto in:
# ~/restore-specific/nextcloud-aio-nextcloud/data/admin/files/Documents/rubrica.vcf
```

### Estrazione con Pattern

```bash
# Estrai tutti i PDF
mkdir -p ~/restore-pdfs
cd ~/restore-pdfs

borg extract ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio \
  --pattern='+ **/*.pdf' \
  --pattern='- **'

# Estrai tutti i calendari (.ics)
borg extract ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio \
  --pattern='+ **/calendari/*.ics' \
  --pattern='- **'

# Estrai file modificati nelle ultime 24h
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
borg extract ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio \
  --pattern="+ **" \
  --newer-than="${YESTERDAY}"
```

### Dry-Run (Test)

```bash
# Vedi cosa verrebbe estratto SENZA estrarre
borg extract --dry-run --list ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio

# Utile per verificare prima di estrarre grandi quantità di dati
```

---

## 🗂️ Mount Backup

**La Feature Più Potente di Borg!** 🚀

Monta i backup come directory read-only - puoi navigarli come normali cartelle!

### Mount Tutti i Backup

```bash
# Crea mountpoint
mkdir -p ~/borg-mount

# Monta tutti i backup
borg mount ~/nextcloud-backup-local/borg ~/borg-mount

# Naviga i backup
ls ~/borg-mount/

# Output:
# 20251111_040133-nextcloud-aio/
# 20251110_040122-nextcloud-aio/
# 20251109_040115-nextcloud-aio/
# ...

# Naviga un backup specifico
ls ~/borg-mount/20251111_040133-nextcloud-aio/

# Copia file normalmente
cp ~/borg-mount/20251111_040133-nextcloud-aio/nextcloud-aio-nextcloud/data/admin/files/document.pdf ~/Desktop/

# Quando finito, smonta
borg umount ~/borg-mount
```

### Mount Singolo Backup

```bash
# Monta solo un backup specifico
borg mount ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio ~/borg-mount

# Naviga direttamente i file (senza sottodirectory del nome backup)
ls ~/borg-mount/nextcloud-aio-nextcloud/data/admin/files/

# Smonta
borg umount ~/borg-mount
```

### Usa con File Manager Grafico

```bash
# Monta
borg mount ~/nextcloud-backup-local/borg ~/borg-mount

# Apri file manager grafico
nautilus ~/borg-mount  # Fedora/GNOME
dolphin ~/borg-mount   # KDE
thunar ~/borg-mount    # XFCE

# Naviga visualmente i backup! 🎨

# Quando finito
borg umount ~/borg-mount
```

### Mount in Foreground (Debug)

```bash
# Mount in foreground (vedi log, utile per debug)
borg mount -f ~/nextcloud-backup-local/borg ~/borg-mount

# CTRL+C per smontare
```

---

## ✅ Verifica Integrità

### Verifica Repository Completo

```bash
# Check integrità di tutto il repository
borg check ~/nextcloud-backup-local/borg

# Output se OK:
# Archive consistency check completed successfully
```

**Tempo:** 2-5 minuti (prima volta), poi più veloce (usa cache)

### Verifica Backup Specifico

```bash
# Check di un singolo backup
borg check ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio
```

### Verifica con Dettagli

```bash
# Check verbose con dettagli
borg check --verify-data ~/nextcloud-backup-local/borg

# Opzioni:
# --verify-data = verifica anche i dati (non solo metadata)
# --progress = mostra barra progresso
```

### Verifica Dopo Download (IMPORTANTE!)

```bash
# Sempre verificare integrità dopo rsync
rsync -avz --progress ubuntu@<IP>:/mnt/nextcloud-data/borg-backups/ ~/nextcloud-backup-local/

# Poi verifica
borg check ~/nextcloud-backup-local/borg

# Se OK, il download non ha corrotto i dati ✅
```

**Nota:** Lo script automatico fa questo check automaticamente dopo ogni sync!

---

## ✅ Best Practices

### 1. Schedulazione Raccomandata

**Settimanale** è ottimale per la maggior parte dei casi:

✅ Backup sempre recenti (max 7 giorni vecchi)
✅ Carico minimo sul server
✅ Banda/spazio disk sotto controllo
✅ Tempo sufficiente per reagire in caso di disaster

**Giornaliero** solo se:

- Modifichi dati critici ogni giorno
- Hai banda/spazio abbondante
- Vuoi RPO (Recovery Point Objective) < 24h

### 2. Verifica Periodica Manuale

```bash
# Una volta al mese, testa manualmente:
nextcloud-backup --extract-only

# Verifica file estratti
ls -lh ~/restore-nextcloud/

# Apri qualche file per assicurarti siano leggibili
nautilus ~/restore-nextcloud
```

### 3. Monitoring Spazio Disco

```bash
# Monitora spazio occupato
du -sh ~/nextcloud-backup-local
du -sh ~/restore-nextcloud

# Libera spazio se necessario (elimina vecchie estrazioni)
rm -rf ~/restore-nextcloud-*/  # Vecchie estrazioni con timestamp
```

### 4. Retention Backup Locali

I backup locali seguono la **stessa retention del server** (configurata in AIO):

- Daily: ultimi 7 giorni
- Weekly: ultime 4 settimane
- Monthly: ultimi 6 mesi

**NON serve** cancellare manualmente backup vecchi - Borg lo fa automaticamente sul server!

### 5. Backup del Backup (3-2-1 Rule)

Per massima sicurezza:

```bash
# Copia periodicamente su disco esterno
rsync -avz ~/nextcloud-backup-local/ /media/external-disk/nextcloud-backup/

# O su cloud storage (rclone)
rclone sync ~/nextcloud-backup-local/ gdrive:nextcloud-backups/
```

**3-2-1 Rule:**

- **3** copie dei dati
- **2** tipi di media diversi
- **1** copia off-site

Attualmente hai:

1. ✅ Server OCI (production)
2. ✅ PC locale (script automatico)
3. ⚠️ Disco esterno/cloud (raccomandato!)

### 6. Password Borg Sicura

```bash
# Salva password in password manager
# NON committare in git
# NON condividere via email/chat

# Backup password in luogo sicuro
# Se perdi password = backup inutilizzabili!
```

### 7. Test Restore Periodico

```bash
# Ogni 3 mesi, prova restore completo
nextcloud-backup
# → Rispondi "s" a estrazione

# Verifica che tutto sia leggibile
# Questo è un DRILL di disaster recovery!
```

### 8. Log Review

```bash
# Una volta al mese, controlla log per errori
grep -i error ~/nextcloud-backup.log
grep -i warning ~/nextcloud-backup.log
grep -i failed ~/nextcloud-backup-cron.log
```

---

## 🔧 Troubleshooting

### Problema: Cron non esegue lo script

**Diagnosi:**

```bash
# Verifica cron attivo
systemctl status cronie

# Controlla log sistema
sudo journalctl -u cronie -f

# Controlla syntax crontab
crontab -l
```

**Possibili Cause:**

1. Path script errato (usa path assoluto!)
2. BORG_PASSPHRASE non disponibile (cron ha environment diverso)
3. Script non eseguibile

**Soluzione:**

```bash
# 1. Usa path assoluto
crontab -e
# SBAGLIATO: nextcloud-backup --sync-only
# GIUSTO: $HOME/bin/nextcloud-backup --sync-only

# 2. Export password nel cron (se necessario)
BORG_PASSPHRASE=your-borg-password-here
0 22 * * 0 $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1

# 3. Verifica permessi
chmod +x ~/bin/nextcloud-backup
```

### Problema: rsync Permission Denied

**Causa:** File sul server owned da root

**Soluzione:**

```bash
# Sul server, fixa permessi (una volta)
ssh ubuntu@<server-ip> 'sudo chown -R ubuntu:ubuntu /mnt/nextcloud-data/borg-backups/'
```

### Problema: borg check fallisce

**Causa:** Repository corrotto o download incompleto

**Soluzione:**

```bash
# 1. Cancella cache Borg locale
rm -rf ~/.cache/borg
rm -rf ~/.config/borg/security

# 2. Ri-scarica repository
rm -rf ~/nextcloud-backup-local
nextcloud-backup --sync-only

# 3. Verifica integrità
borg check ~/nextcloud-backup-local/borg
```

### Problema: "Cache is newer than repository"

**Causa:** Hai scaricato repository, cancellato, e riscaricato. Borg cache ha timestamp vecchi.

**Soluzione:**

```bash
# Cancella cache Borg (sicuro - solo metadata locale)
rm -rf ~/.cache/borg
rm -rf ~/.config/borg/security

# Riprova comando
borg list ~/nextcloud-backup-local/borg  # Ricrea cache
```

### Problema: Disco pieno

**Causa:** Backup + estrazioni occupano troppo spazio

**Soluzione:**

```bash
# 1. Elimina vecchie estrazioni
rm -rf ~/restore-nextcloud-*/

# 2. Controlla spazio
df -h ~

# 3. Se necessario, sposta su disco esterno
mv ~/nextcloud-backup-local /media/external-disk/
ln -s /media/external-disk/nextcloud-backup-local ~/nextcloud-backup-local
```

### Problema: Script lento

**Causa:** Connessione lenta o grande quantità dati

**Soluzione:**

```bash
# Limita banda rsync nel script (se devi usare internet durante sync)
# Modifica script, riga rsync:
rsync -avz --progress --delete --bwlimit=5000 ...
# bwlimit in KB/s (5000 = ~5 MB/s)

# O esegui di notte via cron quando non usi PC
```

### Problema: "Passphrase wrong"

**Causa:** Password Borg errata o non configurata

**Soluzione:**

```bash
# Recupera password dal server
ssh ubuntu@<server-ip>
docker exec nextcloud-aio-mastercontainer env | grep BORG_PASSWORD

# Export password corretta
export BORG_PASSPHRASE="password-corretta-qui"

# O aggiungi a ~/.bash_profile permanentemente
echo 'export BORG_PASSPHRASE="password-corretta"' >> ~/.bash_profile
source ~/.bash_profile
```

### Problema: Directory restore locked (mount)

**Causa:** File estratti hanno permessi root

**Soluzione:**

```bash
# Usa extraction invece di mount, poi fix permessi
cd ~/restore-nextcloud
borg extract ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio
sudo chown -R $USER:$USER ~/restore-nextcloud/

# Ora accessibile!
```

**Nota:** Lo script automatico fa questo fix automaticamente!

---

## 📝 Quick Reference

### Setup una tantum

```bash
# Install Borg
sudo dnf install borgbackup

# Configure password
echo 'export BORG_PASSPHRASE="..."' >> ~/.bash_profile
source ~/.bash_profile

# Create symlink
ln -s ~/Projects/nextcloud-oci-terraform/scripts/local-backup-sync.sh ~/bin/nextcloud-backup

# Test
nextcloud-backup --help
```

### Uso Script Automatico

```bash
nextcloud-backup                  # Interattivo (sync + chiede estrazione)
nextcloud-backup --sync-only      # Solo sincronizza (perfetto per cron)
nextcloud-backup --extract-only   # Solo estrai ultimo
nextcloud-backup --help           # Help
```

### Automazione Cron

```bash
crontab -e
# Aggiungi:
0 22 * * 0 $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1
```

### Monitoring

```bash
tail -f ~/nextcloud-backup.log          # Log principale
tail -f ~/nextcloud-backup-cron.log     # Log cron
borg info ~/nextcloud-backup-local/borg # Statistiche
du -sh ~/nextcloud-backup-local         # Spazio occupato
```

### Comandi Borg Manuali

```bash
# Esplorazione
borg list ~/nextcloud-backup-local/borg                              # Lista backup
borg info ~/nextcloud-backup-local/borg                              # Info repository
borg list ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio  # File in backup

# Estrazione
cd ~/restore && borg extract ~/nextcloud-backup-local/borg::20251111_040133-nextcloud-aio

# Mount
borg mount ~/nextcloud-backup-local/borg ~/borg-mount
# ... naviga ...
borg umount ~/borg-mount

# Verifica
borg check ~/nextcloud-backup-local/borg
```

---

## 📚 Riferimenti

- **Script Source**: `scripts/local-backup-sync.sh`
- **Scripts Overview**: `scripts/README.md`
- **Backup Strategy**: `docs/06-BACKUP-RESTORE.md`
- **Borg Documentation**: <https://borgbackup.readthedocs.io/>
- **Cron Tutorial**: `man 5 crontab`

---

**Creato**: 11 Novembre 2025
**Testato su**: Fedora 43, borgbackup 1.2.7, OCI Ubuntu 24.04
**Script Version**: local-backup-sync.sh v1.0
