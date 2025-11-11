# 🗺️ Project Roadmap

Stato avanzamento del progetto Nextcloud su Oracle Cloud Infrastructure.

**Ultimo aggiornamento**: 11 Novembre 2025

---

## ✅ FASE 1: INFRASTRUCTURE SETUP - COMPLETATA

### Infrastruttura Base

- [x] Creazione istanza OCI A1.Flex (4 vCPU, 24GB RAM, 100GB storage)
- [x] Configurazione Security Lists OCI (porte 22, 80, 443, 8080)
- [x] Setup SSH con chiavi e script di connessione
- [x] Configurazione DuckDNS per DNS dinamico

### Sistema e Sicurezza Base

- [x] Update sistema Ubuntu 24.04 LTS
- [x] Installazione pacchetti essenziali
- [x] Configurazione UFW firewall
- [x] Setup Fail2ban per protezione SSH
- [x] Configurazione unattended-upgrades

### Docker Stack

- [x] Installazione Docker Engine + Docker Compose
- [x] Configurazione user non-root per Docker
- [x] Setup Caddy reverse proxy
- [x] Configurazione Let's Encrypt SSL automatico
- [x] Deploy Nextcloud AIO con tutti i servizi

### Nextcloud Configuration

- [x] Installazione Nextcloud Hub 25 Autumn
- [x] Configurazione componenti opzionali:
  - [x] Collabora Online (Office editing)
  - [x] Imaginary (image processing)
  - [x] Notify Push (performance)
  - [x] ~~Talk~~ (rimosso - non necessario)
  - [x] ~~Whiteboard~~ (rimosso - non necessario)

### Data Migration

- [x] Creazione utente admin personalizzato
- [x] Import contatti (rubrica.vcf)
- [x] Import calendari (10 calendari .ics)
- [x] Import tasks/attività

### Documentation & Version Control

- [x] Documentazione completa step-by-step (6 guide)
- [x] README professionale con architettura
- [x] Script di deployment e utility
- [x] Repository pubblicato su GitHub

---

## ✅ FASE 2: HARDENING & PRODUCTION READINESS - COMPLETATA

### Security Hardening

- [x] Eliminazione account admin default
- [x] Verifica completa configurazione sicurezza
  - [x] Test SSL/TLS headers (HSTS, X-Frame-Options, X-Content-Type-Options)
  - [x] Audit firewall rules (UFW + OCI Security Lists)
  - [x] Check Fail2ban logs (5 IP bannati, 492 tentativi bloccati)
- [x] Configurazione 2FA (TOTP)
- [x] Setup App Passwords per dispositivi

### Backup & Disaster Recovery

- [x] Verifica backup automatici abilitati (Borg daily 04:00 UTC)
- [x] Test backup manuale (primo backup 2.6MB)
- [x] **Script download backup locale** (`download-backup.sh`)
- [x] **Script export dati leggibili** (`export-data.sh` - calendari .ics, contatti .vcf)
- [x] **Script backup settimanale automatico** (`weekly-backup.sh`)
- [x] **Setup cron automation** (`setup-cron.sh` - domenica 22:00) ✅ **CONFIGURATO**
- [x] **Cron job attivo** (verifica: `crontab -l`)
- [x] Documentazione procedura disaster recovery (`docs/06-BACKUP-RESTORE.md`)
- [ ] Test restore completo da backup - _Opzionale_
- [ ] Test disaster recovery completo - _Opzionale_

### Testing & Validation

- [ ] Test sincronizzazione dispositivi (iPad, iPhone) - _Pianificato domani_
- [x] Test desktop client (Fedora) - _In corso_
- [x] Verifica consumo risorse: **~1GB RAM** di 24GB (ottimizzato!)
- [x] Test funzionalità core (Calendar, Contacts, Files)
- [x] Test app Collabora/Office

### Documentation

- [x] Guida backup & restore completa (`docs/06-BACKUP-RESTORE.md`)
- [x] Scripts documentation (`scripts/README.md`)
- [x] Troubleshooting guide integrata
- [x] README principale aggiornato con backup strategy

---

## ✅ FASE 3: AUTOMATION & IaC - COMPLETATA

### Terraform Infrastructure as Code

- [x] **Setup Terraform OCI provider** (`terraform/provider.tf`)
- [x] **Configurazione variabili** (`terraform/variables.tf`)
- [x] **Modulo creazione VCN e networking** (`terraform/network.tf`)
  - [x] VCN, Internet Gateway, Route Table
  - [x] Public Subnet
  - [x] Security Lists (SSH, HTTP, HTTPS, 8080, 8443)
- [x] **Modulo creazione compute instance** (`terraform/compute.tf`)
  - [x] Ubuntu 24.04 ARM (A1.Flex)
  - [x] Cloud-init bootstrap script
  - [x] Configurazione shape (4 OCPU, 24GB RAM)
- [x] **Modulo storage con persistent volume** (`terraform/storage.tf`)
  - [x] Block Volume separato (150GB per backup Borg)
  - [x] `prevent_destroy = true` per protezione backup
  - [x] Volume attachment automatico
  - [x] **Architettura corretta**: Persistent volume SOLO per backup, dati in volumi Docker standard
- [x] **Output e informazioni** (`terraform/outputs.tf`)
  - [x] Instance info, IPs, URLs
  - [x] SSH command, cost estimate
- [x] **Cloud-init automation completa** (`terraform/cloud-init.yaml`)
  - [x] Docker installation
  - [x] Persistent storage mount per backup
  - [x] UFW + Fail2ban setup
  - [x] DuckDNS auto-update
  - [x] Nextcloud AIO + Caddy auto-deploy
  - [x] **GitHub repository auto-clone** - Configuration sempre aggiornata
  - [x] Monitoring stack auto-deploy (Prometheus + Grafana + Exporters)
- [x] **Multi-environment setup** (`test.tfvars`, `prod.tfvars`)
- [x] **Testing completo su TEST environment**
- [x] **Deploy e test su PROD environment**
- [x] **Validazione destroy/apply cycle** - Backup persistenti ✅
- [x] **Test disaster recovery completo** (3 cicli destroy/apply testati)
  - [x] DNS propagation verificata
  - [x] SSL certificate renewal testato (Let's Encrypt staging)
  - [x] Data persistence confermata (block volume protected)
- [x] **Documentazione Terraform** (`terraform/README.md`, `docs/08-TERRAFORM-STRATEGY.md`)
  - [x] Disaster Recovery procedures documentate
  - [x] Workflow operativi (git pull vs destroy/apply)
  - [x] Troubleshooting completo (SSL rate limit, DNS, cloud-init)

### Configuration Management

- [x] **Automatizzazione installazione Docker** - FATTO via `cloud-init.yaml`
- [x] **Automatizzazione deploy Nextcloud stack** - FATTO via `cloud-init.yaml`
- [x] **Automatizzazione firewall + security** - FATTO (UFW + Fail2ban via cloud-init)
- [x] **Automatizzazione DuckDNS update** - FATTO via cloud-init
- [ ] Ansible playbook per system setup - _Non necessario (cloud-init è sufficiente)_
- [ ] Idempotency testing - _Opzionale_

### CI/CD Pipeline ✅ COMPLETATA

- [x] **GitHub Actions workflow per Terraform** (`ci.yml`)
  - [x] Staged pipeline con 5 stage sequenziali
  - [x] Fast feedback (< 5 min per PR)
  - [x] Parallelizzazione intelligente (security + docker in parallelo)
- [x] **Terraform validation su PR**
  - [x] Format check (`terraform fmt`)
  - [x] Init + Validate
  - [x] tfsec security scanning
  - [x] Trivy IaC vulnerability scanning
- [ ] Terraform apply su merge - _Non implementato by design (deploy manuale)_
- [x] **Automated testing completo**
  - [x] YAML linting (yamllint)
  - [x] Docker Compose validation
  - [x] Markdown linting (markdownlint-cli2)
  - [x] Shell script linting (shellcheck)
  - [x] Secret detection (gitleaks)
  - [x] Custom security checks (privileged containers, socket permissions)
- [x] **Pre-commit hooks** (`.pre-commit-config.yaml`)
  - [x] Setup script (`scripts/setup-precommit.sh`)
  - [x] Auto-format Terraform, Markdown
  - [x] Auto-lint YAML, Shell scripts
  - [x] Secret detection locale
- [x] **Scheduled security scans**
  - [x] Deep security scan (weekly Monday 9:00 UTC)
  - [x] Docker image vulnerability scan (weekly Wednesday 3:00 UTC)
  - [x] SARIF upload to GitHub Security tab
- [x] **PR automation**
  - [x] Auto-labeling by file paths
  - [x] Size labeling (XS/S/M/L/XL)
  - [x] Conventional commits validation (informational)
  - [x] Branch protection rules documented
- [x] **Documentation CI/CD** (`docs/09-CICD-MONITORING.md`)
  - [x] Pipeline architecture diagrams
  - [x] Workflow structure explanation
  - [x] Troubleshooting guide
  - [x] Best practices

---

## ⏳ FASE 4: MONITORING & OBSERVABILITY - IN CORSO

### Monitoring Stack ✅ COMPLETATO

- [x] **Prometheus setup per metriche** (`docker/monitoring/prometheus.yml`)
  - [x] 30 giorni retention
  - [x] Scrape interval 15s
  - [x] Job configuration per tutti i servizi
- [x] **Grafana dashboard** (`docker/docker-compose.yml`)
  - [x] Auto-provisioned Prometheus datasource
  - [x] SSL reverse proxy via Caddy (monitoring.YOUR_DOMAIN.duckdns.org)
  - [x] Password protection configurata
- [x] **Node Exporter** - System metrics
  - [x] CPU, RAM, disk, network
  - [x] Filesystem monitoring
  - [x] System load metrics
- [x] **cAdvisor** - Docker container metrics
  - [x] Container resource usage
  - [x] Per-container CPU/memory/network
  - [x] Docker events tracking
- [x] **Caddy metrics endpoint** (`:2019/metrics`)
  - [x] HTTP request metrics
  - [x] SSL certificate expiry
  - [x] Response times
- [x] **Monitoring network isolation** - Secure by default
  - [x] Prometheus, Grafana, exporters su rete `monitoring`
  - [x] Localhost-only bindings (solo Grafana esposta via HTTPS)
- [x] **Auto-deployment via cloud-init** - Monitoring sempre presente

### Dashboard & Visualization 🚧 IN CORSO

- [x] Grafana accessibile su `https://monitoring.YOUR_DOMAIN.duckdns.org`
- [x] Import dashboard ID 179 (Docker Container & Host Metrics)
- [x] Import dashboard ID 11074 (Node Exporter Full)
- [x] Custom dashboard per Nextcloud-specific metrics
- [x] Dashboard per Caddy reverse proxy metrics

### Alerting & Notifications 📋 PIANIFICATO

- [ ] Alert manager configuration
- [ ] Critical alerts:
  - [ ] Disk space < 20%
  - [ ] Memory usage > 90%
  - [ ] Container down/restarting
  - [ ] SSL certificate expiry < 7 days
- [ ] Notification channels (email, webhook)

### Advanced Observability 🔮 FUTURO

- [ ] Log aggregation (Loki + Promtail)
- [ ] Distributed tracing (opzionale)
- [ ] Application Performance Monitoring

---

## 🔮 FASE 5: ADVANCED FEATURES - FUTURO

### High Availability & Scalability

- [ ] Multi-region backup strategy
- [ ] Database replication (futuro)
- [ ] Load balancing considerations
- [ ] CDN integration (opzionale)

### Additional Services

- [ ] Vaultwarden (password manager)
- [ ] Portainer (Docker GUI management)
- [ ] Uptime Kuma (uptime monitoring)
- [ ] Watchtower (auto-updates container)

### Advanced Security

- [ ] Intrusion detection (OSSEC/Wazuh)
- [ ] Web Application Firewall
- [ ] Regular security audits
- [ ] Penetration testing

---

## 📊 Metriche di Successo

### MVP (Minimum Viable Product) ✅

- [x] Nextcloud accessibile e funzionante
- [x] SSL/HTTPS configurato
- [x] Dati migrati correttamente
- [x] Backup funzionanti

### Production Ready ✅ COMPLETATO

- [x] Security hardening completo
- [x] Backup testati e funzionanti (dual system: Borg + exports)
- [x] Documentazione completa
- [x] **Monitoring base attivo** - Prometheus + Grafana deployati

### Portfolio Ready ✅ COMPLETATO

- [x] Terraform struttura completa (IaC pattern production-grade)
- [x] Terraform testato su deployment reale (test + prod environments)
- [x] **CI/CD pipeline attiva** (GitHub Actions con 3 workflows)
- [x] **Monitoring stack deployato** - Prometheus + Grafana + Exporters
- [x] **Disaster Recovery testato** - 3 cicli destroy/apply completati
- [x] Monitoring dashboards configurati - _In corso_
- [ ] Demo/screenshots - _Opzionale_

### Production Grade (Lungo termine)

- [ ] HA setup
- [x] **Disaster recovery testato** - Funzionante (3 test cycles)
- [ ] Monitoring completo con alerting e dashboards
- [ ] Security audit completato

---

## 🎯 Next Immediate Actions

### ✅ Completato (10-11 Nov 2025)

1. ✅ **Monitoring stack deployato** - Prometheus + Grafana + Node Exporter + cAdvisor
2. ✅ **Cloud-init con GitHub clone** - Configuration auto-update da repo
3. ✅ **Disaster recovery testato** - 3 cicli destroy/apply completati con successo
4. ✅ **DNS wildcard configurato** - monitoring.YOUR_DOMAIN.duckdns.org funzionante
5. ✅ **Documentazione workflow operativi** - git pull vs destroy/apply
6. ✅ **SSL staging configuration** - Let's Encrypt rate limit bypassato
7. ✅ **Grafana password configurata** - Login protetto

### 🚧 In Corso (11 Nov 2025)

1. **Monitoring Dashboards** ⏱️ 30 min

   - [x] Accesso Grafana verificato (`https://monitoring.YOUR_DOMAIN.duckdns.org`)
   - [x] Import Dashboard ID 179 (Docker Container & Host Metrics)
   - [x] Import Dashboard ID 11074 (Node Exporter Full)
   - [x] Verifica metriche Nextcloud, Caddy, containers

2. **SSL Production Certificates** ⏱️ 2 min (martedì 11 Nov 21:04 CET)
   - [ ] Rimuovere staging configuration da Caddyfile (righe 1-3)
   - [ ] Restart Caddy: `docker compose restart caddy-reverse-proxy`
   - [ ] Verifica certificati production: `openssl s_client -connect YOUR_DOMAIN.duckdns.org:443`
   - [ ] Test sync dispositivi mobili (dopo SSL production)

### Prossimi Step (Questa settimana)

3. **Monitoring Alerting** ⏱️ 1-2 ore

   - [ ] Configurare Alertmanager
   - [ ] Alert critici (disk space, memory, containers down)
   - [ ] Notification channels (email/webhook)

4. **Test Sincronizzazione Completo** ⏱️ 30 min

   - [ ] Test CalDAV/CardDAV da iPad/iPhone
   - [ ] Test client desktop Nextcloud
   - [ ] Verifica modifiche calendari/contatti sync bidirezionale

5. **Portfolio Finalization** ⏱️ 1-2 ore
   - [ ] Screenshot monitoring dashboards
   - [ ] Screenshot architettura completa
   - [ ] README update con monitoring stack
   - [ ] Blog post/writeup (opzionale)

### Note Operative

**Stato SSL Certificates:**

- **Attuale**: Let's Encrypt Staging (non trusted, warning browser)
- **Impatto**: Sync dispositivi NON funziona (app Nextcloud rifiutano cert staging)
- **Soluzione**: Rimuovere staging 11 Nov 21:04 CET (quando rate limit scade)
- **Workaround temporaneo**: Accesso solo via browser web (bypass manuale warning)

**Monitoring Access:**

- Grafana: `https://monitoring.YOUR_DOMAIN.duckdns.org` (bypass SSL warning per ora)
- Prometheus: `http://localhost:9090` (SSH tunnel: `ssh -L 9090:localhost:9090 ubuntu@IP`)
- Node Exporter: `http://localhost:9100` (metrics endpoint)
- cAdvisor: `http://localhost:8081` (container stats)
- Caddy metrics: `http://localhost:2019/metrics`

---

## 📝 Note & Decisions

### Scelte architetturali

- **Caddy vs Nginx/Traefik**: Scelto Caddy per SSL automatico e semplicità
- **AIO vs Manual Setup**: AIO per gestione semplificata e best practices integrate
- **PostgreSQL vs MySQL**: PostgreSQL incluso in AIO, migliori performance
- **DuckDNS vs altri**: Gratuito, semplice, integrazione Let's Encrypt

### Container rimossi e perché

- **Talk**: Funzionalità multi-utente non necessaria per uso singolo
- **Whiteboard**: Collaborazione non necessaria
- **ClamAV**: Troppo pesante (1GB RAM), antivirus non essenziale

### Lezioni apprese

- `SKIP_DOMAIN_VALIDATION=true` causa problemi → Usare Caddy come reverse proxy
- Importare calendario e tasks insieme, non separatamente
- OCI Security Lists devono essere configurate PRIMA del deploy
- Backup testing è critico prima di considerare il sistema production-ready
- **Dual backup strategy** (Borg + exports) offre disaster recovery completo + portabilità
- Script bash con `set -e` possono terminare prematuramente in loop → usare `set -u` o error handling
- curl in while loop consuma stdin → usare array o redirect `< /dev/null`

#### Terraform & Infrastructure as Code (Nov 2025)

- **❌ ERRORE CRITICO**: Configurare Docker `data-root` sul volume persistente causa corruzione degli overlay2 layers al destroy/apply
- **✅ ARCHITETTURA CORRETTA**: Volume persistente SOLO per backup Borg, Docker volumes in `/var/lib/docker/volumes` (su boot volume)
- **Pattern "Pets vs Cattle"**: Compute = Cattle (effimero, ricreabile), Data = Pet (persistente, nei backup)
- Nextcloud AIO richiede volumi Docker standard - non modificare posizione con `data-root`
- **Destroy/Apply workflow**: Istanza fresh → Setup AIO manuale → Restore da backup Borg
- Questo è **by design**: disaster recovery richiede restore manuale, ma destroy/apply non dovrebbe essere frequente in production
- `prevent_destroy` sul volume dati previene cancellazione accidentale dei backup
- Cloud-init può auto-deployare container ma NON può restorare dati (richiede AIO interface)

#### CI/CD & GitHub Actions (Nov 2025)

- **Staged Pipeline**: Struttura con stage sequenziali (validation → security/docker parallel → summary) offre feedback rapido e chiaro
- **Fail Fast**: Validation stage prima (< 2 min) evita di eseguire security scan costosi su codice malformato
- **SARIF Upload Permissions**: Workflow che caricano su GitHub Security tab richiedono `security-events: write` permission
- **Markdown Linting Exclusions**: `.terraform/` provider dependencies vanno esclusi con pattern `*/\.terraform/*` (doppio asterisco per nested paths)
- **Pre-commit Hooks**: Testare localmente **prima** del commit riduce drasticamente i cicli di feedback CI/CD
- **Terraform Security**: `tfsec` trova security issues che Terraform validate non rileva (es. public IP, security group rules)
- **Separazione CI/Scheduled**: CI workflow con output `table` per feedback immediato, scheduled workflows con SARIF per tracking lungo termine
- **Testing Locale Prima**: `find . -name "*.md" -not -path "*/\.terraform/*" | xargs markdownlint-cli2` per evitare commit inutili
- **Git History Pulita**: Testare sempre localmente prima di pushare - commit multipli di fix sporcano la repo

---

_Ultimo aggiornamento: 11 Novembre 2025_
