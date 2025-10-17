# 🚀 Guía de Deployment a Staging

Esta guía te ayudará a configurar y desplegar Adyela a staging por primera vez.

## 📋 Prerrequisitos

Antes de comenzar, asegúrate de tener:

- ✅ **gcloud CLI instalado y autenticado**

  ```bash
  gcloud auth login
  gcloud config set project adyela-staging
  ```

- ✅ **GitHub CLI configurado**

  ```bash
  gh auth login
  ```

- ✅ **Acceso a Firebase Console**
  - Ve a: https://console.firebase.google.com/project/adyela-staging

## 🔐 Configuración de Secretos

### Opción A: Script Automático (Recomendado)

Ejecuta el script maestro que configurará todo:

```bash
./scripts/setup-staging-deployment.sh
```

Este script:

1. ✅ Genera y configura secretos en GCP Secret Manager
2. ✅ Te pedirá las credenciales de Firebase
3. ✅ Configurará todos los secretos de GitHub

### Opción B: Configuración Manual

#### 1. Configurar Secretos de GCP Secret Manager

```bash
./scripts/setup-gcp-secrets.sh
```

Esto creará:

- `api-secret-key` - Clave secreta para la API (generada automáticamente)
- `firebase-project-id` - ID del proyecto Firebase

#### 2. Obtener Credenciales de Firebase

**Si NO tienes una app web en Firebase:**

1. Ve a:
   https://console.firebase.google.com/project/adyela-staging/settings/general
2. Scroll down a **"Your apps"**
3. Click en el icono web `</>`
4. Nombra tu app: **"Adyela Web Staging"**
5. NO marques "Firebase Hosting"
6. Click **"Register app"**
7. Copia la configuración

**Si YA tienes una app web:**

1. Ve a:
   https://console.firebase.google.com/project/adyela-staging/settings/general
2. Scroll down a **"Your apps"**
3. Selecciona tu app web
4. En **"SDK setup and configuration"**, selecciona **"Config"**
5. Copia los valores

Deberías ver algo como:

```javascript
const firebaseConfig = {
  apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
  authDomain: 'adyela-staging.firebaseapp.com',
  projectId: 'adyela-staging',
  storageBucket: 'adyela-staging.appspot.com',
  messagingSenderId: '123456789012',
  appId: '1:123456789012:web:abc123def456',
};
```

#### 3. Configurar Secretos de GitHub

```bash
./scripts/setup-firebase-secrets.sh
```

O manualmente:

```bash
# Firebase Configuration
gh secret set VITE_FIREBASE_API_KEY -b "AIzaSy..."
gh secret set VITE_FIREBASE_PROJECT_ID -b "adyela-staging"
gh secret set VITE_FIREBASE_AUTH_DOMAIN -b "adyela-staging.firebaseapp.com"
gh secret set VITE_FIREBASE_STORAGE_BUCKET -b "adyela-staging.appspot.com"
gh secret set VITE_FIREBASE_MESSAGING_SENDER_ID -b "123456789012"
gh secret set VITE_FIREBASE_APP_ID -b "1:123456789012:web:..."

# API URL (se obtendrá después del primer deployment del backend)
gh secret set VITE_API_URL_STAGING -b "https://adyela-api-staging-xxx.a.run.app"
```

## 🚀 Ejecutar Deployment

### Primera vez (sin API URL)

En el primer deployment, el frontend fallará porque no tenemos la API URL
todavía:

```bash
gh workflow run cd-staging.yml \
  --ref main \
  -f version=v1.0.0 \
  -f skip_e2e=true
```

El workflow:

1. ✅ Desplegará el **backend** exitosamente
2. ❌ Fallará en **build-web** (porque falta API URL)

### Obtener la API URL

Una vez que el backend se despliega, obtén la URL:

```bash
gcloud run services describe adyela-api-staging \
  --region us-central1 \
  --format='value(status.url)'
```

Configura el secreto:

```bash
gh secret set VITE_API_URL_STAGING -b "https://adyela-api-staging-xxx.a.run.app"
```

### Segundo Deployment (Completo)

Ahora ejecuta de nuevo el workflow:

```bash
gh workflow run cd-staging.yml \
  --ref main \
  -f version=v1.0.0 \
  -f skip_e2e=true
```

Esta vez:

1. ✅ Desplegará el **backend**
2. ✅ Desplegará el **frontend**
3. ⏭️ Se saltarán los tests E2E

## 📊 Monitorear Deployment

```bash
# Ver el workflow en ejecución
gh run watch

# Listar workflows recientes
gh run list --workflow=cd-staging.yml --limit 5

# Ver detalles de un run específico
gh run view <RUN_ID>
```

O ve a: https://github.com/heggar/adyela/actions/workflows/cd-staging.yml

## 🔍 Verificar Deployment

### Backend (API)

```bash
# Obtener URL
API_URL=$(gcloud run services describe adyela-api-staging \
  --region us-central1 \
  --format='value(status.url)')

# Probar health endpoint
curl $API_URL/health

# Ver docs
open $API_URL/docs
```

### Frontend (Web)

```bash
# Ver la URL configurada en el workflow
# Probablemente: https://staging.adyela.com o similar
```

## ❌ Troubleshooting

### Error: "Secret not found"

Verifica que todos los secretos están configurados:

```bash
# GitHub Secrets
gh secret list | grep -i "vite\|firebase"

# GCP Secrets
gcloud secrets list --project adyela-staging
```

### Error: "Permission denied"

Asegúrate de que el Service Account tenga permisos:

```bash
# Obtener el service account
SERVICE_ACCOUNT=$(gh secret get SERVICE_ACCOUNT_STAGING)

# Dar permisos de Secret Manager
gcloud projects add-iam-policy-binding adyela-staging \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor"
```

### Error: "Image build failed"

Revisa los logs del workflow y asegúrate de que:

- Docker está configurado correctamente
- El Dockerfile existe en `apps/api/`
- Las dependencias están correctas en `pyproject.toml`

## 📝 Próximos Pasos

Después de un deployment exitoso:

1. ✅ Configura el dominio personalizado (opcional)
2. ✅ Ejecuta los tests E2E
3. ✅ Configura monitoreo y alertas
4. ✅ Configura backups automáticos

## 🔗 Referencias

- [GCP Setup Guide](deployment/gcp-setup.md)
- [GitHub Actions Workflows](.github/workflows/)
- [Project Commands](PROJECT_COMMANDS_REFERENCE.md)

---

**Status**: En desarrollo **Última actualización**: 2025-10-06
