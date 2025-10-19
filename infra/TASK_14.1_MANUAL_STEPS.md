# 🔧 Task 14.1 - Pasos Manuales Requeridos

**Fecha:** 2025-10-19 **Estado:** 90% Completo - Requiere Autenticación
Interactiva **Tiempo Estimado:** 2-3 minutos

---

## ✅ Progreso Completado

1. ✅ Script `setup-terraform-backend.sh` ejecutado exitosamente
2. ✅ Buckets GCS verificados (ya existían):
   - `gs://adyela-staging-terraform-state`
   - `gs://adyela-production-terraform-state`
3. ✅ Configuración de backend.tf actualizada
4. ✅ Cuenta GCP configurada: `hever_gonzalezg@adyela.care`
5. ✅ Proyecto configurado: `adyela-staging`

---

## ⚠️ Problema Actual

**Error:** OAuth2 Invalid RAPT (Risk-Aware Protection Toolkit)

```
Error: oauth2: cannot fetch token: 400 Bad Request
Response: {
  "error": "invalid_grant",
  "error_description": "reauth related error (invalid_rapt)"
}
```

**Causa:** Las "Application Default Credentials" (ADC) están expiradas o no
configuradas.

**Solución:** Requiere autenticación interactiva con navegador.

---

## 🚀 Pasos a Seguir (TÚ DEBES EJECUTAR)

### Paso 1: Autenticar Application Default Credentials

```bash
# Esto abrirá tu navegador para autenticarte
gcloud auth application-default login
```

**Qué hacer:**

1. Se abrirá tu navegador automáticamente
2. Inicia sesión con la cuenta: `hever_gonzalezg@adyela.care`
3. Acepta los permisos solicitados
4. Espera el mensaje "Credentials saved"

**Resultado esperado:**

```
Credentials saved to file: [/Users/hevergonzalezgarcia/.config/gcloud/application_default_credentials.json]

These credentials will be used by any library that requests Application Default Credentials (ADC).
```

---

### Paso 2: Inicializar Terraform con Backend Remoto

```bash
# Navega al directorio de staging
cd /Users/hevergonzalezgarcia/TFM\ Agentes\ IA/CLAUDE/adyela/infra/environments/staging

# Inicializa Terraform y migra el estado local a GCS
terraform init -migrate-state
```

**Qué esperar:**

- Terraform detectará que tienes estado local (terraform.tfstate)
- Te preguntará si quieres migrarlo al backend remoto
- Responde **"yes"**

**Resultado esperado:**

```
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "gcs" backend. No existing state was found in the newly
  configured "gcs" backend. Do you want to copy this state to the new "gcs"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes


Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing modules...

Initializing provider plugins...

Terraform has been successfully initialized!
```

---

### Paso 3: Verificar el Estado Remoto

```bash
# Verifica que el estado se migró a GCS
gcloud storage ls gs://adyela-staging-terraform-state/terraform/state/

# Deberías ver:
# gs://adyela-staging-terraform-state/terraform/state/default.tfstate
```

---

### Paso 4: Probar Terraform Plan

```bash
# Ejecuta un plan para verificar que todo funciona
terraform plan

# Esto mostrará el estado actual de tu infraestructura
```

---

## 📊 Estado Actual de la Infraestructura

### Estado Local Detectado

```bash
File: terraform.tfstate
Size: 133,655 bytes (130 KB)
Last Modified: Oct 17 16:17
Backups: 3 archivos
```

Este estado contiene la configuración actual de:

- 6 microservices (api-auth, api-appointments, api-payments, api-notifications,
  api-admin, api-analytics)
- Módulos de finops (budget alerts)
- Pub/Sub messaging
- Otros recursos desplegados

**Es importante migrar este estado** para no perder la referencia a los recursos
existentes.

---

## 🔍 Verificación Post-Migración

### Comandos de Verificación

```bash
# 1. Verificar backend configurado
cd /Users/hevergonzalezgarcia/TFM\ Agentes\ IA/CLAUDE/adyela/infra/environments/staging
terraform init

# Debería decir: "Backend configuration changed!" seguido de "Successfully configured the backend"

# 2. Verificar estado en GCS
gcloud storage ls -l gs://adyela-staging-terraform-state/terraform/state/

# 3. Verificar que el estado local ya no se usa
cat .terraform/terraform.tfstate
# Debería mostrar que el backend es "gcs"

# 4. Probar operaciones de Terraform
terraform plan
terraform validate
```

---

## ❓ Troubleshooting

### Error: "Failed to get existing workspaces"

**Solución:**

```bash
rm -rf .terraform
terraform init -migrate-state
```

### Error: "Error acquiring the state lock"

**Causa:** Otro proceso tiene el lock del estado

**Solución:**

```bash
# Espera unos segundos y reintenta
# O fuerza la liberación del lock (¡solo si estás seguro!)
terraform force-unlock <LOCK_ID>
```

### Error: "Bucket does not exist"

**Solución:**

```bash
# Verifica que el bucket existe
gcloud storage buckets describe gs://adyela-staging-terraform-state

# Si no existe, créalo
gcloud storage buckets create gs://adyela-staging-terraform-state \
    --project=adyela-staging \
    --location=us-central1 \
    --uniform-bucket-level-access
```

---

## 📚 Referencias

### Documentación Creada

- `BACKEND_SETUP_STATUS.md` - Guía completa de setup
- `TASK_14.1_COMPLETION_REPORT.md` - Análisis detallado de completitud
- `TASK_14.1_EXECUTION_RESULTS.md` - Resumen de ejecución
- `TASK_14.1_MANUAL_STEPS.md` - Este documento

### Enlaces Útiles

- [Terraform GCS Backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)
- [GCP Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)
- [GCP RAPT Error](https://support.google.com/a/answer/9368756)

---

## ✅ Checklist de Completitud

- [x] Script ejecutado exitosamente
- [x] Buckets GCS verificados
- [x] Backend.tf configurado
- [x] Cuenta y proyecto configurados
- [ ] **Application Default Credentials configuradas** ⬅️ PASO ACTUAL
- [ ] **Terraform inicializado con backend GCS**
- [ ] **Estado local migrado a GCS**
- [ ] **Terraform plan ejecutado sin errores**

---

## 🎯 Siguiente Tarea

Una vez completados estos pasos, podemos continuar con:

**Task 14.2:** Create Core GCP Compute Modules

- Enhanced Cloud Run configuration
- Cloud Armor (WAF) integration
- Auto-scaling policies

---

## 💡 Nota Importante

**¿Por qué "Application Default Credentials"?**

Terraform usa ADC para autenticarse con Google Cloud APIs. Hay dos tipos de
credenciales:

1. **User Credentials** (`gcloud auth login`): Para comandos gcloud ✅ Ya tienes
   esto
2. **Application Default Credentials**
   (`gcloud auth application-default login`): Para aplicaciones/Terraform ⏳
   Necesitas esto

Son diferentes y se almacenan en ubicaciones diferentes:

- User: `~/.config/gcloud/credentials.db`
- ADC: `~/.config/gcloud/application_default_credentials.json`

---

**Preparado por:** Claude Code **Tiempo estimado total:** 2-3 minutos **Blocker
actual:** Autenticación interactiva requerida **Prioridad:** HIGH

---

## 🚨 ACCIÓN REQUERIDA

**Ejecuta ahora:**

```bash
gcloud auth application-default login
```

Luego avísame para continuar con la inicialización de Terraform.
