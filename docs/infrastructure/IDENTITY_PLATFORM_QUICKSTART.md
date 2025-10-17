# Identity Platform Quick Start Guide

Esta guía te permite desplegar Identity Platform en 15 minutos.

## ⚠️ Nota Importante sobre Permisos

El deployment de Identity Platform **requiere permisos especiales**. Si
encuentras errores de permisos:

### Opción 1: Habilitar desde Firebase Console (RECOMENDADO)

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona el proyecto `adyela-staging`
3. Ve a **Authentication** en el menú lateral
4. Click en "Get Started"
5. Esto habilitará automáticamente Identity Platform

### Opción 2: Solicitar permisos al Owner del proyecto

```bash
# El owner del proyecto puede ejecutar:
gcloud projects add-iam-policy-binding adyela-staging \
  --member="user:hever_gonzalezg@adyela.care" \
  --role="roles/editor"
```

## Paso 1: Habilitar Identity Platform (Desde Firebase Console)

**Antes de usar Terraform**, habilita Identity Platform manualmente:

1. Abre:
   https://console.firebase.google.com/project/adyela-staging/authentication
2. Click en "Get Started"
3. Esto crea la configuración base de Identity Platform

## Paso 2: Configurar OAuth Providers (Desde Firebase Console)

### Google OAuth

1. En Firebase Console > Authentication > Sign-in method
2. Click en "Google" > "Enable"
3. Configurar:
   - **Web SDK configuration**: Selecciona tu proyecto de GCP
   - **Public-facing name**: "Adyela Healthcare Platform"
   - **Support email**: hever_gonzalezg@adyela.care

### Microsoft OAuth

1. En Firebase Console > Authentication > Sign-in method
2. Click en "Microsoft" > "Enable"
3. Necesitarás:
   - **Application (client) ID**: De Azure Portal
   - **Application (client) Secret**: De Azure Portal

**Configurar en Azure:**

1. Ve a:
   https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps
2. "New registration" > Name: "Adyela Healthcare Platform"
3. Redirect URI: `https://adyela-staging.firebaseapp.com/__/auth/handler`
4. Copiar Application ID y crear Client Secret

### Facebook OAuth

1. En Firebase Console > Authentication > Sign-in method
2. Click en "Facebook" > "Enable"
3. Necesitarás:
   - **App ID**: De Facebook Developers
   - **App secret**: De Facebook Developers

**Configurar en Facebook:**

1. Ve a: https://developers.facebook.com/apps/
2. "Create App" > "Consumer"
3. Add Product > "Facebook Login"
4. Settings > Basic:
   - **App Domains**: `adyela-staging.firebaseapp.com`
   - **Privacy Policy URL**: https://staging.adyela.care/privacy
   - **Terms of Service URL**: https://staging.adyela.care/terms
5. Facebook Login > Settings:
   - **Valid OAuth Redirect URIs**:
     `https://adyela-staging.firebaseapp.com/__/auth/handler`

## Paso 3: Verificar Configuración

```bash
# Verificar que Identity Platform está habilitado
gcloud services list --enabled --filter="identitytoolkit.googleapis.com"

# Debería aparecer:
# identitytoolkit.googleapis.com
```

## Paso 4: (Opcional) Deploy con Terraform

Si quieres gestionar configuraciones adicionales con Terraform:

```bash
cd infra/environments/staging

# Crear archivo identity-platform.tf
cat > identity-platform.tf <<'EOF'
# Identity Platform - Configuración Adicional
# La configuración base ya está en Firebase Console

# Habilitar APIs necesarias
resource "google_project_service" "identity_toolkit" {
  project = var.project_id
  service = "identitytoolkit.googleapis.com"
  disable_on_destroy = false
}

# Configuración de dominios autorizados
resource "google_identity_platform_config" "default" {
  project = var.project_id

  authorized_domains = [
    "localhost",
    "staging.adyela.care",
    "${var.project_id}.firebaseapp.com",
    "${var.project_id}.web.app"
  ]

  depends_on = [google_project_service.identity_toolkit]
}

# Outputs
output "identity_platform_config" {
  description = "Identity Platform configuration"
  value = {
    project = var.project_id
    authorized_domains = google_identity_platform_config.default.authorized_domains
  }
}
EOF

# Inicializar y aplicar
terraform init
terraform plan
terraform apply
```

## Paso 5: Actualizar App Frontend

Tu app React ya tiene el código OAuth implementado. Solo necesitas actualizar
las variables de entorno:

```bash
# apps/web/.env.staging (o .env.production)
VITE_FIREBASE_API_KEY=<tu-api-key>
VITE_FIREBASE_AUTH_DOMAIN=adyela-staging.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=adyela-staging
VITE_FIREBASE_STORAGE_BUCKET=adyela-staging.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=<tu-sender-id>
VITE_FIREBASE_APP_ID=<tu-app-id>
```

Obtener valores:

```bash
# Desde Firebase Console > Project Settings > General > Your apps
# O usando Firebase CLI:
firebase projects:list
firebase apps:sdkconfig web
```

## Paso 6: Testing

```bash
# 1. Iniciar app localmente
cd apps/web
npm run dev

# 2. Navegar a http://localhost:5173/login

# 3. Probar OAuth buttons:
#    - "Continue with Google"
#    - "Continue with Microsoft"
#    - "Continue with Facebook"

# 4. Verificar en Firebase Console > Authentication > Users
#    que los usuarios se crean correctamente
```

## Troubleshooting

### Error: "Invalid OAuth client"

- Verificar que el Client ID sea correcto
- Verificar que el redirect URI coincida exactamente

### Error: "Unauthorized domain"

- Agregar dominio en Firebase Console > Authentication > Settings > Authorized
  domains

### Error: "API not enabled"

- Ejecutar: `gcloud services enable identitytoolkit.googleapis.com`

## Next Steps

Una vez que OAuth funciona:

1. **Habilitar MFA**: Firebase Console > Authentication > Settings >
   Multi-factor auth
2. **Configurar Email Templates**: Authentication > Templates
3. **Setup Audit Logging**: Logging > Log Router
4. **Production Deployment**: Repetir pasos para proyecto production

## Resumen de Costos

- Identity Platform: **$0** (hasta 50,000 MAU)
- OAuth Providers: **$0** (incluido en Identity Platform)
- Firebase Auth: **$0** (plan Spark es gratuito)

Total: **$0/mes** para staging

## Referencias

- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Identity Platform Pricing](https://cloud.google.com/identity-platform/pricing)
- [OAuth Implementation Guide](../guides/OAUTH_SETUP.md)
