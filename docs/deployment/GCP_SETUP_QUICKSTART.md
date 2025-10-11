# 🚀 GCP Setup Quickstart Guide

Esta guía te ayudará a configurar GCP paso a paso para el proyecto Adyela.

## ✅ Estado actual

- [x] Organización creada
- [x] Proyectos creados (staging y production)
- [ ] APIs habilitadas
- [ ] Terraform backend configurado
- [ ] Workload Identity Federation (OIDC) configurado
- [ ] Secrets de GitHub configurados
- [ ] Presupuestos configurados

## 📋 Prerrequisitos

Asegúrate de tener instalado:

```bash
# Verificar instalaciones
gcloud --version
terraform --version
gh --version  # opcional

# Autenticarse en GCP
gcloud auth login
gcloud auth application-default login
```

## 🎯 Opción 1: Setup Automático (Recomendado)

Ejecuta el script completo que te guiará paso a paso:

```bash
cd /Users/hevergonzalezgarcia/TFM\ Agentes\ IA/CLAUDE/adyela

# Ejecutar setup completo interactivo
./scripts/setup-gcp-complete.sh
```

Este script:

1. ✅ Recopilará tu configuración (IDs de proyecto, org, billing)
2. ✅ Habilitará todas las APIs necesarias
3. ✅ Creará los buckets de Terraform
4. ✅ Configurará Workload Identity Federation
5. ✅ Configurará presupuestos y alertas
6. ✅ Generará los secrets para GitHub

## 🎯 Opción 2: Setup Manual Paso a Paso

### Paso 1: Configuración inicial

```bash
# Ejecutar configuración interactiva
./scripts/gcp-setup-interactive.sh
```

Esto creará un archivo `.gcp-config` con tu configuración.

### Paso 2: Habilitar APIs

```bash
# Para staging
./scripts/enable-gcp-apis.sh adyela-staging staging

# Para production
./scripts/enable-gcp-apis.sh adyela-production production
```

**Tiempo estimado:** 2-3 minutos por proyecto

### Paso 3: Configurar Backend de Terraform

```bash
./scripts/setup-terraform-backend.sh
```

Esto creará:

- `gs://adyela-staging-terraform-state`
- `gs://adyela-production-terraform-state`

**Tiempo estimado:** 1-2 minutos

### Paso 4: Configurar OIDC (Workload Identity Federation)

```bash
# Para staging
./scripts/setup-gcp-oidc.sh adyela-staging heggar/adyela staging

# Para production
./scripts/setup-gcp-oidc.sh adyela-production heggar/adyela production
```

**IMPORTANTE:** Este comando mostrará los secrets que debes agregar a GitHub. Guárdalos en un lugar seguro.

**Tiempo estimado:** 2-3 minutos por entorno

### Paso 5: Configurar Presupuestos

```bash
./scripts/setup-budgets.sh
```

**Tiempo estimado:** 1-2 minutos

## 🔐 Configurar GitHub Secrets

Una vez ejecutados los scripts de OIDC, ve a:

**URL:** https://github.com/heggar/adyela/settings/secrets/actions

### Secrets a agregar

#### Para Staging (Environment: `staging`)

```
WORKLOAD_IDENTITY_PROVIDER_STAGING = projects/123.../workloadIdentityPools/.../providers/...
SERVICE_ACCOUNT_STAGING = github-actions-staging@adyela-staging.iam.gserviceaccount.com
GCP_PROJECT_ID_STAGING = adyela-staging
```

#### Para Production (Environment: `production`)

```
WORKLOAD_IDENTITY_PROVIDER_PRODUCTION = projects/456.../workloadIdentityPools/.../providers/...
SERVICE_ACCOUNT_PRODUCTION = github-actions-production@adyela-production.iam.gserviceaccount.com
GCP_PROJECT_ID_PRODUCTION = adyela-production
```

#### Variables de repositorio

Ve a: https://github.com/heggar/adyela/settings/variables/actions

Crea una variable:

```
GCP_CONFIGURED = true
```

Esto habilitará los jobs de Terraform en los workflows de CI/CD.

## 🧪 Verificar la configuración

### 1. Verificar buckets de Terraform

```bash
# Staging
gsutil ls gs://adyela-staging-terraform-state

# Production
gsutil ls gs://adyela-production-terraform-state
```

### 2. Verificar Workload Identity Pools

```bash
# Staging
gcloud iam workload-identity-pools list --location=global --project=adyela-staging

# Production
gcloud iam workload-identity-pools list --location=global --project=adyela-production
```

### 3. Verificar Service Accounts

```bash
# Staging
gcloud iam service-accounts list --project=adyela-staging

# Production
gcloud iam service-accounts list --project=adyela-production
```

### 4. Inicializar Terraform

```bash
# Staging
cd infra/environments/staging
terraform init
terraform plan

# Production
cd ../production
terraform init
terraform plan
```

### 5. Test de autenticación en GitHub Actions

Una vez configurados los secrets, haz un push al PR:

```bash
git add .
git commit -m "chore: add GCP setup scripts"
git push origin feat/api-backend
```

Los workflows de CI/CD deberían correr sin errores de autenticación.

## 📊 Verificar Presupuestos

Ve a: https://console.cloud.google.com/billing/budgets

Deberías ver:

- **Staging Monthly Budget** - $10/mes
- **Production Monthly Budget** - $100/mes

Con alertas configuradas al 50%, 80%, 100%, y 120% del presupuesto.

## 🔍 Troubleshooting

### Error: "API not enabled"

```bash
# Volver a ejecutar
./scripts/enable-gcp-apis.sh PROJECT_ID ENVIRONMENT
```

### Error: "Permission denied"

Verifica que tu cuenta tenga los roles necesarios:

```bash
gcloud projects get-iam-policy PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:YOUR_EMAIL"
```

Roles necesarios:

- `roles/owner` o
- `roles/resourcemanager.projectIamAdmin`
- `roles/iam.serviceAccountAdmin`
- `roles/iam.workloadIdentityPoolAdmin`

### Error: "Bucket already exists"

Si el bucket ya existe, los scripts lo detectarán y continuarán sin problemas.

### Error en GitHub Actions: "Failed to authenticate"

1. Verifica que los secrets estén configurados correctamente
2. Verifica que la variable `GCP_CONFIGURED=true` esté creada
3. Verifica que el repositorio en OIDC sea el correcto (`heggar/adyela`)

## 📚 Documentación Adicional

- [GCP Setup Completo](./docs/deployment/gcp-setup.md)
- [Architecture Validation](./docs/deployment/architecture-validation.md)
- [Workflows Documentation](./.github/workflows/README.md)

## 🎉 Siguiente paso

Una vez completada la configuración:

1. Merge el PR actual
2. Deploy a staging se ejecutará automáticamente
3. Revisa los logs en: https://github.com/heggar/adyela/actions

## 💡 Tips

- **Usa `gcloud config configurations`** para manejar múltiples proyectos:

  ```bash
  gcloud config configurations create staging
  gcloud config configurations create production
  gcloud config configurations activate staging
  ```

- **Monitorea costos diariamente:**

  ```bash
  ./scripts/check-daily-costs.sh adyela-staging
  ./scripts/check-daily-costs.sh adyela-production
  ```

- **Backup de configuración:**
  El archivo `.gcp-config` contiene tu configuración. NO lo subas a git (ya está en .gitignore).

---

**Tiempo total estimado:** 15-20 minutos

**¿Necesitas ayuda?** Revisa la documentación completa en `docs/deployment/gcp-setup.md`
