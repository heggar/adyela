#!/bin/bash

# Script: Verificar Configuración de Alertas y Google OAuth
# Descripción: Valida la configuración de alertas de Cloud Monitoring y Google OAuth
# Autor: Claude Code
# Fecha: 2025-10-16

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ID="adyela-staging"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Verificación de Alertas y Google OAuth - Adyela Staging${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Function to print section header
print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================================================
# 1. VERIFICACIÓN DE ALERTAS
# ============================================================================

print_section "1. VERIFICACIÓN DE ALERTAS DE MONITORING"

print_info "Verificando políticas de alerta..."
ALERT_POLICIES=$(gcloud alpha monitoring policies list --project=$PROJECT_ID --format="value(displayName)" 2>/dev/null || echo "")

if [ -z "$ALERT_POLICIES" ]; then
    print_error "No se encontraron políticas de alerta"
    exit 1
fi

EXPECTED_POLICIES=("adyela-staging-api-downtime" "adyela-staging-high-error-rate" "adyela-staging-high-latency")
FOUND_COUNT=0

for policy in "${EXPECTED_POLICIES[@]}"; do
    if echo "$ALERT_POLICIES" | grep -q "$policy"; then
        print_success "Política encontrada: $policy"
        ((FOUND_COUNT++))
    else
        print_error "Política no encontrada: $policy"
    fi
done

echo ""
if [ $FOUND_COUNT -eq 3 ]; then
    print_success "Todas las políticas de alerta están configuradas (3/3)"
else
    print_warning "Solo $FOUND_COUNT de 3 políticas encontradas"
fi

print_info "Verificando canales de notificación..."
NOTIFICATION_CHANNELS=$(gcloud alpha monitoring channels list --project=$PROJECT_ID --format="table(displayName,type,labels.email_address,enabled)" 2>/dev/null)

if echo "$NOTIFICATION_CHANNELS" | grep -q "adyela-staging-email-alerts"; then
    print_success "Canal de email encontrado"

    EMAIL=$(echo "$NOTIFICATION_CHANNELS" | grep "adyela-staging-email-alerts" | awk '{print $3}')
    if [ "$EMAIL" == "hever_gonzalezg@adyela.care" ]; then
        print_success "Email configurado correctamente: $EMAIL"
    else
        print_warning "Email configurado: $EMAIL (esperado: hever_gonzalezg@adyela.care)"
    fi
else
    print_error "Canal de notificación no encontrado"
fi

# ============================================================================
# 2. VERIFICACIÓN DE UPTIME CHECKS
# ============================================================================

print_section "2. VERIFICACIÓN DE UPTIME CHECKS"

print_info "Verificando uptime checks..."
UPTIME_CHECKS=$(gcloud monitoring uptime list-configs --project=$PROJECT_ID --format="value(displayName)" 2>/dev/null || echo "")

if [ -z "$UPTIME_CHECKS" ]; then
    print_error "No se encontraron uptime checks"
else
    EXPECTED_CHECKS=("adyela-staging-api-uptime" "adyela-staging-web-uptime")
    UPTIME_COUNT=0

    for check in "${EXPECTED_CHECKS[@]}"; do
        if echo "$UPTIME_CHECKS" | grep -q "$check"; then
            print_success "Uptime check encontrado: $check"
            ((UPTIME_COUNT++))
        else
            print_error "Uptime check no encontrado: $check"
        fi
    done

    echo ""
    if [ $UPTIME_COUNT -eq 2 ]; then
        print_success "Todos los uptime checks están configurados (2/2)"
    else
        print_warning "Solo $UPTIME_COUNT de 2 uptime checks encontrados"
    fi
fi

# ============================================================================
# 3. VERIFICACIÓN DE SERVICIOS
# ============================================================================

print_section "3. VERIFICACIÓN DE SERVICIOS DE IDENTITY PLATFORM"

print_info "Verificando servicios habilitados..."

# Check Identity Toolkit
if gcloud services list --enabled --project=$PROJECT_ID 2>/dev/null | grep -q "identitytoolkit.googleapis.com"; then
    print_success "Identity Toolkit habilitado"
else
    print_error "Identity Toolkit NO habilitado"
fi

# Check Identity Platform (puede estar deshabilitado, es OK)
if gcloud services list --enabled --project=$PROJECT_ID 2>/dev/null | grep -q "identityplatform.googleapis.com"; then
    print_success "Identity Platform habilitado"
else
    print_info "Identity Platform no habilitado (OK si Identity Toolkit está activo)"
fi

# ============================================================================
# 4. VERIFICACIÓN DE SECRETOS OAUTH
# ============================================================================

print_section "4. VERIFICACIÓN DE SECRETOS OAUTH EN SECRET MANAGER"

print_info "Verificando secretos de Google OAuth..."

REQUIRED_SECRETS=("oauth-google-client-id" "oauth-google-client-secret")
SECRET_COUNT=0

for secret in "${REQUIRED_SECRETS[@]}"; do
    if gcloud secrets describe "$secret" --project=$PROJECT_ID >/dev/null 2>&1; then
        print_success "Secret encontrado: $secret"
        ((SECRET_COUNT++))

        # Verificar que el secret tiene contenido
        if gcloud secrets versions access latest --secret="$secret" --project=$PROJECT_ID >/dev/null 2>&1; then
            print_info "  → Secret tiene valor configurado"
        else
            print_warning "  → Secret existe pero no tiene valor"
        fi
    else
        print_error "Secret no encontrado: $secret"
    fi
done

echo ""
if [ $SECRET_COUNT -eq 2 ]; then
    print_success "Todos los secretos de Google OAuth están configurados (2/2)"
else
    print_warning "Solo $SECRET_COUNT de 2 secretos encontrados"
fi

# Show Google Client ID
print_info "Client ID de Google OAuth:"
GOOGLE_CLIENT_ID=$(gcloud secrets versions access latest --secret="oauth-google-client-id" --project=$PROJECT_ID 2>/dev/null || echo "ERROR")
if [ "$GOOGLE_CLIENT_ID" != "ERROR" ]; then
    echo "  → ${GOOGLE_CLIENT_ID:0:50}..."
else
    print_error "  → No se pudo obtener el Client ID"
fi

# ============================================================================
# 5. VERIFICACIÓN DE CLOUD RUN
# ============================================================================

print_section "5. VERIFICACIÓN DE SERVICIOS CLOUD RUN"

print_info "Verificando servicio Web (adyela-web-staging)..."
if gcloud run services describe adyela-web-staging --region=us-central1 --project=$PROJECT_ID >/dev/null 2>&1; then
    print_success "Servicio Web encontrado"

    # Check Firebase env vars
    print_info "Verificando variables de entorno de Firebase..."
    ENV_VARS=$(gcloud run services describe adyela-web-staging --region=us-central1 --project=$PROJECT_ID --format="value(spec.template.spec.containers[0].env)" 2>/dev/null)

    if echo "$ENV_VARS" | grep -q "VITE_FIREBASE_PROJECT_ID"; then
        print_success "  → VITE_FIREBASE_PROJECT_ID configurado"
    else
        print_warning "  → VITE_FIREBASE_PROJECT_ID no encontrado"
    fi

    if echo "$ENV_VARS" | grep -q "VITE_FIREBASE_API_KEY"; then
        print_success "  → VITE_FIREBASE_API_KEY configurado"
    else
        print_warning "  → VITE_FIREBASE_API_KEY no encontrado"
    fi
else
    print_error "Servicio Web no encontrado"
fi

print_info "Verificando servicio API (adyela-api-staging)..."
if gcloud run services describe adyela-api-staging --region=us-central1 --project=$PROJECT_ID >/dev/null 2>&1; then
    print_success "Servicio API encontrado"
else
    print_error "Servicio API no encontrado"
fi

# ============================================================================
# 6. PRUEBA DE CONECTIVIDAD
# ============================================================================

print_section "6. PRUEBA DE CONECTIVIDAD"

print_info "Probando acceso a Web App..."
WEB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://staging.adyela.care 2>/dev/null || echo "ERROR")
if [ "$WEB_STATUS" == "200" ]; then
    print_success "Web App accesible (HTTP $WEB_STATUS)"
else
    print_error "Web App no accesible (HTTP $WEB_STATUS)"
fi

print_info "Probando acceso a API Health..."
API_HEALTH=$(curl -s https://api.staging.adyela.care/health 2>/dev/null || echo "ERROR")
if echo "$API_HEALTH" | grep -q "healthy"; then
    print_success "API Health endpoint funcionando"
    echo "  → Response: $API_HEALTH"
else
    print_error "API Health endpoint no responde correctamente"
fi

# ============================================================================
# RESUMEN FINAL
# ============================================================================

print_section "RESUMEN DE VERIFICACIÓN"

echo ""
echo -e "${BLUE}📊 Estado de Componentes:${NC}"
echo ""

# Alertas
if [ $FOUND_COUNT -eq 3 ]; then
    echo -e "${GREEN}✅ Alertas de Monitoring: OK (3/3 políticas)${NC}"
else
    echo -e "${YELLOW}⚠️  Alertas de Monitoring: INCOMPLETO ($FOUND_COUNT/3 políticas)${NC}"
fi

# Uptime Checks
if [ $UPTIME_COUNT -eq 2 ]; then
    echo -e "${GREEN}✅ Uptime Checks: OK (2/2)${NC}"
else
    echo -e "${YELLOW}⚠️  Uptime Checks: INCOMPLETO ($UPTIME_COUNT/2)${NC}"
fi

# OAuth Secrets
if [ $SECRET_COUNT -eq 2 ]; then
    echo -e "${GREEN}✅ Secretos OAuth: OK (2/2)${NC}"
else
    echo -e "${YELLOW}⚠️  Secretos OAuth: INCOMPLETO ($SECRET_COUNT/2)${NC}"
fi

# Connectivity
if [ "$WEB_STATUS" == "200" ] && echo "$API_HEALTH" | grep -q "healthy"; then
    echo -e "${GREEN}✅ Conectividad: OK (Web + API)${NC}"
else
    echo -e "${RED}❌ Conectividad: FALLO${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Verificación Completa${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

print_info "Próximos pasos:"
echo "  1. Probar notificaciones de alertas en Cloud Console"
echo "  2. Configurar Google OAuth en Firebase Console"
echo "  3. Probar flujo de autenticación en staging.adyela.care"
echo ""

print_info "Documentación completa:"
echo "  → docs/guides/ALERTAS_Y_OAUTH_CONFIG.md"
echo ""

print_info "Enlaces útiles:"
echo "  → Alertas: https://console.cloud.google.com/monitoring/alerting/policies?project=$PROJECT_ID"
echo "  → Firebase Auth: https://console.firebase.google.com/project/$PROJECT_ID/authentication/providers"
echo "  → OAuth Consent: https://console.cloud.google.com/apis/credentials/consent?project=$PROJECT_ID"
echo ""
