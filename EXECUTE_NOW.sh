#!/bin/bash
# 🚀 Configuración de GCP Secrets - Ejecutar en Terminal
# ======================================================

echo "🔐 Configurando Secretos de GCP Secret Manager"
echo "=============================================="
echo ""

# Paso 1: Autenticación
echo "📝 Paso 1/6: Autenticación en gcloud"
echo "Ejecutando: gcloud auth login"
gcloud auth login

echo ""
echo "Ejecutando: gcloud auth application-default login"
gcloud auth application-default login

# Paso 2: Configurar proyecto
echo ""
echo "📝 Paso 2/6: Configurando proyecto"
gcloud config set project adyela-staging

# Paso 3: Habilitar API
echo ""
echo "📝 Paso 3/6: Habilitando Secret Manager API"
gcloud services enable secretmanager.googleapis.com

# Paso 4: Crear api-secret-key
echo ""
echo "📝 Paso 4/6: Creando secreto api-secret-key"
echo -n '1786c41493658800373afd6c3dbdd6a4d791fb2b1567acab119d0980fed9a0b1' | \
gcloud secrets create api-secret-key \
  --data-file=- \
  --replication-policy=automatic \
  --labels=environment=staging,app=adyela-api

# Paso 5: Crear firebase-project-id
echo ""
echo "📝 Paso 5/6: Creando secreto firebase-project-id"
echo -n 'adyela-staging' | \
gcloud secrets create firebase-project-id \
  --data-file=- \
  --replication-policy=automatic \
  --labels=environment=staging,app=adyela-api

# Paso 6: Verificar
echo ""
echo "📝 Paso 6/6: Verificando secretos creados"
gcloud secrets list --project=adyela-staging

echo ""
echo "✅ ¡Configuración completa!"
echo ""
echo "Ahora puedes ejecutar el deployment con:"
echo "gh workflow run cd-staging.yml --ref main -f version=v1.0.0 -f skip_e2e=true"
echo ""
