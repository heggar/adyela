# Adyela Infrastructure Terraform Modules

This directory contains reusable Terraform modules for deploying and managing
Adyela's Google Cloud Platform infrastructure. All modules follow consistent
patterns for labeling, security, and cost optimization.

## 📚 Available Modules

### Core Compute & Container Modules

| Module                                        | Purpose                         | Status    | Documentation                           |
| --------------------------------------------- | ------------------------------- | --------- | --------------------------------------- |
| **[cloud-run-service](./cloud-run-service/)** | Serverless container deployment | ✅ Stable | [README](./cloud-run-service/README.md) |
| **[artifact-registry](./artifact-registry/)** | Docker container registry       | ✅ Stable | [README](./artifact-registry/README.md) |
| **[cloud-build](./cloud-build/)**             | CI/CD pipeline automation       | ✅ Stable | [README](./cloud-build/README.md)       |

### Data Storage Modules

| Module                                | Purpose                | Status    | Documentation                       |
| ------------------------------------- | ---------------------- | --------- | ----------------------------------- |
| **[cloud-storage](./cloud-storage/)** | Object storage buckets | ✅ Stable | [README](./cloud-storage/README.md) |
| **[firestore](./firestore/)**         | NoSQL database         | ✅ Stable | [README](./firestore/README.md)     |
| **[cloud-sql](./cloud-sql/)**         | Managed PostgreSQL     | ✅ Stable | [README](./cloud-sql/README.md)     |

### Common Modules

| Module                  | Purpose                | Status    | Documentation                |
| ----------------------- | ---------------------- | --------- | ---------------------------- |
| **[common](./common/)** | Standard labels & tags | ✅ Stable | [README](./common/README.md) |

### Networking & Security Modules

| Module                                | Purpose                               | Status    | Documentation                       |
| ------------------------------------- | ------------------------------------- | --------- | ----------------------------------- |
| **[vpc-network](./vpc-network/)**     | VPC with subnets, NAT, VPC connectors | ✅ Stable | [README](./vpc-network/README.md)   |
| **[load-balancer](./load-balancer/)** | Global HTTPS LB with SSL & CDN        | ✅ Stable | [README](./load-balancer/README.md) |
| **[cloud-armor](./cloud-armor/)**     | WAF & DDoS protection                 | ✅ Stable | [README](./cloud-armor/README.md)   |

**Note**: Cloud CDN is integrated within the load-balancer module for static
assets caching.

### Security & IAM Modules

| Module                                  | Purpose                                         | Status    | Documentation                        |
| --------------------------------------- | ----------------------------------------------- | --------- | ------------------------------------ |
| **[iam](./iam/)**                       | Service accounts, custom roles, least privilege | ✅ Stable | [README](./iam/README.md)            |
| **[secret-manager](./secret-manager/)** | Secrets with rotation & CMEK                    | ✅ Stable | [README](./secret-manager/README.md) |
| **[cloud-kms](./cloud-kms/)**           | Encryption key management                       | ✅ Stable | [README](./cloud-kms/README.md)      |

### Planned Modules

| Module         | Purpose            | Status     | Target Date |
| -------------- | ------------------ | ---------- | ----------- |
| **monitoring** | Metrics & alerting | 📋 Planned | Task 14.6   |
| **logging**    | Log aggregation    | 📋 Planned | Task 14.6   |

---

## 🚀 Quick Start

### 1. Basic Cloud Run Service Deployment

```hcl
# environments/staging/main.tf

# Standard labels for all resources
module "labels" {
  source = "../../modules/common"

  environment = "staging"
  team        = "backend"
  application = "api"
  owner       = "platform-team"
}

# Artifact Registry for Docker images
module "container_registry" {
  source = "../../modules/artifact-registry"

  project_id    = "adyela-staging"
  repository_id = "adyela"
  location      = "us-central1"
  environment   = "staging"

  description = "Docker images for Adyela microservices"

  # Cleanup old images to save costs
  cleanup_policies = [
    {
      id     = "delete-untagged"
      action = "DELETE"
      condition = {
        tag_state  = "UNTAGGED"
        older_than = "2592000s"  # 30 days
      }
    }
  ]

  # Create service account for GitHub Actions
  create_cicd_service_account = true
  grant_storage_admin         = true

  labels = module.labels.cicd_labels
}

# Deploy Cloud Run service
module "api_service" {
  source = "../../modules/cloud-run-service"

  project_id   = "adyela-staging"
  service_name = "adyela-api-staging"
  location     = "us-central1"
  environment  = "staging"

  image = "${module.container_registry.repository_url}/api:latest"

  # Autoscaling
  min_instances = 0
  max_instances = 10

  # Resources
  cpu_limit    = "1000m"
  memory_limit = "512Mi"

  # Environment variables
  env_vars = {
    ENVIRONMENT = "staging"
    LOG_LEVEL   = "INFO"
  }

  # Secrets from Secret Manager
  secrets = {
    DATABASE_URL = {
      secret  = "database-url"
      version = "latest"
    }
    API_KEY = {
      secret  = "api-key-staging"
      version = "latest"
    }
  }

  # Public access
  allow_public_access = true

  labels = module.labels.compute_labels
}
```

### 2. Complete CI/CD Pipeline

```hcl
# Cloud Build trigger for automated deployments
module "api_cicd" {
  source = "../../modules/cloud-build"

  project_id   = "adyela-staging"
  trigger_name = "api-staging-deploy"
  environment  = "staging"

  # Trigger on push to main branch
  github_config = {
    owner     = "adyela"
    repo_name = "adyela"
    push_config = {
      branch = "^main$"
    }
  }

  # Use cloudbuild.yaml from repository
  build_config_file = "apps/api/cloudbuild.yaml"

  # Variables available in build
  substitutions = {
    _ENVIRONMENT    = "staging"
    _REGION         = "us-central1"
    _SERVICE_NAME   = module.api_service.service_name
    _REPOSITORY_URL = module.container_registry.repository_url
  }

  # Only trigger on app changes, not docs
  included_files = [
    "apps/api/**",
    "apps/api/cloudbuild.yaml"
  ]

  ignored_files = [
    "docs/**",
    "*.md"
  ]

  # Create service account with permissions
  create_service_account         = true
  grant_artifact_registry_access = true
  grant_cloud_run_access         = true
  grant_secret_access            = true

  # Allow Cloud Build to deploy with Cloud Run SA
  cloud_run_service_account = module.api_service.service_account_id

  tags = module.labels.tags
}
```

### 3. Multi-Service Deployment

```hcl
# environments/staging/main.tf

# Shared resources
module "labels" {
  source      = "../../modules/common"
  environment = "staging"
  team        = "platform"
}

module "container_registry" {
  source        = "../../modules/artifact-registry"
  project_id    = var.project_id
  repository_id = "adyela"
  environment   = "staging"
  labels        = module.labels.cicd_labels
}

# API Service
module "api_service" {
  source       = "../../modules/cloud-run-service"
  service_name = "adyela-api-staging"
  image        = "${module.container_registry.repository_url}/api:latest"
  labels       = module.labels.compute_labels
}

module "api_build" {
  source             = "../../modules/cloud-build"
  trigger_name       = "api-deploy"
  build_config_file  = "apps/api/cloudbuild.yaml"
  included_files     = ["apps/api/**"]
  tags               = module.labels.tags
}

# Web Service
module "web_service" {
  source       = "../../modules/cloud-run-service"
  service_name = "adyela-web-staging"
  image        = "${module.container_registry.repository_url}/web:latest"
  labels       = module.labels.compute_labels
}

module "web_build" {
  source             = "../../modules/cloud-build"
  trigger_name       = "web-deploy"
  build_config_file  = "apps/web/cloudbuild.yaml"
  included_files     = ["apps/web/**"]
  tags               = module.labels.tags
}

# API Admin Service
module "admin_service" {
  source       = "../../modules/cloud-run-service"
  service_name = "adyela-api-admin-staging"
  image        = "${module.container_registry.repository_url}/api-admin:latest"
  labels       = module.labels.compute_labels
}

module "admin_build" {
  source             = "../../modules/cloud-build"
  trigger_name       = "admin-deploy"
  build_config_file  = "apps/api-admin/cloudbuild.yaml"
  included_files     = ["apps/api-admin/**"]
  tags               = module.labels.tags
}
```

---

## 🏗️ Module Design Principles

All modules follow these design principles:

### 1. **Consistent Labeling**

All modules integrate with the `common` module for standardized labels:

```hcl
module "labels" {
  source      = "../../modules/common"
  environment = var.environment
  team        = var.team
}

module "my_resource" {
  source = "../../modules/some-module"
  labels = module.labels.compute_labels  # or storage_labels, cicd_labels, etc.
}
```

### 2. **Security by Default**

- Service accounts with least-privilege IAM
- Private by default (opt-in for public access)
- Secret Manager integration (no hardcoded secrets)
- CMEK encryption support where applicable

### 3. **Cost Optimization**

- Scale-to-zero for Cloud Run
- Cleanup policies for Artifact Registry
- Regional resources (lower egress)
- Appropriate resource sizing

### 4. **HIPAA Compliance**

- Audit logging enabled
- Encryption at rest and in transit
- VPC connectors for private communication
- PHI-appropriate labels (`hipaa_scope`, `data_classification`)

### 5. **Operational Excellence**

- Health checks and liveness probes
- Autoscaling based on load
- Structured logging
- Monitoring and alerting integration

---

## 📖 Module Usage Patterns

### Pattern 1: Shared Container Registry

**Use Case**: Single Artifact Registry for all services in an environment

```hcl
# One registry
module "registry" {
  source        = "../../modules/artifact-registry"
  repository_id = "adyela"
}

# Multiple services use it
module "api" {
  source = "../../modules/cloud-run-service"
  image  = "${module.registry.repository_url}/api:latest"
}

module "web" {
  source = "../../modules/cloud-run-service"
  image  = "${module.registry.repository_url}/web:latest"
}
```

### Pattern 2: Service-Specific Registries

**Use Case**: Separate registries with different cleanup policies

```hcl
# Production registry (keep more versions)
module "prod_registry" {
  source      = "../../modules/artifact-registry"
  environment = "production"

  cleanup_policies = [
    {
      id     = "keep-recent-50"
      action = "KEEP"
      most_recent_versions = { keep_count = 50 }
    }
  ]

  immutable_tags = true  # Prevent tag overwrites
}

# Staging registry (aggressive cleanup)
module "staging_registry" {
  source      = "../../modules/artifact-registry"
  environment = "staging"

  cleanup_policies = [
    {
      id     = "delete-old-7days"
      action = "DELETE"
      condition = { older_than = "604800s" }
    }
  ]
}
```

### Pattern 3: Multi-Environment with DRY

**Use Case**: Reuse configuration across environments

```hcl
# modules/app-stack/main.tf (wrapper module)
module "labels" {
  source      = "../../common"
  environment = var.environment
  team        = var.team
}

module "registry" {
  source      = "../../artifact-registry"
  environment = var.environment
  labels      = module.labels.cicd_labels
}

module "api" {
  source      = "../../cloud-run-service"
  service_name = "${var.app_name}-${var.environment}"
  image        = "${module.registry.repository_url}/${var.app_name}:latest"
  labels       = module.labels.compute_labels
}

module "build" {
  source      = "../../cloud-build"
  trigger_name = "${var.app_name}-${var.environment}"
  labels       = module.labels.cicd_labels
}

# environments/staging/main.tf
module "staging_stack" {
  source      = "../../modules/app-stack"
  environment = "staging"
  app_name    = "api"
  team        = "backend"
}

# environments/production/main.tf
module "production_stack" {
  source      = "../../modules/app-stack"
  environment = "production"
  app_name    = "api"
  team        = "backend"
}
```

---

## 🔧 Module Development Guide

### Creating a New Module

1. **Create module directory**: `infra/modules/my-module/`
2. **Add required files**:
   - `main.tf` - Resource definitions
   - `variables.tf` - Input variables
   - `outputs.tf` - Output values
   - `README.md` - Documentation
3. **Follow naming conventions**:
   - Use `snake_case` for file/variable names
   - Use descriptive resource names
   - Include `environment` in resource names
4. **Integrate with common module**:

   ```hcl
   variable "labels" {
     description = "Labels from common module"
     type        = map(string)
     default     = {}
   }

   resource "google_resource" "this" {
     labels = var.labels
   }
   ```

5. **Document thoroughly**:
   - Usage examples
   - Input/output tables
   - Security considerations
   - Cost implications

### Module Testing

```bash
# Format
terraform fmt -recursive modules/

# Validate
cd modules/my-module
terraform init
terraform validate

# Plan (with example)
cd ../../examples/my-module-example
terraform init
terraform plan
```

---

## 📂 Directory Structure

```
infra/
├── modules/                    # Reusable Terraform modules
│   ├── artifact-registry/      # Container registry
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── cloud-build/            # CI/CD pipelines
│   ├── cloud-run-service/      # Serverless containers
│   ├── common/                 # Labels & tags
│   └── README.md               # This file
│
├── environments/               # Environment-specific configs
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── production/
│       └── ...
│
└── examples/                   # Usage examples
    ├── basic-api-deployment/
    ├── multi-service-stack/
    └── cicd-pipeline/
```

---

## 🔐 Security & Compliance

### HIPAA Compliance Checklist

When deploying healthcare infrastructure:

- [x] Use `common` module with `hipaa_scope = "yes"` label
- [x] Enable audit logging (automatic in modules)
- [x] Use Secret Manager for credentials (no hardcoded secrets)
- [x] Enable encryption at rest (CMEK where needed)
- [x] Use VPC connectors for private communication (Task 14.4)
- [x] Set `data_classification = "restricted"` for PHI resources
- [x] Implement network policies and Cloud Armor (Task 14.4)
- [x] Configure monitoring and alerting (Task 14.5)
- [x] Set up disaster recovery (Task 14.7)

### Security Best Practices

1. **Service Accounts**: Create dedicated SAs with least privilege
2. **Secrets**: Use Secret Manager, never commit secrets
3. **Network**: Use VPC connectors, not public endpoints (where possible)
4. **IAM**: Grant roles at resource level, not project level
5. **Logging**: Enable Cloud Audit Logs for all resources
6. **Encryption**: Use CMEK for sensitive data
7. **Access**: Implement IAM conditions and time-based access

---

## 💰 Cost Optimization

### Estimated Monthly Costs (Staging Environment)

| Resource                         | Configuration               | Monthly Cost       |
| -------------------------------- | --------------------------- | ------------------ |
| **Compute & Containers**         |                             |                    |
| Cloud Run (3 services)           | Min: 0, Max: 10, 512MB      | $15-30             |
| Artifact Registry                | 10GB storage, 50GB egress   | $1-5               |
| Cloud Build                      | 1000 build-minutes/month    | $3                 |
| **Data Storage**                 |                             |                    |
| Cloud Storage (uploads, backups) | 100GB STANDARD              | $2-5               |
| Firestore                        | 1GB storage, 1M reads/day   | $1-3               |
| Cloud SQL (if used)              | db-custom-1-3840, HA        | $50-80             |
| **Networking**                   |                             |                    |
| VPC Network                      | Subnets, firewall rules     | $0 (free)          |
| Cloud NAT                        | 1 gateway (optional)        | $0-45              |
| VPC Connector                    | 2-3 instances, e2-micro     | $30-45             |
| Load Balancer                    | 1 forwarding rule + traffic | $18-25             |
| Cloud Armor (disabled)           | WAF protection (optional)   | $0-10              |
| **Operations**                   |                             |                    |
| Secret Manager                   | 10 secrets, 1000 accesses   | $0.60              |
| Cloud Logging                    | 10GB/month                  | $5                 |
| **Total (without Cloud SQL)**    |                             | **$70-140/month**  |
| **Total (with Cloud SQL)**       |                             | **$120-220/month** |

**Cost Optimization for Staging**:

- Disable Cloud NAT (use allowlisted IPs instead): Save $45/month
- Disable Cloud SQL (use Firestore only): Save $50-80/month
- Disable Cloud Armor (enable for production only): Save $10/month
- **Minimal Staging**: ~$70-90/month (VPC connector + LB + compute + storage)

### Cost Optimization Tips

1. **Use scale-to-zero** for non-production services
2. **Implement cleanup policies** in Artifact Registry
3. **Use regional resources** (not multi-region unless needed)
4. **Set appropriate resource limits** (CPU/memory)
5. **Use Cloud Build free tier** (120 minutes/day)
6. **Archive old logs** to Cloud Storage
7. **Use committed use discounts** for production (not implemented yet)

---

## 📞 Support & Contribution

### Getting Help

- **Module documentation**: Each module has a detailed README
- **Examples**: See `examples/` directory
- **Issues**: Report issues in GitHub
- **Team**: Contact DevOps team (@devops-team)

### Contributing New Modules

1. Follow module development guide (above)
2. Include comprehensive tests
3. Document usage examples
4. Submit PR with module + example
5. Update this README with new module entry

### Module Versioning

Modules use Git tags for versioning:

```hcl
module "api" {
  source = "git::https://github.com/adyela/adyela.git//infra/modules/cloud-run-service?ref=v1.0.0"
}
```

For development, use relative paths:

```hcl
module "api" {
  source = "../../modules/cloud-run-service"
}
```

---

## 🎯 Roadmap

### ✅ Completed

**Task 14.1 - Setup** (Completed):

- [x] Terraform project structure
- [x] Backend configuration (GCS)
- [x] Environment scaffolding

**Task 14.2 - Core Compute** (Completed):

- [x] Cloud Run Service module
- [x] Artifact Registry module
- [x] Cloud Build module
- [x] Common labels module

**Task 14.3 - Data Storage** (Completed):

- [x] Cloud Storage module (lifecycle, CDN, PHI support)
- [x] Firestore module (PITR, backups, security rules)
- [x] Cloud SQL module (HA, read replicas, PITR)

**Task 14.4 - Networking** (Completed):

- [x] VPC Network module (subnets, NAT, VPC connectors, firewall)
- [x] Load Balancer module (SSL, CDN, multi-backend routing)
- [x] Cloud Armor module (WAF, OWASP Top 10, rate limiting)

**Task 14.5 - Security & IAM** (Completed):

- [x] IAM module (service accounts, custom roles, Workload Identity)
- [x] Secret Manager module (secrets rotation, CMEK, auto-generation)
- [x] Cloud KMS module (encryption keys, HSM, rotation)

### 📋 Planned

- Task 14.6: Monitoring & Logging (Cloud Monitoring, Logging, Alerting)
- Task 14.7: CI/CD Pipelines (GitHub Actions integration)
- Task 14.8: Disaster Recovery (Backups, DR automation)
- Task 14.9: Deploy Staging Environment
- Task 14.10: Deploy Production Environment

---

## 📚 Additional Resources

- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Best Practices](https://cloud.google.com/architecture/framework)
- [HIPAA on GCP](https://cloud.google.com/security/compliance/hipaa)
- [Terraform Module Best Practices](https://www.terraform.io/docs/modules/index.html)

---

**Last Updated**: 2025-10-19 **Maintained by**: Platform Team **Version**: 1.0.0
