#!/bin/bash

# 🔍 Script de Validación - Fase 1: Corrección DNS
# Verifica que los cambios DNS se hayan aplicado correctamente

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
EXPECTED_IP="34.96.108.162"
FRONTEND_DOMAIN="staging.adyela.care"
API_DOMAIN="api.staging.adyela.care"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Validación Fase 1: Corrección DNS para Adyela Staging${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Contadores de éxito/fallo
SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL_CHECKS=8

# Función para validar DNS
validate_dns() {
    local domain=$1
    local check_name=$2

    echo -e "${BLUE}📍 Verificando DNS: ${domain}${NC}"

    # Obtener IP actual
    actual_ip=$(dig +short "$domain" A | head -1)

    if [ -z "$actual_ip" ]; then
        echo -e "   ${RED}❌ No se pudo resolver el dominio${NC}"
        echo -e "   ${YELLOW}   Posible causa: DNS aún no propagado${NC}"
        return 1
    fi

    if [ "$actual_ip" = "$EXPECTED_IP" ]; then
        echo -e "   ${GREEN}✅ DNS correcto: $actual_ip${NC}"
        ((SUCCESS_COUNT++))
        return 0
    else
        echo -e "   ${RED}❌ DNS incorrecto: $actual_ip${NC}"
        echo -e "   ${YELLOW}   Esperado: $EXPECTED_IP${NC}"

        # Verificar si es IP de Cloudflare
        if [[ "$actual_ip" =~ ^(172\.67\.|104\.21\.) ]]; then
            echo -e "   ${YELLOW}   Detectado: IP de Cloudflare${NC}"
            echo -e "   ${YELLOW}   Acción: Desactivar proxy en Cloudflare (nube gris)${NC}"
        fi

        ((FAIL_COUNT++))
        return 1
    fi
}

# Función para validar endpoint HTTP
validate_http() {
    local url=$1
    local endpoint=$2
    local expected_code=${3:-200}
    local check_name=$4

    echo -e "${BLUE}🌐 Probando: ${url}${endpoint}${NC}"

    # Hacer request y obtener código HTTP
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url$endpoint" 2>/dev/null || echo "000")

    if [ "$http_code" = "$expected_code" ]; then
        echo -e "   ${GREEN}✅ HTTP $http_code - Funcionando correctamente${NC}"
        ((SUCCESS_COUNT++))
        return 0
    else
        echo -e "   ${RED}❌ HTTP $http_code - Error (esperado: $expected_code)${NC}"

        # Diagnosticar error común
        case "$http_code" in
            000)
                echo -e "   ${YELLOW}   Posible causa: Timeout o DNS no resuelve${NC}"
                ;;
            403)
                echo -e "   ${YELLOW}   Posible causa: Cloudflare bloqueando o WAF activo${NC}"
                ;;
            404)
                echo -e "   ${YELLOW}   Posible causa: Ruta no encontrada${NC}"
                ;;
            502|503|504)
                echo -e "   ${YELLOW}   Posible causa: Backend no disponible${NC}"
                ;;
        esac

        ((FAIL_COUNT++))
        return 1
    fi
}

# Función para validar respuesta JSON
validate_json_response() {
    local url=$1
    local expected_field=$2
    local check_name=$3

    echo -e "${BLUE}🔧 Probando API: ${url}${NC}"

    response=$(curl -s --max-time 10 "$url" 2>/dev/null || echo "{}")

    if echo "$response" | jq -e ".$expected_field" > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ API responde correctamente${NC}"
        echo -e "   ${GREEN}   Respuesta: $(echo "$response" | jq -c .)${NC}"
        ((SUCCESS_COUNT++))
        return 0
    else
        echo -e "   ${RED}❌ API no responde correctamente${NC}"
        echo -e "   ${YELLOW}   Respuesta: $response${NC}"
        ((FAIL_COUNT++))
        return 1
    fi
}

# Función para validar SSL
validate_ssl() {
    local domain=$1
    local check_name=$2

    echo -e "${BLUE}🔒 Verificando SSL: ${domain}${NC}"

    ssl_info=$(openssl s_client -connect "${domain}:443" -servername "$domain" < /dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null || echo "")

    if [ -n "$ssl_info" ]; then
        echo -e "   ${GREEN}✅ Certificado SSL válido${NC}"
        echo "$ssl_info" | sed 's/^/   /'
        ((SUCCESS_COUNT++))
        return 0
    else
        echo -e "   ${RED}❌ No se pudo verificar certificado SSL${NC}"
        ((FAIL_COUNT++))
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VALIDACIONES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 FASE 1: VALIDACIÓN DNS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Validar DNS staging
validate_dns "$FRONTEND_DOMAIN" "Frontend DNS"
dns_frontend=$?
echo ""

# 2. Validar DNS api
validate_dns "$API_DOMAIN" "API DNS"
dns_api=$?
echo ""

# Esperar si DNS aún no se propagó
if [ $dns_frontend -ne 0 ] || [ $dns_api -ne 0 ]; then
    echo -e "${YELLOW}⏳ DNS aún no propagado completamente.${NC}"
    echo -e "${YELLOW}   Esperando 30 segundos antes de continuar...${NC}"
    echo ""
    sleep 30
fi

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 FASE 2: VALIDACIÓN HTTP${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# 3. Validar frontend HTTP
validate_http "https://$FRONTEND_DOMAIN" "/" 200 "Frontend HTTP"
echo ""

# 4. Validar API health
validate_http "https://$API_DOMAIN" "/health" 200 "API Health"
echo ""

# 5. Validar API root
validate_http "https://$API_DOMAIN" "/" 200 "API Root"
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 FASE 3: VALIDACIÓN API DETALLADA${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# 6. Validar respuesta JSON del health endpoint
validate_json_response "https://$API_DOMAIN/health" "status" "API Health JSON"
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 FASE 4: VALIDACIÓN SSL${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# 7. Validar SSL frontend
validate_ssl "$FRONTEND_DOMAIN" "Frontend SSL"
echo ""

# 8. Validar SSL API
validate_ssl "$API_DOMAIN" "API SSL"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RESUMEN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 RESUMEN DE VALIDACIÓN${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

success_percent=$((SUCCESS_COUNT * 100 / TOTAL_CHECKS))
echo -e "Validaciones exitosas: ${GREEN}${SUCCESS_COUNT}/${TOTAL_CHECKS}${NC} (${success_percent}%)"
echo -e "Validaciones fallidas:  ${RED}${FAIL_COUNT}/${TOTAL_CHECKS}${NC}"
echo ""

if [ $SUCCESS_COUNT -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ ¡FASE 1 COMPLETADA EXITOSAMENTE!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✅ DNS configurado correctamente${NC}"
    echo -e "${GREEN}✅ Frontend accesible en https://$FRONTEND_DOMAIN${NC}"
    echo -e "${GREEN}✅ API funcional en https://$API_DOMAIN${NC}"
    echo -e "${GREEN}✅ Certificados SSL válidos${NC}"
    echo ""
    echo -e "${BLUE}📋 Próximos pasos:${NC}"
    echo -e "   1. Validar OAuth login end-to-end"
    echo -e "   2. Probar integración frontend-backend"
    echo -e "   3. Proceder con Fase 2: Optimización de infraestructura"
    echo ""
    exit 0
elif [ $success_percent -ge 75 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  FASE 1 PARCIALMENTE COMPLETADA${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Algunas validaciones fallaron, pero el sistema está mayormente funcional${NC}"
    echo ""
    echo -e "${BLUE}🔍 Revisar logs arriba para identificar problemas${NC}"
    echo ""
    exit 1
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ FASE 1 INCOMPLETA${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${RED}❌ Múltiples validaciones fallaron${NC}"
    echo ""
    echo -e "${YELLOW}📋 Acciones recomendadas:${NC}"
    echo -e "   1. Verificar que los cambios DNS se hayan aplicado en Cloudflare"
    echo -e "   2. Desactivar proxy de Cloudflare (nube gris)"
    echo -e "   3. Esperar propagación DNS (5-30 minutos)"
    echo -e "   4. Ejecutar nuevamente este script"
    echo ""
    echo -e "${BLUE}🔍 Comandos útiles:${NC}"
    echo -e "   dig +short $FRONTEND_DOMAIN"
    echo -e "   dig +short $API_DOMAIN"
    echo -e "   curl -I https://$FRONTEND_DOMAIN"
    echo -e "   curl -s https://$API_DOMAIN/health | jq ."
    echo ""
    exit 2
fi
