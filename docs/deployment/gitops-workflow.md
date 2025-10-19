# GitOps Workflow for Infrastructure

**Version**: 1.0.0 **Last Updated**: 2025-10-19 **Owner**: Infrastructure Team

---

## 📋 Overview

This document describes our GitOps workflow for infrastructure management using
Terraform and GitHub Actions. Infrastructure changes follow the same rigorous
review and testing process as application code.

**Key Principles**:

- ✅ Infrastructure as Code (IaC)
- ✅ Git as single source of truth
- ✅ Automated testing and validation
- ✅ Pull request-based workflow
- ✅ Environment promotion (staging → production)
- ✅ Audit trail for all changes

---

## 🔄 Workflow Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     GITOPS WORKFLOW                              │
└──────────────────────────────────────────────────────────────────┘

Developer          GitHub               CI/CD                 GCP
    │                 │                   │                     │
    │  1. Create PR   │                   │                     │
    ├────────────────>│                   │                     │
    │                 │  2. Trigger CI    │                     │
    │                 ├──────────────────>│                     │
    │                 │                   │                     │
    │                 │                   │ 3. Validate         │
    │                 │                   │ 4. Security scan    │
    │                 │                   │ 5. Terraform plan   │
    │                 │                   │ 6. Cost estimate    │
    │                 │                   │                     │
    │                 │  7. Post results  │                     │
    │                 │<──────────────────┤                     │
    │                 │                   │                     │
    │  8. Review PR   │                   │                     │
    │<────────────────┤                   │                     │
    │                 │                   │                     │
    │  9. Approve     │                   │                     │
    ├────────────────>│                   │                     │
    │                 │                   │                     │
    │ 10. Merge       │                   │                     │
    ├────────────────>│                   │                     │
    │                 │ 11. Trigger Apply │                     │
    │                 ├──────────────────>│                     │
    │                 │                   │                     │
    │                 │                   │ 12. Manual approval │
    │                 │                   │     (production)    │
    │                 │                   │                     │
    │                 │                   │ 13. Apply changes   │
    │                 │                   ├────────────────────>│
    │                 │                   │                     │
    │                 │                   │ 14. Verify health   │
    │                 │                   │<────────────────────┤
    │                 │                   │                     │
    │                 │  15. Notify       │                     │
    │<────────────────┴───────────────────┤                     │
    │                                                            │
└────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Detailed Workflow Stages

### Stage 1: Development (Local)

**Objective**: Make infrastructure changes in a feature branch

**Steps**:

1. **Create feature branch**

   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/add-monitoring-alerts
   ```

2. **Make changes**

   ```bash
   cd infra/environments/staging
   vim monitoring.tf  # Add new alert policies
   ```

3. **Format and validate locally**

   ```bash
   terraform fmt -recursive
   terraform validate
   ```

4. **Optional: Local plan** (requires GCP credentials)

   ```bash
   terraform init
   terraform plan
   ```

5. **Commit changes**
   ```bash
   git add .
   git commit -m "feat(infra): add monitoring alerts for Cloud Run"
   git push origin feature/add-monitoring-alerts
   ```

**Best Practices**:

- Use conventional commit messages (`feat:`, `fix:`, `chore:`)
- Keep changes small and focused
- Include descriptive commit message explaining "why"

---

### Stage 2: Pull Request Creation

**Objective**: Request code review and trigger automated checks

**Steps**:

1. **Create PR via GitHub UI or CLI**

   ```bash
   gh pr create \
     --title "feat(infra): add monitoring alerts for Cloud Run" \
     --body "Adds CPU and memory utilization alerts for Cloud Run services" \
     --base develop
   ```

2. **Automated checks triggered** (GitHub Actions)
   - ✅ Terraform format check
   - ✅ Terraform validate
   - ✅ Security scanning (tfsec, checkov, terrascan)
   - ✅ Terraform plan (staging)
   - ✅ Cost estimation (Infracost)

3. **Review automated outputs**
   - Check workflow status in PR
   - Review terraform plan comment
   - Review cost estimate comment
   - Address any security findings

**Pull Request Template**:

```markdown
## Description

Brief description of infrastructure changes

## Motivation

Why are we making this change?

## Changes

- Resource 1 (create/update/delete)
- Resource 2 (create/update/delete)

## Terraform Plan Summary

<!-- Auto-populated by GitHub Actions -->

## Cost Impact

<!-- Auto-populated by Infracost -->

## Testing

- [ ] Tested locally with `terraform plan`
- [ ] Reviewed security scan results
- [ ] Cost impact reviewed and approved
- [ ] Rollback plan prepared

## Checklist

- [ ] Code follows Terraform style guide
- [ ] Documentation updated
- [ ] No secrets in code
- [ ] Breaking changes documented
```

---

### Stage 3: Code Review

**Objective**: Peer review of infrastructure changes

**Review Criteria**:

1. **Correctness**
   - ✅ Resources configured properly
   - ✅ Variables and outputs defined
   - ✅ Dependencies correct
   - ✅ Naming conventions followed

2. **Security**
   - ✅ No hardcoded secrets
   - ✅ Least privilege IAM
   - ✅ Encryption enabled where needed
   - ✅ Security scan findings addressed

3. **Cost Impact**
   - ✅ Cost increase justified
   - ✅ Resource sizing appropriate
   - ✅ Within budget

4. **Operational Impact**
   - ✅ Downtime documented (if any)
   - ✅ Rollback plan clear
   - ✅ Monitoring/alerting in place

5. **Code Quality**
   - ✅ Follows style guide
   - ✅ Modules reused where possible
   - ✅ Documentation updated

**Approval Requirements**:

- **Staging**: 1 approval from infrastructure team
- **Production**: 2 approvals (1 from infra team + 1 from tech lead/manager)

---

### Stage 4: Automated Testing (CI Pipeline)

**Workflow**: `.github/workflows/ci-infra.yml`

**Jobs**:

#### 4.1 Terraform Validate

```yaml
- terraform init -backend=false
- terraform fmt -check -recursive
- terraform validate
```

**Purpose**: Ensure syntax and configuration is valid

**Fail Fast**: Yes - blocks merge if failed

---

#### 4.2 Security Scanning

**Tools**:

1. **tfsec**: Static analysis for security issues
2. **checkov**: Policy-as-code scanning
3. **terrascan**: Compliance and security checks

**Output**: SARIF files uploaded to GitHub Security tab

**Fail Fast**: No (soft fail) - allows merge but highlights issues

---

#### 4.3 Terraform Plan (Staging)

```yaml
- terraform init
- terraform plan -out=tfplan
- terraform show tfplan > plan.txt
- Post plan as PR comment
```

**Purpose**: Show what will change in staging environment

**Artifacts**: Plan file saved for 7 days

**Fail Fast**: Yes - if plan fails, merge blocked

---

#### 4.4 Cost Estimation (Infracost)

```yaml
- infracost breakdown --path tfplan
- infracost diff --path tfplan
- Post cost comment to PR
- Alert if cost increase > $100/month
```

**Purpose**: Understand financial impact before merging

**Fail Fast**: No (warning only)

---

### Stage 5: Merge to Branch

**Branch Strategy**:

```
feature/xxx  →  develop  →  main
    ↓              ↓          ↓
  (local)      (staging)  (production)
```

**Merge to `develop`** (Staging Deployment):

- Automatically triggers `terraform-apply.yml` workflow
- Deploys to staging environment
- No manual approval required
- Post-deployment validation runs

**Merge to `main`** (Production Deployment):

- Automatically triggers `terraform-apply.yml` workflow
- Requires manual approval before apply
- Full deployment validation
- Stakeholder notifications

---

### Stage 6: Automated Deployment (CD Pipeline)

**Workflow**: `.github/workflows/terraform-apply.yml`

**Jobs**:

#### 6.1 Determine Environment

- Detect target environment from branch
- `develop` → staging
- `main` → production

#### 6.2 Terraform Plan (Pre-Apply)

```yaml
- terraform init
- terraform plan -out=tfplan
- Upload plan artifact
```

**Purpose**: Generate execution plan for apply

**Safety**: Plan is stored and reused in apply step

---

#### 6.3 Cost Estimation

```yaml
- infracost diff --path tfplan
- Post cost breakdown
```

**Purpose**: Final cost check before apply

---

#### 6.4 Approval Gate (Production Only)

**GitHub Environment**: `production-approval`

**Protected Environment Settings**:

- Required reviewers: Infrastructure team leads
- Wait timer: None (immediate approval available)
- Deployment branches: `main` only

**Approval Process**:

1. Workflow pauses at approval gate
2. Reviewers receive notification
3. Review terraform plan and cost estimate
4. Approve or reject deployment
5. Workflow continues or fails based on decision

**Approval SLA**: <2 hours during business hours

---

#### 6.5 Terraform Apply

```yaml
- terraform init
- terraform apply -auto-approve tfplan
- Upload apply logs
```

**Purpose**: Execute infrastructure changes

**Safeguards**:

- Uses pre-approved plan file
- No user input required
- Idempotent operations
- Automated rollback on failure (where possible)

---

#### 6.6 Post-Deployment Validation

```yaml
- gcloud run services list
- gcloud sql instances list
- gsutil ls
- Health check critical services
```

**Purpose**: Verify deployment succeeded

**Fail Behavior**: Workflow fails if validation fails

---

#### 6.7 Notifications

**Success**:

- GitHub deployment status updated
- Slack notification (optional)
- Email to stakeholders (optional)

**Failure**:

- GitHub issue created automatically
- PagerDuty alert (production only)
- Incident response team notified

---

## 🔐 Security and Compliance

### Secret Management

**DO**:

- ✅ Store secrets in GCP Secret Manager
- ✅ Reference secrets via Terraform data sources
- ✅ Use GitHub Secrets for CI/CD credentials
- ✅ Rotate credentials regularly

**DON'T**:

- ❌ Commit secrets to Git
- ❌ Put secrets in terraform.tfvars
- ❌ Share service account keys
- ❌ Use long-lived credentials

### Access Control

**GitHub Repository**:

- Branch protection on `develop` and `main`
- Require PR reviews
- Require status checks to pass
- No direct pushes allowed

**GCP Project**:

- Workload Identity for GitHub Actions
- Service accounts with least privilege
- IAM audit logging enabled
- Regular access reviews

### Audit Trail

**What's Tracked**:

- All terraform changes via Git history
- Terraform state versions (GCS)
- CI/CD workflow logs (GitHub Actions)
- GCP audit logs
- Cost changes over time

**Retention**:

- Git history: Indefinite
- Terraform state: 30 days (GCS versioning)
- Workflow logs: 90 days
- GCP audit logs: 400 days
- Cost data: 1 year

---

## 🔄 Environment Promotion

### Staging → Production Promotion

**Process**:

1. **Test in Staging**

   ```bash
   # Merge to develop
   git checkout develop
   git merge feature/new-feature
   git push origin develop

   # Observe staging deployment
   # Test functionality
   # Monitor for issues (24-48 hours)
   ```

2. **Prepare Production PR**

   ```bash
   # Create production PR
   git checkout main
   git pull origin main
   git checkout -b promote/staging-to-prod-YYYY-MM-DD

   # Cherry-pick or merge from develop
   git merge develop

   # Push and create PR
   git push origin promote/staging-to-prod-YYYY-MM-DD
   gh pr create --base main
   ```

3. **Production Review**
   - Extended review period (min 2 approvals)
   - Schedule deployment window
   - Notify stakeholders
   - Prepare rollback plan

4. **Merge to Main**
   - Merge PR during maintenance window
   - Monitor approval gate workflow
   - Approve when ready
   - Observe deployment

5. **Post-Deployment**
   - Verify production health
   - Monitor metrics for 24 hours
   - Document any issues
   - Update runbook if needed

---

## 🚨 Emergency Procedures

### Hotfix Process

**When to Use**: Critical production issue requiring immediate infrastructure
fix

**Process**:

1. **Create hotfix branch from main**

   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/critical-fix
   ```

2. **Make minimal fix**
   - Only change what's necessary
   - Keep changes small and focused
   - Document thoroughly

3. **Expedited review**
   - Post in Slack #infrastructure-urgent
   - Tag reviewers directly
   - Explain urgency
   - Get approval within 15 minutes

4. **Fast-track deployment**

   ```bash
   git push origin hotfix/critical-fix
   gh pr create --base main --label "hotfix"
   # Merge immediately after approval
   ```

5. **Post-incident**
   - Apply same fix to develop
   - Conduct post-mortem
   - Update procedures

### Manual Override (Break Glass)

**When to Use**: CI/CD pipeline down, must apply changes manually

**Prerequisites**:

- Approval from 2 infrastructure leads
- Documented justification
- GCP credentials available

**Procedure**:

```bash
# Local apply (ONLY IN EMERGENCY)
cd infra/environments/production

# Authenticate
gcloud auth application-default login

# Plan
terraform plan -out=emergency.tfplan

# Get approval
# Share plan output with team
# Obtain explicit approval

# Apply
terraform apply emergency.tfplan

# Document
# Create incident report
# Update state in GitHub (commit changes)
# Notify team
```

**Post-Emergency**:

- Document what happened
- Fix CI/CD pipeline
- Ensure state is synchronized
- Review and improve procedures

---

## 📊 Metrics and Monitoring

### GitOps Health Metrics

| Metric                  | Target      | Alert Threshold |
| ----------------------- | ----------- | --------------- |
| PR Review Time          | <4 hours    | >24 hours       |
| CI Pipeline Duration    | <10 minutes | >20 minutes     |
| Deployment Frequency    | >1/week     | <1/month        |
| Failed Deployments      | <5%         | >15%            |
| Mean Time to Recovery   | <2 hours    | >4 hours        |
| Approval Gate Wait Time | <2 hours    | >4 hours        |

### Dashboards

**GitHub Actions**:

- Workflow success rate
- Average duration
- Failed runs by workflow

**Terraform**:

- Resources managed
- State file size
- Drift detection results

**Costs**:

- Monthly spend by environment
- Cost changes over time
- Budget alerts

---

## 🎓 Training and Onboarding

### New Team Member Checklist

- [ ] Read this GitOps workflow document
- [ ] Review Terraform operations runbook
- [ ] Complete Terraform fundamentals training
- [ ] Shadow 2-3 infrastructure deployments
- [ ] Make first change in staging (with mentor)
- [ ] Participate in quarterly DR drill
- [ ] Complete security training

### Resources

- [Terraform Operations Runbook](./terraform-operations-runbook.md)
- [DR Runbook](./disaster-recovery-runbook.md)
- [GCP Setup Guide](./gcp-setup.md)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

---

## 📝 Revision History

| Version | Date       | Author | Changes                               |
| ------- | ---------- | ------ | ------------------------------------- |
| 1.0.0   | 2025-10-19 | Claude | Initial GitOps workflow documentation |

---

**Remember**: Infrastructure changes follow the same rigor as code changes.
Every change is reviewed, tested, and audited.

**Questions?** Ask in #infrastructure-team Slack channel
