# Nextcloud Terraform Configuration

Infrastructure as Code for deploying Nextcloud on Oracle Cloud Infrastructure (OCI) Always Free tier.

## 🎯 Architecture Pattern

This Terraform configuration implements the **"Stateful Application with Persistent Storage"** pattern:

```
┌─────────────────────────────────┐
│  Compute Instance               │
│  (EPHEMERAL - can be destroyed) │
│  - Ubuntu 24.04 ARM             │
│  - Docker + Compose             │
│  - Caddy reverse proxy          │
└────────────┬────────────────────┘
             │ attached
             ↓
┌─────────────────────────────────┐
│  Block Volume                   │
│  (PERSISTENT - protected)       │
│  - prevent_destroy = true       │
│  - PostgreSQL database          │
│  - Nextcloud files              │
│  - Configuration                │
│  - Borg backups                 │
└─────────────────────────────────┘
```

**Key Benefits:**
- ✅ `terraform destroy` on instance = safe (data preserved)
- ✅ Data persists across instance recreations
- ✅ Zero data loss on infrastructure updates
- ✅ Blue-green deployments possible
- ✅ Disaster recovery ready

---

## 📁 File Structure

```
terraform/
├── provider.tf              # OCI provider configuration
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── network.tf               # VCN, subnet, security lists
├── compute.tf               # Compute instance
├── storage.tf               # Block volume (persistent data)
├── cloud-init.yaml          # Instance bootstrap script
├── terraform.tfvars.example # Template for your variables
├── .gitignore               # Ignore sensitive files
└── README.md                # This file
```

---

## 🚀 Quick Start

### Prerequisites

1. **OCI Account** (Always Free tier)
2. **OCI CLI configured** or API keys ready
3. **Terraform** installed (>= 1.5.0)
4. **SSH key pair** generated
5. **DuckDNS account** with domain and token

### Step 1: Get OCI Credentials

```bash
# Login to OCI Console
# Profile → User Settings → API Keys → Add API Key
# Download private key to ~/.oci/oci_api_key.pem

# Get required OCIDs:
# - Tenancy OCID: Profile → Tenancy
# - User OCID: Profile → User Settings
# - Compartment OCID: Identity → Compartments (or use tenancy OCID for root)
# - Fingerprint: From API key creation
```

### Step 2: Configure Variables

```bash
cd terraform/

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Required values:**
```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaa..."
user_ocid        = "ocid1.user.oc1..aaaaa..."
fingerprint      = "aa:bb:cc:dd:ee:ff..."
compartment_ocid = "ocid1.compartment.oc1..aaaaa..."
duckdns_domain   = "your-domain"
duckdns_token    = "your-token"
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Review Plan

```bash
terraform plan
```

**Expected resources:**
- ✅ 1 VCN
- ✅ 1 Internet Gateway
- ✅ 1 Route Table
- ✅ 1 Subnet
- ✅ 1 Security List
- ✅ 1 Compute Instance
- ✅ 1 Block Volume (data)
- ✅ 1 Volume Attachment

**Cost:** $0.00 (within Always Free limits)

### Step 5: Apply Configuration

```bash
terraform apply
```

Type `yes` to confirm.

**Time:** ~5-10 minutes

### Step 6: Get Outputs

```bash
terraform output

# SSH to instance
terraform output -raw ssh_command | bash

# Get Nextcloud AIO URL
terraform output nextcloud_aio_url

# Get public URL
terraform output nextcloud_url
```

---

## 🔧 Post-Deployment

### Deploy Nextcloud AIO

After Terraform completes, SSH to the instance and deploy Nextcloud:

```bash
# SSH to instance
ssh ubuntu@$(terraform output -raw public_ip)

# Check cloud-init completed
sudo cloud-init status

# Deploy Nextcloud (use scripts from repo)
cd ~/nextcloud
# Copy docker-compose.yml and Caddyfile from repository
docker compose up -d

# Get AIO admin password
docker exec nextcloud-aio-mastercontainer \
  grep -oP '"password":\s*"\K[^"]+' \
  /mnt/docker-aio-config/data/configuration.json
```

### Access Nextcloud

1. **AIO Admin:** `https://<public-ip>:8080`
2. **Nextcloud:** `https://your-domain.duckdns.org`

---

## 🔄 Operations

### Update Instance (OS, Docker, etc.)

With persistent storage, you can safely destroy and recreate the instance:

```bash
# 1. Backup (always!)
./scripts/weekly-backup.sh

# 2. Update Terraform config (e.g., new Ubuntu version)
# Edit compute.tf or variables

# 3. Destroy instance (data volume is protected!)
terraform destroy -target=oci_core_instance.nextcloud

# 4. Recreate with new config
terraform apply

# 5. Data automatically reattached
# 6. Devices reconnect (10-15 min downtime)
```

**What happens:**
- ✅ Compute instance destroyed
- ✅ Block volume **preserved** (prevent_destroy)
- ✅ New instance created
- ✅ Volume attached automatically
- ✅ Data intact (database, files, config)
- ✅ Devices reconnect with same credentials

### Scale Resources

```bash
# Edit terraform.tfvars
instance_ocpus = 6  # Scale up (if within budget)

# Apply changes (may require instance restart)
terraform apply
```

**Note:** Some changes require instance restart, others can be applied in-place.

### Migrate Regions

```bash
# 1. Backup data
./scripts/weekly-backup.sh

# 2. Change region in terraform.tfvars
region = "eu-milan-1"

# 3. Apply (creates new resources in new region)
terraform apply

# 4. Manually copy block volume or restore from backup
# 5. Update DNS
# 6. Destroy old region resources
```

---

## 🛡️ Data Protection

### Prevent Accidental Data Loss

The data volume has `prevent_destroy = true`:

```bash
# This will FAIL:
terraform destroy
# Error: Instance depends on volume with prevent_destroy

# To force destroy (DANGEROUS!):
# 1. Edit storage.tf, remove prevent_destroy
# 2. terraform apply
# 3. terraform destroy
```

### Backup Strategy

**Before ANY Terraform changes:**

```bash
# Local backup
cd /path/to/nextcloud-oci-terraform
./scripts/weekly-backup.sh

# Verify backup
ls -lh ~/nextcloud-backups/
ls -lh ~/nextcloud-exports/latest/
```

### Disaster Recovery

If instance is lost:

```bash
# 1. Terraform recreate infrastructure
terraform apply

# 2. If data volume is intact: automatic restore
# 3. If data volume is lost: restore from backup
#    (see ../docs/06-BACKUP-RESTORE.md)
```

---

## 📊 Cost Management

### Always Free Limits

```
Compute:
✅ 4 OCPU ARM (A1.Flex)
✅ 24 GB RAM
✅ 2 instances (if total ≤ 4 OCPU)

Storage:
✅ 200 GB Block Volume total
   - This config: 100GB boot + 100GB data = 200GB ✅
✅ 10 GB Object Storage (for future backups)

Network:
✅ 10 TB outbound/month
✅ 2 Reserved Public IPs
```

### Verify Costs

```bash
# Check resource usage
terraform output cost_estimate

# Expected output:
# compute: FREE
# storage: FREE (200GB total)
# network: FREE
# total_monthly: $0.00
```

**Warning:** Exceeding limits will incur charges!

---

## 🔍 Troubleshooting

### Instance Creation Fails (Out of Capacity)

OCI A1.Flex instances are in high demand:

```bash
# Try different availability domain
# Edit compute.tf:
ad_number = 2  # Try AD-2 or AD-3

# Try different region
region = "eu-zurich-1"
```

**Tip:** Try late at night or early morning.

### Cloud-init Failed

```bash
# SSH to instance
ssh ubuntu@<public-ip>

# Check cloud-init status
sudo cloud-init status --long

# View logs
sudo cat /var/log/cloud-init-output.log
sudo journalctl -u cloud-init
```

### Data Volume Not Mounted

```bash
# SSH to instance
ssh ubuntu@<public-ip>

# Check volume attachment
lsblk
# Should see /dev/oracleoci/oraclevdb

# Mount manually
sudo mount /dev/oracleoci/oraclevdb /mnt/nextcloud-data

# Check fstab
cat /etc/fstab
```

### Terraform State Issues

```bash
# Refresh state
terraform refresh

# Import existing resource (if needed)
terraform import oci_core_instance.nextcloud <INSTANCE_OCID>

# Remove from state (without destroying)
terraform state rm oci_core_instance.nextcloud
```

---

## 🔮 Future Enhancements

### Planned Features

- [ ] **Object Storage backup** (off-site Borg backups)
- [ ] **Reserved Public IP** (static IP across recreations)
- [ ] **Multiple environments** (dev, staging, prod)
- [ ] **Remote state** (S3/OCI Object Storage backend)
- [ ] **Modules** (reusable components)
- [ ] **CI/CD** (GitHub Actions for terraform plan/apply)

### Enable Object Storage Backup

Uncomment in `storage.tf`:

```hcl
resource "oci_objectstorage_bucket" "backups" {
  # ... configuration
}
```

### Enable Reserved Public IP

Uncomment in `network.tf`:

```hcl
resource "oci_core_public_ip" "nextcloud" {
  lifetime = "RESERVED"
  # ...
}
```

---

## 📚 Additional Resources

- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Always Free](https://www.oracle.com/cloud/free/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Project Documentation](../docs/)

---

## 🤝 Contributing

Improvements and suggestions welcome!

1. Test on separate OCI account
2. Document changes
3. Update this README
4. Submit PR

---

_Last updated: November 2025_
