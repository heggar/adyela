# Patrones de Comunicación entre Servicios

## Resumen Ejecutivo

Este documento detalla los patrones de comunicación y resilience para la
arquitectura de microservicios de Adyela.

**Ver también**: `docs/planning/health-platform-strategy.plan.md` - Sección 4.2
para detalles de implementación completos.

---

## Matriz de Comunicación

| Servicio Origen  | Servicio Destino  | Patrón                  | Protocolo  | Caso de Uso               |
| ---------------- | ----------------- | ----------------------- | ---------- | ------------------------- |
| api-appointments | api-auth          | Sync (Request-Response) | REST/HTTPS | Validar permisos usuario  |
| api-payments     | api-appointments  | Async (Event)           | Pub/Sub    | Notificar pago completado |
| api-admin        | api-auth          | Sync (Request-Response) | REST/HTTPS | Otorgar permisos          |
| api-admin        | api-notifications | Sync (Request-Response) | REST/HTTPS | Enviar email aprobación   |
| api-appointments | api-notifications | Async (Event)           | Pub/Sub    | Recordatorio cita         |
| api-\*           | api-analytics     | Async (Event)           | Pub/Sub    | Tracking métricas         |

---

## Patrones Implementados

### 1. Synchronous REST (Request-Response)

**Cuándo usar**:

- Operaciones que requieren respuesta inmediata
- Validaciones críticas (auth, permisos)
- Operaciones transaccionales

**Implementación**:

```python
# Ver health-platform-strategy.plan.md líneas 191-224
```

**Best Practices**:

- ✅ Timeout: 5s crítico, 15s no-crítico
- ✅ Retry: 3 intentos con exponential backoff
- ✅ Circuit Breaker: Failfast tras 5 fallos
- ✅ Correlation IDs: Propagación en headers

---

### 2. Asynchronous Events (Pub/Sub)

**Cuándo usar**:

- Notificaciones no bloqueantes
- Analytics y logging
- Integración entre bounded contexts

**Topics Pub/Sub**:

| Topic                   | Publisher        | Subscribers                      | Schema Version |
| ----------------------- | ---------------- | -------------------------------- | -------------- |
| `appointment.created`   | api-appointments | api-notifications, api-analytics | v1             |
| `appointment.cancelled` | api-appointments | api-notifications, api-analytics | v1             |
| `professional.approved` | api-admin        | api-auth, api-notifications      | v1             |
| `payment.completed`     | api-payments     | api-appointments, api-analytics  | v1             |
| `user.registered`       | api-auth         | api-notifications, api-analytics | v1             |

**Implementación**:

```python
# Ver health-platform-strategy.plan.md líneas 243-308
```

**Best Practices**:

- ✅ Idempotency: Subscribers deben detectar duplicados
- ✅ Dead Letter Queue: Para mensajes fallidos
- ✅ Schema versioning: `version` field en eventos
- ✅ Event ID: UUID para deduplicación

---

### 3. Saga Pattern (Distributed Transactions)

**Casos de uso**:

- Reservar cita con pago (api-appointments + api-payments)
- Aprobar profesional (api-admin + api-auth + api-notifications)

**Implementación**: Ver `microservices-migration-strategy.md` - Saga examples

**Compensating Transactions**:

- Si pago falla → cancelar cita creada
- Si email falla → retry asíncrono (non-critical)

---

## Resilience Patterns

### Circuit Breaker

```python
# pybreaker library
from pybreaker import CircuitBreaker

payments_breaker = CircuitBreaker(fail_max=5, timeout_duration=60)

@payments_breaker
async def create_payment_intent(amount: int, currency: str):
    return await payments_client.create_intent(amount, currency)
```

**Configuración por servicio**:

- api-payments: `fail_max=5, timeout=60s` (crítico)
- api-notifications: `fail_max=10, timeout=120s` (menos crítico)
- api-analytics: `fail_max=20, timeout=300s` (non-critical)

### Retry con Exponential Backoff

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10)
)
async def call_service(data):
    # Implementation
```

### Caching

**Redis para hot paths**:

- User permissions: TTL 5 min
- Tenant config: TTL 15 min
- Professional availability: TTL 1 min

```python
# Ver health-platform-strategy.plan.md líneas 446-464
```

---

## Observabilidad

### Distributed Tracing

**Cloud Trace** con correlation IDs:

```python
# Propagación de trace context
@app.middleware("http")
async def add_correlation_id(request: Request, call_next):
    correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))

    # Attach to request state
    request.state.correlation_id = correlation_id

    # Add to response headers
    response = await call_next(request)
    response.headers["X-Correlation-ID"] = correlation_id

    return response
```

### Structured Logging

```python
import structlog

logger = structlog.get_logger()

logger.info(
    "appointment_created",
    appointment_id=appt.id,
    tenant_id=appt.tenant_id,
    correlation_id=get_correlation_id(),
    latency_ms=latency
)
```

---

## Testing Strategy

### Contract Testing (Pact)

Garantizar compatibilidad entre servicios:

```python
# Consumer (api-appointments) define contract
from pact import Consumer, Provider

pact = Consumer("api-appointments").has_pact_with(Provider("api-auth"))

pact.given("user exists")\
    .upon_receiving("permission validation request")\
    .with_request(method="POST", path="/api/v2/auth/validate")\
    .will_respond_with(status=200, body={"allowed": True})
```

### Integration Testing

Test inter-service communication con test containers:

```python
# tests/integration/test_appointment_creation.py
import pytest
from testcontainers.core.container import DockerContainer

@pytest.fixture
def api_auth_container():
    with DockerContainer("gcr.io/adyela/api-auth:test") as container:
        container.with_exposed_ports(8080)
        yield container

async def test_create_appointment_with_auth(api_auth_container):
    # Test full flow with real api-auth running
    ...
```

---

## Service Mesh Considerations

**Decision para MVP**: **NO usar Istio** (demasiado complejo)

**Alternativas GCP-native**:

- ✅ Cloud Run service-to-service auth (IAM)
- ✅ Cloud Load Balancing (routing, health checks)
- ✅ Cloud Trace (distributed tracing)
- ✅ Cloud Monitoring (métricas)

**Reevaluar Istio** en Fase 2 si necesitamos:

- mTLS automático
- Traffic splitting (canary deployments)
- Advanced observability

---

## Próximos Pasos

1. ✅ Implementar clients HTTP con circuit breakers (Fase 0)
2. ✅ Setup Cloud Pub/Sub topics (Fase 0)
3. ✅ Implementar distributed tracing (Fase 1)
4. ✅ Contract testing setup (Fase 1)

**Documento**: `docs/architecture/service-communication-patterns.md`
**Version**: 1.0 **Última actualización**: 2025-10-18
