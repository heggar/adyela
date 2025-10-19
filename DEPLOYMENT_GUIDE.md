# Adyela Deployment Guide

Comprehensive guide for deploying the Adyela platform to GCP.

## Prerequisites

- [x] GCP Project created (`adyela-staging` or `adyela-production`)
- [x] Billing account linked
- [x] `gcloud` CLI installed and authenticated
- [x] `terraform` >= 1.0 installed
- [x] `docker` installed
- [x] GitHub repository with push access

## 📋 Deployment Checklist

### Phase 1: GCP Project Setup (30 minutes)

```bash
# 1. Set your project
export PROJECT_ID="adyela-staging"
export REGION="us-central1"

gcloud config set project $PROJECT_ID

# 2. Enable required APIs
gcloud services enable \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    secretmanager.googleapis.com \
    firestore.googleapis.com \
    firebase.googleapis.com \
    cloudtrace.googleapis.com \
    logging.googleapis.com \
    monitoring.googleapis.com \
    pubsub.googleapis.com \
    cloudbuild.googleapis.com

# 3. Create Artifact Registry repository
gcloud artifacts repositories create adyela \
    --repository-format=docker \
    --location=$REGION \
    --description="Adyela container images"

# 4. Configure Docker authentication
gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

### Phase 2: Secrets Setup (15 minutes)

```bash
# Run the automated secrets setup script
./scripts/setup-secrets.sh staging

# This will prompt you for:
# - JWT secret (auto-generated if empty)
# - Firebase API key
# - Admin secret (auto-generated if empty)
# - Stripe credentials (optional for MVP)
# - SendGrid/Twilio credentials (optional for MVP)
```

**Manual Alternative:**

```bash
# JWT Secret (required)
echo -n "YOUR_SECURE_JWT_SECRET" | gcloud secrets create jwt-secret-staging \
    --data-file=- \
    --replication-policy="automatic"

# Firebase API Key (required)
echo -n "YOUR_FIREBASE_API_KEY" | gcloud secrets create firebase-api-key-staging \
    --data-file=- \
    --replication-policy="automatic"
```

### Phase 3: Terraform Infrastructure (20 minutes)

```bash
cd infra/environments/staging

# 1. Create terraform.tfvars
cat > terraform.tfvars <<EOF
project_id = "adyela-staging"
region = "us-central1"
billing_account = "YOUR_BILLING_ACCOUNT_ID"
budget_alert_emails = ["dev@adyela.care", "admin@adyela.care"]
EOF

# 2. Initialize Terraform
terraform init

# 3. Plan infrastructure
terraform plan -out=tfplan

# 4. Review and apply
terraform apply tfplan
```

**What gets created:**

- 6 Cloud Run services (api-auth, api-appointments, api-payments,
  api-notifications, api-admin, api-analytics)
- 4 Pub/Sub topics with subscriptions
- Budget alerts ($150/month for staging)
- Service accounts with IAM permissions
- Cloud Monitoring alert policies

### Phase 4: Firebase Setup (15 minutes)

1. **Create Firebase Project**:
   - Go to https://console.firebase.google.com
   - Add Firebase to existing GCP project (`adyela-staging`)

2. **Enable Authentication**:
   - Firebase Console → Authentication → Sign-in method
   - Enable: Email/Password, Google, Facebook, Apple

3. **Configure Firestore**:
   - Firebase Console → Firestore Database
   - Create database in `us-central1` region
   - Start in **production mode** (we'll add rules later)

4. **Download Config Files**:

   ```bash
   # For Web (React Admin)
   # Copy Firebase config to apps/web/src/config/firebase.ts

   # For Mobile (Flutter)
   # Download google-services.json (Android)
   # Download GoogleService-Info.plist (iOS)
   ```

### Phase 5: Build and Deploy Microservices (45 minutes)

**Option A: Automated Deployment**

```bash
# Deploy all services at once
./scripts/deploy-all.sh staging
```

**Option B: Manual Deployment (per service)**

```bash
# Example: Deploy api-auth
cd apps/api-auth

# Build Docker image
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/adyela/api-auth:latest .

# Push to Artifact Registry
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/adyela/api-auth:latest

# Already deployed by Terraform, but to update:
gcloud run deploy api-auth-staging \
    --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/adyela/api-auth:latest \
    --region=${REGION}
```

**Repeat for all 6 services:**

- api-auth (Python, port 8000)
- api-appointments (Python, port 8000)
- api-payments (Node.js, port 3000)
- api-notifications (Node.js, port 3000)
- api-admin (Python, port 8000)
- api-analytics (Python, port 8000)

### Phase 6: GitHub Actions Setup (10 minutes)

Add the following secrets to GitHub repository:

```
Settings → Secrets and variables → Actions → New repository secret
```

**Required Secrets:**

- `GCP_SA_KEY_STAGING` - Service account key JSON for staging
- `GCP_SA_KEY_PRODUCTION` - Service account key JSON for production (later)
- `SLACK_WEBHOOK_URL` - Slack webhook for notifications (optional)

**Create Service Account:**

```bash
# Create service account
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions Deployment"

# Grant permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions@${PROJECT_ID}.iam.gserviceaccount.com

# Copy content of github-actions-key.json to GitHub secret GCP_SA_KEY_STAGING
cat github-actions-key.json

# Delete local key file
rm github-actions-key.json
```

### Phase 7: Verification (10 minutes)

**Health Checks:**

```bash
# Get service URLs
gcloud run services list --region=$REGION

# Test each service health endpoint
curl https://api-auth-staging-...run.app/health
curl https://api-appointments-staging-...run.app/health
curl https://api-payments-staging-...run.app/health
curl https://api-notifications-staging-...run.app/health
curl https://api-admin-staging-...run.app/health
curl https://api-analytics-staging-...run.app/health
```

**Expected Response:**

```json
{
  "status": "healthy",
  "service": "api-auth",
  "version": "0.1.0",
  "environment": "staging"
}
```

**Check Logs:**

```bash
# View logs for api-auth
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=api-auth-staging" \
    --limit=50 \
    --format=json
```

**Verify Budgets:**

```bash
# List budgets
gcloud billing budgets list --billing-account=YOUR_BILLING_ACCOUNT_ID
```

### Phase 8: Load Balancer & Custom Domain (Optional, 30 minutes)

**If you want custom domains:**

1. **Reserve Static IP:**

```bash
gcloud compute addresses create adyela-staging-ip \
    --global
```

2. **Create Load Balancer with Cloud Run backend**
   - Follow GCP Console wizard for HTTPS Load Balancer
   - Add SSL certificate for your domain

3. **Point DNS to Load Balancer IP**

## 📊 Cost Monitoring

**View Current Costs:**

```bash
# Current month costs
gcloud billing accounts list
gcloud billing projects describe $PROJECT_ID
```

**Set Up Billing Alerts:**

Already configured via Terraform with $150/month threshold for staging.

**Monitor in Console:**

- https://console.cloud.google.com/billing

## 🔧 Troubleshooting

### Service Won't Start

```bash
# Check service logs
gcloud run services logs read api-auth-staging --region=$REGION

# Check service configuration
gcloud run services describe api-auth-staging --region=$REGION
```

### Secret Not Found

```bash
# List secrets
gcloud secrets list

# Check secret permissions
gcloud secrets get-iam-policy jwt-secret-staging
```

### Budget Alerts Not Working

```bash
# Verify budget exists
gcloud billing budgets list --billing-account=YOUR_BILLING_ACCOUNT_ID

# Check notification channels
gcloud alpha monitoring channels list
```

### Terraform State Issues

```bash
# If state is corrupted
cd infra/environments/staging
terraform init -reconfigure

# Import existing resource
terraform import google_cloud_run_v2_service.api_auth projects/$PROJECT_ID/locations/$REGION/services/api-auth-staging
```

## 🚀 CI/CD Pipeline

Once GitHub Actions is configured, deployments are automatic:

1. **Push to `main` branch** → Automatic deployment to staging
2. **Manual approval** → Deployment to production
3. **Pull Request** → Run tests and linting

**Manual Deploy via GitHub Actions:**

```bash
# Trigger workflow manually
gh workflow run cd-deploy-staging.yml -f services=api-auth

# Deploy all services
gh workflow run cd-deploy-staging.yml -f services=all
```

## 📚 Next Steps

After deployment:

1. **Configure Firestore Security Rules** - See
   `docs/architecture/multi-tenancy-hybrid-model.md`
2. **Set Up Monitoring Dashboards** - See
   `docs/infrastructure/observability-distributed-systems.md`
3. **Run E2E Tests** - `pnpm test:e2e`
4. **Load Testing** - Use k6 or similar
5. **Security Audit** - Run `pnpm security:scan`

## 🆘 Support

- **Documentation**: See `docs/` folder
- **Issues**: Create GitHub issue
- **Emergency**: Contact dev@adyela.care

---

**Last Updated**: 2025-10-18 **Environment**: Staging **Estimated Setup Time**:
~2.5 hours
