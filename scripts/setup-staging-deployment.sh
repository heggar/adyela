#!/bin/bash
set -e

echo "🚀 Adyela Staging Deployment Setup"
echo "===================================="
echo ""
echo "Este script te guiará en la configuración completa de los secretos"
echo "necesarios para desplegar a staging."
echo ""
echo "Se configurarán:"
echo "  1. ✅ Secretos de GitHub (Firebase config, API URL)"
echo "  2. ✅ Secretos de GCP Secret Manager (API keys, Firebase Project ID)"
echo ""
echo "Prerrequisitos:"
echo "  - Tener acceso a Firebase Console"
echo "  - Estar autenticado en gcloud (gcloud auth login)"
echo "  - Tener gh CLI configurado"
echo ""
read -p "¿Continuar? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelado."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASO 1: Configurar secretos de GCP Secret Manager"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! ./scripts/setup-gcp-secrets.sh; then
    echo "❌ Error configurando secretos de GCP."
    echo "Por favor verifica que estás autenticado: gcloud auth login"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASO 2: Configurar secretos de GitHub (Firebase)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! ./scripts/setup-firebase-secrets.sh; then
    echo "❌ Error configurando secretos de GitHub."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CONFIGURACIÓN COMPLETA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Ahora puedes desplegar a staging ejecutando:"
echo ""
echo "  gh workflow run cd-staging.yml \\"
echo "    --ref main \\"
echo "    -f version=v1.0.0 \\"
echo "    -f skip_e2e=true"
echo ""
echo "Para monitorear el deployment:"
echo "  gh run watch"
echo ""
echo "O ver logs en: https://github.com/heggar/adyela/actions"
echo ""
