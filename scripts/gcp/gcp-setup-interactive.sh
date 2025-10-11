#!/bin/bash

# Interactive GCP Setup Script for Adyela
# This script guides you through the GCP setup process

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🚀 Adyela GCP Setup - Interactive Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Verify gcloud installation
echo -e "${YELLOW}Step 1: Verifying gcloud installation...${NC}"
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI not found${NC}"
    echo "Install it with: brew install google-cloud-sdk"
    exit 1
fi
echo -e "${GREEN}✅ gcloud CLI installed${NC}"
gcloud --version | head -n 1
echo ""

# Step 2: Check authentication
echo -e "${YELLOW}Step 2: Checking authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 &> /dev/null; then
    echo -e "${RED}❌ Not authenticated${NC}"
    echo "Run: gcloud auth login"
    exit 1
fi

CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1)
echo -e "${GREEN}✅ Authenticated as: $CURRENT_ACCOUNT${NC}"
echo ""

# Step 3: Get organization and billing info
echo -e "${YELLOW}Step 3: Gathering project information...${NC}"
echo ""

# List organizations
echo "📋 Available organizations:"
gcloud organizations list
echo ""

read -p "Enter your Organization ID: " ORG_ID
if [ -z "$ORG_ID" ]; then
    echo -e "${RED}❌ Organization ID is required${NC}"
    exit 1
fi

# List billing accounts
echo ""
echo "💳 Available billing accounts:"
gcloud billing accounts list
echo ""

read -p "Enter your Billing Account ID: " BILLING_ACCOUNT
if [ -z "$BILLING_ACCOUNT" ]; then
    echo -e "${RED}❌ Billing Account ID is required${NC}"
    exit 1
fi

# Get project IDs
echo ""
read -p "Enter Staging Project ID [adyela-staging]: " STAGING_PROJECT
STAGING_PROJECT=${STAGING_PROJECT:-adyela-staging}

read -p "Enter Production Project ID [adyela-production]: " PRODUCTION_PROJECT
PRODUCTION_PROJECT=${PRODUCTION_PROJECT:-adyela-production}

read -p "Enter GitHub Repository (owner/repo) [heggar/adyela]: " GITHUB_REPO
GITHUB_REPO=${GITHUB_REPO:-heggar/adyela}

read -p "Enter your email for billing alerts: " EMAIL

# Save configuration
cat > .gcp-config <<EOF
ORG_ID=$ORG_ID
BILLING_ACCOUNT=$BILLING_ACCOUNT
STAGING_PROJECT=$STAGING_PROJECT
PRODUCTION_PROJECT=$PRODUCTION_PROJECT
GITHUB_REPO=$GITHUB_REPO
EMAIL=$EMAIL
EOF

echo ""
echo -e "${GREEN}✅ Configuration saved to .gcp-config${NC}"
echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  📋 Configuration Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Organization ID:     $ORG_ID"
echo "Billing Account:     $BILLING_ACCOUNT"
echo "Staging Project:     $STAGING_PROJECT"
echo "Production Project:  $PRODUCTION_PROJECT"
echo "GitHub Repository:   $GITHUB_REPO"
echo "Email:               $EMAIL"
echo ""

# Step 4: Verify projects exist
echo -e "${YELLOW}Step 4: Verifying projects...${NC}"

if gcloud projects describe $STAGING_PROJECT &> /dev/null; then
    echo -e "${GREEN}✅ Staging project exists: $STAGING_PROJECT${NC}"
else
    echo -e "${YELLOW}⚠️  Staging project not found. It will be created.${NC}"
fi

if gcloud projects describe $PRODUCTION_PROJECT &> /dev/null; then
    echo -e "${GREEN}✅ Production project exists: $PRODUCTION_PROJECT${NC}"
else
    echo -e "${YELLOW}⚠️  Production project not found. It will be created.${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ Configuration complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/enable-gcp-apis.sh $STAGING_PROJECT staging"
echo "  2. Run: ./scripts/enable-gcp-apis.sh $PRODUCTION_PROJECT production"
echo "  3. Run: ./scripts/setup-terraform-backend.sh"
echo "  4. Run: ./scripts/setup-gcp-oidc.sh"
echo "  5. Run: ./scripts/setup-budgets.sh"
echo ""
