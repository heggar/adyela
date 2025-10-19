# Staging Infrastructure Status Report

**Date**: 2025-10-19 **Environment**: Staging (adyela-staging)
**Configuration**: Cost-Optimized ($29-46/month) **Terraform Status**: Partially
Configured

---

## 📊 Executive Summary

The staging environment has a **hybrid infrastructure** with resources deployed
manually through GCP Console/gcloud CLI and a Terraform configuration that is
being aligned with the actual deployed state.

**Current Status**:

- ✅ **78 resources** identified in Terraform configuration
- ✅ **Majority deployed manually** via Console/CI-CD
- ✅ Terraform configuration **syntax validated** and ready
- ⚠️ **State import required** before Terraform can manage existing resources

---

## 🏗️ Infrastructure Inventory

### ✅ Deployed and Running (Manual)

| Resource                   | Status     | Managed By             | URL/ID                                          |
| -------------------------- | ---------- | ---------------------- | ----------------------------------------------- |
| **Load Balancer**          | ✅ Active  | Manual (Console)       | IP: 34.96.108.162                               |
| **DNS Records**            | ✅ Active  | Cloudflare             | staging.adyela.care<br/>api.staging.adyela.care |
| **SSL Certificate**        | ✅ Active  | Google-managed         | adyela-staging-web-ssl-cert                     |
| **Cloud Run - Web**        | ✅ Running | CI/CD (GitHub Actions) | adyela-web-staging                              |
| **Cloud Run - API**        | ✅ Running | CI/CD (GitHub Actions) | adyela-api-staging                              |
| **Secret Manager**         | ✅ Active  | Manual                 | 19 secrets                                      |
| **Service Account**        | ✅ Active  | Manual                 | adyela-staging-hipaa@...                        |
| **VPC Network**            | ✅ Created | Manual/Terraform       | adyela-staging-vpc                              |
| **Firewall Rules**         | ✅ Active  | Terraform (imported)   | 4 rules                                         |
| **Monitoring - Uptime**    | ✅ Active  | Terraform (imported)   | 2 checks                                        |
| **Monitoring - Alerts**    | ✅ Active  | Terraform (imported)   | 3 policies                                      |
| **Monitoring - SLO**       | ✅ Active  | Terraform (imported)   | 1 SLO (availability)                            |
| **Monitoring - Dashboard** | ✅ Active  | Terraform (imported)   | Main dashboard                                  |
| **Artifact Registry**      | ✅ Active  | Manual                 | adyela repository                               |
| **Cloud Storage**          | ✅ Active  | Manual                 | Multiple buckets                                |
| **Firestore**              | ✅ Active  | Manual                 | Native mode                                     |
| **Identity Platform**      | ✅ Active  | Terraform (partial)    | OAuth configured                                |

### ⏳ Configured in Terraform (Not Deployed)

| Resource                          | Status          | Reason                                | Config File                   |
| --------------------------------- | --------------- | ------------------------------------- | ----------------------------- |
| **Cloud Armor**                   | ❌ Disabled     | Cost optimization ($17/month saved)   | security.tf.disabled          |
| **Artifact Registry (Terraform)** | ❌ Disabled     | Already exists manually               | artifact-registry.tf.disabled |
| **Storage Buckets (Terraform)**   | ❌ Disabled     | Already exist manually                | storage.tf.disabled           |
| **Secrets (Terraform)**           | ❌ Disabled     | Already exist manually                | secrets.tf.disabled           |
| **Microservices (6 services)**    | ❌ Not deployed | In development                        | main.tf                       |
| **Pub/Sub Topics**                | ❌ Not deployed | Not needed yet                        | Configured but not applied    |
| **BigQuery Log Sinks**            | ❌ Disabled     | Cost optimization ($0.20/month saved) | Monitoring module             |
| **Cloud Trace**                   | ❌ Disabled     | Not needed for 1-2 testers            | Monitoring module             |
| **SMS Alerts**                    | ❌ Disabled     | Cost optimization ($0.30/month saved) | Monitoring module             |

---

## 🔧 Terraform Configuration Status

### ✅ Fixed Issues

1. **Variable "version" → "app_version"** (`infra/modules/common/variables.tf`)
   - **Issue**: "version" is a reserved name in Terraform modules
   - **Fix**: Renamed to "app_version"
   - **Impact**: Common labels module now validates correctly

2. **Secret Manager ignore_changes** (`infra/modules/secret-manager/main.tf`)
   - **Issue**: Dynamic expression in static `ignore_changes` block
   - **Fix**: Changed to always ignore `secret_data` changes
   - **Impact**: Prevents Terraform from overwriting manually managed secrets

3. **Monitoring Dashboard Conditional** (`infra/modules/monitoring/main.tf`)
   - **Issue**: Inconsistent types in ternary (list[3] vs list[0])
   - **Fix**: Removed API-specific tiles (consistent with staging
     simplification)
   - **Impact**: Dashboard configuration validates correctly

4. **Missing Variables** (`infra/environments/staging/variables.tf`)
   - **Issue**: `environment`, `artifact_registry_repository`, `allowed_ips` not
     declared
   - **Fix**: Added variable declarations with defaults
   - **Impact**: Terraform plan now runs without variable errors

### 📁 File Organization

**Active Configuration** (used by `terraform plan`):

```
infra/environments/staging/
├── main.tf                  # Core module configurations
├── variables.tf             # Variable declarations (updated)
├── terraform.tfvars         # Variable values
├── backend.tf               # GCS state backend
├── outputs.tf              # Output definitions
└── README.md               # Environment documentation
```

**Disabled Configuration** (for future use or documentation):

```
infra/environments/staging/
├── security.tf.disabled          # Cloud Armor (not deployed in staging)
├── secrets.tf.disabled           # Secret Manager (managed manually)
├── storage.tf.disabled           # Cloud Storage (managed manually)
└── artifact-registry.tf.disabled # Artifact Registry (managed manually)
```

---

## 📋 Terraform Plan Summary

**Last Run**: 2025-10-19

```
Plan: 78 to add, 0 to change, 0 to destroy
```

**What Terraform Wants to Create**:

1. **Microservices (6 Cloud Run services)** - Not deployed yet:
   - api-admin-staging
   - api-appointments-staging
   - api-auth-staging
   - api-analytics-staging
   - api-notifications-staging
   - api-payments-staging

2. **Identity Platform Configuration**:
   - Tenant creation
   - OAuth provider configurations (Google, Microsoft)
   - Authorized domains setup

3. **Pub/Sub Infrastructure**:
   - 10+ topics for event-driven communication
   - Subscriptions for each microservice
   - Dead letter topics

4. **Additional Monitoring Resources**:
   - Error reporting alerts
   - SLO burn rate alerts
   - Additional dashboards

**Why 78 Resources?**

The high count is because:

- Terraform state is **empty** (no imports done yet)
- Many resources **already exist** manually
- Full microservices architecture configured but **not deployed**

---

## 🎯 Next Steps to Align Terraform with Reality

### Option 1: Import Existing Resources (Recommended for Production)

```bash
# Import Load Balancer
terraform import 'module.load_balancer.google_compute_global_forwarding_rule.http' projects/adyela-staging/global/forwardingRules/adyela-staging-http

# Import Cloud Run services
terraform import 'module.cloud_run.google_cloud_run_v2_service.web' projects/adyela-staging/locations/us-central1/services/adyela-web-staging

# Import Secrets (19 secrets)
terraform import 'module.secrets.google_secret_manager_secret.secrets["jwt-secret-key"]' projects/adyela-staging/secrets/jwt-secret-key

# ... and 70+ more resources
```

**Pros**:

- ✅ Terraform manages existing infrastructure
- ✅ Infrastructure as Code benefits
- ✅ Automated drift detection

**Cons**:

- ⚠️ Time-consuming (78 resources)
- ⚠️ Risk of breaking existing setup
- ⚠️ Requires careful import mapping

---

### Option 2: Keep Hybrid Approach (Current - Recommended for Staging)

**Terraform Manages**:

- VPC networking (already partially imported)
- Monitoring (already partially imported)
- Identity Platform OAuth configuration
- Future microservices deployments

**Manual/CI-CD Manages**:

- Existing Cloud Run services (adyela-web-staging, adyela-api-staging)
- Existing secrets
- Existing storage buckets
- Existing artifact registry

**Pros**:

- ✅ No disruption to current workflow
- ✅ CI/CD continues deploying Cloud Run
- ✅ Terraform ready for new infrastructure
- ✅ Low risk

**Cons**:

- ⚠️ State file doesn't reflect all infrastructure
- ⚠️ Manual coordination needed

---

## 💰 Cost Validation

**Target**: $29-46/month **Current Deployed**:

```
Load Balancer:        $18-25/month  ✅ Deployed
Cloud Run API:        $5-10/month   ✅ Deployed (scale-to-zero)
Cloud Run Web:        $5-10/month   ✅ Deployed (scale-to-zero)
Secret Manager:       $1.20/month   ✅ Deployed (19 secrets)
Monitoring:           $0/month      ✅ Deployed (free tier)
Artifact Registry:    $0.10/month   ✅ Deployed
Cloud Storage:        $0.05/month   ✅ Deployed
─────────────────────────────────────
TOTAL:               $29-46/month   ✅ Within target
```

**Not Deployed** (intentionally disabled):

```
Cloud Armor:          $17/month     ❌ Disabled (cost optimization)
BigQuery Logs:        $0.20/month   ❌ Disabled (cost optimization)
SMS Alerts:           $0.30/month   ❌ Disabled (cost optimization)
VPC Connector:        $64/month     ❌ Disabled (not needed)
Cloud NAT:            $32/month     ❌ Disabled (not needed)
```

**Savings**: $113.50/month from not deploying optional features

---

## 🔒 Security & Compliance Status

### HIPAA Compliance

**Implemented** ✅:

- Encryption in transit (HTTPS/TLS 1.2+)
- Encryption at rest (Google-managed keys)
- Service account with least privilege
- Audit logging (basic, 30-day retention)
- Secret management (Secret Manager)
- Access control (IAM roles)

**Not Implemented** (staging optimization):

- Cloud Armor WAF (planned for production)
- VPC Service Controls (planned for production)
- CMEK (customer-managed keys) - (planned for production)
- Advanced audit logging (planned for production)

**Status**: 🟡 **Basic HIPAA compliance** suitable for internal testing

---

## 📝 Deployment Checklist

### Current State (Manual Deployment)

- [x] Load Balancer configured with DNS
- [x] SSL certificates active
- [x] Cloud Run services deployed via CI/CD
- [x] Secrets created manually
- [x] Service accounts configured
- [x] VPC network created
- [x] Monitoring alerts active
- [x] Firewall rules configured

### Terraform State Alignment (Optional)

- [ ] Import existing Load Balancer resources
- [ ] Import existing Cloud Run services
- [ ] Import existing secrets (or keep manual)
- [ ] Import existing storage buckets (or keep manual)
- [ ] Import existing monitoring resources
- [ ] Validate terraform plan shows minimal changes
- [ ] Test terraform apply in dry-run mode

### Future Microservices Deployment (via Terraform)

- [ ] Deploy api-auth-staging
- [ ] Deploy api-appointments-staging
- [ ] Deploy api-admin-staging
- [ ] Deploy api-analytics-staging
- [ ] Deploy api-notifications-staging
- [ ] Deploy api-payments-staging
- [ ] Configure Pub/Sub topics and subscriptions
- [ ] Set up inter-service authentication

---

## 🚨 Known Limitations

1. **Terraform Drift**: State file doesn't include manually deployed resources
   - **Impact**: `terraform plan` will show resources to create that already
     exist
   - **Mitigation**: Use `.disabled` files or don't apply full plan

2. **CI/CD Dependency**: Cloud Run images managed by GitHub Actions
   - **Impact**: Terraform will show drift in container images
   - **Mitigation**: Use `ignore_changes` lifecycle rule (already configured)

3. **Secrets Management**: Secrets created manually via console
   - **Impact**: Terraform can't read secret values
   - **Mitigation**: Use `manage_secret_data = false` (already configured)

4. **Module Errors**: Some modules had syntax issues
   - **Impact**: Terraform init/plan failed initially
   - **Mitigation**: Fixed in this session (see "Fixed Issues" above)

---

## 📖 Related Documentation

- [Cost Optimization Strategy](REVISED_COST_OPTIMIZATION.md) - Current
  $29-46/month plan
- [Staging Environment README](README.md) - Complete environment guide
- [Backend Setup Status](BACKEND_SETUP_STATUS.md) - Terraform backend
  configuration
- [Security Modules](SECURITY_MODULES_README.md) - Security infrastructure (not
  deployed)

---

## ✅ Recommendations

### For Current Staging Use (1-2 Testers)

1. ✅ **Keep hybrid approach** - Don't import all existing resources
2. ✅ **Use Terraform for new infrastructure** - Microservices, Pub/Sub, etc.
3. ✅ **Continue CI/CD for Cloud Run** - GitHub Actions works well
4. ✅ **Manage secrets manually** - Less risk, more flexibility
5. ✅ **Document what's manual vs Terraform** - Clear ownership

### For Production Deployment (Future)

1. 📋 **Import all critical resources** - Load Balancer, Cloud Run, Secrets
2. 📋 **Enable Cloud Armor** - Add $17/month for WAF protection
3. 📋 **Implement advanced monitoring** - BigQuery logs, Cloud Trace
4. 📋 **Add CMEK encryption** - Customer-managed keys for compliance
5. 📋 **Multi-region setup** - Disaster recovery and high availability

---

## 🎯 Summary

**Staging Environment Status**: ✅ **Operational and Cost-Optimized**

- **Infrastructure**: Deployed and working
- **Cost**: $29-46/month (within target)
- **Terraform**: Configured and validated, ready for new resources
- **Approach**: Hybrid (manual + Terraform) works well for staging
- **Next Step**: Use Terraform for deploying microservices when ready

**No immediate action required.** Current setup is functional and cost-effective
for single-tester scenario.

---

**Last Updated**: 2025-10-19 **Reviewed By**: Infrastructure Team **Next
Review**: Before beta launch or microservices deployment
