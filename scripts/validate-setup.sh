#!/bin/bash
# scripts/validate-setup.sh - Validar configuración de GCP y GitHub

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🔍 Validación de Configuración Adyela${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Cargar configuración
if [ -f ".gcp-config" ]; then
    source .gcp-config
    echo -e "${GREEN}✅ Configuración GCP cargada${NC}"
    echo "  - ORG_ID: $ORG_ID"
    echo "  - BILLING_ACCOUNT: $BILLING_ACCOUNT"
    echo "  - STAGING_PROJECT: $STAGING_PROJECT"
    echo "  - PRODUCTION_PROJECT: $PRODUCTION_PROJECT"
    echo "  - GITHUB_REPO: $GITHUB_REPO"
else
    echo -e "${RED}❌ Archivo .gcp-config no encontrado${NC}"
    exit 1
fi

echo ""

# 1. Validar autenticación GCP
echo -e "${BLUE}[1/6] Validando autenticación GCP...${NC}"
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    echo -e "${GREEN}✅ Autenticado como: $ACTIVE_ACCOUNT${NC}"
else
    echo -e "${RED}❌ No hay cuenta GCP autenticada${NC}"
    echo -e "${YELLOW}💡 Ejecuta: gcloud auth login${NC}"
    exit 1
fi

# 2. Validar proyectos GCP
echo -e "${BLUE}[2/6] Validando proyectos GCP...${NC}"
if gcloud projects list --format="value(projectId)" | grep -q "$STAGING_PROJECT"; then
    echo -e "${GREEN}✅ Proyecto staging existe: $STAGING_PROJECT${NC}"
else
    echo -e "${YELLOW}⚠️  Proyecto staging NO existe: $STAGING_PROJECT${NC}"
    echo -e "${YELLOW}💡 Crear con: gcloud projects create $STAGING_PROJECT --name='Adyela Staging'${NC}"
fi

if gcloud projects list --format="value(projectId)" | grep -q "$PRODUCTION_PROJECT"; then
    echo -e "${GREEN}✅ Proyecto production existe: $PRODUCTION_PROJECT${NC}"
else
    echo -e "${YELLOW}⚠️  Proyecto production NO existe: $PRODUCTION_PROJECT${NC}"
    echo -e "${YELLOW}💡 Crear con: gcloud projects create $PRODUCTION_PROJECT --name='Adyela Production'${NC}"
fi

# 3. Validar billing
echo -e "${BLUE}[3/6] Validando billing...${NC}"
if [ -n "$BILLING_ACCOUNT" ]; then
    echo -e "${GREEN}✅ Billing account configurado: $BILLING_ACCOUNT${NC}"
else
    echo -e "${RED}❌ Billing account no configurado${NC}"
fi

# 4. Validar GitHub token
echo -e "${BLUE}[4/6] Validando GitHub token...${NC}"
if [ -f ".cursor/mcp.json" ] && grep -q "GITHUB_PERSONAL_ACCESS_TOKEN" .cursor/mcp.json; then
    echo -e "${GREEN}✅ GitHub token configurado en MCP${NC}"
    
    # Extraer token y validar
    TOKEN=$(grep "GITHUB_PERSONAL_ACCESS_TOKEN" .cursor/mcp.json | cut -d'"' -f4)
    if [ "$TOKEN" != "YOUR_GITHUB_TOKEN_HERE" ] && [ -n "$TOKEN" ]; then
        echo -e "${GREEN}✅ Token válido configurado${NC}"
        
        # Validar token con GitHub API
        if curl -s -H "Authorization: token $TOKEN" https://api.github.com/user | grep -q "login"; then
            USER=$(curl -s -H "Authorization: token $TOKEN" https://api.github.com/user | grep '"login"' | cut -d'"' -f4)
            echo -e "${GREEN}✅ Token válido para usuario: $USER${NC}"
        else
            echo -e "${RED}❌ Token GitHub inválido o expirado${NC}"
        fi
    else
        echo -e "${RED}❌ Token GitHub no configurado correctamente${NC}"
    fi
else
    echo -e "${RED}❌ GitHub token no encontrado en MCP config${NC}"
fi

# 5. Validar repositorio GitHub
echo -e "${BLUE}[5/6] Validando repositorio GitHub...${NC}"
if [ -n "$GITHUB_REPO" ]; then
    echo -e "${GREEN}✅ Repositorio configurado: $GITHUB_REPO${NC}"
    
    # Validar que el repo existe
    if curl -s "https://api.github.com/repos/$GITHUB_REPO" | grep -q "full_name"; then
        echo -e "${GREEN}✅ Repositorio existe en GitHub${NC}"
    else
        echo -e "${RED}❌ Repositorio no existe o no es accesible: $GITHUB_REPO${NC}"
    fi
else
    echo -e "${RED}❌ Repositorio GitHub no configurado${NC}"
fi

# 6. Validar workflows
echo -e "${BLUE}[6/6] Validando workflows GitHub Actions...${NC}"
if [ -d ".github/workflows" ]; then
    WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l)
    echo -e "${GREEN}✅ $WORKFLOW_COUNT workflows encontrados${NC}"
    
    # Listar workflows
    echo "  Workflows disponibles:"
    for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do
        if [ -f "$workflow" ]; then
            echo "    - $(basename "$workflow")"
        fi
    done
else
    echo -e "${RED}❌ Directorio .github/workflows no encontrado${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Resumen
echo -e "${BLUE}📋 Resumen de Validación:${NC}"
echo ""

# Verificar si todo está listo
ALL_READY=true

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo -e "${RED}❌ GCP: No autenticado${NC}"
    ALL_READY=false
else
    echo -e "${GREEN}✅ GCP: Autenticado${NC}"
fi

if ! gcloud projects list --format="value(projectId)" | grep -q "$STAGING_PROJECT"; then
    echo -e "${RED}❌ GCP: Proyecto staging faltante${NC}"
    ALL_READY=false
else
    echo -e "${GREEN}✅ GCP: Proyecto staging existe${NC}"
fi

if ! gcloud projects list --format="value(projectId)" | grep -q "$PRODUCTION_PROJECT"; then
    echo -e "${RED}❌ GCP: Proyecto production faltante${NC}"
    ALL_READY=false
else
    echo -e "${GREEN}✅ GCP: Proyecto production existe${NC}"
fi

if [ -f ".cursor/mcp.json" ] && grep -q "GITHUB_PERSONAL_ACCESS_TOKEN" .cursor/mcp.json; then
    echo -e "${GREEN}✅ GitHub: Token configurado${NC}"
else
    echo -e "${RED}❌ GitHub: Token faltante${NC}"
    ALL_READY=false
fi

if [ -d ".github/workflows" ]; then
    echo -e "${GREEN}✅ GitHub: Workflows configurados${NC}"
else
    echo -e "${RED}❌ GitHub: Workflows faltantes${NC}"
    ALL_READY=false
fi

echo ""

if [ "$ALL_READY" = true ]; then
    echo -e "${GREEN}🎉 ¡Todo listo! Puedes proceder con el deployment.${NC}"
    echo ""
    echo -e "${BLUE}Próximos pasos:${NC}"
    echo "1. Implementar infraestructura Terraform (Tareas 1-8)"
    echo "2. Configurar secrets en GitHub Actions"
    echo "3. Ejecutar primer deployment a staging"
else
    echo -e "${YELLOW}⚠️  Configuración incompleta. Revisa los errores arriba.${NC}"
    echo ""
    echo -e "${BLUE}Acciones requeridas:${NC}"
    echo "1. gcloud auth login"
    echo "2. Crear proyectos GCP si no existen"
    echo "3. Configurar billing accounts"
    echo "4. Verificar GitHub token"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
