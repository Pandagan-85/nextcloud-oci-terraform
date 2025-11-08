# ==============================================================================
# PERSISTENT DATA STORAGE
# ==============================================================================
# This block volume contains ALL Nextcloud data and is PROTECTED from destroy.
# It persists across instance recreations, ensuring zero data loss.
#
# Contains:
# - Nextcloud database (PostgreSQL)
# - User files and photos
# - Nextcloud configuration
# - Docker volumes
# - Borg backups
#
# IMPORTANT: This volume has prevent_destroy = true
# If you need to destroy it, you must:
# 1. Backup all data
# 2. Remove prevent_destroy lifecycle rule
# 3. Run terraform apply, then terraform destroy
# ==============================================================================

resource "oci_core_volume" "nextcloud_data" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
  display_name        = "${var.app_name}-persistent-data-${var.environment}"

  size_in_gbs = var.data_volume_size_gb

  # Performance tier (Free tier supports: 10 VPU/GB balanced)
  vpus_per_gb = 10

  # CRITICAL: Prevent accidental destruction of data
  lifecycle {
    prevent_destroy = true

    # Ignore changes to these fields (they may be updated externally)
    ignore_changes = [
      defined_tags,
      freeform_tags
    ]
  }

  freeform_tags = merge(
    var.tags,
    {
      Name        = "${var.app_name}-data"
      Type        = "persistent-storage"
      Critical    = "true"
      BackupDaily = "true"
    }
  )
}

# Attach data volume to instance
resource "oci_core_volume_attachment" "nextcloud_data" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.nextcloud.id
  volume_id       = oci_core_volume.nextcloud_data.id

  display_name = "${var.app_name}-data-attachment"

  # Device name (will be /dev/oracleoci/oraclevdb)
  device = "/dev/oracleoci/oraclevdb"

  # Read-only: false (we need write access)
  is_read_only = false

  # Shared: false (single instance attachment)
  is_shareable = false
}

# ==============================================================================
# OBJECT STORAGE (Optional - for off-site backups)
# ==============================================================================
# Future enhancement: Store Borg backups on Object Storage
# Benefits:
# - Off-site backup (separate from instance)
# - 10GB free tier
# - Durable (11 nines)
# - Can be used for disaster recovery

# Uncomment to enable:
#
# resource "oci_objectstorage_bucket" "backups" {
#   compartment_id = var.compartment_ocid
#   namespace      = data.oci_objectstorage_namespace.ns.namespace
#   name           = "${var.app_name}-backups-${var.environment}"
#
#   access_type = "NoPublicAccess"
#
#   # Versioning for backup history
#   versioning = "Enabled"
#
#   # Auto-tiering to Archive Storage after 30 days
#   # (Not available in free tier, but good practice)
#   # auto_tiering = "InfrequentAccess"
#
#   freeform_tags = merge(
#     var.tags,
#     {
#       Name    = "${var.app_name}-backups"
#       Type    = "backup-storage"
#       Purpose = "disaster-recovery"
#     }
#   )
# }
#
# data "oci_objectstorage_namespace" "ns" {
#   compartment_id = var.compartment_ocid
# }
