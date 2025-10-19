# VPC Network Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "description" {
  description = "Description of the VPC network"
  type        = string
  default     = ""
}

variable "routing_mode" {
  description = "Routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be REGIONAL or GLOBAL"
  }
}

variable "delete_default_routes" {
  description = "Delete default routes on VPC creation"
  type        = bool
  default     = false
}

# Subnets
variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name                     = string
    ip_cidr_range            = string
    region                   = string
    description              = optional(string)
    private_ip_google_access = optional(bool)
    enable_flow_logs         = optional(bool)
    flow_logs_interval       = optional(string)
    flow_logs_sampling       = optional(number)
    flow_logs_metadata       = optional(string)
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })))
  }))
  default = []
}

# Cloud Router and NAT
variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for private instances"
  type        = bool
  default     = false
}

variable "nat_regions" {
  description = "Regions where Cloud NAT should be created"
  type        = list(string)
  default     = []
}

variable "router_asn" {
  description = "BGP ASN for Cloud Router"
  type        = number
  default     = 64514
}

variable "nat_ip_allocate_option" {
  description = "How to allocate NAT IPs (AUTO_ONLY or MANUAL_ONLY)"
  type        = string
  default     = "AUTO_ONLY"

  validation {
    condition     = contains(["AUTO_ONLY", "MANUAL_ONLY"], var.nat_ip_allocate_option)
    error_message = "NAT IP allocate option must be AUTO_ONLY or MANUAL_ONLY"
  }
}

variable "nat_source_subnetwork_ip_ranges" {
  description = "How NAT should be configured per subnetwork"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  validation {
    condition = contains([
      "ALL_SUBNETWORKS_ALL_IP_RANGES",
      "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES",
      "LIST_OF_SUBNETWORKS"
    ], var.nat_source_subnetwork_ip_ranges)
    error_message = "Invalid NAT source subnetwork IP ranges option"
  }
}

variable "nat_static_ips" {
  description = "Map of region to list of static IP names for Cloud NAT"
  type        = map(list(string))
  default     = {}
}

variable "nat_log_config_enable" {
  description = "Enable logging for Cloud NAT"
  type        = bool
  default     = false
}

variable "nat_log_config_filter" {
  description = "Filter for Cloud NAT logs (ERRORS_ONLY, TRANSLATIONS_ONLY, ALL)"
  type        = string
  default     = "ERRORS_ONLY"

  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_log_config_filter)
    error_message = "NAT log filter must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL"
  }
}

# Serverless VPC Access
variable "enable_serverless_vpc_access" {
  description = "Enable Serverless VPC Access connectors"
  type        = bool
  default     = false
}

variable "vpc_connectors" {
  description = "Map of VPC Access connectors to create"
  type = map(object({
    name           = string
    region         = string
    ip_cidr_range  = string
    machine_type   = optional(string)
    min_instances  = optional(number)
    max_instances  = optional(number)
    min_throughput = optional(number)
    max_throughput = optional(number)
  }))
  default = {}
}

# Firewall Rules
variable "firewall_rules" {
  description = "List of firewall rules"
  type = list(object({
    name                    = string
    description             = optional(string)
    priority                = optional(number)
    direction               = optional(string)
    source_ranges           = optional(list(string))
    source_tags             = optional(list(string))
    source_service_accounts = optional(list(string))
    destination_ranges      = optional(list(string))
    target_tags             = optional(list(string))
    target_service_accounts = optional(list(string))
    enable_logging          = optional(bool)
    log_metadata            = optional(string)
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
  }))
  default = []
}

# Private Service Access (for Cloud SQL, etc.)
variable "enable_private_service_access" {
  description = "Enable private service access for managed services"
  type        = bool
  default     = false
}

variable "private_service_access_prefix_length" {
  description = "Prefix length for private service access IP range"
  type        = number
  default     = 16
}

# DNS Policy
variable "enable_dns_policy" {
  description = "Enable DNS policy for the VPC"
  type        = bool
  default     = false
}

variable "dns_enable_inbound_forwarding" {
  description = "Enable inbound DNS forwarding"
  type        = bool
  default     = false
}

variable "dns_enable_logging" {
  description = "Enable DNS query logging"
  type        = bool
  default     = false
}

variable "dns_alternative_name_servers" {
  description = "Alternative DNS name servers"
  type = list(object({
    ipv4_address    = string
    forwarding_path = optional(string)
  }))
  default = []
}

# Labels
variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
