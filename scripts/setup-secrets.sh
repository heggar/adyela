#!/bin/bash
# Script to setup secrets in GCP Secret Manager for Adyela microservices
# Usage: ./scripts/setup-secrets.sh [environment]

set -e

ENVIRONMENT=${1:-staging}
PROJECT_ID="adyela-${ENVIRONMENT}"

echo "🔐 Setting up secrets for ${ENVIRONMENT} environment in project ${PROJECT_ID}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to create secret
create_secret() {
    local secret_name=$1
    local secret_value=$2

    echo -e "${YELLOW}Creating secret: ${secret_name}${NC}"

    # Check if secret already exists
    if gcloud secrets describe "${secret_name}" --project="${PROJECT_ID}" &>/dev/null; then
        echo -e "${YELLOW}  → Secret already exists, adding new version${NC}"
        echo -n "${secret_value}" | gcloud secrets versions add "${secret_name}" \
            --data-file=- \
            --project="${PROJECT_ID}"
    else
        echo -e "${YELLOW}  → Creating new secret${NC}"
        echo -n "${secret_value}" | gcloud secrets create "${secret_name}" \
            --data-file=- \
            --project="${PROJECT_ID}" \
            --replication-policy="automatic"
    fi

    echo -e "${GREEN}  ✓ Secret ${secret_name} created/updated${NC}"
}

# Generate secure random strings
generate_secret() {
    openssl rand -base64 32
}

echo ""
echo "📝 This script will create the following secrets:"
echo "  1. jwt-secret-${ENVIRONMENT}"
echo "  2. firebase-api-key-${ENVIRONMENT}"
echo "  3. admin-secret-${ENVIRONMENT}"
echo "  4. stripe-secret-key-${ENVIRONMENT}"
echo "  5. stripe-webhook-secret-${ENVIRONMENT}"
echo "  6. sendgrid-api-key-${ENVIRONMENT}"
echo "  7. twilio-account-sid-${ENVIRONMENT}"
echo "  8. twilio-auth-token-${ENVIRONMENT}"
echo ""
echo "⚠️  You will be prompted to enter values for each secret"
echo "    (or press Enter to generate a secure random value where applicable)"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# 1. JWT Secret (auto-generate if empty)
echo ""
echo "1️⃣  JWT Secret"
echo "   Used for signing JWT tokens"
read -p "   Enter JWT secret (or press Enter to generate): " jwt_secret
if [ -z "$jwt_secret" ]; then
    jwt_secret=$(generate_secret)
    echo "   Generated: ${jwt_secret:0:20}..."
fi
create_secret "jwt-secret-${ENVIRONMENT}" "$jwt_secret"

# 2. Firebase API Key
echo ""
echo "2️⃣  Firebase API Key"
echo "   Get from Firebase Console → Project Settings → Web API Key"
read -p "   Enter Firebase API key: " firebase_key
if [ -n "$firebase_key" ]; then
    create_secret "firebase-api-key-${ENVIRONMENT}" "$firebase_key"
else
    echo -e "${YELLOW}   Skipping (empty value)${NC}"
fi

# 3. Admin Secret (auto-generate if empty)
echo ""
echo "3️⃣  Admin Secret"
echo "   Used for admin authentication"
read -p "   Enter admin secret (or press Enter to generate): " admin_secret
if [ -z "$admin_secret" ]; then
    admin_secret=$(generate_secret)
    echo "   Generated: ${admin_secret:0:20}..."
fi
create_secret "admin-secret-${ENVIRONMENT}" "$admin_secret"

# 4. Stripe Secret Key
echo ""
echo "4️⃣  Stripe Secret Key"
echo "   Get from Stripe Dashboard → API Keys"
read -p "   Enter Stripe secret key (sk_test_... or sk_live_...): " stripe_key
if [ -n "$stripe_key" ]; then
    create_secret "stripe-secret-key-${ENVIRONMENT}" "$stripe_key"
else
    echo -e "${YELLOW}   Skipping (empty value)${NC}"
fi

# 5. Stripe Webhook Secret
echo ""
echo "5️⃣  Stripe Webhook Secret"
echo "   Get from Stripe Dashboard → Webhooks → Signing secret"
read -p "   Enter Stripe webhook secret (whsec_...): " stripe_webhook
if [ -n "$stripe_webhook" ]; then
    create_secret "stripe-webhook-secret-${ENVIRONMENT}" "$stripe_webhook"
else
    echo -e "${YELLOW}   Skipping (empty value)${NC}"
fi

# 6. SendGrid API Key
echo ""
echo "6️⃣  SendGrid API Key"
echo "   Get from SendGrid → Settings → API Keys"
read -p "   Enter SendGrid API key: " sendgrid_key
if [ -n "$sendgrid_key" ]; then
    create_secret "sendgrid-api-key-${ENVIRONMENT}" "$sendgrid_key"
else
    echo -e "${YELLOW}   Skipping (empty value)${NC}"
fi

# 7. Twilio Account SID
echo ""
echo "7️⃣  Twilio Account SID"
echo "   Get from Twilio Console"
read -p "   Enter Twilio Account SID: " twilio_sid
if [ -n "$twilio_sid" ]; then
    create_secret "twilio-account-sid-${ENVIRONMENT}" "$twilio_sid"
else
    echo -e "${YELLOW}   Skipping (empty value)${NC}"
fi

# 8. Twilio Auth Token
echo ""
echo "8️⃣  Twilio Auth Token"
echo "   Get from Twilio Console"
read -p "   Enter Twilio Auth Token: " twilio_token
if [ -n "$twilio_token" ]; then
    create_secret "twilio-auth-token-${ENVIRONMENT}" "$twilio_token"
else
    echo -e "${YELLOW}   Skipping (empty value)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Secrets setup complete!${NC}"
echo ""
echo "To view secrets:"
echo "  gcloud secrets list --project=${PROJECT_ID}"
echo ""
echo "To access a secret value:"
echo "  gcloud secrets versions access latest --secret=jwt-secret-${ENVIRONMENT} --project=${PROJECT_ID}"
echo ""
