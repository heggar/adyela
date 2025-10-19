# Adyela Infrastructure - Terraform

This directory contains all Infrastructure as Code (IaC) for the Adyela
microservices platform using Terraform.

## 📁 Structure

```
infra/
├── modules/                       # Reusable Terraform modules
│   ├── cloud-run-service/         # Generic Cloud Run service (used by all microservices) ✅
│   ├── messaging/
│   │   └── pubsub/                # Pub/Sub topics and subscriptions ✅
│   ├── finops/                    # Budget alerts and cost monitoring ✅
│   ├── microservices/ (specific modules, use cloud-run-service instead)
│   ├── frontend/                  # (to be created)
│   ├── data/                      # (to be created)
│   └── monitoring/                # (to be created)
├── environments/
│   └── staging/
│       ├── main.tf                # Main configuration (existing)
│       ├── microservices.tf       # All 6 microservices deployment ✅ NEW
│       ├── variables.tf           # Environment variables ✅ UPDATED
│       ├── backend.tf             # Terraform state backend
│       └── identity-platform.tf   # Firebase Auth (existing)
└── README.md                      # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Terraform** >= 1.0 installed
2. **gcloud CLI** authenticated
3. **GCP Project** created (staging: `adyela-staging`)
4. **Billing Account** linked to project
5. **Docker images** pushed to Artifact Registry

### Initial Setup

```bash
# 1. Navigate to staging environment
cd infra/environments/staging

# 2. Set your project ID
export TF_VAR_project_id="adyela-staging"
export TF_VAR_billing_account="YOUR_BILLING_ACCOUNT_ID"

# 3. Initialize Terraform
terraform init

# 4. Review plan
terraform plan

# 5. Apply infrastructure
terraform apply
```

## 📦 Modules

### 1. Cloud Run Service (Generic) ✅

**Path**: `modules/cloud-run-service/`

Reusable module for deploying any microservice to Cloud Run with scale-to-zero,
health checks, secrets integration, and cost attribution.

### 2. Pub/Sub Messaging ✅

**Path**: `modules/messaging/pubsub/`

Event-driven architecture with 4 topics + dead letter handling.

### 3. FinOps - Budget Alerts ✅

**Path**: `modules/finops/`

Budget monitoring with $150/month staging threshold and email alerts.

## 🏗️ Deployed Microservices (Staging)

| Service               | Port | Min | Max | CPU | Memory | Language       |
| --------------------- | ---- | --- | --- | --- | ------ | -------------- |
| **api-auth**          | 8000 | 0   | 5   | 1   | 512Mi  | Python/FastAPI |
| **api-appointments**  | 8000 | 0   | 10  | 1   | 512Mi  | Python/FastAPI |
| **api-payments**      | 3000 | 0   | 5   | 1   | 512Mi  | Node.js        |
| **api-notifications** | 3000 | 0   | 10  | 0.5 | 256Mi  | Node.js        |
| **api-admin**         | 8000 | 0   | 3   | 1   | 512Mi  | Python/FastAPI |
| **api-analytics**     | 8000 | 0   | 5   | 1   | 1Gi    | Python         |

**Cost**: ~$100-150/month with scale-to-zero enabled

## 📚 Documentation

- [Microservices Migration](../../docs/architecture/microservices-migration-strategy.md)
- [Communication Patterns](../../docs/architecture/service-communication-patterns.md)
- [FinOps Analysis](../../docs/finops/cost-analysis-and-budgets.md)
- [Observability](../../docs/infrastructure/observability-distributed-systems.md)

---

**Version**: 1.0.0 | **Last Updated**: 2025-10-18
