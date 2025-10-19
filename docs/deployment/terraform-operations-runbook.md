# Terraform Operations Runbook

**Version**: 1.0.0 **Last Updated**: 2025-10-19 **Owner**: Infrastructure Team
**Classification**: PRODUCTION OPERATIONS

---

## 📋 Overview

This runbook provides operational procedures for managing Terraform
infrastructure, including common tasks, troubleshooting, and emergency
procedures.

---

## 🎯 Quick Reference

### Common Commands

```bash
# Navigate to environment directory
cd infra/environments/staging  # or production

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Show current state
terraform show

# List resources
terraform state list

# View specific resource
terraform state show <resource_address>

# Refresh state
terraform refresh

# Destroy all resources (DANGEROUS)
terraform destroy
```

### Emergency Contacts

- **Infrastructure Team Lead**: [Name] | [Email] | [Phone]
- **On-Call Engineer**: [PagerDuty link]
- **GCP Support**: 1-877-355-5787 (US) | Priority: P1
- **HashiCorp Support**: support@hashicorp.com

---

## 📚 Standard Operating Procedures

### SOP 1: Making Infrastructure Changes

**Purpose**: Safely deploy infrastructure changes through GitOps workflow

**Prerequisites**:

- [ ] Changes reviewed and approved
- [ ] CI/CD pipeline passing
- [ ] Cost impact assessed
- [ ] Rollback plan prepared

**Procedure**:

1. **Create feature branch**

   ```bash
   git checkout -b feature/add-new-service
   ```

2. **Make Terraform changes**

   ```bash
   cd infra/environments/staging
   # Edit .tf files
   terraform fmt -recursive
   terraform validate
   ```

3. **Test locally** (optional, requires GCP credentials)

   ```bash
   terraform init
   terraform plan
   ```

4. **Commit and push**

   ```bash
   git add .
   git commit -m "feat(infra): add new Cloud Run service"
   git push origin feature/add-new-service
   ```

5. **Create Pull Request**
   - GitHub Actions will automatically run:
     - `terraform validate`
     - `terraform fmt -check`
     - Security scans (tfsec, checkov, terrascan)
     - `terraform plan` (staging)
     - Cost estimation (Infracost)

6. **Review terraform plan output**
   - Check plan comment in PR
   - Verify resources to be created/modified/destroyed
   - Review cost estimate
   - Ensure no unexpected changes

7. **Get approval**
   - Request review from infrastructure team
   - Address any feedback
   - Obtain at least 1 approval

8. **Merge to develop/main**
   - Merge PR when approved
   - Merging to `develop` → deploys to staging
   - Merging to `main` → deploys to production (with manual approval)

9. **Monitor deployment**
   - Watch GitHub Actions workflow
   - Approve manual approval gate (production only)
   - Verify deployment success
   - Check post-deployment validation

10. **Verify in GCP Console**
    - Confirm resources created correctly
    - Test service functionality
    - Monitor for errors

---

### SOP 2: Emergency Rollback

**Purpose**: Quickly rollback failed infrastructure changes

**When to Use**:

- Terraform apply failed
- Applied changes broke production
- Critical service unavailable after deployment

**Procedure**:

1. **Assess the situation**

   ```bash
   # Check current state
   terraform show

   # View recent state history
   gsutil ls gs://BUCKET/terraform/state/staging.tfstate.*
   ```

2. **Option A: Revert Git commit and re-apply**

   ```bash
   # Revert the problematic commit
   git revert <commit-sha>
   git push origin main

   # This triggers new terraform apply with reverted config
   ```

3. **Option B: Restore previous state (DANGEROUS)**

   ```bash
   # List state backups
   gsutil ls gs://adyela-staging-terraform-state/terraform/state/

   # Download previous state
   gsutil cp gs://BUCKET/terraform/state/staging.tfstate.TIMESTAMP staging.tfstate.backup

   # Restore (ONLY IF ABSOLUTELY NECESSARY)
   # CAUTION: This can cause state drift
   gsutil cp staging.tfstate.backup gs://BUCKET/terraform/state/staging.tfstate
   ```

4. **Option C: Manual resource cleanup**

   ```bash
   # Remove problematic resource from state (doesn't delete actual resource)
   terraform state rm <resource_address>

   # Delete actual resource manually via GCP console
   # Re-import if needed:
   terraform import <resource_address> <gcp_resource_id>
   ```

5. **Verify rollback success**

   ```bash
   terraform plan
   # Should show "No changes" if rollback successful
   ```

6. **Post-incident**
   - Document what happened
   - Update runbook if needed
   - Conduct post-mortem

---

### SOP 3: Adding New Environment

**Purpose**: Create new environment (e.g., dev, uat, demo)

**Procedure**:

1. **Create environment directory**

   ```bash
   cd infra/environments
   cp -r staging new-environment
   cd new-environment
   ```

2. **Update backend configuration** Edit `backend.tf`:

   ```hcl
   terraform {
     backend "gcs" {
       bucket = "adyela-new-environment-terraform-state"
       prefix = "terraform/state"
     }
   }
   ```

3. **Update variables** Edit `terraform.tfvars`:

   ```hcl
   project_id  = "adyela-new-environment"
   environment = "new-environment"
   region      = "us-central1"
   # ... other variables
   ```

4. **Create GCS bucket for state**

   ```bash
   gsutil mb -p adyela-new-environment -c STANDARD -l US gs://adyela-new-environment-terraform-state

   # Enable versioning
   gsutil versioning set on gs://adyela-new-environment-terraform-state
   ```

5. **Initialize Terraform**

   ```bash
   terraform init
   terraform plan
   ```

6. **Update CI/CD workflows**
   - Add environment to `.github/workflows/ci-infra.yml`
   - Add secrets to GitHub (GCP credentials, project ID)
   - Add environment protection rules

7. **Create and apply**
   ```bash
   terraform apply
   ```

---

### SOP 4: State Management

**Purpose**: Manage Terraform state safely

#### 4.1 Viewing State

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show google_cloud_run_service.web

# Show entire state
terraform show
```

#### 4.2 Moving Resources in State

```bash
# Move resource to different address (e.g., refactoring module structure)
terraform state mv \
  google_cloud_run_service.old_name \
  google_cloud_run_service.new_name

# Move resource to different module
terraform state mv \
  google_cloud_run_service.web \
  module.cloud_run.google_cloud_run_service.web
```

#### 4.3 Removing Resources from State

```bash
# Remove from state WITHOUT destroying actual resource
terraform state rm google_cloud_run_service.temp_service

# The resource still exists in GCP but Terraform no longer manages it
```

#### 4.4 Importing Existing Resources

```bash
# Import existing GCP resource into Terraform state
terraform import \
  google_cloud_run_service.web \
  projects/adyela-staging/locations/us-central1/services/adyela-web-staging

# After import, add corresponding configuration to .tf files
# Then run terraform plan to verify
```

#### 4.5 State Locking Issues

```bash
# If state is locked (concurrent operations)
# Check lock info:
gsutil cat gs://BUCKET/terraform/state/staging.tfstate.tflock

# Force unlock (ONLY if you're sure no other operation is running)
terraform force-unlock LOCK_ID
```

---

### SOP 5: Module Development

**Purpose**: Create and maintain Terraform modules

**Procedure**:

1. **Create module structure**

   ```bash
   mkdir -p infra/modules/new-module
   cd infra/modules/new-module

   touch main.tf variables.tf outputs.tf README.md
   ```

2. **Define module interface**

   `variables.tf`:

   ```hcl
   variable "project_id" {
     description = "GCP Project ID"
     type        = string
   }

   variable "name" {
     description = "Resource name"
     type        = string
   }
   ```

   `outputs.tf`:

   ```hcl
   output "resource_id" {
     description = "Resource ID"
     value       = google_resource.example.id
   }
   ```

3. **Implement module logic** in `main.tf`

4. **Document module** in `README.md`
   - Purpose
   - Usage example
   - Input variables
   - Outputs
   - Requirements

5. **Test module**

   ```bash
   cd infra/environments/staging

   # Use module in environment config
   module "new_resource" {
     source = "../../modules/new-module"

     project_id = var.project_id
     name       = "test-resource"
   }

   terraform init
   terraform plan
   ```

6. **Version module** (if using external repository)
   ```bash
   git tag -a v1.0.0 -m "Initial release"
   git push origin v1.0.0
   ```

---

## 🔧 Troubleshooting

### Issue 1: Terraform Init Fails

**Symptoms**:

```
Error: Failed to get existing workspaces: querying Cloud Storage failed:
storage: bucket doesn't exist
```

**Diagnosis**:

- GCS bucket for state doesn't exist
- Incorrect bucket name in backend config
- Missing GCP permissions

**Solution**:

```bash
# Create state bucket
gsutil mb -p PROJECT_ID -c STANDARD -l US gs://BUCKET_NAME

# Enable versioning
gsutil versioning set on gs://BUCKET_NAME

# Verify access
gsutil ls -b gs://BUCKET_NAME
```

---

### Issue 2: State Lock Timeout

**Symptoms**:

```
Error: Error acquiring the state lock
Lock Info:
  ID:        LOCK_ID
  Operation: OperationTypeApply
  Who:       user@hostname
  Created:   2025-10-19 14:30:00
```

**Diagnosis**:

- Another terraform operation is running
- Previous operation crashed without releasing lock
- Concurrent CI/CD workflows

**Solution**:

```bash
# Wait for other operation to complete (recommended)
# OR

# Verify no other operations running
# Check GitHub Actions workflows
# Check local terminal sessions

# Force unlock (USE WITH CAUTION)
terraform force-unlock LOCK_ID
```

---

### Issue 3: Resource Already Exists

**Symptoms**:

```
Error: Error creating Service: googleapi: Error 409: Requested entity already exists
```

**Diagnosis**:

- Resource exists in GCP but not in Terraform state
- State drift
- Resource created outside Terraform

**Solution**:

```bash
# Import existing resource
terraform import google_cloud_run_service.web \
  projects/PROJECT_ID/locations/us-central1/services/service-name

# Verify import
terraform plan
# Should show no changes if config matches existing resource
```

---

### Issue 4: Plan Shows Unexpected Changes

**Symptoms**:

- Terraform plan shows changes for resources you didn't modify
- Resources being recreated unexpectedly

**Diagnosis**:

- Provider version changed
- Resource configuration drift
- GCP API changes
- Computed values changed

**Solution**:

```bash
# Refresh state from actual infrastructure
terraform refresh

# Compare state with actual resources
terraform plan -refresh-only

# Review plan carefully
terraform plan

# Check provider version
terraform version

# Update provider version constraints if needed (in versions.tf)
```

---

### Issue 5: Terraform Apply Hangs

**Symptoms**:

- Apply operation stuck for >10 minutes
- No progress output

**Diagnosis**:

- GCP API timeout
- Long-running resource creation (e.g., Cloud SQL)
- Network issues

**Solution**:

```bash
# Wait - some resources take time (Cloud SQL: 10-30min)

# Check GCP Console for operation status

# If truly stuck, Ctrl+C to cancel
# Then investigate:
terraform show
gcloud operations list --filter="status=RUNNING"

# Re-run apply if safe
terraform apply
```

---

### Issue 6: Permission Denied Errors

**Symptoms**:

```
Error: googleapi: Error 403: Permission 'iam.serviceAccounts.actAs' denied
```

**Diagnosis**:

- Insufficient IAM permissions
- Service account missing roles
- Workload Identity misconfigured

**Solution**:

```bash
# Check current permissions
gcloud projects get-iam-policy PROJECT_ID

# Verify service account roles
gcloud iam service-accounts get-iam-policy \
  SERVICE_ACCOUNT_EMAIL --project PROJECT_ID

# Add required role (example)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" \
  --role="roles/iam.serviceAccountUser"
```

---

## 💡 Best Practices

### 1. Always Use Feature Branches

- Never commit directly to main/develop
- Use descriptive branch names: `feature/`, `fix/`, `refactor/`

### 2. Small, Focused Changes

- One logical change per PR
- Easier to review and rollback
- Reduces blast radius

### 3. Use Terraform Modules

- DRY (Don't Repeat Yourself)
- Reusable components
- Easier maintenance

### 4. Version Control Everything

- All .tf files in Git
- Never manually edit state
- Document infrastructure changes

### 5. Test in Staging First

- Always deploy to staging before production
- Validate changes thoroughly
- Monitor for issues

### 6. Use Terraform Workspaces (Optional)

- For managing multiple environments in one config
- Not recommended for our setup (we use separate directories)

### 7. Regular State Backups

- GCS versioning is enabled
- Keep state backups for 30+ days
- Test restore procedures

### 8. Monitor Costs

- Review Infracost reports
- Set up billing alerts
- Optimize resource sizing

### 9. Security Scanning

- Always pass security scans (tfsec, checkov)
- Address critical findings immediately
- Document accepted risks

### 10. Documentation

- Keep README.md updated in each module
- Document non-obvious decisions
- Update runbook based on incidents

---

## 📊 Monitoring and Alerts

### Key Metrics to Monitor

1. **Terraform State Lock Duration**
   - Alert if lock held >30 minutes
   - Indicates stuck operations

2. **Failed Apply Operations**
   - Alert on all failures
   - Investigate immediately

3. **State File Size**
   - Monitor for unusual growth
   - Large states indicate complexity

4. **Cost Drift**
   - Compare actual vs estimated costs
   - Investigate significant variances

5. **Resource Drift**
   - Regular drift detection runs
   - Alert on unexpected changes

### Drift Detection

```bash
# Manual drift detection
terraform plan -refresh-only

# Automated (add to cron or CI/CD)
#!/bin/bash
terraform plan -refresh-only -no-color > drift-report.txt
if grep -q "Your infrastructure matches" drift-report.txt; then
  echo "✅ No drift detected"
else
  echo "⚠️ Drift detected - sending alert"
  # Send notification
fi
```

---

## 🔐 Security Considerations

### Secrets Management

1. **Never commit secrets to Git**
   - Use Secret Manager
   - Reference secrets in Terraform:

   ```hcl
   data "google_secret_manager_secret_version" "api_key" {
     secret = "api-key"
   }
   ```

2. **Protect Terraform State**
   - State may contain sensitive data
   - Restrict bucket access
   - Enable encryption

3. **Use Service Accounts**
   - Dedicated service account per environment
   - Principle of least privilege
   - Rotate credentials regularly

4. **Workload Identity**
   - Prefer Workload Identity over service account keys
   - Configured in GitHub Actions workflows

---

## 📝 Checklists

### Pre-Deployment Checklist

- [ ] Changes reviewed by infrastructure team
- [ ] Terraform plan reviewed and approved
- [ ] Cost impact assessed and approved
- [ ] Security scans passed
- [ ] Documentation updated
- [ ] Rollback plan prepared
- [ ] Stakeholders notified (if major change)
- [ ] Maintenance window scheduled (if downtime expected)

### Post-Deployment Checklist

- [ ] Terraform apply succeeded
- [ ] All resources created correctly
- [ ] Services are healthy
- [ ] No errors in logs
- [ ] Cost monitoring enabled
- [ ] Documentation updated
- [ ] Stakeholders notified of completion
- [ ] Runbook updated (if new procedures)

---

## 📚 References

- [Terraform Documentation](https://www.terraform.io/docs)
- [Google Cloud Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Infracost Documentation](https://www.infracost.io/docs/)
- [DR Runbook](./disaster-recovery-runbook.md)
- [DR Activation Procedures](./dr-activation-procedures.md)
- [GCP Setup Guide](./gcp-setup.md)

---

## 📝 Revision History

| Version | Date       | Author | Changes                              |
| ------- | ---------- | ------ | ------------------------------------ |
| 1.0.0   | 2025-10-19 | Claude | Initial Terraform operations runbook |

---

**REMEMBER**: Infrastructure is code. Treat it with the same rigor as
application code - reviews, testing, and careful deployment.

**NEXT REVIEW DATE**: 2025-11-19 (30 days)
