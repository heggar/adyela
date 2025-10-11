# Guía de Configuración OAuth

Esta guía explica cómo configurar la autenticación OAuth con Google, Facebook, Apple y Microsoft para la aplicación Adyela.

## Tabla de Contenidos

- [Configuración de Proveedores OAuth](#configuración-de-proveedores-oauth)
- [Configuración de Firebase](#configuración-de-firebase)
- [Variables de Entorno](#variables-de-entorno)
- [Testing Local](#testing-local)
- [Deploy a Staging](#deploy-a-staging)
- [Troubleshooting](#troubleshooting)

## Configuración de Proveedores OAuth

### 1. Google OAuth

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto o crea uno nuevo
3. Habilita la API de Google+ (si no está habilitada)
4. Ve a "Credenciales" > "Crear credenciales" > "ID de cliente OAuth 2.0"
5. Configura:
   - **Tipo de aplicación**: Aplicación web
   - **Nombre**: Adyela OAuth
   - **Orígenes JavaScript autorizados**:
     - `http://localhost:5173` (desarrollo)
     - `https://staging.adyela.care` (staging)
     - `https://adyela.care` (producción)
   - **URI de redirección autorizados**:
     - `http://localhost:9099/__/auth/handler` (desarrollo)
     - `https://staging.adyela.care/__/auth/handler` (staging)
     - `https://adyela.care/__/auth/handler` (producción)

### 2. Facebook OAuth

1. Ve a [Facebook Developers](https://developers.facebook.com/)
2. Crea una nueva aplicación
3. Agrega el producto "Facebook Login"
4. Configura:
   - **Dominios de la aplicación**:
     - `localhost` (desarrollo)
     - `staging.adyela.care` (staging)
     - `adyela.care` (producción)
   - **URI de redirección de OAuth válidos**:
     - `http://localhost:9099/__/auth/handler`
     - `https://staging.adyela.care/__/auth/handler`
     - `https://adyela.care/__/auth/handler`

### 3. Apple OAuth

1. Ve a [Apple Developer Console](https://developer.apple.com/)
2. Crea un nuevo App ID
3. Habilita "Sign In with Apple"
4. Crea un Service ID
5. Configura:
   - **Domains and Subdomains**:
     - `staging.adyela.care`
     - `adyela.care`
   - **Return URLs**:
     - `https://staging.adyela.care/__/auth/handler`
     - `https://adyela.care/__/auth/handler`

### 4. Microsoft OAuth

1. Ve a [Azure Portal](https://portal.azure.com/)
2. Registra una nueva aplicación
3. Configura:
   - **Redirect URIs**:
     - `http://localhost:9099/__/auth/handler`
     - `https://staging.adyela.care/__/auth/handler`
     - `https://adyela.care/__/auth/handler`
   - **API permissions**: User.Read (Microsoft Graph)

## Configuración de Firebase

### 1. Habilitar Proveedores OAuth

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a "Authentication" > "Sign-in method"
4. Habilita cada proveedor:
   - **Google**: Ingresa Client ID y Client Secret
   - **Facebook**: Ingresa App ID y App Secret
   - **Apple**: Ingresa Service ID, Team ID, Key ID y Private Key
   - **Microsoft**: Ingresa Client ID y Client Secret

### 2. Configurar Dominios Autorizados

En "Authentication" > "Settings" > "Authorized domains", agrega:

- `localhost` (desarrollo)
- `staging.adyela.care` (staging)
- `adyela.care` (producción)

## Variables de Entorno

### Desarrollo Local

Crea `apps/web/.env.local`:

```env
# Firebase Configuration
VITE_FIREBASE_API_KEY=your-api-key
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789
VITE_FIREBASE_APP_ID=1:123456789:web:abcdef

# API Configuration
VITE_API_BASE_URL=http://localhost:8000
```

### Staging/Producción

Configura en GCP Secret Manager:

```bash
# Google OAuth
gcloud secrets create oauth-google-client-id --data-file=- <<< "your-google-client-id"
gcloud secrets create oauth-google-client-secret --data-file=- <<< "your-google-client-secret"

# Facebook OAuth
gcloud secrets create oauth-facebook-app-id --data-file=- <<< "your-facebook-app-id"
gcloud secrets create oauth-facebook-app-secret --data-file=- <<< "your-facebook-app-secret"

# Apple OAuth
gcloud secrets create oauth-apple-client-id --data-file=- <<< "your-apple-service-id"
gcloud secrets create oauth-apple-client-secret --data-file=- <<< "your-apple-private-key"

# Microsoft OAuth
gcloud secrets create oauth-microsoft-client-id --data-file=- <<< "your-microsoft-client-id"
gcloud secrets create oauth-microsoft-client-secret --data-file=- <<< "your-microsoft-client-secret"
```

## Testing Local

### 1. Iniciar Firebase Emulator

```bash
firebase emulators:start --only auth,firestore
```

### 2. Ejecutar Script de Testing

```bash
./scripts/test-oauth-local.sh
```

### 3. Verificar Funcionamiento

1. Abre http://localhost:5173
2. Ve a la página de login
3. Prueba cada botón OAuth
4. Verifica en Firebase Emulator UI (http://localhost:4000) que se crean usuarios
5. Revisa logs del backend para confirmar sincronización

## Deploy a Staging

### 1. Actualizar Workflow CD-Staging

Agrega los nuevos secrets OAuth al workflow:

```yaml
--set-secrets="SECRET_KEY=api-secret-key,FIREBASE_PROJECT_ID=firebase-project-id,FIREBASE_ADMIN_KEY=firebase-admin-key,JWT_SECRET=jwt-secret-key,ENCRYPTION_KEY=encryption-key,DATABASE_URL=database-connection-string,SMTP_CREDENTIALS=smtp-credentials,EXTERNAL_API_KEYS=external-api-keys,OAUTH_GOOGLE_CLIENT_ID=oauth-google-client-id,OAUTH_GOOGLE_CLIENT_SECRET=oauth-google-client-secret,OAUTH_FACEBOOK_APP_ID=oauth-facebook-app-id,OAUTH_FACEBOOK_APP_SECRET=oauth-facebook-app-secret,OAUTH_APPLE_CLIENT_ID=oauth-apple-client-id,OAUTH_APPLE_CLIENT_SECRET=oauth-apple-client-secret,OAUTH_MICROSOFT_CLIENT_ID=oauth-microsoft-client-id,OAUTH_MICROSOFT_CLIENT_SECRET=oauth-microsoft-client-secret"
```

### 2. Configurar Firebase en Staging

1. Actualiza configuración de Firebase con credenciales reales
2. Configura dominios autorizados para staging
3. Habilita proveedores OAuth con credenciales de producción

### 3. Validar Deploy

1. Ejecuta workflow CD-Staging
2. Verifica que la aplicación esté accesible en staging.adyela.care
3. Prueba login OAuth en staging
4. Revisa logs de Cloud Run para confirmar funcionamiento

## Troubleshooting

### Problemas Comunes

#### 1. Error: "Invalid OAuth client"

**Causa**: Client ID incorrecto o dominio no autorizado
**Solución**:

- Verifica Client ID en Firebase Console
- Agrega dominio a dominios autorizados
- Confirma que el dominio coincide exactamente

#### 2. Error: "Redirect URI mismatch"

**Causa**: URI de redirección no configurado correctamente
**Solución**:

- Verifica URI de redirección en proveedor OAuth
- Debe incluir `/__/auth/handler` al final
- Confirma que el protocolo (http/https) sea correcto

#### 3. Error: "Firebase Auth Emulator not connected"

**Causa**: Emulator no está ejecutándose
**Solución**:

- Ejecuta `firebase emulators:start --only auth`
- Verifica que el puerto 9099 esté disponible
- Confirma que la configuración de Firebase apunte al emulator

#### 4. Error: "Backend sync failed"

**Causa**: API backend no está ejecutándose o hay error en el endpoint
**Solución**:

- Verifica que el backend esté ejecutándose en puerto 8000
- Revisa logs del backend para errores
- Confirma que el endpoint `/api/v1/auth/sync` esté disponible

### Logs Útiles

#### Frontend (Browser Console)

```javascript
// Verificar configuración Firebase
console.log(firebase.app().options);

// Verificar usuario autenticado
console.log(firebase.auth().currentUser);
```

#### Backend (Cloud Run Logs)

```bash
# Ver logs de autenticación
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=adyela-api-staging AND jsonPayload.message~'OAuth'" --limit=50
```

#### Firebase Emulator

- Ve a http://localhost:4000 para ver usuarios creados
- Revisa logs en la terminal donde ejecutaste el emulator

### Comandos de Diagnóstico

```bash
# Verificar que Firebase Emulator esté ejecutándose
curl http://localhost:9099

# Verificar que Backend API esté ejecutándose
curl http://localhost:8000/health

# Verificar que Frontend esté ejecutándose
curl http://localhost:5173

# Ver logs de Firebase Emulator
firebase emulators:start --only auth --debug

# Ver logs de Backend
cd apps/api && poetry run python -m adyela_api.main --log-level debug
```

## Consideraciones de Seguridad

### HIPAA Compliance

1. **No almacenar PHI en tokens OAuth**
2. **Audit logging de todos los logins**
3. **Encriptación de datos sensibles**
4. **Tokens con expiración corta**
5. **Validación estricta de proveedores OAuth**

### Mejores Prácticas

1. **Usar HTTPS en producción**
2. **Validar tokens en el backend**
3. **Implementar rate limiting**
4. **Monitorear intentos de login fallidos**
5. **Rotar credenciales regularmente**

## Recursos Adicionales

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Facebook Login Documentation](https://developers.facebook.com/docs/facebook-login/)
- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Microsoft Identity Platform Documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/)
