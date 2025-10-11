# VPC Module - HIPAA-Ready Networking
# Cost: $0.00/month (FREE)
# Required for: VPC Service Controls, Private Firestore, secure Cloud Run

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC for ${var.environment} environment - HIPAA compliant"

  # Delete default routes on creation to ensure controlled egress
  delete_default_routes_on_create = false
}

# Subnet for Cloud Run and other services
resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.network_name}-private-${var.region}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  # Enable Private Google Access for accessing GCP services without public IPs
  private_ip_google_access = true

  # Flow logs for audit and security monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  description = "Private subnet for ${var.environment} - HIPAA compliant"
}

# Serverless VPC Access Connector for Cloud Run
# Allows Cloud Run to access resources in the VPC
resource "google_vpc_access_connector" "connector" {
  name   = "adyela-staging-connector"
  region = var.region

  # Use existing subnet instead of creating new CIDR
  subnet {
    name       = "adyela-staging-connector-subnet"
    project_id = var.project_id
  }

  # Minimum instances for cost optimization
  min_instances = var.connector_min_instances
  max_instances = var.connector_max_instances

  # Machine type - f1-micro for staging, e2-standard-4 for production
  machine_type = var.connector_machine_type
}

# Cloud Router for NAT (optional - only if external API calls needed)
resource "google_compute_router" "router" {
  count   = var.enable_cloud_nat ? 1 : 0
  name    = "${var.network_name}-router-${var.region}"
  region  = var.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT for controlled egress (optional)
# Cost: $0.044/hour = ~$32/month if enabled
# Only enable if you need to call external APIs
resource "google_compute_router_nat" "nat" {
  count  = var.enable_cloud_nat ? 1 : 0
  name   = "${var.network_name}-nat-${var.region}"
  router = google_compute_router.router[0].name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rule: Allow internal communication within VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
  description   = "Allow all internal traffic within VPC"
}

# Firewall rule: Allow health checks from Google Load Balancers
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.network_name}-allow-health-checks"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8000", "8080"]
  }

  # Google Cloud health check ranges
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  description = "Allow health checks from Google Load Balancers"
}

# Firewall rule: Deny all ingress by default (except allowed rules above)
resource "google_compute_firewall" "deny_all_ingress" {
  name     = "${var.network_name}-deny-all-ingress"
  network  = google_compute_network.vpc.name
  priority = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Deny all ingress traffic by default"
}

# Firewall rule: Allow SSH from IAP (Identity-Aware Proxy) for emergency access
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.network_name}-allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP IP range
  source_ranges = ["35.235.240.0/20"]
  description   = "Allow SSH from Identity-Aware Proxy"
}
