# 🗺️ Project Roadmap

Stato avanzamento del progetto Nextcloud su Oracle Cloud Infrastructure.

**Ultimo aggiornamento**: 7 Novembre 2025

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
- [ ] Configurazione 2FA (TOTP) - *Pianificato per setup dispositivi*
- [ ] Setup App Passwords per dispositivi - *Pianificato domani*

### Backup & Disaster Recovery
- [x] Verifica backup automatici abilitati (Borg daily 04:00 UTC)
- [x] Test backup manuale (primo backup 2.6MB)
- [x] **Script download backup locale** (`download-backup.sh`)
- [x] **Script export dati leggibili** (`export-data.sh` - calendari .ics, contatti .vcf)
- [x] **Script backup settimanale automatico** (`weekly-backup.sh`)
- [x] **Setup cron automation** (`setup-cron.sh` - domenica 22:00)
- [x] Documentazione procedura disaster recovery (`docs/06-BACKUP-RESTORE.md`)
- [ ] Test restore completo da backup - *Opzionale*
- [ ] Test disaster recovery completo - *Opzionale*

### Testing & Validation
- [ ] Test sincronizzazione dispositivi (iPad, iPhone) - *Pianificato domani*
- [x] Test desktop client (Fedora) - *In corso*
- [x] Verifica consumo risorse: **~1GB RAM** di 24GB (ottimizzato!)
- [x] Test funzionalità core (Calendar, Contacts, Files)
- [x] Test app Collabora/Office

### Documentation
- [x] Guida backup & restore completa (`docs/06-BACKUP-RESTORE.md`)
- [x] Scripts documentation (`scripts/README.md`)
- [x] Troubleshooting guide integrata
- [x] README principale aggiornato con backup strategy

---

## ⏳ FASE 3: AUTOMATION & IaC - PIANIFICATA

### Terraform Infrastructure as Code
- [ ] Setup Terraform OCI provider
- [ ] Configurazione variabili e secrets
- [ ] Modulo creazione VCN e networking
- [ ] Modulo creazione compute instance
- [ ] Modulo security lists e firewall
- [ ] Modulo storage e volumes
- [ ] Output e data sources
- [ ] Testing e validazione Terraform

### Configuration Management
- [ ] Ansible playbook per system setup (opzionale)
- [ ] Automatizzazione installazione Docker
- [ ] Automatizzazione deploy Nextcloud stack
- [ ] Idempotency testing

### CI/CD Pipeline
- [ ] GitHub Actions workflow per Terraform
- [ ] Terraform plan su PR
- [ ] Terraform apply su merge
- [ ] Automated testing
- [ ] Linting e validation automatica

---

## 🔮 FASE 4: ADVANCED FEATURES - FUTURO

### Monitoring & Observability
- [ ] Prometheus setup per metriche
- [ ] Grafana dashboard
  - [ ] System resources (CPU, RAM, disk)
  - [ ] Docker containers metrics
  - [ ] Nextcloud application metrics
  - [ ] Caddy/SSL metrics
- [ ] Alert manager configuration
- [ ] Log aggregation (opzionale)

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
- [ ] Monitoring base attivo - *FASE 4*

### Portfolio Ready
- [ ] Terraform funzionante e testato
- [ ] CI/CD pipeline attiva
- [ ] Monitoring avanzato
- [ ] Demo/screenshots

### Production Grade (Lungo termine)
- [ ] HA setup
- [ ] Disaster recovery testato
- [ ] Monitoring completo con alerting
- [ ] Security audit completato

---

## 🎯 Next Immediate Actions

### Oggi/Domani
1. **⚠️ CONFIGURARE CRON BACKUP** ⏱️ 2 min
   ```bash
   ./scripts/setup-cron.sh
   ```
   Verifica con: `crontab -l`

2. **Test Nextcloud Desktop Client su Fedora** ⏱️ 15 min
   ```bash
   sudo dnf install nextcloud-client
   ```

3. **Setup dispositivi mobili (iPad/iPhone)** ⏱️ 20 min
   - Configurare CalDAV/CardDAV
   - Abilitare 2FA
   - Creare App Passwords

4. **Test sincronizzazione completa** ⏱️ 10 min

5. **Verifica primo backup automatico** (domenica 22:00)
   ```bash
   tail -f /tmp/nextcloud-backup.log
   ```

### Prossime Settimane (FASE 3)
5. **Terraform automation** - Infrastructure as Code
6. **CI/CD pipeline** - GitHub Actions
7. **Monitoring** - Prometheus + Grafana (FASE 4)

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

---

_Ultimo aggiornamento: 7 Novembre 2025_
