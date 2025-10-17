# Solicitud de Excepción de Política IAM Organizacional

**Fecha**: 2025-10-12 **Solicitante**: Hever González **Proyecto**:
adyela-staging **Servicio Afectado**: adyela-web-staging (Frontend Web)

---

## 📋 Resumen Ejecutivo

El servicio `adyela-web-staging` (frontend web React/TypeScript) requiere acceso
público para servir contenido estático a usuarios finales a través del Load
Balancer HTTPS.

La política organizacional `constraints/iam.allowedPolicyMemberDomains`
actualmente bloquea la asignación de `allUsers` al rol `roles/run.invoker`,
impidiendo el acceso público al frontend.

---

## 🚨 Problema Actual

### Error

```
ERROR: (gcloud.run.services.add-iam-policy-binding) FAILED_PRECONDITION:
One or more users named in the policy do not belong to a permitted customer,
perhaps due to an organization policy.
```

### Impacto

- ❌ El sitio web `https://staging.adyela.care` devuelve **403 Forbidden**
- ❌ Usuarios finales no pueden acceder a la aplicación
- ❌ Testing de OAuth y funcionalidad bloqueado

---

## ✅ Justificación Técnica

### 1. **Naturaleza del Servicio**

El servicio `adyela-web-staging` es un **contenedor Nginx que sirve contenido
estático**:

```
- HTML, CSS, JavaScript (bundle compilado de React)
- Assets públicos (imágenes, fonts)
- NO contiene datos sensibles ni PHI
- NO ejecuta lógica de negocio
```

**Arquitectura**:

```
Usuario → Load Balancer → adyela-web-staging (Nginx) → HTML/JS/CSS
                                    ↓
                         HTML ejecuta en navegador
                                    ↓
                         Llama a adyela-api-staging (autenticado)
```

### 2. **Separación de Seguridad**

| Componente             | Tipo              | Acceso  | Datos Sensibles | Autenticación     |
| ---------------------- | ----------------- | ------- | --------------- | ----------------- |
| **adyela-web-staging** | Frontend estático | Público | NO              | No requerida      |
| **adyela-api-staging** | Backend API       | Privado | SÍ (PHI/HIPAA)  | Firebase + Tenant |

**Toda la seguridad real está en el backend**:

- ✅ `adyela-api-staging` mantiene `--no-allow-unauthenticated`
- ✅ Validación de Firebase Auth token en cada request
- ✅ Tenant isolation middleware (X-Tenant-ID)
- ✅ Acceso a datos PHI protegido con RBAC

### 3. **Estándar de la Industria**

Frontends web modernos **siempre** son públicos:

- Google Cloud Console (console.cloud.google.com)
- Firebase Console (console.firebase.google.com)
- AWS Console (console.aws.amazon.com)

Todos sirven JavaScript estático públicamente y protegen el backend con
autenticación.

---

## 🎯 Solución Requerida

### Opción 1: Excepción de Proyecto (RECOMENDADO)

Permitir `allUsers` solo para el proyecto `adyela-staging`:

```bash
gcloud resource-manager org-policies set-policy policy.yaml \
  --project=adyela-staging
```

**policy.yaml**:

```yaml
name: projects/adyela-staging/policies/iam.allowedPolicyMemberDomains
spec:
  rules:
    - allowAll: true
```

Luego ejecutar:

```bash
gcloud run services add-iam-policy-binding adyela-web-staging \
  --project=adyela-staging \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker"
```

### Opción 2: Excepción de Servicio Específico

Permitir `allUsers` solo para `adyela-web-staging`:

```bash
gcloud resource-manager org-policies set-policy policy.yaml \
  --project=adyela-staging
```

**policy.yaml**:

```yaml
name: projects/adyela-staging/policies/iam.allowedPolicyMemberDomains
spec:
  rules:
    - condition:
        expression: |
          resource.name.endsWith("services/adyela-web-staging")
      allowAll: true
    - denyAll: true
```

---

## 🔒 Garantías de Seguridad

### Lo que NO cambia:

1. ✅ **API Backend** (`adyela-api-staging`) mantiene autenticación estricta
2. ✅ **Secrets** en GCP Secret Manager siguen privados
3. ✅ **PHI/HIPAA data** solo accesible vía API autenticado
4. ✅ **Load Balancer** filtra tráfico malicioso (Cloud Armor disponible)
5. ✅ **VPC connector** mantiene egress privado

### Lo que cambia:

- ✅ Usuarios anónimos pueden **descargar HTML/JS/CSS** del frontend
- ✅ El JavaScript ejecuta en el navegador del usuario (como debe ser)
- ✅ Toda interacción con datos requiere autenticación en el API backend

---

## 📊 Arquitectura de Seguridad

```
┌─────────────────────────────────────────────────────────┐
│                   Internet (Público)                     │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│            Load Balancer (Cloud Armor)                   │
│              https://staging.adyela.care                 │
└──────────────┬─────────────────┬────────────────────────┘
               │                 │
               ▼                 ▼
┌──────────────────────┐  ┌──────────────────────┐
│ adyela-web-staging   │  │ adyela-api-staging   │
│ ✅ Público           │  │ ❌ Privado            │
│ • Nginx + HTML/JS    │  │ • FastAPI            │
│ • Sin datos PHI      │  │ • Firebase Auth      │
│ • allUsers invoker   │  │ • Tenant Middleware  │
└──────────────────────┘  │ • HIPAA Secrets      │
                          │ • NO allUsers        │
                          └──────────────────────┘
```

---

## ⚙️ Comandos de Implementación

### Paso 1: Administrador ejecuta (Nivel Organización)

```bash
# 1. Crear policy.yaml (ver arriba)
# 2. Aplicar excepción
gcloud resource-manager org-policies set-policy policy.yaml \
  --project=adyela-staging

# 3. Verificar
gcloud resource-manager org-policies describe \
  iam.allowedPolicyMemberDomains \
  --project=adyela-staging
```

### Paso 2: Developer ejecuta (Nivel Servicio)

```bash
# Agregar permiso público al frontend
gcloud run services add-iam-policy-binding adyela-web-staging \
  --project=adyela-staging \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker"

# Verificar acceso
curl -I https://staging.adyela.care/
# Esperado: HTTP/2 200 (en vez de 403)
```

---

## 🧪 Plan de Validación

### Después de la excepción:

1. **Frontend accesible**:

   ```bash
   curl https://staging.adyela.care/
   # Debe retornar HTML (no 403)
   ```

2. **API sigue protegido**:

   ```bash
   curl https://staging.adyela.care/api/v1/appointments
   # Debe retornar 401 Unauthorized (autenticación requerida)
   ```

3. **OAuth funcional**:
   - Usuario puede ver login page
   - "Continue with Google" funciona
   - POST a `/api/v1/auth/sync` exitoso

---

## 📞 Contacto

**Solicitante**: Hever González (hever_gonzalezg@adyela.care) **Proyecto GCP**:
adyela-staging **ID Proyecto**: 717907307897 **Región**: us-central1

---

## 📚 Referencias

- [Cloud Run Authentication](https://cloud.google.com/run/docs/securing/managing-access)
- [IAM Organization Policies](https://cloud.google.com/resource-manager/docs/organization-policy/overview)
- [HIPAA Compliance on GCP](https://cloud.google.com/security/compliance/hipaa)

---

**Última actualización**: 2025-10-12 **Estado**: Pendiente aprobación
**Prioridad**: Alta (bloqueador de testing)
