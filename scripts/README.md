# Scripts di Backup e Manutenzione

Questa directory contiene tutti gli script per gestire backup, export dati e manutenzione del sistema Nextcloud.

## 📋 Scripts Disponibili

### 🔐 Backup e Export

#### `local-backup-sync.sh` ⭐ **NUOVO - Raccomandato**

Script completo e automatizzato per sincronizzazione backup Borg su PC locale.

```bash
./scripts/local-backup-sync.sh
# O crea link simbolico:
ln -s ~/Projects/nextcloud-oci-terraform/scripts/local-backup-sync.sh ~/bin/nextcloud-backup
nextcloud-backup
```

**Cosa fa:**

- 📥 Sincronizza backup dal server via rsync (solo differenze)
- ✅ Verifica integrità automatica con `borg check`
- 📋 Lista tutti i backup disponibili
- 📊 Mostra statistiche repository (spazio, compressione, deduplica)
- 🎯 Identifica automaticamente backup più recente
- 💾 Opzione estrazione interattiva con gestione directory esistenti
- 🔓 Fix permessi automatico (`chown`)
- 📝 Logging completo delle operazioni
- 🎨 Output colorato e user-friendly

**Modalità disponibili:**

```bash
nextcloud-backup              # Interattivo (sync + chiede estrazione)
nextcloud-backup --sync-only  # Solo sincronizza (per cron)
nextcloud-backup --extract-only  # Solo estrai ultimo
nextcloud-backup --help       # Mostra help completo
```

**Quando usarlo:**

- ✅ Setup automazione backup locale (preferito rispetto a `download-backup.sh`)
- ✅ Sincronizzazione settimanale automatica via cron
- ✅ Download ed estrazione rapida ultimo backup
- ✅ Verifica integrità periodica

**Automazione con cron:**

```bash
# Setup cron per sync settimanale automatico
crontab -e

# Aggiungi:
0 22 * * 0 $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1
```

**Documentazione completa**: `docs/10-LOCAL-BACKUP-MANAGEMENT.md`

**Prerequisiti:**

- `borgbackup` installato: `sudo dnf install borgbackup`
- `BORG_PASSPHRASE` configurata in `~/.bash_profile`
- Accesso SSH al server OCI

---

#### `create-backup.sh`

Crea un backup manuale immediato sul server OCI.

```bash
./scripts/create-backup.sh
# O con download automatico:
./scripts/create-backup.sh --download
```

**Cosa fa:**

- 🎯 Trigger manuale del processo di backup Borg su OCI
- ⏱️ Mostra log iniziali del processo di backup
- 🔄 Opzionale: attende completamento e scarica backup (`--download`)
- ✅ Verifica e riavvia automaticamente i container Nextcloud dopo backup
- 📊 Mostra stato backup e progress
- ⏳ Timeout 20 minuti con controlli ogni 30 secondi

**Quando usarlo:**

- Prima di update importanti di Nextcloud
- Prima di modifiche significative al sistema
- Quando serve backup "su richiesta" fuori dallo scheduling
- Per testare il processo di backup manualmente

**Modalità disponibili:**

```bash
./scripts/create-backup.sh              # Solo crea backup, mostra istruzioni download
./scripts/create-backup.sh --download   # Crea + attende + scarica automaticamente
```

**⚠️ Importante:**

- Il backup richiede 5-15 minuti per completare
- I container Nextcloud vengono fermati durante il backup
- Lo script verifica e riavvia i container automaticamente

---

#### `download-backup.sh` (Legacy - Path Obsoleta)

Scarica i backup Borg dal server OCI al PC locale.

⚠️ **ATTENZIONE**: Questo script usa la vecchia path `/mnt/backup/borg/` che non è più corretta.
La path corretta è `/mnt/nextcloud-data/borg-backups/` (volume persistente).
**Usa invece `local-backup-sync.sh` che è aggiornato e più completo.**

```bash
./scripts/download-backup.sh
```

**Cosa fa:**

- ❌ Scarica backup da `/mnt/backup/borg/` (path OBSOLETA!)
- Salva in `~/nextcloud-backups/` (su PC locale)
- Usa rsync per transfer efficiente (solo differenze)
- Mostra spazio disponibile e dimensione backup
- Crea `BACKUP_INFO.txt` con dettagli

**Quando usarlo:**

- ❌ **NON usare** - Path obsoleta
- ✅ **Usa invece** `local-backup-sync.sh`

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

#### `generate-config.sh`

Genera il Caddyfile da template .env per reverse proxy.

```bash
./scripts/generate-config.sh
```

**Cosa fa:**

- 📄 Genera `docker/Caddyfile` da configurazione .env
- 🌐 Configura reverse proxy per Nextcloud (dominio principale)
- 📊 Configura reverse proxy per Grafana (sottodominio monitoring)
- 🔒 Applica security headers (HSTS, X-Frame-Options, ecc.)
- 📝 Configura logging per accessi
- ⚡ Abilita compressione gzip

**Quando usarlo:**

- Dopo aver modificato `DUCKDNS_DOMAIN` in `.env`
- Quando aggiungi nuovi servizi al reverse proxy
- Per rigenerare Caddyfile dopo modifiche
- Prima del primo deployment

**⚠️ Importante:**

- Richiede `DUCKDNS_DOMAIN` configurato in `.env`
- Aggiungere sottodominio `monitoring.TUODOMINIO` a DuckDNS
- Configurare `GRAFANA_ADMIN_PASSWORD` prima del deployment

---

#### `duckdns-update.sh`

Aggiorna il record DNS di DuckDNS con l'IP del server OCI.

```bash
./scripts/duckdns-update.sh
```

**Cosa fa:**

- 🌐 Aggiorna DNS DuckDNS con IP corrente del server
- ✅ Verifica successo operazione
- 📊 Mostra domain e IP configurati

**Quando usarlo:**

- Dopo deploy Terraform (IP potrebbe cambiare)
- Se l'IP pubblico del server OCI cambia
- Per testare configurazione DuckDNS
- Manualmente se DNS non si aggiorna

**Prerequisiti:**

- `DUCKDNS_DOMAIN` configurato in `.env`
- `DUCKDNS_TOKEN` configurato in `.env`
- `OCI_INSTANCE_IP` configurato in `.env`

---

#### `setup-precommit.sh`

Configura pre-commit hooks per qualità del codice.

```bash
./scripts/setup-precommit.sh
```

**Cosa fa:**

- 🔧 Installa `pre-commit` (Python package)
- 🪝 Configura git hooks automatici
- ✨ Abilita formattazione automatica prima di ogni commit:
  - Terraform formatting (`terraform fmt`)
  - Shell script linting (`shellcheck`)
  - Markdown linting (`markdownlint`)
  - YAML syntax checking
  - Secret detection (`gitleaks`)
  - Trailing whitespace cleanup
- 🧪 Esegue check iniziale su tutti i file

**Quando usarlo:**

- Una volta dopo il clone del repository
- Per mantenere qualità del codice
- Prima di contribuire al progetto

**Prerequisiti:**

- Python 3 installato
- pip3 installato

**Comandi utili:**

```bash
pre-commit run --all-files    # Run manualmente su tutti i file
git commit --no-verify         # Skip hooks (sconsigliato)
```

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

- **⭐ Local Backup Management:** `docs/10-LOCAL-BACKUP-MANAGEMENT.md` (automazione + comandi avanzati)
- **Backup & Restore:** `docs/06-BACKUP-RESTORE.md`
- **Security:** `docs/04-FIREWALL-SECURITY.md`
- **Deployment:** `docs/05-NEXTCLOUD-DEPLOYMENT.md`
- **Terraform Strategy:** `docs/08-TERRAFORM-STRATEGY.md`
- **SSL Production Switch:** `SSL-PRODUCTION-SWITCH.md`

---

## 📜 Lista Completa Scripts

### Backup & Export

- ⭐ `local-backup-sync.sh` - Sync automatico backup Borg + estrazione (raccomandato)
- `create-backup.sh` - Backup manuale on-demand su OCI
- `download-backup.sh` - Download backup Borg da OCI (legacy)
- `export-data.sh` - Export calendari/contatti in formato leggibile
- `weekly-backup.sh` - Wrapper per backup completo settimanale

### Setup & Configurazione

- `setup-cron.sh` - Configura automazione backup settimanali
- `generate-config.sh` - Genera Caddyfile da .env template
- `duckdns-update.sh` - Aggiorna DNS DuckDNS
- `setup-precommit.sh` - Setup git hooks per code quality
- `deploy-nextcloud.sh` - Deployment iniziale Nextcloud AIO
- `ssh-connect.sh` - Connessione SSH rapida al server

---

_Last updated: 11 November 2025_
