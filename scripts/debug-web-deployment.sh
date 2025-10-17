#!/bin/bash

# Script para diagnosticar problemas de despliegue web
# Uso: ./scripts/debug-web-deployment.sh

set -e

echo "=================================================="
echo "🔍 DIAGNÓSTICO DE DESPLIEGUE WEB"
echo "=================================================="
echo ""

# Variables
PROJECT_ID="adyela-staging"
REGION="us-central1"
SERVICE_NAME="adyela-web-staging"
WEB_URL="https://staging.adyela.care"

echo "📋 Configuración:"
echo "   Project: ${PROJECT_ID}"
echo "   Region: ${REGION}"
echo "   Service: ${SERVICE_NAME}"
echo "   Web URL: ${WEB_URL}"
echo ""

# 1. Verificar estado del servicio
echo "1️⃣ Verificando estado del servicio Cloud Run..."
gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${PROJECT_ID} \
  --format="table(metadata.name,status.conditions[0].status,spec.template.metadata.name)" \
  2>/dev/null || echo "   ❌ Servicio no encontrado"
echo ""

# 2. Verificar última revisión
echo "2️⃣ Verificando última revisión..."
LATEST_REVISION=$(gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${PROJECT_ID} \
  --format="value(status.latestReadyRevisionName)" 2>/dev/null || echo "N/A")
echo "   Última revisión: ${LATEST_REVISION}"
echo ""

# 3. Verificar logs recientes
echo "3️⃣ Verificando logs recientes..."
echo "   Últimos 10 logs:"
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=${SERVICE_NAME}" \
  --limit=10 \
  --format="table(timestamp,severity,textPayload)" \
  --project=${PROJECT_ID} 2>/dev/null || echo "   ❌ No se pudieron obtener logs"
echo ""

# 4. Verificar errores en logs
echo "4️⃣ Verificando errores en logs..."
echo "   Errores recientes:"
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=${SERVICE_NAME} AND severity>=ERROR" \
  --limit=5 \
  --format="table(timestamp,severity,textPayload)" \
  --project=${PROJECT_ID} 2>/dev/null || echo "   ✅ No se encontraron errores"
echo ""

# 5. Verificar imagen desplegada
echo "5️⃣ Verificando imagen desplegada..."
IMAGE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${PROJECT_ID} \
  --format="value(spec.template.spec.containers[0].image)" 2>/dev/null || echo "N/A")
echo "   Imagen: ${IMAGE_URL}"
echo ""

# 6. Verificar contenido de la imagen
if [ "${IMAGE_URL}" != "N/A" ]; then
  echo "6️⃣ Verificando contenido de la imagen..."
  echo "   Archivos en /usr/share/nginx/html/:"
  docker run --rm --entrypoint ls ${IMAGE_URL} -la /usr/share/nginx/html/ | head -10
  echo ""
  
  echo "   Verificando index.html:"
  docker run --rm --entrypoint cat ${IMAGE_URL} /usr/share/nginx/html/index.html | head -5
  echo ""
  
  echo "   Verificando assets:"
  docker run --rm --entrypoint ls ${IMAGE_URL} -la /usr/share/nginx/html/assets/ | head -5
  echo ""
fi

# 7. Verificar respuesta HTTP
echo "7️⃣ Verificando respuesta HTTP..."
echo "   GET ${WEB_URL}/"
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' ${WEB_URL}/ || echo "FAILED")
echo "   Código HTTP: ${HTTP_CODE}"
echo ""

if [ "${HTTP_CODE}" == "200" ]; then
  echo "   ✅ El sitio responde correctamente"
  
  # Verificar headers de cache
  echo "   Verificando headers de cache:"
  curl -s -I ${WEB_URL}/ | grep -i "cache\|etag\|last-modified" || echo "   No se encontraron headers de cache"
  echo ""
else
  echo "   ❌ El sitio no responde correctamente"
fi

# 8. Verificar CDN
echo "8️⃣ Verificando configuración de CDN..."
echo "   URL Maps:"
gcloud compute url-maps list --project=${PROJECT_ID} --filter="name~adyela-staging" --format="table(name,defaultService)" 2>/dev/null || echo "   ❌ No se encontraron URL maps"
echo ""

# 9. Verificar Load Balancer
echo "9️⃣ Verificando Load Balancer..."
echo "   Backend Services:"
gcloud compute backend-services list --project=${PROJECT_ID} --filter="name~adyela-staging" --format="table(name,backends[].group)" 2>/dev/null || echo "   ❌ No se encontraron backend services"
echo ""

# 10. Recomendaciones
echo "🔟 Recomendaciones:"
echo ""

if [ "${HTTP_CODE}" != "200" ]; then
  echo "   ❌ PROBLEMA: El sitio no responde"
  echo "   💡 Soluciones:"
  echo "      1. Verificar que el servicio Cloud Run esté funcionando"
  echo "      2. Verificar logs de Cloud Run para errores"
  echo "      3. Verificar configuración de Load Balancer"
  echo "      4. Ejecutar el workflow con 'force_rebuild: true'"
  echo ""
fi

if [ "${LATEST_REVISION}" == "N/A" ]; then
  echo "   ❌ PROBLEMA: No se puede obtener la revisión"
  echo "   💡 Soluciones:"
  echo "      1. Verificar permisos de GCP"
  echo "      2. Verificar que el proyecto sea correcto"
  echo "      3. Verificar que el servicio exista"
  echo ""
fi

echo "   💡 Comandos útiles para debugging:"
echo "      # Ver logs en tiempo real:"
echo "      gcloud logging tail \"resource.type=cloud_run_revision AND resource.labels.service_name=${SERVICE_NAME}\" --project=${PROJECT_ID}"
echo ""
echo "      # Forzar nueva revisión:"
echo "      gcloud run services update ${SERVICE_NAME} --region ${REGION} --project ${PROJECT_ID} --no-traffic"
echo ""
echo "      # Invalidar cache CDN manualmente:"
echo "      gcloud compute url-maps invalidate-cdn-cache adyela-staging-web-url-map --path=\"/*\" --project=${PROJECT_ID}"
echo ""

echo "=================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=================================================="
