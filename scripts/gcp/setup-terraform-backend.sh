#!/bin/bash

# Setup Terraform Backend (GCS buckets) for Adyela
# This script creates GCS buckets for Terraform state storage

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🗄️  Terraform Backend Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Load configuration
if [ -f .gcp-config ]; then
    source .gcp-config
    echo -e "${GREEN}✅ Loaded configuration from .gcp-config${NC}"
else
    echo -e "${RED}❌ Configuration file not found${NC}"
    echo "Run: ./scripts/gcp-setup-interactive.sh first"
    exit 1
fi

REGION=${REGION:-us-central1}

echo ""
echo "This script will create GCS buckets for Terraform state storage:"
echo "  - ${STAGING_PROJECT}-terraform-state"
echo "  - ${PRODUCTION_PROJECT}-terraform-state"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 1
fi

# Function to create Terraform backend bucket
create_backend_bucket() {
    local PROJECT_ID=$1
    local ENVIRONMENT=$2
    local BUCKET_NAME="${PROJECT_ID}-terraform-state"

    echo ""
    echo -e "${YELLOW}📦 Creating Terraform backend for $ENVIRONMENT ($PROJECT_ID)...${NC}"

    gcloud config set project $PROJECT_ID

    # Check if bucket already exists
    if gsutil ls gs://$BUCKET_NAME &> /dev/null; then
        echo -e "${YELLOW}⚠️  Bucket gs://$BUCKET_NAME already exists${NC}"
        return 0
    fi

    # Create bucket
    echo "Creating bucket gs://$BUCKET_NAME..."
    gcloud storage buckets create gs://$BUCKET_NAME \
        --project=$PROJECT_ID \
        --location=$REGION \
        --uniform-bucket-level-access \
        --public-access-prevention

    # Enable versioning
    echo "Enabling versioning..."
    gcloud storage buckets update gs://$BUCKET_NAME \
        --versioning

    # Set lifecycle policy to keep last 10 versions
    cat > /tmp/lifecycle-$ENVIRONMENT.json <<EOF
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

    echo "Setting lifecycle policy..."
    gcloud storage buckets update gs://$BUCKET_NAME \
        --lifecycle-file=/tmp/lifecycle-$ENVIRONMENT.json

    rm /tmp/lifecycle-$ENVIRONMENT.json

    echo -e "${GREEN}✅ Terraform backend created: gs://$BUCKET_NAME${NC}"
}

# Create backend for staging
create_backend_bucket $STAGING_PROJECT "staging"

# Create backend for production
create_backend_bucket $PRODUCTION_PROJECT "production"

# Update Terraform backend configurations
echo ""
echo -e "${YELLOW}📝 Updating Terraform backend configurations...${NC}"

# Update staging backend
cat > infra/environments/staging/backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${STAGING_PROJECT}-terraform-state"
    prefix = "terraform/state"
  }
}
EOF

# Update production backend
cat > infra/environments/production/backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${PRODUCTION_PROJECT}-terraform-state"
    prefix = "terraform/state"
  }
}
EOF

# Update dev backend
cat > infra/environments/dev/backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${STAGING_PROJECT}-terraform-state"
    prefix = "terraform/state/dev"
  }
}
EOF

echo -e "${GREEN}✅ Backend configurations updated${NC}"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ Terraform Backend Setup Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Created buckets:"
echo "  - gs://${STAGING_PROJECT}-terraform-state"
echo "  - gs://${PRODUCTION_PROJECT}-terraform-state"
echo ""
echo "Next step:"
echo "  Run: ./scripts/setup-gcp-oidc.sh"
echo ""
