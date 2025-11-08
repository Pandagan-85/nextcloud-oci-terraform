# ==============================================================================
# NETWORKING
# ==============================================================================

# Virtual Cloud Network (VCN)
resource "oci_core_vcn" "nextcloud" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.app_name}-vcn-${var.environment}"
  dns_label      = var.app_name

  cidr_blocks = [var.vcn_cidr]

  freeform_tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-vcn"
    }
  )
}

# Internet Gateway (for outbound/inbound internet access)
resource "oci_core_internet_gateway" "nextcloud" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.nextcloud.id
  display_name   = "${var.app_name}-igw-${var.environment}"
  enabled        = true

  freeform_tags = var.tags
}

# Route Table (routes traffic to internet gateway)
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.nextcloud.id
  display_name   = "${var.app_name}-public-rt-${var.environment}"

  route_rules {
    network_entity_id = oci_core_internet_gateway.nextcloud.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  freeform_tags = var.tags
}

# Public Subnet (for Nextcloud instance)
resource "oci_core_subnet" "public" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.nextcloud.id
  display_name      = "${var.app_name}-public-subnet-${var.environment}"
  dns_label         = "public"
  cidr_block        = var.public_subnet_cidr
  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.public.id]

  # Public subnet - instances get public IPs
  prohibit_public_ip_on_vnic = false

  freeform_tags = var.tags
}

# Security List (Firewall rules)
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.nextcloud.id
  display_name   = "${var.app_name}-public-sl-${var.environment}"

  # ============================================================================
  # EGRESS RULES (Outbound traffic)
  # ============================================================================

  egress_security_rules {
    description      = "Allow all outbound traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  # ============================================================================
  # INGRESS RULES (Inbound traffic)
  # ============================================================================

  # SSH (22)
  ingress_security_rules {
    description = "SSH access"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP
    stateless   = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP (80) - Redirects to HTTPS
  ingress_security_rules {
    description = "HTTP (redirects to HTTPS)"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP
    stateless   = false

    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS (443)
  ingress_security_rules {
    description = "HTTPS"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP
    stateless   = false

    tcp_options {
      min = 443
      max = 443
    }
  }

  # HTTP/3 (443 UDP)
  ingress_security_rules {
    description = "HTTP/3 (QUIC)"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "17" # UDP
    stateless   = false

    udp_options {
      min = 443
      max = 443
    }
  }

  # Nextcloud AIO Admin Interface (8080)
  ingress_security_rules {
    description = "Nextcloud AIO admin interface"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP
    stateless   = false

    tcp_options {
      min = 8080
      max = 8080
    }
  }

  # Nextcloud AIO Admin HTTPS (8443)
  ingress_security_rules {
    description = "Nextcloud AIO admin HTTPS"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP
    stateless   = false

    tcp_options {
      min = 8443
      max = 8443
    }
  }

  # ICMP (Ping)
  ingress_security_rules {
    description = "ICMP (ping)"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "1" # ICMP
    stateless   = false

    icmp_options {
      type = 8 # Echo request
      code = 0
    }
  }

  freeform_tags = var.tags
}

# ==============================================================================
# RESERVED PUBLIC IP (Optional but recommended)
# ==============================================================================
# Reserved IP survives instance destroy/recreate
# Free tier: 2 reserved IPs allowed
#
# Benefits:
# - Same IP after terraform destroy/apply
# - No DNS update needed
# - Faster recovery
#
# Uncomment to enable:

# resource "oci_core_public_ip" "nextcloud" {
#   compartment_id = var.compartment_ocid
#   lifetime       = "RESERVED"
#   display_name   = "${var.app_name}-public-ip-${var.environment}"
#
#   lifecycle {
#     prevent_destroy = true
#   }
#
#   freeform_tags = merge(
#     var.tags,
#     {
#       Name = "${var.app_name}-ip"
#     }
#   )
# }
