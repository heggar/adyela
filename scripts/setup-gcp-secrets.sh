#!/bin/bash
set -e

PROJECT_ID="adyela-staging"

echo "🔐 GCP Secret Manager Setup for Staging"
echo "========================================"
echo ""
echo "Este script configurará los secretos necesarios en GCP Secret Manager"
echo "para el proyecto: $PROJECT_ID"
echo ""

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ No estás autenticado en gcloud."
    echo "Por favor ejecuta: gcloud auth login"
    exit 1
fi

# Set project
echo "Configurando proyecto: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Enable Secret Manager API if not already enabled
echo "Habilitando Secret Manager API..."
gcloud services enable secretmanager.googleapis.com --quiet

echo ""
echo "Configurando secretos..."
echo ""

# 1. API Secret Key
echo "1️⃣ Generando SECRET_KEY para la API..."
API_SECRET_KEY=$(openssl rand -hex 32)
echo -n "$API_SECRET_KEY" | gcloud secrets create api-secret-key \
    --data-file=- \
    --replication-policy="automatic" \
    --labels="environment=staging,app=adyela-api" 2>/dev/null || \
echo -n "$API_SECRET_KEY" | gcloud secrets versions add api-secret-key --data-file=-

echo "✅ api-secret-key configurado"

# 2. Firebase Project ID
echo ""
echo "2️⃣ Configurando FIREBASE_PROJECT_ID..."
echo -n "$PROJECT_ID" | gcloud secrets create firebase-project-id \
    --data-file=- \
    --replication-policy="automatic" \
    --labels="environment=staging,app=adyela-api" 2>/dev/null || \
echo -n "$PROJECT_ID" | gcloud secrets versions add firebase-project-id --data-file=-

echo "✅ firebase-project-id configurado"

echo ""
echo "✅ Todos los secretos de GCP Secret Manager configurados:"
echo "   - api-secret-key (generado automáticamente)"
echo "   - firebase-project-id ($PROJECT_ID)"
echo ""
echo "Listando secretos..."
gcloud secrets list --filter="labels.environment=staging"

echo ""
echo "📝 Nota: Asegúrate de que el Service Account de Cloud Run tenga permisos:"
echo "gcloud projects add-iam-policy-binding $PROJECT_ID \\"
echo "  --member='serviceAccount:SERVICE_ACCOUNT_EMAIL' \\"
echo "  --role='roles/secretmanager.secretAccessor'"
echo ""
