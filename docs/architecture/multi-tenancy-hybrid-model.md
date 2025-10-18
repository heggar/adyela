# Modelo de Multi-Tenancy Híbrido

## 📊 Resumen Ejecutivo

Este documento define el modelo de multi-tenancy híbrido para Adyela, combinando
**Pool Model** (infraestructura compartida) para tiers Free/Pro y **Silo Model**
(infraestructura dedicada) para tier Enterprise.

**Decisión Arquitectónica**: Cada profesional de salud independiente es un
**tenant**.

**Modelo**:

- **Tier Free/Pro**: Pool model (todos comparten infraestructura)
- **Tier Enterprise**: Silo model (infraestructura dedicada por tenant)

---

## 🏗️ Modelos de Multi-Tenancy

### Pool Model (Shared Infrastructure)

**Qué es**: Todos los tenants comparten la misma instancia de aplicación y base
de datos, pero los datos están lógicamente aislados.

**Pros** ✅:

- Costo eficiente (un deployment para todos)
- Fácil de escalar horizontalmente
- Mantenimiento simplificado (una versión)
- Onboarding rápido (sin provisioning)

**Cons** ❌:

- Tenant ruidoso puede afectar a otros (noisy neighbor)
- Menos personalización por tenant
- Complejidad en data isolation

**Cuándo usar**: **Tier Free, Tier Pro** (mayoría de profesionales)

---

### Silo Model (Dedicated Infrastructure)

**Qué es**: Cada tenant tiene su propia instancia de aplicación y/o base de
datos.

**Pros** ✅:

- Aislamiento completo (performance, security)
- Personalización total por tenant
- SLA dedicado

**Cons** ❌:

- Costoso (N instancias para N tenants)
- Complejo de mantener (N deployments)
- Onboarding lento (provisioning infrastructure)

**Cuándo usar**: **Tier Enterprise** (grandes organizaciones, hospitales)

---

## 🎯 Estrategia Híbrida Adyela

### Segmentación por Tier

| Tier           | Modelo | Infraestructura | Firestore                     | Cloud Run         |
| -------------- | ------ | --------------- | ----------------------------- | ----------------- |
| **Free**       | Pool   | Compartida      | Shared DB (logical isolation) | Shared instances  |
| **Pro**        | Pool   | Compartida      | Shared DB (logical isolation) | Shared instances  |
| **Enterprise** | Silo   | Dedicada        | Dedicated DB (optional)       | Dedicated service |

### Criterios para Enterprise (Silo)

Un tenant califica para silo model si cumple >= 2 de:

- ✅ >500 pacientes activos/mes
- ✅ >$2,000/mes en revenue
- ✅ Requisitos de compliance estrictos (HIPAA, certificaciones)
- ✅ Data residency específico (ej: Brasil requiere data en Brasil)
- ✅ SLA custom (99.99%+ uptime)
- ✅ Personalización de plataforma (white-label)

---

## 🗄️ Diseño de Datos: Firestore Multi-Tenant

### Estructura Actual (Single-Tenant)

```
/users/{userId}
/appointments/{appointmentId}
/patients/{patientId}
/professionals/{professionalId}
```

**Problema**: No hay aislamiento por tenant, todos los datos en flat
collections.

### Estructura Objetivo (Multi-Tenant - Pool Model)

```
/tenants/{tenantId}/                     # Tenant root
  /users/{userId}                        # Usuarios del tenant
  /appointments/{appointmentId}          # Citas del tenant
  /patients/{patientId}                  # Pacientes del tenant
  /professionals/{professionalId}        # Profesionales del tenant (si hay colaboradores)
  /settings/config                       # Configuración del tenant

/users/{userId}/                         # Global users (cross-tenant)
  /tenants/{tenantId}                    # Tenants a los que pertenece
```

**Nota**: Un paciente puede tener citas con múltiples profesionales (múltiples
tenants), pero cada cita pertenece a un solo tenant.

### Ejemplo Concreto

**Tenant**: Dr. Carlos García (Psicólogo)

- `tenant_id`: `tenant_carlos_garcia_123`

**Paciente**: María López

- `user_id`: `user_maria_lopez_456`

**Estructura Firestore**:

```
/tenants/tenant_carlos_garcia_123/
  /appointments/appt_001
    {
      patient_id: "user_maria_lopez_456",
      professional_id: "user_carlos_garcia_123",
      scheduled_at: "2025-10-20T10:00:00Z",
      status: "CONFIRMED",
      notes: "Primera consulta de ansiedad"  // PHI
    }

  /patients/user_maria_lopez_456  # Metadata del paciente EN ESTE TENANT
    {
      user_id: "user_maria_lopez_456",
      first_visit_date: "2025-10-20T10:00:00Z",
      total_visits: 1,
      last_visit_date: "2025-10-20T10:00:00Z"
    }

/users/user_maria_lopez_456/  # Usuario global
  {
    name: "María López",
    email: "maria@example.com",
    phone: "+57 300 123 4567",
    role: "patient"
  }

  /tenants/tenant_carlos_garcia_123  # Tenants a los que pertenece
    {
      professional_name: "Dr. Carlos García",
      specialty: "Psicología",
      joined_at: "2025-10-20T10:00:00Z"
    }
```

**Ventajas de esta estructura**:

- ✅ Aislamiento lógico por tenant
- ✅ Queries eficientes (scope a tenant)
- ✅ Usuario puede tener citas con múltiples profesionales
- ✅ Cada tenant solo ve sus propios datos

### Firestore Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function: check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper function: get user's role
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }

    // Helper function: check if user belongs to tenant
    function belongsToTenant(tenantId) {
      return exists(/databases/$(database)/documents/users/$(request.auth.uid)/tenants/$(tenantId));
    }

    // Tenants collection
    match /tenants/{tenantId} {
      // Only authenticated users
      allow read: if isAuthenticated() && belongsToTenant(tenantId);
      allow write: if false;  // Only backend can write tenant metadata

      // Appointments within tenant
      match /appointments/{appointmentId} {
        allow read: if isAuthenticated() &&
          (request.auth.uid == resource.data.patient_id ||  // Patient can read their own
           request.auth.uid == resource.data.professional_id);  // Professional can read

        allow create: if isAuthenticated() &&
          request.auth.uid == request.resource.data.patient_id &&  // Patient creating
          belongsToTenant(tenantId);

        allow update: if isAuthenticated() &&
          (request.auth.uid == resource.data.patient_id ||  // Patient can update
           request.auth.uid == resource.data.professional_id);  // Professional can update

        allow delete: if isAuthenticated() &&
          request.auth.uid == resource.data.professional_id;  // Only professional can delete
      }

      // Patients within tenant
      match /patients/{patientId} {
        allow read: if isAuthenticated() &&
          (request.auth.uid == patientId ||  // Patient reads themselves
           request.auth.uid == tenantId);  // Professional (tenant owner) reads

        allow write: if isAuthenticated() &&
          request.auth.uid == tenantId;  // Only professional can write
      }

      // Settings
      match /settings/config {
        allow read: if isAuthenticated() && request.auth.uid == tenantId;
        allow write: if isAuthenticated() && request.auth.uid == tenantId;
      }
    }

    // Global users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && request.auth.uid == userId;

      match /tenants/{tenantId} {
        allow read: if isAuthenticated() && request.auth.uid == userId;
        allow write: if false;  // Only backend can associate user with tenant
      }
    }
  }
}
```

### Queries Multi-Tenant

**Obtener todas las citas de un profesional (tenant)**:

```python
# Backend
from google.cloud import firestore

db = firestore.Client()

def get_tenant_appointments(tenant_id: str, status: str = None):
    """Get all appointments for a tenant"""
    query = db.collection("tenants").document(tenant_id).collection("appointments")

    if status:
        query = query.where("status", "==", status)

    query = query.order_by("scheduled_at", direction=firestore.Query.DESCENDING)

    appointments = []
    for doc in query.stream():
        appointments.append(doc.to_dict())

    return appointments
```

**Obtener todas las citas de un paciente (across all tenants)**:

```python
def get_patient_appointments(patient_id: str):
    """Get all appointments for a patient across all tenants"""
    # Get tenants where patient has appointments
    user_tenants = db.collection("users").document(patient_id).collection("tenants").stream()

    all_appointments = []

    for tenant_ref in user_tenants:
        tenant_id = tenant_ref.id

        # Query appointments in this tenant
        appointments = db.collection("tenants").document(tenant_id)\
                         .collection("appointments")\
                         .where("patient_id", "==", patient_id)\
                         .order_by("scheduled_at", direction=firestore.Query.DESCENDING)\
                         .stream()

        for appt_doc in appointments:
            appt = appt_doc.to_dict()
            appt["tenant_id"] = tenant_id
            all_appointments.append(appt)

    # Sort by date
    all_appointments.sort(key=lambda x: x["scheduled_at"], reverse=True)

    return all_appointments
```

### Indexes Multi-Tenant

```
# firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "appointments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "professional_id", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "scheduled_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "appointments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "patient_id", "order": "ASCENDING" },
        { "fieldPath": "scheduled_at", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Deploy indexes**:

```bash
firebase deploy --only firestore:indexes
```

---

## 🏢 Silo Model para Enterprise

### Dedicated Cloud Run Service

**Terraform configuration para tenant enterprise**:

```hcl
# infra/modules/microservices/api-appointments-enterprise/main.tf
resource "google_cloud_run_service" "api_appointments_enterprise" {
  for_each = var.enterprise_tenants  # Map of tenant_id => config

  name     = "api-appointments-${each.key}"
  location = var.region

  metadata {
    labels = {
      tenant_id   = each.key
      tier        = "enterprise"
      environment = var.environment
    }
  }

  template {
    metadata {
      labels = {
        tenant_id = each.key
      }
      annotations = {
        "autoscaling.knative.dev/minScale" = "1"  # Always 1 instance minimum
        "autoscaling.knative.dev/maxScale" = each.value.max_scale
      }
    }

    spec {
      service_account_name = google_service_account.api_appointments_enterprise[each.key].email

      containers {
        image = var.appointments_image

        env {
          name  = "TENANT_ID"
          value = each.key
        }

        env {
          name  = "FIRESTORE_COLLECTION_PREFIX"
          value = "tenants/${each.key}"  # Dedicated collection prefix
        }

        env {
          name  = "TIER"
          value = "enterprise"
        }

        resources {
          limits = {
            cpu    = each.value.cpu
            memory = each.value.memory
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Service account per enterprise tenant
resource "google_service_account" "api_appointments_enterprise" {
  for_each = var.enterprise_tenants

  account_id   = "api-appt-${each.key}"
  display_name = "API Appointments - Enterprise Tenant ${each.key}"
}

# IAM binding: specific to tenant's resources
resource "google_project_iam_member" "enterprise_firestore_access" {
  for_each = var.enterprise_tenants

  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.api_appointments_enterprise[each.key].email}"
}
```

**Variables**:

```hcl
# infra/envs/production/terraform.tfvars
enterprise_tenants = {
  "hospital_san_jose" = {
    max_scale = 100
    cpu       = "2000m"
    memory    = "2Gi"
  },
  "clinica_vida" = {
    max_scale = 50
    cpu       = "1000m"
    memory    = "1Gi"
  }
}
```

### Dedicated Firestore Database (Optional - Extreme Isolation)

Para tenants que requieren compliance estricto:

```hcl
# infra/modules/data/firestore-enterprise/main.tf
resource "google_firestore_database" "enterprise_tenant" {
  for_each = var.enterprise_tenants_dedicated_db

  project     = var.project_id
  name        = "tenant-${each.key}"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  # Different from default database
}
```

**Costo**: ~$50/mes por database adicional (solo para casos extremos)

---

## 💰 Cost Attribution Multi-Tenancy

### Pool Model: Cost Proration

Costo total compartido se distribuye por:

1. **Operational metrics** (60% del costo):
   - API calls por tenant
   - Storage usado (documentos, archivos)
   - Egress bandwidth

2. **User-based** (40% del costo):
   - # usuarios activos (MAU)
   - # citas creadas/mes

**Implementación**:

```python
# apps/api-analytics/calculate_tenant_cost.py
from google.cloud import firestore, billing

def calculate_monthly_cost_attribution(month: str):
    """Calculate cost attribution for all pool-model tenants"""

    # Get total infrastructure cost for the month
    total_cost = get_total_infrastructure_cost(month)

    # Get usage metrics per tenant
    tenant_metrics = {}

    for tenant_id in get_all_pool_tenants():
        tenant_metrics[tenant_id] = {
            "api_calls": get_api_calls(tenant_id, month),
            "storage_gb": get_storage_used(tenant_id, month),
            "egress_gb": get_egress_bandwidth(tenant_id, month),
            "active_users": get_active_users(tenant_id, month),
            "appointments_created": get_appointments_count(tenant_id, month)
        }

    # Calculate weight per tenant
    total_api_calls = sum(m["api_calls"] for m in tenant_metrics.values())
    total_storage = sum(m["storage_gb"] for m in tenant_metrics.values())
    total_egress = sum(m["egress_gb"] for m in tenant_metrics.values())
    total_users = sum(m["active_users"] for m in tenant_metrics.values())
    total_appointments = sum(m["appointments_created"] for m in tenant_metrics.values())

    # Prorate cost
    tenant_costs = {}

    for tenant_id, metrics in tenant_metrics.items():
        operational_cost = total_cost * 0.6 * (
            (metrics["api_calls"] / total_api_calls * 0.4) +
            (metrics["storage_gb"] / total_storage * 0.3) +
            (metrics["egress_gb"] / total_egress * 0.3)
        )

        user_cost = total_cost * 0.4 * (
            (metrics["active_users"] / total_users * 0.5) +
            (metrics["appointments_created"] / total_appointments * 0.5)
        )

        tenant_costs[tenant_id] = operational_cost + user_cost

    return tenant_costs

# Save to Cloud SQL for reporting
def save_cost_attribution(tenant_costs, month):
    db = get_postgres_connection()

    for tenant_id, cost in tenant_costs.items():
        db.execute(
            """
            INSERT INTO tenant_costs (tenant_id, month, attributed_cost)
            VALUES (%s, %s, %s)
            ON CONFLICT (tenant_id, month) DO UPDATE SET attributed_cost = EXCLUDED.attributed_cost
            """,
            (tenant_id, month, cost)
        )

    db.commit()
```

### Silo Model: Direct Cost Attribution

Cada recurso está etiquetado con `tenant_id`:

```hcl
# Resources with labels
resource "google_cloud_run_service" "api_appointments_enterprise" {
  metadata {
    labels = {
      tenant_id   = each.key
      tier        = "enterprise"
      cost_center = "healthcare"
    }
  }
}
```

**Query billing**:

```sql
-- BigQuery billing export
SELECT
  labels.key as tenant_id,
  SUM(cost) as total_cost
FROM `project.billing_export.gcp_billing_export_v1_XXXXX`
WHERE labels.key IN ('tenant_id')
  AND DATE(usage_start_time) >= '2025-10-01'
  AND DATE(usage_end_time) < '2025-11-01'
GROUP BY labels.key
ORDER BY total_cost DESC
```

---

## 🔄 Data Migration Strategy

### Migración: Single-Tenant → Multi-Tenant

**Script de migración**:

```python
# scripts/migrate-to-multitenant.py
from google.cloud import firestore
import logging

logger = logging.getLogger(__name__)
db = firestore.Client()

DEFAULT_TENANT_ID = "adyela-clinic"  # Existing clinic becomes first tenant

async def migrate_to_multitenant():
    """Migrate existing single-tenant data to multi-tenant structure"""

    # Step 1: Create default tenant
    logger.info(f"Creating default tenant: {DEFAULT_TENANT_ID}")
    db.collection("tenants").document(DEFAULT_TENANT_ID).set({
        "name": "Adyela Clinic",
        "tier": "pro",
        "created_at": firestore.SERVER_TIMESTAMP,
        "migrated_from_legacy": True
    })

    # Step 2: Migrate collections
    collections_to_migrate = ["appointments", "patients", "users"]

    for collection_name in collections_to_migrate:
        logger.info(f"Migrating collection: {collection_name}")

        # Read all docs from old structure
        old_docs = db.collection(collection_name).stream()

        batch = db.batch()
        count = 0

        for doc in old_docs:
            # Create doc in new multi-tenant structure
            new_ref = db.collection("tenants").document(DEFAULT_TENANT_ID)\
                        .collection(collection_name).document(doc.id)

            batch.set(new_ref, doc.to_dict())
            count += 1

            # Commit every 500 docs (Firestore batch limit)
            if count % 500 == 0:
                batch.commit()
                batch = db.batch()
                logger.info(f"Migrated {count} {collection_name} documents")

        # Final commit
        if count % 500 != 0:
            batch.commit()

        logger.info(f"Migration complete: {count} {collection_name} documents")

    # Step 3: Verify migration
    for collection_name in collections_to_migrate:
        old_count = len(list(db.collection(collection_name).stream()))
        new_count = len(list(db.collection("tenants").document(DEFAULT_TENANT_ID)\
                                .collection(collection_name).stream()))

        logger.info(f"{collection_name}: old={old_count}, new={new_count}")
        assert old_count == new_count, f"Migration verification failed for {collection_name}"

    logger.info("✅ Migration completed successfully")

# Run migration
if __name__ == "__main__":
    import asyncio
    asyncio.run(migrate_to_multitenant())
```

**Rollback plan**:

```python
async def rollback_migration():
    """Rollback migration if something goes wrong"""

    logger.warning("Rolling back migration...")

    # Copy data back to old structure
    collections = ["appointments", "patients", "users"]

    for collection_name in collections:
        new_docs = db.collection("tenants").document(DEFAULT_TENANT_ID)\
                     .collection(collection_name).stream()

        batch = db.batch()
        count = 0

        for doc in new_docs:
            old_ref = db.collection(collection_name).document(doc.id)
            batch.set(old_ref, doc.to_dict())
            count += 1

            if count % 500 == 0:
                batch.commit()
                batch = db.batch()

        if count % 500 != 0:
            batch.commit()

        logger.info(f"Rolled back {count} {collection_name} documents")

    logger.warning("⏪ Rollback complete")
```

---

## ✅ Checklist de Implementación

### Fase 0 (Mes 1-2)

- [ ] **Firestore schema** diseñado (multi-tenant)
- [ ] **Data migration script** escrito y testeado
- [ ] **Security rules** actualizadas para multi-tenant
- [ ] **Indexes** creados
- [ ] **Migration dry-run** ejecutada en staging

### Fase 1 (Mes 3-6)

- [ ] **Production migration** ejecutada
- [ ] **Verification** de data integrity
- [ ] **Rollback plan** documentado
- [ ] **Pool model** funcionando (tier Free/Pro)

### Fase 2 (Mes 7-12)

- [ ] **Silo model Terraform** implementado
- [ ] **Cost attribution** automatizado
- [ ] **Primer enterprise tenant** onboarded
- [ ] **Dashboards multi-tenant** creados

---

**Documento**: `docs/architecture/multi-tenancy-hybrid-model.md` **Version**:
1.0 **Última actualización**: 2025-10-18 **Owner**: Architecture + Backend Team
