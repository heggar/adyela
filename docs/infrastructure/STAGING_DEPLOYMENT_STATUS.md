# Staging Deployment - Estado Actual y Análisis

**Fecha**: 2025-10-11 **Environment**: Staging **Dominio**:
https://staging.adyela.care

---

## 📊 Estado Actual de la Infraestructura

### ✅ Recursos Desplegados

#### 1. Cloud Run Services

| Servicio               | URL Interna                                        | Revisión  | Estado   |
| ---------------------- | -------------------------------------------------- | --------- | -------- |
| **adyela-api-staging** | https://adyela-api-staging-vrqu3jr6aa-uc.a.run.app | 00052-6mw | ✅ Ready |
| **adyela-web-staging** | https://adyela-web-staging-vrqu3jr6aa-uc.a.run.app | 00036-g9x | ✅ Ready |

#### 2. Load Balancer

| Componente          | Configuración              | Estado                     |
| ------------------- | -------------------------- | -------------------------- |
| **IP Pública**      | 34.96.108.162              | ✅ Activo                  |
| **Dominio**         | staging.adyela.care        | ✅ Configurado             |
| **URL Map**         | adyela-staging-lb          | ✅ Activo                  |
| **Default Backend** | adyela-staging-web-backend | ✅ Funcionando             |
| **Backend API**     | adyela-staging-api-backend | ⚠️ Existe pero no enrutado |
| **Backend Web**     | adyela-staging-web-backend | ✅ Enrutado                |

#### 3. Secretos en Secret Manager

| Categoría             | Secretos                                                                | Estado           |
| --------------------- | ----------------------------------------------------------------------- | ---------------- |
| **API Core**          | api-secret-key, jwt-secret-key, encryption-key                          | ✅ Configurados  |
| **Database**          | database-connection-string                                              | ✅ Configurado   |
| **Firebase Admin**    | firebase-admin-key, firebase-project-id                                 | ✅ Configurados  |
| **OAuth Providers**   | google, microsoft, facebook, apple (client-id + secret)                 | ✅ Configurados  |
| **External Services** | smtp-credentials, external-api-keys                                     | ✅ Configurados  |
| **Firebase Web**      | firebase-web-api-key, firebase-messaging-sender-id, firebase-web-app-id | ❌ **FALTANTES** |

---

## 🐛 Problema Actual: Redirect a localhost

### Causa Raíz

El servicio **adyela-web-staging** tiene configuradas solo 4 variables de
ambiente:

```yaml
VITE_ENV=staging HIPAA_COMPLIANCE=true AUDIT_LOGGING=true VERSION=latest
```

**Faltan variables críticas:**

- ❌ `VITE_API_URL` → Por defecto usa `http://localhost:8000`
- ❌ `VITE_FIREBASE_API_KEY`
- ❌ `VITE_FIREBASE_PROJECT_ID`
- ❌ `VITE_FIREBASE_AUTH_DOMAIN`
- ❌ `VITE_FIREBASE_STORAGE_BUCKET`
- ❌ `VITE_FIREBASE_MESSAGING_SENDER_ID`
- ❌ `VITE_FIREBASE_APP_ID`
- ❌ `VITE_JITSI_DOMAIN`

### Impacto

1. **OAuth Redirect**: El frontend intenta hacer POST a
   `http://localhost:8000/api/v1/auth/sync` en lugar de
   `https://staging.adyela.care/api/v1/auth/sync`
2. **CORS Error**: Aunque se arreglara el redirect, el backend rechazaría la
   petición por CORS (ya corregido en código pero no desplegado)
3. **Firebase Init**: El frontend no puede inicializar Firebase correctamente

---

## 🎯 Opciones de Solución

### Opción A: Update Manual del Servicio Web (RÁPIDO - 5 minutos)

**Pros:**

- ✅ Solución inmediata sin rebuild
- ✅ No requiere CI/CD
- ✅ No requiere crear secretos Firebase Web primero

**Contras:**

- ⚠️ No persistente (se perderá en próximo deploy con Terraform)
- ⚠️ Variables hardcodeadas vs. secretos

**Pasos:**

```bash
# 1. Actualizar variables de ambiente directamente
gcloud run services update adyela-web-staging \
  --project=adyela-staging \
  --region=us-central1 \
  --set-env-vars="VITE_API_URL=https://staging.adyela.care,\
VITE_FIREBASE_PROJECT_ID=adyela-staging,\
VITE_FIREBASE_AUTH_DOMAIN=adyela-staging.firebaseapp.com,\
VITE_FIREBASE_STORAGE_BUCKET=adyela-staging.appspot.com,\
VITE_FIREBASE_API_KEY=<YOUR_API_KEY>,\
VITE_FIREBASE_MESSAGING_SENDER_ID=<YOUR_SENDER_ID>,\
VITE_FIREBASE_APP_ID=<YOUR_APP_ID>,\
VITE_JITSI_DOMAIN=meet.jit.si"

# 2. Esperar deployment (~2 minutos)
# 3. Probar en https://staging.adyela.care/login
```

**Obtener valores de Firebase:**

```bash
# Ir a: https://console.firebase.google.com/project/adyela-staging/settings/general
# Sección: "Your apps" > Web app > Config
```

---

### Opción B: Terraform Deploy Completo (RECOMENDADO - 20 minutos)

**Pros:**

- ✅ Solución persistente
- ✅ Variables desde Secret Manager (más seguro)
- ✅ Configuración versionada en Git
- ✅ Incluye Identity Platform deployment

**Contras:**

- ⏱️ Requiere crear secretos Firebase Web primero
- ⏱️ Requiere terraform apply completo
- ⚠️ Puede fallar por permisos Identity Platform API

**Pasos:**

```bash
# 1. Crear secretos de Firebase Web (interactivo)
bash scripts/setup/setup-firebase-web-secrets.sh

# 2. Aplicar Terraform (incluye Identity Platform + Cloud Run update)
cd infra/environments/staging
terraform apply

# 3. Verificar deployment
gcloud run services describe adyela-web-staging \
  --project=adyela-staging \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"
```

**Tiempo estimado:** 15-20 minutos

---

### Opción C: CI/CD Rebuild (MÁS LENTO - 30+ minutos)

**Pros:**

- ✅ Proceso completo de CI/CD
- ✅ Testing automático
- ✅ Build desde código

**Contras:**

- ⏱️ Más lento
- ⚠️ Requiere commit + push
- ⚠️ Puede fallar si hay otros issues

**Pasos:**

```bash
# 1. Crear archivo .env.staging en apps/web/
cat > apps/web/.env.staging <<EOF
VITE_API_URL=https://staging.adyela.care
VITE_FIREBASE_PROJECT_ID=adyela-staging
VITE_FIREBASE_AUTH_DOMAIN=adyela-staging.firebaseapp.com
VITE_FIREBASE_STORAGE_BUCKET=adyela-staging.appspot.com
VITE_FIREBASE_API_KEY=<YOUR_API_KEY>
VITE_FIREBASE_MESSAGING_SENDER_ID=<YOUR_SENDER_ID>
VITE_FIREBASE_APP_ID=<YOUR_APP_ID>
VITE_JITSI_DOMAIN=meet.jit.si
VITE_ENV=staging
EOF

# 2. Build con variables correctas
cd apps/web
npm run build:staging

# 3. Tag y push imagen a Artifact Registry
# (esto normalmente lo hace CI/CD)

# 4. Actualizar Cloud Run service con nueva imagen
```

---

## 🎬 Recomendación

### Para AHORA (desbloquear OAuth):

**Opción A (Update manual)** - 5 minutos

- Actualiza solo las variables sin rebuild
- Permite probar OAuth inmediatamente

### Para DESPUÉS (infraestructura correcta):

**Opción B (Terraform)** - cuando tengas tiempo

- Persiste la configuración
- Despliega Identity Platform
- Usa Secret Manager correctamente

---

## 📝 Checklist de Validación Post-Fix

### 1. Variables de Ambiente

```bash
# Verificar que todas las variables están configuradas
gcloud run services describe adyela-web-staging \
  --project=adyela-staging \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)" | grep VITE_
```

Debe incluir:

- ✅ VITE_API_URL=https://staging.adyela.care
- ✅ VITE_FIREBASE_PROJECT_ID=adyela-staging
- ✅ VITE_FIREBASE_AUTH_DOMAIN=adyela-staging.firebaseapp.com
- ✅ VITE_FIREBASE_API_KEY=<valor>
- ✅ VITE_FIREBASE_APP_ID=<valor>
- ✅ VITE_FIREBASE_MESSAGING_SENDER_ID=<valor>
- ✅ VITE_FIREBASE_STORAGE_BUCKET=adyela-staging.appspot.com
- ✅ VITE_JITSI_DOMAIN=meet.jit.si

### 2. Prueba OAuth

1. Abrir DevTools en navegador
2. Ir a https://staging.adyela.care/login
3. Click en "Continue with Google"
4. Verificar en Network tab:
   - POST a `https://staging.adyela.care/api/v1/auth/sync` (NO localhost)
   - Response 200 o 201
   - Cookie de sesión configurada

### 3. Verificar Firebase

1. Abrir Console en DevTools
2. Verificar que no hay errores de Firebase initialization
3. Verificar que `firebase.auth().currentUser` tiene datos después del login

---

## 🔧 Comandos Útiles

### Ver logs en tiempo real

```bash
# Web service logs
gcloud run services logs tail adyela-web-staging \
  --project=adyela-staging \
  --region=us-central1

# API service logs
gcloud run services logs tail adyela-api-staging \
  --project=adyela-staging \
  --region=us-central1
```

### Ver última revision

```bash
gcloud run revisions list \
  --service=adyela-web-staging \
  --project=adyela-staging \
  --region=us-central1 \
  --limit=5
```

### Rollback si hay problemas

```bash
# Listar revisiones
gcloud run revisions list --service=adyela-web-staging \
  --project=adyela-staging --region=us-central1

# Rollback a revisión específica
gcloud run services update-traffic adyela-web-staging \
  --to-revisions=<REVISION_NAME>=100 \
  --project=adyela-staging \
  --region=us-central1
```

---

## 📊 Diagrama de Flujo OAuth Actual vs. Esperado

### ❌ Flujo Actual (BROKEN)

```
User en staging.adyela.care
    ↓
Click "Login with Google"
    ↓
Google OAuth → Redirect a staging.adyela.care
    ↓
Frontend intenta POST /api/v1/auth/sync
    ↓
VITE_API_URL = undefined → usa default
    ↓
POST http://localhost:8000/api/v1/auth/sync
    ↓
❌ CORS Error / Connection Refused
```

### ✅ Flujo Esperado (FIXED)

```
User en staging.adyela.care
    ↓
Click "Login with Google"
    ↓
Google OAuth → Redirect a staging.adyela.care
    ↓
Frontend intenta POST /api/v1/auth/sync
    ↓
VITE_API_URL = https://staging.adyela.care
    ↓
POST https://staging.adyela.care/api/v1/auth/sync
    ↓
Load Balancer → adyela-api-staging
    ↓
✅ API procesa auth y devuelve token
```

---

## 🚀 Estado Identity Platform

**Pendiente deployment** debido a:

1. ⚠️ Error de permisos: `identityplatform.googleapis.com` requiere permisos
   elevados
2. ⚠️ Error VPC connector format en Cloud Run
3. ⚠️ Restricción de creación de Service Account Keys

**Alternativa:** Habilitar desde Firebase Console (ver
`IDENTITY_PLATFORM_QUICKSTART.md`)

---

**Última actualización**: 2025-10-11 23:55 UTC **Actualizado por**: Claude Code
**Versión**: 1.0.0
