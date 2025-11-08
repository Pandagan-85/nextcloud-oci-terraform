# ==============================================================================
# COMPUTE INSTANCE
# ==============================================================================

# Get latest Ubuntu 24.04 ARM image
data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Get availability domain
data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_ocid
  ad_number      = 1 # Use AD-1 (can be parameterized)
}

# Nextcloud instance
resource "oci_core_instance" "nextcloud" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
  display_name        = "${var.app_name}-instance-${var.environment}"

  shape = var.instance_shape

  # Shape configuration (for flexible shapes like A1.Flex)
  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gb
  }

  # Source image
  source_details {
    source_id   = data.oci_core_images.ubuntu.images[0].id
    source_type = "image"

    # Boot volume size
    boot_volume_size_in_gbs = var.boot_volume_size_gb

    # Boot volume performance (Free tier: 10 VPU/GB)
    boot_volume_vpus_per_gb = 10
  }

  # Network configuration
  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "${var.app_name}-vnic"
    hostname_label   = var.app_name

    # Optional: Assign reserved public IP
    # Uncomment if using oci_core_public_ip resource
    # public_ip = oci_core_public_ip.nextcloud.ip_address
  }

  # Metadata for cloud-init
  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
    user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      duckdns_domain = var.duckdns_domain
      duckdns_token  = var.duckdns_token
      app_name       = var.app_name
    }))
  }

  # Preserve boot volume on instance termination (set to false for clean destroy)
  preserve_boot_volume = false

  # Lifecycle
  lifecycle {
    # Ignore changes to metadata (cloud-init runs only once)
    ignore_changes = [
      metadata,
      defined_tags,
      freeform_tags
    ]
  }

  freeform_tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-instance"
      Role = "application-server"
    }
  )

  # Wait for data volume attachment before completing
  depends_on = [
    oci_core_volume_attachment.nextcloud_data
  ]
}
