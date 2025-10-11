# VPC Module Outputs

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The URI of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_id" {
  description = "The ID of the private subnet"
  value       = google_compute_subnetwork.private_subnet.id
}

output "subnet_name" {
  description = "The name of the private subnet"
  value       = google_compute_subnetwork.private_subnet.name
}

output "subnet_self_link" {
  description = "The URI of the private subnet"
  value       = google_compute_subnetwork.private_subnet.self_link
}

output "vpc_connector_name" {
  description = "The name of the VPC Access Connector"
  value       = google_vpc_access_connector.connector.name
}

output "vpc_connector_id" {
  description = "The ID of the VPC Access Connector"
  value       = google_vpc_access_connector.connector.id
}

output "vpc_connector_self_link" {
  description = "The URI of the VPC Access Connector"
  value       = google_vpc_access_connector.connector.self_link
}

output "cloud_nat_enabled" {
  description = "Whether Cloud NAT is enabled"
  value       = var.enable_cloud_nat
}

output "router_name" {
  description = "The name of the Cloud Router (if NAT enabled)"
  value       = var.enable_cloud_nat ? google_compute_router.router[0].name : null
}
