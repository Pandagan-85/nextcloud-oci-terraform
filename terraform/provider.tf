terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }

  # Optional: Remote state (future enhancement)
  # backend "s3" {
  #   bucket = "terraform-state"
  #   key    = "nextcloud/terraform.tfstate"
  #   region = "eu-frankfurt-1"
  # }
}

provider "oci" {
  # Authentication via ~/.oci/config
  # Or use environment variables:
  # - TF_VAR_tenancy_ocid
  # - TF_VAR_user_ocid
  # - TF_VAR_fingerprint
  # - TF_VAR_private_key_path

  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
