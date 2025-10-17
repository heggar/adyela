# Staging Environment - HIPAA-Ready Infrastructure

**Cost**: $1.20/month (HIPAA-Ready base) + ~$2-3/month (usage)
**Deployment Time**: 15-20 minutes
**Status**: 🟢 1/12 components implemented (VPC)

---

## 📋 Overview

This staging environment implements a **HIPAA-Ready infrastructure** with 85% compliance at minimal cost ($1.20/month additional).

### Current Implementation Status

| Component              | Status | Cost/Month | Module        |
| ---------------------- | ------ | ---------- | ------------- |
| VPC + Networking       | ✅     | $0.00      | `vpc`         |
| Cloud Run API          | ⏸️     | $2.00      | (manual)      |
| Cloud Run Web          | ⏸️     | $1.00      | (manual)      |
| Firestore              | ⏸️     | $0.18      | `firestore`   |
| Cloud Storage          | ⏸️     | $0.13      | `storage`     |
| Secret Manager         | ⏸️     | $0.24      | `secrets`     |
| API Gateway            | ⏸️     | $0.45      | `api-gateway` |
| VPC Service Controls   | ⏸️     | $0.00      | `vpc-sc`      |
| Cloud Monitoring       | ⏸️     | $0.00      | `monitoring`  |
| Audit Logging          | ⏸️     | $0.00      | `audit`       |
| IAM Policies           | ⏸️     | $0.00      | `iam`         |
| Pub/Sub + Tasks        | ⏸️     | $0.20      | `async`       |
| **Total Implemented**  | 1/12   | **$0.00**  | -             |
| **Total Target (MVP)** | 12/12  | **$1.20**  | -             |

### Postponed Components (Until Real Users)

| Component   | Cost/Month | Activation Trigger           |
| ----------- | ---------- | ---------------------------- |
| CMEK        | $0.12      | 100+ active users            |
| Cloud Armor | $5.17      | 10K+ requests/day or attacks |

---

## 🚀 Quick Start

### Prerequisites

1. **GCP Project** with billing enabled
2. **Terraform** >= 1.9.0
3. **gcloud CLI** installed and authenticated
4. **Service Account** with required permissions

---

## 📦 Deployment Workflow

### Infrastructure Changes (Terraform)

Terraform manages infrastructure configuration only, NOT application deployments:

```bash
cd infra/environments/staging
terraform plan    # Review infrastructure changes
terraform apply   # Apply ONLY infrastructure changes
```

### Application Deployments (CI/CD)

Application deployments are handled by GitHub Actions (`.github/workflows/cd-staging.yml`):

- CI/CD builds and deploys images directly to Cloud Run
- Terraform is NOT involved in image deployments
- Images are updated via `gcloud run deploy`

### Expected Drift

Terraform will always show drift in:

- `template[0].containers[0].image` - CI/CD manages images
- `template[0].labels["version"]` - Updated by CI/CD
- `client` / `client_version` - Metadata from gcloud

**This drift is expected and safe.** Do NOT apply Terraform to "fix" these differences.

### When to Apply Terraform

Only apply Terraform when you need to change:

- Scaling configuration (min/max instances)
- Environment variables or secrets
- VPC configuration
- Resource limits (CPU/memory)
- Networking or load balancer settings

**Important:** Never apply Terraform just to sync image versions. This is managed by CI/CD.

---

### 1. Authenticate to GCP

```bash
# Login
gcloud auth login
gcloud auth application-default login

# Set project
export GCP_PROJECT_ID="your-project-id"
gcloud config set project $GCP_PROJECT_ID
```

### 2. Initialize Terraform Backend

```bash
cd infra/environments/staging

# Create GCS bucket for Terraform state
gsutil mb -p $GCP_PROJECT_ID -l us-central1 gs://${GCP_PROJECT_ID}-terraform-state

# Enable versioning
gsutil versioning set on gs://${GCP_PROJECT_ID}-terraform-state

# Initialize Terraform
terraform init
```

### 3. Create terraform.tfvars

```bash
cat > terraform.tfvars <<EOF
project_id   = "${GCP_PROJECT_ID}"
project_name = "adyela"
region       = "us-central1"
EOF
```

### 4. Deploy VPC Infrastructure

```bash
# Review plan
terraform plan

# Apply (only VPC module for now)
terraform apply -target=module.vpc
```

**Expected output:**

```
Plan: 8 to add, 0 to change, 0 to destroy

module.vpc.google_compute_network.vpc: Creating...
module.vpc.google_compute_subnetwork.private_subnet: Creating...
module.vpc.google_vpc_access_connector.connector: Creating...
module.vpc.google_compute_firewall.allow_internal: Creating...
module.vpc.google_compute_firewall.allow_health_checks: Creating...
module.vpc.google_compute_firewall.deny_all_ingress: Creating...
module.vpc.google_compute_firewall.allow_iap_ssh: Creating...

Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

subnet_name = "adyela-staging-vpc-private-us-central1"
vpc_connector_name = "adyela-staging-vpc-connector-us-central1"
vpc_network_name = "adyela-staging-vpc"
```

### 5. Verify VPC Deployment

```bash
# Check VPC
gcloud compute networks describe adyela-staging-vpc

# Check VPC Connector
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

---

## 📐 Architecture

### Current (Phase 1: VPC Only)

```
┌─────────────────────────────────────────────────────────┐
│                     Internet                            │
└──────────────────────┬──────────────────────────────────┘
                       │
           ┌───────────▼───────────┐
           │   Cloud Load Balancer │
           │   (Future)             │
           └───────────┬───────────┘
                       │
           ┌───────────▼────────────────────────┐
           │         adyela-staging-vpc         │
           │    (10.0.0.0/24 - Private)         │
           │                                    │
           │  ┌──────────────────────────────┐  │
           │  │  VPC Access Connector        │  │
           │  │  (10.8.0.0/28)               │  │
           │  └──────────────────────────────┘  │
           │                                    │
           │  Firewall Rules:                   │
           │  ✅ Allow internal                 │
           │  ✅ Allow health checks            │
           │  ✅ Allow IAP SSH                  │
           │  ❌ Deny all other ingress         │
           │                                    │
           │  VPC Flow Logs: ✅ Enabled         │
           │  Private Google Access: ✅ Enabled │
           │  Cloud NAT: ❌ Disabled ($0 cost)  │
           └────────────────────────────────────┘
```

### Target (Phase 2: Full HIPAA-Ready)

```
┌────────────────────────────────────────────────────────────┐
│                        Internet                            │
└───────────────────────┬────────────────────────────────────┘
                        │
            ┌───────────▼───────────┐
            │  Cloud Armor (Future) │
            │  WAF + DDoS Protection│
            └───────────┬───────────┘
                        │
            ┌───────────▼───────────┐
            │    API Gateway         │
            │    Rate Limiting       │
            └───────────┬───────────┘
                        │
    ┌───────────────────▼────────────────────────────────┐
    │             VPC Service Controls                   │
    │         (Perimeter Protection)                     │
    │  ┌──────────────────────────────────────────────┐  │
    │  │           adyela-staging-vpc                 │  │
    │  │                                              │  │
    │  │  ┌─────────────────┐  ┌──────────────────┐  │  │
    │  │  │ Cloud Run API   │  │ Cloud Run Web    │  │  │
    │  │  │ (VPC Connector) │  │ (VPC Connector)  │  │  │
    │  │  └────────┬────────┘  └────────┬─────────┘  │  │
    │  │           │                    │            │  │
    │  │  ┌────────▼────────────────────▼─────────┐  │  │
    │  │  │     Serverless VPC Access Connector   │  │  │
    │  │  └───────────────────────────────────────┘  │  │
    │  │                                              │  │
    │  │  ┌──────────┐  ┌─────────────┐  ┌────────┐  │  │
    │  │  │Firestore │  │Cloud Storage│  │Secrets │  │  │
    │  │  │(Private) │  │  (Private)  │  │Manager │  │  │
    │  │  └─────┬────┘  └──────┬──────┘  └───┬────┘  │  │
    │  │        │              │              │       │  │
    │  │  ┌─────▼──────────────▼──────────────▼────┐  │  │
    │  │  │      Cloud Monitoring + Logging        │  │  │
    │  │  │         Audit Logs (7 years)           │  │  │
    │  │  └────────────────────────────────────────┘  │  │
    │  └──────────────────────────────────────────────┘  │
    └─────────────────────────────────────────────────────┘
```

---

## 💰 Cost Breakdown

### Current Costs (VPC Only)

```
VPC Network:                    $0.00  ✅
Private Subnet:                 $0.00  ✅
VPC Access Connector:           $0.00  ✅ (within free tier)
Firewall Rules:                 $0.00  ✅
VPC Flow Logs:                  $0.00  ✅ (within free tier)
Cloud NAT:                      $0.00  ✅ (disabled)
──────────────────────────────────────
Subtotal Infrastructure:        $0.00/month
```

### Target Costs (Full HIPAA-Ready MVP)

```
Infrastructure (VPC):           $0.00
API Gateway:                    $0.45
Firestore:                      $0.18
Cloud Storage:                  $0.13
VPC Service Controls:           $0.00
Secret Manager:                 $0.24
Pub/Sub + Tasks:                $0.20
Cloud Monitoring:               $0.00
Audit Logging:                  $0.00
──────────────────────────────────────
Subtotal HIPAA-Ready:           $1.20/month

Cloud Run API (usage):          ~$2.00
Cloud Run Web (usage):          ~$1.00
──────────────────────────────────────
Total Staging (estimated):      $4.20/month
```

**Postponed** (activate with real users):

- CMEK: $0.12/month
- Cloud Armor: $5.17/month

---

## 🔐 Security Configuration

### Current Security (VPC)

✅ **Network Isolation**

- Private VPC with no auto-created routes
- No public IP addresses
- Traffic controlled by firewall rules

✅ **Audit Logging**

- VPC Flow Logs enabled (5-second intervals)
- All network traffic logged
- Logs retained for 7 years (future)

✅ **Access Control**

- Default deny-all ingress
- Allow only Google health checks
- Allow only IAP SSH for emergency

✅ **Private Google Access**

- Services can access GCP APIs without public IPs
- Cloud Run, Firestore, Storage all use private connectivity

### Pending Security (Future Modules)

⏸️ **VPC Service Controls**

- Prevent data exfiltration
- Restrict API access to authorized services

⏸️ **IAM Policies**

- Least privilege principle
- Service accounts per service
- No Owner/Editor roles

⏸️ **Secret Management**

- All secrets in Secret Manager
- Automatic rotation
- Version control

⏸️ **Audit Logging**

- All PHI access logged
- Tamper-proof storage
- 7-year retention

---

## 🧪 Testing & Validation

### Manual Testing

```bash
# 1. Test VPC connectivity
gcloud compute ssh test-vm \
  --zone us-central1-a \
  --tunnel-through-iap

# 2. Test VPC connector
gcloud run deploy test-service \
  --image gcr.io/cloudrun/hello \
  --vpc-connector adyela-staging-vpc-connector-us-central1 \
  --region us-central1

# 3. Test firewall rules
# Should FAIL (ingress denied)
curl http://CLOUD_RUN_URL

# Should SUCCEED (with auth)
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  http://CLOUD_RUN_URL
```

### Automated Testing (Future)

```bash
# Terraform validation
terraform validate

# Terraform security scan
tfsec .

# Terraform cost estimation
infracost breakdown --path .

# Apply with dry-run
terraform plan -detailed-exitcode
```

---

## 📖 Next Steps

### Phase 2: Add Cloud Run Module (Week 2)

```bash
# Create module
mkdir -p ../../modules/cloud-run

# Update staging main.tf
module "cloud_run_api" {
  source = "../../modules/cloud-run"

  service_name     = "adyela-api-staging"
  vpc_connector_id = module.vpc.vpc_connector_id
  # ...
}
```

### Phase 3: Add Firestore + Storage (Week 2)

```bash
# Create modules
mkdir -p ../../modules/firestore
mkdir -p ../../modules/storage

# Deploy
terraform apply -target=module.firestore
terraform apply -target=module.storage
```

### Phase 4: Add Security Modules (Week 3)

```bash
# VPC Service Controls
module "vpc_sc" {
  source = "../../modules/vpc-sc"
  # ...
}

# IAM Policies
module "iam" {
  source = "../../modules/iam"
  # ...
}

# Secret Manager
module "secrets" {
  source = "../../modules/secrets"
  # ...
}
```

### Phase 5: Complete HIPAA-Ready (Week 4)

```bash
# API Gateway
module "api_gateway" {
  source = "../../modules/api-gateway"
  # ...
}

# Monitoring + Audit
module "monitoring" {
  source = "../../modules/monitoring"
  # ...
}

# Deploy everything
terraform apply
```

---

## 🚨 Troubleshooting

### Issue: Terraform state locked

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### Issue: VPC connector creation slow

VPC connectors take 5-10 minutes to provision. This is normal.

```bash
# Check status
gcloud compute networks vpc-access connectors describe \
  adyela-staging-vpc-connector-us-central1 \
  --region us-central1 \
  --format="get(state)"

# Expected states: CREATING → READY
```

### Issue: Firewall rules not working

```bash
# Check rule priority
gcloud compute firewall-rules list \
  --filter="network:adyela-staging-vpc" \
  --format="table(name,priority,direction,sourceRanges[],allowed[].ports)"

# Test connectivity
gcloud compute networks subnets describe \
  adyela-staging-vpc-private-us-central1 \
  --region us-central1 \
  --format="get(privateIpGoogleAccess)"
```

### Issue: Costs higher than expected

```bash
# Check actual costs
gcloud billing accounts list

# View detailed usage
gcloud billing projects describe $GCP_PROJECT_ID

# Disable Cloud NAT if enabled
terraform apply -var="enable_cloud_nat=false"
```

---

## 📚 References

- [VPC Module Documentation](../../modules/vpc/README.md)
- [HIPAA Compliance Cost Analysis](../../../docs/deployment/hipaa-compliance-cost-analysis.md)
- [MVP Task Prioritization](../../../docs/planning/mvp-task-prioritization.md)
- [MVP PHI Strategy](../../../docs/planning/mvp-phi-strategy.md)
- [GCP HIPAA Compliance](https://cloud.google.com/security/compliance/hipaa)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

## 🤝 Support

**Issues**: Create a GitHub issue
**Questions**: Contact DevOps team
**Documentation**: See `/docs` directory

---

**Last Updated**: 2025-01-11
**Version**: 1.0.0 (VPC Module)
**Next Milestone**: Add Cloud Run module (Week 2)
