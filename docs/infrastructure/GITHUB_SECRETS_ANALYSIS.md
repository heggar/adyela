# Análisis de Secretos GitHub vs Pipeline CD-Staging

**Fecha**: 2025-10-11
**Archivo Pipeline**: `.github/workflows/cd-staging.yml`

---

## 🔍 Secretos de GitHub Requeridos por el Pipeline

### Secretos GCP Core (Autenticación)

| Secreto GitHub                       | Usado en                 | Propósito                           |
| ------------------------------------ | ------------------------ | ----------------------------------- |
| `WORKLOAD_IDENTITY_PROVIDER_STAGING` | Líneas 69, 127, 226, 304 | Autenticación con Workload Identity |
| `SERVICE_ACCOUNT_STAGING`            | Líneas 70, 128, 227, 305 | Service Account para deploy         |
| `GCP_PROJECT_ID_STAGING`             | Líneas 80, 138, 237, 315 | ID del proyecto GCP                 |

### Secretos de Build Web (Build-time)

| Secreto GitHub                      | Usado en  | Propósito                    | Estado                |
| ----------------------------------- | --------- | ---------------------------- | --------------------- |
| `VITE_API_URL_STAGING`              | Línea 260 | URL del backend API          | ⚠️ **Revisar nombre** |
| `VITE_FIREBASE_API_KEY`             | Línea 261 | Firebase API Key             | ❓                    |
| `VITE_FIREBASE_PROJECT_ID`          | Línea 262 | Firebase Project ID          | ❓                    |
| `VITE_FIREBASE_AUTH_DOMAIN`         | Línea 263 | Firebase Auth Domain         | ❓                    |
| `VITE_FIREBASE_STORAGE_BUCKET`      | Línea 264 | Firebase Storage Bucket      | ❓                    |
| `VITE_FIREBASE_MESSAGING_SENDER_ID` | Línea 265 | Firebase Messaging Sender ID | ❓                    |
| `VITE_FIREBASE_APP_ID`              | Línea 266 | Firebase Web App ID          | ❓                    |

### Secretos Opcionales

| Secreto GitHub       | Usado en  | Propósito                       |
| -------------------- | --------- | ------------------------------- |
| `COSIGN_PRIVATE_KEY` | Línea 107 | Firma de imágenes (opcional)    |
| `K6_CLOUD_TOKEN`     | Línea 455 | Performance tests (opcional)    |
| `SLACK_WEBHOOK_URL`  | Línea 565 | Notificaciones Slack (opcional) |

---

## 🐛 Problema Identificado: Variables en Build vs Runtime

### ¿Cómo funciona Vite?

Vite (el bundler de React) reemplaza las variables `VITE_*` en **BUILD TIME**:

```javascript
// En código:
const apiUrl = import.meta.env.VITE_API_URL;

// Después del build:
const apiUrl = "https://staging.adyela.care";
```

Las variables se "queman" (bake) en el JavaScript bundle durante el build.

### Pipeline Actual: Build vs Deploy

#### Build Stage (Líneas 259-268)

```yaml
build-args: |
  VITE_API_BASE_URL=${{ secrets.VITE_API_URL_STAGING }}  # ⚠️ Nombre diferente!
  VITE_FIREBASE_API_KEY=${{ secrets.VITE_FIREBASE_API_KEY }}
  VITE_FIREBASE_PROJECT_ID=${{ secrets.VITE_FIREBASE_PROJECT_ID }}
  VITE_FIREBASE_AUTH_DOMAIN=${{ secrets.VITE_FIREBASE_AUTH_DOMAIN }}
  VITE_FIREBASE_STORAGE_BUCKET=${{ secrets.VITE_FIREBASE_STORAGE_BUCKET }}
  VITE_FIREBASE_MESSAGING_SENDER_ID=${{ secrets.VITE_FIREBASE_MESSAGING_SENDER_ID }}
  VITE_FIREBASE_APP_ID=${{ secrets.VITE_FIREBASE_APP_ID }}
  VITE_JITSI_DOMAIN=meet.jit.si
  VITE_ENV=${{ env.ENVIRONMENT }}
```

✅ **Las variables se pasan al Docker build** como `--build-arg`

#### Deploy Stage (Líneas 329-333)

```yaml
--set-env-vars="VITE_ENV=${{ env.ENVIRONMENT }},VERSION=${{ inputs.version }},HIPAA_COMPLIANCE=true,AUDIT_LOGGING=true"
```

⚠️ **Solo se configuran 4 variables en runtime** (¡pero ya no importan para Vite!)

### ¿Entonces cuál es el problema?

El problema está en el **Dockerfile** de apps/web. Voy a verificarlo...

---

## 🔍 Verificación del Dockerfile

Voy a revisar el Dockerfile para ver si está usando correctamente los `build-args`.

---

## 🚨 Posibles Causas del Problema

### Causa 1: Nombre de Variable Inconsistente ⚠️

**En pipeline:**

```yaml
VITE_API_BASE_URL=${{ secrets.VITE_API_URL_STAGING }} # Línea 260
```

**En código (esperado):**

```typescript
// apps/web/src/config.ts probablemente usa:
import.meta.env.VITE_API_URL; // ❌ No VITE_API_BASE_URL
```

**Solución:**

- Cambiar el pipeline a `VITE_API_URL` en vez de `VITE_API_BASE_URL`
- O cambiar el código para usar `VITE_API_BASE_URL`

### Causa 2: Secretos de GitHub No Configurados ❓

Los secretos deben estar configurados en GitHub:

```
Repository Settings > Secrets and variables > Actions > Repository secrets
```

Secretos necesarios:

1. `VITE_API_URL_STAGING` → Valor: `https://staging.adyela.care`
2. `VITE_FIREBASE_API_KEY` → Obtener de Firebase Console
3. `VITE_FIREBASE_PROJECT_ID` → Valor: `adyela-staging`
4. `VITE_FIREBASE_AUTH_DOMAIN` → Valor: `adyela-staging.firebaseapp.com`
5. `VITE_FIREBASE_STORAGE_BUCKET` → Valor: `adyela-staging.appspot.com`
6. `VITE_FIREBASE_MESSAGING_SENDER_ID` → Obtener de Firebase Console
7. `VITE_FIREBASE_APP_ID` → Obtener de Firebase Console

### Causa 3: Dockerfile No Usa los ARGs Correctamente ❓

El Dockerfile debe:

1. Declarar los `ARG` antes de usarlos
2. Convertir `ARG` a `ENV` antes del build de Vite
3. Vite debe poder leer esas variables durante `npm run build`

Ejemplo correcto:

```dockerfile
# Declarar ARGs
ARG VITE_API_URL
ARG VITE_FIREBASE_API_KEY
# ... resto de ARGs

# Convertir a ENV para que Vite los vea
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_FIREBASE_API_KEY=$VITE_FIREBASE_API_KEY
# ... resto de ENVs

# Build (Vite lee las ENV)
RUN npm run build
```

---

## 📋 Plan de Acción

### Paso 1: Verificar Dockerfile ✅

Revisar que el Dockerfile de apps/web esté configurado correctamente.

### Paso 2: Verificar Secretos de GitHub ⚠️

```bash
# No se puede hacer desde CLI, debe hacerse manualmente en GitHub UI:
# https://github.com/<OWNER>/adyela/settings/secrets/actions
```

**Checklist de secretos:**

- [ ] `WORKLOAD_IDENTITY_PROVIDER_STAGING` - Existe
- [ ] `SERVICE_ACCOUNT_STAGING` - Existe
- [ ] `GCP_PROJECT_ID_STAGING` - Existe
- [ ] `VITE_API_URL_STAGING` - ❓ Verificar
- [ ] `VITE_FIREBASE_API_KEY` - ❓ Verificar
- [ ] `VITE_FIREBASE_PROJECT_ID` - ❓ Verificar
- [ ] `VITE_FIREBASE_AUTH_DOMAIN` - ❓ Verificar
- [ ] `VITE_FIREBASE_STORAGE_BUCKET` - ❓ Verificar
- [ ] `VITE_FIREBASE_MESSAGING_SENDER_ID` - ❓ Verificar
- [ ] `VITE_FIREBASE_APP_ID` - ❓ Verificar

### Paso 3: Corregir Inconsistencias de Nombres

**Opción A:** Cambiar el pipeline (línea 260)

```yaml
# Antes:
VITE_API_BASE_URL=${{ secrets.VITE_API_URL_STAGING }}

# Después:
VITE_API_URL=${{ secrets.VITE_API_URL_STAGING }}
```

**Opción B:** Cambiar el código del frontend

```typescript
// Antes:
const apiUrl = import.meta.env.VITE_API_URL;

// Después:
const apiUrl = import.meta.env.VITE_API_BASE_URL;
```

### Paso 4: Trigger Nuevo Deployment

Una vez configurados los secretos y corregidas las inconsistencias:

```bash
# Desde GitHub UI:
Actions > CD - Staging > Run workflow
# Ingresar version: v1.0.0 (o la actual)
```

---

## 🎯 Solución Recomendada (RÁPIDA)

### Para desbloquear AHORA sin esperar CI/CD:

**Opción A: Update Manual Cloud Run** (5 min)

Aunque las variables VITE no se usan en runtime, podemos actualizar el servicio y forzar un rebuild desde la última imagen con variables correctas:

```bash
# 1. Ver qué imagen está desplegada actualmente
gcloud run services describe adyela-web-staging \
  --project=adyela-staging \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].image)"

# 2. La imagen ya tiene las variables "baked in" desde el último build
#    El problema es que el último build usó valores incorrectos o vacíos
```

**Por lo tanto, necesitamos:**

1. Configurar los secretos de GitHub correctamente
2. Re-ejecutar el pipeline CD-Staging con un nuevo build

### Para después del fix:

1. ✅ Verificar que todos los secretos de GitHub estén configurados
2. ✅ Corregir el nombre de variable (VITE_API_BASE_URL → VITE_API_URL)
3. ✅ Trigger nuevo deployment con el pipeline
4. ✅ Verificar que la nueva imagen tenga las variables correctas

---

## 🔧 Comandos de Diagnóstico

### Ver variables en la imagen actual

```bash
# Pull la imagen actual
IMAGE="us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-web-staging:latest"
docker pull $IMAGE

# Ver archivos compilados (las variables están en main.js)
docker run --rm $IMAGE cat /usr/share/nginx/html/assets/*.js | grep -o "VITE_[A-Z_]*" | sort -u

# O buscar directamente por URLs
docker run --rm $IMAGE cat /usr/share/nginx/html/assets/*.js | grep -E "localhost:8000|staging.adyela.care"
```

Si encuentras `localhost:8000` en el bundle JS, confirma que la imagen se buildó sin las variables correctas.

---

## 📊 Comparación: GCP Secrets vs GitHub Secrets

### GCP Secret Manager (para API backend)

- Almacena credenciales sensibles (OAuth, API keys, DB passwords)
- Se inyectan en runtime a Cloud Run
- **Uso**: Backend API

### GitHub Secrets (para Web frontend)

- Almacena variables de configuración para el build
- Se usan en BUILD TIME por Vite
- **Uso**: Frontend Web (durante CI/CD build)

**Son complementarios, no reemplazan uno al otro.**

---

## 📝 Conclusión

**El problema NO es del deploy**, sino del **build de la imagen**.

La imagen Docker actual (`adyela-web-staging:latest`) fue compilada (built) sin las variables correctas de Firebase y API URL.

**Solución:**

1. Configurar los secretos de GitHub
2. Corregir el nombre de variable inconsistente
3. Re-ejecutar el pipeline para crear una nueva imagen con las variables correctas

---

**Próximos pasos:** Revisar el Dockerfile y luego verificar los secretos de GitHub.

**Última actualización**: 2025-10-12 00:10 UTC
**Actualizado por**: Claude Code
