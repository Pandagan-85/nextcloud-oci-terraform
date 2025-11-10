# Scripts di Backup e Manutenzione

Questa directory contiene tutti gli script per gestire backup, export dati e manutenzione del sistema Nextcloud.

## 📋 Scripts Disponibili

### 🔐 Backup e Export

#### `download-backup.sh`

Scarica i backup Borg dal server OCI al PC locale.

```bash
./scripts/download-backup.sh
```

**Cosa fa:**

- Scarica backup Borg encrypted da `/mnt/backup/borg/` (su OCI)
- Salva in `~/nextcloud-backups/` (su PC locale)
- Usa rsync per transfer efficiente (solo differenze)
- Mostra spazio disponibile e dimensione backup
- Crea `BACKUP_INFO.txt` con dettagli

**Quando usarlo:**

- Settimanalmente (automatico con cron)
- Prima di update importanti
- Quando vuoi copia locale dei backup

---

#### `export-data.sh`

Esporta dati Nextcloud in formati leggibili (calendari, contatti).

```bash
./scripts/export-data.sh
```

**Cosa fa:**

- Esporta calendari come file `.ics`
- Esporta contatti come file `.vcf`
- Crea lista file disponibili
- Salva in `~/nextcloud-exports/YYYYMMDD_HHMMSS/`
- Crea symlink `latest` all'ultimo export

**Quando usarlo:**

- Settimanalmente (automatico con cron)
- Prima di migrare ad altro servizio
- Per backup "leggibile" dei dati
- Per import in Google/Apple/Outlook

**⚠️ Importante:** Verifica che nel file `.env` ci sia:

- `NEXTCLOUD_ADMIN_USER=` con il tuo username admin (NON "admin" default!)
- `NEXTCLOUD_ADMIN_PASSWORD=` con la tua password

---

#### `weekly-backup.sh`

Script wrapper che esegue entrambi i backup (Borg + Export).

```bash
./scripts/weekly-backup.sh
```

**Cosa fa:**

1. Esegue `download-backup.sh` (Borg backup)
2. Esegue `export-data.sh` (dati leggibili)
3. Mostra riepilogo e dimensioni
4. Log completo dell'operazione

**Quando usarlo:**

- Automaticamente ogni domenica 22:00 (via cron)
- Manualmente quando vuoi backup completo

---

### ⚙️ Setup e Configurazione

#### `setup-cron.sh`

Configura il cron job per backup automatici settimanali.

```bash
./scripts/setup-cron.sh
```

**Cosa fa:**

- Verifica che gli script esistano
- Aggiunge cron job per domenica 22:00
- Verifica se esiste già (evita duplicati)
- Mostra crontab risultante
- Verifica che il servizio cron sia attivo

**Quando usarlo:**

- Una tantum dopo il setup iniziale
- Se vuoi cambiare orario backup (modifica lo script prima)

---

#### `ssh-connect.sh`

Connessione SSH rapida al server OCI.

```bash
./scripts/ssh-connect.sh
```

**Cosa fa:**

- Carica configurazione da `.env`
- Verifica SSH key permissions
- Connette al server OCI

**Quando usarlo:**

- Quando devi accedere al server
- Per manutenzione
- Per verificare backup remoti

---

#### `deploy-nextcloud.sh`

Script iniziale per deployment Nextcloud AIO (già usato).

```bash
./scripts/deploy-nextcloud.sh
```

**Quando usarlo:**

- Primo deployment (già fatto)
- Reinstallazione completa

---

## 🔄 Workflow Raccomandato

### Setup Iniziale (fatto una volta)

1. Configura `.env` con le tue credenziali:

   ```bash
   cp .env.example .env
   nano .env
   ```

2. Setup cron per backup automatici:

   ```bash
   ./scripts/setup-cron.sh
   ```

3. Test manuale primo backup:

   ```bash
   ./scripts/weekly-backup.sh
   ```

### Uso Normale

**Automatico:**

- Backup settimanale domenica 22:00 (cron)
- Nessun intervento richiesto
- Controlla log: `tail -f /tmp/nextcloud-backup.log`

**Manuale:**

- Backup on-demand: `./scripts/weekly-backup.sh`
- Solo export dati: `./scripts/export-data.sh`
- Solo Borg: `./scripts/download-backup.sh`

### Verifica Backup

```bash
# Verifica cron attivo
crontab -l

# Verifica ultimo backup Borg
ls -lh ~/nextcloud-backups/

# Verifica ultimo export
ls -lh ~/nextcloud-exports/latest/
```

---

## 📁 Directory di Output

```
~/
├── nextcloud-backups/          # Backup Borg (encrypted)
│   ├── config/
│   ├── data/
│   ├── lock.roster
│   ├── README
│   └── BACKUP_INFO.txt
│
└── nextcloud-exports/          # Export leggibili
    ├── 20251107_200342/        # Export con timestamp
    │   ├── calendars/          # File .ics
    │   ├── contacts/           # File .vcf
    │   ├── files/              # File list
    │   └── README.md
    └── latest/                 # → Symlink all'ultimo
```

---

## 🆘 Troubleshooting

### Export fallisce con HTTP 401

**Problema:** Username o password errati.

**Soluzione:**

1. Apri `.env`
2. Verifica `NEXTCLOUD_ADMIN_USER=IL_TUO_USERNAME`
3. Verifica `NEXTCLOUD_ADMIN_PASSWORD=LA_TUA_PASSWORD`
4. NON usare "admin" (account eliminato!)

### Download backup fallisce

**Problema:** Errore SSH o permessi.

**Soluzione:**

1. Verifica connessione: `./scripts/ssh-connect.sh`
2. Verifica path SSH key in `.env`
3. Verifica permessi: `chmod 600 ~/.ssh/TUA_CHIAVE`

### Cron non esegue backup

**Problema:** Cron job non configurato o cron service non attivo.

**Soluzione:**

1. Verifica crontab: `crontab -l`
2. Rimuovi e ricrea: `crontab -e` (cancella riga) poi `./scripts/setup-cron.sh`
3. Verifica cron service: `systemctl status cron`
4. Controlla log: `tail /tmp/nextcloud-backup.log`

### Spazio insufficiente

**Problema:** Disco pieno per backup.

**Soluzione:**

1. Verifica spazio: `df -h ~`
2. Elimina vecchi export: `rm -rf ~/nextcloud-exports/OLD_DATE/`
3. Elimina vecchi Borg: Vedi `docs/06-BACKUP-RESTORE.md`

---

## 📚 Documentazione Completa

Per informazioni dettagliate:

- **Backup & Restore:** `docs/06-BACKUP-RESTORE.md`
- **Security:** `docs/04-FIREWALL-SECURITY.md`
- **Deployment:** `docs/05-NEXTCLOUD-DEPLOYMENT.md`

---

_Last updated: November 2025_
