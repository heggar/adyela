# Disaster Recovery Activation Procedures

**Version**: 1.0.0 **Last Updated**: 2025-10-19 **Owner**: Infrastructure Team
**Classification**: PRODUCTION ACTIVATION ONLY

---

## 📋 Overview

This document provides step-by-step procedures for **activating** disaster
recovery infrastructure in production for the first time. This is a **planned,
non-emergency** activity that should be executed during a maintenance window.

**IMPORTANT DISTINCTIONS:**

| Document                                        | Purpose                                | When to Use                              |
| ----------------------------------------------- | -------------------------------------- | ---------------------------------------- |
| **This Document** (dr-activation-procedures.md) | First-time DR activation in production | Planned deployment, NOT during emergency |
| **disaster-recovery-runbook.md**                | Emergency failover procedures          | During actual disaster/outage            |

---

## 🎯 Activation Objectives

**What This Achieves:**

- Deploy DR infrastructure in secondary region (us-east1)
- Create cross-region read replicas for Cloud SQL
- Configure multi-region Firestore (if not already done)
- Setup dual/multi-region storage buckets
- Enable monitoring and alerting for DR components
- Validate DR readiness without customer impact

**What This Does NOT Do:**

- Serve production traffic from secondary region (remains standby)
- Promote replicas to primary (that's failover, not activation)
- Migrate data (data replication is automatic)

**Success Criteria:**

- ✅ All DR resources deployed and healthy
- ✅ Replica lag <5 minutes
- ✅ Monitoring alerts configured
- ✅ DR costs within budget ($300-500/month)
- ✅ Zero customer impact during activation
- ✅ Quarterly DR drills scheduled

---

## 💰 Cost Impact

### Before DR Activation (Current State)

```
Cloud Run (single region):        $70-90/month
Cloud SQL (single region):         $60-80/month
Firestore (single region):         $30-50/month
Storage (single region):           $20-30/month
───────────────────────────────────────────────
TOTAL:                             ~$180-250/month
```

### After DR Activation (Production State)

```
Cloud Run DR (cold standby):       +$20-40/month
Cloud SQL Replica:                 +$85-110/month
Firestore (multi-region):          +$15-25/month (1.5x current)
Storage (dual-region):             +$30-60/month
Monitoring & Alerts:               +$10-15/month
───────────────────────────────────────────────
ADDITIONAL COST:                   ~$160-250/month
NEW TOTAL:                         ~$340-500/month
```

**Budget Approval Required**: Yes (budgeted increase of ~$200-300/month)

---

## ⏰ Timeline and Planning

### Preparation Phase (1 week before)

**Week Before Activation:**

- [ ] Review and approve budget increase
- [ ] Schedule maintenance window (low traffic period)
- [ ] Notify stakeholders of planned maintenance
- [ ] Review this document with team
- [ ] Test activation in staging environment
- [ ] Prepare rollback plan
- [ ] Update on-call rotation

### Activation Window

**Recommended Time**: Saturday 02:00-06:00 UTC (Friday evening US time)

**Duration Estimates**:

- Cloud Run DR: 30-45 minutes
- Cloud SQL Replica: 60-90 minutes (initial sync)
- Firestore Migration: 2-4 hours (if needed)
- Storage Setup: 15-30 minutes
- Monitoring Config: 15-20 minutes
- Validation: 30-45 minutes
- **TOTAL**: 3-6 hours (with Firestore migration) or 2-3 hours (without)

### Post-Activation

- [ ] Validate all components (Day 1)
- [ ] Monitor costs daily (Week 1)
- [ ] First DR drill (Week 2)
- [ ] Post-activation review (Week 4)

---

## 📝 Pre-Activation Checklist

### Technical Prerequisites

- [ ] Terraform >=1.0 installed
- [ ] gcloud CLI authenticated and configured
- [ ] Access to `adyela-production` GCP project
- [ ] Terraform state bucket accessible
- [ ] Required IAM permissions (Project Editor or Owner)
- [ ] Access to Secret Manager for credentials

### Documentation Reviewed

- [ ] [DR Module README](../../infra/modules/disaster-recovery/README.md)
- [ ] [Disaster Recovery Runbook](./disaster-recovery-runbook.md) (for
      reference)
- [ ] [Architecture Validation](./architecture-validation.md)
- [ ] Cost estimates and budget approval obtained

### Stakeholder Communications

- [ ] Maintenance window communicated (72 hours notice)
- [ ] Customer-facing status page prepared
- [ ] Internal team notified (#engineering, #product)
- [ ] On-call team briefed on activation plan

### Backup Strategy

- [ ] Current Cloud SQL backup verified (within 24 hours)
- [ ] Firestore export completed successfully
- [ ] Storage bucket snapshots available (if applicable)
- [ ] Rollback procedure documented and understood

---

## 🚀 Activation Procedures

### Phase 1: Terraform Configuration (30 minutes)

#### Step 1.1: Update Production Variables

Edit `infra/environments/production/terraform.tfvars`:

```hcl
# ============================================================================
# DISASTER RECOVERY CONFIGURATION
# ============================================================================

# Enable DR components (SET TO TRUE for production activation)
enable_cloud_run_dr  = true   # Changed from false
enable_firestore_dr  = true   # Changed from false (if migrating to multi-region)
enable_cloud_sql_dr  = true   # Changed from false
enable_storage_dr    = true   # Changed from false

# Regional configuration
primary_region   = "us-central1"
secondary_region = "us-east1"

# RTO/RPO targets
rto_minutes = 15   # <15 minutes recovery time
rpo_minutes = 60   # <1 hour data loss acceptable

# Cloud Run DR configuration
cloud_run_services = [
  {
    name  = "adyela-web-production"
    image = "us-central1-docker.pkg.dev/adyela-production/adyela/web:latest"
    min_instances = 0  # Cold standby
    max_instances = 10
    cpu_limit     = "2"
    memory_limit  = "1Gi"
  },
  {
    name  = "adyela-api-production"
    image = "us-central1-docker.pkg.dev/adyela-production/adyela/api:latest"
    min_instances = 0  # Cold standby
    max_instances = 10
    cpu_limit     = "2"
    memory_limit  = "2Gi"
  }
]

min_secondary_instances = 0  # Cold standby (cost optimization)

# Cloud SQL DR configuration
cloud_sql_primary_instance = "adyela-db-production"
cloud_sql_replica_tier     = "db-custom-2-7680"  # Match primary tier

# Firestore DR configuration
firestore_multi_region_location = "nam5"  # North America multi-region

# Storage DR configuration
storage_buckets_for_dr = [
  {
    name          = "adyela-production-uploads"
    storage_class = "STANDARD"
    versioning    = true
    quota_gb      = 500
  },
  {
    name          = "adyela-production-backups"
    storage_class = "NEARLINE"
    versioning    = true
    quota_gb      = 1000
  }
]

storage_replication_type  = "dual-region"
storage_dr_location       = "NAM4"  # Iowa + South Carolina
enable_storage_turbo_replication = false  # Cost optimization

# Monitoring configuration
enable_dr_monitoring = true
dr_notification_channels = [
  "projects/adyela-production/notificationChannels/EMAIL_CHANNEL_ID",
  "projects/adyela-production/notificationChannels/PAGERDUTY_CHANNEL_ID"
]

# Cost control
enable_cost_alerts    = true
monthly_dr_budget_usd = 500  # Alert if DR costs exceed $500/month
```

#### Step 1.2: Validate Terraform Configuration

```bash
cd infra/environments/production

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Expected output: Success! The configuration is valid.
```

#### Step 1.3: Review Terraform Plan

```bash
# Generate execution plan
terraform plan -var-file=terraform.tfvars -out=dr-activation.tfplan

# Review output carefully:
# - Resources to be created (~40-60 resources)
# - No resources to be destroyed (unless intentional)
# - Estimated costs align with budget
```

**Review Checklist**:

- [ ] Cloud Run services in us-east1 with `-dr` suffix
- [ ] Cloud SQL replica with `failover_target = true`
- [ ] Firestore database location change (if applicable)
- [ ] Storage buckets with dual-region location
- [ ] Monitoring alert policies created
- [ ] No destruction of existing resources

---

### Phase 2: Cloud Run DR Deployment (30-45 minutes)

#### Step 2.1: Deploy Cloud Run Services to Secondary Region

```bash
# Apply Terraform for Cloud Run DR module only
terraform apply -target=module.disaster_recovery.module.multi_region_cloud_run -var-file=terraform.tfvars

# Confirm when prompted (review resource list)
```

#### Step 2.2: Verify Secondary Services

```bash
# List DR services
gcloud run services list \
  --region=us-east1 \
  --project=adyela-production \
  --filter="labels.disaster_recovery=enabled"

# Expected output:
# NAME                       REGION     URL                                                  READY
# adyela-web-production-dr   us-east1   https://adyela-web-production-dr-xxx-ue.a.run.app    Yes
# adyela-api-production-dr   us-east1   https://adyela-api-production-dr-xxx-ue.a.run.app    Yes
```

#### Step 2.3: Test Secondary Service Health

```bash
# Test health endpoints
for SERVICE in adyela-web-production-dr adyela-api-production-dr; do
  URL=$(gcloud run services describe $SERVICE --region=us-east1 --project=adyela-production --format='value(status.url)')
  echo "Testing $SERVICE: $URL/health"
  curl -s "$URL/health" | jq
done

# Expected: { "status": "healthy", "version": "x.y.z", "region": "us-east1" }
```

#### Step 2.4: Verify Cold Standby Configuration

```bash
# Check min instances (should be 0 for cold standby)
gcloud run services describe adyela-web-production-dr \
  --region=us-east1 \
  --project=adyela-production \
  --format="value(spec.template.metadata.annotations['autoscaling.knative.dev/minScale'])"

# Expected: 0 (cold standby mode)
```

**Validation Checklist**:

- [ ] All DR services deployed successfully
- [ ] Health checks returning 200 OK
- [ ] Min instances = 0 (cold standby)
- [ ] No errors in Cloud Run logs
- [ ] Estimated cost: $20-40/month

---

### Phase 3: Cloud SQL Replica Deployment (60-90 minutes)

#### Step 3.1: Create Cross-Region Read Replica

```bash
# Apply Terraform for Cloud SQL DR module
terraform apply -target=module.disaster_recovery.module.cloud_sql_dr -var-file=terraform.tfvars

# Confirm when prompted
# WARNING: Initial replication can take 30-60 minutes for large databases
```

#### Step 3.2: Monitor Replica Creation

```bash
# Watch replica creation progress
watch -n 30 'gcloud sql operations list \
  --instance=adyela-db-production-dr-us-east1 \
  --project=adyela-production \
  --limit=5 \
  --format="table(name, operationType, status, startTime, endTime)"'

# Wait for CREATE_REPLICA operation to show status: DONE
```

#### Step 3.3: Verify Replica Configuration

```bash
# Check replica status
gcloud sql instances describe adyela-db-production-dr-us-east1 \
  --project=adyela-production \
  --format="yaml(state, replicaConfiguration, settings.tier, settings.availabilityType)"

# Expected:
# state: RUNNABLE
# replicaConfiguration:
#   failoverTarget: true
# settings:
#   tier: db-custom-2-7680
#   availabilityType: ZONAL
```

#### Step 3.4: Monitor Replication Lag

```bash
# Check initial replication lag
gcloud sql instances describe adyela-db-production-dr-us-east1 \
  --project=adyela-production \
  --format="value(replicaConfiguration.failoverTarget, state)"

# Monitor lag continuously (should decrease over time)
watch -n 60 'gcloud logging read \
  "resource.type=cloudsql_database AND resource.labels.database_id=adyela-production:adyela-db-production-dr-us-east1 AND metric.type=cloudsql.googleapis.com/database/replication/replica_lag" \
  --limit=1 \
  --project=adyela-production \
  --format="value(jsonPayload.lag_seconds)"'

# Target: <300 seconds (5 minutes)
```

#### Step 3.5: Test Replica Connectivity (Read-Only)

```bash
# Get replica IP address
REPLICA_IP=$(gcloud sql instances describe adyela-db-production-dr-us-east1 \
  --project=adyela-production \
  --format='value(ipAddresses[0].ipAddress)')

# Test connection via Cloud SQL Proxy (from Cloud Shell or bastion)
cloud_sql_proxy -instances=adyela-production:us-east1:adyela-db-production-dr-us-east1=tcp:5433 &

# Test read query
psql -h localhost -p 5433 -U postgres -d adyela -c "SELECT COUNT(*) FROM appointments;"

# Should return current count (read-only access)
```

**Validation Checklist**:

- [ ] Replica created successfully (state: RUNNABLE)
- [ ] Failover target enabled
- [ ] Replication lag <5 minutes
- [ ] Read queries working
- [ ] Monitoring alerts configured
- [ ] Estimated cost: $85-110/month

---

### Phase 4: Firestore Multi-Region Migration (2-4 hours) [OPTIONAL]

⚠️ **WARNING**: This is a BREAKING change requiring downtime. Only execute if
Firestore is currently single-region.

**Current State Assessment**:

```bash
# Check current Firestore configuration
gcloud firestore databases describe (default) \
  --project=adyela-production \
  --format="value(locationId, type)"

# If output is "us-central1" → Migration needed
# If output is "nam5" or other multi-region → Skip this phase
```

**If Migration Needed**, follow these sub-steps:

#### Step 4.1: Schedule Maintenance Window

**CRITICAL**: This requires 2-4 hours of application downtime.

- [ ] Notify users 72 hours in advance
- [ ] Update status page with maintenance notice
- [ ] Prepare customer communication
- [ ] Brief support team

#### Step 4.2: Export Existing Firestore Data

```bash
# Create export bucket (if not exists)
gsutil mb -p adyela-production -c STANDARD -l US gs://adyela-production-firestore-exports

# Export all collections
gcloud firestore export gs://adyela-production-firestore-exports/migration-$(date +%Y%m%d-%H%M%S) \
  --project=adyela-production

# Wait for export to complete (check operations)
gcloud firestore operations list --project=adyela-production

# Verify export
gsutil ls -r gs://adyela-production-firestore-exports/migration-*
```

#### Step 4.3: Delete Single-Region Database

⚠️ **DESTRUCTIVE**: Only proceed after verifying successful export.

```bash
# Disable deletion protection first (via console or Terraform)
# Then delete database
gcloud firestore databases delete (default) \
  --project=adyela-production

# Confirmation required - type: adyela-production
```

#### Step 4.4: Create Multi-Region Database

```bash
# Apply Terraform to create multi-region Firestore
terraform apply -target=module.disaster_recovery.module.firestore_replication -var-file=terraform.tfvars

# This creates a new database with location_id = "nam5"
```

#### Step 4.5: Import Data to New Database

```bash
# Get latest export path
EXPORT_PATH=$(gsutil ls gs://adyela-production-firestore-exports/ | sort | tail -1)

# Import data
gcloud firestore import $EXPORT_PATH \
  --project=adyela-production

# Monitor import progress
watch -n 30 'gcloud firestore operations list --project=adyela-production --limit=1'
```

#### Step 4.6: Redeploy Security Rules

```bash
# Redeploy Firestore security rules
gcloud firestore rules deploy firestore.rules \
  --project=adyela-production

# Verify rules deployed
gcloud firestore rules list --project=adyela-production
```

#### Step 4.7: Redeploy Indexes

```bash
# Redeploy Firestore indexes
gcloud firestore indexes create --project=adyela-production

# Wait for indexes to build (can take 10-30 minutes)
watch -n 60 'gcloud firestore indexes list --project=adyela-production'
```

#### Step 4.8: Validate Data Integrity

```bash
# Compare document counts before and after
# (Use application API or custom script)

# Test critical queries
curl https://api.adyela.care/api/v1/professionals?limit=10
curl https://api.adyela.care/api/v1/appointments?userId=test

# Verify no errors in logs
gcloud logging read "severity>=ERROR AND resource.type=cloud_firestore_database" \
  --project=adyela-production \
  --limit=50
```

**Validation Checklist**:

- [ ] Multi-region Firestore created (nam5)
- [ ] All data imported successfully
- [ ] Document counts match pre-migration
- [ ] Security rules redeployed
- [ ] Indexes built and active
- [ ] Application queries working
- [ ] No errors in logs
- [ ] Estimated cost increase: +$15-25/month

---

### Phase 5: Cross-Region Storage Deployment (15-30 minutes)

#### Step 5.1: Create Dual-Region Storage Buckets

```bash
# Apply Terraform for storage DR module
terraform apply -target=module.disaster_recovery.module.cross_region_storage -var-file=terraform.tfvars

# Confirm when prompted
```

#### Step 5.2: Migrate Existing Data (if needed)

**Option A: For NEW buckets (recommended)**

- Create new dual-region buckets with different names
- Update application to use new buckets
- Copy data asynchronously in background

**Option B: For REPLACING existing buckets**

```bash
# Copy data from single-region to dual-region bucket
gsutil -m rsync -r -d \
  gs://adyela-production-uploads-old \
  gs://adyela-production-uploads

# Verify copy completed
gsutil du -sh gs://adyela-production-uploads
gsutil du -sh gs://adyela-production-uploads-old

# Update application to use new bucket
# Delete old bucket after verification
```

#### Step 5.3: Verify Storage Configuration

```bash
# Check bucket locations
for BUCKET in adyela-production-uploads adyela-production-backups; do
  echo "Checking $BUCKET..."
  gsutil ls -L gs://$BUCKET | grep -E "Location|Storage class|Versioning"
done

# Expected:
# Location: NAM4 (dual-region)
# Storage class: STANDARD
# Versioning enabled: True
```

#### Step 5.4: Test Upload/Download

```bash
# Test write
echo "DR activation test $(date)" | gsutil cp - gs://adyela-production-uploads/dr-test.txt

# Test read
gsutil cat gs://adyela-production-uploads/dr-test.txt

# Test versioning
gsutil ls -a gs://adyela-production-uploads/dr-test.txt

# Cleanup
gsutil rm gs://adyela-production-uploads/dr-test.txt
```

**Validation Checklist**:

- [ ] Dual-region buckets created
- [ ] Versioning enabled
- [ ] Lifecycle rules configured
- [ ] Data migrated (if applicable)
- [ ] Upload/download working
- [ ] No errors in logs
- [ ] Estimated cost: +$30-60/month

---

### Phase 6: Monitoring and Alerting (15-20 minutes)

#### Step 6.1: Verify Alert Policies Created

```bash
# List DR alert policies
gcloud alpha monitoring policies list \
  --project=adyela-production \
  --filter="displayName~DR" \
  --format="table(displayName, enabled, notificationChannels)"

# Expected policies:
# - [DR] Cloud SQL Replica Lag High
# - [DR] Cloud SQL Replica Down
# - [DR] Secondary Service Down - adyela-web-production
# - [DR] Secondary Service Down - adyela-api-production
# - [DR] Firestore Backup Failure (if applicable)
# - [DR] Storage Quota Alert (if quota set)
```

#### Step 6.2: Test Notification Channels

```bash
# Test email notification
gcloud alpha monitoring channels describe CHANNEL_ID \
  --project=adyela-production

# Trigger test alert (optional)
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Test DR Alert" \
  --condition-display-name="Test" \
  --condition-threshold-value=0 \
  --project=adyela-production

# Delete test alert after verification
```

#### Step 6.3: Configure Monitoring Dashboard

```bash
# Create custom DR dashboard (via console or API)
# Include metrics:
# - Cloud Run request count (secondary region)
# - Cloud SQL replica lag
# - Firestore operation latency
# - Storage bucket size
# - DR component costs
```

**Validation Checklist**:

- [ ] All DR alert policies created
- [ ] Notification channels configured
- [ ] Test alerts received
- [ ] Monitoring dashboard created
- [ ] Estimated cost: +$10-15/month

---

## ✅ Final Validation

### Comprehensive Health Check (30 minutes)

```bash
# 1. Verify all DR components deployed
terraform output -json dr_components_enabled

# Expected:
# {
#   "cloud_run": true,
#   "firestore": true,
#   "cloud_sql": true,
#   "storage": true,
#   "monitoring": true
# }

# 2. Check DR readiness status
terraform output -json dr_readiness_checklist

# All items should be true

# 3. Verify RTO/RPO targets configured
terraform output -json dr_targets

# Expected:
# {
#   "rto_minutes": 15,
#   "rpo_minutes": 60
# }

# 4. Review cost estimates
terraform output -json estimated_monthly_cost_usd

# Verify within budget ($300-500/month)

# 5. Check secondary region health
gcloud run services list --region=us-east1 --project=adyela-production
gcloud sql instances list --filter="name~dr" --project=adyela-production
gsutil ls | grep production
```

### DR Capability Tests (Non-Disruptive)

```bash
# Test 1: Secondary Cloud Run services respond
for SERVICE in adyela-web-production-dr adyela-api-production-dr; do
  URL=$(gcloud run services describe $SERVICE --region=us-east1 --project=adyela-production --format='value(status.url)')
  curl -s "$URL/health" | jq
done

# Test 2: Cloud SQL replica is readable
psql -h /cloudsql/adyela-production:us-east1:adyela-db-production-dr-us-east1 \
  -U postgres -d adyela -c "SELECT version();"

# Test 3: Firestore multi-region accessible
curl https://api.adyela.care/api/v1/health/firestore

# Test 4: Storage buckets accessible
gsutil ls gs://adyela-production-uploads | head -5
```

### Documentation Updated

- [ ] DR activation date recorded in this document
- [ ] Actual costs vs estimates documented
- [ ] Any deviations from procedure noted
- [ ] Runbook updated with production details
- [ ] Team training materials updated

---

## 📢 Post-Activation Communications

### Internal Announcement (Slack #engineering)

```
✅ DISASTER RECOVERY ACTIVATED - Production

We successfully activated disaster recovery infrastructure in production.

Components Activated:
✅ Cloud Run (us-east1 cold standby)
✅ Cloud SQL (cross-region replica)
✅ Firestore (multi-region nam5)
✅ Storage (dual-region NAM4)
✅ Monitoring & Alerts

Capabilities:
- RTO: <15 minutes
- RPO: <1 hour
- Zero customer impact during activation
- Total activation time: [X] hours

Cost Impact: +$[X]/month (within budget)

Next Steps:
1. First DR drill scheduled: [DATE]
2. Quarterly drill calendar created
3. Team training session: [DATE]

Runbook: docs/deployment/disaster-recovery-runbook.md

Questions? #infrastructure-team
```

### Stakeholder Summary (Email)

```
Subject: ✅ Disaster Recovery Successfully Activated - Adyela Production

Team,

We have successfully activated disaster recovery capabilities for our production environment. This is a significant milestone in our infrastructure maturity and SLA readiness.

Summary:
- Secondary region deployed (us-east1)
- Database replication enabled
- Multi-region data storage configured
- Full monitoring and alerting active

Business Impact:
- RTO improved from N/A to <15 minutes
- RPO improved from N/A to <1 hour
- 99.95% uptime SLA now achievable
- Zero service disruption during activation

Cost Impact: $[X]/month additional (approved)

Next Steps:
- Quarterly DR drills scheduled
- Team training on failover procedures
- SLA update for customer contracts

Documentation: [Link to runbook]

Please reach out with any questions.

Best regards,
Infrastructure Team
```

---

## 🧪 Post-Activation Testing

### Week 1: Initial DR Drill (Staging)

Execute full DR failover simulation in staging environment:

```bash
# 1. Simulate primary region failure
# 2. Execute failover to secondary region
# 3. Validate all services functional
# 4. Execute failback to primary region
# 5. Document lessons learned
```

### Week 2: Monitoring Validation

- [ ] Verify all alerts triggering correctly
- [ ] Review actual costs vs estimates
- [ ] Tune alert thresholds if needed
- [ ] Validate notification routing

### Month 1: Production DR Drill

- [ ] Schedule with stakeholders
- [ ] Execute controlled failover during maintenance window
- [ ] Document actual RTO/RPO achieved
- [ ] Update procedures based on learnings

---

## 🔙 Rollback Procedure

**IF ACTIVATION FAILS**, follow this rollback:

### Step 1: Disable DR Components

Edit `infra/environments/production/terraform.tfvars`:

```hcl
enable_cloud_run_dr  = false
enable_cloud_sql_dr  = false
enable_storage_dr    = false
# Keep firestore_dr if migration completed
```

### Step 2: Destroy DR Resources

```bash
terraform plan -var-file=terraform.tfvars
# Verify only DR resources will be destroyed

terraform apply -var-file=terraform.tfvars
```

### Step 3: Verify Primary Still Functional

```bash
# Test primary services
curl https://api.adyela.care/health
curl https://staging.adyela.care

# Check database
gcloud sql instances describe adyela-db-production --project=adyela-production

# Verify no customer impact
```

### Step 4: Document Failure and Reschedule

- Document reason for rollback
- Identify blocking issues
- Create action plan
- Schedule new activation date

---

## 📊 Success Metrics

After 30 days of DR activation, measure:

- [ ] Actual costs vs budget (target: within ±10%)
- [ ] Replica lag average (target: <60 seconds)
- [ ] Secondary service uptime (target: 99.9%)
- [ ] Alert false positive rate (target: <5%)
- [ ] Team readiness (drill participation: 100%)
- [ ] Documentation completeness (runbook up-to-date)

---

## 📚 References

- [Disaster Recovery Runbook](./disaster-recovery-runbook.md) - Emergency
  procedures
- [DR Module README](../../infra/modules/disaster-recovery/README.md) -
  Technical details
- [Architecture Validation](./architecture-validation.md) - Infrastructure
  status
- [GCP Setup Guide](./gcp-setup.md) - GCP configuration
- [Cloud SQL Failover Procedure](../../infra/modules/disaster-recovery/cloud-sql-dr/FAILOVER_PROCEDURE.md)
- [Firestore Migration Instructions](../../infra/modules/disaster-recovery/firestore-replication/MIGRATION_INSTRUCTIONS.md)

---

## 📝 Activation Log

| Date       | Component    | Status           | Notes              | Duration | Cost Impact |
| ---------- | ------------ | ---------------- | ------------------ | -------- | ----------- |
| YYYY-MM-DD | Cloud Run DR | ❌ NOT ACTIVATED | Configuration only | -        | $0          |
| YYYY-MM-DD | Cloud SQL DR | ❌ NOT ACTIVATED | Configuration only | -        | $0          |
| YYYY-MM-DD | Firestore DR | ❌ NOT ACTIVATED | Configuration only | -        | $0          |
| YYYY-MM-DD | Storage DR   | ❌ NOT ACTIVATED | Configuration only | -        | $0          |

**Current Status**: ⚠️ DR CONFIGURED BUT NOT ACTIVATED (staging only)

**Next Activation Review**: [DATE]

---

**REMEMBER**: This document is for PRODUCTION ACTIVATION ONLY. For emergency
failover, use disaster-recovery-runbook.md.

**Last Activation**: N/A (not yet activated in production)

**Next Scheduled Activation**: TBD (pending budget approval and stakeholder
sign-off)
