# Backup Automation with Cron

Guida all'automazione dei backup con cron per Nextcloud.

**Ultima modifica**: 8 Novembre 2025

---

## 📋 Overview

Questo documento spiega la strategia di backup automation implementata per garantire che i dati Nextcloud siano sempre protetti con copie off-site automatiche.

### Perché serve l'automazione?

**Problema**: I backup manuali si dimenticano facilmente.

**Soluzione**: Automazione con cron che esegue backup settimanali senza intervento manuale.

**Risultato**:
- ✅ Backup regolari garantiti
- ✅ Copie off-site su PC locale
- ✅ Dati esportati in formato portabile
- ✅ Disaster recovery pronto

---

## 🎯 Strategia Backup Automation

### Livello 1: Backup Borg Automatico (Nextcloud AIO)

**Già configurato in Nextcloud AIO:**

```
Frequenza: Giornaliera (04:00 UTC)
Location:  /mnt/backup/borg/ (su istanza OCI)
Retention: 7 giorni
Tipo:      Incrementale, encrypted, compresso
```

**Contenuto:**
- ✅ Database PostgreSQL completo
- ✅ File utenti
- ✅ Configurazioni Nextcloud
- ✅ App data

**Limitazione**: I backup sono **sulla stessa istanza OCI**.

→ Se l'istanza viene distrutta accidentalmente, i backup sono persi!

---

### Livello 2: Backup Off-Site Automatico (Cron)

**Soluzione implementata:**

Cron job che esegue **weekly-backup.sh** ogni domenica alle 22:00.

```
┌─────────────────────────────────────────────┐
│  OCI Instance                               │
│  /mnt/backup/borg/                          │
│  ↓ (Borg daily 04:00)                       │
│  ↓                                           │
│  ↓ (rsync ogni domenica 22:00)              │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│  PC Locale (Fedora)                         │
│  ~/nextcloud-backups/                       │
│  - Borg backup completi                     │
│                                              │
│  ~/nextcloud-exports/YYYYMMDD_HHMMSS/       │
│  - calendars/*.ics                           │
│  - contacts/all-contacts.vcf                │
│  - files/file-list.txt                      │
└─────────────────────────────────────────────┘
```

**Vantaggi:**
- ✅ **Off-site**: Backup fisicamente separati dall'istanza
- ✅ **Dual format**: Borg (completo) + Export (portabile)
- ✅ **Automatico**: Zero intervento manuale
- ✅ **Disaster recovery**: Se OCI esplode, hai tutto sul PC

---

## 🔧 Implementazione

### Script Coinvolti

#### 1. `scripts/weekly-backup.sh` (Orchestratore)

Esegue entrambi i backup in sequenza:

```bash
#!/bin/bash
# Orchestratore backup settimanale

echo "=== Weekly Nextcloud Backup ==="
date

# 1. Download Borg backup da OCI
echo "Step 1: Downloading Borg backups..."
/path/to/download-backup.sh

# 2. Export dati in formato leggibile
echo "Step 2: Exporting data..."
/path/to/export-data.sh

echo "=== Backup Complete ==="
```

**Output**: Log in `/tmp/nextcloud-backup.log`

#### 2. `scripts/download-backup.sh` (Borg Sync)

Scarica i backup Borg encrypted dal server:

```bash
rsync -avzh --progress \
  -e "ssh -i ~/.ssh/KEY" \
  --rsync-path="sudo rsync" \
  ubuntu@OCI_IP:/mnt/backup/borg/ \
  ~/nextcloud-backups/
```

**Risultato**: Copia esatta dei backup Borg sul PC locale.

#### 3. `scripts/export-data.sh` (Data Export)

Esporta dati in formato human-readable:

- **Calendari**: .ics files (importabili su Google/Apple/Outlook)
- **Contatti**: .vcf file (rubrica completa)
- **File list**: Elenco file disponibili

**Risultato**: `~/nextcloud-exports/YYYYMMDD_HHMMSS/`

#### 4. `scripts/setup-cron.sh` (Configuratore)

Setup una tantum per configurare il cron job:

```bash
./scripts/setup-cron.sh

# Aggiunge al crontab:
# 0 22 * * 0 /path/to/weekly-backup.sh >> /tmp/nextcloud-backup.log 2>&1
```

---

## ⚙️ Configurazione Cron

### Setup (Una Tantum)

```bash
cd /home/pandagan/Projects/nextcloud-oci-terraform

# Esegui setup script
./scripts/setup-cron.sh
```

**Output:**
```
=== Nextcloud Backup Cron Setup ===

Configuration:
Script: /home/pandagan/Projects/nextcloud-oci-terraform/scripts/weekly-backup.sh
Schedule: Every Sunday at 22:00 (10 PM)
Log file: /tmp/nextcloud-backup.log

✓ Cron job added successfully!

Current crontab:
0 22 * * 0 /home/pandagan/Projects/nextcloud-oci-terraform/scripts/weekly-backup.sh >> /tmp/nextcloud-backup.log 2>&1

✓ Cron service is running
```

### Verifica Configurazione

```bash
# Lista cron jobs
crontab -l

# Verifica servizio cron attivo
systemctl status crond

# Test manuale (prima di domenica)
./scripts/weekly-backup.sh

# Visualizza log
tail -f /tmp/nextcloud-backup.log
```

---

## 🕐 Schedule Dettagliato

### Cron Expression Spiegata

```
0 22 * * 0
│ │  │ │ │
│ │  │ │ └─── Giorno settimana (0 = Domenica)
│ │  │ └───── Mese (1-12, * = ogni mese)
│ │  └─────── Giorno mese (1-31, * = ogni giorno)
│ └────────── Ora (22 = 22:00 / 10 PM)
└──────────── Minuto (0 = :00)
```

**Traduzione**: Ogni domenica alle 22:00

### Perché Domenica alle 22:00?

**Ragionamento:**

1. **Weekend**: Meno attività utente (safe per backup pesanti)
2. **22:00**: Dopo cena, prima di dormire
3. **PC acceso**: Probabilmente il PC è ancora acceso
4. **Network usage**: Meno impatto su altre attività

**Alternativa**: Se preferisci un altro orario:

```bash
# Edit crontab
crontab -e

# Modifica l'orario, esempio: Sabato alle 02:00
0 2 * * 6 /path/to/weekly-backup.sh >> /tmp/nextcloud-backup.log 2>&1
```

---

## 📊 Monitoring & Verifica

### Primo Backup (Domenica prossima)

**Domenica 10 Novembre 2025, ore 22:00:**

Il cron eseguirà il primo backup automatico.

**Come verificare:**

```bash
# Durante l'esecuzione (se sei al PC)
tail -f /tmp/nextcloud-backup.log

# Dopo l'esecuzione
cat /tmp/nextcloud-backup.log

# Verifica file creati
ls -lh ~/nextcloud-backups/
ls -lh ~/nextcloud-exports/latest/
```

### Log Analysis

**Log di successo esempio:**

```
=== Weekly Nextcloud Backup ===
Thu Nov  8 22:00:01 CET 2025

Step 1: Downloading Borg backups...
=== Nextcloud Borg Backup Download ===
Checking remote backup size...
Remote backup size: 125.3 MB
Available local space: 450.2 GB
✓ Sufficient space available

Downloading backups with rsync...
receiving file list ... done
borg-backup-20251107.tar.gz
        125.3M 100%   15.2MB/s    0:00:08

✓ Backup downloaded successfully!

Step 2: Exporting data...
=== Nextcloud Data Export ===
Export directory: /home/pandagan/nextcloud-exports/20251108_220015

Exporting calendars...
✓ 10 calendars exported

Exporting contacts...
✓ 125 contacts exported

Creating file list...
✓ File list created

=== Backup Complete ===
```

**Log di errore esempio:**

```
=== Weekly Nextcloud Backup ===
Thu Nov  8 22:00:01 CET 2025

Step 1: Downloading Borg backups...
ERROR: Cannot connect to OCI instance
ssh: connect to host 138.x.x.x port 22: Connection refused

Backup failed!
```

### Alert su Fallimento

**Setup notifiche email** (opzionale):

```bash
# Modifica weekly-backup.sh
# Aggiungi alla fine:

if [ $? -ne 0 ]; then
  echo "Backup failed! Check logs." | \
    mail -s "Nextcloud Backup Failed" your@email.com
fi
```

---

## 🛡️ Best Practices

### 1. Verifica Regolare

```bash
# Ogni lunedì mattina (dopo backup domenica):
ls -lh ~/nextcloud-backups/
ls -lh ~/nextcloud-exports/latest/

# Controlla dimensioni (devono crescere nel tempo)
du -sh ~/nextcloud-backups/
du -sh ~/nextcloud-exports/
```

### 2. Test Restore Periodico

**Ogni 1-2 mesi:**

```bash
# Test restore di un singolo file
cd ~/nextcloud-exports/latest/calendars/
# Prova ad importare un calendario su Google Calendar

# Test Borg restore (su istanza test)
# Vedi docs/06-BACKUP-RESTORE.md
```

### 3. Spazio Disco

**Monitor utilizzo:**

```bash
# Spazio disponibile
df -h ~

# Dimensione backup nel tempo
du -sh ~/nextcloud-backups/
du -sh ~/nextcloud-exports/
```

**Pulizia vecchi backup** (se necessario):

```bash
# Mantieni solo ultimi 4 backup settimanali (1 mese)
cd ~/nextcloud-backups/
ls -t | tail -n +5 | xargs rm -rf

# Mantieni solo ultimi 4 export
cd ~/nextcloud-exports/
ls -dt */ | tail -n +5 | xargs rm -rf
```

### 4. Backup del Backup

**Considera:**

- ✅ Hard disk esterno (copia periodica manuale)
- ✅ Cloud storage (Google Drive, Dropbox) per export
- ✅ NAS domestico (se disponibile)

---

## 🔧 Troubleshooting

### Cron non esegue lo script

**Verifica cron service:**

```bash
systemctl status crond

# Se inactive:
sudo systemctl start crond
sudo systemctl enable crond
```

**Verifica crontab:**

```bash
crontab -l
# Deve mostrare: 0 22 * * 0 /path/to/weekly-backup.sh ...
```

**Verifica permessi script:**

```bash
ls -l scripts/weekly-backup.sh
# Deve essere: -rwxr-xr-x (executable)

chmod +x scripts/weekly-backup.sh
```

### Script fallisce in cron ma funziona manualmente

**Problema comune**: PATH environment diverso in cron.

**Soluzione**: Usa path assoluti nello script:

```bash
# weekly-backup.sh
#!/bin/bash

# Path assoluti
SCRIPT_DIR="/home/pandagan/Projects/nextcloud-oci-terraform/scripts"
$SCRIPT_DIR/download-backup.sh
$SCRIPT_DIR/export-data.sh
```

### PC spento durante l'esecuzione

**Problema**: Se il PC è spento domenica 22:00, backup salta.

**Soluzione 1**: Esegui manualmente lunedì mattina:

```bash
./scripts/weekly-backup.sh
```

**Soluzione 2**: Setup `anacron` (esegue job persi):

```bash
sudo dnf install cronie-anacron
# anacron esegue job persi al prossimo avvio
```

### Backup troppo lenti

**Ottimizzazione rsync:**

```bash
# Aggiungi flag a download-backup.sh:
rsync -avzh --progress \
  --compress-level=6 \       # Più compressione
  --partial \                # Riprendi se interrotto
  --bwlimit=5000 \          # Limita bandwidth (KB/s)
  ...
```

---

## 📈 Metriche & Monitoring

### Dashboard Manuale (esempio)

Crea file `~/backup-status.sh`:

```bash
#!/bin/bash
echo "=== Nextcloud Backup Status ==="
echo ""

# Ultimo backup
echo "Last backup:"
ls -lt ~/nextcloud-backups/ | head -2

echo ""
echo "Last export:"
ls -lt ~/nextcloud-exports/ | head -2

echo ""
echo "Disk usage:"
echo "Borg:    $(du -sh ~/nextcloud-backups/ | cut -f1)"
echo "Exports: $(du -sh ~/nextcloud-exports/ | cut -f1)"

echo ""
echo "Next scheduled backup: Sunday 22:00"
echo "Cron status: $(systemctl is-active crond)"
```

**Uso:**

```bash
chmod +x ~/backup-status.sh
~/backup-status.sh
```

---

## 🔮 Future Enhancements

### Backup su Cloud Storage

**Esempio: Google Drive con rclone**

```bash
# Install rclone
sudo dnf install rclone

# Configure Google Drive
rclone config

# Add to weekly-backup.sh:
rclone sync ~/nextcloud-exports/latest/ gdrive:nextcloud-backups/
```

### Multiple Backup Destinations

```bash
# weekly-backup.sh
# Aggiungi copie multiple:

# 1. PC locale (primario)
./download-backup.sh

# 2. NAS domestico
rsync -avzh ~/nextcloud-backups/ /mnt/nas/backups/

# 3. Cloud storage
rclone sync ~/nextcloud-exports/ gdrive:backups/
```

### Alert Telegram/Slack

```bash
# Notifica successo/fallimento via Telegram
curl -X POST \
  "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d "chat_id=<CHAT_ID>&text=Backup completed successfully!"
```

---

## ✅ Checklist Setup

- [x] Script `weekly-backup.sh` testato manualmente
- [x] Script `download-backup.sh` funziona
- [x] Script `export-data.sh` funziona
- [x] Cron job configurato (`crontab -l`)
- [x] Cron service attivo (`systemctl status crond`)
- [ ] Test primo backup domenica 10 Nov (da verificare)
- [ ] Setup monitoring/alert (opzionale)
- [ ] Test restore da backup (consigliato)

---

## 📚 Risorse

- **Script directory**: `scripts/`
- **Log file**: `/tmp/nextcloud-backup.log`
- **Backup Borg**: `~/nextcloud-backups/`
- **Export data**: `~/nextcloud-exports/`
- **Cron info**: `man 5 crontab`
- **Guida disaster recovery**: `docs/06-BACKUP-RESTORE.md`

---

_Last updated: 8 November 2025_
