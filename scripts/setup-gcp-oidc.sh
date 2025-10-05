#!/bin/bash
set -e

# Setup Workload Identity Federation (OIDC) for GitHub Actions
# Usage: ./setup-gcp-oidc.sh PROJECT_ID GITHUB_REPO ENVIRONMENT

PROJECT_ID=$1
GITHUB_REPO=$2
ENVIRONMENT=$3

if [ -z "$PROJECT_ID" ] || [ -z "$GITHUB_REPO" ] || [ -z "$ENVIRONMENT" ]; then
  echo "❌ Usage: ./setup-gcp-oidc.sh PROJECT_ID GITHUB_REPO ENVIRONMENT"
  echo ""
  echo "Examples:"
  echo "  ./setup-gcp-oidc.sh adyela-staging heggar/adyela staging"
  echo "  ./setup-gcp-oidc.sh adyela-production heggar/adyela production"
  exit 1
fi

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
  echo "❌ ENVIRONMENT must be 'staging' or 'production'"
  exit 1
fi

echo "🔐 Setting up Workload Identity Federation for GitHub Actions..."
echo "   Project: $PROJECT_ID"
echo "   GitHub Repo: $GITHUB_REPO"
echo "   Environment: $ENVIRONMENT"
echo ""

gcloud config set project $PROJECT_ID

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
POOL_NAME="github-actions-pool"
PROVIDER_NAME="github-actions-provider"
SERVICE_ACCOUNT_NAME="github-actions-${ENVIRONMENT}"

echo "📝 Project Number: $PROJECT_NUMBER"
echo ""

# 1. Create Workload Identity Pool
echo "1️⃣  Creating Workload Identity Pool..."
if gcloud iam workload-identity-pools describe $POOL_NAME --location="global" &>/dev/null; then
  echo "   ⚠️  Pool already exists, skipping..."
else
  gcloud iam workload-identity-pools create $POOL_NAME \
    --location="global" \
    --display-name="GitHub Actions Pool"
  echo "   ✅ Pool created"
fi

# 2. Create OIDC Provider
echo ""
echo "2️⃣  Creating OIDC Provider..."
if gcloud iam workload-identity-pools providers describe $PROVIDER_NAME \
  --location="global" \
  --workload-identity-pool=$POOL_NAME &>/dev/null; then
  echo "   ⚠️  Provider already exists, skipping..."
else
  gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
    --location="global" \
    --workload-identity-pool=$POOL_NAME \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository=='$GITHUB_REPO'"
  echo "   ✅ Provider created"
fi

# 3. Create Service Account
echo ""
echo "3️⃣  Creating Service Account..."
if gcloud iam service-accounts describe ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com &>/dev/null; then
  echo "   ⚠️  Service Account already exists, skipping..."
else
  gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
    --display-name="GitHub Actions - ${ENVIRONMENT^}"
  echo "   ✅ Service Account created"
fi

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# 4. Grant permissions to Service Account
echo ""
echo "4️⃣  Granting IAM permissions to Service Account..."

ROLES=(
  "roles/run.admin"
  "roles/storage.admin"
  "roles/iam.serviceAccountUser"
  "roles/secretmanager.secretAccessor"
  "roles/cloudbuild.builds.builder"
  "roles/viewer"
)

for role in "${ROLES[@]}"; do
  echo "   - Granting $role..."
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="$role" \
    --quiet &>/dev/null
done
echo "   ✅ Permissions granted"

# 5. Allow GitHub Actions to impersonate Service Account
echo ""
echo "5️⃣  Allowing GitHub Actions to impersonate Service Account..."
gcloud iam service-accounts add-iam-policy-binding \
  $SERVICE_ACCOUNT_EMAIL \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_REPO}" \
  --quiet
echo "   ✅ Impersonation allowed"

# 6. Output GitHub Secrets
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Workload Identity Federation setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Add these secrets to GitHub:"
echo "   Repository: https://github.com/$GITHUB_REPO/settings/secrets/actions"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│ Secret Name: WORKLOAD_IDENTITY_PROVIDER_${ENVIRONMENT^^}"
echo "│ Value:"
echo "│ projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│ Secret Name: SERVICE_ACCOUNT_${ENVIRONMENT^^}"
echo "│ Value:"
echo "│ $SERVICE_ACCOUNT_EMAIL"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│ Secret Name: GCP_PROJECT_ID_${ENVIRONMENT^^}"
echo "│ Value:"
echo "│ $PROJECT_ID"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "🔗 Quick links:"
echo "   - GitHub Secrets: https://github.com/$GITHUB_REPO/settings/secrets/actions"
echo "   - GCP Console: https://console.cloud.google.com/iam-admin/workload-identity-pools?project=$PROJECT_ID"
echo ""
echo "🎉 Done! You can now deploy from GitHub Actions without service account keys."
