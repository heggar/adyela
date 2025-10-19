# Complete Microservice Deployment Example

This example demonstrates how to deploy a complete, production-ready
microservice using all Adyela Terraform modules.

## What This Creates

This configuration deploys:

1. **Standard Labels** (via `common` module)
   - Cost attribution labels
   - HIPAA compliance labels
   - Team ownership labels

2. **Artifact Registry** (via `artifact-registry` module)
   - Docker container registry
   - Automated cleanup policies
   - CI/CD service account

3. **Cloud Build Pipeline** (via `cloud-build` module)
   - Automated builds on git push
   - Deployment to Cloud Run
   - GitHub integration

4. **Cloud Run Service** (via `cloud-run-service` module)
   - Serverless container deployment
   - Autoscaling (0-10 or 1-20 instances)
   - Secret Manager integration
   - Health checks

## Architecture

```
GitHub (push to main)
    ↓
Cloud Build Trigger
    ↓
Build Docker Image
    ↓
Push to Artifact Registry
    ↓
Deploy to Cloud Run
    ↓
Service Running (https://adyela-api-staging-xxx.run.app)
```

## Prerequisites

1. **GCP Project** with billing enabled
2. **APIs Enabled**:

   ```bash
   gcloud services enable \
     cloudrun.googleapis.com \
     cloudbuild.googleapis.com \
     artifactregistry.googleapis.com \
     secretmanager.googleapis.com
   ```

3. **GitHub Repository** connected to Cloud Build
4. **Terraform** >= 1.0 installed
5. **GCP Credentials** configured:
   ```bash
   gcloud auth application-default login
   ```

## Quick Start

### 1. Configure Variables

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Update `terraform.tfvars`:

```hcl
project_id  = "your-gcp-project"
region      = "us-central1"
environment = "staging"  # or "production"
github_owner = "your-org"
github_repo  = "your-repo"
```

### 2. Create Secrets in Secret Manager

```bash
# JWT secret
echo -n "your-super-secret-jwt-key" | \
  gcloud secrets create jwt-secret-staging \
    --data-file=-

# Firestore connection string
echo -n "firestore-connection-string-here" | \
  gcloud secrets create firestore-connection-string \
    --data-file=-

# SendGrid API key
echo -n "SG.xxxxxxxxxxxxx" | \
  gcloud secrets create sendgrid-api-key \
    --data-file=-
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review Plan

```bash
terraform plan
```

Expected resources:

- 1 Artifact Registry repository
- 1 Cloud Build trigger
- 1 Cloud Run service
- 3+ IAM bindings
- 2+ Service accounts

### 5. Deploy

```bash
terraform apply
```

Type `yes` when prompted.

### 6. Get Service URL

```bash
terraform output service_url
```

Example output:

```
https://adyela-api-staging-abcd1234-uc.a.run.app
```

### 7. Test Deployment

```bash
curl $(terraform output -raw service_url)/health
```

Expected response:

```json
{ "status": "healthy", "environment": "staging" }
```

## CI/CD Workflow

### GitHub Actions Setup

Create `.github/workflows/deploy-staging.yml`:

```yaml
name: Deploy to Staging

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v4

      - id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/123456789/locations/global/workloadIdentityPools/github/providers/github
          service_account: ${{ secrets.GCP_SA_EMAIL }}

      - name: Build and deploy
        run: |
          # Cloud Build will be triggered automatically via the trigger
          echo "Deployment triggered by push to main"
```

Alternatively, **Cloud Build auto-triggers** on push (no GitHub Actions needed):

1. Push to `main` branch
2. Cloud Build automatically:
   - Builds Docker image
   - Runs tests
   - Pushes to Artifact Registry
   - Deploys to Cloud Run

## Customization

### Environment-Specific Configuration

**Staging** (cost-optimized):

```hcl
environment = "staging"

# Results in:
# - Min instances: 0 (scale to zero)
# - Max instances: 10
# - Public access: enabled
# - Cleanup: 7 days
# - Manual approval: disabled
```

**Production** (high-availability):

```hcl
environment = "production"

# Results in:
# - Min instances: 1 (always warm)
# - Max instances: 20
# - Public access: disabled (use load balancer)
# - Cleanup: 30 days
# - Immutable tags: enabled
# - Manual approval: enabled
```

### Add More Secrets

Edit `main.tf`:

```hcl
secrets = {
  # Existing secrets...

  NEW_SECRET = {
    secret  = "new-secret-name"
    version = "latest"
  }
}
```

Create the secret:

```bash
echo -n "secret-value" | \
  gcloud secrets create new-secret-name --data-file=-
```

### Modify Autoscaling

Edit `main.tf`:

```hcl
module "api_service" {
  # ...

  min_instances = 2  # Always 2 instances running
  max_instances = 50 # Scale up to 50 instances

  max_instance_requests = 100  # 100 concurrent requests per instance
}
```

### Add Environment Variables

Edit `main.tf`:

```hcl
env_vars = {
  # Existing vars...

  FEATURE_FLAGS = "appointments_v2,video_calls"
  MAX_UPLOAD_SIZE = "10485760"  # 10 MB
}
```

## Cost Estimation

### Staging Environment (~$15-25/month)

| Resource          | Configuration            | Cost        |
| ----------------- | ------------------------ | ----------- |
| Cloud Run         | Min: 0, Max: 10, 512MB   | $10-15      |
| Artifact Registry | 5GB storage, 20GB egress | $1-3        |
| Cloud Build       | 500 build-minutes        | $1.50       |
| Secret Manager    | 3 secrets, 500 accesses  | $0.18       |
| **Total**         |                          | **~$15-20** |

### Production Environment (~$100-200/month)

| Resource          | Configuration              | Cost          |
| ----------------- | -------------------------- | ------------- |
| Cloud Run         | Min: 1, Max: 20, 512MB     | $80-150       |
| Artifact Registry | 20GB storage, 100GB egress | $5-10         |
| Cloud Build       | 2000 build-minutes         | $6            |
| Secret Manager    | 5 secrets, 5000 accesses   | $0.90         |
| Load Balancer     | HTTPS LB                   | $20-30        |
| **Total**         |                            | **~$100-200** |

## Troubleshooting

### Build failing with "permission denied"

**Cause**: Cloud Build service account lacks permissions

**Fix**:

```bash
# Check service account
terraform output cicd_service_account

# Verify IAM bindings
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:CICD_SA_EMAIL"
```

### Service not receiving traffic

**Cause**: IAM permissions not set for public access

**Fix**:

```bash
# Allow unauthenticated access (staging only)
gcloud run services add-iam-policy-binding adyela-api-staging \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker"
```

### Image pull errors

**Cause**: Cloud Run can't access Artifact Registry

**Fix**: Ensure Cloud Run service account has `roles/artifactregistry.reader`:

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:SERVICE_ACCOUNT@YOUR_PROJECT.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

### Secrets not loading

**Cause**: Cloud Run service account lacks Secret Manager access

**Fix**:

```bash
# Grant secret accessor role
gcloud secrets add-iam-policy-binding SECRET_NAME \
  --member="serviceAccount:SERVICE_ACCOUNT@YOUR_PROJECT.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

**Warning**: This will delete:

- Cloud Run service (service stops)
- Artifact Registry (Docker images deleted)
- Cloud Build trigger (deployments stop)
- IAM bindings

Secrets in Secret Manager are **NOT deleted** (manual cleanup required).

## Security Considerations

1. ✅ **Secrets**: Stored in Secret Manager, never in code
2. ✅ **IAM**: Least-privilege service accounts
3. ✅ **Network**: Production uses VPC connector (private)
4. ✅ **Audit**: All API calls logged to Cloud Logging
5. ✅ **Labels**: HIPAA compliance labels for audit trails

## Next Steps

1. **Add Load Balancer** for production (Task 14.4)
2. **Setup Monitoring** and alerting (Task 14.5)
3. **Configure VPC** for private networking (Task 14.4)
4. **Implement Disaster Recovery** (Task 14.7)
5. **Add more microservices** (api-admin, api-analytics)

## References

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

**Maintained by**: Platform Team **Last Updated**: 2025-10-19
