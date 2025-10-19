# Guía Completa: CI/CD y Routing para Microservicios

**Versión**: 2.0.0 **Fecha**: 2025-10-19 **Status**: ✅ IMPLEMENTADO - Load
Balancer Routing Completo

---

## 🎯 Resumen Ejecutivo

Se ha completado la configuración del Load Balancer con **path-based routing**
para todos los microservicios, permitiendo migración gradual usando **Strangler
Pattern**.

### Nueva Arquitectura de Routing

```
https://api.staging.adyela.care/auth/*            → api-auth-staging (NUEVO ✅)
https://api.staging.adyela.care/appointments/*    → api-appointments-staging (NUEVO ✅)
https://api.staging.adyela.care/payments/*        → api-payments-staging (NUEVO ✅)
https://api.staging.adyela.care/notifications/*   → api-notifications-staging (NUEVO ✅)
https://api.staging.adyela.care/admin/*           → api-admin-staging (NUEVO ✅)
https://api.staging.adyela.care/analytics/*       → api-analytics-staging (NUEVO ✅)
https://api.staging.adyela.care/*                 → adyela-api-staging (LEGACY - fallback)
```

**Ventajas**:

- ✅ Single domain para todas las APIs
- ✅ Migración gradual endpoint por endpoint
- ✅ Rollback fácil (solo cambiar routing)
- ✅ No breaking changes para clientes
- ✅ Load balancer automático entre instancias

---

## 📁 Archivos Modificados

### 1. Load Balancer Module

#### `infra/modules/load-balancer/variables.tf`

```hcl
variable "microservices" {
  description = "Map of microservice names to Cloud Run service names for path-based routing"
  type = map(object({
    service_name = string
    path_prefix  = string
  }))
  default = {}
}
```

#### `infra/modules/load-balancer/main.tf`

**Agregado**:

- `google_compute_region_network_endpoint_group.microservices_neg` (6 NEGs
  dinámicos)
- `google_compute_backend_service.microservices_backend` (6 backends dinámicos)
- Path rules dinámicos en URL map para routing de microservicios

### 2. Staging Environment Configuration

#### `infra/environments/staging/main.tf`

```hcl
module "load_balancer" {
  # ... existing config ...

  microservices = {
    auth = {
      service_name = module.api_auth.service_name
      path_prefix  = "/auth"
    }
    appointments = {
      service_name = module.api_appointments.service_name
      path_prefix  = "/appointments"
    }
    payments = {
      service_name = module.api_payments.service_name
      path_prefix  = "/payments"
    }
    notifications = {
      service_name = module.api_notifications.service_name
      path_prefix  = "/notifications"
    }
    admin = {
      service_name = module.api_admin.service_name
      path_prefix  = "/admin"
    }
    analytics = {
      service_name = module.api_analytics.service_name
      path_prefix  = "/analytics"
    }
  }
}
```

---

## 🚀 Implementación del Load Balancer

### Paso 1: Aplicar Terraform

```bash
cd infra/environments/staging

# Ver cambios
terraform plan

# Deberías ver:
# + 6 x google_compute_region_network_endpoint_group (NEGs for microservices)
# + 6 x google_compute_backend_service (backends for microservices)
# ~ google_compute_url_map (updated with path rules)

# Aplicar
terraform apply
```

**Tiempo estimado**: 5-10 minutos

### Paso 2: Verificar Routing

```bash
# Una vez aplicado, probar routing
curl -I https://api.staging.adyela.care/auth/health
curl -I https://api.staging.adyela.care/appointments/health
curl -I https://api.staging.adyela.care/payments/health

# Deberían retornar 200 OK (si los servicios están deployed)
# Si no están deployed, retornará 502 Bad Gateway (esperado)
```

---

## 📋 CI Workflows - Status

### ✅ Creados

| Microservicio        | CI Workflow                                 | Status    |
| -------------------- | ------------------------------------------- | --------- |
| **API Auth**         | `.github/workflows/ci-api-auth.yml`         | ✅ EXISTE |
| **API Appointments** | `.github/workflows/ci-api-appointments.yml` | ✅ CREADO |

### ⚠️ Pendientes (Mismo Patrón)

Crear siguiendo el template de `ci-api-appointments.yml`:

| Microservicio         | Archivo a Crear                              | Template Base                   |
| --------------------- | -------------------------------------------- | ------------------------------- |
| **API Admin**         | `.github/workflows/ci-api-admin.yml`         | Python (copiar de appointments) |
| **API Analytics**     | `.github/workflows/ci-api-analytics.yml`     | Python (copiar de appointments) |
| **API Payments**      | `.github/workflows/ci-api-payments.yml`      | Node.js (adaptar)               |
| **API Notifications** | `.github/workflows/ci-api-notifications.yml` | Node.js (adaptar)               |

---

## 🔨 Template para CI Workflows

### Python Microservices (Admin, Analytics)

**Archivos a crear**:

- `.github/workflows/ci-api-admin.yml`
- `.github/workflows/ci-api-analytics.yml`

**Cambios necesarios**:

1. Reemplazar `api-appointments` con nombre del microservicio
2. Ajustar `working-directory` paths
3. Ajustar nombres de coverage flags

**Ejemplo rápido**:

```yaml
# Copiar ci-api-appointments.yml
# Buscar y reemplazar:
# - "api-appointments" → "api-admin"
# - "adyela_api_appointments" → "adyela_api_admin"
# - "appointments" → "admin"
```

### Node.js Microservices (Payments, Notifications)

**Template CI para Node.js**:

```yaml
name: CI - API Payments

on:
  push:
    branches: [main, develop, feature/**]
    paths:
      - 'apps/api-payments/**'
      - '.github/workflows/ci-api-payments.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'apps/api-payments/**'

env:
  NODE_VERSION: '20'
  SERVICE_NAME: 'api-payments'

jobs:
  lint-and-format:
    name: Lint & Format Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 9

      - name: Install dependencies
        working-directory: apps/api-payments
        run: pnpm install

      - name: Run ESLint
        working-directory: apps/api-payments
        run: pnpm lint

      - name: Run Prettier check
        working-directory: apps/api-payments
        run: pnpm format:check

  type-check:
    name: Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 9

      - name: Install dependencies
        working-directory: apps/api-payments
        run: pnpm install

      - name: Run TypeScript check
        working-directory: apps/api-payments
        run: pnpm type-check

  unit-tests:
    name: Unit Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 9

      - name: Install dependencies
        working-directory: apps/api-payments
        run: pnpm install

      - name: Run Jest tests
        working-directory: apps/api-payments
        run: pnpm test:cov

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        if: always()
        with:
          files: ./apps/api-payments/coverage/lcov.info
          flags: api-payments-unit
          name: api-payments-coverage

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 9

      - name: Run npm audit
        working-directory: apps/api-payments
        run: pnpm audit --audit-level=moderate
        continue-on-error: true

  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: [lint-and-format, type-check, unit-tests, security-scan]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image
        uses: docker/build-push-action@v5
        with:
          context: ./apps/api-payments
          push: false
          tags: adyela/api-payments:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## 🚢 Deployment Workflows - Template

### Deployment Workflow Genérico para Microservicios

**Nombre**: `.github/workflows/deploy-microservices.yml`

```yaml
name: Deploy Microservices

on:
  push:
    branches:
      - develop # Staging
      - main # Production
    paths:
      - 'apps/api-auth/**'
      - 'apps/api-appointments/**'
      - 'apps/api-payments/**'
      - 'apps/api-notifications/**'
      - 'apps/api-admin/**'
      - 'apps/api-analytics/**'
  workflow_dispatch:
    inputs:
      service:
        description: 'Microservice to deploy'
        required: true
        type: choice
        options:
          - all
          - api-auth
          - api-appointments
          - api-payments
          - api-notifications
          - api-admin
          - api-analytics
      environment:
        description: 'Environment'
        required: true
        type: choice
        options:
          - staging
          - production

env:
  GCP_REGION: 'us-central1'

permissions:
  contents: read
  id-token: write

jobs:
  determine-changes:
    name: Determine Changed Services
    runs-on: ubuntu-latest
    outputs:
      auth: ${{ steps.filter.outputs.auth }}
      appointments: ${{ steps.filter.outputs.appointments }}
      payments: ${{ steps.filter.outputs.payments }}
      notifications: ${{ steps.filter.outputs.notifications }}
      admin: ${{ steps.filter.outputs.admin }}
      analytics: ${{ steps.filter.outputs.analytics }}
      environment: ${{ steps.set-env.outputs.environment }}
    steps:
      - uses: actions/checkout@v4

      - name: Detect changed services
        uses: dorny/paths-filter@v2
        id: filter
        with:
          filters: |
            auth:
              - 'apps/api-auth/**'
            appointments:
              - 'apps/api-appointments/**'
            payments:
              - 'apps/api-payments/**'
            notifications:
              - 'apps/api-notifications/**'
            admin:
              - 'apps/api-admin/**'
            analytics:
              - 'apps/api-analytics/**'

      - name: Set environment
        id: set-env
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "environment=${{ github.event.inputs.environment }}" >> $GITHUB_OUTPUT
          elif [ "${{ github.ref }}" == "refs/heads/main" ]; then
            echo "environment=production" >> $GITHUB_OUTPUT
          else
            echo "environment=staging" >> $GITHUB_OUTPUT
          fi

  # Individual deploy jobs for each microservice...
  # (Similar structure to deploy-flutter-web.yml)
```

---

## 📊 Plan de Acción Completo

### ✅ Fase 1: Load Balancer (COMPLETADO)

- ✅ Actualizado load balancer module con microservices support
- ✅ Agregados 6 NEGs dinámicos
- ✅ Agregados 6 backend services dinámicos
- ✅ Configurado path-based routing en URL map
- ✅ Actualizado staging environment configuration

**Resultado**: API routing listo para microservicios

---

### 🟡 Fase 2: CI Workflows (EN PROGRESO)

**Completado**:

- ✅ ci-api-auth.yml
- ✅ ci-api-appointments.yml

**Pendiente**:

- ⚠️ ci-api-admin.yml (copiar de appointments)
- ⚠️ ci-api-analytics.yml (copiar de appointments)
- ⚠️ ci-api-payments.yml (adaptar para Node.js)
- ⚠️ ci-api-notifications.yml (adaptar para Node.js)

**Tiempo estimado**: 1-2 horas

---

### 🔴 Fase 3: Deployment Workflows (PENDIENTE)

**Opciones**:

1. **Opción A: Un workflow por microservicio** (más simple)
   - deploy-api-auth.yml
   - deploy-api-appointments.yml
   - etc.

2. **Opción B: Workflow unificado con matriz** (más eficiente)
   - deploy-microservices.yml (con matriz de servicios)

**Recomendación**: Opción B (unificado)

**Tiempo estimado**: 3-4 horas

---

## 🎯 Prioridades Actualizadas

### P0 - Inmediato (Esta sesión)

1. ✅ Load Balancer routing → **COMPLETADO**
2. ⚠️ Completar CI workflows para Python microservices
3. ⚠️ Completar CI workflows para Node.js microservices

### P1 - Esta Semana

4. ⚠️ Crear deployment workflow unificado
5. ⚠️ Deploy y probar api-auth en staging
6. ⚠️ Deploy y probar api-appointments en staging

### P2 - Próximas 2 Semanas

7. ⚠️ Deploy microservicios restantes
8. ⚠️ Migrar endpoints del monolito a microservicios
9. ⚠️ E2E testing de arquitectura completa

---

## 🔄 Strangler Pattern Migration

### Estrategia de Migración

**Fase 1**: Auth (ya en progreso)

```
ANTES: https://api.staging.adyela.care/v1/auth/login → Monolito
AHORA: https://api.staging.adyela.care/auth/login → api-auth microservice
```

**Fase 2**: Appointments

```
ANTES: https://api.staging.adyela.care/v1/appointments → Monolito
AHORA: https://api.staging.adyela.care/appointments → api-appointments
```

**Fase 3-6**: Payments, Notifications, Admin, Analytics

**Fase 7**: Deprecar monolito

```
FINALMENTE: https://api.staging.adyela.care/* → 404 (todo migrado)
```

---

## ✅ Checklist Final

### Load Balancer

- [x] Variables agregadas para microservices
- [x] NEGs creados dinámicamente
- [x] Backend services creados dinámicamente
- [x] URL map con path-based routing
- [x] Configuración en staging environment
- [ ] Terraform apply ejecutado ⚠️
- [ ] Routing verificado con curl ⚠️

### CI Workflows

- [x] ci-api-auth.yml (ya existía)
- [x] ci-api-appointments.yml (creado)
- [ ] ci-api-admin.yml ⚠️
- [ ] ci-api-analytics.yml ⚠️
- [ ] ci-api-payments.yml ⚠️
- [ ] ci-api-notifications.yml ⚠️

### Deployment Workflows

- [ ] deploy-microservices.yml (unificado) ⚠️
- [ ] O deploy-api-\*.yml (individuales) ⚠️

### Testing

- [ ] E2E tests actualizados con nuevas URLs ⚠️
- [ ] Load testing del nuevo routing ⚠️
- [ ] Rollback procedure tested ⚠️

---

## 📚 Referencias

- [Load Balancer Module](infra/modules/load-balancer/main.tf)
- [Staging Configuration](infra/environments/staging/main.tf)
- [Microservices Audit](MICROSERVICES_AUDIT.md)
- [GitOps Workflow](docs/deployment/gitops-workflow.md)
- [Strangler Pattern](docs/architecture/microservices-migration-strategy.md)

---

**Status Actual**: ✅ Load Balancer listo, ⚠️ CI/CD workflows en progreso
**Próximo Paso**: Ejecutar `terraform apply` y crear workflows CI restantes
