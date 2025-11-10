# CI/CD & Monitoring Setup

**Fase 4 del progetto** - Automazione deployment e observability

**Status**: 📋 PIANIFICATO

**Prerequisiti**: Fase 3 completata (Terraform Infrastructure as Code)

---

## 🎯 Obiettivi

1. **CI/CD Pipeline**: Automazione testing e deployment via GitHub Actions
2. **Monitoring**: Metriche sistema e applicazione con Prometheus
3. **Dashboards**: Visualizzazione con Grafana
4. **Alerting**: Notifiche proattive su problemi

---

## 📦 PARTE 1: CI/CD con GitHub Actions

### Setup GitHub Actions Workflow

**File**: `.github/workflows/terraform.yml`

#### Features da implementare:

1. **Terraform Plan on PR**
   - Trigger su ogni Pull Request
   - `terraform fmt -check`
   - `terraform validate`
   - `terraform plan` e post comment su PR

2. **Terraform Apply on Merge**
   - Trigger su merge to main
   - `terraform apply -auto-approve`
   - Solo se plan è valido

3. **Security Scanning**
   - Checkov per Terraform security
   - SAST per script bash
   - Dependency scanning

4. **Testing**
   - Syntax validation
   - Cloud-init YAML validation
   - Terraform module testing

### Secrets da configurare in GitHub

```yaml
# Repository Settings → Secrets → Actions
OCI_TENANCY_OCID: "ocid1.tenancy..."
OCI_USER_OCID: "ocid1.user..."
OCI_FINGERPRINT: "aa:bb:cc..."
OCI_PRIVATE_KEY: "-----BEGIN PRIVATE KEY-----..."
OCI_REGION: "eu-frankfurt-1"
DUCKDNS_TOKEN: "your-token"
OCI_COMPARTMENT_OCID: "ocid1.compartment..."
```

### Workflow Example Structure

```yaml
name: 'Terraform CI/CD'

on:
  pull_request:
    paths:
      - 'terraform/**'
  push:
    branches:
      - main
    paths:
      - 'terraform/**'

jobs:
  terraform-plan:
    name: 'Terraform Plan'
    runs-on: ubuntu-latest
    # Steps: checkout, setup terraform, init, plan

  terraform-apply:
    name: 'Terraform Apply'
    if: github.ref == 'refs/heads/main'
    needs: terraform-plan
    # Steps: apply only on main branch

  security-scan:
    name: 'Security Scanning'
    runs-on: ubuntu-latest
    # Steps: checkov, tfsec, etc.
```

### Considerazioni Importanti

⚠️ **Automation Limits per Nextcloud AIO**:
- Terraform può creare/distruggere infrastruttura
- **NON può** restorare dati automaticamente
- Setup AIO iniziale e restore richiedono intervento manuale
- Pensato per disaster recovery, non deploy frequenti

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

### CI/CD Pipeline
- [ ] Create `.github/workflows/terraform.yml`
- [ ] Configure GitHub Secrets
- [ ] Test PR workflow
- [ ] Test merge workflow
- [ ] Add security scanning
- [ ] Document pipeline in README

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
- [Nextcloud Monitoring](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/monitoring.html)
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

**Next Steps**: Dopo completamento Fase 4, il progetto sarà **Portfolio-Ready** con:
- ✅ Infrastructure as Code completa
- ✅ CI/CD automation
- ✅ Monitoring e observability
- ✅ Disaster recovery testato
- ✅ Production-grade security

