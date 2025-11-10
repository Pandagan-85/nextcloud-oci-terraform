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

## 📚 Tech Stack

| Component          | Technology              | Purpose                     |
| ------------------ | ----------------------- | --------------------------- |
| **Cloud Provider** | Oracle Cloud (OCI)      | Always Free tier hosting    |
| **Compute**        | A1.Flex (ARM64)         | 4 vCPU, 24GB RAM            |
| **Containers**     | Docker + Docker Compose | Service orchestration       |
| **Application**    | Nextcloud AIO           | All-in-One cloud suite      |
| **Reverse Proxy**  | Caddy                   | Automatic HTTPS, HTTP/3     |
| **Database**       | PostgreSQL              | Nextcloud database          |
| **Cache**          | Redis                   | Performance optimization    |
| **DNS**            | DuckDNS                 | Dynamic DNS (free)          |
| **Firewall**       | UFW + Fail2ban          | System security             |
| **SSL/TLS**        | Let's Encrypt           | Free automated certificates |

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
└─────────────────────────────────────┘
   ↓
┌─────────────────────────────────────┐
│  Caddy Reverse Proxy                │
│  - HTTPS (443) + Let's Encrypt      │
│  - HTTP (80) → HTTPS redirect       │
└─────────────────────────────────────┘
   ↓ (internal port 11000)
┌─────────────────────────────────────┐
│  Nextcloud AIO Master Container     │
│  - Orchestrates all services        │
└─────────────────────────────────────┘
   ↓
┌─────────────────────────────────────┐
│  Nextcloud Services (Docker)        │
│  - Nextcloud (PHP-FPM)              │
│  - PostgreSQL Database              │
│  - Redis Cache                      │
│  - Apache Web Server                │
│  - Collabora Office                 │
│  - Imaginary (image processing)     │
│  - Notify Push                      │
│  - BorgBackup (daily 04:00 UTC)     │
└─────────────────────────────────────┘
```

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

| Document                                                        | Description                            |
| --------------------------------------------------------------- | -------------------------------------- |
| [`01-INITIAL-SETUP.md`](docs/01-INITIAL-SETUP.md)               | SSH configuration and first connection |
| [`02-SYSTEM-SETUP.md`](docs/02-SYSTEM-SETUP.md)                 | System updates and base packages       |
| [`03-DOCKER-SETUP.md`](docs/03-DOCKER-SETUP.md)                 | Docker and Docker Compose installation |
| [`04-FIREWALL-SECURITY.md`](docs/04-FIREWALL-SECURITY.md)       | UFW and Fail2ban configuration         |
| [`05-CADDY-REVERSE-PROXY.md`](docs/05-CADDY-REVERSE-PROXY.md)   | Caddy setup for automatic SSL          |
| [`05-NEXTCLOUD-DEPLOYMENT.md`](docs/05-NEXTCLOUD-DEPLOYMENT.md) | Nextcloud AIO deployment guide         |
| [`06-BACKUP-RESTORE.md`](docs/06-BACKUP-RESTORE.md)             | Backup strategy and disaster recovery  |

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
- **Location**: `/mnt/backup/borg/` on OCI instance
- **Retention**: 7 days
- **Encryption**: Yes (password-protected)
- **Off-site**: Weekly download to local PC with `download-backup.sh`
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

### Automation

⚠️ **IMPORTANT**: Cron must be configured once after deployment!

```bash
# Setup automated weekly backups (one-time setup required!)
./scripts/setup-cron.sh

# Verify cron is active
crontab -l

# Manual backup anytime
./scripts/weekly-backup.sh

# Check backup logs
tail -f /tmp/nextcloud-backup.log
```

See: [`docs/06-BACKUP-RESTORE.md`](docs/06-BACKUP-RESTORE.md) for complete guide

## 📊 Resource Usage

Typical resource consumption (optimized single-user setup):

| Metric      | Usage            | Available   | Note                     |
| ----------- | ---------------- | ----------- | ------------------------ |
| **RAM**     | ~1GB active      | 24GB        | Optimized (no Talk/WB)   |
| **CPU**     | 5-10% avg        | 4 cores     | Low idle consumption     |
| **Storage** | ~5-10GB (base)   | 100GB       | + user data + backups    |
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

```bash
# Check container status
docker ps

# View logs
docker logs nextcloud-aio-nextcloud
docker logs caddy-reverse-proxy

# Resource usage
docker stats

# SSL certificate expiry
echo | openssl s_client -connect YOUR_DOMAIN:443 2>/dev/null | openssl x509 -noout -dates
```

## 🧪 Troubleshooting

Common issues and solutions documented in:

- [`docs/04-FIREWALL-SECURITY.md#troubleshooting`](docs/04-FIREWALL-SECURITY.md#troubleshooting)
- [`docs/05-CADDY-REVERSE-PROXY.md#troubleshooting`](docs/05-CADDY-REVERSE-PROXY.md#troubleshooting)

## 🔮 Roadmap

### ✅ Completed (Phase 1 & 2)
- [x] **Terraform automation for OCI provisioning** - Full IaC implementation
- [x] **Automated backup system** - Borg + human-readable exports
- [x] **Pets vs Cattle pattern** - Persistent data volume, recreatable compute
- [x] **Production hardening** - Firewall, Fail2ban, SSL, security headers

### 🚧 In Progress (Phase 3)
- [ ] **CI/CD with GitHub Actions** - Automated testing and deployment
- [ ] **Monitoring with Prometheus + Grafana** - Metrics and alerting

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
