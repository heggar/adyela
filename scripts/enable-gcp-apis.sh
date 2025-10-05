#!/bin/bash
set -e

# Enable GCP APIs for Adyela project
# Usage: ./enable-gcp-apis.sh PROJECT_ID ENVIRONMENT

PROJECT_ID=$1
ENVIRONMENT=$2

if [ -z "$PROJECT_ID" ] || [ -z "$ENVIRONMENT" ]; then
  echo "❌ Usage: ./enable-gcp-apis.sh PROJECT_ID ENVIRONMENT"
  echo ""
  echo "Examples:"
  echo "  ./enable-gcp-apis.sh adyela-staging staging"
  echo "  ./enable-gcp-apis.sh adyela-production production"
  exit 1
fi

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
  echo "❌ ENVIRONMENT must be 'staging' or 'production'"
  exit 1
fi

echo "🔧 Enabling GCP APIs for $PROJECT_ID ($ENVIRONMENT)..."
echo ""

gcloud config set project $PROJECT_ID

# Core APIs (both staging and production)
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

# Production-only APIs
PRODUCTION_APIS=(
  "compute.googleapis.com"
  "cloudcdn.googleapis.com"
  "cloudarmor.googleapis.com"
  "vpcaccess.googleapis.com"
)

echo "📦 Enabling core APIs..."
for api in "${CORE_APIS[@]}"; do
  echo "  - Enabling $api..."
  gcloud services enable $api --quiet
done

# Enable production APIs if production environment
if [ "$ENVIRONMENT" = "production" ]; then
  echo ""
  echo "🏭 Enabling production-specific APIs..."
  for api in "${PRODUCTION_APIS[@]}"; do
    echo "  - Enabling $api..."
    gcloud services enable $api --quiet
  done
fi

echo ""
echo "✅ All APIs enabled successfully!"
echo ""
echo "📋 Enabled APIs:"
gcloud services list --enabled --format="table(config.name,config.title)"

echo ""
echo "🎉 Done! You can now deploy infrastructure to $PROJECT_ID"
