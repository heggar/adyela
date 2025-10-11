#!/bin/bash

# Complete GCP Setup Script for Adyela
# This script runs all setup steps in order

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🚀 Adyela Complete GCP Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "This script will:"
echo "  1. Collect configuration information"
echo "  2. Enable required GCP APIs"
echo "  3. Setup Terraform backend (GCS buckets)"
echo "  4. Configure Workload Identity Federation (OIDC)"
echo "  5. Setup budgets and billing alerts"
echo "  6. Generate GitHub secrets configuration"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 1
fi

echo ""

# Step 1: Interactive configuration
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 1: Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
bash "$SCRIPT_DIR/gcp-setup-interactive.sh"

# Load configuration
source .gcp-config

echo ""
echo -e "${GREEN}✅ Configuration loaded${NC}"
echo ""

# Step 2: Enable APIs
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 2: Enable GCP APIs${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "Enable APIs for staging? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/enable-gcp-apis.sh" $STAGING_PROJECT staging
fi

echo ""
read -p "Enable APIs for production? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/enable-gcp-apis.sh" $PRODUCTION_PROJECT production
fi

echo ""
echo -e "${GREEN}✅ APIs enabled${NC}"
echo ""

# Step 3: Setup Terraform Backend
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 3: Setup Terraform Backend${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "Setup Terraform backend? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/setup-terraform-backend.sh"
fi

echo ""
echo -e "${GREEN}✅ Terraform backend configured${NC}"
echo ""

# Step 4: Setup OIDC
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 4: Configure Workload Identity Federation (OIDC)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "Setup OIDC for staging? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/setup-gcp-oidc.sh" $STAGING_PROJECT $GITHUB_REPO staging > /tmp/oidc-staging.txt
    cat /tmp/oidc-staging.txt
fi

echo ""
read -p "Setup OIDC for production? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/setup-gcp-oidc.sh" $PRODUCTION_PROJECT $GITHUB_REPO production > /tmp/oidc-production.txt
    cat /tmp/oidc-production.txt
fi

echo ""
echo -e "${GREEN}✅ OIDC configured${NC}"
echo ""

# Step 5: Setup Budgets
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 5: Setup Budgets and Billing Alerts${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "Setup budgets? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/setup-budgets.sh"
fi

echo ""
echo -e "${GREEN}✅ Budgets configured${NC}"
echo ""

# Generate final summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  🎉 GCP Setup Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Add GitHub Secrets (see OIDC output above)"
echo "   URL: https://github.com/$GITHUB_REPO/settings/secrets/actions"
echo ""
echo "2. Create a repository variable GCP_CONFIGURED=true"
echo "   URL: https://github.com/$GITHUB_REPO/settings/variables/actions"
echo ""
echo "3. Initialize Terraform:"
echo "   cd infra/environments/staging"
echo "   terraform init"
echo ""
echo "4. Test the setup:"
echo "   Push this branch to trigger CI/CD"
echo ""
echo "📄 OIDC output files:"
echo "   - Staging: /tmp/oidc-staging.txt"
echo "   - Production: /tmp/oidc-production.txt"
echo ""
