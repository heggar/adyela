#!/bin/bash
set -e

PROJECT_ID="adyela-staging"
REGION="us-central1"
REPOSITORY_NAME="adyela"

echo "🐳 Creando Artifact Registry Repository"
echo "========================================"
echo ""
echo "Proyecto: $PROJECT_ID"
echo "Región: $REGION"
echo "Repositorio: $REPOSITORY_NAME"
echo ""

# Autenticarse (si es necesario)
echo "1️⃣ Verificando autenticación..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "Autenticando..."
    gcloud auth login
fi

# Configurar proyecto
echo ""
echo "2️⃣ Configurando proyecto..."
gcloud config set project $PROJECT_ID

# Habilitar Artifact Registry API
echo ""
echo "3️⃣ Habilitando Artifact Registry API..."
gcloud services enable artifactregistry.googleapis.com

# Crear repositorio
echo ""
echo "4️⃣ Creando repositorio Docker..."
gcloud artifacts repositories create $REPOSITORY_NAME \
    --repository-format=docker \
    --location=$REGION \
    --description="Adyela Docker images repository" \
    --labels=environment=staging,app=adyela

echo ""
echo "5️⃣ Verificando repositorio..."
gcloud artifacts repositories describe $REPOSITORY_NAME \
    --location=$REGION

echo ""
echo "✅ ¡Repositorio creado exitosamente!"
echo ""
echo "URL del repositorio:"
echo "$REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY_NAME"
echo ""
echo "Ahora puedes ejecutar el workflow de nuevo:"
echo "gh workflow run cd-staging.yml --ref feat/api-backend -f version=v1.0.0 -f skip_e2e=true"
echo ""
