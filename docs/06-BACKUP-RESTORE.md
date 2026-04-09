# Backup & Restore Guide

Guida completa per backup e disaster recovery di Nextcloud AIO.

## 📋 Overview

### Strategia 3-2-1 Backup

- **3 copie** dei dati:
  1. Dati originali su Nextcloud (OCI)
  2. Backup locale su OCI (`/mnt/nextcloud-data/borg-backups/` - volume persistente)
  3. Backup offline sul tuo PC (`~/nextcloud-backups/`)

- **2 tipi** di media:
  - SSD OCI (cloud)
  - Disco locale PC

- **1 copia off-site**:
  - PC locale (diversa location fisica)

---

## 🔐 Backup Configuration

### Configurazione attuale

| Parametro       | Valore                                                          |
| --------------- | --------------------------------------------------------------- |
| **Location**    | `/mnt/nextcloud-data/borg-backups/` (volume persistente su OCI) |
| **Frequenza**   | Giornaliera alle 04:00 UTC (05:00 Italia)                       |
| **Retention**   | 7 giorni                                                        |
| **Encryption**  | Sì (password required)                                          |
| **Compression** | Sì                                                              |
| **Tool**        | BorgBackup                                                      |

⚠️ **IMPORTANTE**: I backup sono sul **volume persistente** (`/mnt/nextcloud-data/`), quindi sopravvivono al destroy/recreate dell'istanza compute. Il volume ha `prevent_destroy = true` per protezione totale.

### Cosa viene backuppato

✅ **Incluso**:

- Database PostgreSQL completo
- File utenti (documenti, foto, etc.)
- Configurazioni Nextcloud
- App installate e dati app
- Configurazione mastercontainer AIO

❌ **Escluso**:

- **Video**, **Music**, **Photos** e **Fumetti** (media libraries per Jellyfin/Komga) - spostati in `/mnt/nextcloud-data/media/` come External Storage, fuori dal datadir di Nextcloud
- External storage (se configurato)
- Container images (si riscaricano)
- Logs temporanei

---

## 💾 Download Backup su PC Locale

### Metodo automatico (script)

**Dal tuo PC locale**:

```bash
cd /home/pandagan/Projects/nextcloud-oci-terraform

# Prima esecuzione - scarica tutti i backup
./scripts/download-backup.sh

# Esecuzioni successive - aggiorna solo le differenze
./scripts/download-backup.sh
```

**Lo script**:

- Verifica spazio disponibile
- Mostra dimensione backup remoto
- Usa `rsync` per download efficiente
- Crea file `BACKUP_INFO.txt` con dettagli

**Backup scaricati in**: `~/nextcloud-backups/`

### Metodo manuale (rsync)

```bash
# Crea directory locale
mkdir -p ~/nextcloud-backups

# Download con rsync
rsync -avzh --progress \
  -e "ssh -i ~/.ssh/TUA_CHIAVE" \
  --rsync-path="sudo rsync" \
  ubuntu@YOUR_IP:/mnt/nextcloud-data/borg-backups/ \
  ~/nextcloud-backups/
```

### Frequenza consigliata

- **Settimanale**: Per uso personale normale
- **Dopo modifiche importanti**: Prima di update, cambiamenti config
- **Mensile minimo**: Per sicurezza base

---

## 📤 Export Dati Leggibili

Oltre ai backup Borg (encrypted), puoi esportare i tuoi dati in formati standard leggibili.

### Perché serve l'export?

- ✅ **Portabilità**: File .ics e .vcf importabili ovunque (Google, Apple, Outlook)
- ✅ **Leggibilità**: Puoi aprire e leggere i file senza Borg
- ✅ **Migrazione**: Facile spostamento ad altri servizi
- ✅ **Backup "umano"**: Verifica visiva dei dati

### Export automatico

Lo script `export-data.sh` scarica:

**Calendari** (formato .ics):

- Eventi
- Task/Attività
- Importabili in qualsiasi app calendario

**Contatti** (formato .vcf):

- Tutti i contatti in un unico file
- Importabile in qualsiasi rubrica

**File list** (file-list.txt):

- Lista file disponibili su Nextcloud
- Per download completo, usa WebDAV o client desktop

### Export manuale

**Dal tuo PC locale**:

```bash
cd /home/pandagan/Projects/nextcloud-oci-terraform

# Export dati
./scripts/export-data.sh
```

**Cosa viene creato**:

```
~/nextcloud-exports/
├── 20251107_200342/           # Export con timestamp
│   ├── calendars/
│   │   ├── personal.ics
│   │   ├── work.ics
│   │   └── ...
│   ├── contacts/
│   │   └── all-contacts.vcf
│   ├── files/
│   │   └── file-list.txt
│   └── README.md             # Istruzioni import
└── latest -> 20251107_200342/ # Symlink all'ultimo
```

### Import dati esportati

**Calendari (.ics)**:

- Google Calendar: Settings → Import & Export → Import
- Apple Calendar: File → Import
- Outlook: File → Open & Export → Import/Export

**Contatti (.vcf)**:

- Google Contacts: Import
- Apple Contacts: File → Import
- Outlook: File → Open & Export → Import/Export

**Files**:

- WebDAV: `https://your-domain.example.com/remote.php/dav/files/USERNAME/`
- Desktop client: <https://nextcloud.com/install/#install-clients>

---

## 🔄 Restore da Backup

### Prerequisiti

1. **Password backup** (salvata in password manager)
2. **Accesso SSH** all'istanza OCI
3. **Borg installato** (già incluso in AIO)

### Scenario A: Restore via Interfaccia AIO (consigliato)

**Se l'istanza OCI è ancora accessibile**:

1. Accedi a `https://YOUR_IP:8080` (AIO interface)

2. Sezione **"Backup and restore"**

3. Click **"Restore from backup"**

4. Seleziona backup da ripristinare (lista date)

5. Inserisci **password backup**

6. Conferma restore

7. **Aspetta**: Container verranno fermati, dati ripristinati, container riavviati (~10-20 min)

### Scenario B: Restore manuale da riga di comando

**Se l'interfaccia AIO non è disponibile**:

```bash
# Sull'istanza OCI via SSH
cd /mnt/nextcloud-data/borg-backups

# Lista backup disponibili
sudo borg list .

# Output esempio:
# nextcloud-aio_20251107-190000  Wed, 2025-11-07 19:00:00
# nextcloud-aio_20251106-040000  Tue, 2025-11-06 04:00:00

# Restore specifico backup
sudo borg extract ::nextcloud-aio_20251107-190000

# Ti chiederà la password backup
```

### Scenario C: Disaster Recovery completo

**Se l'istanza OCI è distrutta**:

1. **Crea nuova istanza OCI** (stesso setup)

2. **Deploy Nextcloud AIO** (seguendo docs/05-CADDY-REVERSE-PROXY.md)

3. **Carica backup** dal PC locale all'istanza:

   ```bash
   rsync -avzh ~/nextcloud-backups/ \
     ubuntu@NEW_IP:/mnt/nextcloud-data/borg-backups/
   ```

4. **Restore** via interfaccia AIO (Scenario A)

---

## 🧪 Test Restore (Raccomandato)

### Test restore parziale

**Per verificare che i backup funzionino senza sovrascrivere**:

```bash
# Sull'istanza OCI
cd /tmp

# Crea directory test
mkdir restore-test

# Extract solo alcuni file dal backup
sudo borg extract /mnt/nextcloud-data/borg-backups::BACKUP_NAME \
  --strip-components 3 \
  path/to/specific/file
```

### Test restore completo (ATTENZIONE!)

⚠️ **SOVRASCRIVE TUTTO!** Fai solo se sicuro.

Usa interfaccia AIO → "Restore from backup" → Seleziona backup precedente.

---

## 📊 Monitoring Backup

### Verifica backup giornalieri

**Sull'istanza OCI**:

```bash
# Lista backup
sudo borg list /mnt/nextcloud-data/borg-backups/

# Info ultimo backup
sudo borg info /mnt/nextcloud-data/borg-backups/::BACKUP_NAME

# Verifica integrità
sudo borg check /mnt/nextcloud-data/borg-backups/
```

### Verifica via interfaccia AIO

`https://YOUR_IP:8080` → **Backup and restore**

Dovresti vedere:

- ✅ Data ultimo backup
- ✅ Prossimo backup schedulato
- ✅ Lista backup disponibili

### Alert se backup fallisce

Nextcloud AIO **invia notifica** nell'interfaccia se backup fallisce.

**Setup email alert** (opzionale):

- Settings → Administration → Email server
- Configura SMTP
- Test invio email

---

## 🔐 Gestione Password Backup

### Dove è salvata

1. **Password manager** (Bitwarden, 1Password, etc.)
2. **File `.env` locale** (variabile `NEXTCLOUD_BACKUP_PASSWORD`)
3. **Carta stampata** (in cassaforte)

### Come cambiarla (se necessario)

⚠️ **Attenzione**: Cambiare password invalida backup precedenti!

1. AIO interface → Backup section
2. "Change backup password"
3. **PRIMA** esegui backup con vecchia password
4. **POI** cambia password
5. **SALVA** nuova password ovunque

---

## 💡 Best Practices

### Backup

- ✅ **Test restore** almeno una volta al mese
- ✅ **Download locale** settimanale
- ✅ **Verifica integrità** mensile: `borg check`
- ✅ **Documenta restore procedure** (questo file!)
- ✅ **Multiple copie password** (3 posti diversi)

### Disaster Recovery

- ✅ **Documenta configurazione** OCI (Security Lists, VCN, etc.)
- ✅ **Tieni copie** di `docker-compose.yml` e `Caddyfile`
- ✅ **Salva** credenziali dominio, email SMTP, etc.
- ✅ **Test restore** su istanza test (se possibile)

### Retention

**Configurazione Implementata** ✅

Il sistema di retention automatica è configurato con:

- **Daily**: ultimi 7 giorni
- **Weekly**: ultime 4 settimane
- **Monthly**: ultimi 6 mesi

**Come Funziona:**

1. **Backup automatici**: Nextcloud AIO crea backup ogni giorno alle **04:00 UTC**
2. **Pruning automatico**: Script esegue pulizia ogni **lunedì alle 06:00 UTC**
3. **Policy applicata**: `borg prune --keep-daily=7 --keep-weekly=4 --keep-monthly=6`

**Script di Pruning:**

Lo script `/usr/local/bin/borg-prune.sh` viene eseguito automaticamente via cronjob:

```bash
# Cronjob configurato in root crontab
0 6 * * 1 /usr/local/bin/borg-prune.sh
```

**Verifica Pruning:**

```bash
# Sul server - visualizza log pruning
sudo tail -50 /var/log/borg-prune.log

# Verifica cronjob attivo
sudo crontab -l | grep borg

# Test manuale script
sudo /usr/local/bin/borg-prune.sh
```

**Modifica Retention Policy:**

Se vuoi cambiare la retention (es: 14 giorni invece di 7):

```bash
# Sul server - modifica lo script
sudo nano /usr/local/bin/borg-prune.sh

# Cambia i valori:
# --keep-daily=14    # invece di 7
# --keep-weekly=8    # invece di 4
# --keep-monthly=12  # invece di 6
```

**Statistiche Repository:**

```bash
# Verifica spazio occupato e efficienza
sudo -E borg info /mnt/nextcloud-data/borg-backups/borg

# Lista backup attuali
sudo -E borg list /mnt/nextcloud-data/borg-backups/borg
```

⚠️ **Nota**: La password Borg è salvata in `/home/ubuntu/nextcloud/.env` (protetto con permessi 600).

---

## 🚨 Troubleshooting

### Backup fails

**Errore: Not enough space**

```bash
# Verifica spazio
df -h /mnt/backup

# Elimina backup vecchi manualmente
sudo borg delete /mnt/nextcloud-data/borg-backups/::OLD_BACKUP_NAME
```

**Errore: Password incorrect**

Verifica password salvata:

- Controlla in `.env` file
- Controlla password manager
- Se persa: **NON puoi recuperare backup**

### Restore fails

**Errore: Archive not found**

```bash
# Lista backup disponibili
sudo borg list /mnt/nextcloud-data/borg-backups/

# Usa nome esatto dall'output
```

**Errore: Corruption detected**

```bash
# Verifica integrità
sudo borg check /mnt/nextcloud-data/borg-backups/

# Repair se possibile
sudo borg check --repair /mnt/nextcloud-data/borg-backups/
```

---

## 📚 Comandi Utili

```bash
# Lista tutti i backup
sudo borg list /mnt/nextcloud-data/borg-backups/

# Info dettagliate backup
sudo borg info /mnt/nextcloud-data/borg-backups/::BACKUP_NAME

# Verifica integrità
sudo borg check /mnt/nextcloud-data/borg-backups/

# Lista file in backup
sudo borg list /mnt/nextcloud-data/borg-backups/::BACKUP_NAME

# Cerca file specifico
sudo borg list /mnt/nextcloud-data/borg-backups/::BACKUP_NAME | grep "filename"

# Estrai singolo file
sudo borg extract /mnt/nextcloud-data/borg-backups/::BACKUP_NAME path/to/file

# Dimensione repository
sudo borg info /mnt/nextcloud-data/borg-backups/ | grep "All archives"

# Elimina backup vecchio
sudo borg delete /mnt/nextcloud-data/borg-backups/::BACKUP_NAME

# Compatta repository (recupera spazio)
sudo borg compact /mnt/nextcloud-data/borg-backups/
```

---

## 🔮 Future Enhancements

### Backup remoto cloud (pianificato)

**BorgBase** (10GB gratis):

1. Crea account su <https://www.borgbase.com>
2. Crea repository
3. Configura in AIO → Remote borg repo
4. Dual backup: locale + cloud

**Alternative**:

- Backblaze B2 (economico, $0.005/GB)
- Google Drive + rclone
- Rsync.net (professionale)

### Automation

**✅ Backup settimanale automatico implementato!**

Abbiamo creato un sistema completo che combina:

1. **Download Borg backup** (sistema completo, encrypted)
2. **Export dati leggibili** (calendari .ics, contatti .vcf)

**Setup automatico con script**:

```bash
cd /home/pandagan/Projects/nextcloud-oci-terraform

# Setup cron job (una tantum)
./scripts/setup-cron.sh
```

Lo script configura automaticamente:

- Backup ogni **domenica alle 22:00**
- Log in `/tmp/nextcloud-backup.log`
- Esegue sia download Borg che export dati

**Setup manuale crontab**:

```bash
# Aggiungi al crontab
crontab -e

# Aggiungi questa riga:
0 22 * * 0 /home/pandagan/Projects/nextcloud-oci-terraform/scripts/weekly-backup.sh >> /tmp/nextcloud-backup.log 2>&1
```

**Test manuale**:

```bash
# Esegui backup manualmente
./scripts/weekly-backup.sh

# Visualizza log
tail -f /tmp/nextcloud-backup.log
```

**Cosa viene creato**:

- `~/nextcloud-backups/` - Borg backup completi (encrypted)
- `~/nextcloud-exports/YYYYMMDD_HHMMSS/` - Export leggibili per data
- `~/nextcloud-exports/latest` - Symlink all'ultimo export

**Verifica cron attivo**:

```bash
# Lista cron jobs
crontab -l

# Verifica servizio cron
systemctl status cron
```

---

## 📞 Emergency Contacts

In caso di disaster recovery:

1. **Questo repository**: <https://github.com/Pandagan-85/nextcloud-oci-terraform>
2. **Documentazione Nextcloud AIO**: <https://github.com/nextcloud/all-in-one>
3. **BorgBackup docs**: <https://borgbackup.readthedocs.io>

---

_Last updated: November 2025_
