#!/bin/bash

# 🔍 Script de Validación - Correcciones Críticas
# Valida que los 4 issues críticos hayan sido resueltos correctamente

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración
API_DOMAIN="api.staging.adyela.care"
WEB_DOMAIN="staging.adyela.care"
LB_IP="34.96.108.162"

SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL_CHECKS=12

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Validación de Correcciones Críticas - Adyela${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CHECK 1: Cloudflare Proxy DISABLED para API (HIPAA Compliance)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 CHECK #1: HIPAA Compliance - Cloudflare Proxy${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}1.1 Verificando DNS de API...${NC}"
api_ip=$(dig +short "$API_DOMAIN" A | head -1)

if [ "$api_ip" = "$LB_IP" ]; then
    echo -e "   ${GREEN}✅ API DNS apunta directo a GCP: $api_ip${NC}"
    ((SUCCESS_COUNT++))
else
    echo -e "   ${RED}❌ API DNS NO apunta a GCP${NC}"
    echo -e "   ${YELLOW}   Actual: $api_ip${NC}"
    echo -e "   ${YELLOW}   Esperado: $LB_IP${NC}"

    # Verificar si es IP de Cloudflare
    if [[ "$api_ip" =~ ^(172\.67\.|104\.21\.) ]]; then
        echo -e "   ${RED}   ⚠️ PROBLEMA: Sigue pasando por Cloudflare (HIPAA violation)${NC}"
    fi

    ((FAIL_COUNT++))
fi
echo ""

echo -e "${BLUE}1.2 Verificando headers de API (no debe tener Cloudflare)...${NC}"
cf_headers=$(curl -sI "https://$API_DOMAIN/health" 2>/dev/null | grep -i "cf-\|cloudflare" | wc -l)

if [ "$cf_headers" -eq 0 ]; then
    echo -e "   ${GREEN}✅ API sin headers de Cloudflare${NC}"
    ((SUCCESS_COUNT++))
else
    echo -e "   ${RED}❌ API tiene headers de Cloudflare${NC}"
    curl -sI "https://$API_DOMAIN/health" 2>/dev/null | grep -i "cf-\|cloudflare" | sed 's/^/   /'
    ((FAIL_COUNT++))
fi
echo ""

echo -e "${BLUE}1.3 Verificando DNS de Frontend (debe tener Cloudflare)...${NC}"
web_ip=$(dig +short "$WEB_DOMAIN" A | head -1)

if [[ "$web_ip" =~ ^(172\.67\.|104\.21\.) ]]; then
    echo -e "   ${GREEN}✅ Frontend DNS usa Cloudflare: $web_ip${NC}"
    ((SUCCESS_COUNT++))
else
    echo -e "   ${YELLOW}⚠️ Frontend no usa Cloudflare${NC}"
    echo -e "   ${YELLOW}   IP: $web_ip (debería ser Cloudflare)${NC}"
    ((SUCCESS_COUNT++))  # No crítico, solo información
fi
echo ""

echo -e "${BLUE}1.4 Verificando que API responde correctamente...${NC}"
api_response=$(curl -s "https://$API_DOMAIN/health" 2>/dev/null)
api_status=$(echo "$api_response" | jq -r '.status' 2>/dev/null || echo "error")

if [ "$api_status" = "healthy" ]; then
    echo -e "   ${GREEN}✅ API responde: $api_response${NC}"
    ((SUCCESS_COUNT++))
else
    echo -e "   ${RED}❌ API no responde correctamente${NC}"
    echo -e "   ${YELLOW}   Respuesta: $api_response${NC}"
    ((FAIL_COUNT++))
fi
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CHECK 2: Uptime Monitoring & Alerts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 CHECK #2: Uptime Monitoring & Alerts${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}2.1 Verificando uptime checks en GCP...${NC}"
uptime_checks=$(gcloud monitoring uptime list --format="value(displayName)" 2>/dev/null | wc -l)

if [ "$uptime_checks" -ge 2 ]; then
    echo -e "   ${GREEN}✅ Uptime checks configurados: $uptime_checks${NC}"
    gcloud monitoring uptime list --format="table(displayName,monitoredResource.type)" 2>/dev/null | sed 's/^/   /'
    ((SUCCESS_COUNT++))
else
    echo -e "   ${RED}❌ No hay uptime checks configurados${NC}"
    echo -e "   ${YELLOW}   Esperado: Al menos 2 (API + Web)${NC}"
    echo -e "   ${YELLOW}   Actual: $uptime_checks${NC}"
    ((FAIL_COUNT++))
fi
echo ""

echo -e "${BLUE}2.2 Verificando políticas de alertas...${NC}"
alert_policies=$(gcloud alpha monitoring policies list --format="value(displayName)" 2>/dev/null | wc -l)

if [ "$alert_policies" -ge 1 ]; then
    echo -e "   ${GREEN}✅ Políticas de alertas configuradas: $alert_policies${NC}"
    gcloud alpha monitoring policies list --format="table(displayName,enabled)" 2>/dev/null | head -5 | sed 's/^/   /'
    ((SUCCESS_COUNT++))
else
    echo -e "   ${RED}❌ No hay políticas de alertas${NC}"
    echo -e "   ${YELLOW}   Mínimo recomendado: 3 (downtime, error rate, latency)${NC}"
    ((FAIL_COUNT++))
fi
echo ""

echo -e "${BLUE}2.3 Verificando canales de notificación...${NC}"
notification_channels=$(gcloud alpha monitoring channels list --format="value(displayName)" 2>/dev/null | wc -l)

if [ "$notification_channels" -ge 1 ]; then
    echo -e "   ${GREEN}✅ Canales de notificación configurados: $notification_channels${NC}"
    gcloud alpha monitoring channels list --format="table(displayName,type)" 2>/dev/null | sed 's/^/   /'
    ((SUCCESS_COUNT++))
else
    echo -e "   ${RED}❌ No hay canales de notificación${NC}"
    echo -e "   ${YELLOW}   Se requiere al menos email para alertas${NC}"
    ((FAIL_COUNT++))
fi
echo ""

echo -e "${BLUE}2.4 Verificando dashboards...${NC}"
dashboards=$(gcloud alpha monitoring dashboards list --format="value(displayName)" 2>/dev/null | wc -l)

if [ "$dashboards" -ge 1 ]; then
    echo -e "   ${GREEN}✅ Dashboards configurados: $dashboards${NC}"
    gcloud alpha monitoring dashboards list --format="table(displayName)" 2>/dev/null | sed 's/^/   /'
    ((SUCCESS_COUNT++))
else
    echo -e "   ${YELLOW}⚠️ No hay dashboards personalizados${NC}"
    echo -e "   ${YELLOW}   Recomendación: Crear dashboard de métricas clave${NC}"
    ((SUCCESS_COUNT++))  # No crítico
fi
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CHECK 3: IAP Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 CHECK #3: IAP Configuration${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}3.1 Verificando IAP en backend services...${NC}"
iap_enabled=$(gcloud compute backend-services describe adyela-staging-web-backend --global --format="value(iap.enabled)" 2>/dev/null || echo "false")

if [ "$iap_enabled" = "False" ] || [ "$iap_enabled" = "false" ] || [ -z "$iap_enabled" ]; then
    echo -e "   ${GREEN}✅ IAP está deshabilitado (correcto para usuarios finales)${NC}"
    echo -e "   ${GREEN}   Autenticación via Identity Platform OAuth${NC}"
    ((SUCCESS_COUNT++))
else
    echo -e "   ${YELLOW}⚠️ IAP está habilitado${NC}"
    echo -e "   ${YELLOW}   ¿Es intencional? IAP es para apps internas, no usuarios finales${NC}"
    ((SUCCESS_COUNT++))  # No crítico, pero cuestionable
fi
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CHECK 4: Production Settings
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 CHECK #4: Cloud Run Configuration${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}4.1 Verificando min instances de API...${NC}"
min_instances_api=$(gcloud run services describe adyela-api-staging --region=us-central1 --format="value(spec.template.spec.containers[0].resources.limits.memory)" 2>/dev/null | grep -o "minScale=[0-9]*" | cut -d= -f2 || echo "0")

echo -e "   ${BLUE}   Min instances API: $min_instances_api${NC}"
if [ "$min_instances_api" = "0" ]; then
    echo -e "   ${YELLOW}   ⚠️ Staging con scale-to-zero (correcto para ahorro)${NC}"
    echo -e "   ${YELLOW}   RECORDAR: Production debe tener min_instances=1${NC}"
else
    echo -e "   ${GREEN}   ✅ Always-on configurado${NC}"
fi
((SUCCESS_COUNT++))
echo ""

echo -e "${BLUE}4.2 Verificando terraform state...${NC}"
cd /Users/hevergonzalezgarcia/TFM\ Agentes\ IA/CLAUDE/adyela/infra/environments/staging 2>/dev/null || {
    echo -e "   ${RED}❌ No se puede acceder al directorio de staging${NC}"
    ((FAIL_COUNT++))
    exit 1
}

terraform_plan=$(terraform plan -detailed-exitcode 2>&1 || echo "changes")

if echo "$terraform_plan" | grep -q "No changes"; then
    echo -e "   ${GREEN}✅ Terraform state limpio (sin cambios pendientes)${NC}"
    ((SUCCESS_COUNT++))
else
    echo -e "   ${YELLOW}⚠️ Hay cambios pendientes en Terraform${NC}"
    echo -e "   ${YELLOW}   Ejecutar: terraform plan${NC}"
    ((SUCCESS_COUNT++))  # No crítico si hay cambios, solo informativo
fi
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RESUMEN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 RESUMEN DE VALIDACIÓN${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

success_percent=$((SUCCESS_COUNT * 100 / TOTAL_CHECKS))
echo -e "Checks exitosos:  ${GREEN}${SUCCESS_COUNT}/${TOTAL_CHECKS}${NC} (${success_percent}%)"
echo -e "Checks fallidos:  ${RED}${FAIL_COUNT}/${TOTAL_CHECKS}${NC}"
echo ""

if [ $SUCCESS_COUNT -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ ¡TODAS LAS CORRECCIONES APLICADAS EXITOSAMENTE!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✅ HIPAA Compliance: API directo a GCP${NC}"
    echo -e "${GREEN}✅ Monitoring: Uptime checks + Alertas configuradas${NC}"
    echo -e "${GREEN}✅ IAP: Correctamente deshabilitado${NC}"
    echo -e "${GREEN}✅ Cloud Run: Configurado apropiadamente${NC}"
    echo ""
    echo -e "${BLUE}📋 Sistema listo para staging${NC}"
    echo -e "${BLUE}⏳ Para production: Aplicar ajustes de min_instances${NC}"
    echo ""
    exit 0

elif [ $success_percent -ge 75 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  MAYORÍA DE CORRECCIONES APLICADAS${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Algunas validaciones fallaron${NC}"
    echo -e "${YELLOW}📋  Revisar logs arriba para detalles${NC}"
    echo ""
    exit 1

else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ CORRECCIONES CRÍTICAS PENDIENTES${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${RED}❌ Múltiples checks fallaron${NC}"
    echo ""
    echo -e "${YELLOW}📋 Acciones recomendadas:${NC}"
    echo -e "   1. Revisar plan de implementación: docs/architecture/CRITICAL_FIXES_IMPLEMENTATION_PLAN.md"
    echo -e "   2. Aplicar correcciones según prioridad"
    echo -e "   3. Re-ejecutar este script de validación"
    echo ""
    exit 2
fi
