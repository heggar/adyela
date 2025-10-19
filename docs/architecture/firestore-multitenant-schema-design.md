# 🗄️ Firestore Multi-Tenant Schema Design - Adyela

**Version:** 2.0 **Date:** 2025-10-19 **Status:** ✅ Complete Design - Ready for
Implementation **Task:** 13.1 - Design Multi-Tenant Firestore Schema
Architecture

---

## 📋 Executive Summary

This document defines the complete Firestore multi-tenant schema architecture
for Adyela, including collection structure, document hierarchy, tenant isolation
patterns, and migration strategy from the current single-tenant model to
multi-tenant.

**Key Decisions:**

- ✅ **Hybrid Model**: Pool model for Free/Pro tiers + Silo model for Enterprise
- ✅ **Tenant = Healthcare Professional/Organization**
- ✅ **Nested Collections**: `/tenants/{tenantId}/appointments/{appointmentId}`
- ✅ **Logical Isolation**: Firestore security rules enforce tenant boundaries
- ✅ **Backward Compatibility**: Migration preserves all existing data

---

## 🎯 Design Goals

1. **Tenant Isolation**: Complete data isolation between tenants (HIPAA
   compliance)
2. **Scalability**: Support 10,000+ tenants in pool model
3. **Performance**: Efficient queries with proper indexing
4. **Maintainability**: Clear schema that's easy to understand and extend
5. **Migration Safety**: Zero downtime migration from single-tenant

---

## 🏗️ Current State (Single-Tenant)

### Current Collection Structure

```
/appointments/{appointmentId}
/users/{userId}
/patients/{patientId}
/practitioners/{practitionerId}
/notifications/{notificationId}
/audit_logs/{logId}
```

**Problems:**

- ❌ No tenant isolation (all data mixed together)
- ❌ Queries fetch data across all tenants (security risk)
- ❌ Can't scale to multiple healthcare organizations
- ❌ HIPAA violation risk (data bleed between professionals)

### Current Code Pattern

```python
# apps/api/adyela_api/infrastructure/repositories/firestore_appointment_repository.py
class FirestoreAppointmentRepository:
    def __init__(self, db: firestore.Client):
        self.db = db
        self.collection = "appointments"  # ❌ Flat collection

    async def list_by_patient(self, tenant_id: str, patient_id: str):
        # ⚠️ Uses tenant_id in WHERE clause but collection is shared
        docs = (
            self.db.collection(self.collection)
            .where("tenant_id", "==", tenant_id)  # Filtering only, no isolation
            .where("patient_id", "==", patient_id)
            .stream()
        )
```

**Issue**: `tenant_id` is used in queries but collection is flat. Security rules
can't enforce tenant boundaries efficiently.

---

## 🎯 Target State (Multi-Tenant)

### Multi-Tenant Collection Structure

```
/tenants/{tenantId}/                           # Tenant root document
  ├── /appointments/{appointmentId}            # Tenant's appointments
  ├── /patients/{patientId}                    # Tenant's patient metadata
  ├── /practitioners/{practitionerId}          # Tenant's staff (if multi-professional practice)
  ├── /settings/configuration                  # Tenant's settings
  ├── /availability/{availabilityId}           # Practitioner availability slots
  ├── /prescriptions/{prescriptionId}          # Medical prescriptions (PHI)
  └── /medical_records/{recordId}              # Medical records (PHI)

/users/{userId}/                               # Global users (cross-tenant)
  ├── /tenants/{tenantId}                      # Tenants user belongs to
  └── /sessions/{sessionId}                    # User auth sessions

/organizations/{orgId}/                        # Enterprise organizations (Silo model)
  ├── /tenants/{tenantId}                      # Tenants in this organization
  └── /settings/configuration                  # Organization settings

/audit_logs/{logId}                            # Global audit logs (compliance)
/notifications_queue/{notificationId}          # Global notification queue
```

---

## 📊 Detailed Schema Design

### 1. Tenant Document

**Path:** `/tenants/{tenantId}`

**Document ID Pattern:** `tenant_{professionalId}_{randomSuffix}`

- Example: `tenant_dr_carlos_garcia_a7b3c2`

**Document Structure:**

```typescript
interface Tenant {
  id: string; // tenant_dr_carlos_garcia_a7b3c2
  owner_id: string; // user_carlos_garcia_123
  name: string; // "Dr. Carlos García - Psicología"
  tier: 'free' | 'pro' | 'enterprise';
  status: 'active' | 'suspended' | 'cancelled';

  // Contact info
  email: string; // carlos.garcia@adyela.care
  phone: string; // +57 300 123 4567

  // Organization info (optional for enterprise)
  organization_id?: string; // org_hospital_san_jose

  // Metadata
  created_at: Timestamp;
  updated_at: Timestamp;
  migrated_from_legacy: boolean; // true if migrated from old structure

  // Billing
  subscription_expires_at?: Timestamp;
  payment_method_id?: string;

  // Settings
  timezone: string; // "America/Bogota"
  language: string; // "es"

  // Statistics (denormalized for dashboard)
  stats: {
    total_appointments: number;
    total_patients: number;
    total_revenue: number;
    last_appointment_date: Timestamp;
  };
}
```

---

### 2. Appointments Subcollection

**Path:** `/tenants/{tenantId}/appointments/{appointmentId}`

**Document ID:** Auto-generated Firestore ID

**Document Structure:**

```typescript
interface Appointment {
  id: string; // Auto-generated
  tenant_id: string; // tenant_dr_carlos_garcia_a7b3c2 (denormalized)

  // Participants
  patient_id: string; // user_maria_lopez_456
  practitioner_id: string; // user_carlos_garcia_123

  // Scheduling
  start_time: Timestamp;
  end_time: Timestamp;
  duration_minutes: number; // 30
  timezone: string; // "America/Bogota"

  // Type
  type: 'in_person' | 'video_call' | 'phone_call';

  // Status
  status:
    | 'scheduled'
    | 'confirmed'
    | 'in_progress'
    | 'completed'
    | 'cancelled'
    | 'no_show';
  cancellation_reason?: string;
  cancelled_by?: string; // user_id who cancelled
  cancelled_at?: Timestamp;

  // Clinical (PHI - Protected Health Information)
  reason: string; // "Primera consulta de ansiedad"
  notes?: string; // Clinical notes (only visible to practitioner)
  diagnosis_codes?: string[]; // ICD-10 codes

  // Video call (if applicable)
  video_room_id?: string; // jitsi_room_abc123
  video_room_url?: string;

  // Metadata
  created_at: Timestamp;
  updated_at: Timestamp;
  created_by: string; // user_id

  // Payment (optional)
  payment_status?: 'pending' | 'paid' | 'failed';
  payment_amount?: number;
  payment_currency?: string; // "COP"
}
```

**Indexes Required:**

```json
{
  "collectionGroup": "appointments",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "patient_id", "order": "ASCENDING" },
    { "fieldPath": "start_time", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "appointments",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "practitioner_id", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "start_time", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "appointments",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "start_time", "order": "ASCENDING" }
  ]
}
```

---

### 3. Patients Subcollection

**Path:** `/tenants/{tenantId}/patients/{patientId}`

**Document ID:** Same as global user ID (`user_maria_lopez_456`)

**Purpose:** Store patient metadata **specific to this tenant** (not PHI)

**Document Structure:**

```typescript
interface PatientMetadata {
  id: string; // user_maria_lopez_456
  user_id: string; // user_maria_lopez_456 (redundant but useful)
  tenant_id: string; // tenant_dr_carlos_garcia_a7b3c2

  // Relationship metadata (NON-PHI)
  first_visit_date: Timestamp;
  last_visit_date: Timestamp;
  total_visits: number;
  next_appointment_date?: Timestamp;

  // Status in THIS tenant
  status: 'active' | 'inactive';

  // Preferences (tenant-specific)
  preferred_appointment_time?: string; // "morning" | "afternoon" | "evening"
  communication_preference?: 'email' | 'sms' | 'whatsapp';

  // Tags (for organization)
  tags?: string[]; // ["alta-prioridad", "seguimiento-mensual"]

  // Financial (tenant-specific)
  outstanding_balance?: number;
  payment_method_id?: string;

  // Metadata
  created_at: Timestamp;
  updated_at: Timestamp;
}
```

**Note:** Actual patient PII (name, email, phone) is in `/users/{userId}`, not
here.

---

### 4. Global Users Collection

**Path:** `/users/{userId}`

**Document ID Pattern:** `user_{firstName}_{lastName}_{randomSuffix}`

- Example: `user_maria_lopez_456`

**Document Structure:**

```typescript
interface User {
  id: string; // user_maria_lopez_456

  // PII (Protected Personally Identifiable Information)
  email: string; // maria.lopez@example.com
  phone: string; // +57 300 123 4567
  first_name: string; // "María"
  last_name: string; // "López"

  // Profile
  photo_url?: string;
  date_of_birth?: Timestamp; // PHI
  gender?: 'male' | 'female' | 'other' | 'prefer_not_to_say';

  // Address (PHI if medical context)
  address?: {
    street: string;
    city: string;
    state: string;
    country: string;
    postal_code: string;
  };

  // Role (global)
  role: 'patient' | 'practitioner' | 'admin';

  // Auth
  firebase_uid: string; // Firebase Auth UID
  email_verified: boolean;
  phone_verified: boolean;

  // Metadata
  created_at: Timestamp;
  updated_at: Timestamp;
  last_login_at?: Timestamp;

  // Security
  account_locked: boolean;
  locked_reason?: string;
  locked_at?: Timestamp;
}
```

---

### 5. User Tenants Subcollection

**Path:** `/users/{userId}/tenants/{tenantId}`

**Purpose:** Track which tenants a user belongs to (many-to-many relationship)

**Document Structure:**

```typescript
interface UserTenant {
  id: string; // tenant_dr_carlos_garcia_a7b3c2
  tenant_id: string; // tenant_dr_carlos_garcia_a7b3c2
  user_id: string; // user_maria_lopez_456

  // Tenant info (denormalized for quick access)
  tenant_name: string; // "Dr. Carlos García - Psicología"
  tenant_specialty?: string; // "Psicología"
  tenant_photo_url?: string;

  // Relationship
  role_in_tenant: 'patient' | 'practitioner' | 'staff';
  joined_at: Timestamp;
  last_interaction_at: Timestamp;

  // Status
  status: 'active' | 'inactive';
}
```

---

### 6. Tenant Settings

**Path:** `/tenants/{tenantId}/settings/configuration`

**Document ID:** Fixed: `configuration`

**Document Structure:**

```typescript
interface TenantSettings {
  // Business hours
  business_hours: {
    monday: { start: string; end: string; enabled: boolean };
    tuesday: { start: string; end: string; enabled: boolean };
    // ... other days
  };

  // Appointment settings
  default_appointment_duration: number; // 30 minutes
  appointment_buffer: number; // 15 minutes between appointments
  advance_booking_days: number; // 30 days
  cancellation_policy_hours: number; // 24 hours

  // Notifications
  send_appointment_reminders: boolean;
  reminder_hours_before: number; // 24 hours

  // Branding (for enterprise)
  logo_url?: string;
  primary_color?: string; // #3B82F6
  custom_domain?: string; // salud.clinicavida.com

  // Integrations
  video_call_provider: 'jitsi' | 'zoom' | 'teams';
  payment_provider?: 'stripe' | 'mercadopago';

  // Compliance
  require_patient_consent: boolean;
  data_retention_days: number; // 2555 days (7 years HIPAA)

  // Multi-tenancy tier
  tier: 'free' | 'pro' | 'enterprise';
  features_enabled: string[]; // ["video_calls", "prescriptions", "analytics"]
}
```

---

### 7. Audit Logs (Global)

**Path:** `/audit_logs/{logId}`

**Document ID:** Auto-generated

**Purpose:** HIPAA compliance - log all PHI access

**Document Structure:**

```typescript
interface AuditLog {
  id: string;

  // Who
  user_id: string; // user_carlos_garcia_123
  user_email: string; // carlos@example.com
  user_role: string; // "practitioner"

  // What
  action: 'VIEW' | 'CREATE' | 'UPDATE' | 'DELETE' | 'EXPORT';
  resource_type: 'appointment' | 'patient' | 'prescription' | 'medical_record';
  resource_id: string;

  // Where (tenant context)
  tenant_id: string; // tenant_dr_carlos_garcia_a7b3c2

  // PHI access (if applicable)
  phi_accessed: boolean;
  phi_fields?: string[]; // ["diagnosis", "notes"]

  // Why (optional)
  reason?: string; // "Scheduled appointment"

  // How
  ip_address: string;
  user_agent: string;

  // When
  timestamp: Timestamp;

  // Metadata
  success: boolean;
  error_message?: string;
}
```

**Retention:** 7 years (HIPAA requirement)

---

## 🔒 Firestore Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function getUserId() {
      return request.auth.uid;
    }

    function getTenantOwner(tenantId) {
      return get(/databases/$(database)/documents/tenants/$(tenantId)).data.owner_id;
    }

    function belongsToTenant(tenantId) {
      return exists(/databases/$(database)/documents/users/$(getUserId())/tenants/$(tenantId));
    }

    function isTenantOwner(tenantId) {
      return getUserId() == getTenantOwner(tenantId);
    }

    // ===================
    // TENANTS
    // ===================
    match /tenants/{tenantId} {
      // Read: Must belong to tenant
      allow read: if isAuthenticated() && belongsToTenant(tenantId);

      // Write: Only backend (Cloud Functions)
      allow write: if false;

      // --- APPOINTMENTS ---
      match /appointments/{appointmentId} {
        // Read: Patient OR practitioner can read
        allow read: if isAuthenticated() && (
          getUserId() == resource.data.patient_id ||
          getUserId() == resource.data.practitioner_id ||
          isTenantOwner(tenantId)
        );

        // Create: Patient can create in their tenant
        allow create: if isAuthenticated() &&
          getUserId() == request.resource.data.patient_id &&
          belongsToTenant(tenantId) &&
          request.resource.data.tenant_id == tenantId;  // Ensure tenant_id matches

        // Update: Patient OR practitioner can update
        allow update: if isAuthenticated() && (
          getUserId() == resource.data.patient_id ||
          getUserId() == resource.data.practitioner_id ||
          isTenantOwner(tenantId)
        );

        // Delete: Only practitioner/owner
        allow delete: if isAuthenticated() && (
          getUserId() == resource.data.practitioner_id ||
          isTenantOwner(tenantId)
        );
      }

      // --- PATIENTS ---
      match /patients/{patientId} {
        // Read: Patient reads themselves OR practitioner reads their patients
        allow read: if isAuthenticated() && (
          getUserId() == patientId ||
          isTenantOwner(tenantId)
        );

        // Write: Only practitioner/owner
        allow write: if isAuthenticated() && isTenantOwner(tenantId);
      }

      // --- SETTINGS ---
      match /settings/configuration {
        // Read: Anyone in tenant
        allow read: if isAuthenticated() && belongsToTenant(tenantId);

        // Write: Only tenant owner
        allow write: if isAuthenticated() && isTenantOwner(tenantId);
      }
    }

    // ===================
    // USERS (Global)
    // ===================
    match /users/{userId} {
      // Read: User reads themselves
      allow read: if isAuthenticated() && getUserId() == userId;

      // Create: User creates themselves
      allow create: if isAuthenticated() && getUserId() == userId;

      // Update: User updates themselves
      allow update: if isAuthenticated() && getUserId() == userId;

      // Delete: No one (use Cloud Function with admin)
      allow delete: if false;

      // --- USER TENANTS ---
      match /tenants/{tenantId} {
        // Read: User reads their own tenant memberships
        allow read: if isAuthenticated() && getUserId() == userId;

        // Write: Only backend (Cloud Functions)
        allow write: if false;
      }
    }

    // ===================
    // AUDIT LOGS (Global)
    // ===================
    match /audit_logs/{logId} {
      // Read: Only admins (backend only)
      allow read: if false;

      // Write: Only backend (Cloud Functions)
      allow write: if false;
    }
  }
}
```

---

## 🔄 Migration Strategy

### Phase 0: Preparation (Week 1-2)

**Tasks:**

1. ✅ Design schema (this document)
2. Create migration script
3. Test in development
4. Backup production data
5. Create rollback plan

---

### Phase 1: Data Migration (Week 3)

**Migration Script:**

```python
# scripts/migrate_to_multitenant.py
import asyncio
from google.cloud import firestore
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

db = firestore.Client()

# Default tenant for existing data
DEFAULT_TENANT_ID = "tenant_legacy_clinic_001"
DEFAULT_TENANT_NAME = "Adyela Legacy Clinic"

async def create_default_tenant():
    """Create default tenant for migration"""
    logger.info(f"Creating default tenant: {DEFAULT_TENANT_ID}")

    tenant_ref = db.collection("tenants").document(DEFAULT_TENANT_ID)
    tenant_ref.set({
        "id": DEFAULT_TENANT_ID,
        "name": DEFAULT_TENANT_NAME,
        "tier": "pro",
        "status": "active",
        "created_at": firestore.SERVER_TIMESTAMP,
        "migrated_from_legacy": True,
        "stats": {
            "total_appointments": 0,
            "total_patients": 0,
            "total_revenue": 0,
        }
    })

    logger.info("✅ Default tenant created")

async def migrate_appointments():
    """Migrate appointments to multi-tenant structure"""
    logger.info("Migrating appointments...")

    # Read all old appointments
    old_appointments = db.collection("appointments").stream()

    batch = db.batch()
    count = 0

    for old_doc in old_appointments:
        # New path with tenant
        new_ref = db.collection("tenants").document(DEFAULT_TENANT_ID)\\
                    .collection("appointments").document(old_doc.id)

        # Get data and add tenant_id
        data = old_doc.to_dict()
        data["tenant_id"] = DEFAULT_TENANT_ID

        if "migrated_at" not in data:
            data["migrated_at"] = firestore.SERVER_TIMESTAMP

        batch.set(new_ref, data)
        count += 1

        # Commit every 500 (Firestore limit)
        if count % 500 == 0:
            await batch.commit()
            batch = db.batch()
            logger.info(f"  Migrated {count} appointments...")

    # Final commit
    if count % 500 != 0:
        await batch.commit()

    logger.info(f"✅ Migrated {count} appointments")
    return count

async def migrate_patients():
    """Migrate patients to multi-tenant structure"""
    logger.info("Migrating patients...")

    # Read all old patients
    old_patients = db.collection("patients").stream()

    batch = db.batch()
    count = 0

    for old_doc in old_patients:
        # New path with tenant
        new_ref = db.collection("tenants").document(DEFAULT_TENANT_ID)\\
                    .collection("patients").document(old_doc.id)

        data = old_doc.to_dict()
        data["tenant_id"] = DEFAULT_TENANT_ID
        data["migrated_at"] = firestore.SERVER_TIMESTAMP

        # Convert to PatientMetadata format
        patient_metadata = {
            "id": old_doc.id,
            "user_id": old_doc.id,
            "tenant_id": DEFAULT_TENANT_ID,
            "first_visit_date": data.get("created_at", firestore.SERVER_TIMESTAMP),
            "last_visit_date": data.get("last_visit_date", firestore.SERVER_TIMESTAMP),
            "total_visits": data.get("total_visits", 0),
            "status": "active",
            "created_at": data.get("created_at", firestore.SERVER_TIMESTAMP),
            "updated_at": firestore.SERVER_TIMESTAMP,
            "migrated_at": firestore.SERVER_TIMESTAMP,
        }

        batch.set(new_ref, patient_metadata)
        count += 1

        if count % 500 == 0:
            await batch.commit()
            batch = db.batch()
            logger.info(f"  Migrated {count} patients...")

    if count % 500 != 0:
        await batch.commit()

    logger.info(f"✅ Migrated {count} patients")
    return count

async def create_user_tenant_associations():
    """Create user-tenant associations for all users"""
    logger.info("Creating user-tenant associations...")

    # Get all users
    users = db.collection("users").stream()

    batch = db.batch()
    count = 0

    for user_doc in users:
        user_data = user_doc.to_dict()

        # Create association with default tenant
        assoc_ref = db.collection("users").document(user_doc.id)\\
                      .collection("tenants").document(DEFAULT_TENANT_ID)

        batch.set(assoc_ref, {
            "id": DEFAULT_TENANT_ID,
            "tenant_id": DEFAULT_TENANT_ID,
            "user_id": user_doc.id,
            "tenant_name": DEFAULT_TENANT_NAME,
            "role_in_tenant": user_data.get("role", "patient"),
            "joined_at": user_data.get("created_at", firestore.SERVER_TIMESTAMP),
            "last_interaction_at": firestore.SERVER_TIMESTAMP,
            "status": "active",
        })

        count += 1

        if count % 500 == 0:
            await batch.commit()
            batch = db.batch()
            logger.info(f"  Created {count} user-tenant associations...")

    if count % 500 != 0:
        await batch.commit()

    logger.info(f"✅ Created {count} user-tenant associations")
    return count

async def verify_migration():
    """Verify migration completed successfully"""
    logger.info("Verifying migration...")

    # Count old data
    old_appointments = len(list(db.collection("appointments").stream()))
    old_patients = len(list(db.collection("patients").stream()))

    # Count new data
    new_appointments = len(list(
        db.collection("tenants").document(DEFAULT_TENANT_ID)
          .collection("appointments").stream()
    ))
    new_patients = len(list(
        db.collection("tenants").document(DEFAULT_TENANT_ID)
          .collection("patients").stream()
    ))

    logger.info(f"Appointments: old={old_appointments}, new={new_appointments}")
    logger.info(f"Patients: old={old_patients}, new={new_patients}")

    assert old_appointments == new_appointments, "Appointment migration mismatch!"
    assert old_patients == new_patients, "Patient migration mismatch!"

    logger.info("✅ Migration verification passed")

async def main():
    """Run complete migration"""
    try:
        logger.info("="*60)
        logger.info("Starting Adyela Multi-Tenant Migration")
        logger.info("="*60)

        await create_default_tenant()
        appointments_count = await migrate_appointments()
        patients_count = await migrate_patients()
        users_count = await create_user_tenant_associations()
        await verify_migration()

        logger.info("="*60)
        logger.info("✅ Migration Complete!")
        logger.info(f"  - Appointments: {appointments_count}")
        logger.info(f"  - Patients: {patients_count}")
        logger.info(f"  - User Associations: {users_count}")
        logger.info("="*60)

    except Exception as e:
        logger.error(f"❌ Migration failed: {e}")
        raise

if __name__ == "__main__":
    asyncio.run(main())
```

---

### Phase 2: Code Migration (Week 4-5)

**Update Repository Pattern:**

```python
# apps/api/adyela_api/infrastructure/repositories/firestore_appointment_repository_v2.py
from google.cloud import firestore

class MultiTenantFirestoreAppointmentRepository:
    """Multi-tenant Firestore implementation"""

    def __init__(self, db: firestore.Client):
        self.db = db

    def _get_collection(self, tenant_id: str):
        """Get tenant-scoped collection"""
        return self.db.collection("tenants").document(tenant_id).collection("appointments")

    async def create(self, tenant_id: str, entity: Appointment) -> Appointment:
        """Create appointment in tenant scope"""
        doc_ref = self._get_collection(tenant_id).document()
        entity.id = doc_ref.id
        entity.tenant_id = tenant_id  # Ensure tenant_id is set
        doc_ref.set(entity.to_dict())
        return entity

    async def get_by_id(self, tenant_id: str, entity_id: str) -> Appointment | None:
        """Get appointment by ID within tenant scope"""
        doc = self._get_collection(tenant_id).document(entity_id).get()
        if not doc.exists:
            return None
        return Appointment.from_dict({"id": doc.id, **doc.to_dict()})

    async def list_by_patient(
        self, tenant_id: str, patient_id: str, skip: int = 0, limit: int = 100
    ) -> list[Appointment]:
        """List appointments for patient within tenant"""
        docs = (
            self._get_collection(tenant_id)
            .where("patient_id", "==", patient_id)
            .offset(skip)
            .limit(limit)
            .order_by("start_time", direction=firestore.Query.DESCENDING)
            .stream()
        )
        return [Appointment.from_dict({"id": doc.id, **doc.to_dict()}) for doc in docs]
```

---

### Phase 3: Security Rules Deployment (Week 6)

```bash
# Deploy new security rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes
```

---

### Phase 4: Rollback Plan

**If migration fails:**

```python
# scripts/rollback_migration.py
async def rollback():
    """Rollback to single-tenant structure"""
    logger.warning("Starting rollback...")

    # Copy data back
    new_appointments = db.collection("tenants").document(DEFAULT_TENANT_ID)\\
                         .collection("appointments").stream()

    batch = db.batch()
    for doc in new_appointments:
        old_ref = db.collection("appointments").document(doc.id)
        batch.set(old_ref, doc.to_dict())

    batch.commit()
    logger.info("✅ Rollback complete")
```

---

## 📈 Performance Considerations

### Query Patterns

**✅ Efficient (tenant-scoped):**

```python
# All queries are scoped to tenant automatically
db.collection("tenants").document(tenant_id)\\
  .collection("appointments")\\
  .where("patient_id", "==", patient_id)\\
  .limit(20)
```

**❌ Avoid (collection group queries across all tenants):**

```python
# DON'T do this unless absolutely necessary
db.collection_group("appointments")\\
  .where("patient_id", "==", patient_id)  # Queries ALL tenants!
```

### Denormalization Strategy

**Denormalize frequently accessed data:**

- `tenant_id` in every document (redundant but fast for queries)
- Patient name in appointment (avoid extra lookups)
- Practitioner name in appointment

### Caching Strategy

```python
# Cache tenant settings (rarely change)
@cache(ttl=3600)  # 1 hour
async def get_tenant_settings(tenant_id: str):
    doc = db.collection("tenants").document(tenant_id)\\
           .collection("settings").document("configuration").get()
    return doc.to_dict()
```

---

## 🎯 Implementation Checklist

### Design Phase ✅

- [x] Define collection structure
- [x] Design document schemas
- [x] Create security rules
- [x] Plan indexes
- [x] Document migration strategy

### Development Phase ⏳

- [ ] Create migration script (`scripts/migrate_to_multitenant.py`)
- [ ] Update repository pattern (multi-tenant aware)
- [ ] Create tenant management API
- [ ] Update frontend to be tenant-aware
- [ ] Write tests for multi-tenant queries

### Testing Phase ⏳

- [ ] Test migration script in development
- [ ] Verify security rules work correctly
- [ ] Load test with multiple tenants
- [ ] Test tenant isolation (no data bleed)
- [ ] Test rollback procedure

### Deployment Phase ⏳

- [ ] Backup production database
- [ ] Run migration in staging
- [ ] Verify staging migration
- [ ] Schedule production maintenance window
- [ ] Run production migration
- [ ] Verify production migration
- [ ] Deploy new security rules
- [ ] Monitor for errors

---

## 📊 Success Metrics

**Migration Success:**

- ✅ 100% data migrated (no data loss)
- ✅ All queries return same results as before
- ✅ < 1 hour downtime
- ✅ Zero security incidents

**Performance:**

- ✅ Query latency < 200ms (p95)
- ✅ Supports 10,000+ tenants
- ✅ < $50/month Firestore costs (100 tenants)

**Security:**

- ✅ No cross-tenant data access
- ✅ All PHI access logged
- ✅ HIPAA compliance maintained

---

## 🔗 Related Documents

- [Multi-Tenancy Hybrid Model](/docs/architecture/multi-tenancy-hybrid-model.md)
- [HIPAA Compliance Guide](/docs/compliance/hipaa-compliance.md)
- [Firestore Security Rules](/firestore.rules)
- [Firestore Indexes](/firestore.indexes.json)

---

**Document Version:** 2.0 **Last Updated:** 2025-10-19 **Owner:** Backend
Architecture Team **Status:** ✅ Complete - Ready for Implementation **Next
Review:** Before Phase 1 (Data Migration)
