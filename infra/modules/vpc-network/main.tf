# VPC Network Module
# Manages VPC networks, subnets, firewall rules, Cloud NAT, and VPC connectors

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  description             = var.description

  # Delete default routes on creation
  delete_default_routes_on_create = var.delete_default_routes
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  project       = var.project_id
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.vpc.id
  description   = lookup(each.value, "description", null)

  # Private Google Access (for GCS, BigQuery, etc.)
  private_ip_google_access = lookup(each.value, "private_ip_google_access", true)

  # Secondary IP ranges (for GKE pods/services)
  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "secondary_ip_ranges", [])
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  # Flow logs
  dynamic "log_config" {
    for_each = lookup(each.value, "enable_flow_logs", false) ? [1] : []
    content {
      aggregation_interval = lookup(each.value, "flow_logs_interval", "INTERVAL_5_SEC")
      flow_sampling        = lookup(each.value, "flow_logs_sampling", 0.5)
      metadata             = lookup(each.value, "flow_logs_metadata", "INCLUDE_ALL_METADATA")
    }
  }
}

# Cloud Router (required for Cloud NAT)
resource "google_compute_router" "router" {
  for_each = var.enable_cloud_nat ? toset(var.nat_regions) : toset([])

  project = var.project_id
  name    = "${var.network_name}-router-${each.value}"
  region  = each.value
  network = google_compute_network.vpc.id

  bgp {
    asn = var.router_asn
  }
}

# Cloud NAT (for private instances to access internet)
resource "google_compute_router_nat" "nat" {
  for_each = var.enable_cloud_nat ? toset(var.nat_regions) : toset([])

  project                            = var.project_id
  name                               = "${var.network_name}-nat-${each.value}"
  router                             = google_compute_router.router[each.value].name
  region                             = each.value
  nat_ip_allocate_option             = var.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = var.nat_source_subnetwork_ip_ranges

  # Static NAT IPs (optional)
  dynamic "nat_ips" {
    for_each = lookup(var.nat_static_ips, each.value, [])
    content {
      name = nat_ips.value
    }
  }

  # Logging
  log_config {
    enable = var.nat_log_config_enable
    filter = var.nat_log_config_filter
  }
}

# Serverless VPC Access Connector (for Cloud Run, Cloud Functions)
resource "google_vpc_access_connector" "connector" {
  for_each = var.enable_serverless_vpc_access ? var.vpc_connectors : {}

  project       = var.project_id
  name          = each.value.name
  region        = each.value.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = each.value.ip_cidr_range

  # Machine type
  machine_type = lookup(each.value, "machine_type", "e2-micro")

  # Instances (2-10)
  min_instances = lookup(each.value, "min_instances", 2)
  max_instances = lookup(each.value, "max_instances", 3)

  # Throughput (200-1000 Mbps per instance)
  min_throughput = lookup(each.value, "min_throughput", 200)
  max_throughput = lookup(each.value, "max_throughput", 300)
}

# Firewall Rules
resource "google_compute_firewall" "rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  project     = var.project_id
  name        = each.value.name
  network     = google_compute_network.vpc.name
  description = lookup(each.value, "description", null)
  priority    = lookup(each.value, "priority", 1000)
  direction   = lookup(each.value, "direction", "INGRESS")

  # Source/destination
  source_ranges           = lookup(each.value, "source_ranges", null)
  source_tags             = lookup(each.value, "source_tags", null)
  source_service_accounts = lookup(each.value, "source_service_accounts", null)
  destination_ranges      = lookup(each.value, "destination_ranges", null)
  target_tags             = lookup(each.value, "target_tags", null)
  target_service_accounts = lookup(each.value, "target_service_accounts", null)

  # Allow rules
  dynamic "allow" {
    for_each = lookup(each.value, "allow", [])
    content {
      protocol = allow.value.protocol
      ports    = lookup(allow.value, "ports", null)
    }
  }

  # Deny rules
  dynamic "deny" {
    for_each = lookup(each.value, "deny", [])
    content {
      protocol = deny.value.protocol
      ports    = lookup(deny.value, "ports", null)
    }
  }

  # Logging
  dynamic "log_config" {
    for_each = lookup(each.value, "enable_logging", false) ? [1] : []
    content {
      metadata = lookup(each.value, "log_metadata", "INCLUDE_ALL_METADATA")
    }
  }
}

# VPC Peering (for private services like Cloud SQL)
resource "google_compute_global_address" "private_ip_range" {
  for_each = var.enable_private_service_access ? toset(["default"]) : toset([])

  project       = var.project_id
  name          = "${var.network_name}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_access_prefix_length
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  for_each = var.enable_private_service_access ? toset(["default"]) : toset([])

  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range[each.key].name]
}

# DNS Policy (for private DNS zones)
resource "google_dns_policy" "dns_policy" {
  count = var.enable_dns_policy ? 1 : 0

  project                   = var.project_id
  name                      = "${var.network_name}-dns-policy"
  enable_inbound_forwarding = var.dns_enable_inbound_forwarding
  enable_logging            = var.dns_enable_logging

  networks {
    network_url = google_compute_network.vpc.id
  }

  # Alternative name servers
  dynamic "alternative_name_server_config" {
    for_each = length(var.dns_alternative_name_servers) > 0 ? [1] : []
    content {
      dynamic "target_name_servers" {
        for_each = var.dns_alternative_name_servers
        content {
          ipv4_address    = target_name_servers.value.ipv4_address
          forwarding_path = lookup(target_name_servers.value, "forwarding_path", "default")
        }
      }
    }
  }
}
