#!/bin/bash

# OAuth Secrets Setup Script for GCP Secret Manager
# This script creates OAuth secrets in GCP Secret Manager for staging and production

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 OAuth Secrets Setup for GCP Secret Manager${NC}"
echo "=================================================="

# Function to create secret
create_secret() {
    local secret_name=$1
    local secret_description=$2
    local project_id=$3
    
    echo -e "${YELLOW}📝 Creating secret: ${secret_name}${NC}"
    
    # Check if secret already exists
    if gcloud secrets describe "${secret_name}" --project="${project_id}" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Secret ${secret_name} already exists. Skipping...${NC}"
        return 0
    fi
    
    # Create secret with placeholder value
    echo "PLACEHOLDER_VALUE" | gcloud secrets create "${secret_name}" \
        --data-file=- \
        --project="${project_id}" \
        --labels="environment=staging,type=oauth,managed-by=script" \
        --replication-policy="automatic"
    
    echo -e "${GREEN}✅ Secret ${secret_name} created successfully${NC}"
}

# Function to update secret value
update_secret() {
    local secret_name=$1
    local secret_value=$2
    local project_id=$3
    
    echo -e "${YELLOW}🔄 Updating secret: ${secret_name}${NC}"
    
    echo "${secret_value}" | gcloud secrets versions add "${secret_name}" \
        --data-file=- \
        --project="${project_id}"
    
    echo -e "${GREEN}✅ Secret ${secret_name} updated successfully${NC}"
}

# Main function
main() {
    local environment=${1:-staging}
    local project_id=""
    
    # Set project ID based on environment
    case $environment in
        staging)
            project_id="adyela-staging"
            ;;
        production)
            project_id="adyela-production"
            ;;
        *)
            echo -e "${RED}❌ Invalid environment. Use 'staging' or 'production'${NC}"
            echo "Usage: $0 [staging|production]"
            exit 1
            ;;
    esac
    
    echo -e "${BLUE}🎯 Setting up OAuth secrets for ${environment} environment${NC}"
    echo -e "${BLUE}📋 Project ID: ${project_id}${NC}"
    echo ""
    
    # Verify we're authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        echo -e "${RED}❌ Not authenticated with gcloud. Please run 'gcloud auth login'${NC}"
        exit 1
    fi
    
    # Verify project access
    if ! gcloud projects describe "${project_id}" >/dev/null 2>&1; then
        echo -e "${RED}❌ Cannot access project ${project_id}. Please check permissions.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Authentication and project access verified${NC}"
    echo ""
    
    # Create OAuth secrets
    echo -e "${BLUE}📦 Creating OAuth secrets...${NC}"
    
    # Google OAuth
    create_secret "oauth-google-client-id" "Google OAuth Client ID" "${project_id}"
    create_secret "oauth-google-client-secret" "Google OAuth Client Secret" "${project_id}"
    
    # Facebook OAuth
    create_secret "oauth-facebook-app-id" "Facebook OAuth App ID" "${project_id}"
    create_secret "oauth-facebook-app-secret" "Facebook OAuth App Secret" "${project_id}"
    
    # Apple OAuth
    create_secret "oauth-apple-client-id" "Apple OAuth Service ID" "${project_id}"
    create_secret "oauth-apple-client-secret" "Apple OAuth Private Key" "${project_id}"
    
    # Microsoft OAuth
    create_secret "oauth-microsoft-client-id" "Microsoft OAuth Client ID" "${project_id}"
    create_secret "oauth-microsoft-client-secret" "Microsoft OAuth Client Secret" "${project_id}"
    
    echo ""
    echo -e "${GREEN}🎉 OAuth secrets created successfully!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "1. Update each secret with actual OAuth credentials:"
    echo "   gcloud secrets versions add oauth-google-client-id --data-file=- <<< 'your-google-client-id'"
    echo "   gcloud secrets versions add oauth-google-client-secret --data-file=- <<< 'your-google-client-secret'"
    echo "   # ... repeat for all secrets"
    echo ""
    echo "2. Configure OAuth providers in Firebase Console:"
    echo "   - Go to Firebase Console > Authentication > Sign-in method"
    echo "   - Enable each provider with the credentials from step 1"
    echo ""
    echo "3. Update authorized domains in Firebase:"
    echo "   - Add ${environment}.adyela.care to authorized domains"
    echo ""
    echo "4. Test OAuth login in staging environment"
    echo ""
    echo -e "${BLUE}📚 For detailed instructions, see: docs/guides/OAUTH_SETUP.md${NC}"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "OAuth Secrets Setup Script"
    echo ""
    echo "Usage: $0 [staging|production]"
    echo ""
    echo "This script creates OAuth secrets in GCP Secret Manager for the specified environment."
    echo ""
    echo "Examples:"
    echo "  $0 staging     # Create secrets for staging environment"
    echo "  $0 production  # Create secrets for production environment"
    echo ""
    echo "Prerequisites:"
    echo "  - gcloud CLI installed and authenticated"
    echo "  - Access to the target GCP project"
    echo "  - Secret Manager API enabled"
    exit 0
fi

# Run main function
main "$@"
