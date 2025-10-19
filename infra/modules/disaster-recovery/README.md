# Disaster Recovery Module (CONFIGURATION ONLY)

> **⚠️ IMPORTANT**: This module contains DR configurations for **FUTURE
> PRODUCTION ACTIVATION**. **DO NOT APPLY** to staging environment to avoid
> additional costs ($120-200/month).

## Overview

This module provides comprehensive disaster recovery capabilities with:

- **RTO Target**: <15 minutes
- **RPO Target**: <1 hour
- **Architecture**: Multi-region active-passive failover
- **Regions**: Primary (us-central1) → Secondary (us-east1)

## Components

### 1. Multi-Region Cloud Run (`multi-region-cloud-run/`)

- Deploys services in secondary region (us-east1)
- Automatic failover via load balancer health checks
- Traffic splitting: 100% primary / 0% secondary (standby)
- **Cost**: ~2x Cloud Run costs when activated

### 2. Firestore Multi-Region (`firestore-replication/`)

- Multi-region database configuration (nam5 → multi-region)
- Strong consistency model for DR scenarios
- Automatic data replication across regions
- **Cost**: ~1.5x storage costs when activated

### 3. Cloud SQL DR (`cloud-sql-dr/`)

- Cross-region read replicas (us-east1)
- Automated failover with promotion procedures
- Point-in-time recovery across regions
- **Cost**: ~$50-80/month per replica

### 4. Cross-Region Storage (`cross-region-storage/`)

- Dual-region bucket configuration
- Automatic replication for critical data
- Geo-redundancy for backup storage
- **Cost**: ~$2-5/month per 100GB

## Activation Procedures

### When to Activate

**Production Ready Criteria:**

- ✅ MVP launched with real users
- ✅ Revenue generating (>100 Pro tier users)
- ✅ SLA commitments in place
- ✅ 24/7 on-call rotation established
- ✅ Budget approved for DR costs ($300-500/month)

### How to Activate

1. **Review Configurations**

   ```bash
   cd infra/modules/disaster-recovery
   terraform init
   terraform validate
   ```

2. **Estimate Costs**

   ```bash
   terraform plan -out=dr.tfplan
   # Review monthly costs in plan output
   ```

3. **Apply to Production Only**

   ```bash
   # In production environment
   cd infra/environments/production

   # Uncomment DR module in main.tf
   # module "disaster_recovery" { ... }

   terraform plan
   terraform apply
   ```

4. **Verify DR Setup**
   - Check multi-region Firestore replication
   - Verify Cloud SQL replicas are syncing
   - Test failover load balancer configuration
   - Run DR drill (see runbook)

## Cost Breakdown (Estimated Monthly)

### Staging (NOT ACTIVATED - $0)

- Current: Module exists but not applied
- Impact: No additional costs

### Production (WHEN ACTIVATED)

- Multi-region Cloud Run: $80-120/month
- Firestore multi-region: $40-60/month
- Cloud SQL read replica: $50-80/month
- Cross-region storage: $20-40/month
- Monitoring & logs: $10-15/month
- **Total**: $300-500/month

## RTO/RPO Targets

### Recovery Time Objective (RTO): <15 minutes

**Breakdown:**

1. Incident detection: 2 minutes (automated alerts)
2. Decision to failover: 3 minutes (on-call assessment)
3. DNS/traffic routing: 5 minutes (load balancer cutover)
4. Database promotion: 3 minutes (read replica → primary)
5. Application validation: 2 minutes (health checks)

**Total**: 15 minutes worst-case

### Recovery Point Objective (RPO): <1 hour

**Backup Strategy:**

- Firestore: Continuous replication (RPO ~0)
- Cloud SQL: Transaction logs every 5 minutes (RPO ~5 min)
- Storage: Geo-replication (RPO ~1 hour)
- **Worst case**: 1 hour data loss

## Testing Procedures

### Quarterly DR Drills

1. **Tabletop Exercise** (quarterly)
   - Review runbook with team
   - Walk through failover procedures
   - Update contact information
   - Validate escalation paths

2. **Non-disruptive Test** (bi-annually)
   - Verify replica lag metrics
   - Test read replica queries
   - Validate backup restoration
   - Check monitoring alerts

3. **Full Failover Drill** (annually)
   - Execute complete failover to secondary region
   - Validate application functionality
   - Measure actual RTO/RPO
   - Document lessons learned

## Documentation References

- **Activation Guide**: `docs/deployment/dr-activation-procedures.md`
- **Runbook**: `docs/deployment/disaster-recovery-runbook.md`
- **Cost Analysis**: `docs/deployment/dr-cost-analysis.md`
- **Rollback Procedures**: `docs/deployment/dr-rollback-procedures.md`

## Terraform Modules

### Module Structure

```
disaster-recovery/
├── main.tf                    # Main orchestration
├── variables.tf               # Input variables
├── outputs.tf                 # Outputs for integration
├── multi-region-cloud-run/    # Multi-region service deployment
├── firestore-replication/     # Multi-region Firestore config
├── cloud-sql-dr/              # Read replica configuration
└── cross-region-storage/      # Dual-region buckets
```

### Usage Example (Production Only)

```hcl
module "disaster_recovery" {
  source = "../../modules/disaster-recovery"

  project_id = var.project_id
  environment = "production"

  # Regional configuration
  primary_region   = "us-central1"
  secondary_region = "us-east1"

  # RTO/RPO targets
  rto_minutes = 15
  rpo_minutes = 60

  # Services to protect
  enable_cloud_run_dr  = true
  enable_firestore_dr  = true
  enable_cloud_sql_dr  = true
  enable_storage_dr    = true

  # Cost controls
  enable_autoscaling = true
  min_secondary_instances = 0  # Standby mode

  labels = local.common_labels
}
```

## Validation (Safe - No Costs)

```bash
# Validate configurations without applying
cd infra/modules/disaster-recovery
terraform init
terraform validate

# Check each submodule
for dir in */; do
  echo "Validating $dir"
  cd $dir
  terraform init
  terraform validate
  cd ..
done
```

## Migration Path

### Phase 1: Preparation (Current - Staging)

- ✅ Modules created and validated
- ✅ Documentation complete
- ✅ Cost analysis done
- ❌ NOT applied to staging (avoid costs)

### Phase 2: Production Activation (Future)

- Apply to production environment only
- Monitor costs and performance
- Run initial DR drill
- Establish regular testing schedule

### Phase 3: Optimization (Post-activation)

- Tune failover thresholds
- Optimize replica lag
- Reduce costs where possible
- Update procedures based on drills

---

**Status**: ✅ READY FOR PRODUCTION ACTIVATION **Last Updated**: 2025-10-19
**Maintained By**: Infrastructure Team **Cost Impact**: $0 (not activated) →
$300-500/month (when activated)
