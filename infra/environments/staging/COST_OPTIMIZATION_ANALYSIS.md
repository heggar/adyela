# Cost Optimization Analysis - Staging Environment

**Date**: 2025-10-19 **Scenario**: Single tester, development/testing only
**Goal**: Minimize costs while maintaining functionality

---

## 📊 Current Cost Analysis

### Current Staging Infrastructure

| Resource                    | Status        | Monthly Cost           | Necessity      | Recommendation                  |
| --------------------------- | ------------- | ---------------------- | -------------- | ------------------------------- |
| **Cloud Run API**           | Deployed      | ~$5-10 (scale-to-zero) | ✅ ESSENTIAL   | Keep - scale to zero            |
| **Cloud Run Web**           | Deployed      | ~$5-10 (scale-to-zero) | ✅ ESSENTIAL   | Keep - scale to zero            |
| **Load Balancer**           | Deployed      | ~$18-25                | ⚠️ OPTIONAL    | **REMOVE** - use Cloud Run URLs |
| **Cloud Armor**             | Configured    | ~$17                   | ❌ NOT NEEDED  | **DISABLE** for staging         |
| **VPC Network**             | Created       | $0 (no connector)      | ✅ FREE        | Keep                            |
| **Service Account**         | Created       | $0                     | ✅ ESSENTIAL   | Keep                            |
| **Secret Manager**          | 19 secrets    | ~$1.20                 | ✅ ESSENTIAL   | Keep                            |
| **Monitoring - Uptime**     | 2 checks      | $0 (first 3 free)      | ✅ RECOMMENDED | Keep basic                      |
| **Monitoring - Alerts**     | 7 policies    | $0                     | ⚠️ OPTIONAL    | Reduce to 2-3                   |
| **Monitoring - SLOs**       | 3 SLOs        | $0                     | ❌ NOT NEEDED  | **DISABLE** for staging         |
| **Monitoring - Dashboards** | 1+ dashboards | $0                     | ⚠️ OPTIONAL    | Keep 1 basic                    |
| **Log Sinks (BigQuery)**    | 3 sinks       | ~$0.20                 | ❌ NOT NEEDED  | **DISABLE** - use basic logs    |
| **Artifact Registry**       | 1 repository  | ~$0.10                 | ✅ ESSENTIAL   | Keep                            |
| **Cloud Storage**           | Buckets       | ~$0.05                 | ✅ ESSENTIAL   | Keep                            |
| **Firestore**               | Database      | ~$0 (free tier)        | ✅ ESSENTIAL   | Keep                            |
|                             |               |                        |                |
| **CURRENT TOTAL**           |               | **~$46-70/month**      |                |                                 |
| **OPTIMIZED TOTAL**         |               | **~$11-25/month**      |                | **-76% savings**                |

---

## 🎯 Optimization Strategy

### Phase 1: Immediate Savings (Deploy Now)

#### 1. Remove Load Balancer (~$18-25/month savings)

**Current**: Load Balancer + SSL + Cloud Armor **Optimized**: Direct Cloud Run
URLs

```hcl
# staging/main.tf - COMMENT OUT or REMOVE

# module "load_balancer" {
#   source = "../../modules/load-balancer"
#   ...
# }
```

**Access URLs**:

- API: `https://adyela-api-staging-HASH-uc.a.run.app`
- Web: `https://adyela-web-staging-HASH-uc.a.run.app`

**Pros**:

- ✅ $18-25/month savings
- ✅ Simpler infrastructure
- ✅ Faster deployments (no LB updates)
- ✅ Built-in HTTPS via Cloud Run

**Cons**:

- ⚠️ Ugly URLs (acceptable for staging)
- ⚠️ No custom domain (not needed for testing)
- ⚠️ No WAF protection (not needed for staging)

---

#### 2. Disable Cloud Armor (~$17/month savings)

**Current**: Full WAF with OWASP rules **Optimized**: Not deployed in staging

```hcl
# staging/security.tf - DO NOT CREATE for staging
# Only enable in production
```

**Reasoning**:

- Staging is not publicly accessible (test users only)
- No real user data or traffic
- Can test security rules in production deployment later

---

#### 3. Simplify Monitoring (~$0 savings, but cleaner)

**Current**: 7 alert policies, 3 SLOs, multiple dashboards **Optimized**: 2
alert policies, 1 dashboard

```hcl
# staging/main.tf - monitoring configuration

module "monitoring" {
  source = "../../modules/monitoring"

  # ... basic config ...

  # DISABLE advanced features for staging
  enable_log_sinks              = false  # Save BigQuery costs
  enable_error_reporting_alerts = false  # Not needed for 1 tester
  enable_trace_alerts           = false  # Not needed
  enable_microservices_dashboards = false  # Not needed yet

  # Keep basic uptime monitoring only
  # 2 uptime checks (API + Web) = FREE
}
```

**Keep Only**:

- ✅ 2 uptime checks (API health, Web homepage)
- ✅ 1 basic dashboard
- ✅ 1 alert for downtime
- ✅ Email notifications

**Remove**:

- ❌ SLO tracking (no SLA for staging)
- ❌ Error budget alerts
- ❌ BigQuery log sinks
- ❌ Advanced dashboards
- ❌ SMS alerts

---

#### 4. Use Cloud Run Direct URLs

**Current**: Custom domain via Load Balancer **Optimized**: Cloud Run generated
URLs

```hcl
# staging/main.tf - Cloud Run configuration

module "cloud_run" {
  source = "../../modules/cloud-run"

  # ... config ...

  # Allow unauthenticated access (for testing)
  # No IAP, no Load Balancer needed

  # API URL will be auto-generated by Cloud Run
  # api_url = "https://adyela-api-staging-XXX-uc.a.run.app"
}
```

**Get URLs after deployment**:

```bash
gcloud run services describe adyela-api-staging --region=us-central1 --format='value(status.url)'
gcloud run services describe adyela-web-staging --region=us-central1 --format='value(status.url)'
```

---

### Phase 2: Additional Optimizations (Optional)

#### 5. Reduce Secret Count (optional, ~$0.60/month savings)

**Current**: 19 secrets **Optimized**: 10-12 essential secrets only

Remove staging-specific OAuth providers not being tested:

- Keep: Google, Microsoft (most common)
- Remove for now: Apple, Facebook (add when testing those features)

**Savings**: ~$0.60/month (9 secrets × $0.06)

---

#### 6. Shared Staging Environment (future, 50% savings)

If multiple projects share staging:

- Share Artifact Registry (~$0.05/month per project)
- Share monitoring dashboards
- Potential savings: ~$5-10/month per additional project

---

## 📋 Optimized Staging Configuration

### Essential Resources (Deploy)

```hcl
# infra/environments/staging/main.tf - OPTIMIZED

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ============================================================================
# ESSENTIAL: Service Account
# Cost: $0/month
# ============================================================================

module "service_account" {
  source = "../../modules/service-account"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
}

# ============================================================================
# ESSENTIAL: Secret Manager
# Cost: ~$0.60-1.20/month (10-19 secrets)
# ============================================================================

module "secrets" {
  source = "../../modules/secret-manager"

  project_id = var.project_id
  secrets    = var.staging_secrets  # Reduced list
}

# ============================================================================
# ESSENTIAL: Cloud Run Services (scale-to-zero)
# Cost: ~$10-20/month (usage-based, minimal for 1 tester)
# ============================================================================

module "cloud_run" {
  source = "../../modules/cloud-run"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  service_account_email = module.service_account.service_account_email
  vpc_connector_name    = null  # No VPC connector needed

  # Images
  api_image = var.api_image
  web_image = var.web_image

  # STAGING: Scale to zero for cost savings
  min_instances = 0  # Scale to zero when idle
  max_instances = 2  # Limit max instances

  # Memory/CPU: Minimal for testing
  api_memory = "512Mi"   # Reduced from 1Gi
  api_cpu    = "1"       # 1 vCPU sufficient
  web_memory = "256Mi"   # Minimal for frontend
  web_cpu    = "1"

  # Secrets
  hipaa_secrets = var.hipaa_secrets
}

# ============================================================================
# RECOMMENDED: Basic Monitoring (FREE)
# Cost: $0/month (first 3 uptime checks free)
# ============================================================================

module "monitoring" {
  source = "../../modules/monitoring"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  # Use Cloud Run URL instead of custom domain
  domain = module.cloud_run.api_service_url  # Dynamic URL

  # Alerts
  alert_email = var.alert_email

  # DISABLE expensive/unnecessary features for staging
  enable_sms_alerts                = false  # No SMS in staging
  enable_log_sinks                 = false  # No BigQuery logs
  enable_error_reporting_alerts    = false  # Use console directly
  enable_trace_alerts              = false  # Not needed
  enable_microservices_dashboards  = false  # Not needed yet
  enable_slack_notifications       = false  # Optional
  enable_pagerduty_notifications   = false  # Not for staging
}

# ============================================================================
# OPTIONAL: Artifact Registry (for CI/CD)
# Cost: ~$0.10/month
# ============================================================================

# Already exists, keep as-is

# ============================================================================
# OPTIONAL: Cloud Storage (for static assets, backups)
# Cost: ~$0.05/month
# ============================================================================

# Already exists, keep as-is

# ============================================================================
# OUTPUTS
# ============================================================================

output "api_url" {
  description = "Direct Cloud Run URL for API (no load balancer)"
  value       = module.cloud_run.api_service_url
}

output "web_url" {
  description = "Direct Cloud Run URL for Web (no load balancer)"
  value       = module.cloud_run.web_service_url
}

output "service_account_email" {
  description = "Service account for Cloud Run"
  value       = module.service_account.service_account_email
}

output "monitoring_dashboard" {
  description = "Monitoring dashboard URL"
  value       = module.monitoring.dashboard_url
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost for staging"
  value       = "$11-25/month (optimized for single tester)"
}
```

---

## 💰 Cost Comparison

### Before Optimization

```
┌─────────────────────────────────────────┐
│ STAGING - FULL PRODUCTION-LIKE SETUP   │
├─────────────────────────────────────────┤
│ Load Balancer:        $18-25/month     │
│ Cloud Armor:          $17/month        │
│ Cloud Run (API):      $5-10/month      │
│ Cloud Run (Web):      $5-10/month      │
│ Secret Manager:       $1.20/month      │
│ BigQuery Logs:        $0.20/month      │
│ Artifact Registry:    $0.10/month      │
│ Cloud Storage:        $0.05/month      │
├─────────────────────────────────────────┤
│ TOTAL:                $46-70/month     │
└─────────────────────────────────────────┘
```

### After Optimization

```
┌─────────────────────────────────────────┐
│ STAGING - OPTIMIZED FOR TESTING         │
├─────────────────────────────────────────┤
│ Cloud Run (API):      $5-10/month      │
│ Cloud Run (Web):      $5-10/month      │
│ Secret Manager:       $0.60/month      │  (10 secrets)
│ Monitoring:           $0/month         │  (basic, free tier)
│ Artifact Registry:    $0.10/month      │
│ Cloud Storage:        $0.05/month      │
├─────────────────────────────────────────┤
│ TOTAL:                $11-25/month     │
│ SAVINGS:              $35-45/month     │  (-76%)
└─────────────────────────────────────────┘
```

### Zero-Usage Scenario (No Testing)

If no one is testing (Cloud Run scales to zero):

```
┌─────────────────────────────────────────┐
│ STAGING - IDLE (NO TRAFFIC)            │
├─────────────────────────────────────────┤
│ Cloud Run:            $0/month         │  (scaled to zero)
│ Secret Manager:       $0.60/month      │
│ Artifact Registry:    $0.10/month      │
│ Cloud Storage:        $0.05/month      │
├─────────────────────────────────────────┤
│ TOTAL:                ~$0.75/month     │
└─────────────────────────────────────────┘
```

---

## 🚀 Deployment Strategy

### Stage 1: Testing Phase (Current)

**Duration**: 1-3 months **Users**: 1-2 testers **Configuration**: Optimized
staging (above)

**Monthly Cost**: $11-25/month

**Features**:

- ✅ Full application functionality
- ✅ Direct Cloud Run URLs (HTTPS)
- ✅ Basic uptime monitoring
- ✅ Email alerts for downtime
- ✅ Scale-to-zero cost savings
- ❌ No custom domain
- ❌ No WAF/DDoS protection
- ❌ No advanced monitoring

---

### Stage 2: Pre-Production (Future)

**Duration**: 1-2 months before production **Users**: 5-10 beta testers
**Configuration**: Add some production features

**Monthly Cost**: $30-50/month

**Add**:

- ✅ Custom domain (staging.adyela.care)
- ✅ Basic Cloud Armor (essential rules only)
- ✅ More comprehensive monitoring
- ✅ Log sinks for debugging
- ⚠️ Still scale-to-zero

---

### Stage 3: Production

**Duration**: Post-launch **Users**: Real patients and professionals
**Configuration**: Full production setup

**Monthly Cost**: $70-103/month (target)

**Add**:

- ✅ Full Cloud Armor with OWASP rules
- ✅ Advanced monitoring (SLOs, error budgets)
- ✅ Multi-region deployment
- ✅ High availability (min instances > 0)
- ✅ Disaster recovery
- ✅ Advanced alerting (SMS, PagerDuty)
- ✅ Log analytics with BigQuery
- ✅ Performance monitoring
- ✅ Security scanning

---

## 📝 Implementation Checklist

### Immediate Actions (Do Now)

- [ ] Comment out Load Balancer module in `staging/main.tf`
- [ ] Remove `staging/security.tf` (Cloud Armor)
- [ ] Update monitoring config to disable advanced features
- [ ] Update Cloud Run to use direct URLs
- [ ] Document Cloud Run URLs for team
- [ ] Update CI/CD to deploy without Load Balancer
- [ ] Test application with new URLs
- [ ] Update documentation with new access URLs

### Configuration Files to Modify

1. **`infra/environments/staging/main.tf`**
   - Comment out `module "load_balancer"`
   - Update `module "monitoring"` with optimized config

2. **`infra/environments/staging/security.tf`**
   - Rename to `security.tf.disabled` or delete

3. **`infra/environments/staging/terraform.tfvars`**
   - Add `enable_load_balancer = false`
   - Add `enable_cloud_armor = false`

4. **`.github/workflows/*.yml`** (CI/CD)
   - Update to use Cloud Run URLs
   - Remove Load Balancer deployment steps

---

## 🎯 Cost Monitoring

### Weekly Review

Check actual costs:

```bash
# View current month costs
gcloud billing accounts list
gcloud billing accounts get-cost --billing-account=ACCOUNT_ID

# Cloud Run specific costs
gcloud run services describe adyela-api-staging --region=us-central1 --format="value(status.traffic)"
```

### Monthly Budget Alert

Set up budget alert at $30/month:

```bash
gcloud billing budgets create \
  --billing-account=ACCOUNT_ID \
  --display-name="Staging Monthly Budget" \
  --budget-amount=30USD \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90 \
  --threshold-rule=percent=100
```

---

## 📊 Savings Summary

| Optimization              | Monthly Savings  | Difficulty | Priority          |
| ------------------------- | ---------------- | ---------- | ----------------- |
| Remove Load Balancer      | $18-25           | Easy       | ✅ HIGH           |
| Disable Cloud Armor       | $17              | Easy       | ✅ HIGH           |
| Disable BigQuery Logs     | $0.20            | Easy       | ✅ HIGH           |
| Reduce secrets (optional) | $0.60            | Easy       | ⚠️ MEDIUM         |
| **TOTAL SAVINGS**         | **$35-45/month** |            | **76% reduction** |

---

## ⚠️ Important Notes

1. **URLs will change**: Team must use Cloud Run URLs instead of
   staging.adyela.care
2. **No WAF protection**: Don't expose staging to untrusted users
3. **Basic monitoring only**: Use GCP Console for detailed debugging
4. **Scale-to-zero**: First request after idle will be slow (cold start ~5-10
   sec)
5. **Production will be different**: This is staging-specific optimization

---

## ✅ Recommended: Optimized Staging

**For 1 tester, testing phase (1-3 months)**:

- Cost: **$11-25/month** (vs $46-70 current)
- Savings: **76%** ($35-45/month)
- Trade-offs: Minimal, acceptable for testing
- Recommendation: **Implement immediately**

---

**Next Steps**: ¿Quieres que implemente esta configuración optimizada ahora?
