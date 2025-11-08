# ==============================================================================
# OUTPUTS
# ==============================================================================

# Instance Information
output "instance_id" {
  description = "OCID of the Nextcloud instance"
  value       = oci_core_instance.nextcloud.id
}

output "instance_name" {
  description = "Display name of the instance"
  value       = oci_core_instance.nextcloud.display_name
}

output "instance_state" {
  description = "Current state of the instance"
  value       = oci_core_instance.nextcloud.state
}

# Network Information
output "public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.nextcloud.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.nextcloud.private_ip
}

# DNS Information
output "duckdns_domain" {
  description = "DuckDNS domain for the instance"
  value       = "${var.duckdns_domain}.duckdns.org"
}

# Storage Information
output "data_volume_id" {
  description = "OCID of the persistent data volume"
  value       = oci_core_volume.nextcloud_data.id
}

output "data_volume_size_gb" {
  description = "Size of the data volume in GB"
  value       = oci_core_volume.nextcloud_data.size_in_gbs
}

output "data_volume_state" {
  description = "State of the data volume"
  value       = oci_core_volume.nextcloud_data.state
}

# Access Information
output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ubuntu@${oci_core_instance.nextcloud.public_ip}"
}

output "nextcloud_aio_url" {
  description = "Nextcloud AIO admin interface URL"
  value       = "https://${oci_core_instance.nextcloud.public_ip}:8080"
}

output "nextcloud_url" {
  description = "Nextcloud public URL (via DuckDNS)"
  value       = "https://${var.duckdns_domain}.duckdns.org"
}

# Summary
output "deployment_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    instance = {
      id         = oci_core_instance.nextcloud.id
      shape      = var.instance_shape
      ocpus      = var.instance_ocpus
      memory_gb  = var.instance_memory_gb
      public_ip  = oci_core_instance.nextcloud.public_ip
      private_ip = oci_core_instance.nextcloud.private_ip
    }
    storage = {
      data_volume_id      = oci_core_volume.nextcloud_data.id
      data_volume_size_gb = oci_core_volume.nextcloud_data.size_in_gbs
      boot_volume_size_gb = var.boot_volume_size_gb
    }
    network = {
      vcn_id    = oci_core_vcn.nextcloud.id
      subnet_id = oci_core_subnet.public.id
      vcn_cidr  = var.vcn_cidr
    }
    access = {
      ssh             = "ssh ubuntu@${oci_core_instance.nextcloud.public_ip}"
      aio_interface   = "https://${oci_core_instance.nextcloud.public_ip}:8080"
      nextcloud       = "https://${var.duckdns_domain}.duckdns.org"
      duckdns_update  = "https://www.duckdns.org/update?domains=${var.duckdns_domain}&token=YOUR_TOKEN&ip="
    }
  }
}

# Cost Estimate (Free Tier)
output "cost_estimate" {
  description = "Estimated cost (Free Tier usage)"
  value = {
    compute          = "FREE (4 OCPU ARM A1.Flex within Always Free limit)"
    storage          = "FREE (${var.boot_volume_size_gb + var.data_volume_size_gb}GB total, max 200GB free)"
    network          = "FREE (10TB outbound/month included)"
    total_monthly    = "$0.00"
    exceeds_free_tier = var.boot_volume_size_gb + var.data_volume_size_gb > 200 ? "YES - Storage exceeds 200GB limit" : "NO"
  }
}
