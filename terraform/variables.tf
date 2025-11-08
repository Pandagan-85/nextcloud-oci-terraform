# OCI Provider Configuration
variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "OCI API Key Fingerprint"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Path to OCI API private key"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "OCI Region"
  type        = string
  default     = "eu-frankfurt-1"
}

# Compartment
variable "compartment_ocid" {
  description = "OCI Compartment OCID (use root compartment or create dedicated)"
  type        = string
  sensitive   = true
}

# Network Configuration
variable "vcn_cidr" {
  description = "CIDR block for VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Compute Configuration
variable "instance_shape" {
  description = "Instance shape (Always Free: VM.Standard.A1.Flex)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs (Free tier max: 4 total across all A1 instances)"
  type        = number
  default     = 4
}

variable "instance_memory_gb" {
  description = "Memory in GB (Free tier: 24GB max for 4 OCPUs)"
  type        = number
  default     = 24
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB"
  type        = number
  default     = 100
}

# Data Block Volume (Persistent Storage)
variable "data_volume_size_gb" {
  description = "Data block volume size in GB (for persistent Nextcloud data)"
  type        = number
  default     = 100
}

# SSH Configuration
variable "ssh_public_key_path" {
  description = "Path to SSH public key for instance access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# Application Configuration
variable "app_name" {
  description = "Application name (used for resource naming)"
  type        = string
  default     = "nextcloud"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Nextcloud Self-Hosted"
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}

# DuckDNS Configuration (for cloud-init)
variable "duckdns_domain" {
  description = "DuckDNS domain (without .duckdns.org)"
  type        = string
}

variable "duckdns_token" {
  description = "DuckDNS API token"
  type        = string
  sensitive   = true
}
