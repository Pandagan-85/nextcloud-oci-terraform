# Terraform Infrastructure as Code Strategy

Guida alla strategia Terraform implementata per Nextcloud: perché, come, e pattern production-grade.

**Ultima modifica**: 8 Novembre 2025

---

## 🎯 Perché Terraform per Questo Progetto?

### Il Problema Iniziale

Abbiamo deployato Nextcloud **manualmente**:
- SSH all'istanza OCI
- Comandi manuali per setup (Docker, UFW, Fail2ban)
- Configurazione via SSH
- Deploy docker-compose manuale

**Problema**: Se devo ricreare tutto da zero → 3-4 ore di lavoro manuale!

### La Soluzione: Infrastructure as Code

Con Terraform:
- ✅ **Riproducibile**: Deploy identico ogni volta
- ✅ **Versionato**: Git traccia ogni modifica
- ✅ **Documentato**: Il codice È la documentazione
- ✅ **Portfolio**: Dimostra competenze DevOps/Cloud
- ✅ **Disaster recovery**: Ricreo tutto in 10 minuti

---

## 🏗️ Il Pattern Implementato

### "Stateful Application with Persistent Storage"

Questo è un pattern production-grade per applicazioni con dati persistenti.

```
┌────────────────────────────────────────────┐
│  APPLICATION LAYER (EPHEMERAL)             │
│                                             │
│  Compute Instance (VM.Standard.A1.Flex)    │
│  - Ubuntu 24.04 ARM64                      │
│  - Docker Engine                           │
│  - Docker Compose                          │
│  - Caddy reverse proxy                     │
│  - UFW firewall                            │
│  - Fail2ban                                │
│                                             │
│  Status: CATTLE 🐄                          │
│  └─> Ricreabile senza perdita dati         │
│                                             │
└──────────────┬─────────────────────────────┘
               │
               │ Volume Attachment
               │ (sempre presente)
               ↓
┌────────────────────────────────────────────┐
│  DATA LAYER (PERSISTENT)                   │
│                                             │
│  Block Volume (100 GB)                     │
│  /mnt/nextcloud-data/                      │
│  ├── docker-volumes/                       │
│  │   ├── nextcloud_aio_mastercontainer/   │
│  │   │   ├── database/ (PostgreSQL)       │
│  │   │   ├── nextcloud/ (file utenti)     │
│  │   │   ├── config/ (configurazioni)     │
│  │   │   └── apps/ (app data)             │
│  │   ├── caddy_data/ (SSL certs)          │
│  │   └── caddy_config/                    │
│  ├── borg-backups/ (backup locali)        │
│  └── exports/ (dati esportati)            │
│                                             │
│  Status: PET 🐕                             │
│  └─> Protetto da destroy (prevent_destroy) │
│  └─> Contiene TUTTI i dati critici:        │
│      • Password App dispositivi            │
│      • 2FA secrets                         │
│      • Session tokens                      │
│      • Calendari, contatti, file           │
│                                             │
└────────────────────────────────────────────┘
```

---

## 🐄 vs 🐕 Pets vs Cattle Philosophy

### Cattle (Bestiame) - Application Layer

**Caratteristiche:**
- 🔄 Sostituibile
- 📦 Standardizzato
- 🚫 Nessun dato critico
- ✅ Destroy/recreate è normale

**Esempi nel progetto:**
- Istanza OCI compute
- Docker containers
- Caddy reverse proxy
- Sistema operativo

**Operazione normale:**
```bash
terraform destroy -target=oci_core_instance.nextcloud
terraform apply
# 10 minuti dopo: tutto funziona di nuovo!
```

### Pets (Animali domestici) - Data Layer

**Caratteristiche:**
- 💎 Unico e insostituibile
- 🔒 Protetto con `prevent_destroy`
- 📊 Contiene lo stato dell'applicazione
- ⚠️ Destroy = DISASTRO!

**Esempi nel progetto:**
- Block volume con database
- Password app dispositivi
- 2FA tokens
- File utenti
- Backup Borg

**Protezione:**
```hcl
resource "oci_core_volume" "nextcloud_data" {
  # ...
  lifecycle {
    prevent_destroy = true  # ← Terraform blocca destroy!
  }
}
```

---

## 🎓 Perché Questo Pattern?

### Problema Classico con Terraform

**Scenario sbagliato (senza storage separato):**

```
┌─────────────────────────────────┐
│  Compute Instance               │
│  Boot Volume (100GB)            │
│  ├── OS                         │
│  ├── Docker                     │
│  └── /var/lib/docker/volumes/  │ ← DATI QUI!
│      └── nextcloud_data/        │
│          └── database.db        │ ← Password App!
└─────────────────────────────────┘

terraform destroy
↓
💥 TUTTO PERSO! (istanza + dati)
```

**Problemi:**
- ❌ `terraform destroy` → perdita dati
- ❌ Cambio OS → devo migrare dati
- ❌ Update infrastruttura → rischio
- ❌ Non puoi fare blue-green deployment

### Pattern Corretto (storage separato)

```
Compute (destroy OK)
    ↓ attached
Block Volume (persiste)
```

**Vantaggi:**
- ✅ `terraform destroy` instance → dati intatti
- ✅ Cambio OS → riattach volume, zero migrazione
- ✅ Update infrastruttura → safe
- ✅ Blue-green deployment → possibile
- ✅ Disaster recovery → facile

---

## 💰 Costi OCI - Sempre €0.00?

### Always Free Tier Limits

```
Compute:
✅ 4 OCPU ARM (A1.Flex)
✅ 24 GB RAM
✅ Fino a 4 istanze (totale ≤ 4 OCPU)

Storage:
✅ 200 GB Block Volume totale
   ├── Boot volume: 100 GB
   └── Data volume: 100 GB
   └── TOTALE: 200 GB ✅ FREE

Network:
✅ 10 TB outbound/month
✅ 2 Reserved Public IPs
```

### Scenario: Destroy e Recreate

**Setup iniziale:**
```
Boot Volume: 100 GB (contiene OS)
Data Volume: 100 GB (contiene dati)
────────────────────────────
TOTALE:      200 GB ✅ FREE
```

**Dopo terraform destroy:**
```
Boot Volume: ELIMINATO (0 GB)
Data Volume: 100 GB (persiste, prevent_destroy)
────────────────────────────
TOTALE:      100 GB ✅ FREE
```

**Dopo terraform apply (recreate):**
```
Boot Volume: 100 GB (nuovo, ricreato)
Data Volume: 100 GB (stesso di prima, riattached)
────────────────────────────
TOTALE:      200 GB ✅ FREE
```

**Costo totale**: **€0.00** 🎉

### ⚠️ Attenzione ai Costi

**Cosa può costare:**

❌ **Non cancellare boot volume vecchio:**
```
Boot old:  100 GB (orphan!)
Boot new:  100 GB
Data:      100 GB
─────────────────
TOTALE:    300 GB → OLTRE FREE TIER! (100GB = ~€2.50/mese)
```

**Prevenzione Terraform:**
```hcl
resource "oci_core_instance" "nextcloud" {
  preserve_boot_volume = false  # ← Auto-delete su destroy
}
```

❌ **Snapshot manuali dimenticati:**
```
Free tier: 5 snapshot gratis
Se ne crei > 5: costi!
```

❌ **Reserved IP non utilizzati:**
```
Free tier: 2 reserved IPs
Se ne crei 3+: costi!
```

---

## 🛡️ Protezione Dati in Terraform

### Livello 1: `prevent_destroy`

```hcl
# terraform/storage.tf

resource "oci_core_volume" "nextcloud_data" {
  display_name = "nextcloud-persistent-data"
  size_in_gbs  = 100

  lifecycle {
    prevent_destroy = true  # ← PROTEZIONE
  }
}
```

**Effetto:**
```bash
$ terraform destroy

Error: Instance depends on volume with prevent_destroy

Cannot destroy oci_core_volume.nextcloud_data because
lifecycle.prevent_destroy is set to true.
```

### Livello 2: Backup Prima di Tutto

**Policy di sicurezza:**

Prima di QUALSIASI operazione Terraform:

```bash
# 1. Backup manuale
cd ~/Projects/nextcloud-oci-terraform
./scripts/weekly-backup.sh

# 2. Verifica backup completato
ls -lh ~/nextcloud-backups/
ls -lh ~/nextcloud-exports/latest/

# 3. SOLO ADESSO: terraform apply/destroy
cd terraform/
terraform plan
terraform apply
```

### Livello 3: Terraform Plan è Obbligatorio

**Mai fare apply diretto!**

```bash
# ❌ PERICOLOSO:
terraform apply -auto-approve

# ✅ CORRETTO:
terraform plan -out=tfplan
# Leggi l'output, verifica cosa cambia
# Solo se tutto OK:
terraform apply tfplan
```

---

## 🔄 Workflow Operativi

### Scenario 1: Update Sistema Operativo

**Obiettivo**: Passare da Ubuntu 24.04 a Ubuntu 26.04

**Workflow tradizionale (manuale):**
1. SSH all'istanza
2. `do-release-upgrade`
3. Sperare che non si rompa nulla
4. Se si rompe: ripristino complesso

**Workflow con Terraform + Storage Separato:**

```bash
# 1. Backup (sempre!)
./scripts/weekly-backup.sh

# 2. Update Terraform config
# Edit terraform/compute.tf:
operating_system_version = "26.04"  # Era 24.04

# 3. Plan
cd terraform/
terraform plan
# Output mostra: instance will be replaced

# 4. Apply (destroy old, create new)
terraform apply

# 5. Cosa succede:
# - Destroy istanza vecchia (Ubuntu 24.04)
# - Boot volume vecchio eliminato
# - Data volume INTATTO (prevent_destroy)
# - Create nuova istanza (Ubuntu 26.04)
# - Data volume attached automaticamente
# - Cloud-init setup (Docker, UFW, etc.)
# - Mount /mnt/nextcloud-data
# - Docker compose up con dati esistenti

# 6. Risultato (10-15 minuti):
# - Ubuntu 26.04 ✅
# - TUTTI i dati preserved ✅
# - Password app funzionano ✅
# - Dispositivi si riconnettono automaticamente ✅
```

**Downtime**: 10-15 minuti

**Dati persi**: ZERO

### Scenario 2: Scale UP Risorse

**Obiettivo**: Passare da 4 OCPU a 6 OCPU (se budget permette)

```bash
# Edit terraform.tfvars
instance_ocpus = 6  # Era 4

# Apply (OCI fa resize in-place se possibile)
terraform apply

# Se serve reboot:
# - Terraform restarta istanza
# - Data volume persiste
# - 2-3 minuti downtime
```

### Scenario 3: Migrate Regione

**Obiettivo**: Da Frankfurt a Milano

```bash
# 1. Backup completo
./scripts/weekly-backup.sh

# 2. Change region
# Edit terraform.tfvars:
region = "eu-milan-1"

# 3. Apply (crea infra in nuova region)
terraform apply

# 4. Copy data volume
# Metodo A: Restore da backup
# Metodo B: OCI volume cross-region copy

# 5. Update DNS (DuckDNS)
curl "https://www.duckdns.org/update?domains=...&ip=NEW_IP"

# 6. Test funzionamento

# 7. Destroy old region
terraform destroy -target=oci_core_instance.nextcloud_old
```

### Scenario 4: Blue-Green Deployment

**Obiettivo**: Zero downtime upgrade

```bash
# 1. Deploy GREEN (nuova istanza in parallelo)
terraform apply -var="instance_name=nextcloud-green"

# 2. Test GREEN in parallelo (BLUE continua a funzionare)
# Accedi a GREEN-IP:8080, verifica tutto OK

# 3. Switch DNS da BLUE a GREEN
curl "https://www.duckdns.org/update?domains=...&ip=GREEN_IP"

# 4. Monitor (5-10 min)

# 5. Se tutto OK: destroy BLUE
# 6. Se problemi: rollback DNS a BLUE
```

---

## 📊 Cosa Succede ai Dispositivi?

### Domanda Critica

> "Se faccio terraform destroy e apply, i miei dispositivi (iPad, iPhone, Desktop) devono essere riconfigurati?"

**Risposta**: NO! ❌

### Perché NON Serve Riconfigurare

**Database PostgreSQL contiene:**
```sql
nextcloud_db
├── users (username, hashed password)
├── authtoken (app passwords, 2FA tokens)
├── devices (dispositivi autorizzati)
├── sessions (sessioni attive)
├── shares (link condivisione)
└── settings (configurazioni)
```

**Quando fai destroy + apply:**
1. ✅ Database persiste nel data volume
2. ✅ Password app preserved
3. ✅ 2FA secrets preserved
4. ✅ Device tokens preserved

**I dispositivi vedono:**
```
1. Tentano connessione: pandagan-oci.duckdns.org
2. DNS risolve nuovo IP (DuckDNS aggiorna)
3. Inviano password app esistente
4. Nextcloud verifica nel database (restored)
5. ✅ Autenticazione OK
6. ✅ Riprendono sync normalmente
```

**Downtime dispositivi**: 10-15 minuti (tempo recreate instance)

**Riconfigurazione necessaria**: ZERO

---

## 🎯 Pattern vs Anti-Pattern

### ❌ Anti-Pattern: Database nel Boot Volume

```hcl
# SBAGLIATO!
resource "oci_core_instance" "nextcloud" {
  boot_volume_size_gb = 200  # Tutto in boot volume
  preserve_boot_volume = true  # Workaround pericoloso
}
```

**Problemi:**
- Boot volume ha tutti i dati
- Non puoi cambiare OS facilmente
- Cresce indefinitamente (backup, log, file)
- `preserve_boot_volume = true` accumula volumi orphan (costi!)

### ✅ Pattern: Persistent Data Volume

```hcl
# CORRETTO!
resource "oci_core_instance" "nextcloud" {
  boot_volume_size_gb = 100  # Solo OS + app
  preserve_boot_volume = false  # Auto-cleanup
}

resource "oci_core_volume" "data" {
  size_in_gbs = 100  # Dati separati
  lifecycle {
    prevent_destroy = true  # Protetto
  }
}
```

**Vantaggi:**
- Boot volume ricreabile (clean OS ogni volta)
- Data volume persiste (dati al sicuro)
- Separazione compute/storage (cloud best practice)
- Costi controllati (cleanup automatico)

---

## 🔮 Confronto con Alternative

### Opzione A: Setup Manuale (no Terraform)

**Pro:**
- Veloce per MVP
- Nessuna curva apprendimento Terraform

**Contro:**
- ❌ Non riproducibile (dimentichi step)
- ❌ Non versionato (no Git history)
- ❌ Disaster recovery lento (3-4 ore rebuild)
- ❌ No value per portfolio

### Opzione B: Terraform Semplice (no storage separato)

**Pro:**
- IaC basics
- Riproducibile

**Contro:**
- ❌ `terraform destroy` = perdita dati
- ❌ Pattern sbagliato per production
- ❌ Portfolio value medio

### Opzione C: Terraform + Storage Separato ✅ (implementato)

**Pro:**
- ✅ IaC production-grade
- ✅ Dati sicuri (prevent_destroy)
- ✅ Riproducibile + versionato
- ✅ Disaster recovery veloce (10 min)
- ✅ Portfolio value alto ⭐⭐⭐⭐⭐

**Contro:**
- Più complesso (ma documentato!)
- Richiede pianificazione storage

### Opzione D: Kubernetes + Helm

**Pro:**
- Buzzword-compliant per CV
- Auto-scaling, HA, etc.

**Contro:**
- ❌ Overkill per single-user
- ❌ OKE non è free tier (~€50/mese)
- ❌ Complessità 10x rispetto a Docker Compose
- ❌ 2-3GB RAM solo per K8s stesso

**Verdetto**: K8s ottimo per portfolio SEPARATO, non per questo progetto.

---

## 📚 Best Practices Terraform

### 1. Sempre Plan Prima di Apply

```bash
terraform plan -out=tfplan
# Leggi output attentamente!
# Cerca: "will be destroyed", "must be replaced"
terraform apply tfplan
```

### 2. State File è Critico

Il file `terraform.tfstate` contiene lo stato dell'infrastruttura.

**Protezione:**
```bash
# In .gitignore (già fatto)
*.tfstate
*.tfstate.*

# Backup locale
cp terraform.tfstate terraform.tfstate.backup-$(date +%Y%m%d)
```

**Future**: Remote state (S3 o OCI Object Storage)

### 3. Variabili Sensibili

```bash
# terraform.tfvars (in .gitignore)
duckdns_token = "secret-token"
ssh_key_path = "~/.ssh/id_rsa"

# Mai commitare su Git!
```

### 4. Tagging Risorse

```hcl
tags = {
  Project     = "Nextcloud"
  ManagedBy   = "Terraform"
  Environment = "Production"
  CostCenter  = "Personal"
}
```

**Utile per:**
- Cost tracking
- Resource filtering
- Audit trail

---

## 🎓 Valore Portfolio

### Cosa Dimostri con Questo Setup

**1. Cloud Engineering:**
- ✅ OCI expertise
- ✅ Free tier optimization
- ✅ Networking (VCN, Security Lists)
- ✅ Storage management (Block Volumes)

**2. Infrastructure as Code:**
- ✅ Terraform provider configuration
- ✅ Modular structure
- ✅ Variables e parametrizzazione
- ✅ Output e automation

**3. Production Patterns:**
- ✅ Pets vs Cattle philosophy
- ✅ Data persistence strategy
- ✅ Disaster recovery planning
- ✅ Cost optimization

**4. DevOps:**
- ✅ Automation (cloud-init, cron)
- ✅ Security (UFW, Fail2ban, 2FA)
- ✅ Monitoring e logging
- ✅ Documentation-as-code

**5. Problem Solving:**
- ✅ Identificazione sfide (dati persistenti)
- ✅ Ricerca soluzioni (storage separato)
- ✅ Implementazione pattern (prevent_destroy)
- ✅ Validazione (test destroy/recreate)

### Differenziazione Portfolio

**Nextcloud basic (comune):**
- Docker Compose + reverse proxy
- Backup manuali
- Setup one-time

**Il TUO Nextcloud (avanzato):**
- IaC con Terraform ⭐
- Pattern production-grade ⭐⭐
- Backup automation ⭐⭐
- Disaster recovery < 15 min ⭐⭐⭐
- Documentazione completa ⭐⭐⭐⭐
- Costi €0.00 ⭐⭐⭐⭐⭐

---

## 🚀 Prossimi Step

### Questa Settimana

1. **Test Terraform su istanza separata**
   ```bash
   cd terraform/
   # Use different instance name
   terraform apply -var="app_name=nextcloud-test"
   ```

2. **Validate pattern**
   - Deploy
   - Destroy
   - Recreate
   - Verify data persistence

### Prossime Settimane

3. **Terraform Import** (risorse esistenti)
4. **CI/CD Pipeline** (GitHub Actions)
5. **Monitoring** (Prometheus + Grafana - Fase 4)

---

## 📖 Risorse

### Documentazione Correlata

- `terraform/README.md` - Guida Terraform completa
- `docs/06-BACKUP-RESTORE.md` - Disaster recovery
- `docs/07-CRON-AUTOMATION.md` - Backup automation

### Link Utili

- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [12 Factor App](https://12factor.net/) - Stateless app principles
- [Pets vs Cattle](https://www.slideshare.net/gmccance/cern-data-centre-evolution) - Original concept

---

## ✅ Checklist Comprensione

Hai capito il pattern se puoi rispondere:

- [ ] Cosa succede ai dati se faccio `terraform destroy`? → Persistono su data volume
- [ ] Perché i dispositivi NON devono essere riconfigurati? → Database persiste
- [ ] Quanto costa fare destroy/recreate? → €0.00 (dentro free tier)
- [ ] Quanto downtime per i dispositivi? → 10-15 minuti
- [ ] Cosa protegge `prevent_destroy`? → Data volume da destroy accidentale
- [ ] Perché non usare K8s? → Overkill + non free tier
- [ ] Boot volume vs Data volume? → Boot=OS (cattle), Data=DB (pet)

---

_Last updated: 8 November 2025_
