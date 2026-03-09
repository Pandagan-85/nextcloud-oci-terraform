# Nextcloud on Oracle Cloud Free Tier

Production-ready, self-hosted cloud infrastructure on Oracle Cloud Infrastructure's Always Free tier. Zero cost, fully automated, security hardened.

[![Infrastructure](https://img.shields.io/badge/Infrastructure-Oracle_Cloud-red?logo=oracle)](https://www.oracle.com/cloud/free/)
[![IaC](https://img.shields.io/badge/IaC-Terraform-purple?logo=terraform)](https://www.terraform.io/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://www.docker.com/)
[![SSL](https://img.shields.io/badge/SSL-Let's_Encrypt-green?logo=letsencrypt)](https://letsencrypt.org/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-black?logo=github)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Project Overview

A complete self-hosted cloud platform running on Oracle Cloud's Always Free tier, featuring Nextcloud as the core with integrated media services, full monitoring stack, and automated backups. Built with Infrastructure as Code principles and production-grade security.

**Key highlights:**

- **Zero cost** - Runs entirely on OCI Always Free tier
- **Infrastructure as Code** - One-command deployment with Terraform
- **Multi-service platform** - Nextcloud + Komga + Jellyfin + Monitoring
- **Security hardened** - Multi-layer firewall, Fail2ban, HTTPS, Tailscale VPN
- **Automated backups** - Borg daily backups with off-site sync
- **CI/CD pipeline** - GitHub Actions with security scanning

## Architecture

```
                        INTERNET
                           |
              +---------------------------+
              |  OCI Security Lists (FW)  |
              |  Ports: 22, 80, 443       |
              +---------------------------+
                           |
              +---------------------------+
              |  Ubuntu 24.04 LTS (ARM64) |
              |  UFW + Fail2ban (SSH +    |
              |  Nextcloud login)         |
              |  4 vCPU, 24GB RAM         |
              +---------------------------+
                     |            |
          PUBLIC     |            |     PRIVATE (Tailscale VPN)
                     |            |
     +---------------+            +--------------------+
     |                                                 |
     v                                                 v
+--------------------+                  +----------------------------+
|  Caddy Reverse     |                  |  Tailscale Serve (HTTPS)   |
|  Proxy (SSL/TLS)   |                  |                            |
|  Let's Encrypt     |                  |  - AIO Admin :8443         |
+--------------------+                  |  - Komga     :25600        |
     |                                  |  - Jellyfin  :8096         |
     v                                  |  - Grafana   :3000         |
+--------------------+                  +----------------------------+
|  Nextcloud AIO     |                               |
|  - PostgreSQL      |                  +----------------------------+
|  - Redis           |                  |  Monitoring Stack          |
|  - Collabora       |                  |  - Prometheus (30d)        |
|  - BorgBackup      |                  |  - Grafana (dashboards)    |
+--------------------+                  |  - Node Exporter           |
                                        |  - cAdvisor                |
                                        +----------------------------+

+------------------------------------------------------------+
|  Persistent Block Volume (100GB, prevent_destroy)          |
|  /mnt/nextcloud-data/                                      |
|    +-- nextcloud-data/ (user files, database, config)      |
|    +-- borg-backups/ (encrypted daily backups)             |
+------------------------------------------------------------+
```

**Design pattern: "Pets vs Cattle"**

- **Cattle (Compute):** Instance is ephemeral and fully recreatable via `terraform destroy` + `terraform apply`
- **Pet (Storage):** Persistent block volume is protected (`prevent_destroy = true`) and holds all critical data
- **Disaster Recovery:** Infrastructure can be rebuilt from scratch while data survives on the protected volume

## Tech Stack

| Component | Technology | Purpose |
| --- | --- | --- |
| **Cloud** | Oracle Cloud (OCI) | Always Free tier hosting |
| **Compute** | A1.Flex (ARM64) | 4 vCPU, 24GB RAM |
| **Storage** | OCI Block Volume | 100GB persistent data (prevent_destroy) |
| **IaC** | Terraform | One-command infrastructure deployment |
| **Containers** | Docker Compose | Service orchestration |
| **Application** | Nextcloud AIO | Self-hosted cloud suite |
| **Reverse Proxy** | Caddy | Automatic HTTPS with Let's Encrypt |
| **VPN** | Tailscale | Private access to internal services |
| **Manga/Comics** | Komga | Reader integrated with Nextcloud files |
| **Media Server** | Jellyfin | Video streaming from Nextcloud files |
| **Database** | PostgreSQL | Nextcloud database (via AIO) |
| **Cache** | Redis | Performance optimization (via AIO) |
| **Backup** | BorgBackup | Encrypted, deduplicated daily backups |
| **Monitoring** | Prometheus + Grafana | Metrics collection and dashboards |
| **Exporters** | Node Exporter, cAdvisor | System and container metrics |
| **CI/CD** | GitHub Actions | Automated validation and security scans |
| **Firewall** | UFW + Fail2ban | System security and SSH protection |
| **SSL/TLS** | Let's Encrypt | Free automated certificates |

## Features

### Infrastructure & Deployment

- **Terraform IaC** - Complete infrastructure defined as code (network, compute, storage)
- **Cloud-init automation** - System bootstrap, Docker install, service deployment
- **Persistent storage** - Protected block volume survives instance destroy/recreate
- **Disaster recovery tested** - 3 complete destroy/apply cycles validated

### Services

- **Nextcloud Hub** - Files, Calendar, Contacts, Tasks, Collabora Office, Photos
- **Komga** - Manga/comics reader serving files directly from Nextcloud library
- **Jellyfin** - Media server streaming video from Nextcloud library
- **Monitoring** - Prometheus + Grafana with pre-configured dashboards and exporters

### Security

- **Multi-layer firewall** - OCI Security Lists + UFW (deny by default)
- **SSH hardening** - Key-based auth only, Fail2ban brute-force protection
- **Nextcloud brute-force protection** - Fail2ban monitoring login attempts (5 attempts → 1h ban)
- **HTTPS everywhere** - Caddy with automatic Let's Encrypt certificates
- **Security headers** - HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
- **AIO admin locked down** - Ports 8080/8443 closed to internet, accessible only via Tailscale
- **Private services** - Komga, Jellyfin, Grafana bound to localhost, accessible only via Tailscale VPN
- **2FA (TOTP)** - Two-factor authentication on Nextcloud
- **Unattended upgrades** - Automatic security updates

### Backup & Recovery

- **BorgBackup** - Encrypted daily backups at 04:00 UTC
- **Automated pruning** - 7 daily, 4 weekly, 6 monthly retention
- **Off-site sync** - rsync to local PC with integrity verification
- **Data export** - Human-readable exports (calendars .ics, contacts .vcf)
- **Local automation** - `local-backup-sync.sh` for cron-based backup sync

### CI/CD & Quality

- **3 GitHub Actions workflows** - CI validation, weekly security scans, Docker image scans
- **5-stage CI pipeline** - Validation, security, Docker checks, PR automation, summary
- **Security scanning** - tfsec, Trivy, Gitleaks, ShellCheck
- **Pre-commit hooks** - Local validation before every commit
- **Conventional commits** - Standardized commit message format

## Project Structure

```
nextcloud-oci-terraform/
|
+-- terraform/                    # Infrastructure as Code
|   +-- provider.tf               # OCI provider configuration
|   +-- variables.tf              # Configurable variables
|   +-- network.tf                # VCN, subnet, security lists
|   +-- compute.tf                # A1.Flex instance + cloud-init
|   +-- storage.tf                # Persistent block volume (protected)
|   +-- outputs.tf                # Deployment outputs
|   +-- cloud-init.yaml           # Full system bootstrap (319 lines)
|   +-- terraform.tfvars.example  # Configuration template
|   +-- README.md                 # Terraform deployment guide
|
+-- docker/                       # Container orchestration
|   +-- docker-compose.yml        # All services definition
|   +-- Caddyfile                 # Reverse proxy configuration
|   +-- monitoring/
|       +-- prometheus.yml        # Prometheus scrape config
|       +-- grafana/provisioning/ # Auto-provisioned dashboards & datasources
|
+-- scripts/                      # Automation (11 scripts)
|   +-- local-backup-sync.sh     # Borg backup sync + integrity check
|   +-- create-backup.sh          # On-demand backup trigger
|   +-- export-data.sh            # Calendar/contacts export
|   +-- generate-config.sh        # Caddyfile generator from .env
|   +-- deploy-nextcloud.sh       # Initial deployment
|   +-- borg-prune.sh             # Server-side backup pruning
|   +-- setup-cron.sh             # Backup cron automation
|   +-- ssh-connect.sh            # Quick SSH connection
|   +-- README.md                 # Scripts reference
|
+-- docs/                         # Comprehensive guides (11 documents)
|   +-- 01-INITIAL-SETUP.md      # SSH and first connection
|   +-- 02-SYSTEM-SETUP.md       # System configuration
|   +-- 03-DOCKER-SETUP.md       # Docker installation
|   +-- 04-FIREWALL-SECURITY.md  # UFW and Fail2ban
|   +-- 05-CADDY-REVERSE-PROXY.md  # Caddy and SSL setup
|   +-- 05-NEXTCLOUD-DEPLOYMENT.md  # Nextcloud AIO deployment
|   +-- 06-BACKUP-RESTORE.md     # Backup strategy and recovery
|   +-- 07-CRON-AUTOMATION.md    # Scheduled tasks setup
|   +-- 08-TERRAFORM-STRATEGY.md # IaC patterns and workflows
|   +-- 09-CICD-MONITORING.md    # CI/CD pipeline architecture
|   +-- 10-LOCAL-BACKUP-MANAGEMENT.md  # Local backup automation
|
+-- .github/workflows/           # CI/CD pipelines
|   +-- ci.yml                   # Main CI (PR + push validation)
|   +-- security-deep.yml        # Weekly security scans
|   +-- docker-image-scan.yml    # Weekly Docker vulnerability scans
|
+-- .env.example                 # Environment variables template
+-- .pre-commit-config.yaml      # Pre-commit hooks
+-- ROADMAP.md                   # Project roadmap and progress
+-- README.md                    # This file
```

## Quick Start

### Option A: Terraform Deployment (Recommended)

One-command infrastructure deployment. Everything is automated.

**Prerequisites:** Oracle Cloud account (free tier), Terraform, a domain with DNS A record

```bash
# 1. Clone and configure
git clone https://github.com/Pandagan-85/nextcloud-oci-terraform.git
cd nextcloud-oci-terraform/terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Add OCI credentials and domain

# 2. Deploy
terraform init
terraform plan
terraform apply   # Full deployment in ~10 minutes

# 3. Access
terraform output  # Shows IPs, URLs, SSH command
```

**What gets deployed automatically:**

- OCI compute instance (4 vCPU ARM, 24GB RAM)
- Persistent data volume (100GB, protected)
- Network infrastructure (VCN, subnet, security lists, internet gateway)
- System hardening (UFW, Fail2ban, unattended-upgrades)
- Docker + all services (Nextcloud, Caddy, monitoring stack)
- SSL certificates (Let's Encrypt)

See [`terraform/README.md`](terraform/README.md) for the detailed guide.

### Option B: Manual Deployment

Step-by-step deployment for learning or custom setups.

```bash
# 1. Clone and configure
git clone https://github.com/Pandagan-85/nextcloud-oci-terraform.git
cd nextcloud-oci-terraform
cp .env.example .env
nano .env  # Configure your values

# 2. Generate config and deploy
./scripts/generate-config.sh
./scripts/deploy-nextcloud.sh
```

Follow the guides in [`docs/`](docs/) for each step.

### Private Services Setup (Tailscale Serve)

Komga, Jellyfin, and Grafana are not exposed publicly. They are accessible only through Tailscale VPN with HTTPS:

```bash
# On the server, after docker compose up:
sudo tailscale serve --bg --https 8443  https+insecure://localhost:8080  # AIO Admin
sudo tailscale serve --bg --https 25600 http://localhost:25600           # Komga
sudo tailscale serve --bg --https 8096  http://localhost:8096            # Jellyfin
sudo tailscale serve --bg --https 3000  http://localhost:3000            # Grafana
```

Access from any device on your Tailscale network:
- **AIO Admin:** `https://your-tailscale-hostname:8443`
- **Komga:** `https://your-tailscale-hostname:25600`
- **Jellyfin:** `https://your-tailscale-hostname:8096`
- **Grafana:** `https://your-tailscale-hostname:3000`

## Monitoring

The monitoring stack collects system and container metrics:

- **Prometheus** - Metrics storage with 30-day retention, 15s scrape interval
- **Grafana** - Pre-provisioned dashboards (Docker metrics, Node Exporter, Caddy)
- **Node Exporter** - System metrics (CPU, RAM, disk, network)
- **cAdvisor** - Per-container resource usage

All monitoring services bind to localhost only and are accessed via Tailscale Serve.

## Backup Strategy

Dual backup system for maximum data protection:

**BorgBackup (automated):**
- Daily encrypted backups at 04:00 UTC via Nextcloud AIO
- Stored on persistent volume (`/mnt/nextcloud-data/borg-backups/`)
- Automated pruning: 7 daily, 4 weekly, 6 monthly
- Off-site sync to local PC via `local-backup-sync.sh`

**Data export (human-readable):**
- Weekly export of calendars (.ics) and contacts (.vcf)
- Portable format, importable to Google/Apple/Outlook

```bash
# Sync backups to local PC (one-time setup)
ln -s ~/Projects/nextcloud-oci-terraform/scripts/local-backup-sync.sh ~/bin/nextcloud-backup

# Run sync
nextcloud-backup --sync-only    # Automated (cron-friendly)
nextcloud-backup                # Interactive (sync + extract)
```

See [`docs/10-LOCAL-BACKUP-MANAGEMENT.md`](docs/10-LOCAL-BACKUP-MANAGEMENT.md) for the complete guide.

## CI/CD Pipeline

Three GitHub Actions workflows ensure code quality and security:

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| **CI Pipeline** | PR + push to main | Terraform validation, YAML/Docker/Markdown/Shell linting, security scans |
| **Security Deep** | Weekly (Monday) | tfsec, Trivy, Gitleaks, ShellCheck with SARIF upload |
| **Docker Scan** | Weekly (Wednesday) | Container image vulnerability scanning |

The CI pipeline runs in 5 stages: fast validation, security scans, Docker checks, PR automation, and summary. Pre-commit hooks provide local validation before every commit.

See [`docs/09-CICD-MONITORING.md`](docs/09-CICD-MONITORING.md) for pipeline architecture details.

## Resource Usage

Typical consumption on OCI Always Free tier (single-user setup):

| Resource | Usage | Available | Note |
| --- | --- | --- | --- |
| **RAM** | ~1GB active | 24GB | Optimized (Talk/Whiteboard removed) |
| **CPU** | 5-10% avg | 4 cores | Low idle consumption |
| **Storage** | ~5-10GB base | 100GB data volume | + user data + backups |
| **Network** | Variable | 10TB/month | OCI Free Tier outbound |
| **Cost** | $0.00 | - | Always Free tier |

## Documentation

| Guide | Description |
| --- | --- |
| [`01-INITIAL-SETUP.md`](docs/01-INITIAL-SETUP.md) | SSH configuration and first connection |
| [`02-SYSTEM-SETUP.md`](docs/02-SYSTEM-SETUP.md) | System updates and base packages |
| [`03-DOCKER-SETUP.md`](docs/03-DOCKER-SETUP.md) | Docker and Docker Compose installation |
| [`04-FIREWALL-SECURITY.md`](docs/04-FIREWALL-SECURITY.md) | UFW and Fail2ban configuration |
| [`05-CADDY-REVERSE-PROXY.md`](docs/05-CADDY-REVERSE-PROXY.md) | Caddy setup for automatic SSL |
| [`05-NEXTCLOUD-DEPLOYMENT.md`](docs/05-NEXTCLOUD-DEPLOYMENT.md) | Nextcloud AIO deployment guide |
| [`06-BACKUP-RESTORE.md`](docs/06-BACKUP-RESTORE.md) | Backup strategy and disaster recovery |
| [`07-CRON-AUTOMATION.md`](docs/07-CRON-AUTOMATION.md) | Scheduled tasks setup |
| [`08-TERRAFORM-STRATEGY.md`](docs/08-TERRAFORM-STRATEGY.md) | IaC patterns and operational workflows |
| [`09-CICD-MONITORING.md`](docs/09-CICD-MONITORING.md) | CI/CD pipeline architecture |
| [`10-LOCAL-BACKUP-MANAGEMENT.md`](docs/10-LOCAL-BACKUP-MANAGEMENT.md) | Local backup automation guide |
| [`terraform/README.md`](terraform/README.md) | Terraform deployment guide |
| [`scripts/README.md`](scripts/README.md) | Scripts reference |
| [`ROADMAP.md`](ROADMAP.md) | Project roadmap and progress |

## Roadmap

### Completed

- [x] **Infrastructure** - OCI Always Free tier with Terraform IaC
- [x] **Nextcloud** - Full deployment with Collabora, Calendar, Contacts, Files
- [x] **Security** - Multi-layer firewall, Fail2ban, HTTPS, 2FA
- [x] **Backups** - Borg daily + data exports + off-site sync
- [x] **Monitoring** - Prometheus + Grafana + exporters
- [x] **CI/CD** - 3 GitHub Actions workflows + pre-commit hooks
- [x] **Media services** - Komga (manga) + Jellyfin (video) via Tailscale
- [x] **Disaster recovery** - Tested with 3 destroy/apply cycles

### Planned

- [ ] Alertmanager for critical notifications (disk, memory, container health)
- [ ] Off-site backup to OCI Object Storage
- [ ] Log aggregation (Loki + Promtail)
- [ ] Additional services (Vaultwarden, Uptime Kuma)

## License

MIT License - Feel free to use and modify for your own projects.

## Acknowledgments

- [Nextcloud AIO](https://github.com/nextcloud/all-in-one) - All-in-one Nextcloud distribution
- [Caddy](https://caddyserver.com/) - Automatic HTTPS web server
- [Tailscale](https://tailscale.com/) - Zero-config VPN
- [Oracle Cloud](https://www.oracle.com/cloud/free/) - Always Free tier
- [Komga](https://komga.org/) - Comics/manga media server
- [Jellyfin](https://jellyfin.org/) - Free media server

---

Project by [Veronica Schembri](https://www.veronicaschembri.com/)

_Last updated: March 2025_
