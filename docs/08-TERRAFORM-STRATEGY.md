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

# 5. Update DNS
# Update DNS A record to point to NEW_IP

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
# Accedi a GREEN AIO via SSH tunnel o Tailscale, verifica tutto OK

# 3. Switch DNS da BLUE a GREEN
# Update DNS A record to point to GREEN_IP

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
1. Tentano connessione: your-domain.example.com
2. DNS risolve nuovo IP (aggiornare record A)
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
domain = "secret-token"
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

## 🧪 Disaster Recovery: Procedura Testata

**Data test**: 10 Novembre 2025
**Obiettivo**: Verificare deploy completo con monitoring stack via cloud-init automation

### Pre-requisiti

1. ✅ Repository GitHub aggiornata con:

   - docker-compose.yml (con monitoring stack)
   - Cloud-init che clona repo automaticamente
   - Fix critici (GRAFANA_ADMIN_PASSWORD con `$`)

2. ✅ Certificati SSL: awareness rate limit Let's Encrypt (5/settimana)

### Procedura Step-by-Step

#### 1. Destroy Istanza (Preserva Dati)

```bash
cd terraform/

# Destroy SOLO istanza VM (non volume dati!)
terraform destroy -var-file=prod.tfvars \
  -target=oci_core_instance.nextcloud \
  -target=oci_core_volume_attachment.nextcloud_data

# Conferma: yes
```

**Risultato:**

- ❌ VM distrutta
- ❌ Boot volume eliminato
- ✅ **Data volume PRESERVATO** (prevent_destroy)
  - Database PostgreSQL intatto
  - File utenti intatti
  - Configurazioni Nextcloud intatte
  - Backup Borg preservati

**Tempo:** ~2-3 minuti

#### 2. Apply - Ricrea Infrastruttura

```bash
# Ricrea VM + riattacca volume dati
terraform apply -var-file=prod.tfvars

# Conferma: yes
```

**Cloud-init Automation (eseguito automaticamente):**

```bash
# 1. System setup
- Update packages
- Install Docker, UFW, Fail2ban
- Configure firewall rules

# 2. Storage setup
- Mount data volume (/mnt/nextcloud-data)
- Verify data integrity

# 3. Repository automation (NUOVO!)
- git clone https://github.com/user/nextcloud-oci-terraform.git
- Copia docker-compose.yml (con monitoring!)
- Copia Caddyfile + monitoring configs
- Genera Caddyfile con dominio corretto
- Crea /home/ubuntu/SETUP-NEXTCLOUD.txt

# 4. Container deployment
- docker compose up -d
  → nextcloud-aio-mastercontainer
  → caddy-reverse-proxy
  → prometheus ✨
  → grafana ✨
  → node-exporter ✨
  → cadvisor ✨

# 5. Completion
- File reminder con istruzioni post-deploy
```

**Tempo:** ~5-7 minuti

#### 2.5. Monitoraggio Cloud-init (Durante Apply)

Mentre cloud-init esegue, monitora i progressi in tempo reale:

```bash
# Ottieni IP dalla output Terraform
NEW_IP=$(terraform output -raw public_ip)

# SSH al server (potrebbe richiedere 1-2 min dopo apply)
ssh ubuntu@$NEW_IP

# Monitora cloud-init in tempo reale
tail -f /var/log/cloud-init-output.log

# Dovresti vedere progressivamente:
# → Installing Docker
# → Cloning Nextcloud configuration repository
# → Deploying Nextcloud AIO + Caddy
# → Cloud-init setup complete

# Quando vedi "Cloud-init setup complete", premi CTRL+C
```

**Comandi Diagnostici Cloud-init:**

```bash
# Status cloud-init
cloud-init status

# Output dovrebbe essere:
# status: done

# Se mostra "running": aspetta che finisca
# Se mostra "error": vedi debug sotto

# Verifica timing
cloud-init analyze show

# Output mostra tempo per ogni stage:
# Finished stage: (modules-config) 245.32 seconds
# Finished stage: (modules-final) 12.45 seconds

# Log completo (se problemi)
sudo cat /var/log/cloud-init-output.log | less

# Cerca errori specifici
sudo cat /var/log/cloud-init-output.log | grep -i "error\|fail\|fatal"

# Cerca le nostre azioni (dovrebbe mostrare "===...")
sudo cat /var/log/cloud-init-output.log | grep "==="

# Output atteso:
# === Starting cloud-init setup ===
# === DNS configured ===
# === Configuring UFW firewall ===
# === Installing Docker ===
# === Cloning Nextcloud configuration repository ===
# === Deploying Nextcloud AIO + Caddy ===
# === Cloud-init setup complete ===
```

**Verifica Deploy Automatico:**

```bash
# 1. Docker installato?
docker --version
# Output: Docker version 28.x.x

# 2. Repository clonata?
ls -la /home/ubuntu/nextcloud/
# Dovresti vedere:
# - docker-compose.yml
# - Caddyfile
# - monitoring/
# - .env

# 3. Monitoring files presenti?
ls -la /home/ubuntu/nextcloud/monitoring/
# Dovresti vedere:
# - prometheus.yml
# - grafana/provisioning/...
# - README.md

# 4. Caddyfile generato con dominio corretto?
grep "your-domain.example.com" /home/ubuntu/nextcloud/Caddyfile
# Deve mostrare il TUO dominio (non YOUR_DOMAIN)

# 5. File reminder creato?
cat /home/ubuntu/SETUP-NEXTCLOUD.txt
# Mostra istruzioni post-deployment

# 6. Container avviati?
docker ps

# Dovresti vedere (potrebbe richiedere 1-2 min per pull immagini):
# - nextcloud-aio-mastercontainer
# - caddy-reverse-proxy
# - prometheus
# - grafana
# - node-exporter
# - cadvisor

# Se alcuni container mancano, vedi troubleshooting sotto
```

**Se Container Non Sono Running:**

```bash
# Controlla se docker-compose ha avuto problemi
docker compose -f /home/ubuntu/nextcloud/docker-compose.yml ps -a

# Vedi log dei container
docker compose -f /home/ubuntu/nextcloud/docker-compose.yml logs

# Riavvia manualmente se necessario
cd /home/ubuntu/nextcloud
docker compose up -d

# Verifica di nuovo
docker ps
```

#### 3. Post-Deployment Configuration

```bash
# 1. SSH al server
NEW_IP=$(terraform output -raw public_ip)
ssh ubuntu@$NEW_IP

# 2. Verifica deploy completo
docker ps
# Dovrebbe mostrare tutti i container (Nextcloud + monitoring)

# 3. Configura password Grafana
cd /home/ubuntu/nextcloud
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 32)
echo "GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD" >> .env
echo "Password Grafana: $GRAFANA_ADMIN_PASSWORD"  # Salvala!

# 4. Restart Grafana
docker compose restart grafana

# 5. Verifica configurazione
docker inspect grafana | grep GF_SECURITY_ADMIN_PASSWORD
# Deve mostrare: "GF_SECURITY_ADMIN_PASSWORD=<tua-password>"

# se non mostra la password
# Ricrea container
docker compose down grafana
docker compose up -d grafana

# 6. Verifica Prometheus raccoglie metriche
curl -s http://localhost:9090/-/healthy
# Output: Prometheus Server is Healthy.

# 7. Verifica targets Prometheus
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"'
# Output dovrebbe mostrare:
# prometheus: up
# node-exporter: up
# cadvisor: up
# caddy: down (normale, porta metrics non abilitata)

# 8. Verifica Grafana health
curl -s http://localhost:3000/api/health | jq
# Output: {"database":"ok","version":"..."}
```

**Tempo:** ~2 minuti

**Verifica Network e DNS:**

```bash
# 1. Verifica risoluzione DNS
dig your-domain.example.com +short
# Deve mostrare IP pubblico del server

# NOTA: monitoring non ha più un sottodominio pubblico,
# si accede via Tailscale Serve (https://tailscale-hostname:3000)

# 2. Verifica porte aperte (UFW)
sudo ufw status
# Deve mostrare:
# 22/tcp    ALLOW    (SSH)
# 80/tcp    ALLOW    (HTTP)
# 443/tcp   ALLOW    (HTTPS)
# NOTA: 8080/8443 NON devono essere presenti (AIO solo localhost)

# 3. Verifica container networks
docker network ls
# Deve mostrare:
# nextcloud-aio
# monitoring

# 4. Verifica Grafana funziona
curl -s http://localhost:3000/api/health
# Output: {"database":"ok",...}

# 5. Test connessione Grafana (via Tailscale Serve)
# https://tailscale-hostname:3000
# Deve mostrare pagina login Grafana

# 6. Verifica SSL certificate
openssl s_client -connect your-domain.example.com:443 -servername your-domain.example.com < /dev/null 2>/dev/null | grep "subject="
# Se staging: subject=CN=Fake LE Intermediate X1
# Se production: subject=CN=R3 (Let's Encrypt)
```

**Verifica Volume Dati Preservato:**

```bash
# 1. Verifica mount point
df -h /mnt/nextcloud-data
# Deve mostrare 150GB volume

# 2. Verifica dati Nextcloud esistenti
ls -lh /mnt/nextcloud-data/nextcloud-data/
# Dovresti vedere directory esistenti se avevi dati

# 3. Verifica backup preservati
ls -lh /mnt/nextcloud-data/borg-backups/
# Dovresti vedere backup precedenti

# 4. Verifica ownership
ls -ld /mnt/nextcloud-data
# Deve mostrare: drwxr-xr-x ubuntu ubuntu

# 5. Verifica spazio disponibile
du -sh /mnt/nextcloud-data/*
# Mostra utilizzo per directory
```

#### 4. Accesso Servizi

```bash
# Nextcloud AIO (setup wizard se prima volta)
# Via Tailscale: https://tailscale-hostname:8443
# Via SSH tunnel: ssh -L 8080:localhost:8080 ubuntu@<ip>

# Nextcloud (dopo setup AIO)
https://your-domain.example.com

# Grafana Monitoring (via Tailscale Serve)
# https://tailscale-hostname:3000
# Username: admin
# Password: da step 3
```

#### 5. Import Dashboard Grafana

```bash
# In Grafana UI:
# 1. ☰ → Dashboards → Import
# 2. Dashboard ID: 179 → Load → Import
#    (Docker Container Metrics)
# 3. Dashboard ID: 11074 → Load → Import
#    (Node Exporter System Metrics)
```

### Risultati Test

✅ **Successo Completo:**

- Istanza ricreata in ~10 minuti totali
- Dati Nextcloud 100% preservati (zero data loss)
- Monitoring stack deployato automaticamente
- Cloud-init automation funzionante
- Repository GitHub come single source of truth

### Troubleshooting Comuni

#### Problema 1: Certificati SSL Rate Limit

**Sintomo:**

```
HTTP 429 rateLimited - too many certificates (5) already issued
retry after 2025-11-11 20:04:07 UTC
```

**Causa:** Let's Encrypt limita a 5 certificati/settimana per dominio

**Soluzione Temporanea (Staging):**

```bash
# Modifica Caddyfile
nano /home/ubuntu/nextcloud/Caddyfile

# Aggiungi in CIMA:
{
    acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

# Restart Caddy
docker compose restart caddy

docker compose restart caddy-reverse-proxy

# Monitora i log (dovrebbe ottenere cert validi in ~30 sec)


docker logs -f caddy-reverse-proxy

```

**Staging:**

- ✅ Rate limit altissimi
- ❌ Certificato "non fidato" (warning browser)
- ✅ Funziona per test

**Soluzione Definitiva:** Aspetta scadenza rate limit (~7 giorni)

#### Problema 2: Cloud-init Non Esegue Comandi

**Sintomo:**

```
docker: command not found
ls /home/ubuntu/nextcloud/ → directory vuota
```

**Causa:** Sintassi cloud-config non valida

**Debug:**

```bash
# Verifica log cloud-init
sudo cat /var/log/cloud-init-output.log | grep "==="

# Se vedi "Unhandled non-multipart userdata":
# → Prima riga DEVE essere: #cloud-config (senza spazio!)
# → Comandi bash NON devono usare - > (folded scalar)
```

**Fix:** Correggi cloud-init.yaml locale, commit, destroy/apply di nuovo

#### Problema 3: Password Grafana Non Funziona

**Sintomo:**

```
docker inspect grafana | grep GRAFANA_ADMIN_PASSWORD
→ "GF_SECURITY_ADMIN_PASSWORD={GRAFANA_ADMIN_PASSWORD}"
                              ^^^^^ Literal, non espanso!
```

**Causa:** Missing `$` in docker-compose.yml

**Fix:**

```bash
cd /home/ubuntu/nextcloud
sed -i 's/{GRAFANA_ADMIN_PASSWORD}/${GRAFANA_ADMIN_PASSWORD}/g' docker-compose.yml
docker compose down grafana && docker compose up -d grafana
```

**Prevenzione:** Verifica fix in repo prima del deploy

### Lessons Learned

1. **Cloud-init Syntax è Critico:**

   - `#cloud-config` (NO spazio dopo #)
   - Comandi bash: usa pipe diretti, NO `- >` folded scalars
   - Testa con `yamllint` MA verifica compatibilità cloud-init

2. **Volume Caddy Non Persiste:**

   - Certificati SSL persi ad ogni destroy
   - Considera: mount caddy_data su block volume per future iterations
   - Oppure: accetta rate limit (rare destroys in production)

3. **Git Clone = Single Source of Truth:**

   - Cloud-init clona repo → sempre aggiornato
   - NO file embedded in cloud-init (maintenance nightmare)
   - Fix locale → commit → destroy/apply = consistent

4. **Test Locale Fondamentale:**

   - `terraform plan` NON testa cloud-init
   - Destroy/apply test environment PRIMA di production
   - Usa staging SSL certs per test infiniti

5. **Separazione Secrets:**
   - Password Grafana NON in cloud-init (security)
   - Configurazione post-deploy manuale accettabile
   - File reminder automatico (.env con istruzioni)

### Metriche Performance

| Operazione              | Tempo       | Downtime Nextcloud  |
| ----------------------- | ----------- | ------------------- |
| Destroy istanza         | 2-3 min     | ✅ Inizia downtime  |
| Apply + cloud-init      | 5-7 min     | ⏳ Continua         |
| Config password Grafana | 2 min       | ❌ Nextcloud già UP |
| **TOTALE**              | **~10 min** | **7-10 min**        |

**Data integrity:** 100% preservata (zero data loss)

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

_Last updated: 11 November 2025_
