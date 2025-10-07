#!/bin/bash
set -e

echo "🔐 GCP Secret Manager Setup - Manual Steps"
echo "=========================================="
echo ""
echo "Ejecuta estos comandos en tu terminal:"
echo ""

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Paso 1: Autenticarse en gcloud${NC}"
echo "gcloud auth login"
echo "gcloud auth application-default login"
echo ""

echo -e "${YELLOW}Paso 2: Configurar proyecto${NC}"
echo "gcloud config set project adyela-staging"
echo ""

echo -e "${YELLOW}Paso 3: Habilitar Secret Manager API${NC}"
echo "gcloud services enable secretmanager.googleapis.com"
echo ""

echo -e "${YELLOW}Paso 4: Crear secreto api-secret-key${NC}"
echo "echo -n '1786c41493658800373afd6c3dbdd6a4d791fb2b1567acab119d0980fed9a0b1' | \\"
echo "gcloud secrets create api-secret-key \\"
echo "  --data-file=- \\"
echo "  --replication-policy=automatic \\"
echo "  --labels=environment=staging,app=adyela-api"
echo ""

echo -e "${YELLOW}Paso 5: Crear secreto firebase-project-id${NC}"
echo "echo -n 'adyela-staging' | \\"
echo "gcloud secrets create firebase-project-id \\"
echo "  --data-file=- \\"
echo "  --replication-policy=automatic \\"
echo "  --labels=environment=staging,app=adyela-api"
echo ""

echo -e "${YELLOW}Paso 6: Dar permisos al Service Account${NC}"
echo "SERVICE_ACCOUNT=\$(gh secret get SERVICE_ACCOUNT_STAGING --app actions)"
echo "gcloud projects add-iam-policy-binding adyela-staging \\"
echo "  --member=\"serviceAccount:\$SERVICE_ACCOUNT\" \\"
echo "  --role=roles/secretmanager.secretAccessor"
echo ""

echo -e "${YELLOW}Paso 7: Verificar secretos${NC}"
echo "gcloud secrets list --project=adyela-staging"
echo ""

echo -e "${GREEN}Después de completar estos pasos, ejecuta:${NC}"
echo "gh workflow run cd-staging.yml --ref main -f version=v1.0.0 -f skip_e2e=true"
echo ""
