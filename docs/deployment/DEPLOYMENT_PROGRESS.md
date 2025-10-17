# 🚀 Deployment Progress - Staging Environment

**Fecha**: 2025-10-07 **Branch**: `feat/api-backend` **Objetivo**: Desplegar
Adyela API y Web a staging en GCP

---

## ✅ Completado

### 1. Configuración de Secretos

- ✅ **Firebase Secrets** - Todos configurados en GitHub:
  - `VITE_FIREBASE_API_KEY`
  - `VITE_FIREBASE_PROJECT_ID`
  - `VITE_FIREBASE_AUTH_DOMAIN`
  - `VITE_FIREBASE_STORAGE_BUCKET`
  - `VITE_FIREBASE_MESSAGING_SENDER_ID`
  - `VITE_FIREBASE_APP_ID`
  - `VITE_FIREBASE_MEASUREMENT_ID`

- ✅ **GCP Secret Manager** - Secretos creados:
  - `api-secret-key` (auto-generado)
  - `firebase-project-id` (adyela-staging)

### 2. Correcciones de Workflow

- ✅ **Error de pnpm**: Actualizado de `version: 9` a `version: 9.15.0`
- ✅ **Artifact Registry**: Creado repositorio `adyela` en us-central1
- ✅ **Secrets en outputs**: Cambiado de pasar `image-tag` completo a solo
  `image-version`
- ✅ **Labels GCP**: Convertir `v1.0.0` → `v1-0-0` (puntos no permitidos)
- ✅ **CPU/Concurrency**: Aumentado de 0.5 CPU a 1 CPU (requerido con
  concurrency > 1)
- ✅ **Memoria**: Aumentada de 256Mi a 512Mi

### 3. Problemas Resueltos

| #   | Error                                                 | Solución                                             | Commit                                  |
| --- | ----------------------------------------------------- | ---------------------------------------------------- | --------------------------------------- |
| 1   | `Unrecognized named-value: 'secrets'`                 | Cambiar `if: secrets...` → `continue-on-error: true` | Previo                                  |
| 2   | `Multiple versions of pnpm`                           | Actualizar workflows a pnpm 9.15.0                   | `fix: update pnpm version`              |
| 3   | `Repository "adyela" not found`                       | Crear Artifact Registry con script                   | Manual (gcloud)                         |
| 4   | `argument --image: expected one argument`             | Pasar solo version, reconstruir tag en deploy job    | `fix: pass only version`                |
| 5   | `Label value 'v1.0.0' violates format`                | Convertir puntos a guiones con `tr '.' '-'`          | `fix: convert version to GCP-compliant` |
| 6   | `Total cpu < 1 is not supported with concurrency > 1` | Aumentar CPU a 1, memoria a 512Mi                    | `fix: increase CPU to 1`                |

---

## ⚠️ Pendiente

### Último Error (Run #18300921730)

**Status**: Deployment fallando **Último commit**: `799a98f` **Run ID**:
https://github.com/heggar/adyela/actions/runs/18300921730

**Acción para mañana**:

1. Verificar logs del último run:
   ```bash
   gh run view 18300921730 --log | grep -A 15 "ERROR:"
   ```
2. Identificar el error específico
3. Aplicar la corrección necesaria
4. Ejecutar workflow de nuevo

### Configuración Pendiente

- ⏳ **VITE_API_URL_STAGING**: Se configurará después del primer deploy exitoso
  del backend
- ⏳ **Segundo deployment del frontend**: Después de obtener API URL

---

## 📊 Estado de Jobs

### Build API Docker Image

- ✅ **Build**: Exitoso
- ✅ **Push**: Exitoso
- ✅ **Image**:
  `us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-api-staging:v1.0.0`
- ✅ **Digest**: Disponible

### Deploy API to Cloud Run

- ❌ **Status**: Fallando (último intento)
- 📝 **Configuración actual**:
  ```yaml
  --min-instances=0 --max-instances=1 --memory=512Mi --cpu=1 --timeout=60s
  --concurrency=80 --port=8000
  ```

### Build Web Application

- ⏳ **Pendiente**: Necesita `VITE_API_URL_STAGING`

---

## 🔧 Recursos Creados en GCP

### Artifact Registry

```
Repository: us-central1-docker.pkg.dev/adyela-staging/adyela
Format: Docker
Location: us-central1
Status: Active
```

### Secret Manager

```
api-secret-key:latest          ✅ Active
firebase-project-id:latest     ✅ Active
```

### Cloud Run (Pendiente)

```
Service Name: adyela-api-staging
Region: us-central1
Status: ⏳ Pendiente creación exitosa
```

---

## 📝 Comandos Útiles

### Verificar último workflow

```bash
gh run list --workflow=cd-staging.yml --limit 5
```

### Ver detalles de un run

```bash
gh run view <RUN_ID> --log
```

### Ejecutar workflow manualmente

```bash
gh workflow run cd-staging.yml \
  --ref feat/api-backend \
  -f version=v1.0.0 \
  -f skip_e2e=true
```

### Verificar secretos de GitHub

```bash
gh secret list | grep -i "vite\|firebase\|gcp"
```

### Verificar secretos de GCP

```bash
gcloud secrets list --project adyela-staging
```

---

## 🎯 Próximos Pasos (Mañana)

1. ✅ **Revisar logs del último run** - Identificar error específico
2. ⚠️ **Corregir error de deployment** - Aplicar fix necesario
3. ⚠️ **Verificar deploy exitoso del backend** - Confirmar que Cloud Run
   funciona
4. ⚠️ **Obtener API URL** - Guardarla para siguiente paso
5. ⚠️ **Configurar VITE_API_URL_STAGING** - Para build del frontend
6. ⚠️ **Ejecutar segundo deployment** - Backend + Frontend completo
7. ⚠️ **Verificar health endpoint** - `curl <API_URL>/health`
8. ⚠️ **Verificar docs endpoint** - `curl <API_URL>/docs`

---

## 📚 Referencias

- **Workflow**: `.github/workflows/cd-staging.yml`
- **Deployment Guide**: `docs/STAGING_DEPLOYMENT_GUIDE.md`
- **Artifact Registry Script**: `scripts/create-artifact-registry.sh`
- **GCP Secrets Script**: `scripts/setup-gcp-secrets.sh`
- **Firebase Cost Analysis**: `docs/FIREBASE_COST_ESTIMATE.md`
- **Google Analytics Implications**: `docs/GOOGLE_ANALYTICS_IMPLICATIONS.md`

---

## 🔍 Debugging Tips

### Si el deploy falla por permisos:

```bash
# Verificar service account
gh secret get SERVICE_ACCOUNT_STAGING

# Verificar IAM roles
gcloud projects get-iam-policy adyela-staging \
  --flatten="bindings[].members" \
  --filter="bindings.members:SERVICE_ACCOUNT" \
  --format="table(bindings.role)"
```

### Si el deploy falla por secretos:

```bash
# Verificar que los secretos existen
gcloud secrets versions access latest --secret=api-secret-key
gcloud secrets versions access latest --secret=firebase-project-id

# Verificar permisos del service account
gcloud secrets get-iam-policy api-secret-key
```

### Si la imagen no se encuentra:

```bash
# Listar imágenes en Artifact Registry
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/adyela-staging/adyela
```

---

**Última actualización**: 2025-10-07 03:17 UTC **Estado**: En progreso - 80%
completado **Próxima sesión**: Resolver último error de deployment
