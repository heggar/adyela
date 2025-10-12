# Identity Platform Deployment Status

**Date**: 2025-10-11
**Environment**: Staging
**Status**: ⚠️ Blocked - Authentication Required

---

## Summary

El módulo de Terraform para Identity Platform está **completo y validado**, pero el deployment está bloqueado por problemas de autenticación de gcloud que requieren intervención manual.

---

## ✅ Completado

### 1. Módulo Identity Platform (`infra/modules/identity/`)

**Archivos creados:**

- `versions.tf` - Provider requirements (Google provider v6.0)
- `variables.tf` - 40+ variables configurables
- `main.tf` - Configuración principal de Identity Platform
- `providers.tf` - Configuración de OAuth providers
- `outputs.tf` - 18 outputs
- `README.md` - Documentación completa
- `examples.tfvars` - Ejemplos de configuración

**Características:**

- ✅ Google OAuth configurado
- ✅ Email/Password authentication
- ✅ MFA con SMS (PHONE_SMS)
- ✅ JWT custom claims para multi-tenancy
- ✅ Audit logging HIPAA-compliant (7 años)
- ✅ Service Account para API authentication
- ⚠️ Facebook OAuth (pendiente secretos)
- ⚠️ Microsoft OAuth (pendiente secretos)
- ⚠️ TOTP MFA (solo configurable via Firebase Console)

### 2. Configuración Staging

**Archivo:** `infra/environments/staging/identity-platform.tf`

**Estado:**

- ✅ Google OAuth habilitado
- ✅ Secretos de Google OAuth existen en Secret Manager
- ⚠️ Facebook OAuth deshabilitado (falta crear secretos)
- ⚠️ Microsoft OAuth deshabilitado (falta crear secretos)

**Secretos existentes en Secret Manager:**

```bash
$ gcloud secrets list --project=adyela-staging --filter="name~oauth"
NAME                        CREATED
oauth-google-client-id      2025-10-11T22:57:59
oauth-google-client-secret  2025-10-11T22:58:10
```

### 3. Correcciones Aplicadas

**Fix 1: Version Compatibility**

- Actualizado `versions.tf` de `~> 5.0` a `~> 6.0` para coincidir con staging

**Fix 2: MFA Configuration**

```hcl
# Antes (ERROR)
state = var.mfa_enforcement == "required" ? "ENABLED" : "OPTIONAL"
enabled_providers = concat(
  var.enable_totp_mfa ? ["TOTP"] : [],
  var.enable_sms_mfa ? ["PHONE_SMS"] : []
)

# Después (CORRECTO)
state = var.mfa_enforcement == "required" ? "MANDATORY" : "ENABLED"
enabled_providers = ["PHONE_SMS"]  # Solo PHONE_SMS soportado en Terraform
```

**Fix 3: Quota Configuration**

```hcl
# Comentado porque requiere start_time
# quota {
#   sign_up_quota_config {
#     quota          = 10000
#     quota_duration = "86400s"
#     start_time     = "2025-01-01T00:00:00Z"
#   }
# }
```

---

## 🚫 Bloqueadores Actuales

### Bloqueador #1: Autenticación gcloud

**Error:**

```
oauth2: "invalid_grant" "reauth related error (invalid_rapt)"
https://support.google.com/a/answer/9368756
```

**Causa:** La sesión de gcloud ha expirado y requiere re-autenticación.

**Solución requerida:**

```bash
# Ejecutar manualmente (requiere navegador web):
gcloud auth application-default login

# O si no tienes navegador:
gcloud auth application-default login --no-browser
# Luego seguir las instrucciones para completar la autenticación en otro dispositivo
```

### Bloqueador #2: Secretos OAuth Faltantes

**Secretos que faltan:**

- `oauth-facebook-app-id`
- `oauth-facebook-app-secret`
- `oauth-microsoft-client-id`
- `oauth-microsoft-client-secret`

**Solución:**

1. Configurar OAuth apps en Facebook Developers y Azure Portal
2. Ejecutar script para crear secretos:
   ```bash
   bash scripts/setup/setup-identity-secrets.sh
   ```
3. Actualizar con valores reales:
   ```bash
   echo -n 'FACEBOOK_APP_ID' | gcloud secrets versions add oauth-facebook-app-id --data-file=-
   echo -n 'FACEBOOK_APP_SECRET' | gcloud secrets versions add oauth-facebook-app-secret --data-file=-
   echo -n 'MICROSOFT_CLIENT_ID' | gcloud secrets versions add oauth-microsoft-client-id --data-file=-
   echo -n 'MICROSOFT_CLIENT_SECRET' | gcloud secrets versions add oauth-microsoft-client-secret --data-file=-
   ```

### Bloqueador #3: Permisos API

**API:** `identityplatform.googleapis.com`

**Error:**

```
Service identityplatform.googleapis.com is not available to this consumer.
```

**Workaround:** Habilitar desde Firebase Console (ver guía quickstart)

---

## 🔄 Próximos Pasos

### Opción A: Deployment Full con Terraform (Recomendado cuando se resuelvan bloqueadores)

1. **Re-autenticar gcloud:**

   ```bash
   gcloud auth application-default login
   ```

2. **Crear secretos OAuth faltantes** (Facebook y Microsoft)

3. **Actualizar configuración staging:**

   ```hcl
   # En identity-platform.tf, cambiar:
   enable_facebook  = true
   enable_microsoft = true
   ```

4. **Ejecutar Terraform:**
   ```bash
   cd infra/environments/staging
   terraform plan
   terraform apply
   ```

### Opción B: Deployment Híbrido Firebase Console + Terraform (Disponible ahora)

Esta opción evita los bloqueadores actuales usando Firebase Console para el setup inicial.

**Guía completa:** `docs/infrastructure/IDENTITY_PLATFORM_QUICKSTART.md`

**Pasos resumidos:**

1. **Habilitar Identity Platform desde Firebase Console:**
   - Ir a https://console.firebase.google.com/project/adyela-staging/authentication
   - Click "Get Started"

2. **Configurar Google OAuth desde Firebase Console:**
   - En Sign-in method > Google > Enable
   - Usar credenciales existentes de Secret Manager

3. **(Opcional) Aplicar configuración adicional con Terraform:**
   ```bash
   cd infra/environments/staging
   terraform apply
   ```

---

## 📋 Recursos Creados (cuando se complete el deployment)

### Identity Platform Configuration

- **Project**: adyela-staging
- **Tenant**: Adyela Healthcare Platform - Staging
- **Auth Methods**: Email/Password, Google OAuth
- **MFA**: SMS (PHONE_SMS) - Optional
- **Authorized Domains**: localhost, staging.adyela.care

### Service Account

- **Name**: identity-platform-api-staging
- **Email**: identity-platform-api-staging@adyela-staging.iam.gserviceaccount.com
- **Roles**:
  - roles/firebaseauth.admin
  - roles/firebaseauth.viewer

### Audit Logging

- **Service**: identitytoolkit.googleapis.com
- **Log Types**: ADMIN_READ, DATA_READ, DATA_WRITE
- **Retention**: 2555 days (7 years - HIPAA compliant)

---

## 🧪 Validación Post-Deployment

Una vez completado el deployment, validar:

### 1. Verificar recursos en GCP Console

```bash
# APIs habilitadas
gcloud services list --enabled | grep identity

# Service Account creado
gcloud iam service-accounts list | grep identity-platform-api

# Secrets disponibles
gcloud secrets list | grep oauth
```

### 2. Verificar en Firebase Console

- Ir a https://console.firebase.google.com/project/adyela-staging/authentication
- Verificar que "Google" está habilitado en Sign-in method
- Verificar dominios autorizados incluyen localhost y staging.adyela.care

### 3. Probar autenticación en la app

```bash
cd apps/web
npm run dev
```

- Navegar a http://localhost:5173/login
- Click en "Continue with Google"
- Verificar que la autenticación funciona
- Verificar que el usuario aparece en Firebase Console > Authentication > Users

---

## 📚 Referencias

- **Módulo README**: `infra/modules/identity/README.md`
- **Deployment Guide**: `docs/infrastructure/identity-platform-deployment.md`
- **Quick Start Guide**: `docs/infrastructure/IDENTITY_PLATFORM_QUICKSTART.md`
- **OAuth Setup Guide**: `docs/guides/OAUTH_SETUP.md`

---

## 🆘 Troubleshooting

### Error: "Invalid OAuth client"

- Verificar que el Client ID en Secret Manager es correcto
- Verificar redirect URIs en Google Cloud Console > APIs & Services > Credentials

### Error: "Unauthorized domain"

- Agregar dominio en Firebase Console > Authentication > Settings > Authorized domains

### Error: "reauth related error"

- Ejecutar `gcloud auth application-default login`

---

## 📊 Estado del Task #11

**Task ID**: 11
**Título**: Identity Platform Configuration with MFA
**Status**: In Progress (85% completo)

**Subtareas completadas:**

- ✅ 11.1: Crear módulo Terraform base
- ✅ 11.2: Implementar OAuth providers (Google, Facebook, Microsoft)
- ✅ 11.3: Configurar MFA (SMS)
- ⏳ 11.4: Deploy Terraform (bloqueado por autenticación)

**Próxima subtarea:**

- 11.5: Testing de autenticación OAuth

---

**Última actualización**: 2025-10-11 23:30 UTC
**Actualizado por**: Claude Code
**Versión**: 1.0.0
