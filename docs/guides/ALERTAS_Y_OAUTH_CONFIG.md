# 🔔 Guía: Configuración de Alertas y Google OAuth

**Fecha**: 2025-10-16 **Proyecto**: adyela-staging **Autor**: Claude Code

---

## 📋 Tabla de Contenidos

1. [Validación de Alertas](#validación-de-alertas)
2. [Prueba de Notificaciones](#prueba-de-notificaciones)
3. [Configuración de Google OAuth](#configuración-de-google-oauth)
4. [Prueba de Flujo de Autenticación](#prueba-de-flujo-de-autenticación)
5. [Solución de Problemas](#solución-de-problemas)

---

## ✅ Validación de Alertas

### Estado Actual

**3 Políticas de Alerta Configuradas**:

| Política                           | Estado        | Canal de Notificación | Condición                |
| ---------------------------------- | ------------- | --------------------- | ------------------------ |
| **adyela-staging-api-downtime**    | ✅ Habilitada | Email                 | API Health Check Failure |
| **adyela-staging-high-error-rate** | ✅ Habilitada | Email                 | API Error Rate >1%       |
| **adyela-staging-high-latency**    | ✅ Habilitada | Email                 | API Latency P95 >1000ms  |

**Canal de Notificación Configurado**:

- **Tipo**: Email
- **Destinatario**: `hever_gonzalezg@adyela.care` ✅
- **Estado**: Habilitado

### Verificación por CLI

```bash
# Listar políticas de alertas
gcloud alpha monitoring policies list --project=adyela-staging

# Listar canales de notificación
gcloud alpha monitoring channels list --project=adyela-staging

# Ver detalles de una política específica
gcloud alpha monitoring policies describe POLICY_ID --project=adyela-staging
```

---

## 🧪 Prueba de Notificaciones

### Opción 1: Probar desde Google Cloud Console (RECOMENDADO)

#### Paso 1: Acceder a Cloud Console

1. Ve a la consola de GCP:

   ```
   https://console.cloud.google.com/monitoring/alerting/policies?project=adyela-staging
   ```

2. Verás la lista de 3 políticas de alerta

#### Paso 2: Probar Alerta de Downtime

1. Click en **"adyela-staging-api-downtime"**
2. En la parte superior derecha, click en **"SEND TEST NOTIFICATION"** (Enviar
   notificación de prueba)
3. Se enviará un email de prueba a `hever_gonzalezg@adyela.care`

**Email esperado**:

```
Asunto: Test Notification - adyela-staging-api-downtime
De: Google Cloud Monitoring

This is a test notification from Cloud Monitoring.

Alert Policy: adyela-staging-api-downtime
Condition: API Health Check Failure
Project: adyela-staging
```

#### Paso 3: Probar Alerta de Error Rate

1. Click en **"adyela-staging-high-error-rate"**
2. Click en **"SEND TEST NOTIFICATION"**
3. Verificar recepción del email

#### Paso 4: Probar Alerta de Latency

1. Click en **"adyela-staging-high-latency"**
2. Click en **"SEND TEST NOTIFICATION"**
3. Verificar recepción del email

### Opción 2: Trigger Manual de Alerta (Avanzado)

#### Simular Downtime de API

```bash
# Detener temporalmente el servicio de API (NO RECOMENDADO EN PRODUCCIÓN)
gcloud run services update adyela-api-staging \
  --min-instances=0 \
  --max-instances=0 \
  --region=us-central1 \
  --project=adyela-staging

# Esperar 60-90 segundos para que se dispare la alerta

# Restaurar servicio
gcloud run services update adyela-api-staging \
  --min-instances=0 \
  --max-instances=2 \
  --region=us-central1 \
  --project=adyela-staging
```

**⚠️ ADVERTENCIA**: Esta opción interrumpe el servicio temporalmente. Solo usar
en staging cuando no hay usuarios activos.

### Opción 3: Verificar Historial de Alertas

```bash
# Ver incidentes recientes
gcloud alpha monitoring policies list --project=adyela-staging --format="table(displayName,enabled,conditions[0].displayName)"

# Ver logs de notificaciones
gcloud logging read \
  'resource.type="alerting_policy" AND severity>=ERROR' \
  --project=adyela-staging \
  --limit=10 \
  --format=json
```

---

## 🔐 Configuración de Google OAuth

### Estado Actual

**Credenciales en Secret Manager** ✅:

```bash
✅ oauth-google-client-id (creado: 2025-10-11)
✅ oauth-google-client-secret (creado: 2025-10-11)
```

**Client ID**:

```
717907307897-bslj2pef6oedrqldivnh1neio75bh891.apps.googleusercontent.com
```

**Servicio Identity Platform** ✅:

```bash
✅ identitytoolkit.googleapis.com (habilitado)
```

---

### Paso 1: Verificar Configuración en Firebase Console

#### 1.1 Acceder a Firebase Console

```
https://console.firebase.google.com/project/adyela-staging/authentication/providers
```

**Credenciales de acceso**: Usa tu cuenta `hever_gonzalezg@adyela.care`

#### 1.2 Verificar Providers Habilitados

En la pestaña **"Sign-in method"** deberías ver:

| Provider           | Estado        | Configuración         |
| ------------------ | ------------- | --------------------- |
| **Google**         | ✅ Habilitado | Client ID configurado |
| **Email/Password** | ?             | Por verificar         |
| **Microsoft**      | ?             | Por verificar         |

---

### Paso 2: Configurar Google OAuth (Si No Está Habilitado)

#### 2.1 Habilitar Provider de Google

1. En Firebase Console → **Authentication** → **Sign-in method**
2. Click en **"Google"** en la lista de providers
3. Click en **"Enable"** (Habilitar)
4. **Configuración**:

**Project support email**:

```
hever_gonzalezg@adyela.care
```

**Client ID** (OAuth 2.0 Web client):

```
717907307897-bslj2pef6oedrqldivnh1neio75bh891.apps.googleusercontent.com
```

**Client Secret**:

```
# Obtener del Secret Manager:
gcloud secrets versions access latest \
  --secret="oauth-google-client-secret" \
  --project=adyela-staging
```

5. Click en **"Save"**

#### 2.2 Verificar OAuth Consent Screen

1. Ve a Google Cloud Console → **APIs & Services** → **OAuth consent screen**:

   ```
   https://console.cloud.google.com/apis/credentials/consent?project=adyela-staging
   ```

2. **Configuración requerida**:

**User Type**: External (para pacientes públicos)

**App information**:

- **App name**: Adyela Healthcare Platform
- **User support email**: hever_gonzalezg@adyela.care
- **App logo**: (opcional, puedes subirlo después)

**App domain**:

- **Application home page**: https://staging.adyela.care
- **Privacy policy**: https://staging.adyela.care/privacy
- **Terms of service**: https://staging.adyela.care/terms

**Authorized domains**:

```
adyela.care
firebaseapp.com
```

**Developer contact**:

```
hever_gonzalezg@adyela.care
```

3. **Scopes** (permisos solicitados):

Agregar estos scopes:

- `openid` (requerido)
- `email` (requerido)
- `profile` (requerido)

4. **Test users** (para desarrollo):

Agregar tu email como test user:

```
hever_gonzalezg@adyela.care
```

**⚠️ IMPORTANTE**: Mientras la app esté en modo "Testing", solo los test users
pueden hacer login con Google OAuth.

---

### Paso 3: Configurar Dominios Autorizados

#### 3.1 En Firebase Console

1. **Authentication** → **Settings** → **Authorized domains**

2. Agregar estos dominios:

```
localhost
staging.adyela.care
adyela-staging.firebaseapp.com
adyela-staging.web.app
```

3. Click en **"Add domain"** para cada uno

#### 3.2 Verificar OAuth Redirect URIs

En Google Cloud Console → **APIs & Services** → **Credentials**:

```
https://console.cloud.google.com/apis/credentials?project=adyela-staging
```

1. Click en el **OAuth 2.0 Client ID** configurado
2. Verificar **Authorized redirect URIs**:

```
https://staging.adyela.care/__/auth/handler
https://adyela-staging.firebaseapp.com/__/auth/handler
https://adyela-staging.web.app/__/auth/handler
http://localhost:9099/__/auth/handler (para desarrollo local)
```

3. Si faltan, agregarlas y click en **"Save"**

---

### Paso 4: Actualizar Frontend Configuration

#### 4.1 Verificar Firebase Config en Web App

El frontend (`apps/web`) necesita la configuración de Firebase. Verifica que
exista en el archivo de environment:

```typescript
// apps/web/src/config/firebase.ts

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: `${import.meta.env.VITE_FIREBASE_PROJECT_ID}.firebaseapp.com`,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: `${import.meta.env.VITE_FIREBASE_PROJECT_ID}.appspot.com`,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};
```

#### 4.2 Variables de Entorno en Cloud Run

Verificar que el servicio `adyela-web-staging` tiene estas variables:

```bash
# Verificar variables de entorno
gcloud run services describe adyela-web-staging \
  --region=us-central1 \
  --project=adyela-staging \
  --format="value(spec.template.spec.containers[0].env)"
```

**Variables requeridas**:

- `VITE_FIREBASE_PROJECT_ID=adyela-staging`
- `VITE_FIREBASE_API_KEY` (desde Secret Manager: `firebase-web-api-key`)
- `VITE_FIREBASE_MESSAGING_SENDER_ID` (desde Secret Manager)
- `VITE_FIREBASE_APP_ID` (desde Secret Manager)
- `VITE_FIREBASE_AUTH_DOMAIN=adyela-staging.firebaseapp.com`

Estas ya están configuradas en Terraform ✅ (ver
`infra/modules/cloud-run/main.tf` líneas 188-216)

---

## 🧪 Prueba de Flujo de Autenticación

### Opción 1: Prueba en Staging (Web App)

#### Paso 1: Acceder a la Aplicación

```
https://staging.adyela.care
```

#### Paso 2: Intentar Login con Google

1. En la pantalla de login, click en **"Sign in with Google"**
2. Se abrirá popup de Google OAuth
3. Seleccionar tu cuenta de Google
4. **Si aparece "This app is blocked"**:
   - Esto es normal porque la app está en modo "Testing"
   - Necesitas agregar tu cuenta como "Test user" (ver Paso 2.2 arriba)
5. **Si aparece consent screen**:
   - Revisar permisos solicitados
   - Click en **"Continue"** o **"Allow"**
6. Deberías ser redirigido a la app ya autenticado

#### Paso 3: Verificar Usuario Creado

```bash
# Ver usuarios en Firebase Auth
# (Necesitas Firebase CLI instalado)
firebase auth:export users.json --project adyela-staging

# O verificar en Firebase Console:
# https://console.firebase.google.com/project/adyela-staging/authentication/users
```

---

### Opción 2: Prueba con Firebase SDK (Local)

Si quieres probar localmente antes de desplegar:

#### Crear archivo de prueba HTML

```html
<!-- test-google-oauth.html -->
<!DOCTYPE html>
<html>
  <head>
    <title>Test Google OAuth - Adyela</title>
    <script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-auth-compat.js"></script>
  </head>
  <body>
    <h1>Test Google OAuth</h1>
    <button id="loginBtn">Sign in with Google</button>
    <div id="status"></div>
    <div id="userInfo"></div>

    <script>
      // Firebase configuration
      const firebaseConfig = {
        apiKey: 'AIzaSyDl3w...', // Obtener de Secret Manager
        authDomain: 'adyela-staging.firebaseapp.com',
        projectId: 'adyela-staging',
        storageBucket: 'adyela-staging.appspot.com',
        messagingSenderId: '...', // Obtener de Secret Manager
        appId: '...', // Obtener de Secret Manager
      };

      // Initialize Firebase
      firebase.initializeApp(firebaseConfig);
      const auth = firebase.auth();

      // Google OAuth Provider
      const provider = new firebase.auth.GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');

      // Login button
      document.getElementById('loginBtn').addEventListener('click', () => {
        document.getElementById('status').textContent = 'Logging in...';

        auth
          .signInWithPopup(provider)
          .then(result => {
            const user = result.user;
            document.getElementById('status').textContent = 'Login successful!';
            document.getElementById('userInfo').innerHTML = `
            <h2>User Info:</h2>
            <p>Name: ${user.displayName}</p>
            <p>Email: ${user.email}</p>
            <p>UID: ${user.uid}</p>
            <img src="${user.photoURL}" alt="Profile photo" width="100">
          `;
          })
          .catch(error => {
            document.getElementById('status').textContent = 'Login failed!';
            console.error('Error:', error);
            document.getElementById('userInfo').innerHTML = `
            <h2>Error:</h2>
            <p>${error.code}: ${error.message}</p>
          `;
          });
      });

      // Auth state observer
      auth.onAuthStateChanged(user => {
        if (user) {
          console.log('User is signed in:', user);
        } else {
          console.log('User is signed out');
        }
      });
    </script>
  </body>
</html>
```

#### Servir el archivo localmente

```bash
# Opción 1: Python simple server
python3 -m http.server 8080

# Opción 2: Node.js http-server
npx http-server -p 8080

# Abrir en navegador:
# http://localhost:8080/test-google-oauth.html
```

**⚠️ IMPORTANTE**: Agrega `http://localhost:8080` a los dominios autorizados en
Firebase Console para testing local.

---

### Opción 3: Verificar Logs de Autenticación

```bash
# Ver logs de Identity Platform
gcloud logging read \
  'resource.type="identitytoolkit.googleapis.com/instances" AND severity>=INFO' \
  --project=adyela-staging \
  --limit=50 \
  --format=json

# Ver logs de errores de autenticación
gcloud logging read \
  'resource.type="identitytoolkit.googleapis.com/instances" AND severity>=ERROR' \
  --project=adyela-staging \
  --limit=20
```

---

## 🐛 Solución de Problemas

### Problema 1: "This app is blocked" al hacer login

**Causa**: La app está en modo "Testing" en OAuth Consent Screen

**Solución**:

1. Agregar tu email como "Test user" en OAuth consent screen
2. O publicar la app (cambiar de "Testing" a "In production")

**Pasos**:

```
1. https://console.cloud.google.com/apis/credentials/consent?project=adyela-staging
2. Si está en "Testing", click "PUBLISH APP"
3. O agregar email en "Test users" → "ADD USERS"
```

---

### Problema 2: "Redirect URI mismatch"

**Error**: `redirect_uri_mismatch` en OAuth flow

**Causa**: El redirect URI no está autorizado en Google Cloud Console

**Solución**:

1. Ve a
   [OAuth Credentials](https://console.cloud.google.com/apis/credentials?project=adyela-staging)
2. Click en el OAuth 2.0 Client ID
3. Agregar URI faltante en "Authorized redirect URIs":
   ```
   https://staging.adyela.care/__/auth/handler
   ```
4. Click "Save"

---

### Problema 3: "API key not valid"

**Causa**: Firebase API key incorrecta o restringida

**Solución**:

```bash
# Verificar API key en Secret Manager
gcloud secrets versions access latest \
  --secret="firebase-web-api-key" \
  --project=adyela-staging

# Comparar con la clave en Firebase Console:
# https://console.firebase.google.com/project/adyela-staging/settings/general
```

Si son diferentes, actualizar el secret:

```bash
# Obtener nueva key de Firebase Console
echo "NUEVA_API_KEY" | gcloud secrets versions add firebase-web-api-key \
  --data-file=- \
  --project=adyela-staging

# Reiniciar Cloud Run para cargar nuevo secret
gcloud run services update adyela-web-staging \
  --region=us-central1 \
  --project=adyela-staging
```

---

### Problema 4: No recibo emails de alertas

**Verificaciones**:

1. **Canal de notificación habilitado**:

```bash
gcloud alpha monitoring channels list --project=adyela-staging
# Verificar que "ENABLED" = True
```

2. **Email correcto**:

```bash
gcloud alpha monitoring channels describe CHANNEL_ID --project=adyela-staging
# Verificar que email sea hever_gonzalezg@adyela.care
```

3. **Revisar carpeta de spam**: Los emails de GCP pueden caer en spam

4. **Verificar estado de política**:

```bash
gcloud alpha monitoring policies list --project=adyela-staging
# Todas deben tener ENABLED = True
```

---

### Problema 5: Usuarios no se crean en Firebase Auth

**Verificaciones**:

1. **Identity Platform habilitado**:

```bash
gcloud services list --enabled --project=adyela-staging | grep identity
# Debe aparecer: identitytoolkit.googleapis.com
```

2. **Provider de Google habilitado en Firebase Console**:
   - https://console.firebase.google.com/project/adyela-staging/authentication/providers
   - Google debe estar "Enabled"

3. **Logs de autenticación**:

```bash
gcloud logging read \
  'resource.type="identitytoolkit.googleapis.com/instances"' \
  --project=adyela-staging \
  --limit=10
```

---

## 📊 Checklist de Validación

### Alertas ✅

- [x] 3 políticas de alerta creadas
- [x] Canal de email configurado con `hever_gonzalezg@adyela.care`
- [ ] Notificaciones de prueba enviadas y recibidas
- [ ] Verificado que emails no caen en spam
- [ ] Documentación de runbooks revisada

### Google OAuth

- [x] Client ID y Secret en Secret Manager
- [ ] Google Provider habilitado en Firebase Console
- [ ] OAuth Consent Screen configurado
- [ ] Test users agregados (si app en modo Testing)
- [ ] Dominios autorizados configurados (4 dominios)
- [ ] Redirect URIs autorizados
- [ ] Variables de entorno en Cloud Run verificadas
- [ ] Prueba de login exitosa
- [ ] Usuario creado en Firebase Auth verificado

---

## 🎯 Próximos Pasos

### Inmediato (Hoy)

1. ✅ Probar notificaciones de alertas (15 min)
2. ✅ Verificar Google OAuth en Firebase Console (10 min)
3. ✅ Configurar OAuth Consent Screen (15 min)
4. ✅ Probar flujo de login con Google (10 min)

### Corto Plazo (Esta Semana)

1. Configurar Microsoft OAuth (similar a Google)
2. Configurar Apple Sign In (si es necesario)
3. Implementar MFA (Multi-Factor Authentication)
4. Configurar email/password authentication

### Mediano Plazo (Próximas 2 Semanas)

1. Implementar flujo completo de registro de pacientes
2. Configurar roles y permisos (RBAC)
3. Implementar audit logging para acceso a PHI
4. Configurar password policies (complejidad, rotación)

---

## 📚 Referencias

### Documentación Oficial

- **Cloud Monitoring**: https://cloud.google.com/monitoring/docs
- **Alert Policies**: https://cloud.google.com/monitoring/alerts
- **Identity Platform**: https://cloud.google.com/identity-platform/docs
- **Firebase Auth**: https://firebase.google.com/docs/auth
- **OAuth 2.0**: https://developers.google.com/identity/protocols/oauth2

### Comandos Útiles

```bash
# Ver todas las políticas de alerta
gcloud alpha monitoring policies list --project=adyela-staging

# Ver todos los canales de notificación
gcloud alpha monitoring channels list --project=adyela-staging

# Ver servicios habilitados
gcloud services list --enabled --project=adyela-staging

# Ver secretos
gcloud secrets list --project=adyela-staging

# Ver logs de autenticación
gcloud logging read \
  'resource.type="identitytoolkit.googleapis.com/instances"' \
  --project=adyela-staging \
  --limit=50
```

---

## 🎉 Conclusión

Este documento proporciona una guía completa para:

✅ Validar configuración de alertas ✅ Probar notificaciones de email ✅
Configurar Google OAuth en Identity Platform ✅ Verificar flujo de autenticación
✅ Solucionar problemas comunes

**Siguiente paso**: Ejecutar las pruebas descritas y verificar que todo funciona
correctamente.

---

**Generado**: 2025-10-16 **Proyecto**: adyela-staging **Autor**: Claude Code
**Contacto**: hever_gonzalezg@adyela.care
