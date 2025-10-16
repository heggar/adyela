#!/bin/bash

# 🚀 FASE 1: DIAGNÓSTICO Y CORRECCIÓN CRÍTICA - Script de Ejecución
# Este script ejecuta automáticamente la Fase 1 del Plan Integral de Arquitectura

set -e  # Exit on any error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar dependencias
check_dependencies() {
    log "Verificando dependencias..."
    
    local deps=("gcloud" "docker" "curl" "jq" "terraform")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Dependencias faltantes: ${missing[*]}"
        exit 1
    fi
    
    success "Todas las dependencias están disponibles"
}

# Verificar autenticación
check_auth() {
    log "Verificando autenticación..."
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        error "No hay cuentas autenticadas en gcloud"
        exit 1
    fi
    
    if ! gcloud config get-value project >/dev/null 2>&1; then
        error "No hay proyecto configurado en gcloud"
        exit 1
    fi
    
    success "Autenticación verificada"
}

# PASO 1: DIAGNÓSTICO PROFUNDO DEL BACKEND
diagnose_backend() {
    log "🔍 PASO 1: Diagnóstico profundo del backend..."
    
    # 1.1 Verificar logs detallados del API
    log "1.1 Verificando logs detallados del API..."
    gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=adyela-api-staging AND timestamp>=\"2025-10-12T20:00:00Z\"" --limit=20 --format="table(timestamp,severity,textPayload)" || warning "No se pudieron obtener logs recientes"
    
    # 1.2 Analizar configuración de FastAPI
    log "1.2 Analizando configuración de FastAPI..."
    gcloud run services describe adyela-api-staging --region=us-central1 --format="export" > /tmp/api-config.yaml
    success "Configuración del API guardada en /tmp/api-config.yaml"
    
    # 1.3 Verificar variables de entorno
    log "1.3 Verificando variables de entorno..."
    gcloud run services describe adyela-api-staging --region=us-central1 --format="value(spec.template.spec.containers[0].env[].name,spec.template.spec.containers[0].env[].value)" | head -10
    
    # 1.4 Verificar secrets
    log "1.4 Verificando secrets..."
    gcloud secrets list --format="table(name,createTime)" | head -10
    
    success "Diagnóstico del backend completado"
}

# PASO 2: CORRECCIÓN DEL BACKEND
fix_backend() {
    log "🔧 PASO 2: Corrección del backend..."
    
    # 2.1 Verificar construcción local del API
    log "2.1 Verificando construcción local del API..."
    cd apps/api
    
    if [ -f "pyproject.toml" ]; then
        log "Verificando configuración de Poetry..."
        poetry --version
        poetry env info
        
        log "Instalando dependencias..."
        poetry install --no-dev
        
        log "Verificando que el API se puede ejecutar..."
        timeout 10s poetry run python -c "from adyela_api.main import app; print('FastAPI app loaded successfully')" || warning "No se pudo cargar la aplicación FastAPI"
    else
        warning "No se encontró pyproject.toml en apps/api"
    fi
    
    cd ../..
    
    # 2.2 Verificar Docker build
    log "2.2 Verificando Docker build del API..."
    cd apps/api
    docker build -t adyela-api-test:latest . || error "Docker build falló"
    success "Docker build del API exitoso"
    cd ../..
    
    # 2.3 Aplicar configuración correcta via Terraform
    log "2.3 Aplicando configuración correcta via Terraform..."
    cd infra/environments/staging
    
    log "Verificando plan de Terraform..."
    terraform plan -target=module.cloud_run.google_cloud_run_v2_service.api
    
    log "Aplicando cambios..."
    terraform apply -target=module.cloud_run.google_cloud_run_v2_service.api -auto-approve
    
    cd ../../..
    
    success "Corrección del backend completada"
}

# PASO 3: VERIFICACIÓN DEL FRONTEND
verify_frontend() {
    log "🎨 PASO 3: Verificación del frontend..."
    
    # 3.1 Verificar construcción del frontend
    log "3.1 Verificando construcción del frontend..."
    cd apps/web
    
    if [ -f "package.json" ]; then
        log "Instalando dependencias..."
        pnpm install
        
        log "Construyendo aplicación..."
        pnpm build
        
        if [ -d "dist" ]; then
            success "Construcción del frontend exitosa"
            ls -la dist/ | head -5
        else
            error "No se generó el directorio dist/"
        fi
    else
        warning "No se encontró package.json en apps/web"
    fi
    
    cd ../..
    
    # 3.2 Verificar Docker build del frontend
    log "3.2 Verificando Docker build del frontend..."
    cd apps/web
    docker build -t adyela-web-test:latest . || error "Docker build del frontend falló"
    success "Docker build del frontend exitoso"
    cd ../..
    
    success "Verificación del frontend completada"
}

# PASO 4: SINCRONIZACIÓN TERRAFORM
sync_terraform() {
    log "🔄 PASO 4: Sincronización Terraform..."
    
    cd infra/environments/staging
    
    log "Verificando estado de Terraform..."
    terraform plan
    
    log "Aplicando configuración completa..."
    terraform apply -auto-approve
    
    cd ../../..
    
    success "Sincronización Terraform completada"
}

# PASO 5: VERIFICACIÓN DEL LOAD BALANCER
verify_load_balancer() {
    log "🔗 PASO 5: Verificación del Load Balancer..."
    
    # 5.1 Verificar configuración del Load Balancer
    log "5.1 Verificando configuración del Load Balancer..."
    gcloud compute backend-services list --global --format="table(name,backends[].group,healthChecks[].name)"
    
    # 5.2 Verificar routing
    log "5.2 Verificando routing..."
    log "Probando endpoint de health a través del Load Balancer..."
    curl -s -o /dev/null -w "%{http_code}" "https://staging.adyela.care/health" || warning "No se pudo conectar al Load Balancer"
    
    # 5.3 Verificar DNS
    log "5.3 Verificando DNS..."
    nslookup staging.adyela.care || warning "No se pudo resolver DNS"
    
    success "Verificación del Load Balancer completada"
}

# VERIFICACIÓN FINAL
final_verification() {
    log "✅ VERIFICACIÓN FINAL..."
    
    # Esperar que los servicios se actualicen
    log "Esperando que los servicios se actualicen..."
    sleep 30
    
    # Probar endpoints críticos
    log "Probando endpoints críticos..."
    
    # API directo
    log "Probando API directo..."
    curl -s -o /dev/null -w "API directo: %{http_code}\n" "https://adyela-api-staging-vrqu3jr6aa-uc.a.run.app/health"
    
    # API a través del Load Balancer
    log "Probando API a través del Load Balancer..."
    curl -s -o /dev/null -w "API Load Balancer: %{http_code}\n" "https://api.staging.adyela.care/health"
    
    # Web app
    log "Probando aplicación web..."
    curl -s -o /dev/null -w "Web app: %{http_code}\n" "https://staging.adyela.care"
    
    success "Verificación final completada"
}

# Función principal
main() {
    log "🚀 Iniciando FASE 1: Diagnóstico y Corrección Crítica"
    log "=================================================="
    
    # Verificaciones previas
    check_dependencies
    check_auth
    
    # Ejecutar pasos
    diagnose_backend
    fix_backend
    verify_frontend
    sync_terraform
    verify_load_balancer
    final_verification
    
    log "=================================================="
    success "🎉 FASE 1 COMPLETADA EXITOSAMENTE"
    log "Próximos pasos:"
    log "1. Verificar que todos los endpoints funcionan correctamente"
    log "2. Ejecutar pruebas de integración"
    log "3. Proceder con Fase 2: Optimización de Infraestructura"
}

# Ejecutar función principal
main "$@"

