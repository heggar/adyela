# VPC Network Terraform Module

Creates and manages Google Cloud VPC networks with subnets, firewall rules,
Cloud NAT, and VPC connectors for serverless workloads.

## Features

- ✅ Custom VPC networks with configurable routing
- ✅ Subnets with private Google access and flow logs
- ✅ Cloud NAT for private instance internet access
- ✅ Serverless VPC Access connectors (Cloud Run, Functions)
- ✅ Firewall rules with logging
- ✅ Private Service Access (Cloud SQL, Memorystore)
- ✅ DNS policies

## Usage

### Basic VPC with Subnets

```hcl
module "vpc" {
  source = "../../modules/vpc-network"

  project_id   = "my-project"
  network_name = "adyela-vpc"

  subnets = [
    {
      name                     = "subnet-us-central1"
      ip_cidr_range            = "10.0.0.0/24"
      region                   = "us-central1"
      private_ip_google_access = true
    }
  ]

  # Basic firewall rules
  firewall_rules = [
    {
      name          = "allow-internal"
      source_ranges = ["10.0.0.0/8"]
      allow = [{
        protocol = "all"
      }]
    }
  ]
}
```

### Production VPC with Cloud NAT and VPC Connectors

```hcl
module "vpc_production" {
  source = "../../modules/vpc-network"

  project_id   = "adyela-production"
  network_name = "adyela-vpc-prod"

  subnets = [
    {
      name                     = "private-us-central1"
      ip_cidr_range            = "10.0.0.0/24"
      region                   = "us-central1"
      private_ip_google_access = true
      enable_flow_logs         = true
    }
  ]

  # Cloud NAT for private instances
  enable_cloud_nat = true
  nat_regions      = ["us-central1"]

  # VPC Connector for Cloud Run
  enable_serverless_vpc_access = true
  vpc_connectors = {
    "us-central1" = {
      name          = "serverless-connector"
      region        = "us-central1"
      ip_cidr_range = "10.8.0.0/28"
      min_instances = 2
      max_instances = 3
    }
  }

  # Private Service Access for Cloud SQL
  enable_private_service_access = true

  # Firewall rules
  firewall_rules = [
    {
      name          = "allow-internal"
      source_ranges = ["10.0.0.0/8"]
      allow = [{ protocol = "all" }]
    },
    {
      name          = "allow-health-checks"
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      allow = [{ protocol = "tcp", ports = ["80", "443"] }]
    }
  ]
}
```

## Cost Estimation

| Resource               | Configuration           | Monthly Cost |
| ---------------------- | ----------------------- | ------------ |
| VPC Network            | Free                    | $0           |
| Subnets                | Free                    | $0           |
| Firewall Rules         | Free (first 1000)       | $0           |
| Cloud NAT              | 1 gateway               | $45          |
| VPC Connector          | 2-3 instances, e2-micro | $30-45       |
| Private Service Access | Free                    | $0           |

**Typical Production:** ~$75-90/month (with Cloud NAT + VPC Connector) **Staging
(no NAT):** ~$30-45/month (VPC Connector only)

## Inputs

| Name                          | Description                   | Type           | Default | Required |
| ----------------------------- | ----------------------------- | -------------- | ------- | :------: |
| project_id                    | GCP project ID                | `string`       | n/a     |   yes    |
| network_name                  | VPC network name              | `string`       | n/a     |   yes    |
| subnets                       | List of subnets               | `list(object)` | `[]`    |    no    |
| enable_cloud_nat              | Enable Cloud NAT              | `bool`         | `false` |    no    |
| enable_serverless_vpc_access  | Enable VPC connectors         | `bool`         | `false` |    no    |
| enable_private_service_access | Enable private service access | `bool`         | `false` |    no    |
| firewall_rules                | Firewall rules                | `list(object)` | `[]`    |    no    |

## Outputs

| Name                     | Description              |
| ------------------------ | ------------------------ |
| network_name             | VPC network name         |
| network_self_link        | VPC network self link    |
| subnet_self_links        | Map of subnet self links |
| vpc_connector_self_links | VPC connector self links |

## Requirements

- Terraform >= 1.0
- Google Cloud Provider >= 6.0
- Compute Engine API enabled
- Service Networking API enabled (for private service access)
