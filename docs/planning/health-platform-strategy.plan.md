# Plan de Estrategia para Plataforma de Salud Integral

## 📊 Resumen Ejecutivo

### Visión

Transformar Adyela de un sistema de citas médicas en una **plataforma integral
de salud multi-tenant** que conecte pacientes con profesionales independientes
de múltiples especialidades (medicina general, fisioterapia, psicología).

### Modelo de Negocio

**Freemium con suscripciones por niveles** para profesionales de salud
independientes.

### Mercado Objetivo

**Latinoamérica** (compliance básico, escalable a HIPAA/GDPR futuro).

### Capacidades del Equipo

**6+ desarrolladores especializados** en Python/FastAPI, React, Flutter,
Node.js, microservicios.

### Timeline

**8-12 meses para MVP completo** (prioridad: calidad > velocidad).

### Arquitectura Propuesta

- **Backend**: Microservicios (6 servicios) con Python/FastAPI + Node.js
- **Frontend**: Flutter (mobile nativo iOS/Android + web
  pacientes/profesionales) + React (admin @adye.care)
- **Data**: Firestore (operacional) + Cloud SQL PostgreSQL (analytics) - modelo
  híbrido
- **Infraestructura**: GCP Cloud Run + Load Balancer + Terraform IaC
- **Multi-tenancy**: Pool model (tier Free/Pro) + Silo model (tier Enterprise)

### Presupuesto Estimado

- **Staging**: $100-150/mes (desarrollo activo con scale-to-zero)
- **Producción**: $700-900/mes inicial → $1,200-1,800/mes escalado (10k+
  usuarios)

### Riesgos Críticos Identificados

1. **Complejidad Microservicios**: 6 servicios desde MVP aumenta overhead
   operacional
2. **Flutter Web Limitations**: SEO, accesibilidad, performance inicial vs React
3. **Distributed Transactions**: Saga pattern requerido para operaciones
   multi-servicio
4. **Cost Overrun**: Sin budget alerts, riesgo de exceder $150/mes staging
5. **Data Migration**: Firestore single-tenant → multi-tenant requiere
   planificación detallada

### Estrategia de Mitigación

- **Strangler Fig Pattern**: Migración gradual monolito → microservicios (no big
  bang)
- **React Admin**: Mantener para aprovechar trabajo existente (100% E2E tests,
  100% accessibility)
- **Observabilidad**: Distributed tracing, correlation IDs, structured logging
  desde día 1
- **FinOps**: Budget alerts, cost allocation tags, monthly reviews
- **Compliance**: Diseñar con HIPAA en mente aunque no sea requerido
  inicialmente

---

## Objetivo

Crear documentación completa y estrategia de implementación para transformar
Adyela (actual sistema de citas médicas) en una plataforma integral de salud que
conecte pacientes con múltiples tipos de profesionales de la salud.

## Contexto Actual

- **Base existente**: Adyela con FastAPI, React PWA, GCP, Firebase, arquitectura
  hexagonal
- **Infraestructura**: Monorepo con Turbo, staging scale-to-zero optimizado para
  FinOps
- **Stack Backend**: Python 3.12, FastAPI, Firestore, Cloud Run
- **Stack Web**: React 18, TypeScript, PWA con shadcn/ui
- **Stack Móvil**: Flutter (apps separadas para pacientes y profesionales)
- **Equipo**: Definido, con experiencia técnica
- **Ambiente**: Solo staging durante toda la fase de desarrollo (producción
  futura)

## Transformación Propuesta

1. **Evolucionar desde**: Sistema de citas para clínicas
2. **Hacia**: Plataforma multi-tenant para profesionales independientes y
   pacientes
3. **Especialidades iniciales**: Medicina general, fisioterapia, psicología
4. **Modelo de negocio**: Freemium con suscripciones por niveles
5. **Timeline**: MVP en 4-6 meses

## Documentos a Crear

### 1. Prompt Estratégico Refinado

**Archivo**: `docs/planning/health-platform-strategic-prompt.md`

Consolidar el prompt mejorado con todos los detalles técnicos y de negocio para
usar en consultas con AI sobre el proyecto.

**Contenido**:

- Problema y solución detallados
- Contexto de Adyela como base técnica
- Stack actual y componentes a mantener/evolucionar
- Funcionalidades específicas por tipo de usuario
- Modelo de negocio freemium detallado
- Compliance y seguridad (evolución gradual)
- Integraciones futuras planificadas

### 2. Product Requirements Document (PRD)

**Archivo**: `docs/planning/health-platform-prd.md`

PRD completo que sirva como base para generar tareas con Task Master AI.

**Contenido**:

- Executive Summary
- Visión y objetivos del producto
- User Personas (pacientes, profesionales por especialidad, admin)
- User Stories detalladas por rol
- Funcionalidades Core (MVP)
- Sistema multi-tenant con identificadores
- Autenticación múltiple (Google, email, teléfono)
- Gestión de citas y seguimientos
- Historial clínico por profesional-paciente
- Comunicación bidireccional pactada
- Sistema de notificaciones push
- Panel administrativo de aprobación
- Funcionalidades Futuras (Post-MVP)
- Pagos en línea
- Marketplace de servicios
- Matriz de funcionalidades por nivel de suscripción
- Requisitos no funcionales
- Criterios de aceptación

### 3. Arquitectura Evolutiva

**Archivo**: `docs/architecture/health-platform-evolution.md`

Plan de evolución arquitectónica desde Adyela hacia la nueva plataforma.

**Contenido**:

- Análisis de componentes actuales de Adyela
- Componentes a mantener (qué y por qué)
- Infraestructura GCP (Cloud Run, Firestore, etc.)
- Arquitectura hexagonal del API
- Monorepo con Turbo
- PWA con React
- Firebase Authentication base
- Componentes a evolucionar (cómo)
- Firestore: de single-tenant a multi-tenant
- Identity Platform: agregar más proveedores
- Cloud Run API: nuevos módulos para especialidades
- PWA: nuevas interfaces para profesionales
- Componentes a agregar (cuándo)
- Sistema de notificaciones push avanzado
- Gestión de suscripciones y pagos
- Sistema de aprobación de profesionales
- Analytics y reporting
- Diagrama de arquitectura multi-tenant
- Estrategia de separación de datos por tenant
- Plan de migración de datos (si aplica)
- Consideraciones de escalabilidad

### 4. Stack Tecnológico Híbrido

**Archivo**: `docs/architecture/health-platform-stack.md`

Recomendaciones específicas de tecnologías a mantener, cambiar o agregar.

**Contenido**:

- Stack Actual de Adyela (análisis)
  - Backend: FastAPI monolítico, Pydantic, Firebase Admin
  - Frontend Web: React, TypeScript, Vite, TailwindCSS
  - Data: Firestore, Cloud Storage, Secret Manager
  - Auth: Firebase Identity Platform
  - Infra: GCP (Cloud Run, Cloud Functions)

- **Decisión Arquitectónica: Microservicios Híbridos**
  - **Evolucionar desde**: API monolítica FastAPI
  - **Hacia**: Arquitectura de microservicios con Load Balancer como router
  - **Razón**: Escalabilidad independiente, tecnología óptima por servicio,
    desarrollo paralelo
  - **API Gateway Strategy**:
    - **Fase 1 (MVP)**: GCP Load Balancer + Cloud Run (suficiente para routing
      básico)
    - **Fase 2 (Post-MVP)**: Evaluar Cloud Endpoints si necesitamos: API
      versioning, rate limiting avanzado, API analytics, OpenAPI spec
      enforcement
    - **Evitar**: Apigee (overkill y costoso $500+/mes para MVP)

### 4.2 Patrones de Comunicación entre Microservicios

**Archivo relacionado**: `docs/architecture/service-communication-patterns.md`
(documento P0 a crear)

#### Estrategia de Comunicación

**🔄 Comunicación Síncrona (Request-Response)**

Usar para operaciones que requieren respuesta inmediata:

| Origen           | Destino           | Método    | Caso de Uso                   |
| ---------------- | ----------------- | --------- | ----------------------------- |
| web-admin        | api-admin         | REST/HTTP | Aprobar solicitud profesional |
| api-appointments | api-auth          | REST/HTTP | Validar permisos usuario      |
| api-admin        | api-notifications | REST/HTTP | Enviar email de aprobación    |
| mobile-patient   | api-appointments  | REST/HTTP | Reservar cita                 |

**Implementación**:

- Protocolo: REST over HTTPS (familiar, debugging simple, HTTP/2 multiplexing)
- Auth: JWT tokens + service-to-service via service accounts
- Timeout: 5s para llamadas críticas, 15s para no críticas
- Circuit Breaker: Failfast si servicio destino está down

**Ejemplo (Python/FastAPI)**:

```python
# api-appointments llama a api-auth
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential

class AuthServiceClient:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.client = httpx.AsyncClient(timeout=5.0)

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def validate_permissions(
        self,
        user_id: str,
        resource: str,
        action: str
    ) -> bool:
        try:
            response = await self.client.post(
                f"{self.base_url}/auth/validate",
                json={"user_id": user_id, "resource": resource, "action": action},
                headers={"X-Correlation-ID": get_correlation_id()}
            )
            response.raise_for_status()
            return response.json()["allowed"]
        except httpx.TimeoutException:
            # Fallback: deny if auth service is down (fail-secure)
            logger.error(f"Auth service timeout for user {user_id}")
            return False
        except httpx.HTTPStatusError as e:
            logger.error(f"Auth service error: {e.response.status_code}")
            raise
```

**📡 Comunicación Asíncrona (Event-Driven)**

Usar para operaciones que no requieren respuesta inmediata:

| Evento                  | Publisher        | Subscribers                      | Caso de Uso                            |
| ----------------------- | ---------------- | -------------------------------- | -------------------------------------- |
| `appointment.created`   | api-appointments | api-notifications, api-analytics | Enviar confirmación + trackear métrica |
| `professional.approved` | api-admin        | api-auth, api-notifications      | Otorgar permisos + email bienvenida    |
| `payment.completed`     | api-payments     | api-appointments, api-analytics  | Confirmar cita + revenue tracking      |
| `user.registered`       | api-auth         | api-notifications, api-analytics | Email bienvenida + cohort analysis     |

**Implementación**:

- Protocolo: Cloud Pub/Sub (fully managed, at-least-once delivery)
- Schema: JSON con versioning (Avro schemas en Cloud Storage para validación)
- Dead Letter Queue: Para mensajes que fallan procesamiento
- Idempotency: Subscribers deben ser idempotentes (duplicate detection con
  message ID)

**Ejemplo (Cloud Pub/Sub)**:

```python
# api-appointments publica evento
from google.cloud import pubsub_v1
import json

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, "appointment-created")

event_data = {
    "event_type": "appointment.created",
    "event_id": str(uuid.uuid4()),
    "timestamp": datetime.utcnow().isoformat(),
    "version": "v1",
    "data": {
        "appointment_id": "appt_123",
        "patient_id": "pat_456",
        "professional_id": "prof_789",
        "scheduled_at": "2025-10-20T10:00:00Z"
    },
    "metadata": {
        "tenant_id": "tenant_abc",
        "correlation_id": get_correlation_id()
    }
}

future = publisher.publish(
    topic_path,
    json.dumps(event_data).encode("utf-8"),
    event_type="appointment.created",  # attribute for filtering
    tenant_id="tenant_abc"
)
message_id = future.result()  # Block until published
logger.info(f"Published event {event_data['event_id']} as message {message_id}")
```

```python
# api-notifications suscribe a evento
from google.cloud import pubsub_v1

subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path(project_id, "notifications-appointment-created")

def callback(message: pubsub_v1.subscriber.message.Message):
    try:
        event_data = json.loads(message.data.decode("utf-8"))

        # Idempotency check: already processed?
        if await is_event_processed(event_data["event_id"]):
            logger.info(f"Event {event_data['event_id']} already processed, skipping")
            message.ack()
            return

        # Process event
        await send_appointment_confirmation_email(event_data["data"])

        # Mark as processed
        await mark_event_processed(event_data["event_id"])
        message.ack()

    except Exception as e:
        logger.error(f"Error processing message: {e}")
        message.nack()  # Retry later

subscriber.subscribe(subscription_path, callback=callback)
```

#### Distributed Transactions: Saga Pattern

Para operaciones que span múltiples microservicios, usamos **Orchestration-based
Saga**:

**Caso de Uso: Reservar Cita con Pago**

Flujo:

1. Cliente llama `POST /appointments` → api-appointments (orchestrator)
2. api-appointments llama api-auth para validar permisos
3. api-appointments crea cita (estado: `PENDING_PAYMENT`)
4. api-appointments llama api-payments para crear payment intent
5. Cliente completa pago en frontend
6. api-payments recibe webhook de Stripe → publica evento `payment.completed`
7. api-appointments consume evento → actualiza cita a `CONFIRMED`
8. api-appointments publica evento `appointment.confirmed`
9. api-notifications consume evento → envía email/SMS

**Compensating Transactions (rollback)**:

- Si pago falla → api-appointments cancela cita
- Si notificación falla → retry con exponential backoff (no crítico)

**Implementación (Saga Orchestrator)**:

```python
# api-appointments/application/sagas/create_appointment_saga.py
from dataclasses import dataclass
from enum import Enum

class SagaStatus(Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    COMPENSATING = "compensating"
    FAILED = "failed"

@dataclass
class CreateAppointmentSaga:
    appointment_id: str
    status: SagaStatus
    steps_completed: list[str]

    async def execute(self):
        try:
            # Step 1: Validate permissions
            await self._validate_permissions()
            self.steps_completed.append("validate_permissions")

            # Step 2: Create appointment (PENDING_PAYMENT)
            await self._create_appointment()
            self.steps_completed.append("create_appointment")

            # Step 3: Create payment intent
            payment_intent = await self._create_payment_intent()
            self.steps_completed.append("create_payment")

            self.status = SagaStatus.COMPLETED
            return {"appointment_id": self.appointment_id, "payment_intent": payment_intent}

        except Exception as e:
            logger.error(f"Saga failed: {e}")
            await self._compensate()
            raise

    async def _compensate(self):
        """Rollback completed steps"""
        self.status = SagaStatus.COMPENSATING

        if "create_payment" in self.steps_completed:
            await self._cancel_payment_intent()

        if "create_appointment" in self.steps_completed:
            await self._cancel_appointment()

        self.status = SagaStatus.FAILED
```

#### Resilience Patterns

**🔒 Circuit Breaker**

Previene cascading failures cuando un servicio está down:

```python
# Using pybreaker library
from pybreaker import CircuitBreaker

# Circuit breaker for api-payments
payments_breaker = CircuitBreaker(
    fail_max=5,         # Open circuit after 5 failures
    timeout_duration=60 # Try again after 60s
)

@payments_breaker
async def create_payment_intent(amount: int, currency: str):
    # If circuit is OPEN, raises CircuitBreakerError immediately
    # If circuit is CLOSED, calls api-payments normally
    # If circuit is HALF_OPEN, allows one test request
    return await payments_client.create_intent(amount, currency)

# Fallback when circuit is open
try:
    payment = await create_payment_intent(5000, "USD")
except CircuitBreakerError:
    # Fallback: create appointment without payment (manual payment later)
    logger.warning("Payments service unavailable, creating appointment for manual payment")
    return await create_appointment_manual_payment()
```

**⏱️ Retry with Exponential Backoff**

Para errores transitorios (network glitches, temporary overload):

```python
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10),
    retry=retry_if_exception_type((httpx.TimeoutException, httpx.NetworkError))
)
async def call_auth_service(user_id: str):
    return await auth_client.validate_user(user_id)
```

**🚦 Rate Limiting**

Proteger servicios de sobrecarga:

- **Application-level**: Redis con sliding window (api-appointments limita
  requests por tenant)
- **Infrastructure-level**: Cloud Armor (WAF) limita requests por IP

**💾 Caching**

Reducir llamadas entre servicios:

- **In-memory cache**: Redis para auth validations (TTL: 5 min)
- **CDN cache**: Cloud CDN para contenido estático (avatars, assets)

```python
import redis.asyncio as redis

cache = redis.Redis(host="redis-host", decode_responses=True)

async def get_user_permissions(user_id: str) -> dict:
    # Try cache first
    cached = await cache.get(f"perms:{user_id}")
    if cached:
        return json.loads(cached)

    # Cache miss: call auth service
    perms = await auth_client.get_permissions(user_id)

    # Store in cache (5 min TTL)
    await cache.setex(f"perms:{user_id}", 300, json.dumps(perms))

    return perms
```

#### Service Mesh Considerations

**Decision: NO usar Istio para MVP** (demasiado complejo)

En su lugar, usar:

- **Cloud Run service-to-service auth**: Automático con IAM
- **Cloud Load Balancing**: Routing y health checks
- **Cloud Trace**: Distributed tracing nativo
- **Cloud Monitoring**: Métricas y alerts

**Reevaluar Istio** si en Fase 2 necesitamos:

- mTLS automático entre todos los servicios
- Traffic splitting avanzado (canary deployments)
- Service-level circuit breakers
- Mesh-wide policy enforcement

Costo-beneficio actual: **Complejidad de Istio > Beneficios para MVP**

- **Arquitectura Backend: Microservicios por Dominio**

**Servicios Python/FastAPI** (Lógica de negocio):

- **api-auth** (FastAPI): Autenticación centralizada, RBAC, JWT, multi-tenant
- **api-appointments** (FastAPI): Core business logic, citas, calendario,
  disponibilidad
- **api-admin** (FastAPI): Panel administrativo, aprobaciones, moderación
- **api-analytics** (Python): Métricas, reportes, dashboards (pandas, numpy)

**Servicios Node.js** (Integraciones externas):

- **api-payments** (Node.js): Stripe SDK, webhooks, suscripciones, facturación
- **api-notifications** (Node.js): FCM, Twilio, SendGrid, push notifications

**Routing con Load Balancer**:

```
/api/auth/*          → api-auth (Cloud Run)
/api/appointments/*  → api-appointments (Cloud Run)
/api/payments/*      → api-payments (Cloud Run)
/api/notifications/* → api-notifications (Cloud Run)
/api/admin/*         → api-admin (Cloud Run)
/api/analytics/*     → api-analytics (Cloud Run)
```

- Stack completo recomendado por capa

**Backend Microservicios**:

- **Python/FastAPI**: api-auth, api-appointments, api-admin, api-analytics
  - Arquitectura Hexagonal (ports & adapters)
  - Domain-Driven Design (DDD) para api-appointments
  - CQRS Pattern para separar lectura/escritura
  - Repository Pattern + Unit of Work
- **Node.js/Express**: api-payments, api-notifications
  - Clean Architecture con capas bien definidas
  - Event-Driven Architecture para webhooks
  - Circuit Breaker para resilencia

**Frontend Apps**:

- **Admin Web**: React 18, shadcn/ui, TypeScript, Vite, TailwindCSS (solo
  usuarios @adye.care)
- **User Web**: Flutter Web para pacientes y profesionales (PWAs)
- **Mobile Apps**: Flutter 3.x (iOS/Android) con arquitectura BLoC

**Shared Packages**:

- **api-client**: Cliente HTTP generado (actúa como BFF - Backend for Frontend)
- **flutter-shared**: Código compartido Flutter (85-90% entre web/mobile)
- **pnpm workspace + melos**: Gestión de monorepo integrado
- Estructura del Monorepo Expandida (Microservicios + BFF)

  ```
  adyela/
  ├── apps/
  │   ├── api-auth/               # FastAPI - Autenticación + RBAC + Multi-tenant (nuevo)
  │   ├── api-appointments/       # FastAPI - Core business logic citas (evolución de api/)
  │   ├── api-payments/           # Node.js - Stripe + Webhooks + Suscripciones (nuevo)
  │   ├── api-notifications/      # Node.js - FCM + Email + SMS + Push (nuevo)
  │   ├── api-admin/              # FastAPI - Panel admin + Aprobaciones (nuevo)
  │   ├── api-analytics/          # Python - Métricas + Reportes + Pandas (nuevo)
  │   ├── web-admin/              # React + shadcn/ui - Solo @adye.care (renombrado de web/)
  │   ├── web-patient/            # Flutter Web - PACIENTES (nuevo)
  │   ├── web-professional/       # Flutter Web - PROFESIONALES (nuevo)
  │   ├── mobile-patient/         # Flutter Mobile - PACIENTES (nuevo)
  │   └── mobile-professional/    # Flutter Mobile - PROFESIONALES (nuevo)
  ├── packages/
  │   ├── api-client/             # Cliente HTTP como BFF - Backend for Frontend (nuevo)
  │   │   ├── bff/                # Adaptaciones por cliente (mobile, web, admin)
  │   │   ├── services/           # Servicios de backend
  │   │   ├── types/              # Tipos por cliente
  │   │   ├── cache/              # Lógica de caching
  │   │   └── utils/              # Utilidades compartidas
  │   ├── ui/                     # React components para admin (existente)
  │   ├── core/                   # SDK compartido TS/Python (existente)
  │   ├── flutter-shared/         # Widgets compartidos Flutter Web+Mobile (nuevo)
  │   ├── flutter-auth/           # Auth logic compartida Flutter (nuevo)
  │   └── flutter-core/           # Business logic compartida Flutter (nuevo)
  ```

- **Decisión Arquitectónica: Flutter Web + Mobile + React Admin (HÍBRIDO)**

**Justificación Estratégica**:

- Máxima reutilización de código Flutter (85-90% entre web/mobile)
- UX consistente para pacientes y profesionales en todos los dispositivos
- Aprovechamiento inteligente de React existente reconvertido para admin
- Separación clara de responsabilidades por tipo de usuario
- Enfoque en UX/UI optimizado por rol

**🌐 Flutter Web (Pacientes y Profesionales) - NUEVO**

**web-patient (Flutter Web)**:

- UI simplificada y amigable
- Búsqueda y reserva de citas en 3 pasos
- Acceso fácil a historial médico
- Recordatorios y seguimiento
- Chat con profesionales
- PWA instalable desde navegador
- **85-90% código compartido con mobile-patient**

**web-professional (Flutter Web)**:

- Dashboard complejo con analytics
- Gestión avanzada de pacientes
- Calendario profesional interactivo drag & drop
- Herramientas de diagnóstico y registro clínico
- Sistema de facturación y suscripciones
- Gestión de colaboradores (asistentes, secretarias)
- **85-90% código compartido con mobile-professional**

**⚙️ React Admin (Solo Admin Plataforma) - EVOLUCIÓN DE EXISTENTE**

**admin-web (React + shadcn/ui)** - Renombrado de apps/web/:

- **Autenticación RESTRINGIDA**: Solo emails @adye.care
- **Validación backend**: Email domain check
- Aprobación de solicitudes de profesionales
- Validación de credenciales médicas (documentos, certificados)
- Moderación de contenido y reportes
- Analytics y reportes globales de plataforma
- Gestión de suscripciones y pagos
- Configuración de plataforma (features flags, etc.)
- Dashboard de métricas de negocio

**📱 Flutter Mobile (Pacientes y Profesionales) - NUEVO**

- **mobile-patient**: App principal iOS/Android para pacientes
- **mobile-professional**: App principal iOS/Android para profesionales
- **85-90% código compartido con Flutter Web correspondiente**

**💻 Código Compartido Flutter (packages/flutter-\*)**:

- **flutter-shared**: Widgets y componentes UI (70-85% compartido)
- **flutter-auth**: Lógica de autenticación (90-95% compartido)
- **flutter-core**: Business logic, models, DTOs (90-95% compartido)
- Services: API client, state management (90-95% compartido)
- Utils, helpers, constants (100% compartido)
- Tema y estilos base (90-95% compartido)

**✅ Beneficios Arquitectura Híbrida**:

- **Máxima reutilización**: 85-90% código entre Flutter Web/Mobile
- **UX consistente**: Misma experiencia web/móvil para usuarios finales
- **Mantenimiento simplificado**: Un stack (Flutter) para usuarios, otro (React)
  para admin
- **Performance**: Apps Flutter optimizadas por rol, admin React con ecosistema
  maduro
- **Aprovechamiento inteligente**: React existente → admin sin desperdiciar
  trabajo
- **Seguridad robusta**: Admin aislado con autenticación especial (@adye.care)
- **Desarrollo paralelo**: Equipos pueden trabajar simultáneamente web/mobile
  con código compartido
- **Time-to-market reducido**: Una feature en Flutter = web + mobile simultáneo

- **Librerías Específicas por Stack**

**Backend (Python/FastAPI)**:

- Stripe SDK (pagos)
- Firebase Admin SDK (roles y permisos)
- FastAPI-Users (autenticación avanzada)

**Admin Web (React + shadcn/ui)** - Solo para @adye.care:

- **shadcn/ui** (componentes base con Radix UI + TailwindCSS):
  - Form, Input, Select, Checkbox, Radio (formularios)
  - Data Table (listas de profesionales, métricas)
  - Dialog/Modal (aprobaciones, detalles)
  - Calendar (programación interna)
  - Badge (estados: pendiente, aprobado, rechazado)
  - Card (resúmenes, dashboards)
  - Tabs, Accordion (navegación)
  - Command (búsqueda rápida)
  - Popover, Tooltip (información)
- **Complementos**:
  - @tanstack/react-table (tablas administrativas)
  - react-big-calendar (calendario interno)
  - recharts (gráficos de métricas)
  - react-hook-form + zod (ya existe, formularios)
  - @tanstack/react-query (ya existe, servidor)
  - zustand (ya existe, estado)
  - lucide-react (iconos)

**Flutter Web + Mobile (Pacientes y Profesionales)**:

- **Auth & Identity**: firebase_auth, google_sign_in, sign_in_with_apple,
  flutter_facebook_auth
- **State Management**: flutter_bloc o riverpod (decisión por performance)
- **Networking**: dio (HTTP client), retrofit (code generation opcional)
- **Models**: freezed (immutability), json_serializable (serialización)
- **Push Notifications**: firebase_messaging, flutter_local_notifications
- **UI Components**: flutter_form_builder, intl (i18n), cached_network_image
- **Calendario**: table_calendar (citas profesionales)
- **Web específico**: url_strategy (URLs limpias), flutter_web_plugins

**Testing**:

- **Backend**: pytest, pytest-asyncio, pytest-cov
- **Admin React**: vitest, @testing-library/react, playwright
- **Flutter**: flutter_test, integration_test, mockito, golden_toolkit

- **Justificación Flutter para Web + Mobile**
  - **Código compartido**: 85-90% entre web y mobile (vs 40% separados)
  - **Desarrollo simultáneo**: Una feature = dos plataformas
  - **UX consistente**: Misma experiencia usuario final
  - **Integración Firebase**: Nativa en ambas plataformas
  - **Hot reload**: Desarrollo rápido web y mobile
  - **Performance**: Compilado a WebAssembly (web) y nativo (mobile)
  - **PWA**: Flutter Web genera PWAs de forma nativa
  - **Mantenimiento**: Un equipo Flutter vs dos equipos separados
  - **Melos**: Gestión de monorepo Flutter integrada
- Sistema de Roles y Permisos (RBAC)
  - **Paciente**: acceso a su info, citas, historial
  - **Profesional**: gestión de pacientes, citas, historial clínico
  - **Colaborador**: permisos delegados por profesional (ej: asistente,
    secretaria)
  - **Admin Plataforma**: aprobación de profesionales, moderación
  - **Super Admin**: gestión global del sistema
- Arquitectura Multi-Tenant + RBAC
  - Tenant ID: identificador del profesional
  - User roles: matriz de permisos por rol
  - Firestore security rules para aislamiento
  - Backend middleware para autorización

### 4.1 FinOps: Análisis de Costos y Optimización

**Archivo relacionado**: `docs/finops/cost-analysis-and-budgets.md` (documento
P0 a crear)

Este análisis detalla los costos esperados de la arquitectura de microservicios
propuesta y estrategias de optimización.

#### Presupuesto Mensual Estimado

**🔧 Staging Environment (Desarrollo Activo)**

| Componente                           | Configuración                 | Costo Mensual    |
| ------------------------------------ | ----------------------------- | ---------------- |
| **Backend Microservicios**           |                               |                  |
| api-auth (Cloud Run)                 | Scale-to-zero, 512MB, 1vCPU   | $5-10            |
| api-appointments (Cloud Run)         | Scale-to-zero, 1GB, 1vCPU     | $10-15           |
| api-payments (Cloud Run Node)        | Scale-to-zero, 512MB, 1vCPU   | $3-5             |
| api-notifications (Cloud Run Node)   | Scale-to-zero, 256MB, 1vCPU   | $2-5             |
| api-admin (Cloud Run)                | Scale-to-zero, 512MB, 1vCPU   | $3-5             |
| api-analytics (Cloud Run)            | Scale-to-zero, 512MB, 1vCPU   | $2-5             |
| **Frontend Apps**                    |                               |                  |
| web-admin React (Cloud Run)          | Scale-to-zero, 512MB          | $3-5             |
| web-patient Flutter (Cloud Run)      | Scale-to-zero, 512MB          | $3-5             |
| web-professional Flutter (Cloud Run) | Scale-to-zero, 512MB          | $4-5             |
| **Data Layer**                       |                               |                  |
| Firestore                            | 1GB storage, 10k ops/day      | $5-10            |
| Cloud SQL PostgreSQL                 | db-f1-micro (analytics)       | $25-35           |
| Cloud Storage                        | 5GB, 1k ops/day               | $1-3             |
| Secret Manager                       | 30 secrets, 500 accesses/day  | $2-5             |
| **Networking**                       |                               |                  |
| Load Balancer                        | HTTPS LB + health checks      | $18-20           |
| Cloud CDN                            | 10GB egress/mes               | $2-3             |
| Cloud Armor WAF                      | 5 rules                       | $5-7             |
| **Observabilidad**                   |                               |                  |
| Cloud Logging                        | 10GB/mes, 7-30 días retención | $5-10            |
| Cloud Monitoring                     | 50 metrics, 10 dashboards     | $5-10            |
| Cloud Trace                          | 1M spans/mes                  | $0-2             |
| **TOTAL STAGING**                    |                               | **$100-150/mes** |

**Comparación con objetivo actual**: $70-103/mes → +30-45% por microservicios

**🚀 Producción Environment (Alta Disponibilidad)**

| Componente                    | Configuración                                        | Costo Mensual        |
| ----------------------------- | ---------------------------------------------------- | -------------------- |
| **Backend Microservicios**    |                                                      |                      |
| 6 Cloud Run services          | Min 1 instance, CPU always allocated, 1-2GB, 1-2vCPU | $250-400             |
| **Frontend Apps**             |                                                      |                      |
| 3 Cloud Run frontend apps     | Min 1 instance, 512MB-1GB                            | $100-150             |
| **Data Layer**                |                                                      |                      |
| Firestore                     | 10GB storage, 1M ops/día                             | $50-150              |
| Cloud SQL PostgreSQL          | db-custom-2-8192 + HA + backups                      | $150-250             |
| Cloud Storage                 | 50GB + versioning                                    | $10-30               |
| Secret Manager                | 50 secrets, 10k accesses/día                         | $5-10                |
| **Networking**                |                                                      |                      |
| Load Balancer + egress        | HTTPS LB + 100GB egress                              | $40-70               |
| Cloud CDN                     | 500GB egress + cache                                 | $30-60               |
| Cloud Armor WAF               | 20 rules + advanced                                  | $10-15               |
| **Observabilidad**            |                                                      |                      |
| Cloud Logging                 | 100GB/mes, 30 días                                   | $30-50               |
| Cloud Monitoring              | 200 metrics, uptime checks, alerts                   | $20-40               |
| Cloud Trace + Profiler        | 10M spans/mes                                        | $10-20               |
| Error Reporting + Debugger    | Incluido                                             | $0                   |
| **Backup & DR**               |                                                      |                      |
| Cloud SQL backups             | Automated + PITR                                     | $10-20               |
| Firestore exports             | Weekly to GCS                                        | $5-10                |
| Disaster Recovery testing     | Trimestral                                           | $5-10                |
| **TOTAL PRODUCCIÓN INICIAL**  |                                                      | **$700-900/mes**     |
| **TOTAL PRODUCCIÓN ESCALADA** | (10k+ usuarios activos)                              | **$1,200-1,800/mes** |

#### Estrategia de Optimización de Costos

**🎯 Fase Staging (Desarrollo)**

1. **Scale-to-Zero Agresivo**
   - Todos los Cloud Run services escalan a 0 instancias fuera de horario
     laboral
   - Ahorro estimado: 40-50% vs min instances = 1
   - Implementación: `--min-instances=0` en Terraform

2. **Firestore Emulator Local**
   - Desarrollo local usa emulador (gratis)
   - Solo staging usa Firestore real para integration testing
   - Ahorro: $5-10/mes en desarrollo

3. **Cloud SQL Scheduling**
   - Detener instancia Cloud SQL fuera de horario (20:00-8:00, weekends)
   - Cloud Scheduler + Cloud Functions para automatizar
   - Ahorro: ~50% ($12-17/mes)

4. **Logging Retention Reducida**
   - 7 días retención en staging (vs 30 días producción)
   - Ahorro: ~70% en costos de logging

5. **Budget Alerts**
   - Alert al 50%, 80%, 100% de $150/mes
   - Notificaciones a email + Slack
   - GCP Budgets API + Cloud Functions

**Implementación**:

```bash
# Terraform budget alert
resource "google_billing_budget" "staging_budget" {
  billing_account = var.billing_account
  display_name    = "Adyela Staging Budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
    labels   = { environment = "staging" }
  }

  amount {
    specified_amount {
      units = "150" # $150/mes
    }
  }

  threshold_rules {
    threshold_percent = 0.5  # 50%
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 0.8  # 80%
  }
  threshold_rules {
    threshold_percent = 1.0  # 100%
  }
}
```

**🎯 Fase Producción (Optimización Continua)**

1. **Cost Allocation Tags**
   - Etiquetar recursos por: `service`, `tier` (free/pro/enterprise), `tenant`
     (grandes clientes)
   - Permite analytics de costo por componente
   - Identificar servicios más costosos para optimizar

2. **Right-Sizing con Recommender API**
   - GCP Cloud Recommender sugiere optimizaciones
   - Revisar mensualmente: instance sizes, idle resources
   - Estimación ahorro: 15-25%

3. **Committed Use Discounts (CUD)**
   - Cuando volumen es predecible (post-MVP), comprometer 1 año
   - Descuento: 37-57% en Cloud Run, Compute, SQL
   - Aplicar solo cuando usage es estable (Mes 12+)

4. **Firestore Cost Optimization**
   - Denormalización estratégica para reducir reads
   - Caching con Cloud Memorystore Redis ($15-30/mes) para queries frecuentes
   - Composite indexes optimizados (evitar index overhead)
   - Estimated savings: 30-40% en document reads

5. **CDN Hit Ratio Optimization**
   - Objetivo: >80% cache hit ratio (reduce egress costs)
   - Cache-Control headers optimizados
   - Invalidación selectiva (no full cache purge)

6. **Multi-Region vs Single-Region**
   - **Staging**: Single-region (us-central1) - suficiente
   - **Producción inicial**: Single-region + CDN global
   - **Producción escalada**: Multi-region solo si latency crítica (LATAM:
     us-east1 + southamerica-east1)

7. **Monitoreo de Anomalías de Costo**
   - Cloud Functions con Billing Export → BigQuery
   - Alertas automáticas si costo diario > 20% normal
   - Dashboard con Looker Studio (gratis)

#### Cost Attribution por Tenant (Multi-Tenancy)

Para modelo híbrido (pool + silo):

**Pool Model (Tier Free/Pro)**:

- Todos los tenants comparten infraestructura
- Costo prorrateado por: # usuarios activos, API calls, storage usado
- Tracking: Custom metrics en Cloud Monitoring
- `tenant_id` label en todas las operaciones Firestore

**Silo Model (Tier Enterprise)**:

- Infraestructura dedicada por tenant grande
- Cloud Run service dedicado + Firestore collection dedicada
- Billing directo: cada recurso etiquetado con `tenant_id=enterprise_xyz`
- Exportar a factura mensual al cliente

**Ejemplo Terraform para tenant enterprise**:

```hcl
resource "google_cloud_run_service" "api_appointments_enterprise" {
  for_each = var.enterprise_tenants

  name     = "api-appointments-${each.key}"
  location = var.region

  metadata {
    labels = {
      tenant      = each.key
      tier        = "enterprise"
      environment = var.environment
    }
  }

  template {
    spec {
      containers {
        image = var.appointments_image
        env {
          name  = "TENANT_ID"
          value = each.key
        }
      }
    }
  }
}
```

#### Métricas de FinOps a Monitorear

1. **Cost per Active User**: Costo total / MAU (Monthly Active Users)
   - Objetivo staging: N/A (dev team only)
   - Objetivo producción: <$0.50/usuario/mes

2. **Cost per API Request**: Costo backend / # requests
   - Objetivo: <$0.0001/request

3. **Infrastructure Cost as % Revenue** (post-monetization):
   - Objetivo: <30% en Fase 1, <20% en Fase 2

4. **Egress Cost Ratio**: Egress / Total infra cost
   - Objetivo: <15% (CDN optimizado reduce egress)

#### Riesgos de Costos y Mitigación

| Riesgo                                      | Probabilidad | Impacto | Mitigación                                     |
| ------------------------------------------- | ------------ | ------- | ---------------------------------------------- |
| Staging excede $150/mes                     | Media        | Bajo    | Budget alerts + auto-shutdown fuera de horario |
| Firestore runaway costs (query inefficient) | Alta         | Alto    | Query analysis en CI/CD + cost alerts          |
| Cloud SQL oversizing                        | Media        | Medio   | Right-sizing reviews mensuales                 |
| Egress costs por CDN mal configurado        | Media        | Medio   | Cache hit ratio monitoring + alerts            |
| Producción excede budget sin revenue        | Baja         | Alto    | Feature flags para limitar usage + waitlist    |

#### Roadmap de Optimización

- **Mes 1-3**: Setup budget alerts, cost allocation tags, dashboards básicos
- **Mes 4-6**: Análisis de costo por servicio, optimización Firestore queries
- **Mes 7-9**: Implementar caching (Redis), optimizar CDN, right-sizing
- **Mes 10-12**: Cost attribution por tenant, evaluación CUD contracts
- **Post-MVP**: FinOps automation (auto-scaling policies, anomaly detection)

---

- **Estrategia de Datos: Firestore + Cloud SQL (Híbrida para Staging)**

**Decisión Arquitectónica**: Base de datos híbrida optimizada por caso de uso

**🔥 Firestore (Operacional - Microservicios Transaccionales)**:

- **api-auth**: Usuarios, roles, sesiones, tokens
- **api-appointments**: Citas, calendario, disponibilidad, conflictos
- **api-notifications**: Mensajes, notificaciones push, estado de envío
- **api-admin**: Aprobaciones, solicitudes, moderación
- **api-payments**: Transacciones activas, webhooks Stripe

**Ventajas para estos servicios**:

- ✅ Real-time: Cambios instantáneos (citas canceladas, notificaciones)
- ✅ Offline support: Apps móviles funcionan sin conexión
- ✅ Multi-tenant: Aislamiento nativo por profesional con subcollections
- ✅ Escalabilidad: Auto-scaling sin configuración
- ✅ Security rules: Validación granular a nivel de documento
- ✅ Performance: <10ms latencia, perfecto para operaciones CRUD
- ✅ Costo en staging: $1-5/mes con volumen bajo

**Estructura Firestore Multi-tenant**:

```
/tenants/{tenantId}/
  /users/{userId}
  /appointments/{appointmentId}
  /patients/{patientId}
  /professionals/{professionalId}
  /notifications/{notificationId}
```

**🗄️ Cloud SQL PostgreSQL (Analítico - Servicios de Reporting)**:

- **api-analytics**: Métricas, reportes, dashboards, KPIs
- **Audit logs**: Logs de auditoría (7 años para compliance futuro)
- **Business intelligence**: Analytics complejos, agregaciones
- **Data warehouse**: Datos históricos para machine learning

**Ventajas para estos servicios**:

- ✅ SQL completo: Queries complejas, JOINs, subqueries, window functions
- ✅ Analytics: Agregaciones, estadísticas, reportes complejos
- ✅ Compliance: Audit logs estructurados para HIPAA futuro
- ✅ Integraciones: Compatible con herramientas BI (Looker, Metabase)
- ✅ Costo predecible: $25-35/mes staging (db-f1-micro)
- ✅ Backup: Point-in-time recovery automático

**Sincronización Firestore → Cloud SQL**:

- Cloud Functions triggered por cambios en Firestore
- ETL nocturno para datos históricos
- Pub/Sub para eventos críticos
- Replicación asíncrona (eventual consistency aceptable para analytics)

**Costos Estimados Staging**:

```
Firestore: $1-5/mes (operacional, bajo volumen)
Cloud SQL: $25-35/mes (db-f1-micro, analytics)
Total: $26-40/mes (vs $50+ solo Cloud SQL escalado)
```

**Migración Gradual**:

- **Fase 1 (MVP)**: Solo Firestore para todo (desarrollo rápido)
- **Fase 2 (Post-MVP)**: Agregar Cloud SQL para api-analytics
- **Fase 3 (Optimización)**: ETL automático Firestore → Cloud SQL

**Justificación Híbrida**:

- Firestore: Perfecto para operaciones transaccionales, real-time, offline
- Cloud SQL: Ideal para analytics complejos, compliance, reporting
- Costo optimizado: Cada DB para lo que es mejor
- Escalabilidad: Firestore auto-scale, Cloud SQL para análisis

- Consideraciones de compliance (HIPAA evolución)
- Plan de actualización de dependencias

### 5. Plan de Implementación por Fases

**Archivo**: `docs/planning/health-platform-implementation-plan.md`

Roadmap detallado con fases, tareas de alto nivel y dependencias.

**Timeline Actualizado**: **8-12 meses** (vs 4-6 meses original) - prioridad en
calidad > velocidad

**Contenido**:

#### **Fase 0: Preparación y Fundamentos (Mes 1-2)**

**Objetivos**: Setup completo de infraestructura, documentación y arquitectura
base

**Tareas críticas (P0)**:

- ✅ Crear documentación estratégica completa (este plan + 10 docs)
- ✅ Setup Terraform IaC para todos los microservicios
  - Módulos por servicio (api-auth, api-appointments, etc.)
  - Environments (staging, producción)
  - Budget alerts y cost monitoring
- ✅ Migración Firestore single-tenant → multi-tenant schema
  - Diseño de collections por tenant
  - Firestore security rules multi-tenant
  - Data migration scripts
- ✅ Setup CI/CD pipelines (GitHub Actions)
  - Workflows por microservicio
  - Security scanning (Trivy, Snyk, Gitleaks)
  - E2E tests automatizados
- ✅ Setup observabilidad distribuida
  - Cloud Trace para distributed tracing
  - Cloud Logging con correlation IDs
  - Dashboards en Cloud Monitoring
- ✅ Setup Task Master AI con PRD completo

**Criterios de éxito**:

- Infraestructura staging desplegada con Terraform
- Budget alerts funcionando ($150/mes threshold)
- CI/CD pipelines ejecutándose
- Documentación completa aprobada

**Duración**: 8 semanas (2 meses)

---

#### **Fase 1: Microservicios Core + Flutter Mobile MVP (Mes 3-6)**

**Objetivos**: Extraer primeros microservicios del monolito + apps mobile
nativas

**Estrategia**: Strangler Fig Pattern (gradual, no big bang)

**Tareas backend**:

- ✅ **api-auth** (Mes 3-4):
  - Extracción de lógica de autenticación del monolito
  - Multi-provider auth (Google, Facebook, Apple, email)
  - RBAC system (roles: paciente, profesional, admin)
  - Multi-tenancy enforcement
  - JWT token generation
  - Service-to-service authentication
- ✅ **api-appointments** (Mes 4-5):
  - Extracción de lógica de citas del monolito
  - CRUD citas con multi-tenancy
  - Calendario y disponibilidad
  - Validación de conflictos
  - Integración con api-auth (permisos)
  - Event publishing (Pub/Sub)
- ⚠️ **Mantener monolito en paralelo** (routing con feature flags)

**Tareas frontend**:

- ✅ **mobile-patient** (Flutter iOS/Android/Web): ✅ COMPLETADO
  - Onboarding pacientes (3 pasos) ✅
  - Registro y autenticación (Google OAuth + Email) ✅
  - Búsqueda de profesionales ✅
  - Reserva de citas (3 taps) ✅
  - Historial de citas ✅
  - Perfil paciente ✅
- ✅ **mobile-professional** (Flutter iOS/Android/Web): ✅ COMPLETADO
  - Onboarding profesionales (5 pasos + validación) ✅
  - Dashboard profesional ✅
  - Calendario de citas ✅ (UI implementada, backend pendiente)
  - Gestión de pacientes ✅
  - Perfil profesional ✅
- ✅ **Shared packages** (packages/flutter-\*):
  - flutter-core: Models, DTOs, business logic ✅ IMPLEMENTADO
  - flutter-shared: Widgets y componentes UI ✅ IMPLEMENTADO
  - flutter-auth: Lógica autenticación compartida 🔧 PENDIENTE (P1 Post-MVP)
    - Nota: Actualmente cada app maneja su propia auth
    - Beneficio: DRY, consistency, maintainability
    - Contenido sugerido: AuthService, AuthState, User models, token management

**Tareas testing**:

- Unit tests (80% coverage backend, 70% mobile)
- Integration tests con emuladores
- E2E tests críticos (login, crear cita, ver historial)

**Criterios de éxito**:

- 🔧 api-auth y api-appointments en staging funcionando (En desarrollo)
- ✅ Mobile apps (iOS + Android + Web) creadas con UI completa
- ✅ 85%+ código compartido entre mobile apps (flutter-core, flutter-shared)
- ⚠️ E2E tests passing (flujos críticos) - Pendiente implementación
- 🔧 Monolito + microservicios coexistiendo (En progreso)

**Duración**: 16 semanas (4 meses) **Estado Actual**: Fase 1 ~60% completada
(Flutter apps ✅, microservicios 🔧)

---

#### **Fase 2: Panel Admin + Pagos + Notificaciones (Mes 7-9)**

**Objetivos**: Completar microservicios restantes + admin web + monetización

**Tareas backend**:

- ✅ **api-admin** (Mes 7):
  - Panel de aprobación de profesionales
  - Validación de credenciales médicas
  - Moderación de contenido
  - Analytics de plataforma
- ✅ **api-payments** (Node.js, Mes 7-8):
  - Integración Stripe SDK
  - Payment intents
  - Webhooks handling
  - Suscripciones freemium (Free, Pro, Enterprise)
  - Facturación automática
- ✅ **api-notifications** (Node.js, Mes 8):
  - FCM push notifications
  - Email (SendGrid/Twilio)
  - SMS (Twilio)
  - Recordatorios automáticos
  - Templates personalizables
- ✅ **api-analytics** (Python, Mes 9):
  - Cloud SQL PostgreSQL setup
  - ETL Firestore → Cloud SQL
  - Reportes y dashboards
  - Métricas de negocio (MAU, MRR, churn)

**Tareas frontend**:

- ✅ **web-admin** (React + shadcn/ui, Mes 7-8):
  - Evolución del React PWA existente
  - Restricción @adye.care emails
  - Dashboard de aprobaciones
  - Validación de documentos profesionales
  - Analytics y reportes
  - Gestión de suscripciones

**Tareas Flutter Web (opcional, evaluar en Mes 8)**:

- ⚠️ **Decisión**: Evaluar si web-patient y web-professional en Flutter Web son
  realmente necesarios
  - Opción A: Solo mobile (pacientes usan mobile, profesionales mobile + admin
    web)
  - Opción B: Agregar Flutter Web (85-90% código compartido con mobile)
  - **Recomendación**: Opción A para MVP, Opción B post-MVP

**Tareas infraestructura**:

- Cloud SQL PostgreSQL deployment (analytics)
- Pub/Sub topics y subscriptions
- Stripe webhook endpoints
- Redis cache (Memorystore) para rate limiting

**Criterios de éxito**:

- Todos los 6 microservicios en staging
- Admin web funcional con aprobaciones
- Pagos funcionando con Stripe test mode
- Notificaciones push funcionando
- Saga pattern implementado (reserva + pago)

**Duración**: 12 semanas (3 meses)

---

#### **Fase 3: Testing Exhaustivo + Optimización + Pre-Launch (Mes 10-12)**

**Objetivos**: Garantizar calidad, performance y seguridad antes de producción

**Tareas testing**:

- ✅ **E2E Testing Multi-Plataforma**:
  - Playwright (admin web): 100% critical paths
  - Flutter integration_test (mobile): 100% critical paths
  - Cross-browser testing (Chrome, Safari, Firefox)
  - Cross-device testing (iOS 15+, Android 10+)
- ✅ **Performance Testing**:
  - Load testing con k6 (10k usuarios concurrentes)
  - Stress testing (breaking points)
  - Lighthouse CI (admin web: >90/100)
  - Mobile performance (startup time <3s)
- ✅ **Security Testing**:
  - Penetration testing (externo)
  - OWASP API Top 10 validation
  - Firestore security rules testing
  - Secrets scanning (Gitleaks)
- ✅ **Accessibility Testing**:
  - WCAG 2.1 AA compliance (admin web)
  - Mobile accessibility (screen readers)
  - High contrast mode testing

**Tareas optimización**:

- ✅ **Backend Optimization**:
  - Firestore query optimization (índices, denormalización)
  - Caching strategy (Redis para hot paths)
  - API response time <200ms (p95)
  - Circuit breakers tuning
- ✅ **Frontend Optimization**:
  - Bundle size optimization (lazy loading)
  - Image optimization (WebP, responsive)
  - CDN caching strategy (>80% hit ratio)
  - Flutter web optimization (si se implementó)
- ✅ **Cost Optimization**:
  - Right-sizing Cloud Run instances
  - Firestore reads optimization (-30%)
  - CDN egress optimization
  - Budget tracking y forecasting

**Tareas compliance**:

- ✅ **Compliance Latinoamérica**:
  - Términos y condiciones
  - Política de privacidad
  - Consentimientos digitales
  - ARCO rights implementation
- ⚠️ **Preparación HIPAA** (diseño futuro):
  - Audit logs (7 años retención design)
  - PHI encryption strategy
  - BAA templates (futuro)

**Tareas documentación**:

- ✅ Documentación de usuario (pacientes, profesionales)
- ✅ Documentación técnica (arquitectura, runbooks)
- ✅ API documentation (OpenAPI specs)
- ✅ Troubleshooting guides

**Tareas pre-launch**:

- ✅ Disaster recovery testing
- ✅ Backup validation
- ✅ Monitoring alerts tuning
- ✅ On-call runbooks
- ✅ Production deployment plan
- ✅ Rollback procedures

**Criterios de éxito**:

- E2E tests: 100% critical paths passing
- Performance: API <200ms (p95), Mobile <3s startup
- Security: Penetration test passed
- Accessibility: WCAG 2.1 AA compliance
- Cost: Staging <$150/mes, producción projection <$900/mes
- Documentation: 100% complete

**Duración**: 12 semanas (3 meses)

---

#### **Post-MVP (Mes 13+): Optimización Continua**

**Features Post-MVP**:

- Flutter Web (si no se hizo en Fase 2)
- Telemedicina avanzada (Jitsi/Twilio Video)
- Laboratorios y farmacias integrations
- AI features (recomendaciones, chatbot)
- Multi-region deployment
- HIPAA compliance completo
- SOC 2 Type II

**Métricas a monitorear**:

- MAU (Monthly Active Users)
- MRR (Monthly Recurring Revenue)
- Churn rate
- NPS (Net Promoter Score)
- API uptime (SLA: 99.9%)
- Cost per active user (<$0.50)

---

#### Timeline Visual (Gantt Simplificado)

```
Mes 1-2:   [████████████████████] Fase 0: Preparación
Mes 3-6:   [████████████████████████████████████████████] Fase 1: Core + Mobile
Mes 7-9:   [████████████████████████████] Fase 2: Admin + Payments + Notifications
Mes 10-12: [████████████████████████████] Fase 3: Testing + Optimization + Pre-Launch
Mes 13+:   [══════════════════════] Post-MVP: Continuous Improvement

Total: 12 meses para MVP production-ready
```

#### Dependencias entre Fases

- Fase 1 depende de Fase 0 (infraestructura + multi-tenancy)
- Fase 2 depende de Fase 1 (api-auth + api-appointments funcionando)
- Fase 3 depende de Fase 2 (todos los microservicios completos)
- Post-MVP depende de Fase 3 (producción estable)

#### Equipo Recomendado por Fase

**Fase 0** (Mes 1-2):

- 1 DevOps Engineer (Terraform, GCP)
- 1 Backend Lead (multi-tenancy design)
- 1 Tech Lead (arquitectura)

**Fase 1** (Mes 3-6):

- 2 Backend Engineers (Python/FastAPI)
- 2 Mobile Engineers (Flutter)
- 1 DevOps Engineer
- 1 QA Engineer

**Fase 2** (Mes 7-9):

- 2 Backend Engineers (1 Python, 1 Node.js)
- 1 Frontend Engineer (React admin)
- 2 Mobile Engineers (Flutter)
- 1 DevOps Engineer
- 1 QA Engineer

**Fase 3** (Mes 10-12):

- 1 Backend Engineer (optimization)
- 1 Frontend Engineer (optimization)
- 1 Mobile Engineer (optimization)
- 2 QA Engineers (testing exhaustivo)
- 1 Security Engineer (pentesting)
- 1 DevOps Engineer

**Total team size**: 6-8 especialistas (coincide con respuesta del usuario)

### 6. Modelo de Negocio Detallado

**Archivo**: `docs/planning/health-platform-business-model.md`

Estrategia de monetización y go-to-market.

**Contenido**:

- Análisis de mercado (breve)
- Propuesta de valor por segmento
- Estructura de precios
- Tier Free (funcionalidades básicas)
- Tier Professional ($X/mes)
- Tier Premium ($Y/mes)
- Tier Enterprise (custom)
- Funcionalidades por tier (matriz detallada)
- Proyecciones financieras simplificadas
- Estrategia de adquisición de usuarios
- Profesionales: validación y onboarding
- Pacientes: registro abierto
- Estrategia de retención
- KPIs clave a monitorear
- Plan de go-to-market (primeros 6 meses)

### 7. Estrategia de Compliance y Seguridad (Enfoque Staging)

**Archivo**: `docs/planning/health-platform-compliance-roadmap.md`

Estrategia de seguridad para desarrollo en staging. Producción se revisará en
fase futura.

**Contenido**:

- **Enfoque Actual: Solo Staging/Desarrollo**
  - Todo el desarrollo en ambiente staging
  - Compliance básico (no HIPAA todavía)
  - FinOps: Máxima optimización de costos
  - Producción: Revisión futura cuando sea necesario

- **Controles de Seguridad Básicos para Staging**
  - Encriptación en tránsito (TLS 1.3)
  - Autenticación robusta (Firebase Auth multi-provider)
  - Firestore security rules básicas
  - Rate limiting en API
  - Validación de entrada (Pydantic, Zod)
  - Secrets en Secret Manager
  - Logs básicos (7-30 días retención)

- **Regulaciones y Compliance (Referencia Futura)**
  - HIPAA (para producción USA)
  - GDPR (para producción EU)
  - Regulaciones locales por país
  - **Nota**: Implementación completa cuando se migre a producción

- **Medidas Excluidas en Staging** (para producción futura):
  - CMEK encryption
  - VPC Service Controls
  - Audit logs 7 años
  - BAA con GCP
  - Certificaciones formales

### 8. Estrategia de Integraciones Futuras

**Archivo**: `docs/planning/health-platform-integrations-roadmap.md`

Roadmap de integraciones con sistemas externos.

**Contenido**:

- Integraciones Fase 1 (MVP)
- Auth providers (Google, Facebook, Apple, Microsoft)
- SMS/Email (Twilio, SendGrid - ya existe en Adyela)
- Pagos (Stripe)
- Integraciones Fase 2 (Post-MVP)
- Telemedicina (Twilio Video, Jitsi - ya existe en Adyela)
- Laboratorios (APIs específicas)
- Farmacias (APIs específicas)
- Integraciones Fase 3 (Futuro)
- Sistemas hospitalarios (HL7, FHIR)
- Aseguradoras
- Dispositivos médicos (IoT)
- Arquitectura de integración
- APIs y protocolos
- Estrategia de partnerships
- Consideraciones de interoperabilidad

### 9. Estrategia de UX/UI y Design System

**Archivo**: `docs/planning/health-platform-ux-strategy.md`

Guía completa de experiencia de usuario y sistema de diseño.

**Contenido**:

- **Principios de Diseño para Salud**
  - Accesibilidad (WCAG 2.1 AA compliance)
  - Claridad y simplicidad (información médica compleja → simple)
  - Feedback constante (estados de carga, confirmaciones)
  - Diseño empático (considerar momentos de vulnerabilidad)
  - Confianza y profesionalismo
- **Design System - Web (shadcn/ui base)**
  - Paleta de colores
    - Paciente: colores cálidos, amigables (azules suaves, verdes)
    - Profesional: colores profesionales (azules oscuros, grises)
    - Admin: colores neutros, funcionales
  - Tipografía médica legible
    - Fuentes sans-serif (Inter, Roboto)
    - Tamaños adaptados por contexto
    - Jerarquía clara
  - Espaciado consistente (8px grid system)
  - Componentes shadcn/ui personalizados
  - Iconografía con lucide-react
- **Design System - Mobile (Flutter)**
  - Material Design 3 adaptado
  - Componentes propios Flutter
  - Consistencia visual con web
  - Touch-friendly (mínimo 44x44pt)
- **Flujos de Usuario Optimizados**
  - **Paciente**:
    - Onboarding: 3 pasos (registro, perfil, preferencias)
    - Búsqueda de profesional: filtros intuitivos
    - Reserva de cita: máximo 3 taps
    - Acceso a historial: navegación simple
  - **Profesional**:
    - Onboarding: 5 pasos (registro, validación, perfil, especialidad,
      configuración)
    - Dashboard: vista rápida de agenda y pacientes
    - Gestión de citas: arrastrar y soltar
    - Registro clínico: formularios optimizados
  - **Admin**:
    - Panel de aprobaciones: workflow eficiente
    - Moderación: acciones rápidas
    - Analytics: visualizaciones claras
- **Patrones de Interacción**
  - Navegación intuitiva (máximo 3 niveles)
  - Formularios médicos optimizados (autocompletado, validación en tiempo real)
  - Feedback visual inmediato (estados de carga, éxito, error)
  - Confirmaciones para acciones críticas
  - Swipe actions en móvil
  - Búsqueda predictiva
- **Responsive Design**
  - Mobile-first approach
  - Breakpoints: 320px, 768px, 1024px, 1440px
  - Touch-friendly interfaces (botones grandes)
  - Layouts adaptables
- **Diseño Inclusivo**
  - Soporte para adultos mayores (UI más grande, contraste alto)
  - Alta legibilidad (contraste WCAG AA)
  - Iconografía universal (sin depender solo de color)
  - Soporte para modo oscuro
  - Optimización para lectores de pantalla
- **Testing y Validación UX**
  - User testing por rol
  - A/B testing de flujos críticos
  - Métricas de usabilidad (tiempo de tarea, tasa de éxito)
  - Heatmaps y analytics

### 10. DevOps, CI/CD y Calidad Continua

**Archivo**: `docs/infrastructure/health-platform-devops-strategy.md`

Estrategia de infraestructura, pipelines y calidad durante todo el ciclo de
vida.

**Contenido**:

- **Infraestructura como Código (Terraform)**
  - **Mantener estructura actual de Adyela**:
    - Módulos Terraform existentes (`infra/modules/`)
    - Environments (staging, production)
    - Estado remoto en GCS
  - **Evolucionar para nueva plataforma**:
    - Nuevos recursos GCP:
      - Cloud Run services adicionales (admin-api, notifications-service)
      - Firestore multi-tenant indexes
      - Firebase Authentication providers adicionales
      - Cloud Storage buckets por tenant
      - Cloud Scheduler para jobs recurrentes
    - Recursos para Flutter:
      - Firebase App Distribution
      - Play Store/App Store deployment configs
    - Recursos de pago:
      - Stripe webhook endpoints
      - Secret Manager para API keys
  - **Estructura Terraform ampliada (Microservicios)**:

    ```
    infra/
    ├── modules/
    │   ├── microservices/
    │   │   ├── api-auth/              # Cloud Run - Auth service (nuevo)
    │   │   ├── api-appointments/      # Cloud Run - Appointments service (evolución de api/)
    │   │   ├── api-payments/          # Cloud Run - Payments service Node.js (nuevo)
    │   │   ├── api-notifications/     # Cloud Run - Notifications service Node.js (nuevo)
    │   │   ├── api-admin/             # Cloud Run - Admin service (nuevo)
    │   │   └── api-analytics/         # Cloud Run - Analytics service (nuevo)
    │   ├── frontend/
    │   │   ├── web-admin/             # Cloud Run - React admin (evolución de web/)
    │   │   ├── web-patient/           # Cloud Run - Flutter web patient (nuevo)
    │   │   └── web-professional/      # Cloud Run - Flutter web professional (nuevo)
    │   ├── mobile/
    │   │   ├── firebase-config/       # Firebase config para Flutter mobile
    │   │   └── app-distribution/      # Firebase App Distribution
    │   ├── networking/
    │   │   ├── load-balancer/         # HTTPS Load Balancer con routing a microservicios
    │   │   ├── cloud-armor/           # WAF rules
    │   │   └── ssl-certificates/      # Managed SSL certs
    │   ├── data/
    │   │   ├── firestore/             # Firestore multi-tenant indexes
    │   │   ├── storage/               # Cloud Storage buckets por tenant
    │   │   └── secret-manager/        # Secrets para cada servicio
    │   ├── messaging/
    │   │   ├── pubsub/                # Pub/Sub topics para eventos
    │   │   └── cloud-tasks/           # Task queues
    │   └── monitoring/
    │       ├── logging/               # Cloud Logging config
    │       ├── monitoring/            # Cloud Monitoring dashboards
    │       └── alerting/              # Alert policies
    ├── envs/
    │   └── staging/                   # Solo staging (producción futura)
    │       ├── microservices.tf       # Configuración de todos los microservicios
    │       ├── networking.tf          # Load Balancer routing
    │       ├── data.tf                # Firestore, Storage, Secrets
    │       └── monitoring.tf          # Observabilidad
    └── shared/
        ├── vpc.tf                     # VPC config
        ├── iam.tf                     # IAM roles y service accounts
        └── apis.tf                    # GCP APIs habilitadas
    ```

  - Variables por ambiente (staging vs production)
  - Secrets management con Secret Manager
  - IAM roles granulares por servicio

- **GitHub Actions Workflows**
  - **Mantener workflows actuales de Adyela**:
    - CI básico (lint, test, build)
    - Conventional commits validation
    - Pre-commit hooks
  - **Ampliar para Microservicios + Flutter + React Admin**:

    ```yaml
    workflows/
    # Microservicios Backend CI
    ├── ci-api-auth.yml              # FastAPI - Auth service tests, lint
    ├── ci-api-appointments.yml      # FastAPI - Appointments service tests, lint
    ├── ci-api-payments.yml          # Node.js - Payments service tests, lint
    ├── ci-api-notifications.yml     # Node.js - Notifications service tests, lint
    ├── ci-api-admin.yml             # FastAPI - Admin service tests, lint
    ├── ci-api-analytics.yml         # Python - Analytics service tests, lint

    # Frontend Apps CI
    ├── ci-web-admin.yml             # React + shadcn/ui tests, lint (evolución de ci-web.yml)
    ├── ci-web-patient.yml           # Flutter Web patient tests, build
    ├── ci-web-professional.yml      # Flutter Web professional tests, build
    ├── ci-mobile-patient.yml        # Flutter Mobile patient tests
    ├── ci-mobile-professional.yml   # Flutter Mobile professional tests

    # Deployment
    ├── cd-microservices-staging.yml # Deploy todos los microservicios a staging
    ├── cd-frontend-staging.yml      # Deploy todas las apps frontend a staging
    ├── cd-mobile-release.yml        # Firebase App Distribution + Store release

    # Security & Quality
    ├── security-scan.yml            # Trivy, Snyk, Gitleaks para todos los servicios
    ├── dependency-update.yml        # Renovate/Dependabot para todos los repos
    ├── terraform-validate.yml       # Validación de IaC para microservicios

    # E2E Testing
    └── e2e-staging.yml              # Tests E2E multi-plataforma en staging
    ```

  - **Pipeline stages**:
    1. Lint & Format check
    2. Unit tests (parallel)
    3. Integration tests
    4. Build & containerize
    5. Security scan
    6. Deploy to staging (auto)
    7. E2E tests staging
    8. Deploy to production (manual approval)

- **Calidad de Código - Estándares a Mantener**
  - **Backend (Python)**:
    - Linters: ruff, black, mypy (ya configurados)
    - Coverage mínimo: 80%
    - pytest para tests
    - Bandit para seguridad
  - **Web (React/TypeScript)**:
    - ESLint con reglas estrictas (ya configurado)
    - Prettier para formato (ya configurado)
    - TypeScript strict mode
    - Vitest para tests
    - Coverage mínimo: 80%
  - **Mobile (Flutter)**:
    - flutter analyze (lints)
    - dart format
    - flutter test
    - Coverage mínimo: 70%
    - integration_test para E2E

- **Seguridad Continua**
  - **Scan de código**:
    - Gitleaks (secrets detection) - ya existe
    - Trivy (vulnerabilidades en containers)
    - Snyk (dependencias vulnerables)
  - **Scan de infraestructura**:
    - tfsec (Terraform security)
    - checkov (IaC security)
  - **Runtime security**:
    - Cloud Armor (WAF) - ya existe en Adyela
    - VPC Service Controls (producción)
    - Audit logs habilitados
  - **Compliance checks**:
    - HIPAA compliance validation
    - Firestore security rules testing
    - API authorization testing

- **Testing Strategy - Por Tipo de App**
  - **Backend API**:
    - Unit tests: 80% coverage
    - Integration tests con Firestore emulator
    - Contract tests (Schemathesis)
    - Load tests (Locust)
  - **Web App**:
    - Unit tests (Vitest)
    - Component tests (React Testing Library)
    - E2E tests (Playwright) - ya existe
    - Visual regression tests
  - **Mobile Apps**:
    - Unit tests (flutter_test)
    - Widget tests
    - Integration tests en emuladores
    - Golden tests (visual)
  - **E2E Multi-plataforma**:
    - Flujos críticos end-to-end
    - Staging environment
    - Datos de prueba automatizados

- **Monitoreo y Observabilidad**
  - **Mantener de Adyela**:
    - Cloud Logging
    - Cloud Monitoring
    - Error Reporting
  - **Ampliar**:
    - Firebase Crashlytics (móvil)
    - Firebase Performance Monitoring
    - Sentry (errores en tiempo real)
    - Custom dashboards por rol
    - Alertas SLO-based

- **Gestión de Releases**
  - **Versionado semántico** (semver)
  - **Changesets** (ya existe en Adyela)
  - **Release notes automáticos**
  - **Mobile releases**:
    - Beta testing con Firebase App Distribution
    - Staged rollout en stores (10%, 50%, 100%)
  - **Web releases**:
    - Feature flags (LaunchDarkly o similar)
    - Canary deployments
    - Rollback automático si falla health check

- **Environments Strategy**
  - **Development**: Local con emuladores
  - **Staging**: GCP scale-to-zero (mantener)
  - **Production**: GCP alta disponibilidad (mantener)
  - **Preview**: Por cada PR (opcional, Cloud Run)

- **Documentación Técnica Continua**
  - ADRs (Architecture Decision Records)
  - API documentation (OpenAPI/Swagger)
  - Runbooks para operaciones
  - Postmortems de incidentes
  - Changelog automático

## Entregables

Todos los documentos listados arriba en formato Markdown, organizados en:

- `docs/planning/` - Documentos de planificación y negocio
- `docs/architecture/` - Documentos técnicos y arquitectura

## Consideraciones Especiales

1. **Reutilización de Adyela**: Maximizar uso de componentes existentes
2. **Task Master AI**: Generar PRD compatible con `task-master parse-prd`
3. **Equipo técnico**: Documentación para equipo con experiencia
4. **Timeline realista**: 8-12 meses para MVP funcional (actualizado)
5. **Enfoque gradual**: Evolución no revolución
6. **Compliance pragmático**: Staging simple, producción rigurosa

---

**Documento**: `docs/planning/health-platform-strategy.plan.md` **Versión**: 2.0
**Última actualización**: 2025-10-18 **Estado**: Fase 1 en progreso (~60%
completada) **Owner**: Engineering Lead **Próxima revisión**: Fin de Fase 1
(Mes 6)
