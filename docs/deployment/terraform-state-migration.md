# Terraform State Migration Procedures

**Version**: 1.0.0 **Last Updated**: 2025-10-19 **Owner**: Infrastructure Team
**Classification**: CRITICAL OPERATIONS

---

## ⚠️ WARNING

**Terraform state migration is a CRITICAL operation that can result in:**

- Loss of infrastructure management
- Accidental resource deletion
- State corruption
- Service outages

**ALWAYS**:

- ✅ Create backups before migration
- ✅ Test in staging first
- ✅ Have rollback plan ready
- ✅ Schedule during maintenance window
- ✅ Get approval from infrastructure lead
- ✅ Document every step

---

## 📋 Overview

This document covers procedures for migrating Terraform state between backends,
restructuring state, and recovering from state issues.

**Common Use Cases**:

1. Migrating state between GCS buckets
2. Moving from local to remote backend
3. Splitting monolithic state into multiple states
4. Restructuring modules and resource addresses
5. Recovering from state corruption

---

## 🎯 Scenario 1: Migrating State Between GCS Buckets

**Use Case**: Moving state from old bucket to new bucket (e.g., reorganization,
new project)

### Prerequisites

- [ ] New GCS bucket created
- [ ] Versioning enabled on new bucket
- [ ] Backup of current state created
- [ ] Access to both old and new buckets
- [ ] Maintenance window scheduled

### Procedure

#### Step 1: Backup Current State

```bash
# Set variables
OLD_BUCKET="adyela-staging-terraform-state"
NEW_BUCKET="adyela-new-terraform-state"
ENV="staging"

# Download current state as backup
gsutil cp gs://$OLD_BUCKET/terraform/state/$ENV.tfstate \
  ~/terraform-backup-$(date +%Y%m%d-%H%M%S).tfstate

# Verify backup
ls -lh ~/terraform-backup-*

# Store backup in secure location
gsutil cp ~/terraform-backup-*.tfstate \
  gs://$OLD_BUCKET/backups/
```

#### Step 2: Create New Backend Bucket (if needed)

```bash
# Create new bucket
gsutil mb -p adyela-staging \
  -c STANDARD \
  -l US \
  gs://$NEW_BUCKET

# Enable versioning
gsutil versioning set on gs://$NEW_BUCKET

# Verify
gsutil versioning get gs://$NEW_BUCKET
```

#### Step 3: Update Backend Configuration

Edit `backend.tf`:

```hcl
terraform {
  backend "gcs" {
    bucket = "adyela-new-terraform-state"  # Updated
    prefix = "terraform/state"
  }
}
```

#### Step 4: Re-initialize with Migration

```bash
cd infra/environments/$ENV

# Re-initialize (Terraform will detect backend change)
terraform init -migrate-state

# Terraform will prompt:
# "Do you want to copy existing state to the new backend?"
# Answer: yes

# Verify migration
terraform state list
# Should show all existing resources
```

#### Step 5: Verify State in New Bucket

```bash
# Check new bucket
gsutil ls gs://$NEW_BUCKET/terraform/state/

# Verify state file exists
gsutil cat gs://$NEW_BUCKET/terraform/state/$ENV.tfstate | head -20

# Run plan to verify no changes
terraform plan
# Should show: "No changes. Your infrastructure matches the configuration."
```

#### Step 6: Test State Operations

```bash
# List resources
terraform state list

# Show a specific resource
terraform state show google_cloud_run_service.web

# Refresh state
terraform refresh

# If all looks good, migration successful!
```

#### Step 7: Cleanup (After 30 days)

```bash
# After verifying new state works for 30 days
# Delete old state (optional - keep as archive)
# gsutil rm -r gs://$OLD_BUCKET/terraform/state/
```

**Rollback Procedure** (if migration fails):

```bash
# Restore backend.tf to old bucket
# Re-initialize
terraform init -reconfigure

# Verify
terraform plan
```

---

## 🎯 Scenario 2: Splitting Monolithic State

**Use Case**: Separating large state file into multiple smaller states (e.g.,
per service, per module)

### Why Split State?

**Benefits**:

- Faster terraform operations
- Reduced blast radius
- Better team collaboration (different teams manage different states)
- Easier state locking (less contention)

**Drawbacks**:

- More complex management
- Need to handle cross-state dependencies
- More CI/CD workflows

### Procedure

#### Step 1: Plan Split Strategy

**Example Split**:

```
Current: infra/environments/staging/
  - All resources in one state

Proposed:
  - infra/environments/staging/networking/
    - VPC, subnets, firewalls
  - infra/environments/staging/compute/
    - Cloud Run services
  - infra/environments/staging/data/
    - Cloud SQL, Firestore, Storage
```

#### Step 2: Create New State Structures

```bash
cd infra/environments/staging

# Create new directories
mkdir -p networking compute data

# Copy backend config to each
for dir in networking compute data; do
  cat > $dir/backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "adyela-staging-terraform-state"
    prefix = "terraform/state/$dir"
  }
}
EOF
done
```

#### Step 3: Move Configuration Files

```bash
# Move network resources to networking/
mv vpc.tf networking/
mv subnets.tf networking/
mv firewall.tf networking/

# Move compute resources to compute/
mv cloud-run.tf compute/
mv load-balancer.tf compute/

# Move data resources to data/
mv cloud-sql.tf data/
mv firestore.tf data/
mv storage.tf data/
```

#### Step 4: Extract State for Each Component

**For Networking**:

```bash
cd networking

# Initialize new state
terraform init

# Import resources from old state
# List resources in old state first
cd ..
terraform state list | grep google_compute_network

# For each network resource, import
cd networking
terraform import google_compute_network.vpc \
  projects/adyela-staging/global/networks/adyela-vpc

# Repeat for all networking resources

# Verify
terraform plan
# Should show no changes
```

**Repeat for Compute and Data**

#### Step 5: Remove from Old State

```bash
cd infra/environments/staging

# Remove migrated resources from old state
terraform state rm google_compute_network.vpc
terraform state rm google_compute_subnetwork.app_subnet
# ... remove all migrated resources

# Verify old state is empty
terraform state list
# Should show only non-migrated resources (if any)
```

#### Step 6: Update CI/CD Workflows

Update `.github/workflows/ci-infra.yml`:

```yaml
strategy:
  matrix:
    environment: [staging, production]
    component: [networking, compute, data]

working-directory:
  ${{ env.WORKING_DIR }}/environments/${{ matrix.environment }}/${{
  matrix.component }}
```

---

## 🎯 Scenario 3: Restructuring Module References

**Use Case**: Refactoring code to use modules instead of inline resources

### Procedure

#### Step 1: Create Module

```bash
# Create module structure
mkdir -p infra/modules/cloud-run-service
cd infra/modules/cloud-run-service

# Move resource definition to module
# Create main.tf, variables.tf, outputs.tf
```

#### Step 2: Replace Inline Resources with Module

Before:

```hcl
resource "google_cloud_run_service" "web" {
  name     = "adyela-web-staging"
  location = "us-central1"
  # ... configuration
}
```

After:

```hcl
module "web_service" {
  source = "../../modules/cloud-run-service"

  name     = "adyela-web-staging"
  location = "us-central1"
  # ... configuration
}
```

#### Step 3: Move Resources in State

```bash
# Move state from inline resource to module resource
terraform state mv \
  google_cloud_run_service.web \
  module.web_service.google_cloud_run_service.service

# Verify
terraform plan
# Should show no changes
```

---

## 🎯 Scenario 4: Migrating from Local to Remote Backend

**Use Case**: Moving from local state file to GCS backend

### Procedure

#### Step 1: Create GCS Bucket

```bash
gsutil mb -p PROJECT_ID -c STANDARD -l US gs://BUCKET_NAME
gsutil versioning set on gs://BUCKET_NAME
```

#### Step 2: Add Backend Configuration

Create `backend.tf`:

```hcl
terraform {
  backend "gcs" {
    bucket = "adyela-staging-terraform-state"
    prefix = "terraform/state"
  }
}
```

#### Step 3: Re-initialize with Migration

```bash
terraform init -migrate-state

# Terraform will prompt to migrate local state to GCS
# Answer: yes

# Verify
gsutil ls gs://BUCKET_NAME/terraform/state/
```

#### Step 4: Remove Local State (After Verification)

```bash
# After confirming remote state works
rm terraform.tfstate terraform.tfstate.backup

# Add to .gitignore
echo "terraform.tfstate*" >> .gitignore
```

---

## 🎯 Scenario 5: State Recovery

**Use Case**: State file corrupted or accidentally deleted

### Option A: Restore from GCS Versioning

```bash
# List state file versions
gsutil ls -a gs://BUCKET/terraform/state/staging.tfstate

# Output shows versions with generation numbers
# gs://BUCKET/terraform/state/staging.tfstate#1634567890123456

# Copy previous version to restore
gsutil cp \
  gs://BUCKET/terraform/state/staging.tfstate#1634567890123456 \
  gs://BUCKET/terraform/state/staging.tfstate

# Verify
terraform refresh
terraform plan
```

### Option B: Restore from Backup

```bash
# If you have manual backup
gsutil cp ~/terraform-backup-YYYYMMDD.tfstate \
  gs://BUCKET/terraform/state/staging.tfstate

# Re-initialize
terraform init -reconfigure

# Verify
terraform plan
```

### Option C: Rebuild State from Scratch (LAST RESORT)

**WARNING**: This is very risky and error-prone

```bash
# Delete corrupted state
rm terraform.tfstate*

# Re-initialize (creates empty state)
terraform init

# Import each resource manually
terraform import google_cloud_run_service.web \
  projects/PROJECT/locations/REGION/services/SERVICE_NAME

terraform import google_sql_database_instance.db \
  PROJECT:INSTANCE_NAME

# Repeat for ALL resources (this is tedious!)

# Verify
terraform plan
# Should show no changes once all resources imported
```

---

## 🎯 Scenario 6: Cross-Project State Migration

**Use Case**: Moving resources from one GCP project to another

**IMPORTANT**: This is complex and may require resource recreation

### Procedure

#### Step 1: Document Current State

```bash
# Export current configuration
terraform show -json > current-state.json

# List all resources
terraform state list > resources.txt
```

#### Step 2: Update Project ID in Configuration

```hcl
# Update project_id variable
variable "project_id" {
  default = "new-project-id"  # Updated
}
```

#### Step 3: Import Resources in New Project

```bash
# For each resource that can be moved (not all can!)

# Remove from old state
terraform state rm google_cloud_run_service.web

# Update configuration with new project
# Re-initialize
terraform init

# Import in new project
terraform import google_cloud_run_service.web \
  projects/new-project-id/locations/us-central1/services/service-name
```

**NOTE**: Many GCP resources cannot be moved between projects and must be
recreated.

---

## 🔒 Best Practices

### 1. Always Create Backups

```bash
# Before ANY state operation
gsutil cp gs://BUCKET/terraform/state/ENV.tfstate \
  ~/backup-$(date +%Y%m%d-%H%M%S).tfstate
```

### 2. Use State Locking

- GCS backend automatically provides locking
- Never disable locking
- If lock is stuck, investigate before forcing unlock

### 3. Version Control Backend Configuration

- Keep `backend.tf` in Git
- Document backend changes in commits
- Review backend changes in PRs

### 4. Test in Staging First

- Always test state migrations in staging
- Verify thoroughly before production
- Document any issues encountered

### 5. Use Terraform Workspaces (Carefully)

```bash
# Workspaces can help manage multiple environments
terraform workspace list
terraform workspace new dev
terraform workspace select prod

# But separate directories is often clearer
```

### 6. Regular State Health Checks

```bash
# Weekly: verify state matches reality
terraform plan -refresh-only

# Look for drift
terraform plan -detailed-exitcode
# Exit code 2 = changes detected (drift)
```

---

## 🚨 Troubleshooting

### Issue: State Lock Stuck

```bash
# Check lock info
gsutil cat gs://BUCKET/terraform/state/staging.tfstate.tflock

# Wait for operation to complete, or
# Force unlock (use with caution!)
terraform force-unlock LOCK_ID
```

### Issue: State Drift Detected

```bash
# Refresh state from actual infrastructure
terraform refresh

# Compare
terraform plan -refresh-only

# If drift is expected (manual changes), import
terraform import RESOURCE_TYPE.NAME RESOURCE_ID
```

### Issue: Duplicate Resources After Migration

```bash
# List duplicates
terraform state list | sort | uniq -d

# Remove duplicates
terraform state rm RESOURCE_ADDRESS
```

### Issue: Missing Provider Configuration

```bash
# Error: provider required
# Add provider configuration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Re-initialize
terraform init -upgrade
```

---

## 📋 Migration Checklist

### Pre-Migration

- [ ] Document current state structure
- [ ] Create full state backup
- [ ] Test migration in staging
- [ ] Prepare rollback procedure
- [ ] Schedule maintenance window
- [ ] Notify stakeholders
- [ ] Get approval from infrastructure lead

### During Migration

- [ ] Execute migration steps carefully
- [ ] Document each command executed
- [ ] Verify after each major step
- [ ] Take screenshots/logs
- [ ] Monitor for errors

### Post-Migration

- [ ] Verify terraform plan shows no changes
- [ ] Test terraform apply with small change
- [ ] Verify all resources still managed
- [ ] Update documentation
- [ ] Update CI/CD workflows (if needed)
- [ ] Monitor infrastructure for 24-48 hours
- [ ] Archive old state (don't delete immediately)
- [ ] Conduct post-migration review

---

## 📚 References

- [Terraform State Documentation](https://www.terraform.io/docs/language/state/)
- [Terraform State Command Reference](https://www.terraform.io/docs/cli/commands/state/)
- [GCS Backend Configuration](https://www.terraform.io/docs/language/settings/backends/gcs.html)
- [Terraform Operations Runbook](./terraform-operations-runbook.md)
- [GitOps Workflow](./gitops-workflow.md)

---

## 📝 Revision History

| Version | Date       | Author | Changes                                |
| ------- | ---------- | ------ | -------------------------------------- |
| 1.0.0   | 2025-10-19 | Claude | Initial state migration procedures doc |

---

**REMEMBER**: State is the single source of truth for Terraform. Handle with
extreme care. When in doubt, create a backup and consult with the team.

**Questions?** Contact infrastructure team lead before attempting complex state
migrations.
