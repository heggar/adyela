#!/bin/bash
# Deploy all microservices to staging/production
# Usage: ./scripts/deploy-all.sh [environment]

set -e

ENVIRONMENT=${1:-staging}
PROJECT_ID="adyela-${ENVIRONMENT}"
REGION="us-central1"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Deploying all microservices to ${ENVIRONMENT}${NC}"
echo ""

# Services to deploy
SERVICES=(
    "api-auth"
    "api-appointments"
    "api-payments"
    "api-notifications"
    "api-admin"
    "api-analytics"
)

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &>/dev/null; then
    echo -e "${RED}❌ Not authenticated with gcloud${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Set project
echo -e "${YELLOW}Setting project to ${PROJECT_ID}${NC}"
gcloud config set project "${PROJECT_ID}"

# Deploy infrastructure first
echo ""
echo -e "${BLUE}📦 Deploying infrastructure with Terraform${NC}"
cd infra/environments/${ENVIRONMENT}

if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}⚠️  terraform.tfvars not found, creating from example${NC}"
    cat > terraform.tfvars <<EOF
project_id = "${PROJECT_ID}"
region = "${REGION}"
billing_account = "YOUR_BILLING_ACCOUNT_ID"  # UPDATE THIS!
budget_alert_emails = ["dev@adyela.care"]
EOF
    echo -e "${YELLOW}⚠️  Please edit terraform.tfvars and add your billing_account${NC}"
    exit 1
fi

echo "Initializing Terraform..."
terraform init

echo "Planning infrastructure changes..."
terraform plan -out=tfplan

echo -e "${YELLOW}Review the plan above${NC}"
read -p "Apply these changes? (yes/no) " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Aborted."
    exit 1
fi

terraform apply tfplan

cd ../../..

# Build and deploy each service
for service in "${SERVICES[@]}"; do
    echo ""
    echo -e "${BLUE}🔨 Building and deploying ${service}${NC}"

    # Determine port based on service
    if [[ "$service" == api-payments || "$service" == api-notifications ]]; then
        PORT=3000
    else
        PORT=8000
    fi

    # Build Docker image
    echo "  Building Docker image..."
    docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/adyela/${service}:latest \
        --build-arg PORT=${PORT} \
        apps/${service}/

    # Push to Artifact Registry
    echo "  Pushing to Artifact Registry..."
    docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/adyela/${service}:latest

    # Deploy to Cloud Run
    echo "  Deploying to Cloud Run..."
    gcloud run deploy ${service}-${ENVIRONMENT} \
        --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/adyela/${service}:latest \
        --region=${REGION} \
        --platform=managed \
        --allow-unauthenticated \
        --max-instances=10 \
        --min-instances=0 \
        --cpu=1 \
        --memory=512Mi \
        --timeout=60 \
        --set-env-vars="ENVIRONMENT=${ENVIRONMENT},PROJECT_ID=${PROJECT_ID},REGION=${REGION}" \
        --labels="environment=${ENVIRONMENT},service=${service}"

    # Get service URL
    SERVICE_URL=$(gcloud run services describe ${service}-${ENVIRONMENT} \
        --region=${REGION} \
        --format='value(status.url)')

    echo -e "${GREEN}  ✓ ${service} deployed: ${SERVICE_URL}${NC}"
done

echo ""
echo -e "${GREEN}✅ All services deployed successfully!${NC}"
echo ""
echo "Service URLs:"
for service in "${SERVICES[@]}"; do
    URL=$(gcloud run services describe ${service}-${ENVIRONMENT} \
        --region=${REGION} \
        --format='value(status.url)')
    echo "  ${service}: ${URL}"
done
echo ""
