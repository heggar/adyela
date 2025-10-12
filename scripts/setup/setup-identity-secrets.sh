#!/bin/bash

# Setup Identity Platform OAuth Secrets in GCP Secret Manager
# This script creates placeholders for OAuth credentials that need to be configured

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ID="${GCP_PROJECT_ID:-adyela-staging}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Identity Platform OAuth Secrets Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Project: ${YELLOW}${PROJECT_ID}${NC}"
echo ""

# Function to create or update secret
create_or_update_secret() {
    local secret_name=$1
    local secret_value=$2
    local description=$3

    echo -e "${YELLOW}→${NC} Checking secret: ${secret_name}"

    # Check if secret exists
    if gcloud secrets describe "${secret_name}" --project="${PROJECT_ID}" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Secret exists, adding new version..."
        echo -n "${secret_value}" | gcloud secrets versions add "${secret_name}" \
            --project="${PROJECT_ID}" \
            --data-file=- &>/dev/null
    else
        echo -e "  ${GREEN}✓${NC} Creating new secret..."
        echo -n "${secret_value}" | gcloud secrets create "${secret_name}" \
            --project="${PROJECT_ID}" \
            --replication-policy="automatic" \
            --data-file=- &>/dev/null

        # Add labels
        gcloud secrets update "${secret_name}" \
            --project="${PROJECT_ID}" \
            --update-labels="managed-by=terraform,component=identity-platform" &>/dev/null
    fi

    echo -e "  ${GREEN}✓${NC} Done!"
}

# Warning message
echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo -e "This script creates placeholder secrets. You MUST update them with real values:"
echo ""
echo -e "1. Get OAuth credentials from provider consoles"
echo -e "2. Update secrets using: ${YELLOW}echo -n 'YOUR_VALUE' | gcloud secrets versions add SECRET_NAME --data-file=-${NC}"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Google OAuth Secrets
echo -e "${GREEN}Creating Google OAuth secrets...${NC}"
create_or_update_secret \
    "oauth-google-client-id" \
    "REPLACE_WITH_GOOGLE_CLIENT_ID" \
    "Google OAuth 2.0 Client ID"

create_or_update_secret \
    "oauth-google-client-secret" \
    "REPLACE_WITH_GOOGLE_CLIENT_SECRET" \
    "Google OAuth 2.0 Client Secret"

# Facebook OAuth Secrets
echo -e "${GREEN}Creating Facebook OAuth secrets...${NC}"
create_or_update_secret \
    "oauth-facebook-app-id" \
    "REPLACE_WITH_FACEBOOK_APP_ID" \
    "Facebook App ID"

create_or_update_secret \
    "oauth-facebook-app-secret" \
    "REPLACE_WITH_FACEBOOK_APP_SECRET" \
    "Facebook App Secret"

# Microsoft OAuth Secrets
echo -e "${GREEN}Creating Microsoft OAuth secrets...${NC}"
create_or_update_secret \
    "oauth-microsoft-client-id" \
    "REPLACE_WITH_MICROSOFT_CLIENT_ID" \
    "Microsoft Azure AD Client ID"

create_or_update_secret \
    "oauth-microsoft-client-secret" \
    "REPLACE_WITH_MICROSOFT_CLIENT_SECRET" \
    "Microsoft Azure AD Client Secret"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Placeholder secrets created!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo -e "1. Configure OAuth providers:"
echo -e "   ${YELLOW}Google:${NC} https://console.cloud.google.com/apis/credentials"
echo -e "   ${YELLOW}Facebook:${NC} https://developers.facebook.com/"
echo -e "   ${YELLOW}Microsoft:${NC} https://portal.azure.com/"
echo ""
echo -e "2. Update secrets with real values:"
echo -e "   ${YELLOW}echo -n 'YOUR_GOOGLE_CLIENT_ID' | gcloud secrets versions add oauth-google-client-id --data-file=-${NC}"
echo ""
echo -e "3. Verify secrets:"
echo -e "   ${YELLOW}gcloud secrets list --project=${PROJECT_ID}${NC}"
echo ""
echo -e "4. Continue with Terraform deployment"
echo ""
