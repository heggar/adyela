# Observabilidad en Sistemas Distribuidos

## 📊 Resumen Ejecutivo

Este documento define la estrategia de observabilidad para la arquitectura de
microservicios de Adyela, cubriendo logging, tracing, metrics y alerting.

**Objetivos**:

- Visibilidad end-to-end de requests a través de 6 microservicios
- Detección proactiva de problemas antes de que afecten usuarios
- Root cause analysis (RCA) rápido (<15 min para incidentes críticos)
- SLA monitoring y reporting

---

## 🏗️ Los 3 Pilares de Observabilidad

### 1. Logs (Eventos discretos)

### 2. Metrics (Agregaciones numéricas)

### 3. Traces (Flujo de requests distribuidos)

**Stack GCP**:

- **Cloud Logging**: Centralized logging
- **Cloud Monitoring**: Metrics y dashboards
- **Cloud Trace**: Distributed tracing
- **Error Reporting**: Error aggregation y alerting

---

## 📝 1. Logging Distribuido

### Structured Logging

**Formato**: JSON (parseable, filterable)

**Campos obligatorios**:

```json
{
  "timestamp": "2025-10-18T14:32:15.123Z",
  "severity": "INFO",
  "service": "api-appointments",
  "version": "1.2.3",
  "environment": "staging",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440000",
  "trace_id": "projects/adyela-staging/traces/abcd1234",
  "span_id": "000000000000004a",
  "user_id": "user_123",
  "tenant_id": "tenant_abc",
  "message": "Appointment created successfully",
  "metadata": {
    "appointment_id": "appt_789",
    "latency_ms": 145
  }
}
```

### Implementación Python (FastAPI)

```python
# api-*/logging_config.py
import structlog
import logging
from google.cloud import logging as cloud_logging

# Initialize Cloud Logging
cloud_logging_client = cloud_logging.Client()
cloud_logging_client.setup_logging()

# Configure structlog
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Usage
logger.info(
    "appointment_created",
    appointment_id=appointment.id,
    patient_id=appointment.patient_id,
    professional_id=appointment.professional_id,
    tenant_id=appointment.tenant_id,
    correlation_id=get_correlation_id(),
    latency_ms=latency
)
```

### Correlation IDs

**Qué es**: Un ID único que sigue a un request a través de todos los
microservicios

**Implementación**:

```python
# middleware/correlation.py
from fastapi import Request
import uuid

@app.middleware("http")
async def correlation_id_middleware(request: Request, call_next):
    # Extract from header or generate new
    correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))

    # Store in request state
    request.state.correlation_id = correlation_id

    # Add to response header
    response = await call_next(request)
    response.headers["X-Correlation-ID"] = correlation_id

    return response

def get_correlation_id():
    """Get current correlation ID from context"""
    from contextvars import ContextVar
    correlation_id_var: ContextVar[str] = ContextVar("correlation_id", default="")
    return correlation_id_var.get()
```

**Propagation entre servicios**:

```python
# infrastructure/http_client.py
async def call_auth_service(user_id: str):
    headers = {
        "X-Correlation-ID": get_correlation_id(),  # Propagate
        "Authorization": f"Bearer {get_service_token()}"
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api-auth.run.app/validate",
            json={"user_id": user_id},
            headers=headers
        )
        return response.json()
```

### Log Levels

| Level        | Uso                                                     | Staging       | Producción    |
| ------------ | ------------------------------------------------------- | ------------- | ------------- |
| **DEBUG**    | Debugging detallado, variables, flujo                   | ✅ Habilitado | ❌ Disabled   |
| **INFO**     | Eventos normales (request recibido, operación exitosa)  | ✅ Habilitado | ✅ Habilitado |
| **WARNING**  | Situaciones anómalas pero manejadas (retry, cache miss) | ✅ Habilitado | ✅ Habilitado |
| **ERROR**    | Errores manejados que requieren atención                | ✅ Habilitado | ✅ Habilitado |
| **CRITICAL** | Errores críticos, servicio comprometido                 | ✅ Habilitado | ✅ Habilitado |

### Retención de Logs

| Environment     | Retención                                  | Costo Estimado |
| --------------- | ------------------------------------------ | -------------- |
| **Local (dev)** | No cloud logs                              | $0             |
| **Staging**     | 7 días                                     | $5-10/mes      |
| **Producción**  | 30 días (general), 7 años (audit logs PHI) | $30-50/mes     |

### Log Queries Útiles

**1. Todos los errores en las últimas 24h**:

```
resource.type="cloud_run_revision"
severity>=ERROR
timestamp>="2025-10-17T00:00:00Z"
```

**2. Request flow por correlation ID**:

```
jsonPayload.correlation_id="550e8400-e29b-41d4-a716-446655440000"
```

**3. Slow requests (>1s latency)**:

```
resource.type="cloud_run_revision"
jsonPayload.latency_ms>1000
```

**4. Accesos a datos de salud (audit log)**:

```
jsonPayload.resource_type="clinical_notes"
jsonPayload.action="READ"
```

---

## 📈 2. Metrics y Monitoring

### Tipos de Métricas

**Infrastructure Metrics** (Cloud Run automáticas):

- CPU utilization (%)
- Memory utilization (MB)
- Request count
- Request latency (ms)
- Instance count
- Billable instance time

**Application Metrics** (custom):

- Business metrics: appointments_created_total, users_registered_total
- Performance: api_request_duration_seconds, db_query_duration_seconds
- Errors: api_errors_total, circuit_breaker_open_total

### Custom Metrics Implementation

```python
# infrastructure/metrics.py
from google.cloud import monitoring_v3
from google.api import metric_pb2 as ga_metric
from google.api import label_pb2 as ga_label
import time

class MetricsClient:
    def __init__(self, project_id: str):
        self.client = monitoring_v3.MetricServiceClient()
        self.project_name = f"projects/{project_id}"

    def record_counter(
        self,
        metric_type: str,
        value: int = 1,
        labels: dict = None
    ):
        """Increment a counter metric"""
        series = monitoring_v3.TimeSeries()
        series.metric.type = f"custom.googleapis.com/{metric_type}"

        if labels:
            for key, val in labels.items():
                series.metric.labels[key] = str(val)

        now = time.time()
        seconds = int(now)
        nanos = int((now - seconds) * 10 ** 9)
        interval = monitoring_v3.TimeInterval(
            {"end_time": {"seconds": seconds, "nanos": nanos}}
        )

        point = monitoring_v3.Point({
            "interval": interval,
            "value": {"int64_value": value}
        })
        series.points = [point]

        self.client.create_time_series(
            name=self.project_name,
            time_series=[series]
        )

# Usage
metrics = MetricsClient(project_id="adyela-staging")

# Record appointment creation
metrics.record_counter(
    "appointments/created",
    value=1,
    labels={
        "tenant_id": tenant_id,
        "professional_id": professional_id,
        "specialty": specialty
    }
)

# Record API latency (histogram)
metrics.record_histogram(
    "api/request_duration_seconds",
    value=0.145,
    labels={
        "service": "api-appointments",
        "method": "POST",
        "endpoint": "/appointments",
        "status_code": "200"
    }
)
```

### SLIs (Service Level Indicators)

**Availability SLI**:

- **Definition**: % of successful requests (status code < 500)
- **Measurement**: `(successful_requests / total_requests) * 100`
- **Target**: >99.9% (staging), >99.95% (production)

**Latency SLI**:

- **Definition**: % of requests completed within latency threshold
- **Measurement**: `(requests_under_200ms / total_requests) * 100`
- **Target**: >95% requests <200ms (p95)

**Error Rate SLI**:

- **Definition**: % of requests that resulted in errors
- **Measurement**: `(error_requests / total_requests) * 100`
- **Target**: <1% error rate

### SLOs (Service Level Objectives)

| Service           | Availability SLO | Latency SLO (p95) | Error Rate SLO |
| ----------------- | ---------------- | ----------------- | -------------- |
| api-auth          | 99.95%           | <150ms            | <0.5%          |
| api-appointments  | 99.9%            | <200ms            | <1%            |
| api-payments      | 99.95%           | <500ms            | <0.5%          |
| api-notifications | 99.5%            | <1000ms           | <2%            |
| api-admin         | 99.5%            | <300ms            | <1%            |
| api-analytics     | 99%              | <2000ms           | <3%            |

### Dashboards

**Dashboard 1: Service Overview** (por microservicio)

Widgets:

- Request rate (requests/sec)
- Error rate (%)
- Latency percentiles (p50, p90, p95, p99)
- Instance count
- CPU/Memory utilization

**Dashboard 2: Business Metrics**

Widgets:

- Appointments created/day
- Users registered/day
- Active users (DAU, MAU)
- Revenue (MRR, ARR) - post-monetization
- Churn rate

**Dashboard 3: SLO Compliance**

Widgets:

- Availability vs SLO (gauge)
- Latency vs SLO (time series)
- Error budget remaining
- SLO violations (count, timeline)

**Dashboard 4: Multi-Tenant Metrics**

Widgets:

- API calls per tenant
- Storage used per tenant
- Cost attribution per tenant
- Top tenants by usage

**Dashboard 5: Error Analysis**

Widgets:

- Top errors by count
- Errors by service
- Error trends (time series)
- Recent error logs (table)

**Terraform Dashboard Creation**:

```hcl
# infra/modules/monitoring/dashboards.tf
resource "google_monitoring_dashboard" "service_overview" {
  dashboard_json = jsonencode({
    displayName = "Adyela - Service Overview"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Request Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" metric.type=\"run.googleapis.com/request_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}
```

---

## 🔍 3. Distributed Tracing

### Cloud Trace Integration

**Qué rastreamos**:

- HTTP requests a través de todos los microservicios
- Database queries (Firestore, Cloud SQL)
- Pub/Sub publish/subscribe
- External API calls (Stripe, Twilio, etc.)

**Instrumentación automática**:

```python
# main.py (FastAPI)
from opentelemetry import trace
from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Setup tracing
trace.set_tracer_provider(TracerProvider())
cloud_trace_exporter = CloudTraceSpanExporter()
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(cloud_trace_exporter)
)

# Instrument FastAPI
app = FastAPI()
FastAPIInstrumentor.instrument_app(app)

# All HTTP requests are now automatically traced
```

**Instrumentación manual** (para operaciones críticas):

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

async def create_appointment(request: CreateAppointmentRequest):
    with tracer.start_as_current_span("create_appointment") as span:
        # Add attributes to span
        span.set_attribute("tenant_id", request.tenant_id)
        span.set_attribute("professional_id", request.professional_id)

        # Validate permissions (auto-traced HTTP call)
        with tracer.start_as_current_span("validate_permissions"):
            can_create = await auth_client.validate_permissions(...)
            span.set_attribute("permission_granted", can_create)

        if not can_create:
            span.set_status(trace.Status(trace.StatusCode.ERROR, "Permission denied"))
            raise PermissionDeniedError()

        # Save to Firestore (auto-traced DB operation)
        with tracer.start_as_current_span("save_to_firestore"):
            appointment = await appointment_repo.save(request)
            span.set_attribute("appointment_id", appointment.id)

        # Publish event (auto-traced Pub/Sub)
        with tracer.start_as_current_span("publish_event"):
            await event_bus.publish("appointment.created", appointment.dict())

        return appointment
```

### Trace Analysis

**Típico trace end-to-end** (crear cita con pago):

```
Root Span: POST /api/v2/appointments (total: 850ms)
├─ Span: validate_permissions (120ms)
│  └─ HTTP: POST api-auth/validate (115ms)
├─ Span: create_appointment_record (45ms)
│  └─ Firestore: Create /tenants/{id}/appointments/{id} (40ms)
├─ Span: create_payment_intent (650ms)
│  ├─ HTTP: POST api-payments/intents (600ms)
│  │  └─ HTTP: POST stripe.com/v1/payment_intents (550ms)  ← Bottleneck!
│  └─ Firestore: Update appointment payment_intent_id (30ms)
└─ Span: publish_event (35ms)
   └─ PubSub: Publish appointment.created (32ms)
```

**Insights from trace**:

- Total latency: 850ms (p95 target: <200ms) ⚠️ SLO violation
- Bottleneck: Stripe API call (550ms) → Can we optimize?
  - Solution: Create payment intent async, don't block user

---

## 🚨 4. Alerting

### Alert Policies

**Critical Alerts** (Page on-call immediately):

1. **Service Down**
   - Condition: Uptime check failed for >1 min
   - Channels: PagerDuty, SMS, Slack #incidents
   - Severity: P0

2. **Error Rate Spike**
   - Condition: Error rate >5% for >5 min
   - Channels: PagerDuty, Slack #incidents
   - Severity: P0

3. **Latency Degradation**
   - Condition: p95 latency >500ms for >10 min
   - Channels: PagerDuty, Slack #incidents
   - Severity: P1

4. **Budget Exceeded**
   - Condition: Daily spend >120% of expected
   - Channels: Email (finance), Slack #finops
   - Severity: P1

**Warning Alerts** (Email, Slack only):

5. **Approaching SLO Breach**
   - Condition: Error budget <20% remaining
   - Channels: Email (eng team), Slack #engineering
   - Severity: P2

6. **Slow Queries**
   - Condition: Database query >1s
   - Channels: Slack #performance
   - Severity: P3

7. **Disk Space Low**
   - Condition: Cloud SQL disk >80% used
   - Channels: Slack #infrastructure
   - Severity: P2

### Terraform Alert Policy

```hcl
# infra/modules/monitoring/alerts.tf
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "High Error Rate - api-appointments"
  combiner     = "OR"

  conditions {
    display_name = "Error rate > 5%"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"api-appointments\" AND metric.type=\"run.googleapis.com/request_count\""
      duration        = "300s"  # 5 minutes
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05  # 5%

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.pagerduty.id,
    google_monitoring_notification_channel.slack_incidents.id
  ]

  alert_strategy {
    auto_close = "1800s"  # 30 min
  }
}
```

### On-Call Rotation

**Tier 1 (Primary)**:

- Backend Engineer (rotation weekly)
- Responsible for: Initial triage, basic fixes
- Escalates to Tier 2 if >30 min without resolution

**Tier 2 (Secondary)**:

- Senior Backend Engineer + DevOps Engineer
- Responsible for: Complex issues, infrastructure problems
- Escalates to Tier 3 if >1 hour without resolution

**Tier 3 (Escalation)**:

- Tech Lead + CTO
- Responsible for: Critical decisions, major outages

**On-Call Schedule**:

- Week 1: Engineer A (Tier 1), Engineer B (Tier 2)
- Week 2: Engineer C (Tier 1), Engineer D (Tier 2)
- Rotation continues...

**Tools**:

- PagerDuty for on-call management
- Slack for communication (#incidents channel)
- Runbooks in Confluence/Notion
- Post-mortem template for all P0/P1 incidents

---

## 📊 5. Error Reporting

**Cloud Error Reporting**: Automatic aggregation de errores

**Features**:

- Agrupa errores similares (by stack trace)
- Muestra frecuencia, first seen, last seen
- Links directos a logs y traces

**Custom Error Tracking**:

```python
from google.cloud import error_reporting

error_client = error_reporting.Client()

try:
    result = await process_payment(payment_data)
except StripeError as e:
    # Report to Error Reporting
    error_client.report_exception(
        http_context={
            "method": "POST",
            "url": request.url.path,
            "user_agent": request.headers.get("user-agent"),
            "remote_ip": request.client.host
        }
    )
    # Also log structured
    logger.error(
        "payment_processing_failed",
        error=str(e),
        error_type=type(e).__name__,
        payment_id=payment_data.get("id"),
        correlation_id=get_correlation_id()
    )
    raise
```

---

## 🔧 6. Observability Best Practices

### DO ✅

1. **Always use correlation IDs** - Propagate across all services
2. **Structured logging** - JSON format, parseable
3. **Include context** - user_id, tenant_id, request_id in all logs
4. **Instrument critical paths** - DB queries, external APIs, business logic
5. **Set meaningful attributes** - In traces and logs
6. **Alert on SLOs** - Not just symptoms
7. **Document runbooks** - For common alerts
8. **Post-mortems** - For all P0/P1 incidents

### DON'T ❌

1. **Don't log sensitive data** - No passwords, tokens, PHI in plain text
2. **Don't over-alert** - Alert fatigue leads to ignored alerts
3. **Don't trace everything** - Sample 10-20% in production (cost optimization)
4. **Don't ignore warnings** - Warnings often become errors
5. **Don't alert without runbook** - Engineers should know what to do

---

## 📚 Runbooks

### Runbook Template

```markdown
# Runbook: High Error Rate on api-appointments

## Alert Details

- **Alert Name**: High Error Rate - api-appointments
- **Severity**: P0
- **SLO Impact**: Availability SLO (99.9%)

## Symptoms

- Error rate >5% for >5 minutes
- Users unable to create appointments
- Possible 500 errors on /api/v2/appointments

## Diagnosis Steps

1. **Check Error Reporting**:
   - Go to Cloud Console > Error Reporting
   - Filter by service: api-appointments
   - Identify top error types

2. **Check Recent Deployments**:
   - `gcloud run revisions list --service=api-appointments`
   - Was there a deployment in last 30 min?

3. **Check Dependencies**:
   - Is api-auth responding? `curl https://api-auth.run.app/health`
   - Is Firestore healthy? Check Cloud Console > Firestore
   - Is Pub/Sub healthy? Check Cloud Console > Pub/Sub

4. **Check Logs**:
```

gcloud logging read "resource.type=cloud_run_revision AND
resource.labels.service_name=api-appointments AND severity>=ERROR" --limit=50

````

## Remediation

### If caused by bad deployment:
```bash
# Rollback to previous revision
gcloud run services update-traffic api-appointments \
--to-revisions=<previous-revision>=100

# Verify rollback
curl https://api-appointments.run.app/health
````

### If caused by dependency (api-auth down):

```bash
# Check api-auth status
gcloud run services describe api-auth

# If down, check why and restart if needed
# Meanwhile, enable circuit breaker fallback in api-appointments
# (this should be automatic, verify it's working)
```

### If caused by Firestore issue:

```bash
# Check Firestore status page: https://status.cloud.google.com/
# If outage, communicate to users
# If quota issue, increase quota in Cloud Console
```

## Communication

- Post in #incidents Slack channel: "@here P0 alert: High error rate on
  api-appointments. Investigating..."
- Update status page (if public-facing)
- Once resolved: Post RCA (Root Cause Analysis) in #incidents

## Post-Incident

- Write post-mortem (template in Confluence)
- Identify action items to prevent recurrence
- Update runbook if new insights

```

---

## 📊 Checklist de Implementación

### Fase 0 (Mes 1-2) - Setup

- [ ] **Cloud Logging** configurado (structured JSON)
- [ ] **Correlation IDs** en todos los servicios
- [ ] **Cloud Trace** habilitado (auto-instrumentation)
- [ ] **Dashboards básicos** (1 por servicio)
- [ ] **Alertas críticas** (service down, high error rate)

### Fase 1 (Mes 3-6) - Instrumentación

- [ ] **Custom metrics** (business metrics)
- [ ] **SLI/SLO** definidos por servicio
- [ ] **Error Reporting** integrado
- [ ] **Runbooks** para alertas top 5
- [ ] **On-call rotation** establecida

### Fase 2 (Mes 7-9) - Optimización

- [ ] **Multi-tenant dashboards** (cost attribution)
- [ ] **Trace sampling** optimizado (10-20%)
- [ ] **Log retention** política (7d staging, 30d prod, 7y audit)
- [ ] **SLO-based alerting** (error budget)
- [ ] **Automated remediation** (auto-scaling, circuit breakers)

### Fase 3 (Mes 10-12) - Madurez

- [ ] **Chaos engineering** (fault injection tests)
- [ ] **Synthetic monitoring** (proactive health checks)
- [ ] **APM** (Application Performance Monitoring) completo
- [ ] **Post-mortem culture** (blameless, actionable)
- [ ] **Observability-driven development** (developers check metrics)

---

**Documento**: `docs/infrastructure/observability-distributed-systems.md`
**Version**: 1.0
**Última actualización**: 2025-10-18
**Owner**: DevOps + SRE Team
**Review**: Trimestral
```
