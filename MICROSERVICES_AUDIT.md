# Auditoría de Microservicios y CI/CD

**Fecha**: 2025-10-19 **Status**: 🔴 INCOMPLETO - Requiere Acción

---

## 📊 Estado Actual

### Microservicios Existentes (7 total)

| #   | Microservicio         | Directorio                | Lenguaje    | Puerto | Cloud Run Service           | CI Workflow          | Deploy Workflow | Load Balancer Route          |
| --- | --------------------- | ------------------------- | ----------- | ------ | --------------------------- | -------------------- | --------------- | ---------------------------- |
| 0   | **API (Legacy)**      | `apps/api/`               | Python 3.12 | 8000   | `adyela-api-staging`        | ✅ `ci-api.yml`      | ❌ Manual       | ✅ `api.staging.adyela.care` |
| 1   | **API Auth**          | `apps/api-auth/`          | Python 3.12 | 8000   | `api-auth-staging`          | ✅ `ci-api-auth.yml` | ❌ Falta        | ❌ Sin routing               |
| 2   | **API Appointments**  | `apps/api-appointments/`  | Python 3.12 | 8000   | `api-appointments-staging`  | ❌ Falta             | ❌ Falta        | ❌ Sin routing               |
| 3   | **API Payments**      | `apps/api-payments/`      | Node.js 20  | 3000   | `api-payments-staging`      | ❌ Falta             | ❌ Falta        | ❌ Sin routing               |
| 4   | **API Notifications** | `apps/api-notifications/` | Node.js 20  | 3000   | `api-notifications-staging` | ❌ Falta             | ❌ Falta        | ❌ Sin routing               |
| 5   | **API Admin**         | `apps/api-admin/`         | Python 3.12 | 8000   | `api-admin-staging`         | ❌ Falta             | ❌ Falta        | ❌ Sin routing               |
| 6   | **API Analytics**     | `apps/api-analytics/`     | Python 3.12 | 8000   | `api-analytics-staging`     | ❌ Falta             | ❌ Falta        | ❌ Sin routing               |

### Apps Flutter Web (2)

| #   | Aplicación           | Directorio                  | Cloud Run Service                 | CI Workflow | Deploy Workflow             | Load Balancer Route                   |
| --- | -------------------- | --------------------------- | --------------------------------- | ----------- | --------------------------- | ------------------------------------- |
| 7   | **Patient Web**      | `apps/mobile-patient/`      | `adyela-patient-web-staging`      | ❌ N/A      | ✅ `deploy-flutter-web.yml` | ✅ `patient.staging.adyela.care`      |
| 8   | **Professional Web** | `apps/mobile-professional/` | `adyela-professional-web-staging` | ❌ N/A      | ✅ `deploy-flutter-web.yml` | ✅ `professional.staging.adyela.care` |

### Admin Web (1)

| #   | Aplicación    | Directorio  | Cloud Run Service    | CI Workflow     | Deploy Workflow | Load Balancer Route      |
| --- | ------------- | ----------- | -------------------- | --------------- | --------------- | ------------------------ |
| 9   | **Admin Web** | `apps/web/` | `adyela-web-staging` | ✅ `ci-web.yml` | ❌ Manual       | ✅ `staging.adyela.care` |

---

## 🚨 Problemas Identificados

### 1. Load Balancer - Routing Incompleto ⚠️

**Problema**: El load balancer solo enruta a:

- ✅ Admin web app → `staging.adyela.care`
- ✅ Patient web app → `patient.staging.adyela.care`
- ✅ Professional web app → `professional.staging.adyela.care`
- ✅ API monolito legacy → `api.staging.adyela.care`

**Falta routing para los 6 microservicios**:

- ❌ Auth service
- ❌ Appointments service
- ❌ Payments service
- ❌ Notifications service
- ❌ Admin service
- ❌ Analytics service

**Propuesta de URLs**:

```
https://api.staging.adyela.care/auth/*           → api-auth-staging
https://api.staging.adyela.care/appointments/*   → api-appointments-staging
https://api.staging.adyela.care/payments/*       → api-payments-staging
https://api.staging.adyela.care/notifications/*  → api-notifications-staging
https://api.staging.adyela.care/admin/*          → api-admin-staging
https://api.staging.adyela.care/analytics/*      → api-analytics-staging
https://api.staging.adyela.care/*                → adyela-api-staging (legacy fallback)
```

---

### 2. CI Workflows - 5 Microservicios Sin CI ⚠️

**Workflows Existentes**:

- ✅ `.github/workflows/ci-api.yml` (Legacy monolito)
- ✅ `.github/workflows/ci-api-auth.yml` (Auth microservice)
- ✅ `.github/workflows/ci-web.yml` (Admin web)
- ✅ `.github/workflows/ci-infra.yml` (Terraform)

**Workflows Faltantes**:

- ❌ `.github/workflows/ci-api-appointments.yml`
- ❌ `.github/workflows/ci-api-payments.yml`
- ❌ `.github/workflows/ci-api-notifications.yml`
- ❌ `.github/workflows/ci-api-admin.yml`
- ❌ `.github/workflows/ci-api-analytics.yml`

**Cada CI debe incluir**:

- Lint & Format (Ruff + Black para Python, ESLint + Prettier para Node.js)
- Type Check (MyPy para Python, TypeScript para Node.js)
- Unit Tests (pytest para Python, Jest para Node.js)
- Integration Tests
- Security Scan (Bandit para Python, npm audit para Node.js)
- Docker Build (sin push)

---

### 3. Deployment Workflows - 7 Servicios Sin Deploy Automatizado ⚠️

**Workflows Existentes**:

- ✅ `.github/workflows/deploy-flutter-web.yml` (Patient + Professional apps)

**Workflows Faltantes**:

- ❌ `.github/workflows/deploy-api-legacy.yml` (Monolito)
- ❌ `.github/workflows/deploy-api-auth.yml`
- ❌ `.github/workflows/deploy-api-appointments.yml`
- ❌ `.github/workflows/deploy-api-payments.yml`
- ❌ `.github/workflows/deploy-api-notifications.yml`
- ❌ `.github/workflows/deploy-api-admin.yml`
- ❌ `.github/workflows/deploy-api-analytics.yml`
- ❌ `.github/workflows/deploy-admin-web.yml` (React admin panel)

**Cada Deploy debe incluir**:

- Build Docker image
- Push to Artifact Registry
- Deploy to Cloud Run
- Health check verification
- Rollback on failure

---

## 📋 Plan de Acción

### Fase 1: Load Balancer Routing (Alta Prioridad)

**Tiempo estimado**: 1-2 horas

1. Actualizar `infra/modules/load-balancer/main.tf`
   - Agregar 6 NEGs para microservicios
   - Agregar 6 backend services
   - Actualizar URL map con path-based routing

2. Actualizar `infra/environments/staging/main.tf`
   - Pasar referencias de microservicios al módulo load_balancer

3. Aplicar cambios Terraform:
   ```bash
   cd infra/environments/staging
   terraform plan
   terraform apply
   ```

**Beneficios**:

- URLs públicas para cada microservicio
- Routing centralizado
- Single SSL certificate
- Preparado para strangler pattern migration

---

### Fase 2: CI Workflows para Microservicios (Media Prioridad)

**Tiempo estimado**: 2-3 horas

Crear workflows CI siguiendo el patrón de `ci-api-auth.yml`:

1. **Python microservicios** (Appointments, Admin, Analytics):
   - `ci-api-appointments.yml`
   - `ci-api-admin.yml`
   - `ci-api-analytics.yml`

   Template base: `ci-api-auth.yml`

2. **Node.js microservicios** (Payments, Notifications):
   - `ci-api-payments.yml`
   - `ci-api-notifications.yml`

   Adaptación con npm/pnpm en lugar de Poetry

**Beneficios**:

- Quality gates antes de merge
- Detección temprana de bugs
- Security scanning automatizado
- Coverage reports

---

### Fase 3: Deployment Workflows (Alta Prioridad)

**Tiempo estimado**: 3-4 horas

Crear workflows de deployment automatizados:

1. **Microservicios individuales**:
   - `deploy-api-auth.yml`
   - `deploy-api-appointments.yml`
   - `deploy-api-payments.yml`
   - `deploy-api-notifications.yml`
   - `deploy-api-admin.yml`
   - `deploy-api-analytics.yml`

2. **Apps principales**:
   - `deploy-api-legacy.yml` (monolito)
   - `deploy-admin-web.yml` (React)

**Triggers**:

- Push a `develop` → staging
- Push a `main` → production (con approval gate)
- Manual dispatch

**Beneficios**:

- Deployment automatizado
- Consistency entre environments
- Faster time to production
- Audit trail

---

## 🎯 Prioridades

### P0 - Crítico (Esta semana)

1. ✅ Load Balancer routing para microservicios
2. ✅ Deployment workflows para microservicios críticos:
   - api-auth (autenticación)
   - api-appointments (core business)

### P1 - Alta (Próximas 2 semanas)

3. ✅ CI workflows para todos los microservicios
4. ✅ Deployment workflows para microservicios restantes:
   - api-payments
   - api-notifications
   - api-admin
   - api-analytics

### P2 - Media (Próximo mes)

5. ✅ Deployment workflow para admin web
6. ✅ Deployment workflow para API legacy
7. ✅ End-to-end testing de toda la arquitectura

---

## 📊 Métricas de Progreso

| Categoría                    | Completado | Total | %          |
| ---------------------------- | ---------- | ----- | ---------- |
| **Microservicios Terraform** | 6/6        | 6     | 100% ✅    |
| **Load Balancer Routes**     | 4/10       | 10    | 40% 🟡     |
| **CI Workflows**             | 2/7        | 7     | 29% 🔴     |
| **Deploy Workflows**         | 1/9        | 9     | 11% 🔴     |
| **TOTAL**                    | 13/32      | 32    | **41%** 🟡 |

---

## 🔗 Referencias

- [Microservices Terraform Config](infra/environments/staging/microservices.tf)
- [Load Balancer Module](infra/modules/load-balancer/main.tf)
- [Existing CI Workflow](. github/workflows/ci-api-auth.yml)
- [GitOps Workflow Guide](docs/deployment/gitops-workflow.md)
- [Strangler Pattern Documentation](docs/architecture/microservices-migration-strategy.md)

---

**Next Steps**: Comenzar con Fase 1 - Load Balancer Routing
