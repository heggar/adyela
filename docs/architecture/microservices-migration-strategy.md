# Estrategia de Migración a Microservicios

## 📊 Resumen Ejecutivo

Este documento define la estrategia para migrar **gradualmente** de la
arquitectura monolítica actual de Adyela (FastAPI) hacia una arquitectura de
microservicios distribuidos.

### Principios Clave

1. **Strangler Fig Pattern**: Migración incremental, no reescritura big bang
2. **Coexistencia**: Monolito y microservicios coexisten durante la transición
3. **Zero Downtime**: Ninguna interrupción del servicio durante la migración
4. **Rollback Capability**: Capacidad de revertir cambios en cualquier momento
5. **Data Consistency**: Mantener consistencia de datos durante la transición

---

## Estado Actual vs Estado Objetivo

### Estado Actual (Híbrido: Monolito + Microservicios en Desarrollo)

```
┌─────────────────────────────────────────────┐
│         FastAPI Monolith (api/)             │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  Presentation Layer (HTTP API)       │  │
│  └──────────────────────────────────────┘  │
│                   ↓                         │
│  ┌──────────────────────────────────────┐  │
│  │  Application Layer (Use Cases)       │  │
│  │  - AuthenticationUseCase             │  │
│  │  - AppointmentManagementUseCase      │  │
│  │  - PatientManagementUseCase          │  │
│  └──────────────────────────────────────┘  │
│                   ↓                         │
│  ┌──────────────────────────────────────┐  │
│  │  Domain Layer (Entities)             │  │
│  │  - User, Appointment, Patient        │  │
│  └──────────────────────────────────────┘  │
│                   ↓                         │
│  ┌──────────────────────────────────────┐  │
│  │  Infrastructure Layer                │  │
│  │  - Firestore Repository              │  │
│  │  - Firebase Auth                     │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
                   ↓
         ┌─────────────────┐
         │   Firestore DB  │
         │  (single-tenant)│
         └─────────────────┘
```

**Monolito (apps/api/) - Características**:

- ✅ Arquitectura hexagonal bien definida
- ✅ Separation of concerns por capas
- ❌ Single deployment unit (un bug afecta todo)
- ❌ Scaling completo (no granular)
- ❌ Single-tenant (no multi-tenancy)
- ❌ Technology lock-in (todo Python/FastAPI)

**⚠️ Estado Actual (2025-10-18)**:

Coexisten **Monolito + 6 Microservicios en Desarrollo**:

- ✅ **api-auth** (Python/FastAPI) - Autenticación, RBAC, JWT
- ✅ **api-appointments** (Python/FastAPI) - Gestión de citas, calendario
- ✅ **api-admin** (Python/FastAPI) - Panel admin, aprobaciones
- ✅ **api-analytics** (Python/FastAPI) - Reportes, métricas
- ✅ **api-payments** (Node.js/Express) - Stripe, suscripciones
- ✅ **api-notifications** (Node.js/Express) - Email, SMS, push

**Status**: Strangler Fig Pattern en progreso (~40% migración completada)

### Estado Objetivo (Microservicios)

```
                     ┌──────────────────────┐
                     │ GCP Load Balancer    │
                     │  (HTTPS routing)     │
                     └──────────┬───────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
┌───────▼────────┐   ┌──────────▼─────────┐   ┌───────▼────────┐
│   api-auth     │   │ api-appointments   │   │  api-payments  │
│  (Python)      │   │   (Python)         │   │   (Node.js)    │
│                │   │                    │   │                │
│ - Multi-tenant │   │ - Appointments     │   │ - Stripe       │
│ - RBAC         │   │ - Calendar         │   │ - Subscriptions│
│ - JWT          │   │ - Availability     │   │ - Webhooks     │
└────────┬───────┘   └─────────┬──────────┘   └───────┬────────┘
         │                     │                      │
         └─────────┬───────────┴──────────────────────┘
                   │
          ┌────────▼──────────┐
          │  Cloud Pub/Sub    │
          │   (Event Bus)     │
          └────────┬──────────┘
                   │
        ┌──────────┼──────────────┐
        │          │              │
┌───────▼────────┐ │   ┌──────────▼─────────┐
│api-notifications│ │   │  api-analytics    │
│   (Node.js)     │ │   │    (Python)       │
│                 │ │   │                   │
│ - FCM           │ │   │ - Reporting       │
│ - Email/SMS     │ │   │ - Dashboards      │
└─────────────────┘ │   └───────────────────┘
                    │
           ┌────────▼─────────┐
           │   api-admin      │
           │   (Python)       │
           │                  │
           │ - Approval       │
           │ - Moderation     │
           └──────────────────┘
                    │
        ┌───────────┴────────────┐
        │                        │
┌───────▼─────────┐   ┌──────────▼─────────┐
│   Firestore     │   │  Cloud SQL         │
│ (multi-tenant)  │   │  (analytics)       │
│ - Operational   │   │ - Reporting        │
└─────────────────┘   └────────────────────┘
```

**Características**:

- ✅ Independent deployments
- ✅ Granular scaling
- ✅ Multi-tenant ready
- ✅ Technology diversity (Python + Node.js)
- ✅ Fault isolation
- ⚠️ Increased operational complexity

---

## Estrategia de Migración: Strangler Fig Pattern

### ¿Qué es Strangler Fig?

El patrón Strangler Fig (Named after strangler fig trees que crecen alrededor de
árboles existentes) permite:

1. Crear nuevos microservicios alrededor del monolito existente
2. Redirigir tráfico gradualmente del monolito a los microservicios
3. Mantener el monolito funcionando hasta que todos los servicios estén migrados
4. Decommission el monolito cuando ya no sea necesario

### Fases de Migración

#### Fase 0: Preparación (Mes 1-2) ⚠️ PARCIALMENTE COMPLETADA

**Objetivo**: Preparar infraestructura y datos para multi-tenancy

**Estado Actual (2025-10-18)**:

- ✅ Microservicios creados (structure and base code)
- ⚠️ Firestore multi-tenancy migration PENDIENTE (aún single-tenant)
- ⚠️ Terraform IaC PENDIENTE
- ⚠️ CI/CD pipelines PARCIAL (algunos configurados)
- ⚠️ Observabilidad distribuida PENDIENTE

**Tareas**:

1. **Firestore Migration: Single-tenant → Multi-tenant**

   **Estado Actual (single-tenant)**:

   ```
   /users/{userId}
   /appointments/{appointmentId}
   /patients/{patientId}
   ```

   **Estado Objetivo (multi-tenant)**:

   ```
   /tenants/{tenantId}/users/{userId}
   /tenants/{tenantId}/appointments/{appointmentId}
   /tenants/{tenantId}/patients/{patientId}
   ```

   **Data Migration Script**:

   ```python
   # scripts/migrate-to-multitenant.py
   from google.cloud import firestore
   import logging

   db = firestore.Client()

   async def migrate_collection(collection_name: str, default_tenant_id: str):
       """Migrate existing collection to multi-tenant structure"""
       logger.info(f"Migrating {collection_name}...")

       # Read all docs from old structure
       old_docs = db.collection(collection_name).stream()

       batch = db.batch()
       count = 0

       for doc in old_docs:
           # Create doc in new multi-tenant structure
           new_ref = db.collection("tenants").document(default_tenant_id)\
                       .collection(collection_name).document(doc.id)

           batch.set(new_ref, doc.to_dict())
           count += 1

           # Commit every 500 docs (Firestore limit)
           if count % 500 == 0:
               batch.commit()
               batch = db.batch()
               logger.info(f"Migrated {count} {collection_name} documents")

       # Final commit
       if count % 500 != 0:
           batch.commit()

       logger.info(f"Migration complete: {count} {collection_name} documents")

   # Run migration
   DEFAULT_TENANT = "adyela-clinic"  # existing clinic becomes first tenant

   await migrate_collection("users", DEFAULT_TENANT)
   await migrate_collection("appointments", DEFAULT_TENANT)
   await migrate_collection("patients", DEFAULT_TENANT)
   ```

2. **Feature Flags Setup**

   Usar Cloud Firestore para feature flags (migrar a LaunchDarkly post-MVP):

   ```python
   # api/config/feature_flags.py
   from google.cloud import firestore
   from functools import lru_cache

   db = firestore.Client()

   @lru_cache(maxsize=128)
   def is_feature_enabled(feature_name: str, tenant_id: str = None) -> bool:
       """Check if feature is enabled globally or for specific tenant"""
       # Global flag
       global_flag = db.collection("feature_flags").document(feature_name).get()
       if global_flag.exists and global_flag.to_dict().get("enabled", False):
           return True

       # Tenant-specific flag (overrides global)
       if tenant_id:
           tenant_flag = db.collection("tenants").document(tenant_id)\
                          .collection("feature_flags").document(feature_name).get()
           if tenant_flag.exists:
               return tenant_flag.to_dict().get("enabled", False)

       return False

   # Usage in code
   if is_feature_enabled("use_api_auth_microservice", tenant_id):
       # Route to new microservice
       return await auth_microservice_client.validate(user_id)
   else:
       # Use monolith logic
       return await legacy_auth_handler(user_id)
   ```

3. **API Gateway Routing Setup**

   Configurar Load Balancer con path-based routing:

   ```hcl
   # infra/modules/networking/load-balancer/main.tf
   resource "google_compute_url_map" "adyela_lb" {
     name            = "adyela-load-balancer"
     default_service = google_compute_backend_service.monolith.id

     host_rule {
       hosts        = ["api.adyela.com"]
       path_matcher = "api-paths"
     }

     path_matcher {
       name            = "api-paths"
       default_service = google_compute_backend_service.monolith.id

       # New microservices routes
       path_rule {
         paths   = ["/api/v2/auth/*"]
         service = google_compute_backend_service.api_auth.id
       }

       path_rule {
         paths   = ["/api/v2/appointments/*"]
         service = google_compute_backend_service.api_appointments.id
       }

       # Monolith handles all other paths (fallback)
       path_rule {
         paths   = ["/api/v1/*"]
         service = google_compute_backend_service.monolith.id
       }
     }
   }
   ```

**Criterios de éxito Fase 0**:

- ✅ Firestore migrado a multi-tenant (validado con queries)
- ✅ Feature flags funcionando
- ✅ Load Balancer configurado con routing a monolito

---

#### Fase 1: Extraer api-auth (Mes 3-4) 🔧 EN DESARROLLO

**Objetivo**: Primer microservicio autónomo con autenticación y RBAC

**Estado Actual (2025-10-18)**:

- ✅ api-auth creado con estructura base
- 🔧 Lógica de autenticación en desarrollo
- ⚠️ Integración con otros servicios pendiente
- ⚠️ Despliegue en staging pendiente

**Por qué empezar con Auth?**

- ✅ Bounded context claro (authentication & authorization)
- ✅ Sin dependencias complejas con otros dominios
- ✅ Necesario para todos los demás microservicios (fundacional)
- ✅ Permite validar patrones de comunicación inter-service

**Pasos**:

1. **Crear nuevo servicio api-auth**

   ```bash
   # Estructura
   apps/
   ├── api/                    # Monolito existente
   └── api-auth/               # NUEVO microservicio
       ├── adyela_auth/
       │   ├── domain/
       │   │   ├── entities/
       │   │   │   ├── user.py
       │   │   │   ├── role.py
       │   │   │   └── tenant.py
       │   │   └── ports/
       │   ├── application/
       │   │   ├── use_cases/
       │   │   │   ├── authenticate_user.py
       │   │   │   ├── validate_permissions.py
       │   │   │   └── manage_roles.py
       │   │   └── ports/
       │   ├── infrastructure/
       │   │   ├── firestore/
       │   │   │   └── user_repository.py
       │   │   └── firebase/
       │   │       └── auth_service.py
       │   └── presentation/
       │       └── api/
       │           └── v2/
       │               ├── auth.py
       │               └── users.py
       ├── tests/
       ├── Dockerfile
       └── pyproject.toml
   ```

2. **Copiar código de autenticación del monolito**

   Identificar módulos a extraer:

   ```bash
   # En api/ (monolito)
   adyela_api/
   ├── domain/entities/user.py                    → Copiar a api-auth
   ├── application/use_cases/authentication/      → Copiar a api-auth
   ├── infrastructure/firebase/auth.py            → Copiar a api-auth
   └── presentation/api/v1/auth.py                → Adaptar a v2 en api-auth
   ```

3. **Adaptaciones necesarias**:
   - **Multi-tenancy enforcement**:

     ```python
     # api-auth/adyela_auth/application/use_cases/authenticate_user.py

     @dataclass
     class AuthenticateUserRequest:
         email: str
         password: str
         tenant_id: str  # NUEVO: requerido en multi-tenant

     async def execute(self, request: AuthenticateUserRequest) -> AuthResponse:
         # Validate tenant exists
         tenant = await self.tenant_repo.get_by_id(request.tenant_id)
         if not tenant:
             raise TenantNotFoundError(request.tenant_id)

         # Authenticate user within tenant context
         user = await self.auth_service.authenticate(
             email=request.email,
             password=request.password,
             tenant_id=request.tenant_id  # Scope to tenant
         )

         # Generate JWT with tenant claim
         token = self.jwt_service.generate_token({
             "user_id": user.id,
             "tenant_id": request.tenant_id,
             "roles": user.roles
         })

         return AuthResponse(user=user, token=token)
     ```

   - **API versioning (v2)**:

     ```python
     # api-auth/adyela_auth/presentation/api/v2/auth.py
     from fastapi import APIRouter, Depends

     router = APIRouter(prefix="/api/v2/auth", tags=["auth-v2"])

     @router.post("/login")
     async def login(
         request: LoginRequest,
         use_case: AuthenticateUserUseCase = Depends()
     ):
         result = await use_case.execute(AuthenticateUserRequest(
             email=request.email,
             password=request.password,
             tenant_id=request.tenant_id  # Required in v2
         ))
         return {
             "access_token": result.token,
             "user": result.user.dict()
         }
     ```

4. **Deployment independiente**

   ```dockerfile
   # api-auth/Dockerfile
   FROM python:3.12-slim

   WORKDIR /app

   COPY pyproject.toml poetry.lock ./
   RUN pip install poetry && poetry install --no-dev

   COPY adyela_auth/ ./adyela_auth/

   CMD ["poetry", "run", "uvicorn", "adyela_auth.main:app", "--host", "0.0.0.0", "--port", "8080"]
   ```

   ```yaml
   # .github/workflows/cd-api-auth-staging.yml
   name: Deploy api-auth to staging
   on:
     push:
       branches: [main]
       paths:
         - 'apps/api-auth/**'

   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - name: Build and push Docker image
           run: |
             docker build -t gcr.io/$PROJECT_ID/api-auth:$SHA ./apps/api-auth
             docker push gcr.io/$PROJECT_ID/api-auth:$SHA
         - name: Deploy to Cloud Run
           run: |
             gcloud run deploy api-auth \
               --image gcr.io/$PROJECT_ID/api-auth:$SHA \
               --platform managed \
               --region us-central1 \
               --allow-unauthenticated \
               --set-env-vars="ENVIRONMENT=staging"
   ```

5. **Gradual Traffic Shift con Feature Flags**

   ```python
   # api/ (monolito) - Interceptor para auth requests
   from adyela_api.config.feature_flags import is_feature_enabled
   import httpx

   @router.post("/api/v1/auth/login")
   async def login_v1(request: LoginRequest):
       tenant_id = request.tenant_id or "default"

       # Feature flag: use new microservice?
       if is_feature_enabled("use_api_auth_microservice", tenant_id):
           # Proxy to new api-auth microservice
           async with httpx.AsyncClient() as client:
               response = await client.post(
                   "https://api-auth-xxxxx.run.app/api/v2/auth/login",
                   json=request.dict()
               )
               return response.json()
       else:
           # Use legacy monolith logic
           return await legacy_login_handler(request)
   ```

   **Rollout plan**:
   - Week 1: 0% traffic → api-auth (testing only)
   - Week 2: 10% traffic → api-auth (canary, internal users)
   - Week 3: 50% traffic → api-auth (half production)
   - Week 4: 100% traffic → api-auth (full cutover)

   **Rollback**: Disable feature flag → instant fallback to monolith

6. **Monitoring & Alerts**

   ```python
   # api-auth/adyela_auth/middleware/monitoring.py
   from opentelemetry import trace
   from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

   tracer = trace.get_tracer(__name__)

   @app.middleware("http")
   async def add_distributed_tracing(request: Request, call_next):
       # Extract trace context from headers (propagated from LB)
       with tracer.start_as_current_span(f"{request.method} {request.url.path}"):
           response = await call_next(request)
           return response

   # Cloud Monitoring metrics
   from google.cloud import monitoring_v3

   metrics_client = monitoring_v3.MetricServiceClient()

   async def record_auth_attempt(success: bool, tenant_id: str):
       """Record authentication attempt metric"""
       series = monitoring_v3.TimeSeries()
       series.metric.type = "custom.googleapis.com/auth/attempts"
       series.metric.labels["success"] = str(success)
       series.metric.labels["tenant_id"] = tenant_id

       point = monitoring_v3.Point()
       point.value.int64_value = 1
       series.points = [point]

       metrics_client.create_time_series(
           name=f"projects/{project_id}",
           time_series=[series]
       )
   ```

   **Alerts**:
   - Error rate > 5% → Page on-call engineer
   - Latency p95 > 500ms → Warning
   - Monolith proxy calls > 0 (after 100% rollout) → Investigate

**Criterios de éxito Fase 1**:

- ✅ api-auth desplegado en staging
- ✅ 100% traffic shifted to api-auth
- ✅ Monolith auth code marcado como deprecated
- ✅ Latency p95 < 200ms
- ✅ Error rate < 1%

---

#### Fase 2: Extraer api-appointments (Mes 4-5)

**Objetivo**: Microservicio core de citas con integración a api-auth

**Complejidad adicional**: api-appointments depende de api-auth

**Pasos**:

1. **Service-to-service authentication**

   api-appointments necesita llamar a api-auth para validar permisos:

   ```python
   # api-appointments/adyela_appointments/infrastructure/auth_client.py
   import httpx
   from google.auth.transport.requests import Request
   from google.oauth2 import service_account

   class AuthServiceClient:
       def __init__(self, base_url: str, service_account_file: str):
           self.base_url = base_url
           self.credentials = service_account.Credentials.from_service_account_file(
               service_account_file,
               scopes=["https://www.googleapis.com/auth/cloud-platform"]
           )

       async def validate_permissions(
           self,
           user_id: str,
           tenant_id: str,
           resource: str,
           action: str
       ) -> bool:
           """Call api-auth to validate user permissions"""
           # Get service account token for authentication
           self.credentials.refresh(Request())
           token = self.credentials.token

           async with httpx.AsyncClient() as client:
               response = await client.post(
                   f"{self.base_url}/api/v2/auth/validate",
                   json={
                       "user_id": user_id,
                       "tenant_id": tenant_id,
                       "resource": resource,
                       "action": action
                   },
                   headers={"Authorization": f"Bearer {token}"},
                   timeout=5.0  # Timeout to prevent cascading failures
               )
               response.raise_for_status()
               return response.json()["allowed"]
   ```

   Uso en appointment creation:

   ```python
   # api-appointments/application/use_cases/create_appointment.py

   async def execute(self, request: CreateAppointmentRequest) -> Appointment:
       # Validate permissions via api-auth
       can_create = await self.auth_client.validate_permissions(
           user_id=request.user_id,
           tenant_id=request.tenant_id,
           resource="appointments",
           action="create"
       )

       if not can_create:
           raise PermissionDeniedError("User cannot create appointments")

       # Business logic
       appointment = Appointment(
           id=generate_id(),
           patient_id=request.patient_id,
           professional_id=request.professional_id,
           scheduled_at=request.scheduled_at,
           tenant_id=request.tenant_id
       )

       # Save to Firestore
       await self.appointment_repo.save(appointment)

       # Publish event to Pub/Sub
       await self.event_bus.publish("appointment.created", appointment.dict())

       return appointment
   ```

2. **Event-driven communication**

   api-appointments publica eventos que otros servicios consumen:

   ```python
   # api-appointments/infrastructure/event_bus.py
   from google.cloud import pubsub_v1
   import json

   class EventBus:
       def __init__(self, project_id: str):
           self.publisher = pubsub_v1.PublisherClient()
           self.project_id = project_id

       async def publish(self, event_type: str, data: dict):
           """Publish event to Pub/Sub"""
           topic_path = self.publisher.topic_path(self.project_id, event_type)

           event = {
               "event_id": str(uuid.uuid4()),
               "event_type": event_type,
               "timestamp": datetime.utcnow().isoformat(),
               "data": data,
               "metadata": {
                   "tenant_id": data.get("tenant_id"),
                   "correlation_id": get_correlation_id()
               }
           }

           future = self.publisher.publish(
               topic_path,
               json.dumps(event).encode("utf-8")
           )
           message_id = future.result()
           logger.info(f"Published event {event_type} with message ID {message_id}")
   ```

3. **Data Consistency Challenge**

   **Problem**: ¿Qué pasa si api-auth aprueba permisos pero Firestore falla al
   guardar la cita?

   **Solution**: Saga Pattern con compensating transactions

   ```python
   # api-appointments/application/sagas/create_appointment_saga.py
   from dataclasses import dataclass, field
   from enum import Enum

   class SagaStep(Enum):
       VALIDATE_PERMISSIONS = "validate_permissions"
       CREATE_APPOINTMENT = "create_appointment"
       NOTIFY_PATIENT = "notify_patient"

   @dataclass
   class CreateAppointmentSaga:
       request: CreateAppointmentRequest
       completed_steps: list[SagaStep] = field(default_factory=list)
       appointment_id: str = None

       async def execute(self):
           try:
               # Step 1: Validate permissions
               can_create = await self._validate_permissions()
               if not can_create:
                   raise PermissionDeniedError()
               self.completed_steps.append(SagaStep.VALIDATE_PERMISSIONS)

               # Step 2: Create appointment
               self.appointment_id = await self._create_appointment()
               self.completed_steps.append(SagaStep.CREATE_APPOINTMENT)

               # Step 3: Notify patient (async, non-critical)
               await self._notify_patient()
               self.completed_steps.append(SagaStep.NOTIFY_PATIENT)

               return self.appointment_id

           except Exception as e:
               # Compensate (rollback)
               await self._compensate()
               raise

       async def _compensate(self):
           """Rollback completed steps in reverse order"""
           if SagaStep.CREATE_APPOINTMENT in self.completed_steps:
               await self._cancel_appointment(self.appointment_id)

           # Notification failure is non-critical, no compensation needed
   ```

**Criterios de éxito Fase 2**:

- ✅ api-appointments desplegado y funcionando
- ✅ Service-to-service auth con api-auth working
- ✅ Events publicados a Pub/Sub
- ✅ Saga pattern tested (rollback scenarios)
- ✅ 100% traffic shifted

---

#### Fase 3-4: Extraer servicios restantes (Mes 6-9)

Seguir misma metodología para:

- **api-payments** (Node.js, Mes 7-8)
- **api-notifications** (Node.js, Mes 8)
- **api-admin** (Python, Mes 9)
- **api-analytics** (Python, Mes 9)

Cada servicio sigue el patrón:

1. Crear servicio nuevo
2. Copiar/adaptar código del monolito
3. Deployment independiente
4. Feature flag + gradual rollout
5. Monitoring & validation
6. 100% cutover

---

#### Fase 5: Decommission Monolito (Mes 10+)

**Objetivo**: Eliminar código legacy del monolito

**Condiciones para decommissioning**:

- ✅ Todos los 6 microservicios en producción (100% traffic)
- ✅ Zero monolith calls (validated via metrics)
- ✅ 30 días sin incidents major
- ✅ Rollback procedures tested

**Pasos**:

1. Mark monolith API v1 as deprecated (warnings en logs)
2. Monitoring: alert if any v1 calls detected
3. Wait 30 días (grace period)
4. Decommission Cloud Run monolith service
5. Archive `apps/api/` code (git tag: `monolith-final`)

---

## Riesgos y Mitigaciones

| Riesgo                                     | Probabilidad | Impacto | Mitigación                               |
| ------------------------------------------ | ------------ | ------- | ---------------------------------------- |
| **Data inconsistency durante migración**   | Media        | Alto    | Saga pattern + idempotent operations     |
| **Microservicio down afecta a otros**      | Alta         | Alto    | Circuit breakers + fallbacks             |
| **Network latency entre servicios**        | Media        | Medio   | Caching + async communication (Pub/Sub)  |
| **Firestore multi-tenant migration falla** | Baja         | Crítico | Dry-run script + backup before migration |
| **Feature flag misconfiguration**          | Media        | Alto    | Gradual rollout (10% → 50% → 100%)       |
| **Distributed tracing gaps**               | Media        | Medio   | Correlation IDs desde día 1              |
| **Cost overrun (6 services vs 1)**         | Alta         | Medio   | Budget alerts + right-sizing             |

---

## Métricas de Éxito

### Por Fase

**Fase 1 (api-auth)**:

- ✅ 100% autenticaciones via microservicio
- ✅ Latency p95 < 200ms
- ✅ Error rate < 1%
- ✅ Zero rollbacks

**Fase 2 (api-appointments)**:

- ✅ 100% appointments via microservicio
- ✅ Service-to-service auth working (100% success rate)
- ✅ Event publishing (100% success rate)
- ✅ Zero data inconsistencies

**Overall Migration**:

- ✅ All 6 microservices deployed
- ✅ Monolith decommissioned
- ✅ Zero downtime during migration
- ✅ Cost increase < 50% vs monolith
- ✅ Team proficiency in distributed systems (post-mortems, runbooks)

---

## Runbooks y Troubleshooting

### Rollback de Microservicio

Si api-auth tiene problemas:

```bash
# 1. Disable feature flag (instant)
gcloud firestore update feature_flags/use_api_auth_microservice --set enabled=false

# 2. Verify monolith is handling traffic
curl https://api.adyela.com/api/v1/auth/health
# Expected: 200 OK

# 3. Check logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=api-auth" --limit 100

# 4. Incident post-mortem
# Document what went wrong, timeline, learnings
```

### Data Consistency Check

Validar que Firestore multi-tenant está correcto:

```python
# scripts/validate-multitenant.py
async def validate_multitenant_migration():
    """Ensure all data is in multi-tenant structure"""
    db = firestore.Client()

    # Check if old structure is empty
    old_users = db.collection("users").limit(1).stream()
    assert len(list(old_users)) == 0, "Old user collection should be empty"

    # Check if new structure has data
    tenants = db.collection("tenants").stream()
    for tenant in tenants:
        users = db.collection("tenants").document(tenant.id).collection("users").stream()
        assert len(list(users)) > 0, f"Tenant {tenant.id} should have users"

    print("✅ Multi-tenant migration validated")
```

---

## Próximos Pasos

1. **Review este documento con el equipo** (arquitectos, backend leads, DevOps)
2. **Aprobar timeline y recursos** (8 meses, 6-8 engineers)
3. **Crear PRD detallado** (`docs/planning/health-platform-prd.md`)
4. **Setup Terraform IaC** (Fase 0, semana 1-2)
5. **Ejecutar migración Firestore** (Fase 0, semana 2)
6. **Comenzar desarrollo api-auth** (Fase 1, mes 3)

---

**Documento**: `docs/architecture/microservices-migration-strategy.md`
**Versión**: 2.0 **Última actualización**: 2025-10-18 **Estado**: Strangler Fig
Pattern en progreso (~40% migración) **Autor**: Engineering Team **Próxima
revisión**: Fin de Fase 1
