# ☁️ Google Cloud Platform Setup - Adyela

Complete guide to configure Google Cloud Platform for staging and production environments.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [GCP Projects Structure](#gcp-projects-structure)
3. [Enable Required APIs](#enable-required-apis)
4. [Terraform Backend Setup](#terraform-backend-setup)
5. [Workload Identity Federation (OIDC)](#workload-identity-federation-oidc)
6. [Secret Manager Configuration](#secret-manager-configuration)
7. [Budgets and Billing Alerts](#budgets-and-billing-alerts)
8. [Domain and SSL Configuration](#domain-and-ssl-configuration)
9. [Security Checklist](#security-checklist)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

Install these tools locally:

```bash
# Google Cloud SDK
brew install google-cloud-sdk

# Terraform
brew install terraform

# GitHub CLI (optional but recommended)
brew install gh
```

### GCP Account Requirements

- **Google Cloud Account** with billing enabled
- **Organization Admin** role (for creating projects)
- **Billing Account Admin** role (for budget setup)

### Verify Installation

```bash
# Check gcloud version
gcloud --version

# Check terraform version
terraform --version

# Login to GCP
gcloud auth login

# Set default account
gcloud auth application-default login
```

---

## GCP Projects Structure

We recommend **separate projects** for isolation and cost management:

```
Organization: adyela.com
├── adyela-staging      (Project ID: adyela-staging)
│   ├── Purpose: Testing and pre-production validation
│   ├── Budget: $10/month
│   └── Resources: Minimal (scale to zero)
│
└── adyela-production   (Project ID: adyela-production)
    ├── Purpose: Production workloads
    ├── Budget: $100/month
    └── Resources: Full (high availability)
```

### Create Projects

```bash
# Set variables
export ORG_ID="YOUR_ORG_ID"           # Find with: gcloud organizations list
export BILLING_ACCOUNT="YOUR_BILLING_ID"  # Find with: gcloud billing accounts list

# Create staging project
gcloud projects create adyela-staging \
  --name="Adyela - Staging" \
  --organization=$ORG_ID

# Create production project
gcloud projects create adyela-production \
  --name="Adyela - Production" \
  --organization=$ORG_ID

# Link billing accounts
gcloud billing projects link adyela-staging \
  --billing-account=$BILLING_ACCOUNT

gcloud billing projects link adyela-production \
  --billing-account=$BILLING_ACCOUNT

# Verify projects
gcloud projects list --filter="adyela"
```

---

## Enable Required APIs

### API List

Enable these APIs in **both staging and production** projects:

| API                                   | Purpose                            | Required   |
| ------------------------------------- | ---------------------------------- | ---------- |
| `run.googleapis.com`                  | Cloud Run for containers           | ✅         |
| `firestore.googleapis.com`            | Firestore database                 | ✅         |
| `identitytoolkit.googleapis.com`      | Identity Platform (Firebase Auth)  | ✅         |
| `storage-component.googleapis.com`    | Cloud Storage                      | ✅         |
| `storage-api.googleapis.com`          | Cloud Storage API                  | ✅         |
| `secretmanager.googleapis.com`        | Secret Manager                     | ✅         |
| `cloudbuild.googleapis.com`           | Cloud Build                        | ✅         |
| `cloudresourcemanager.googleapis.com` | Resource Manager                   | ✅         |
| `iam.googleapis.com`                  | IAM                                | ✅         |
| `iamcredentials.googleapis.com`       | IAM Credentials                    | ✅         |
| `monitoring.googleapis.com`           | Cloud Monitoring                   | ✅         |
| `logging.googleapis.com`              | Cloud Logging                      | ✅         |
| `cloudtrace.googleapis.com`           | Cloud Trace                        | ✅         |
| `cloudprofiler.googleapis.com`        | Cloud Profiler                     | ✅         |
| `clouderrorreporting.googleapis.com`  | Error Reporting                    | ✅         |
| `containerregistry.googleapis.com`    | Container Registry                 | ✅         |
| `artifactregistry.googleapis.com`     | Artifact Registry (recommended)    | ✅         |
| `compute.googleapis.com`              | Compute Engine (for load balancer) | Production |
| `cloudcdn.googleapis.com`             | Cloud CDN                          | Production |
| `cloudarmor.googleapis.com`           | Cloud Armor (WAF)                  | Production |
| `vpcaccess.googleapis.com`            | VPC Access Connector               | Optional   |

### Enable APIs Script

**Staging:**

```bash
export PROJECT_ID="adyela-staging"

gcloud config set project $PROJECT_ID

# Core APIs
gcloud services enable \
  run.googleapis.com \
  firestore.googleapis.com \
  identitytoolkit.googleapis.com \
  storage-component.googleapis.com \
  storage-api.googleapis.com \
  secretmanager.googleapis.com \
  cloudbuild.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudtrace.googleapis.com \
  cloudprofiler.googleapis.com \
  clouderrorreporting.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com

# Verify enabled APIs
gcloud services list --enabled
```

**Production:**

```bash
export PROJECT_ID="adyela-production"

gcloud config set project $PROJECT_ID

# Core APIs (same as staging)
gcloud services enable \
  run.googleapis.com \
  firestore.googleapis.com \
  identitytoolkit.googleapis.com \
  storage-component.googleapis.com \
  storage-api.googleapis.com \
  secretmanager.googleapis.com \
  cloudbuild.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudtrace.googleapis.com \
  cloudprofiler.googleapis.com \
  clouderrorreporting.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com

# Additional production APIs
gcloud services enable \
  compute.googleapis.com \
  cloudcdn.googleapis.com \
  cloudarmor.googleapis.com \
  vpcaccess.googleapis.com

# Verify
gcloud services list --enabled
```

**Enable All at Once (Alternative):**

Save to `enable-apis.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ID=$1
ENVIRONMENT=$2

if [ -z "$PROJECT_ID" ] || [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./enable-apis.sh PROJECT_ID ENVIRONMENT"
  echo "Example: ./enable-apis.sh adyela-staging staging"
  exit 1
fi

echo "🔧 Enabling APIs for $PROJECT_ID ($ENVIRONMENT)..."

gcloud config set project $PROJECT_ID

CORE_APIS=(
  "run.googleapis.com"
  "firestore.googleapis.com"
  "identitytoolkit.googleapis.com"
  "storage-component.googleapis.com"
  "storage-api.googleapis.com"
  "secretmanager.googleapis.com"
  "cloudbuild.googleapis.com"
  "cloudresourcemanager.googleapis.com"
  "iam.googleapis.com"
  "iamcredentials.googleapis.com"
  "monitoring.googleapis.com"
  "logging.googleapis.com"
  "cloudtrace.googleapis.com"
  "cloudprofiler.googleapis.com"
  "clouderrorreporting.googleapis.com"
  "containerregistry.googleapis.com"
  "artifactregistry.googleapis.com"
)

PRODUCTION_APIS=(
  "compute.googleapis.com"
  "cloudcdn.googleapis.com"
  "cloudarmor.googleapis.com"
  "vpcaccess.googleapis.com"
)

# Enable core APIs
for api in "${CORE_APIS[@]}"; do
  echo "Enabling $api..."
  gcloud services enable $api
done

# Enable production APIs if production environment
if [ "$ENVIRONMENT" = "production" ]; then
  for api in "${PRODUCTION_APIS[@]}"; do
    echo "Enabling $api..."
    gcloud services enable $api
  done
fi

echo "✅ All APIs enabled successfully!"
gcloud services list --enabled
```

Run:

```bash
chmod +x enable-apis.sh
./enable-apis.sh adyela-staging staging
./enable-apis.sh adyela-production production
```

---

## Terraform Backend Setup

Store Terraform state remotely in Google Cloud Storage with state locking.

### Create Terraform Backend Bucket

**Staging:**

```bash
export PROJECT_ID="adyela-staging"
export BUCKET_NAME="${PROJECT_ID}-terraform-state"
export REGION="us-central1"

gcloud config set project $PROJECT_ID

# Create bucket with versioning and encryption
gcloud storage buckets create gs://$BUCKET_NAME \
  --project=$PROJECT_ID \
  --location=$REGION \
  --uniform-bucket-level-access \
  --public-access-prevention

# Enable versioning (for state recovery)
gcloud storage buckets update gs://$BUCKET_NAME \
  --versioning

# Set lifecycle policy to keep last 10 versions
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "numNewerVersions": 10
        }
      }
    ]
  }
}
EOF

gcloud storage buckets update gs://$BUCKET_NAME \
  --lifecycle-file=lifecycle.json

rm lifecycle.json

# Verify bucket
gcloud storage buckets describe gs://$BUCKET_NAME
```

**Production:**

```bash
export PROJECT_ID="adyela-production"
export BUCKET_NAME="${PROJECT_ID}-terraform-state"
export REGION="us-central1"

# Repeat same commands as staging...
```

### Configure Terraform Backend

**File: `infrastructure/terraform/environments/staging/backend.tf`**

```hcl
terraform {
  backend "gcs" {
    bucket  = "adyela-staging-terraform-state"
    prefix  = "terraform/state"
  }

  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
```

**File: `infrastructure/terraform/environments/production/backend.tf`**

```hcl
terraform {
  backend "gcs" {
    bucket  = "adyela-production-terraform-state"
    prefix  = "terraform/state"
  }

  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
```

### Initialize Terraform

```bash
# Staging
cd infrastructure/terraform/environments/staging
terraform init

# Production
cd infrastructure/terraform/environments/production
terraform init
```

---

## Workload Identity Federation (OIDC)

Authenticate GitHub Actions to GCP **without service account keys** using OIDC.

### Why OIDC?

- ✅ No long-lived credentials
- ✅ Automatic key rotation
- ✅ Better security posture
- ✅ GitHub-native integration

### Setup OIDC for Staging

```bash
export PROJECT_ID="adyela-staging"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export GITHUB_REPO="heggar/adyela"  # Replace with your repo
export POOL_NAME="github-actions-pool"
export PROVIDER_NAME="github-actions-provider"
export SERVICE_ACCOUNT_NAME="github-actions-staging"

gcloud config set project $PROJECT_ID

# 1. Create Workload Identity Pool
gcloud iam workload-identity-pools create $POOL_NAME \
  --location="global" \
  --display-name="GitHub Actions Pool"

# 2. Create OIDC Provider
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
  --location="global" \
  --workload-identity-pool=$POOL_NAME \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='$GITHUB_REPO'"

# 3. Create Service Account
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --display-name="GitHub Actions - Staging"

# 4. Grant permissions to Service Account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# 5. Allow GitHub Actions to impersonate Service Account
gcloud iam service-accounts add-iam-policy-binding \
  ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_REPO}"

# 6. Get Workload Identity Provider path (for GitHub Actions)
echo "Add this to GitHub Secrets as WORKLOAD_IDENTITY_PROVIDER_STAGING:"
echo "projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"

echo "Add this to GitHub Secrets as SERVICE_ACCOUNT_STAGING:"
echo "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
```

### Setup OIDC for Production

```bash
export PROJECT_ID="adyela-production"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export GITHUB_REPO="heggar/adyela"
export POOL_NAME="github-actions-pool"
export PROVIDER_NAME="github-actions-provider"
export SERVICE_ACCOUNT_NAME="github-actions-production"

# Repeat same steps as staging with production values...
```

### Add Secrets to GitHub

Go to your GitHub repository → Settings → Secrets and variables → Actions

**Add these secrets:**

| Secret Name                             | Value                                                                 | Environment |
| --------------------------------------- | --------------------------------------------------------------------- | ----------- |
| `WORKLOAD_IDENTITY_PROVIDER_STAGING`    | `projects/123.../workloadIdentityPools/.../providers/...`             | staging     |
| `SERVICE_ACCOUNT_STAGING`               | `github-actions-staging@adyela-staging.iam.gserviceaccount.com`       | staging     |
| `GCP_PROJECT_ID_STAGING`                | `adyela-staging`                                                      | staging     |
| `WORKLOAD_IDENTITY_PROVIDER_PRODUCTION` | `projects/456.../workloadIdentityPools/.../providers/...`             | production  |
| `SERVICE_ACCOUNT_PRODUCTION`            | `github-actions-production@adyela-production.iam.gserviceaccount.com` | production  |
| `GCP_PROJECT_ID_PRODUCTION`             | `adyela-production`                                                   | production  |

### Test OIDC in GitHub Actions

**File: `.github/workflows/test-gcp-auth.yml`**

```yaml
name: Test GCP Authentication

on:
  workflow_dispatch:

jobs:
  test-staging:
    name: Test Staging Auth
    runs-on: ubuntu-latest
    environment: staging
    permissions:
      contents: read
      id-token: write

    steps:
      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WORKLOAD_IDENTITY_PROVIDER_STAGING }}
          service_account: ${{ secrets.SERVICE_ACCOUNT_STAGING }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Test GCP access
        run: |
          gcloud config list
          gcloud projects describe ${{ secrets.GCP_PROJECT_ID_STAGING }}
          echo "✅ Authentication successful!"
```

---

## Secret Manager Configuration

Store sensitive configuration securely in Secret Manager.

### Required Secrets

**Staging:**

| Secret Name           | Description                                    | Example Value               |
| --------------------- | ---------------------------------------------- | --------------------------- |
| `SECRET_KEY`          | Django/FastAPI secret key                      | `openssl rand -base64 32`   |
| `DATABASE_URL`        | Firestore connection (usually auto-configured) | N/A                         |
| `REDIS_URL`           | Redis connection string                        | `redis://redis:6379/0`      |
| `FIREBASE_PROJECT_ID` | Firebase project ID                            | `adyela-staging`            |
| `SMTP_HOST`           | Email server (optional)                        | `smtp.sendgrid.net`         |
| `SMTP_PORT`           | Email port                                     | `587`                       |
| `SMTP_USERNAME`       | Email username                                 | `apikey`                    |
| `SMTP_PASSWORD`       | Email password                                 | `SG.xxx`                    |
| `SENTRY_DSN`          | Error tracking (optional)                      | `https://xxx@sentry.io/xxx` |

**Production (additional):**

| Secret Name       | Description                 | Example Value |
| ----------------- | --------------------------- | ------------- |
| `DOMAIN_NAME`     | Production domain           | `adyela.com`  |
| `SSL_CERTIFICATE` | SSL certificate (if custom) | N/A           |

### Create Secrets

**Staging:**

```bash
export PROJECT_ID="adyela-staging"
gcloud config set project $PROJECT_ID

# Generate secret key
export SECRET_KEY=$(openssl rand -base64 32)

# Create secrets
echo -n "$SECRET_KEY" | gcloud secrets create SECRET_KEY \
  --data-file=- \
  --replication-policy="automatic"

echo -n "adyela-staging" | gcloud secrets create FIREBASE_PROJECT_ID \
  --data-file=- \
  --replication-policy="automatic"

echo -n "redis://redis:6379/0" | gcloud secrets create REDIS_URL \
  --data-file=- \
  --replication-policy="automatic"

# Add more secrets as needed
# echo -n "VALUE" | gcloud secrets create SECRET_NAME --data-file=-

# List all secrets
gcloud secrets list
```

**Production:**

```bash
export PROJECT_ID="adyela-production"
# Repeat with production values...
```

### Grant Access to Secrets

```bash
export PROJECT_ID="adyela-staging"
export SERVICE_ACCOUNT="github-actions-staging@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant access to all secrets
for secret in $(gcloud secrets list --format="value(name)"); do
  gcloud secrets add-iam-policy-binding $secret \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/secretmanager.secretAccessor"
done

# Or grant to Cloud Run service account
export CLOUD_RUN_SA="YOUR_CLOUD_RUN_SA@${PROJECT_ID}.iam.gserviceaccount.com"

for secret in $(gcloud secrets list --format="value(name)"); do
  gcloud secrets add-iam-policy-binding $secret \
    --member="serviceAccount:$CLOUD_RUN_SA" \
    --role="roles/secretmanager.secretAccessor"
done
```

### Access Secrets in Cloud Run

**Option 1: Environment Variables (from secrets)**

```yaml
# In your Cloud Run YAML or terraform
env:
  - name: SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: SECRET_KEY
        key: latest
```

**Option 2: Mount as Volume**

```yaml
volumes:
  - name: secrets
    secret:
      secretName: SECRET_KEY
volumeMounts:
  - name: secrets
    mountPath: /secrets
```

---

## Budgets and Billing Alerts

Prevent unexpected costs with budget alerts.

### Create Budget for Staging

```bash
export PROJECT_ID="adyela-staging"
export BUDGET_AMOUNT=10  # $10/month
export EMAIL="your-email@example.com"

# Create budget via gcloud (requires JSON config)
cat > budget-staging.json <<EOF
{
  "displayName": "Staging Monthly Budget",
  "budgetFilter": {
    "projects": ["projects/${PROJECT_ID}"]
  },
  "amount": {
    "specifiedAmount": {
      "currencyCode": "USD",
      "units": "${BUDGET_AMOUNT}"
    }
  },
  "thresholdRules": [
    {
      "thresholdPercent": 0.5,
      "spendBasis": "CURRENT_SPEND"
    },
    {
      "thresholdPercent": 0.8,
      "spendBasis": "CURRENT_SPEND"
    },
    {
      "thresholdPercent": 1.0,
      "spendBasis": "CURRENT_SPEND"
    },
    {
      "thresholdPercent": 1.2,
      "spendBasis": "CURRENT_SPEND"
    }
  ],
  "notificationsRule": {
    "pubsubTopic": "",
    "monitoringNotificationChannels": [],
    "disableDefaultIamRecipients": false
  }
}
EOF

# Note: Budget creation via CLI requires billing account permissions
# It's easier to create via Console: https://console.cloud.google.com/billing/budgets
```

### Create Budget via Console (Recommended)

1. Go to: https://console.cloud.google.com/billing/budgets
2. Click **Create Budget**
3. **Scope:**
   - Projects: Select `adyela-staging`
4. **Amount:**
   - Budget type: Specified amount
   - Target amount: $10 (staging) or $100 (production)
5. **Actions:**
   - Set alert thresholds: 50%, 80%, 100%, 120%
   - Email recipients: Your team email
6. **Finish** and repeat for production

### Alert Recommendations

| Threshold | Action                                               | Severity  |
| --------- | ---------------------------------------------------- | --------- |
| 50%       | Email notification                                   | Info      |
| 80%       | Email + Slack notification                           | Warning   |
| 100%      | Email + Slack + PagerDuty                            | Critical  |
| 120%      | Email + Slack + PagerDuty + Auto-shutdown (optional) | Emergency |

### Cost Monitoring Dashboard

```bash
# View current month costs
gcloud billing accounts list
gcloud billing projects describe $PROJECT_ID

# Or use this script
cat > check-costs.sh <<'EOF'
#!/bin/bash
PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]; then
  echo "Usage: ./check-costs.sh PROJECT_ID"
  exit 1
fi

echo "📊 Cost report for $PROJECT_ID"
echo "================================"

# Get current billing
gcloud billing projects describe $PROJECT_ID

# View costs (requires BigQuery export setup)
# See: https://cloud.google.com/billing/docs/how-to/export-data-bigquery
EOF

chmod +x check-costs.sh
```

---

## Domain and SSL Configuration

Configure custom domains with automatic SSL certificates.

### Prerequisites

- Domain registered (e.g., `adyela.com`)
- Access to DNS management

### Map Custom Domain to Cloud Run

**Staging:**

```bash
export PROJECT_ID="adyela-staging"
export SERVICE_NAME="adyela-api"
export DOMAIN="api-staging.adyela.com"
export REGION="us-central1"

gcloud config set project $PROJECT_ID

# Map domain to Cloud Run service
gcloud run services update $SERVICE_NAME \
  --region=$REGION \
  --platform=managed \
  --add-domain-mapping=$DOMAIN

# Get DNS records to add
gcloud beta run domain-mappings describe \
  --domain=$DOMAIN \
  --region=$REGION
```

**Production:**

```bash
export PROJECT_ID="adyela-production"
export SERVICE_NAME="adyela-api"
export DOMAIN="api.adyela.com"
export REGION="us-central1"

# Same commands as staging...
```

### Add DNS Records

After running the above commands, you'll get DNS records like:

```
NAME                TYPE    DATA
api-staging         CNAME   ghs.googlehosted.com.
```

**Add to your DNS provider:**

| Type  | Name        | Value                | TTL  |
| ----- | ----------- | -------------------- | ---- |
| CNAME | api-staging | ghs.googlehosted.com | 3600 |
| CNAME | api         | ghs.googlehosted.com | 3600 |

**For web frontend (Firebase Hosting or Cloud Storage + CDN):**

```bash
# If using Firebase Hosting
firebase deploy --only hosting

# Follow prompts to add custom domain
# Add DNS records as instructed
```

### SSL Certificate (Automatic)

Cloud Run automatically provisions SSL certificates via Let's Encrypt.

- **Provisioning time:** 15-60 minutes after DNS propagation
- **Auto-renewal:** Yes, automatic
- **Wildcard support:** No (use Cloud Load Balancer for wildcard)

### Verify SSL

```bash
# Wait for SSL provisioning
gcloud beta run domain-mappings describe \
  --domain=$DOMAIN \
  --region=$REGION \
  --format="value(status.resourceRecords)"

# Test HTTPS
curl -I https://$DOMAIN
```

### Custom SSL with Load Balancer (Production Only)

For advanced features (CDN, WAF, wildcard certificates):

```bash
# Create SSL certificate
gcloud compute ssl-certificates create adyela-ssl-cert \
  --domains=adyela.com,www.adyela.com,*.adyela.com \
  --global

# Create backend service
gcloud compute backend-services create adyela-backend \
  --global

# Create URL map
gcloud compute url-maps create adyela-url-map \
  --default-service=adyela-backend

# Create HTTPS proxy
gcloud compute target-https-proxies create adyela-https-proxy \
  --url-map=adyela-url-map \
  --ssl-certificates=adyela-ssl-cert

# Create forwarding rule
gcloud compute forwarding-rules create adyela-https-rule \
  --global \
  --target-https-proxy=adyela-https-proxy \
  --ports=443

# Get external IP
gcloud compute forwarding-rules describe adyela-https-rule --global
```

---

## Security Checklist

### ✅ Project-Level Security

- [ ] Enable VPC Service Controls
- [ ] Enable Organization Policy constraints
- [ ] Enable Cloud Audit Logs
- [ ] Enable Security Command Center (if available)
- [ ] Configure firewall rules (deny by default)
- [ ] Enable Private Google Access
- [ ] Disable default service accounts

```bash
# Enable audit logs
cat > audit-config.yaml <<EOF
auditConfigs:
- auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_READ
  - logType: DATA_WRITE
  service: allServices
EOF

gcloud projects set-iam-policy $PROJECT_ID audit-config.yaml
```

### ✅ IAM Security

- [ ] Follow principle of least privilege
- [ ] Use Workload Identity Federation (no service account keys)
- [ ] Enable 2FA for all users
- [ ] Review IAM bindings regularly
- [ ] Use service accounts for services (not personal accounts)
- [ ] Set up IAM conditions for time-based access

```bash
# Review IAM bindings
gcloud projects get-iam-policy $PROJECT_ID

# List service accounts
gcloud iam service-accounts list

# Check for service account keys (should be 0)
for sa in $(gcloud iam service-accounts list --format="value(email)"); do
  echo "Keys for $sa:"
  gcloud iam service-accounts keys list --iam-account=$sa
done
```

### ✅ Secret Management

- [ ] All secrets in Secret Manager (no hardcoded secrets)
- [ ] Enable secret versioning
- [ ] Rotate secrets regularly (90 days)
- [ ] Restrict secret access with IAM
- [ ] Enable secret access logging
- [ ] Use customer-managed encryption keys (CMEK) for sensitive data

```bash
# Enable audit logs for Secret Manager
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:your-email@example.com" \
  --role="roles/secretmanager.admin" \
  --condition='expression=request.time < timestamp("2025-12-31T23:59:59Z"),title=Temporary access'
```

### ✅ Network Security

- [ ] Enable Cloud Armor (WAF) for production
- [ ] Configure DDoS protection
- [ ] Use Cloud CDN for static assets
- [ ] Enable HTTPS only (no HTTP)
- [ ] Configure CORS properly
- [ ] Enable VPC Connector for private resources
- [ ] Use private IPs for databases

```bash
# Create Cloud Armor policy (production)
gcloud compute security-policies create adyela-armor-policy \
  --description="Adyela WAF policy"

# Add rules
gcloud compute security-policies rules create 1000 \
  --security-policy=adyela-armor-policy \
  --expression="origin.region_code == 'CN'" \
  --action=deny-403 \
  --description="Block China"

gcloud compute security-policies rules create 2000 \
  --security-policy=adyela-armor-policy \
  --src-ip-ranges=10.0.0.0/8 \
  --action=allow \
  --description="Allow internal"
```

### ✅ Application Security

- [ ] Enable Cloud Run ingress controls (internal/authenticated only)
- [ ] Configure minimum instances (prevent cold starts in production)
- [ ] Set maximum instances (prevent runaway costs)
- [ ] Enable request timeout (< 60s for APIs)
- [ ] Configure health checks
- [ ] Enable container scanning
- [ ] Use distroless/minimal base images

```bash
# Configure Cloud Run security
gcloud run services update $SERVICE_NAME \
  --ingress=internal-and-cloud-load-balancing \
  --min-instances=1 \
  --max-instances=10 \
  --timeout=60s \
  --cpu-throttling \
  --no-allow-unauthenticated \
  --region=$REGION
```

### ✅ Data Security

- [ ] Enable Firestore security rules
- [ ] Enable Cloud Storage bucket policies
- [ ] Encrypt data at rest (default in GCP)
- [ ] Enable audit logging for data access
- [ ] Configure backup retention (30 days minimum)
- [ ] Enable point-in-time recovery
- [ ] Set up data deletion policies (GDPR compliance)

```bash
# Firestore security rules (production)
cat > firestore.rules <<'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Require authentication for all reads/writes
    match /{document=**} {
      allow read, write: if request.auth != null;
    }

    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Appointments require both patient and doctor access
    match /appointments/{appointmentId} {
      allow read: if request.auth.uid == resource.data.patientId
                  || request.auth.uid == resource.data.doctorId;
      allow create: if request.auth.uid == request.resource.data.patientId;
      allow update: if request.auth.uid == resource.data.patientId
                    || request.auth.uid == resource.data.doctorId;
    }
  }
}
EOF

# Deploy rules
firebase deploy --only firestore:rules
```

### ✅ Monitoring & Alerting

- [ ] Set up uptime checks
- [ ] Configure error rate alerts
- [ ] Monitor latency (p95, p99)
- [ ] Track 4xx/5xx error rates
- [ ] Set up log-based metrics
- [ ] Configure incident response playbooks
- [ ] Enable Cloud Trace for request tracing

```bash
# Create uptime check
gcloud monitoring uptime create adyela-api-uptime \
  --display-name="Adyela API Health Check" \
  --resource-type=uptime-url \
  --http-check="https://api.adyela.com/health" \
  --period=60 \
  --timeout=10

# Create alert policy
cat > alert-policy.json <<EOF
{
  "displayName": "API Error Rate > 5%",
  "conditions": [{
    "displayName": "Error rate condition",
    "conditionThreshold": {
      "filter": "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.label.response_code_class=\"5xx\"",
      "comparison": "COMPARISON_GT",
      "thresholdValue": 5,
      "duration": "60s"
    }
  }],
  "notificationChannels": ["CHANNEL_ID"],
  "alertStrategy": {
    "autoClose": "1800s"
  }
}
EOF

gcloud alpha monitoring policies create --policy-from-file=alert-policy.json
```

### ✅ Compliance

- [ ] Enable data residency controls (if required)
- [ ] Configure data retention policies
- [ ] Set up GDPR/HIPAA compliance (if applicable)
- [ ] Enable access transparency logs
- [ ] Document incident response procedures
- [ ] Conduct regular security audits
- [ ] Train team on security best practices

---

## Troubleshooting

### Common Issues

#### 1. "Permission denied" errors

```bash
# Check current user
gcloud auth list

# Check project
gcloud config get-value project

# Grant missing permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:your-email@example.com" \
  --role="roles/owner"
```

#### 2. API not enabled

```bash
# List enabled APIs
gcloud services list --enabled

# Enable missing API
gcloud services enable SERVICE_NAME.googleapis.com
```

#### 3. Terraform state locked

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Or delete lock manually from GCS
gsutil rm gs://BUCKET_NAME/terraform/state/default.tflock
```

#### 4. Cloud Run deployment fails

```bash
# Check logs
gcloud run services logs read $SERVICE_NAME --limit=50

# Describe service
gcloud run services describe $SERVICE_NAME --region=$REGION

# Check IAM permissions
gcloud run services get-iam-policy $SERVICE_NAME --region=$REGION
```

#### 5. Domain mapping not working

```bash
# Verify DNS propagation
dig +short api.adyela.com

# Check domain mapping status
gcloud beta run domain-mappings describe --domain=$DOMAIN --region=$REGION

# View certificate status
gcloud beta run domain-mappings describe --domain=$DOMAIN --region=$REGION \
  --format="value(status.certificateStatus)"
```

#### 6. Secrets not accessible

```bash
# Test secret access
gcloud secrets versions access latest --secret=SECRET_NAME

# Check IAM bindings
gcloud secrets get-iam-policy SECRET_NAME

# Grant access
gcloud secrets add-iam-policy-binding SECRET_NAME \
  --member="serviceAccount:SA@PROJECT.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

---

## Next Steps

After completing this setup:

1. **Deploy Infrastructure:**

   ```bash
   cd infrastructure/terraform/environments/staging
   terraform plan
   terraform apply
   ```

2. **Run Deployment Pipeline:**
   - Trigger GitHub Actions workflow
   - Or manually deploy via CLI

3. **Verify Deployment:**

   ```bash
   # Test API
   curl https://api-staging.adyela.com/health

   # Test Web
   curl https://staging.adyela.com
   ```

4. **Monitor:**
   - Check Cloud Monitoring dashboards
   - Verify logs in Cloud Logging
   - Test alerts

5. **Document:**
   - Add production URLs to README
   - Document runbooks for common issues
   - Share access with team

---

## Additional Resources

- [GCP Best Practices](https://cloud.google.com/architecture/framework)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)

---

**Questions or issues?** Open an issue in the GitHub repository or contact the DevOps team.
