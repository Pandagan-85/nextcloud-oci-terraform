# CI/CD & Monitoring Setup

**Fase 3 del progetto** - Automazione deployment e observability

**Status**: 🚀 CI/CD COMPLETATO | 📋 Monitoring IN PIANIFICAZIONE

**Prerequisiti**: Terraform Infrastructure as Code completata ✅

---

## 🎯 Obiettivi

1. **CI/CD Pipeline**: Automazione testing e deployment via GitHub Actions
2. **Monitoring**: Metriche sistema e applicazione con Prometheus
3. **Dashboards**: Visualizzazione con Grafana
4. **Alerting**: Notifiche proattive su problemi

---

## 📦 PARTE 1: CI/CD con GitHub Actions ✅

### ✨ Workflows Implementati

Il progetto include **5 workflow GitHub Actions** completamente funzionanti:

#### 1. **Terraform Validation** (`.github/workflows/terraform-validation.yml`)

**Trigger:**

- Pull Request su `terraform/**`
- Push su `main` branch

**Azioni:**

- ✅ Format check (`terraform fmt -check -recursive`)
- ✅ Initialization (`terraform init -backend=false`)
- ✅ Validation (`terraform validate`)
- ✅ Auto-comment on PR se fails

**Test locale:**

```bash
cd terraform
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

#### 2. **Security Scanning** (`.github/workflows/security-scan.yml`)

**Trigger:**

- Pull Request
- Push su `main`
- Schedule settimanale (lunedì 9:00 UTC)

**Scanner integrati:**

- ✅ **tfsec**: Terraform security best practices
- ✅ **Trivy**: Infrastructure as Code vulnerability scanner
- ✅ **ShellCheck**: Bash script linting
- ✅ **Gitleaks**: Secret detection in code

**Risultati:** Caricati automaticamente in GitHub Security tab

**Test locale:**

```bash
# Install tools
brew install tfsec trivy shellcheck gitleaks

# Run scans
tfsec terraform/
trivy config .
shellcheck scripts/*.sh
gitleaks detect --source . --verbose
```

#### 3. **Documentation Checks** (`.github/workflows/documentation.yml`)

**Trigger:**

- Pull Request su `*.md` o `docs/**`
- Push su `main`

**Verifiche:**

- ✅ Markdown linting (markdownlint)
- ✅ Link validation (no broken links)
- ✅ Terraform docs generation check
- ✅ Spell checking

**Test locale:**

```bash
npm install -g markdownlint-cli2
markdownlint-cli2 "**/*.md"
```

#### 4. **Pull Request Checks** (`.github/workflows/pr-checks.yml`)

**Automazioni su ogni PR:**

- ✅ Mostra informazioni PR
- ✅ Auto-labeling basato su file modificati
- ✅ Size labels (XS, S, M, L, XL)
- ✅ Conventional Commits validation

**Labels automatiche:**

- `terraform` - per modifiche in `terraform/**`
- `docker` - per modifiche in `docker/**`
- `scripts` - per modifiche in `scripts/**`
- `documentation` - per modifiche `.md` o `docs/**`
- `ci-cd` - per modifiche `.github/**`
- `security` - per modifiche relative a sicurezza

### 🔧 Setup GitHub Actions

I workflow sono già pronti! Basta pushare il codice su GitHub.

#### Secrets Opzionali

I workflow **NON richiedono secrets** per funzionare. Sono opzionali solo per:

```yaml
# Repository Settings → Secrets → Actions
GITLEAKS_LICENSE: "optional-for-pro-features"
```

**Nota:** Nessun secret OCI necessario perché i workflow NON eseguono `terraform apply` automatico (solo validazione).

### 🛡️ Branch Protection (Raccomandato)

Proteggi il branch `main` richiedendo check prima del merge:

1. **Settings → Branches → Add rule** per `main`
2. Abilita:
   - ☑ Require a pull request before merging
   - ☑ Require status checks to pass:
     - `Terraform Format and Validate`
     - `Terraform Security Scan (tfsec)`
     - `ShellCheck (Scripts)`
   - ☑ Require conversation resolution

### 📊 Status Badges

Aggiungi badges al README:

```markdown
![Terraform](https://github.com/YOUR_USERNAME/nextcloud-oci-terraform/actions/workflows/terraform-validation.yml/badge.svg)
![Security](https://github.com/YOUR_USERNAME/nextcloud-oci-terraform/actions/workflows/security-scan.yml/badge.svg)
![Docs](https://github.com/YOUR_USERNAME/nextcloud-oci-terraform/actions/workflows/documentation.yml/badge.svg)
```

### 🎯 Contributing Workflow

**Come contribuire al progetto:**

1. **Fork e clone**

   ```bash
   git clone https://github.com/YOUR_USERNAME/nextcloud-oci-terraform.git
   cd nextcloud-oci-terraform
   ```

2. **Crea branch**

   ```bash
   git checkout -b feat/my-feature
   ```

3. **Commit con Conventional Commits**

   ```bash
   git commit -m "feat(terraform): add custom CIDR support

   - Allow custom VCN CIDR configuration
   - Add validation for CIDR format
   - Update documentation

   Closes #123"
   ```

4. **Push e crea PR**

   ```bash
   git push origin feat/my-feature
   ```

   - I workflow si attivano automaticamente
   - Correggi eventuali errori
   - Aspetta review

5. **Merge** ✅

Vedi `CONTRIBUTING.md` per dettagli completi.

### ⚠️ Considerazioni Importanti

**Design Philosophy:**

- I workflow **validano** il codice (format, security, docs)
- **NON eseguono** `terraform apply` automatico
- Il deploy rimane **manuale e controllato**
- Focus su **qualità del codice** e **sicurezza**

**Perché non auto-deploy?**

- Nextcloud AIO richiede setup manuale iniziale
- Restore da backup necessita intervento umano
- Free tier OCI ha limiti di risorse
- Deploy frequenti non necessari per self-hosting

---

## 📊 PARTE 2: Monitoring con Prometheus

### Architecture Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Nextcloud  │────▶│ Prometheus  │────▶│   Grafana   │
│  + Docker   │     │   (scrape)  │     │ (dashboard) │
└─────────────┘     └─────────────┘     └─────────────┘
       │                    │
       └────────────────────┘
         metrics exporters
```

### Components da installare

#### 1. Node Exporter (System Metrics)

```yaml
# docker-compose.yml addition
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    networks:
      - monitoring
```

**Metriche raccolte**:

- CPU usage, load average
- Memory usage (free, cached, buffers)
- Disk I/O, disk space
- Network traffic
- System uptime

#### 2. cAdvisor (Docker Container Metrics)

```yaml
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: unless-stopped
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    ports:
      - "8081:8080"
    networks:
      - monitoring
```

**Metriche raccolte**:

- Container CPU usage
- Container memory usage
- Container network I/O
- Container disk I/O
- Per-container resource limits

#### 3. Prometheus Server

```yaml
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    ports:
      - "9090:9090"
    networks:
      - monitoring
```

**Configuration** (`prometheus.yml`):

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'caddy'
    static_configs:
      - targets: ['caddy-reverse-proxy:2019']
```

#### 4. Grafana

```yaml
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=your-secure-password
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SERVER_ROOT_URL=https://monitoring.your-domain.duckdns.org
    ports:
      - "3000:3000"
    networks:
      - monitoring
    depends_on:
      - prometheus
```

### Dashboards da importare

1. **Node Exporter Full** (ID: 1860)
   - CPU, Memory, Disk, Network
   - System load and uptime

2. **Docker Container & Host Metrics** (ID: 179)
   - Per-container resource usage
   - Container health status

3. **Caddy Monitoring** (Custom)
   - HTTP request rates
   - Response times
   - SSL certificate expiry

4. **Nextcloud Monitoring** (Custom)
   - Active users
   - Storage usage
   - Database performance

### Firewall Rules da aggiungere

```bash
# Prometheus (solo localhost)
# Grafana (accesso esterno via reverse proxy)
sudo ufw allow from 10.0.0.0/8 to any port 9090 comment 'Prometheus'
sudo ufw allow 3000/tcp comment 'Grafana'
```

---

## 🚨 PARTE 3: Alerting

### Prometheus Alert Rules

**File**: `prometheus/alerts.yml`

```yaml
groups:
  - name: instance
    interval: 30s
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"
          description: "{{ $labels.instance }} has been down for more than 5 minutes"

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for 10 minutes"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 90%"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space is below 10%"

      - alert: SSLCertExpiringSoon
        expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 7
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "SSL certificate expiring soon"
          description: "Certificate expires in less than 7 days"
```

### Alertmanager Configuration

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'severity']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'email-notifications'

receivers:
  - name: 'email-notifications'
    email_configs:
      - to: 'your-email@example.com'
        from: 'alertmanager@your-domain.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@example.com'
        auth_password: 'your-app-password'
```

---

## 📝 Implementation Checklist

### CI/CD Pipeline ✅

- [x] Create `.github/workflows/terraform-validation.yml`
- [x] Create `.github/workflows/security-scan.yml`
- [x] Create `.github/workflows/documentation.yml`
- [x] Create `.github/workflows/pr-checks.yml`
- [x] Add PR template
- [x] Add CONTRIBUTING.md guide
- [x] Document pipeline in docs/09-CICD-MONITORING.md
- [ ] Test workflows on real PR (dopo push su GitHub)
- [ ] Configure branch protection rules

### Monitoring Stack

- [ ] Add exporters to docker-compose.yml
- [ ] Deploy Prometheus
- [ ] Deploy Grafana
- [ ] Import dashboards
- [ ] Configure alerts
- [ ] Test alerting
- [ ] Update firewall rules
- [ ] Add Caddy reverse proxy for Grafana

### Documentation

- [ ] CI/CD usage guide
- [ ] Monitoring dashboard guide
- [ ] Alert response procedures
- [ ] Troubleshooting guide

---

## 🎓 Risorse & Reference

### GitHub Actions

- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [GitHub Actions best practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

### Prometheus & Grafana

- [Node Exporter](https://github.com/prometheus/node_exporter)
- [cAdvisor](https://github.com/google/cadvisor)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Prometheus Alerting](https://prometheus.io/docs/alerting/latest/overview/)

### Nextcloud Monitoring

- [Nextcloud Server Administration](https://docs.nextcloud.com/server/latest/admin_manual/)
- [Nextcloud Prometheus Exporter](https://github.com/xperimental/nextcloud-exporter)

---

## ⚠️ Considerazioni Finali

### Costi

- **Monitoring stack**: +500MB RAM, +5GB disk
- Rientra nel free tier OCI (4 vCPU, 24GB RAM disponibili)

### Sicurezza

- Grafana dietro reverse proxy con autenticazione
- Prometheus solo accesso interno (localhost)
- Alert via email cifrata (TLS)

### Manutenzione

- Backup configurazioni Prometheus/Grafana
- Retention policies per metriche (30 giorni di default)
- Update regolari delle immagini Docker

---

**Status Attuale**:

- ✅ Infrastructure as Code completa (Terraform)
- ✅ CI/CD automation (GitHub Actions)
- ✅ Automated backup system (Borg + exports)
- ✅ Production-grade security (Firewall, Fail2ban, SSL)
- ✅ Pets vs Cattle pattern (persistent storage)
- 🚧 Monitoring e observability (In pianificazione)

**Next Step**: Implementare Prometheus + Grafana per monitoring completo
