# Disaster Recovery Runbook

**Version**: 1.0.0 **Last Updated**: 2025-10-19 **Owner**: Infrastructure Team
**Classification**: CRITICAL - PRODUCTION USE ONLY

---

## 🚨 Emergency Quick Reference

**WHEN TO USE THIS RUNBOOK:**

- Primary region (us-central1) is completely unavailable (>10 minutes)
- Multiple services in primary region are failing
- GCP announces prolonged regional outage
- Data center disaster affecting primary infrastructure

**WHEN NOT TO USE:**

- Single service degradation (use standard incident response)
- Network latency issues (use network troubleshooting)
- Application bugs (use standard deployment rollback)
- Planned maintenance (use maintenance procedures)

**ESTIMATED TIMINGS:**

- **RTO (Recovery Time Objective)**: <15 minutes
- **RPO (Recovery Point Objective)**: <1 hour
- **Decision Time**: <5 minutes
- **Failover Execution**: 5-10 minutes
- **Validation**: 2-5 minutes

---

## 📞 Emergency Contacts

### On-Call Rotation

- **Primary On-Call**: [PagerDuty link] / [Phone]
- **Secondary On-Call**: [PagerDuty link] / [Phone]
- **Manager On-Call**: [Contact]

### External Contacts

- **GCP Support (Production)**: 1-877-355-5787 (US) | Priority: P1
- **GCP Account Manager**: [Name] | [Email] | [Phone]
- **Security Team**: security@adyela.care
- **Communications Team**: comms@adyela.care

### Stakeholder Notifications

1. **CEO/CTO** - Immediate notification for regional outage
2. **Product Team** - Service degradation impact
3. **Customer Success** - User communication
4. **Legal/Compliance** - HIPAA breach assessment (if applicable)

---

## 🔍 Detection and Assessment

### Automated Alerts

DR-related alerts are prefixed with `[DR]`:

```
[DR] Primary Region Degraded
[DR] Cloud SQL Replica Lag High
[DR] Secondary Service Down
[DR] Cloud Run Primary Unavailable
```

### Manual Assessment Checklist

Before initiating failover, verify:

- [ ] **Duration**: Outage has persisted >10 minutes
- [ ] **Scope**: Multiple services affected (not isolated incident)
- [ ] **GCP Status**: Check https://status.cloud.google.com
- [ ] **Regional Impact**: Confirm us-central1 is affected
- [ ] **Secondary Health**: Verify us-east1 services are healthy
- [ ] **Replica Lag**: Cloud SQL replica lag <5 minutes
- [ ] **Stakeholder Notification**: Incident commander assigned

### Assessment Commands

```bash
# Check primary region service health
gcloud run services list --region=us-central1 --project=adyela-production

# Check secondary region service health
gcloud run services list --region=us-east1 --project=adyela-production

# Check Cloud SQL replica lag
gcloud sql instances describe INSTANCE-dr-us-east1 \
  --project=adyela-production \
  --format="value(replicaConfiguration.failoverTarget, state)"

# Check recent GCP operations
gcloud logging read "severity>=ERROR" --limit=50 --format=json

# Check monitoring dashboard
open https://console.cloud.google.com/monitoring/dashboards?project=adyela-production
```

---

## 🎯 Failover Decision Tree

```
┌─────────────────────────────────────┐
│ Is primary region (us-central1)    │
│ completely unavailable?             │
└────────────┬────────────────────────┘
             │
        YES  │  NO
             │  └─> Use standard incident response
             ▼
┌─────────────────────────────────────┐
│ Has outage persisted >10 minutes?   │
└────────────┬────────────────────────┘
             │
        YES  │  NO
             │  └─> Continue monitoring, wait
             ▼
┌─────────────────────────────────────┐
│ Is secondary region (us-east1)      │
│ healthy and responsive?             │
└────────────┬────────────────────────┘
             │
        YES  │  NO
             │  └─> ESCALATE TO GCP SUPPORT
             ▼
┌─────────────────────────────────────┐
│ Is Cloud SQL replica lag <5 min?    │
└────────────┬────────────────────────┘
             │
        YES  │  NO
             │  └─> WAIT or ACCEPT DATA LOSS
             ▼
┌─────────────────────────────────────┐
│ ✅ PROCEED WITH FAILOVER            │
└─────────────────────────────────────┘
```

---

## 🔄 Failover Procedures

### Pre-Failover Checklist

- [ ] Incident Commander assigned and acknowledged
- [ ] Stakeholders notified (CEO, CTO, Product)
- [ ] Communication prepared for customers
- [ ] Secondary region health confirmed
- [ ] Replica lag verified <5 minutes
- [ ] Rollback plan reviewed and understood
- [ ] All team members on incident bridge call

### 1. Cloud Run Failover (5-7 minutes)

**Objective**: Redirect traffic from us-central1 to us-east1 Cloud Run services

**Current State**:

- Primary: `adyela-web-staging` in us-central1
- Secondary: `adyela-web-staging-dr` in us-east1 (cold standby)

#### Step 1.1: Verify Secondary Services

```bash
# List all DR services in secondary region
gcloud run services list \
  --region=us-east1 \
  --project=adyela-production \
  --filter="labels.disaster_recovery=enabled"

# Expected output: adyela-web-staging-dr, adyela-api-staging-dr, etc.
# All should show STATE: RUNNING
```

#### Step 1.2: Scale Up Secondary Services (if cold standby)

```bash
# Update each DR service to minimum 1 instance
for SERVICE in adyela-web-staging-dr adyela-api-staging-dr; do
  gcloud run services update $SERVICE \
    --region=us-east1 \
    --project=adyela-production \
    --min-instances=1 \
    --max-instances=10
done

# Wait 60-90 seconds for instances to start
sleep 90
```

#### Step 1.3: Update Load Balancer / DNS

**Option A: If using Cloud Load Balancer**

```bash
# Update backend service to use secondary region
gcloud compute backend-services update adyela-backend \
  --project=adyela-production \
  --global \
  --enable-logging \
  --logging-sample-rate=1.0

# Add secondary backend (if not already configured)
gcloud compute backend-services add-backend adyela-backend \
  --project=adyela-production \
  --global \
  --network-endpoint-group=adyela-web-dr-neg \
  --network-endpoint-group-region=us-east1 \
  --balancing-mode=UTILIZATION \
  --max-utilization=0.8

# Remove or drain primary backend
gcloud compute backend-services update-backend adyela-backend \
  --project=adyela-production \
  --global \
  --network-endpoint-group=adyela-web-neg \
  --network-endpoint-group-region=us-central1 \
  --balancing-mode=RATE \
  --max-rate-per-endpoint=0  # Drain traffic
```

**Option B: If using Cloudflare DNS**

```bash
# Update DNS A record to point to secondary region
# (Manual via Cloudflare dashboard or API)
# Change staging.adyela.care from PRIMARY_IP to SECONDARY_IP

# Propagation time: 1-5 minutes (with 60s TTL)
```

#### Step 1.4: Verify Traffic Shift

```bash
# Monitor incoming requests to secondary
gcloud logging read \
  "resource.type=cloud_run_revision AND resource.labels.service_name=adyela-web-staging-dr" \
  --project=adyela-production \
  --limit=20 \
  --format="table(timestamp, httpRequest.requestMethod, httpRequest.requestUrl, httpRequest.status)"

# Should see active traffic within 2-5 minutes
```

**Estimated Time**: 5-7 minutes **Success Criteria**:

- ✅ Secondary services receiving traffic
- ✅ HTTP 200 responses from health checks
- ✅ No 5xx errors in logs

---

### 2. Cloud SQL Failover (5-10 minutes)

**Objective**: Promote read replica to primary instance

**Current State**:

- Primary: `adyela-db-production` in us-central1
- Replica: `adyela-db-production-dr-us-east1` (failover target)

#### Step 2.1: Verify Replica Health

```bash
# Check replica status
gcloud sql instances describe adyela-db-production-dr-us-east1 \
  --project=adyela-production \
  --format="value(state, replicaConfiguration.failoverTarget)"

# Expected: RUNNABLE, True

# Check replication lag (CRITICAL)
gcloud sql instances describe adyela-db-production-dr-us-east1 \
  --project=adyela-production \
  --format="value(replicationLag)"

# Should be <300 seconds (5 minutes)
```

#### Step 2.2: Take Database Backup (RECOMMENDED)

```bash
# Create on-demand backup before promotion
gcloud sql backups create \
  --instance=adyela-db-production-dr-us-east1 \
  --project=adyela-production \
  --description="Pre-failover backup $(date +%Y%m%d-%H%M%S)"

# Wait for backup to complete
gcloud sql operations list \
  --instance=adyela-db-production-dr-us-east1 \
  --project=adyela-production \
  --limit=1
```

#### Step 2.3: Promote Replica to Primary

⚠️ **WARNING**: This is IRREVERSIBLE. Replica becomes standalone instance.

```bash
# Promote replica (confirm when prompted)
gcloud sql instances promote-replica adyela-db-production-dr-us-east1 \
  --project=adyela-production

# This operation takes 2-5 minutes
# Monitor progress
gcloud sql operations list \
  --instance=adyela-db-production-dr-us-east1 \
  --project=adyela-production \
  --limit=1 \
  --format="table(name, operationType, status, startTime, endTime)"
```

#### Step 2.4: Update Application Connection Strings

**Option A: Update Secret Manager**

```bash
# Get current database connection secret
gcloud secrets versions access latest \
  --secret=database-connection-string \
  --project=adyela-production

# Update with new instance connection name
echo "postgres://user:pass@/dbname?host=/cloudsql/adyela-production:us-east1:adyela-db-production-dr-us-east1" | \
  gcloud secrets versions add database-connection-string \
    --project=adyela-production \
    --data-file=-

# Restart Cloud Run services to pick up new secret
for SERVICE in adyela-web-staging-dr adyela-api-staging-dr; do
  gcloud run services update $SERVICE \
    --region=us-east1 \
    --project=adyela-production \
    --update-env-vars=DB_FORCE_RELOAD=true
done
```

**Option B: Update Terraform Configuration** (Post-incident)

Update `infra/environments/production/terraform.tfvars`:

```hcl
cloud_sql_primary_instance = "adyela-db-production-dr-us-east1"  # Updated
primary_region = "us-east1"  # Updated
```

#### Step 2.5: Verify Database Connectivity

```bash
# Test connection from Cloud Run service
gcloud run services describe adyela-api-staging-dr \
  --region=us-east1 \
  --project=adyela-production \
  --format="value(status.url)"

# Test API endpoint that queries database
curl https://[SERVICE_URL]/api/v1/health/database

# Expected: { "status": "healthy", "latency_ms": <50 }
```

**Estimated Time**: 5-10 minutes **Success Criteria**:

- ✅ Replica promoted successfully
- ✅ Application connecting to new primary
- ✅ No database connection errors in logs
- ✅ API endpoints responding normally

---

### 3. Firestore Failover (AUTOMATIC)

**Objective**: Verify multi-region Firestore is operating normally

**Current State**:

- Firestore is already multi-region (nam5)
- Automatic failover within Google's infrastructure
- No manual intervention required

#### Step 3.1: Verify Firestore Health

```bash
# Check Firestore operations
gcloud firestore operations list \
  --project=adyela-production \
  --limit=10

# All recent operations should succeed
```

#### Step 3.2: Test Read/Write Operations

```bash
# Test API endpoint that uses Firestore
curl https://[SERVICE_URL]/api/v1/health/firestore

# Expected: { "status": "healthy", "read_latency_ms": <100 }
```

**Estimated Time**: 0 minutes (automatic) **Success Criteria**:

- ✅ Firestore operations succeeding
- ✅ No increased latency
- ✅ No errors in application logs

---

### 4. Storage Failover (AUTOMATIC)

**Objective**: Verify dual/multi-region storage is accessible

**Current State**:

- Storage buckets are dual-region (NAM4) or multi-region (US)
- Automatic failover within Google's infrastructure
- No manual intervention required

#### Step 4.1: Verify Storage Access

```bash
# List recent objects in critical buckets
gsutil ls -lh gs://adyela-production-uploads | head -20

# Should succeed without errors
```

#### Step 4.2: Test Upload/Download

```bash
# Test write
echo "DR test $(date)" | gsutil cp - gs://adyela-production-uploads/dr-test.txt

# Test read
gsutil cat gs://adyela-production-uploads/dr-test.txt

# Cleanup
gsutil rm gs://adyela-production-uploads/dr-test.txt
```

**Estimated Time**: 0 minutes (automatic) **Success Criteria**:

- ✅ Storage operations succeeding
- ✅ No increased latency (<200ms)
- ✅ No errors in application logs

---

## ✅ Post-Failover Validation

### System Health Check (10 minutes)

```bash
# 1. Verify all Cloud Run services are healthy
gcloud run services list --region=us-east1 --project=adyela-production

# 2. Check Cloud SQL instance status
gcloud sql instances describe adyela-db-production-dr-us-east1 --project=adyela-production

# 3. Monitor error rates
gcloud logging read "severity>=ERROR" --limit=100 --project=adyela-production

# 4. Check API health endpoints
for ENDPOINT in /health /api/v1/health /api/v1/health/database /api/v1/health/firestore; do
  echo "Testing $ENDPOINT"
  curl -s https://staging.adyela.care$ENDPOINT | jq
done

# 5. Verify user authentication flow
curl -X POST https://staging.adyela.care/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@adyela.care", "password": "test"}'
```

### Business Function Tests

- [ ] User login successful
- [ ] Professional search returns results
- [ ] Appointment booking functional
- [ ] Video consultation accessible
- [ ] Calendar integration working
- [ ] Notifications being sent
- [ ] Admin panel accessible

### Monitoring Dashboard Review

1. **Cloud Run Metrics**
   - Request count trending upward (traffic shifted)
   - Error rate <1%
   - Latency p95 <500ms

2. **Cloud SQL Metrics**
   - Connections stable
   - Query latency <100ms
   - No connection errors

3. **Firestore Metrics**
   - Read/write operations normal
   - Latency <200ms
   - No quota exceeded errors

4. **Storage Metrics**
   - Upload/download operations normal
   - Latency <500ms
   - No 5xx errors

---

## 📢 Communication Templates

### Internal Notification (Slack #incidents)

```
🚨 DISASTER RECOVERY INITIATED

Incident: [INC-YYYY-NNN]
Start Time: [YYYY-MM-DD HH:MM UTC]
Severity: P1 (Critical)
Impact: Primary region (us-central1) unavailable

DR Status:
✅ Cloud Run: Failover to us-east1 COMPLETE
✅ Cloud SQL: Replica promoted COMPLETE
✅ Firestore: Multi-region OPERATIONAL
✅ Storage: Dual-region OPERATIONAL

Current RTO: [X] minutes
Current RPO: <1 hour

Incident Commander: @[name]
Bridge: [Zoom/Google Meet link]

Next Update: [TIME]
```

### Customer Communication (Status Page)

```
INVESTIGATING: Service Degradation - us-central1 Region

We are currently experiencing an outage in our primary data center (us-central1).

Our disaster recovery systems have automatically failed over to our secondary region (us-east1). Services are being restored with minimal data loss.

Status:
✅ Authentication: Operational
✅ Appointment Booking: Operational
✅ Video Consultations: Operational
⚠️ Some features may experience brief delays

ETA for Full Resolution: [TIME]

We apologize for any inconvenience and will provide updates every 30 minutes.

Posted: [TIME]
```

### GCP Support Ticket

```
Subject: [P1 PRODUCTION] Regional Outage - us-central1 - Customer Impact

GCP Project ID: adyela-production
Affected Region: us-central1
Severity: P1 (Production Impact)

Description:
Complete unavailability of us-central1 region starting at [TIME UTC].
Multiple Cloud Run services and Cloud SQL primary instance affected.

Initiated disaster recovery failover to us-east1 at [TIME UTC].

Request:
1. Confirm status of us-central1 region
2. ETA for primary region restoration
3. Any known data loss or replication issues
4. Assistance with post-incident cleanup

Cloud Run Services Affected:
- adyela-web-staging
- adyela-api-staging

Cloud SQL Instance Affected:
- adyela-db-production

Current Workaround: Failover to us-east1 DR environment

Business Impact: [DESCRIBE]

Contact: [NAME] | [EMAIL] | [PHONE]
```

---

## 🔙 Failback Procedures

**WHEN TO FAIL BACK:**

- Primary region (us-central1) restored and stable for >2 hours
- GCP confirms root cause resolved
- Full post-incident review completed
- Stakeholder approval obtained

### Failback Checklist

- [ ] Primary region health confirmed (>2 hours stable)
- [ ] GCP root cause analysis reviewed
- [ ] New replica created in us-central1 from us-east1 primary
- [ ] Replica lag <5 minutes
- [ ] Maintenance window scheduled (low traffic period)
- [ ] Rollback plan prepared
- [ ] Team members available for execution

### Failback Steps (Reverse of Failover)

1. **Create new replica in us-central1** from current us-east1 primary
2. **Wait for replication** to catch up (lag <5 min)
3. **During maintenance window:**
   - Drain traffic from us-east1
   - Promote us-central1 replica to primary
   - Update connection strings
   - Shift Cloud Run traffic to us-central1
4. **Validate** system health
5. **Return DR services** to cold standby (min_instances=0)

**Estimated Time**: 30-45 minutes **Recommended**: Execute during low-traffic
period (2-4 AM UTC)

---

## 📊 Post-Incident Activities

### Immediate (Within 24 hours)

- [ ] Document timeline of events
- [ ] Collect metrics (actual RTO, RPO, impact)
- [ ] Preserve logs and audit trail
- [ ] Initial incident report to stakeholders

### Short-term (Within 1 week)

- [ ] Post-incident review (PIR) meeting
- [ ] Root cause analysis
- [ ] Identify improvement areas
- [ ] Update runbook with lessons learned
- [ ] Test failback in staging environment

### Long-term (Within 1 month)

- [ ] Implement PIR action items
- [ ] Update DR testing schedule
- [ ] Review and update DR costs
- [ ] Conduct DR drill with full team
- [ ] Update documentation and training

---

## 🧪 DR Testing Schedule

**Quarterly DR Drills** (Required for SLA compliance)

- **Q1**: Cloud Run failover test (staging)
- **Q2**: Cloud SQL failover test (staging)
- **Q3**: Full DR simulation (staging + partial production)
- **Q4**: Tabletop exercise + documentation review

**Monthly Checks**

- Verify secondary region services are healthy
- Check replica lag monitoring
- Review and test alert configurations
- Validate contact information is current

---

## 📚 Reference Documentation

- [DR Activation Procedures](./dr-activation-procedures.md)
- [DR Module README](../../infra/modules/disaster-recovery/README.md)
- [Cloud SQL Failover Procedure](../../infra/modules/disaster-recovery/cloud-sql-dr/FAILOVER_PROCEDURE.md)
- [Firestore Migration Instructions](../../infra/modules/disaster-recovery/firestore-replication/MIGRATION_INSTRUCTIONS.md)
- [Architecture Validation](./architecture-validation.md)
- [GCP Setup Guide](./gcp-setup.md)

---

## 📝 Revision History

| Version | Date       | Author | Changes                           |
| ------- | ---------- | ------ | --------------------------------- |
| 1.0.0   | 2025-10-19 | Claude | Initial disaster recovery runbook |

---

**REMEMBER**: This is a PRODUCTION-CRITICAL document. Keep it updated after
every DR drill and incident.

**NEXT REVIEW DATE**: 2025-11-19 (30 days)
