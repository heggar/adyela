# Staging Environment - Cost-Optimized HIPAA Infrastructure

**Cost**: $29-46/month (optimized for single-tester scenario) **Deployment
Status**: 🟢 Active (Load Balancer + DNS configured) **Environment**: Single
tester, internal testing only **Last Updated**: 2025-10-19

---

## 📋 Overview

This staging environment implements a **cost-optimized HIPAA-compliant
infrastructure** designed for internal testing with 1-2 users. The configuration
maintains production-like architecture while eliminating unnecessary features
for significant cost savings.

### ✅ Currently Deployed

| Component             | Status        | URL/Details                      | Cost/Month       |
| --------------------- | ------------- | -------------------------------- | ---------------- |
| **Load Balancer**     | ✅ Active     | 34.96.108.162                    | $18-25           |
| **DNS**               | ✅ Configured | staging.adyela.care              | $0               |
| **SSL Certificate**   | ✅ Active     | Google-managed                   | $0               |
| **Cloud Run Web**     | ✅ Running    | adyela-web-staging               | $5-10            |
| **Cloud Run API**     | ✅ Running    | adyela-api-staging               | $5-10            |
| **Secret Manager**    | ✅ Active     | 19 secrets                       | $1.20            |
| **VPC Network**       | ✅ Created    | No connector (cost optimization) | $0               |
| **Service Account**   | ✅ Created    | HIPAA-compliant                  | $0               |
| **Monitoring**        | ✅ Basic      | Uptime checks + alerts           | $0               |
| **Artifact Registry** | ✅ Active     | Docker images                    | $0.10            |
| **Cloud Storage**     | ✅ Active     | Static assets                    | $0.05            |
|                       |               | **Total**                        | **$29-46/month** |

### ❌ Disabled for Cost Optimization

| Component                   | Status        | Reason                              | Savings           |
| --------------------------- | ------------- | ----------------------------------- | ----------------- |
| **Cloud Armor**             | ❌ Disabled   | WAF not needed for internal testing | $17/month         |
| **BigQuery Log Sinks**      | ❌ Disabled   | Use Cloud Logging console directly  | $0.20/month       |
| **SMS Alerts**              | ❌ Disabled   | Email alerts sufficient             | $0.30/month       |
| **Cloud Trace**             | ❌ Disabled   | Not needed for 1-2 testers          | $0/month          |
| **Advanced SLOs**           | ⚠️ Simplified | Basic SLOs only (99% vs 99.9%)      | $0/month          |
| **Microservice Dashboards** | ❌ Disabled   | Single dashboard sufficient         | $0/month          |
|                             |               | **Total Savings**                   | **~$17-24/month** |

---

## 🌐 Access URLs

### Public Endpoints (HTTPS) - Unified Domain Structure

**All applications now under `staging.adyela.care` domain:**

```
Admin Panel (React):         https://staging.adyela.care
Patient App (Flutter Web):   https://patient.staging.adyela.care
Professional App (Flutter):  https://professional.staging.adyela.care
API:                         https://api.staging.adyela.care
API Docs:                    https://api.staging.adyela.care/docs
Health:                      https://api.staging.adyela.care/health
```

**Architecture:**

- All apps route through single GCP Load Balancer (IP: `34.96.108.162`)
- Subdomain routing via URL map (host rules)
- Single SSL certificate covering all 4 subdomains
- CORS configured for cross-origin requests

### Direct Cloud Run URLs (Backup)

```
Admin Web:       https://adyela-web-staging-<hash>-uc.a.run.app
Patient Web:     https://adyela-patient-web-staging-<hash>-uc.a.run.app
Professional:    https://adyela-professional-web-staging-<hash>-uc.a.run.app
API:             https://adyela-api-staging-<hash>-uc.a.run.app
```

### GCP Console Quick Links

```
Cloud Run:       https://console.cloud.google.com/run?project=adyela-staging
Load Balancer:   https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers?project=adyela-staging
Monitoring:      https://console.cloud.google.com/monitoring?project=adyela-staging
Logs:            https://console.cloud.google.com/logs/query?project=adyela-staging
Secrets:         https://console.cloud.google.com/security/secret-manager?project=adyela-staging
```

---

## 🚀 Quick Start

### Prerequisites

1. **GCP Project** with billing enabled (`adyela-staging`)
2. **Terraform** >= 1.5.0
3. **gcloud CLI** authenticated
4. **Backend configured** (GCS bucket for Terraform state)

### 1. Authenticate

```bash
# Login to GCP
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project adyela-staging
```

### 2. Initialize Terraform

```bash
cd infra/environments/staging

# Initialize (backend already configured)
terraform init

# Verify backend
cat backend.tf
```

### 3. Review Current State

```bash
# See what's deployed
terraform show

# Check for drift (expected in Cloud Run images)
terraform plan
```

### 4. Apply Infrastructure Changes

```bash
# ONLY apply for infrastructure changes
# NOT for application deployments (handled by CI/CD)

terraform plan   # Review changes
terraform apply  # Apply infrastructure changes only
```

---

## 📐 Architecture

### Current Infrastructure

```
┌──────────────────────────────────────────────────────────┐
│                      Internet                            │
└────────────────────┬─────────────────────────────────────┘
                     │
         ┌───────────▼───────────────┐
         │   Cloud Load Balancer     │
         │   IP: 34.96.108.162       │
         │   ✅ SSL Certificate      │
         │   ❌ Cloud Armor (disabled)│
         └─────┬──────────────┬──────┘
               │              │
    ┌──────────▼────┐    ┌───▼──────────────┐
    │ staging.      │    │ api.staging.     │
    │ adyela.care   │    │ adyela.care      │
    └──────┬────────┘    └───┬──────────────┘
           │                 │
    ┌──────▼─────────┐  ┌───▼──────────────┐
    │ Backend NEG    │  │ Backend NEG      │
    │ (Web)          │  │ (API)            │
    └──────┬─────────┘  └───┬──────────────┘
           │                │
    ┌──────▼─────────┐  ┌───▼──────────────┐
    │ Cloud Run      │  │ Cloud Run        │
    │ adyela-web-    │  │ adyela-api-      │
    │ staging        │  │ staging          │
    │                │  │                  │
    │ Min: 0         │  │ Min: 0           │
    │ Max: 2         │  │ Max: 2           │
    │ Scale-to-zero  │  │ Scale-to-zero    │
    └────────────────┘  └──────────────────┘
           │                │
           └────────┬───────┘
                    │
         ┌──────────▼──────────┐
         │   Service Account   │
         │   (HIPAA-compliant) │
         └──────────┬──────────┘
                    │
    ┌───────────────┼───────────────┐
    │               │               │
┌───▼─────┐  ┌──────▼──────┐  ┌────▼────┐
│Firestore│  │Secret Manager│  │Storage  │
│(NoSQL)  │  │(19 secrets)  │  │(Assets) │
└─────────┘  └─────────────┘  └─────────┘
```

### Monitoring & Logging

```
┌─────────────────────────────────────────┐
│       Cloud Monitoring (Basic)          │
├─────────────────────────────────────────┤
│ ✅ Uptime Checks (API + Web)            │
│ ✅ Basic Alert Policies                 │
│ ✅ Email Notifications                  │
│ ✅ Main Dashboard                       │
│                                         │
│ ❌ BigQuery Log Sinks (disabled)        │
│ ❌ Advanced SLOs (simplified)           │
│ ❌ Cloud Trace (disabled)               │
│ ❌ SMS Alerts (disabled)                │
│ ❌ Microservice Dashboards (disabled)   │
└─────────────────────────────────────────┘
```

---

## 💰 Cost Analysis

### Monthly Cost Breakdown (Optimized)

```
┌─────────────────────────────────────────┐
│ STAGING - OPTIMIZED FOR 1 TESTER       │
├─────────────────────────────────────────┤
│ Load Balancer:        $18-25/month     │  ✅ KEEP (DNS configured)
│ Cloud Run API:        $5-10/month      │  ✅ KEEP (scale-to-zero)
│ Cloud Run Web:        $5-10/month      │  ✅ KEEP (scale-to-zero)
│ Secret Manager:       $1.20/month      │  ✅ KEEP (19 secrets)
│ Artifact Registry:    $0.10/month      │  ✅ KEEP
│ Cloud Storage:        $0.05/month      │  ✅ KEEP
│ Monitoring:           $0/month         │  ✅ KEEP (basic, free tier)
├─────────────────────────────────────────┤
│ TOTAL:                $29-46/month     │
└─────────────────────────────────────────┘
```

### Cost Comparison

| Configuration                       | Monthly Cost | Use Case                      |
| ----------------------------------- | ------------ | ----------------------------- |
| **Original (Full Production-like)** | $46-70       | ❌ Too expensive for 1 tester |
| **Optimized (Current)**             | $29-46       | ✅ Balanced (keeps DNS + LB)  |
| **Minimal (No LB)**                 | $11-25       | ⚠️ Ugly URLs, migration work  |

**Decision**: Keep Load Balancer ($29-46/month) because:

- ✅ DNS already configured (staging.adyela.care)
- ✅ SSL certificate active
- ✅ Professional URLs for testing
- ✅ Same architecture as production
- ✅ No migration work needed

### Idle Cost (No Testing)

When no one is testing, Cloud Run scales to zero:

```
Cloud Run (scaled to zero):   $0/month
Load Balancer:                 $18-25/month
Secret Manager:                $1.20/month
Artifact Registry:             $0.10/month
Cloud Storage:                 $0.05/month
────────────────────────────────────────
TOTAL (idle):                  ~$20/month
```

---

## 🔧 Configuration Details

### Environment Variables

Set in `terraform.tfvars`:

```hcl
project_id   = "adyela-staging"
project_name = "adyela"
environment  = "staging"
region       = "us-central1"
alert_email  = "alerts@adyela.care"
```

### Secrets Configuration

**19 secrets managed by Secret Manager:**

```
Core Secrets:
- SECRET_KEY                    (API secret key)
- JWT_SECRET                    (JWT signing key)
- ENCRYPTION_KEY                (Data encryption)
- FIREBASE_PROJECT_ID           (Firebase config)
- FIREBASE_ADMIN_KEY            (Firebase admin)
- DATABASE_URL                  (DB connection)
- SMTP_CREDENTIALS              (Email)
- EXTERNAL_API_KEYS             (Third-party APIs)

OAuth Providers:
- OAUTH_GOOGLE_CLIENT_ID        (Google OAuth)
- OAUTH_GOOGLE_CLIENT_SECRET
- OAUTH_MICROSOFT_CLIENT_ID     (Microsoft OAuth)
- OAUTH_MICROSOFT_CLIENT_SECRET
- OAUTH_APPLE_CLIENT_ID         (Apple OAuth)
- OAUTH_APPLE_CLIENT_SECRET
- OAUTH_FACEBOOK_APP_ID         (Facebook OAuth)
- OAUTH_FACEBOOK_APP_SECRET
```

**Secret Rotation Policy**: 90 days **Access Control**: Service account only
(HIPAA-compliant)

### Cloud Run Configuration

```hcl
# Staging-specific settings
min_instances = 0    # Scale to zero for cost savings
max_instances = 2    # Limit max instances
memory        = "512Mi"  # API memory
cpu           = "1"      # 1 vCPU

# Environment
vpc_connector_name = null  # No VPC Connector (cost optimization)
```

### Load Balancer Configuration

```hcl
# Custom domain
domain = "staging.adyela.care"

# SSL
ssl_policy = "modern"  # TLS 1.2+

# Cloud Armor
# NOT deployed in staging (cost optimization)

# IAP (Identity-Aware Proxy)
iap_enabled = false  # Auth via Identity Platform OAuth
```

### Monitoring Configuration (Simplified)

```hcl
# ENABLED
enable_error_reporting_alerts = true   # Basic error detection
uptime_checks                 = 2      # API + Web (FREE)
email_notifications          = true   # Alert email

# DISABLED for cost optimization
enable_sms_alerts                = false  # No SMS
enable_log_sinks                 = false  # No BigQuery logs
enable_trace_alerts              = false  # No Cloud Trace
enable_microservices_dashboards  = false  # Single dashboard only

# SIMPLIFIED SLOs
availability_slo_target = 0.99    # 99% (vs 99.9% production)
latency_slo_target_ms   = 2000    # 2s (vs 1s production)
error_rate_slo_target   = 0.05    # 5% (vs 1% production)
slo_rolling_period_days = 7       # 7 days (vs 30 production)
```

---

## 🔒 Security Configuration

### What's Enabled ✅

**Network Security:**

- VPC network (no VPC Connector for cost optimization)
- Private subnet configuration
- Firewall rules (basic)

**Access Control:**

- Service account with least privilege
- IAM roles for Cloud Run
- Secret Manager access control

**SSL/TLS:**

- Google-managed SSL certificate
- HTTPS only (no HTTP)
- TLS 1.2+ (modern SSL policy)

**Authentication:**

- Identity Platform OAuth
- Firebase Authentication
- No IAP (auth handled at application level)

**Audit Logging:**

- Cloud Logging enabled
- Basic audit trails
- 30-day retention (free tier)

### What's Disabled ❌

**Cloud Armor (WAF)** - Not needed for internal testing:

- ❌ OWASP Top 10 protection
- ❌ DDoS mitigation
- ❌ Rate limiting
- ❌ IP allowlisting

**Rationale**: Staging is for internal testers only, no public access needed.

**Advanced Logging:**

- ❌ BigQuery log sinks
- ❌ Log analytics
- ❌ Long-term log retention (beyond 30 days)

**Rationale**: Use Cloud Logging console directly for debugging.

**Advanced Monitoring:**

- ❌ Cloud Trace (distributed tracing)
- ❌ Detailed performance metrics
- ❌ Microservice-specific dashboards

**Rationale**: 1-2 testers don't need advanced observability.

### HIPAA Compliance Notes

**Current Status**: 🟡 Basic HIPAA compliance

**Compliant:**

- ✅ Encryption in transit (HTTPS/TLS)
- ✅ Encryption at rest (Google-managed keys)
- ✅ Access control (service accounts)
- ✅ Audit logging (basic)
- ✅ Secret management

**Not Implemented (Staging):**

- ⚠️ Cloud Armor (add in production)
- ⚠️ VPC Service Controls (add in production)
- ⚠️ CMEK (customer-managed keys) - (add in production)
- ⚠️ Advanced audit logging (add in production)

**Production Requirements**: All missing features will be enabled before
production launch.

---

## 🧪 Testing & Validation

### Health Checks

```bash
# API health
curl https://api.staging.adyela.care/health

# Expected response:
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2025-10-19T12:00:00Z"
}

# Web health
curl https://staging.adyela.care
# Expected: 200 OK
```

### Load Balancer Verification

```bash
# Check Load Balancer
gcloud compute forwarding-rules list --project=adyela-staging

# Check SSL certificate
gcloud compute ssl-certificates describe \
  adyela-staging-ssl-cert \
  --global \
  --project=adyela-staging

# Check backends
gcloud compute backend-services list --project=adyela-staging
```

### DNS Verification

```bash
# Check DNS resolution
dig staging.adyela.care +short
# Expected: 34.96.108.162

dig api.staging.adyela.care +short
# Expected: 34.96.108.162

# Check SSL
curl -I https://staging.adyela.care
# Expected: 200 OK with valid SSL
```

### Cloud Run Verification

```bash
# Check Cloud Run services
gcloud run services list \
  --platform=managed \
  --region=us-central1 \
  --project=adyela-staging

# Get service details
gcloud run services describe adyela-api-staging \
  --platform=managed \
  --region=us-central1 \
  --project=adyela-staging

# Check current revision
gcloud run revisions list \
  --service=adyela-api-staging \
  --platform=managed \
  --region=us-central1 \
  --project=adyela-staging
```

### Monitoring Verification

```bash
# Check uptime checks
gcloud monitoring uptime list-configs --project=adyela-staging

# Check alert policies
gcloud alpha monitoring policies list --project=adyela-staging

# View recent alerts
gcloud logging read "resource.type=uptime_url" \
  --limit=10 \
  --project=adyela-staging
```

---

## 📦 Deployment Workflow

### Infrastructure vs Application Deployments

**CRITICAL DISTINCTION:**

| Type               | Tool                   | What Changes                                 | When               |
| ------------------ | ---------------------- | -------------------------------------------- | ------------------ |
| **Infrastructure** | Terraform              | VPC, Load Balancer, scaling config, env vars | Manual, on-demand  |
| **Application**    | CI/CD (GitHub Actions) | Docker images, code deployments              | Automatic, on push |

### Infrastructure Changes (Terraform)

**Use Terraform ONLY for:**

- Scaling configuration (min/max instances)
- Environment variables
- Secret references
- VPC/networking changes
- Resource limits (CPU/memory)
- Load Balancer configuration

```bash
cd infra/environments/staging

# Make changes to *.tf files
vim main.tf

# Review changes
terraform plan

# Apply infrastructure changes
terraform apply
```

### Application Deployments (CI/CD)

**GitHub Actions handles:**

- Building Docker images
- Pushing to Artifact Registry
- Deploying to Cloud Run
- Updating image tags

```bash
# Deployment triggered automatically by:
git push origin main

# CI/CD pipeline (.github/workflows/cd-staging.yml):
# 1. Build Docker image
# 2. Push to Artifact Registry
# 3. Deploy to Cloud Run
# 4. Update service with new image
```

### Expected Terraform Drift

**Always ignore drift in:**

- `template[0].containers[0].image` - Managed by CI/CD
- `template[0].labels["version"]` - Updated by CI/CD
- `client` / `client_version` - Metadata from gcloud

**This drift is EXPECTED and SAFE.** Do NOT apply Terraform to "fix" it.

### When to Apply Terraform

```bash
# ✅ APPLY when changing:
- Scaling (min_instances, max_instances)
- Environment variables
- Secret references
- VPC configuration
- Resource limits

# ❌ NEVER apply to:
- Sync Docker image versions
- Update application code
- Deploy new features
```

---

## 🎯 Upgrade Path

### From Staging → Pre-Production

**When**: 5-10 beta testers, external users

**Changes** (~$30-50/month total):

```hcl
# Add Cloud Armor (basic rules)
module "cloud_armor" {
  source = "../../modules/cloud-armor"

  # Basic protection only
  owasp_rules = ["sqli", "xss", "lfi"]
}

# Enable log sinks
enable_log_sinks = true

# Add SMS alerts
enable_sms_alerts = true

# Keep scale-to-zero
min_instances = 0
```

**Cost**: +$20-30/month

### From Pre-Production → Production

**When**: Real patients, launch

**Changes** (~$70-103/month total):

```hcl
# Full Cloud Armor
module "cloud_armor" {
  source = "../../modules/cloud-armor"

  # Full OWASP protection
  owasp_rules = "all"
  rate_limiting = true
  geo_blocking = true
}

# High availability
min_instances = 1  # No cold starts
max_instances = 10

# Advanced monitoring
enable_trace_alerts = true
enable_microservices_dashboards = true
availability_slo_target = 0.999  # 99.9%

# CMEK encryption
enable_cmek = true
```

**Cost**: +$40-60/month

### Migration Checklist

**Staging → Pre-Production:**

- [ ] Add Cloud Armor (basic)
- [ ] Enable log sinks
- [ ] Add SMS alerts
- [ ] Update DNS TTL
- [ ] Test with 5-10 users
- [ ] Load testing (k6)

**Pre-Production → Production:**

- [ ] Full Cloud Armor (OWASP)
- [ ] High availability (min_instances = 1)
- [ ] Advanced monitoring
- [ ] CMEK encryption
- [ ] Multi-region setup
- [ ] Disaster recovery plan
- [ ] External security audit
- [ ] HIPAA audit
- [ ] Compliance review

---

## 🚨 Troubleshooting

### Issue: Terraform shows drift in Cloud Run images

**Symptom:**

```
~ template[0].containers[0].image: "us-central1-docker.pkg.dev/.../adyela-api-staging:abc123" → "us-central1-docker.pkg.dev/.../adyela-api-staging:latest"
```

**Solution:** This is EXPECTED. CI/CD manages images, not Terraform. Ignore this
drift.

```bash
# DO NOT run:
terraform apply  # This will overwrite CI/CD deployment!

# Instead, accept the drift
# Or use lifecycle rule in Terraform:
lifecycle {
  ignore_changes = [
    template[0].containers[0].image,
    template[0].labels["version"]
  ]
}
```

### Issue: Load Balancer not routing traffic

**Debug steps:**

```bash
# 1. Check Load Balancer status
gcloud compute forwarding-rules describe adyela-staging-forwarding-rule \
  --global --project=adyela-staging

# 2. Check backend health
gcloud compute backend-services get-health adyela-staging-web-backend \
  --global --project=adyela-staging

# 3. Check Cloud Run service
gcloud run services describe adyela-web-staging \
  --platform=managed \
  --region=us-central1 \
  --project=adyela-staging \
  --format="value(status.url,status.conditions)"

# 4. Test direct Cloud Run URL
curl $(gcloud run services describe adyela-web-staging \
  --platform=managed \
  --region=us-central1 \
  --project=adyela-staging \
  --format="value(status.url)")
```

### Issue: SSL certificate not provisioning

**Symptom:** Certificate stuck in "PROVISIONING" state

**Solution:**

```bash
# 1. Check certificate status
gcloud compute ssl-certificates describe adyela-staging-ssl-cert \
  --global --project=adyela-staging \
  --format="value(managed.status,managed.domainStatus)"

# 2. Verify DNS is pointing to Load Balancer IP
dig staging.adyela.care +short
# Should return: 34.96.108.162

# 3. Wait (can take up to 60 minutes)
# Google needs to verify domain ownership

# 4. If stuck >2 hours, recreate certificate
terraform taint module.load_balancer.google_compute_managed_ssl_certificate.default
terraform apply
```

### Issue: High costs

**Debug steps:**

```bash
# 1. Check actual costs
gcloud billing accounts list
gcloud billing accounts get-cost \
  --billing-account=<ACCOUNT_ID> \
  --start-date=$(date -d '1 month ago' +%Y-%m-%d) \
  --end-date=$(date +%Y-%m-%d)

# 2. Check Cloud Run metrics
gcloud run services describe adyela-api-staging \
  --platform=managed \
  --region=us-central1 \
  --project=adyela-staging \
  --format="value(status.traffic[0].percent,spec.template.spec.containerConcurrency)"

# 3. Verify scale-to-zero
gcloud run services describe adyela-api-staging \
  --platform=managed \
  --region=us-central1 \
  --project=adyela-staging \
  --format="value(spec.template.metadata.annotations['autoscaling.knative.dev/minScale'])"
# Should be: 0

# 4. Check for runaway instances
gcloud logging read "resource.type=cloud_run_revision" \
  --limit=100 \
  --project=adyela-staging \
  --format="table(timestamp,severity,textPayload)"
```

### Issue: Secrets not accessible

**Debug steps:**

```bash
# 1. Check secret exists
gcloud secrets describe jwt-secret-key --project=adyela-staging

# 2. Check IAM permissions
gcloud secrets get-iam-policy jwt-secret-key --project=adyela-staging

# 3. Verify service account has access
gcloud projects get-iam-policy adyela-staging \
  --flatten="bindings[].members" \
  --format="table(bindings.role,bindings.members)" \
  --filter="bindings.members:serviceAccount:*"

# 4. Test secret access
gcloud secrets versions access latest --secret=jwt-secret-key \
  --project=adyela-staging
```

---

## 📚 Related Documentation

### Infrastructure Documentation

- [VPC Module README](../../modules/vpc/README.md)
- [Cloud Run Module README](../../modules/cloud-run/README.md)
- [Load Balancer Module README](../../modules/load-balancer/README.md)
- [Monitoring Module README](../../modules/monitoring/README.md)
- [Secret Manager Module README](../../modules/secret-manager/README.md)

### Cost Optimization Analysis

- [Cost Optimization Analysis](COST_OPTIMIZATION_ANALYSIS.md) - Original
  analysis
- [Revised Cost Optimization](REVISED_COST_OPTIMIZATION.md) - **Current
  strategy** (keep LB)

### Security Documentation

- [Security Modules README](SECURITY_MODULES_README.md)
- [Cloud Armor Configuration](../../modules/cloud-armor/README.md)
- [IAM Configuration](../../modules/iam/README.md)

### Deployment Guides

- [GCP Setup Guide](../../../docs/deployment/gcp-setup.md)
- [Architecture Validation](../../../docs/deployment/architecture-validation.md)
- [HIPAA Compliance Cost Analysis](../../../docs/deployment/hipaa-compliance-cost-analysis.md)

### Project Documentation

- [Project README](../../../README.md)
- [Claude Instructions](../../../CLAUDE.md)
- [Testing Strategy](../../../docs/quality/testing-strategy-microservices.md)

---

## 🤝 Support

**Questions?** Contact DevOps team **Issues?** Create a GitHub issue
**Documentation?** See `/docs` directory

---

## 📊 Summary

### Cost Efficiency

```
Original Setup:     $46-70/month (full production-like)
Optimized Setup:    $29-46/month (current)
Savings:            $17-24/month (37% reduction)
```

### Trade-offs Accepted

✅ **Kept for Production Parity:**

- Load Balancer (already deployed, DNS configured)
- Professional URLs (staging.adyela.care)
- SSL certificates (Google-managed)
- Same architecture as production

❌ **Removed for Cost Savings:**

- Cloud Armor ($17/month saved)
- BigQuery log sinks ($0.20/month saved)
- Advanced monitoring features
- SMS alerts ($0.30/month saved)

### Recommendation

**This configuration is OPTIMAL for:**

- 1-2 internal testers
- Development and testing phase
- Budget-conscious staging environment
- Production-like architecture validation

**Upgrade to pre-production when:**

- 5-10 beta testers needed
- External users access the system
- More comprehensive monitoring required
- Budget allows $50-70/month

---

**Environment**: Staging **Last Updated**: 2025-10-19 **Version**: 2.0.0
(Optimized) **Status**: 🟢 Active **Next Review**: Before beta launch
