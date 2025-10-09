# 🚀 Próximos Pasos para Deployment a Staging

## ✅ Completado

- ✅ **Secretos de GitHub configurados** (con valores REALES de Firebase)
- ✅ **Tag v1.0.0 creado**
- ✅ **Scripts de configuración listos**
- ✅ **Credenciales de Firebase obtenidas y configuradas**

### Secretos de GitHub Configurados ✅

```
✅ VITE_FIREBASE_API_KEY (AIzaSyAn9D_DbF6VecXq82q7RfHgqBzIG-R_-ts)
✅ VITE_FIREBASE_AUTH_DOMAIN (adyela-staging.firebaseapp.com)
✅ VITE_FIREBASE_PROJECT_ID (adyela-staging)
✅ VITE_FIREBASE_STORAGE_BUCKET (adyela-staging.firebasestorage.app)
✅ VITE_FIREBASE_MESSAGING_SENDER_ID (717907307897)
✅ VITE_FIREBASE_APP_ID (1:717907307897:web:65ffed808faffb36c213a8)
⚠️  VITE_API_URL_STAGING (placeholder - se actualizará después del deployment)
```

## ⚠️ ADVERTENCIA: Google Analytics Habilitado

Tu proyecto Firebase tiene Google Analytics habilitado (`measurementId: G-J0DJS84V8G`).

**PROBLEMA:** Google Analytics NO es HIPAA compliant y puede causar violaciones legales si se envía PHI.

**Recomendación:** Desactivar Google Analytics. Ver `docs/GOOGLE_ANALYTICS_IMPLICATIONS.md`

## ⏳ Pendiente: Autenticación de gcloud y Secretos de GCP

Hay un problema con la autenticación de gcloud. Necesitas ejecutar:

```bash
gcloud auth login
gcloud auth application-default login
```

## 📋 Tareas Pendientes

### 1. Configurar Secretos de GCP Secret Manager

Ejecuta manualmente este script:

```bash
./scripts/setup-gcp-secrets.sh
```

O ejecuta estos comandos:

```bash
# 1. Autenticarse
gcloud auth login
gcloud config set project adyela-staging

# 2. Habilitar Secret Manager API
gcloud services enable secretmanager.googleapis.com

# 3. Crear API Secret Key
echo -n "1786c41493658800373afd6c3dbdd6a4d791fb2b1567acab119d0980fed9a0b1" | \
gcloud secrets create api-secret-key \
  --project=adyela-staging \
  --data-file=- \
  --replication-policy=automatic \
  --labels=environment=staging,app=adyela-api

# 4. Crear Firebase Project ID
echo -n "adyela-staging" | \
gcloud secrets create firebase-project-id \
  --project=adyela-staging \
  --data-file=- \
  --replication-policy=automatic \
  --labels=environment=staging,app=adyela-api

# 5. Verificar secretos
gcloud secrets list --project=adyela-staging
```

### 2. Actualizar Secretos de Firebase en GitHub

Los secretos de GitHub están configurados con **valores placeholder**. Necesitas actualizarlos con los valores reales de Firebase Console:

**Ve a:** https://console.firebase.google.com/project/adyela-staging/settings/general

**Si no tienes una app web:**

1. Click en el icono web `</>`
2. Nombra tu app: "Adyela Web Staging"
3. NO marques "Firebase Hosting"
4. Click "Register app"
5. Copia la configuración

**Actualiza los secretos:**

```bash
# Reemplaza estos valores con los reales de Firebase Console
gh secret set VITE_FIREBASE_API_KEY -b "AIzaSy_TU_API_KEY_REAL"
gh secret set VITE_FIREBASE_MESSAGING_SENDER_ID -b "123456789012"
gh secret set VITE_FIREBASE_APP_ID -b "1:123456789012:web:abc123def456"
```

### 3. Ejecutar Primer Deployment (Backend Only)

Una vez que los secretos de GCP estén configurados:

```bash
gh workflow run cd-staging.yml \
  --ref main \
  -f version=v1.0.0 \
  -f skip_e2e=true
```

**Nota:** El build del frontend fallará porque los secretos de Firebase son placeholders.

### 4. Obtener API URL y Actualizar Secret

Después de que el backend se despliegue:

```bash
# Obtener la URL del API
API_URL=$(gcloud run services describe adyela-api-staging \
  --region us-central1 \
  --project adyela-staging \
  --format='value(status.url)')

echo "API URL: $API_URL"

# Actualizar el secreto
gh secret set VITE_API_URL_STAGING -b "$API_URL"
```

### 5. Actualizar Secretos de Firebase con Valores Reales

Después de obtener los valores de Firebase Console:

```bash
gh secret set VITE_FIREBASE_API_KEY -b "AIzaSy..."
gh secret set VITE_FIREBASE_MESSAGING_SENDER_ID -b "123456789"
gh secret set VITE_FIREBASE_APP_ID -b "1:123...:web:abc..."
```

### 6. Ejecutar Deployment Completo

Con todos los secretos configurados correctamente:

```bash
gh workflow run cd-staging.yml \
  --ref main \
  -f version=v1.0.0 \
  -f skip_e2e=true
```

## 📊 Secretos Configurados

### GitHub Secrets ✅

```
✅ GCP_PROJECT_ID_STAGING
✅ SERVICE_ACCOUNT_STAGING
✅ WORKLOAD_IDENTITY_PROVIDER_STAGING
✅ VITE_FIREBASE_PROJECT_ID (adyela-staging)
✅ VITE_FIREBASE_AUTH_DOMAIN (adyela-staging.firebaseapp.com)
✅ VITE_FIREBASE_STORAGE_BUCKET (adyela-staging.appspot.com)
⚠️  VITE_FIREBASE_API_KEY (PLACEHOLDER - actualizar)
⚠️  VITE_FIREBASE_MESSAGING_SENDER_ID (PLACEHOLDER - actualizar)
⚠️  VITE_FIREBASE_APP_ID (PLACEHOLDER - actualizar)
⚠️  VITE_API_URL_STAGING (PLACEHOLDER - actualizar después del deployment)
```

### GCP Secret Manager ⏳

```
⏳ api-secret-key (pendiente de crear)
⏳ firebase-project-id (pendiente de crear)
```

## 🔍 Verificar Deployment

Una vez completado:

```bash
# Ver workflows
gh run list --workflow=cd-staging.yml --limit 3

# Ver logs
gh run watch

# Probar API
API_URL=$(gcloud run services describe adyela-api-staging \
  --region us-central1 \
  --project adyela-staging \
  --format='value(status.url)')

curl $API_URL/health
```

## 📚 Documentación

- [Staging Deployment Guide](docs/STAGING_DEPLOYMENT_GUIDE.md)
- [GCP Setup Guide](docs/deployment/gcp-setup.md)

---

**Generado el:** 2025-10-07
**API Secret Key generada:** 1786c41493658800373afd6c3dbdd6a4d791fb2b1567acab119d0980fed9a0b1
