# VPC Network Module Outputs

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnets" {
  description = "Map of subnet names to their details"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => {
      name            = v.name
      id              = v.id
      self_link       = v.self_link
      ip_cidr_range   = v.ip_cidr_range
      region          = v.region
      gateway_address = v.gateway_address
    }
  }
}

output "subnet_names" {
  description = "List of subnet names"
  value       = [for subnet in google_compute_subnetwork.subnets : subnet.name]
}

output "subnet_self_links" {
  description = "Map of subnet names to self links"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.self_link }
}

output "cloud_router_names" {
  description = "Names of Cloud Routers"
  value       = { for k, v in google_compute_router.router : k => v.name }
}

output "cloud_nat_names" {
  description = "Names of Cloud NAT gateways"
  value       = { for k, v in google_compute_router_nat.nat : k => v.name }
}

output "vpc_connector_ids" {
  description = "IDs of VPC Access connectors"
  value       = { for k, v in google_vpc_access_connector.connector : k => v.id }
}

output "vpc_connector_self_links" {
  description = "Self links of VPC Access connectors"
  value       = { for k, v in google_vpc_access_connector.connector : k => v.self_link }
}

output "firewall_rule_names" {
  description = "Names of firewall rules"
  value       = [for rule in google_compute_firewall.rules : rule.name]
}

output "private_service_access_enabled" {
  description = "Whether private service access is enabled"
  value       = var.enable_private_service_access
}

output "private_ip_range_name" {
  description = "Name of the private IP range for service networking"
  value       = var.enable_private_service_access ? google_compute_global_address.private_ip_range["default"].name : null
}
