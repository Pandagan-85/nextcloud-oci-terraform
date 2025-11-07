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

**Current Status:** ✅ Infrastructure complete | 🔄 Data migration in progress

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
- ✅ Nextcloud Talk (video calls & chat)
- ✅ Calendar, Contacts, Tasks
- ✅ Photo management with preview generation
- ✅ Whiteboard collaboration
- ✅ Automated daily backups

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
│  - Talk (video/chat)                │
│  - Imaginary (image processing)     │
│  - Notify Push                      │
└─────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Oracle Cloud account (free tier)
- SSH key pair
- DuckDNS account (free)
- Domain configured (e.g., `yourname.duckdns.org`)

### Step-by-Step Setup

1. **Create OCI Instance**

   - Shape: VM.Standard.A1.Flex (ARM)
   - Image: Ubuntu 24.04 LTS
   - Resources: 4 OCPU, 24GB RAM
   - Storage: 100GB boot volume

2. **Configure Security Lists**

   - Open ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8080 (AIO admin)
   - See: [`docs/04-FIREWALL-SECURITY.md`](docs/04-FIREWALL-SECURITY.md)

3. **Initial Setup**

   ```bash
   # Clone repository
   git clone https://github.com/Pandagan-85/nextcloud-oci-terraform.git
   cd nextcloud-oci-terraform

   # Configure environment
   cp .env.example .env
   nano .env  # Add your IP, SSH key, DuckDNS credentials

   # Connect to instance
   ./scripts/ssh-connect.sh
   ```

4. **System Configuration**

   - Update system: [`docs/02-SYSTEM-SETUP.md`](docs/02-SYSTEM-SETUP.md)
   - Install Docker: [`docs/03-DOCKER-SETUP.md`](docs/03-DOCKER-SETUP.md)
   - Configure firewall: [`docs/04-FIREWALL-SECURITY.md`](docs/04-FIREWALL-SECURITY.md)

5. **Deploy Nextcloud**

   ```bash
   # From your local machine
   ./scripts/deploy-nextcloud.sh
   ```

   - Full guide: [`docs/05-CADDY-REVERSE-PROXY.md`](docs/05-CADDY-REVERSE-PROXY.md)

6. **Access & Configure**
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

## 🔐 Security Features

- **Firewall**: Multi-layer (OCI Security Lists + UFW)
- **SSH**: Key-based authentication only, Fail2ban protection
- **HTTPS**: Automatic SSL/TLS with Let's Encrypt
- **Headers**: HSTS, X-Frame-Options, CSP configured
- **Updates**: Unattended security updates enabled
- **Backups**: Automated daily backups with 7-day retention

## 💾 Backup Strategy

- **Automated**: Daily backups via Nextcloud AIO
- **Local retention**: 7 days
- **Components backed up**:
  - Database (PostgreSQL)
  - User files and data
  - Configuration
  - App data

## 📊 Resource Usage

Typical resource consumption:

| Metric      | Usage            | Available   |
| ----------- | ---------------- | ----------- |
| **RAM**     | ~8-10GB          | 24GB        |
| **CPU**     | 10-20% avg       | 4 cores     |
| **Storage** | ~5-10GB (base)   | 100GB       |
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

- [ ] Terraform automation for OCI provisioning
- [ ] Automated data migration scripts
- [ ] Monitoring with Prometheus + Grafana
- [ ] Remote backup to cloud storage
- [ ] CI/CD with GitHub Actions
- [ ] High availability setup

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
