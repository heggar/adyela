#!/bin/bash

# Setup Firebase Web Configuration Secrets in GCP Secret Manager
# These values are obtained from Firebase Console > Project Settings > General > Your apps

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ID="${GCP_PROJECT_ID:-adyela-staging}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Firebase Web Configuration Secrets Setup${NC}"
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
            --update-labels="managed-by=manual,component=firebase" &>/dev/null
    fi

    echo -e "  ${GREEN}✓${NC} Done!"
}

# Instructions
echo -e "${YELLOW}📋 How to get these values:${NC}"
echo ""
echo -e "1. Go to Firebase Console:"
echo -e "   ${YELLOW}https://console.firebase.google.com/project/${PROJECT_ID}/settings/general${NC}"
echo ""
echo -e "2. Scroll to 'Your apps' section"
echo ""
echo -e "3. If you don't have a Web app, click 'Add app' > Web"
echo ""
echo -e "4. Copy the config values from the Firebase SDK snippet"
echo ""
echo -e "${YELLOW}⚠️  You will be prompted to enter these values:${NC}"
echo -e "   - Firebase API Key (apiKey)"
echo -e "   - Messaging Sender ID (messagingSenderId)"
echo -e "   - App ID (appId)"
echo ""
read -p "Press Enter when you're ready to continue..."
echo ""

# Prompt for API Key
echo -e "${YELLOW}Enter Firebase API Key:${NC}"
read -r FIREBASE_API_KEY
if [ -z "$FIREBASE_API_KEY" ]; then
    echo -e "${RED}Error: API Key cannot be empty${NC}"
    exit 1
fi

# Prompt for Messaging Sender ID
echo -e "${YELLOW}Enter Firebase Messaging Sender ID:${NC}"
read -r FIREBASE_MESSAGING_SENDER_ID
if [ -z "$FIREBASE_MESSAGING_SENDER_ID" ]; then
    echo -e "${RED}Error: Messaging Sender ID cannot be empty${NC}"
    exit 1
fi

# Prompt for App ID
echo -e "${YELLOW}Enter Firebase App ID:${NC}"
read -r FIREBASE_APP_ID
if [ -z "$FIREBASE_APP_ID" ]; then
    echo -e "${RED}Error: App ID cannot be empty${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Creating secrets...${NC}"
echo ""

# Create Firebase Web secrets
create_or_update_secret \
    "firebase-web-api-key" \
    "$FIREBASE_API_KEY" \
    "Firebase Web API Key"

create_or_update_secret \
    "firebase-messaging-sender-id" \
    "$FIREBASE_MESSAGING_SENDER_ID" \
    "Firebase Messaging Sender ID"

create_or_update_secret \
    "firebase-web-app-id" \
    "$FIREBASE_APP_ID" \
    "Firebase Web App ID"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Firebase Web secrets created!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo -e "1. Verify secrets:"
echo -e "   ${YELLOW}gcloud secrets list --project=${PROJECT_ID} --filter='name~firebase-web'${NC}"
echo ""
echo -e "2. Deploy or update Cloud Run services with Terraform"
echo ""
