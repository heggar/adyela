# VPC Module - HIPAA-Ready Networking

**Cost**: $0.00/month (FREE - Cloud NAT optional adds ~$32/month)

## Overview

This module creates a secure, HIPAA-compliant VPC network with:

- ✅ Private subnet with Google Private Access
- ✅ VPC Access Connector for Cloud Run
- ✅ Firewall rules (default deny-all ingress)
- ✅ VPC Flow Logs for audit trail
- ⏸️ Cloud NAT (optional, for external API calls)

## HIPAA Compliance

| Requirement           | Implementation                          | Status |
| --------------------- | --------------------------------------- | ------ |
| Network Isolation     | Private VPC with no auto-created routes | ✅     |
| Audit Logging         | VPC Flow Logs enabled                   | ✅     |
| Controlled Egress     | Cloud NAT (optional)                    | ⏸️     |
| Private Google Access | Enabled on all subnets                  | ✅     |
| Firewall Rules        | Deny-all by default                     | ✅     |
| IAP Access            | Emergency SSH via IAP only              | ✅     |

## Usage

### Basic Usage (No Cloud NAT)

```hcl
module "vpc" {
  source = "../../modules/vpc"

  network_name = "adyela-staging-vpc"
  environment  = "staging"
  region       = "us-central1"

  subnet_cidr    = "10.0.0.0/24"
  connector_cidr = "10.8.0.0/28"

  enable_cloud_nat = false  # Keep costs at $0

  labels = {
    environment = "staging"
    managed-by  = "terraform"
    hipaa       = "true"
  }
}
```

### With Cloud NAT (for external APIs)

```hcl
module "vpc" {
  source = "../../modules/vpc"

  network_name = "adyela-production-vpc"
  environment  = "production"
  region       = "us-central1"

  enable_cloud_nat = true  # Adds ~$32/month

  connector_machine_type = "e2-standard-4"  # Production-grade
  connector_min_instances = 2
  connector_max_instances = 10
}
```

## Resources Created

1. **VPC Network** (`google_compute_network`)
   - Cost: FREE
   - Regional routing mode
   - No auto-created subnets

2. **Private Subnet** (`google_compute_subnetwork`)
   - Cost: FREE
   - Private Google Access enabled
   - VPC Flow Logs enabled (5 sec intervals)

3. **VPC Access Connector** (`google_vpc_access_connector`)
   - Cost: FREE (first 72M requests/month)
   - Connects Cloud Run to VPC
   - Auto-scaling 2-3 instances (staging)

4. **Firewall Rules** (multiple `google_compute_firewall`)
   - Cost: FREE
   - Allow internal VPC traffic
   - Allow Google health checks
   - Allow IAP SSH
   - Deny all other ingress

5. **Cloud Router + NAT** (optional)
   - Cost: $0.044/hour = ~$32/month
   - Controlled egress to internet
   - NAT logs (errors only)

## Cost Breakdown

### Staging (Recommended)

```
VPC Network:              $0.00
Private Subnet:           $0.00
VPC Connector:            $0.00 (within free tier)
Firewall Rules:           $0.00
Cloud NAT:                $0.00 (disabled)
────────────────────────────────
Total:                    $0.00/month
```

### Production (With NAT)

```
VPC Network:              $0.00
Private Subnet:           $0.00
VPC Connector:            ~$2.00 (scaled traffic)
Firewall Rules:           $0.00
Cloud NAT:                $32.00 (enabled)
────────────────────────────────
Total:                    $34.00/month
```

## Inputs

| Variable                  | Description                          | Type   | Default     | Required |
| ------------------------- | ------------------------------------ | ------ | ----------- | -------- |
| `network_name`            | Name of the VPC network              | string | -           | yes      |
| `environment`             | Environment (dev/staging/production) | string | -           | yes      |
| `region`                  | GCP region                           | string | us-central1 | no       |
| `subnet_cidr`             | CIDR for private subnet              | string | 10.0.0.0/24 | no       |
| `connector_cidr`          | CIDR for VPC connector (/28)         | string | 10.8.0.0/28 | no       |
| `connector_min_instances` | Min connector instances              | number | 2           | no       |
| `connector_max_instances` | Max connector instances              | number | 3           | no       |
| `connector_machine_type`  | Connector machine type               | string | f1-micro    | no       |
| `enable_cloud_nat`        | Enable Cloud NAT (~$32/month)        | bool   | false       | no       |
| `labels`                  | Labels for all resources             | map    | {}          | no       |

## Outputs

| Output               | Description                  |
| -------------------- | ---------------------------- |
| `network_id`         | VPC network ID               |
| `network_name`       | VPC network name             |
| `network_self_link`  | VPC network URI              |
| `subnet_id`          | Private subnet ID            |
| `subnet_name`        | Private subnet name          |
| `vpc_connector_name` | VPC Access Connector name    |
| `vpc_connector_id`   | VPC Access Connector ID      |
| `cloud_nat_enabled`  | Whether Cloud NAT is enabled |

## Example: Connect Cloud Run to VPC

```hcl
resource "google_cloud_run_service" "api" {
  name     = "adyela-api"
  location = var.region

  template {
    metadata {
      annotations = {
        # Connect to VPC
        "run.googleapis.com/vpc-access-connector" = module.vpc.vpc_connector_name
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }

    spec {
      containers {
        image = "gcr.io/..."
      }
    }
  }
}
```

## Validation

After applying, verify:

```bash
# Check VPC exists
gcloud compute networks describe adyela-staging-vpc

# Check VPC connector
gcloud compute networks vpc-access connectors describe \
  adyela-staging-vpc-connector-us-central1 \
  --region us-central1

# Check firewall rules
gcloud compute firewall-rules list --filter="network:adyela-staging-vpc"

# Check flow logs
gcloud compute networks subnets describe \
  adyela-staging-vpc-private-us-central1 \
  --region us-central1 \
  --format="get(logConfig)"
```

## Cleanup

To destroy all resources:

```bash
terraform destroy -target=module.vpc
```

**Note**: You must delete Cloud Run services using this VPC connector first.

## References

- [GCP VPC Overview](https://cloud.google.com/vpc/docs/overview)
- [Serverless VPC Access](https://cloud.google.com/vpc/docs/configure-serverless-vpc-access)
- [Cloud NAT](https://cloud.google.com/nat/docs/overview)
- [VPC Flow Logs](https://cloud.google.com/vpc/docs/using-flow-logs)
