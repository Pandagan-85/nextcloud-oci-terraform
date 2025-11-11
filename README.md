# 🚀 Nextcloud on Oracle Cloud Free Tier

Production-ready Nextcloud self-hosted cloud infrastructure on Oracle Cloud Infrastructure's Always Free tier.

[![Infrastructure](https://img.shields.io/badge/Infrastructure-Oracle_Cloud-red?logo=oracle)](https://www.oracle.com/cloud/free/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://www.docker.com/)
[![SSL](https://img.shields.io/badge/SSL-Let's_Encrypt-green?logo=letsencrypt)](https://letsencrypt.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🎯 Project Overview

This project demonstrates how to deploy a **fully-featured, secure, and scalable** Nextcloud instance on Oracle Cloud's free tier, achieving:

- **Zero cost** hosting (Always Free tier)
- **Production-grade** security and SSL
- **Automatic backups** and monitoring
- **Comprehensive documentation** for reproducibility

**Current Status:** ✅ Production Ready | 🔒 Security Hardened | 💾 Automated Backups

## ✨ Features

### Infrastructure

- ✅ Oracle Cloud A1.Flex instance (4 OCPU ARM, 24GB RAM, 100GB storage)
- ✅ Automated deployment with Docker Compose
- ✅ DuckDNS dynamic DNS integration
- ✅ Caddy reverse proxy with automatic SSL/TLS (Let's Encrypt)

### Security

- ✅ UFW firewall configured
- ✅ Fail2ban SSH protection
- ✅ HTTPS-only with HSTS headers
- ✅ SSH key-based authentication
- ✅ Security Lists (OCI cloud firewall)

### Nextcloud Features

- ✅ Nextcloud Hub 25 Autumn (latest version)
- ✅ Nextcloud Office (Collabora Online)
- ✅ Calendar, Contacts, Tasks (CalDAV/CardDAV)
- ✅ Photo management with preview generation
- ✅ File sync and sharing
- ✅ Automated daily backups with off-site copies
- ⚙️ Optimized for single-user performance (Talk & Whiteboard removed)

### Automation & DevOps

- ✅ **Terraform IaC** - One-command infrastructure deployment
- ✅ **GitHub Actions CI/CD** - Automated testing and validation
- ✅ **Cloud-init** - Automatic system bootstrap
- ✅ **Monitoring Stack** - Prometheus + Grafana + exporters
- ✅ **Backup Automation** - Script for local backup sync with integrity checks
- ✅ **Pre-commit Hooks** - Local validation before commits

## 📁 Project Structure

```
nextcloud-oci-terraform/
├── 📄 README.md                    # This file - project overview
├── 📄 ROADMAP.md                   # Project roadmap and progress
├── 📄 SSL-PRODUCTION-SWITCH.md     # Guide for SSL staging → production
│
├── 📂 docs/                        # Complete documentation
│   ├── 01-INITIAL-SETUP.md         # SSH and first connection
│   ├── 02-SYSTEM-SETUP.md          # System updates and packages
│   ├── 03-DOCKER-SETUP.md          # Docker installation
│   ├── 04-FIREWALL-SECURITY.md     # UFW and Fail2ban config
│   ├── 05-CADDY-REVERSE-PROXY.md   # Caddy setup
│   ├── 05-NEXTCLOUD-DEPLOYMENT.md  # Nextcloud AIO deployment
│   ├── 06-BACKUP-RESTORE.md        # Backup strategy
│   ├── 07-CRON-AUTOMATION.md       # Cron setup for backups
│   ├── 08-TERRAFORM-STRATEGY.md    # IaC patterns and workflows
│   ├── 09-CICD-MONITORING.md       # CI/CD pipeline architecture
│   └── 10-LOCAL-BACKUP-MANAGEMENT.md  # ⭐ Local backup automation
│
├── 📂 terraform/                   # Infrastructure as Code
│   ├── provider.tf                 # OCI provider configuration
│   ├── variables.tf                # Configurable variables
│   ├── network.tf                  # VCN, subnet, security lists
│   ├── compute.tf                  # Compute instance
│   ├── storage.tf                  # Persistent data volume
│   ├── outputs.tf                  # Deployment outputs
│   ├── cloud-init.yaml             # Automated system bootstrap
│   ├── terraform.tfvars.example    # Configuration template
│   └── README.md                   # Terraform guide
│
├── 📂 docker/                      # Docker Compose stack
│   ├── docker-compose.yml          # Nextcloud + Monitoring services
│   ├── Caddyfile                   # Caddy reverse proxy config
│   └── monitoring/
│       └── prometheus.yml          # Prometheus configuration
│
├── 📂 scripts/                     # Automation scripts
│   ├── local-backup-sync.sh        # ⭐ Automated backup sync
│   ├── deploy-nextcloud.sh         # Nextcloud deployment
│   ├── ssh-connect.sh              # Quick SSH connection
│   ├── download-backup.sh          # Legacy backup download
│   ├── export-data.sh              # Human-readable data export
│   ├── weekly-backup.sh            # Backup wrapper
│   ├── setup-cron.sh               # Cron automation setup
│   └── README.md                   # Scripts documentation
│
├── 📂 .github/workflows/           # CI/CD pipelines
│   ├── ci.yml                      # Main CI pipeline (PR + push)
│   ├── security-deep.yml           # Weekly security scans
│   └── docker-scan.yml             # Docker vulnerability scans
│
├── 📄 .pre-commit-config.yaml      # Pre-commit hooks config
├── 📄 .gitignore                   # Git ignore rules
└── 📄 .env.example                 # Environment variables template
```

## 📚 Tech Stack

| Component          | Technology              | Purpose                              |
| ------------------ | ----------------------- | ------------------------------------ |
| **Cloud Provider** | Oracle Cloud (OCI)      | Always Free tier hosting             |
| **Compute**        | A1.Flex (ARM64)         | 4 vCPU, 24GB RAM                     |
| **Storage**        | OCI Block Volume        | 100GB persistent data (prevent_destroy) |
| **Containers**     | Docker + Docker Compose | Service orchestration                |
| **Application**    | Nextcloud AIO           | All-in-One cloud suite               |
| **Reverse Proxy**  | Caddy                   | Automatic HTTPS, HTTP/3              |
| **Database**       | PostgreSQL              | Nextcloud database                   |
| **Cache**          | Redis                   | Performance optimization             |
| **Backup**         | BorgBackup              | Encrypted daily backups              |
| **DNS**            | DuckDNS                 | Dynamic DNS (free)                   |
| **Firewall**       | UFW + Fail2ban          | System security                      |
| **SSL/TLS**        | Let's Encrypt           | Free automated certificates          |
| **Monitoring**     | Prometheus + Grafana    | Metrics and dashboards               |
| **Exporters**      | Node Exporter, cAdvisor | System and container metrics         |

## 🏗️ Architecture

```
Internet
   ↓
┌─────────────────────────────────────┐
│  OCI Security Lists (Cloud FW)      │
│  Ports: 22, 80, 443, 8080           │
└─────────────────────────────────────┘
   ↓
┌─────────────────────────────────────┐
│  Ubuntu 24.04 LTS (ARM64)           │
│  UFW Firewall + Fail2ban            │
│  A1.Flex: 4 vCPU, 24GB RAM          │
└─────────────────────────────────────┘
   ↓                                   ║
┌─────────────────────────────────────┐║
│  Caddy Reverse Proxy                │║
│  - HTTPS (443) + Let's Encrypt      │║
│  - HTTP (80) → HTTPS redirect       │║   ┌──────────────────────────────┐
│  - monitoring.* → Grafana           │║   │ 💾 Persistent Block Volume   │
└─────────────────────────────────────┘║   │  (100GB, prevent_destroy)    │
   ↓ (internal port 11000)             ║   │                              │
┌─────────────────────────────────────┐║   │ /mnt/nextcloud-data/         │
│  Nextcloud AIO Master Container     │║   │  ├─ data/ (user files)       │
│  - Orchestrates all services        │║   │  ├─ database/ (PostgreSQL)   │
└─────────────────────────────────────┘║   │  ├─ config/ (Nextcloud cfg)  │
   ↓                                   ║   │  └─ borg-backups/ (7 days)   │
┌─────────────────────────────────────┐║   │                              │
│  Nextcloud Services (Docker)        │║   │ ⚠️  Survives instance destroy │
│  - Nextcloud (PHP-FPM)              ║╝══>│    "Pets vs Cattle" strategy │
│  - PostgreSQL Database              │    └──────────────────────────────┘
│  - Redis Cache                      │
│  - Apache Web Server                │
│  - Collabora Office                 │
│  - Imaginary (image processing)     │
│  - Notify Push                      │
│  - BorgBackup (daily 04:00 UTC)     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Monitoring Stack (Docker)          │
│  - Prometheus (metrics storage)     │
│  - Grafana (dashboards)             │
│  - Node Exporter (system metrics)   │
│  - cAdvisor (container metrics)     │
└─────────────────────────────────────┘
```

**Architettura "Pets vs Cattle":**

- 🐄 **Cattle (Compute)**: L'istanza è ricreabile, può essere distrutta e ricreata senza perdita dati
- 🐕 **Pet (Storage)**: Il volume persistente è protetto (`prevent_destroy = true`) e contiene TUTTI i dati critici
- 🔄 **Disaster Recovery**: `terraform destroy` + `terraform apply` ricrea l'infrastruttura mantenendo i dati

## 🚀 Quick Start

**Choose your deployment method:**

### 🎯 Option A: Terraform Deployment (Recommended - Fully Automated)

**One command deploys everything!** Infrastructure as Code approach.

**Prerequisites:**

- Oracle Cloud account (free tier) with API credentials
- Terraform installed locally
- DuckDNS account (free)

**Setup:**

```bash
# 1. Clone repository
git clone https://github.com/Pandagan-85/nextcloud-oci-terraform.git
cd nextcloud-oci-terraform/terraform

# 2. Configure Terraform variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Add OCI credentials, DuckDNS token, etc.

# 3. Deploy infrastructure
terraform init
terraform plan    # Review changes
terraform apply   # Deploy! ☕ Takes ~10 minutes

# 4. Get outputs
terraform output  # Shows public IP, URLs, SSH command
```

**What gets deployed automatically:**

- ✅ OCI compute instance (4 OCPU ARM, 24GB RAM)
- ✅ Persistent data volume (100GB, protected from destroy)
- ✅ Network (VCN, subnet, security lists, internet gateway)
- ✅ Firewall configured (UFW + Fail2ban)
- ✅ Docker installed and configured
- ✅ Nextcloud AIO + Caddy deployed
- ✅ DuckDNS configured
- ✅ SSL certificates obtained automatically

**Access your instance:**

```bash
# Get connection info
terraform output ssh_command
terraform output nextcloud_url
```

See: [`terraform/README.md`](terraform/README.md) for detailed guide.

---

### 🛠️ Option B: Manual Deployment (Step-by-Step)

**For learning or custom setups.** Full control over each step.

**Prerequisites:**

- Oracle Cloud account (free tier)
- Existing OCI instance (Ubuntu 24.04 LTS, ARM64)
- SSH key pair
- DuckDNS account (free)

**Setup:**

```bash
# 1. Clone repository
git clone https://github.com/Pandagan-85/nextcloud-oci-terraform.git
cd nextcloud-oci-terraform

# 2. Configure environment
cp .env.example .env
nano .env  # Add your instance IP, SSH key, DuckDNS credentials

# 3. Generate configuration files
./scripts/generate-config.sh  # Creates Caddyfile with your domain

# 4. Connect to instance
./scripts/ssh-connect.sh

# 5. Deploy Nextcloud
./scripts/deploy-nextcloud.sh
```

**Manual steps required:**

1. Create OCI instance manually (VM.Standard.A1.Flex, 4 OCPU, 24GB RAM)
2. Configure Security Lists (ports 22, 80, 443, 8080)
3. Update system: [`docs/02-SYSTEM-SETUP.md`](docs/02-SYSTEM-SETUP.md)
4. Install Docker: [`docs/03-DOCKER-SETUP.md`](docs/03-DOCKER-SETUP.md)
5. Configure firewall: [`docs/04-FIREWALL-SECURITY.md`](docs/04-FIREWALL-SECURITY.md)
6. Deploy: [`docs/05-NEXTCLOUD-DEPLOYMENT.md`](docs/05-NEXTCLOUD-DEPLOYMENT.md)

**Access:**

- Admin interface: `https://YOUR_IP:8080`
- Nextcloud: `https://your-domain.duckdns.org`

## 📖 Documentation

Comprehensive step-by-step guides:

| Document                                                              | Description                            |
| --------------------------------------------------------------------- | -------------------------------------- |
| **Setup & Deployment**                                                |                                        |
| [`01-INITIAL-SETUP.md`](docs/01-INITIAL-SETUP.md)                     | SSH configuration and first connection |
| [`02-SYSTEM-SETUP.md`](docs/02-SYSTEM-SETUP.md)                       | System updates and base packages       |
| [`03-DOCKER-SETUP.md`](docs/03-DOCKER-SETUP.md)                       | Docker and Docker Compose installation |
| [`04-FIREWALL-SECURITY.md`](docs/04-FIREWALL-SECURITY.md)             | UFW and Fail2ban configuration         |
| [`05-CADDY-REVERSE-PROXY.md`](docs/05-CADDY-REVERSE-PROXY.md)         | Caddy setup for automatic SSL          |
| [`05-NEXTCLOUD-DEPLOYMENT.md`](docs/05-NEXTCLOUD-DEPLOYMENT.md)       | Nextcloud AIO deployment guide         |
| **Backup & Recovery**                                                 |                                        |
| [`06-BACKUP-RESTORE.md`](docs/06-BACKUP-RESTORE.md)                   | Backup strategy and disaster recovery  |
| [`10-LOCAL-BACKUP-MANAGEMENT.md`](docs/10-LOCAL-BACKUP-MANAGEMENT.md) | ⭐ Local backup automation with script |
| **Infrastructure as Code**                                            |                                        |
| [`terraform/README.md`](terraform/README.md)                          | Terraform deployment guide             |
| [`08-TERRAFORM-STRATEGY.md`](docs/08-TERRAFORM-STRATEGY.md)           | IaC strategy and operational workflows |
| **CI/CD & Monitoring**                                                |                                        |
| [`09-CICD-MONITORING.md`](docs/09-CICD-MONITORING.md)                 | GitHub Actions pipeline and monitoring |
| **Operations**                                                        |                                        |
| [`scripts/README.md`](scripts/README.md)                              | All available scripts reference        |

## 🔐 Security Features

- **Firewall**: Multi-layer (OCI Security Lists + UFW)
- **SSH**: Key-based authentication only, Fail2ban protection
- **HTTPS**: Automatic SSL/TLS with Let's Encrypt
- **Headers**: HSTS, X-Frame-Options, CSP configured
- **Updates**: Unattended security updates enabled
- **Backups**: Automated daily backups with 7-day retention

## 💾 Backup Strategy

Dual backup system for maximum data protection:

### Borg Backup (System-level)

- **Automated**: Daily backups at 04:00 UTC via Nextcloud AIO
- **Location**: `/mnt/nextcloud-data/borg-backups/` on OCI instance
  - ⚠️ **IMPORTANTE**: I backup sono sul **volume persistente** (`/mnt/nextcloud-data/`)
  - Questo significa che sopravvivono al destroy/recreate dell'istanza compute
  - Il volume ha `prevent_destroy = true` per protezione totale
  - Strategia "Pets vs Cattle": compute è ricreabile, dati sono protetti
- **Retention**: 7 days (configurable)
- **Encryption**: Yes (password-protected)
- **Off-site**: Automated sync to local PC with `local-backup-sync.sh` script
- **Components**:
  - Database (PostgreSQL)
  - User files and data
  - Configuration
  - App data

### Data Export (Human-readable)

- **Automated**: Weekly export via cron (Sunday 22:00)
- **Location**: `~/nextcloud-exports/` on local PC
- **Formats**:
  - Calendars (.ics files)
  - Contacts (.vcf file)
  - File list
- **Portability**: Import to Google/Apple/Outlook
- **Script**: `export-data.sh`

### Local Backup Automation ⭐

Automated script for syncing backups to your local PC:

```bash
# One-time setup (5 minutes)
ln -s ~/Projects/nextcloud-oci-terraform/scripts/local-backup-sync.sh ~/bin/nextcloud-backup
echo 'export BORG_PASSPHRASE="your-password"' >> ~/.bash_profile

# Interactive sync + extraction
nextcloud-backup

# Automated sync only (perfect for cron)
nextcloud-backup --sync-only

# Setup weekly automation
crontab -e
# Add: 0 22 * * 0 $HOME/bin/nextcloud-backup --sync-only >> $HOME/nextcloud-backup-cron.log 2>&1
```

**Features:**

- ✅ rsync incremental sync (only differences)
- ✅ Automatic integrity verification (`borg check`)
- ✅ Interactive extraction with permission fixing
- ✅ Complete logging and statistics
- ✅ Mount backups as filesystem for exploration

See: [`docs/10-LOCAL-BACKUP-MANAGEMENT.md`](docs/10-LOCAL-BACKUP-MANAGEMENT.md) for complete guide

## 📊 Resource Usage

Typical resource consumption (optimized single-user setup):

| Metric      | Usage            | Available   | Note                   |
| ----------- | ---------------- | ----------- | ---------------------- |
| **RAM**     | ~1GB active      | 24GB        | Optimized (no Talk/WB) |
| **CPU**     | 5-10% avg        | 4 cores     | Low idle consumption   |
| **Storage** | ~5-10GB (base)   | 100GB       | + user data + backups  |
| **Network** | Depends on usage | Unlimited\* |

\*OCI Free Tier includes 10TB outbound/month

## 🛠️ Maintenance

### Updates

```bash
# Update Nextcloud (via AIO interface)
https://YOUR_DOMAIN:8080 → Updates tab

# Update system packages
ssh YOUR_INSTANCE
sudo apt update && sudo apt upgrade -y

# Update Docker images
cd ~/nextcloud
docker compose pull
docker compose up -d
```

### Monitoring

**Grafana Dashboard:**

- Access: `https://monitoring.YOUR_DOMAIN.duckdns.org`
- Username: `admin`
- Password: Configure in `.env` file (`GRAFANA_ADMIN_PASSWORD`)

**Available Metrics:**

- System resources (CPU, RAM, disk, network) via Node Exporter
- Docker container metrics via cAdvisor
- Caddy reverse proxy metrics
- Prometheus 30-day retention

**Manual Monitoring Commands:**

```bash
# Check container status
docker ps

# View logs
docker logs nextcloud-aio-nextcloud
docker logs caddy-reverse-proxy
docker logs grafana
docker logs prometheus

# Resource usage real-time
docker stats

# SSL certificate expiry
echo | openssl s_client -connect YOUR_DOMAIN:443 2>/dev/null | openssl x509 -noout -dates

# Prometheus health check
curl -s http://localhost:9090/-/healthy

# Check Grafana status
curl -s http://localhost:3000/api/health
```

## 🧪 Troubleshooting

Common issues and solutions documented in:

- [`docs/04-FIREWALL-SECURITY.md#troubleshooting`](docs/04-FIREWALL-SECURITY.md#troubleshooting)
- [`docs/05-CADDY-REVERSE-PROXY.md#troubleshooting`](docs/05-CADDY-REVERSE-PROXY.md#troubleshooting)

## 🔮 Roadmap

### ✅ Completed (Phase 1-3)

- [x] **Terraform automation for OCI provisioning** - Full IaC implementation
- [x] **Automated backup system** - Borg + human-readable exports
- [x] **Pets vs Cattle pattern** - Persistent data volume, recreatable compute
- [x] **Production hardening** - Firewall, Fail2ban, SSL, security headers
- [x] **CI/CD with GitHub Actions** - Automated testing and deployment
- [x] **Monitoring with Prometheus + Grafana** - Metrics collection and dashboards
- [x] **Disaster Recovery tested** - 3 complete destroy/apply cycles validated

### 🚧 In Progress (Phase 4)

- [ ] **Grafana dashboard configuration** - Import pre-built dashboards
- [ ] **Alerting setup** - Alertmanager for critical notifications

### 📋 Planned (Phase 4+)

- [ ] **Remote backup to cloud storage** - Off-site backup to OCI Object Storage
- [ ] **Automated data migration scripts** - Easy migration between instances
- [ ] **High availability setup** - Multi-region deployment (beyond free tier)

## 🤝 Contributing

This is a personal learning project, but feedback and suggestions are welcome!

- Open an issue for bugs or feature requests
- PRs welcome for documentation improvements
- Share your experience deploying this setup

## 📝 License

MIT License - Feel free to use and modify for your own projects.

## 🙏 Acknowledgments

- [Nextcloud AIO](https://github.com/nextcloud/all-in-one) - Amazing all-in-one Nextcloud distribution
- [Caddy](https://caddyserver.com/) - Modern web server with automatic HTTPS
- [DuckDNS](https://www.duckdns.org/) - Free dynamic DNS service
- [Oracle Cloud](https://www.oracle.com/cloud/free/) - Generous Always Free tier

## 📧 Contact

Project by Veronica Schembri - [Blog/Portfolio](https://www.veronicaschembri.com/)

---

**Note**: This project is for educational purposes. Always follow security best practices when deploying to production.

_Last updated: November 2025_
