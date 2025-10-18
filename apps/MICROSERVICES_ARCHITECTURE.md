# Adyela Microservices Architecture

This document provides an overview of the 6 microservices that compose the Adyela platform.

## 🏗️ Microservices Overview

| Service | Language | Port | Responsibilities | Dependencies |
|---------|----------|------|------------------|--------------|
| **api-auth** | Python/FastAPI | 8000 | Authentication, Authorization, RBAC | Firestore, Firebase Auth |
| **api-appointments** | Python/FastAPI | 8000 | Appointment CRUD, Scheduling, Calendar | Firestore, Pub/Sub, api-auth |
| **api-payments** | Node.js/Express | 3000 | Payment processing, Stripe integration | Stripe, Pub/Sub, api-auth |
| **api-notifications** | Node.js/Express | 3000 | Email, SMS, Push notifications | SendGrid, Twilio, Pub/Sub |
| **api-admin** | Python/FastAPI | 8000 | Admin operations, Professional approval | Firestore, api-auth |
| **api-analytics** | Python | 8000 | Analytics aggregation, reporting | BigQuery, Pub/Sub |

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Load Balancer (Cloud Run)                    │
└──────────────────────┬──────────────────────────────────────────┘
                       │
       ┌───────────────┼───────────────┐
       │               │               │
┌──────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐
│   Flutter   │ │   React    │ │   Flutter  │
│   Patient   │ │   Admin    │ │    Pro     │
│   Mobile    │ │    Web     │ │   Mobile   │
└──────┬──────┘ └─────┬──────┘ └─────┬──────┘
       │               │               │
       └───────────────┼───────────────┘
                       │
       ┌───────────────┴───────────────┐
       │                               │
┌──────▼──────┐              ┌────────▼────────┐
│  api-auth   │◄─────────────┤ api-appointments│
│  (Python)   │              │    (Python)     │
└──────┬──────┘              └────────┬────────┘
       │                               │
       │                   ┌───────────▼─────┐
       │                   │  Pub/Sub Topics │
       │                   └───────┬─────────┘
       │                           │
   ┌───▼────────┬──────────────────┼──────────────┐
   │            │                  │              │
┌──▼────────┐ ┌─▼──────────┐ ┌───▼─────────┐ ┌──▼──────────┐
│api-payments│ │api-notific.│ │  api-admin  │ │api-analytics│
│  (Node.js) │ │  (Node.js) │ │  (Python)   │ │  (Python)   │
└────────────┘ └────────────┘ └─────────────┘ └─────┬───────┘
                                                     │
                                              ┌──────▼──────┐
                                              │  BigQuery   │
                                              └─────────────┘
```

## 🔄 Communication Patterns

### Synchronous (REST)

1. **Client → api-auth**: User authentication
2. **Client → api-appointments**: CRUD operations (with auth validation)
3. **api-appointments → api-auth**: Token validation (internal endpoint)
4. **Client → api-payments**: Payment operations
5. **Client → api-admin**: Admin operations

### Asynchronous (Pub/Sub)

1. **api-appointments → appointments-events**:
   - Event: `AppointmentCreated`, `AppointmentCancelled`, `AppointmentCompleted`
   - Subscribers: api-notifications, api-analytics

2. **api-payments → payments-events**:
   - Event: `PaymentSucceeded`, `PaymentFailed`, `RefundProcessed`
   - Subscribers: api-analytics, api-appointments

3. **api-notifications → notifications-events**:
   - Event: `EmailSent`, `SMSSent`, `PushSent`
   - Subscribers: api-analytics

## 🗂️ Service Details

### 1. API Auth

**Purpose**: Centralized authentication and authorization

**Key Features**:
- Multi-provider OAuth (Google, Facebook, Apple)
- Email/password authentication
- JWT token generation and validation
- RBAC (Role-Based Access Control)
- Multi-tenancy enforcement
- Service-to-service authentication

**Tech Stack**: Python 3.12, FastAPI, Firebase Auth, Firestore

**Endpoints**:
- `POST /auth/login` - Login
- `POST /auth/register` - Register
- `POST /auth/validate-token` - Validate JWT (internal)

**See**: `apps/api-auth/README.md`

---

### 2. API Appointments

**Purpose**: Appointment management and scheduling

**Key Features**:
- CRUD operations for appointments
- Availability management
- Conflict detection
- Calendar integration
- Appointment reminders (via Pub/Sub)
- Multi-tenant data isolation

**Tech Stack**: Python 3.12, FastAPI, Firestore, Pub/Sub

**Endpoints**:
- `GET /appointments` - List appointments
- `POST /appointments` - Create appointment
- `PUT /appointments/{id}` - Update appointment
- `DELETE /appointments/{id}` - Cancel appointment

**Events Published**:
- `AppointmentCreated`
- `AppointmentUpdated`
- `AppointmentCancelled`
- `AppointmentCompleted`

**Dependencies**: api-auth (token validation)

---

### 3. API Payments

**Purpose**: Payment processing with Stripe

**Key Features**:
- Stripe payment intent creation
- Subscription management
- Webhook handling
- Refund processing
- Payment method management
- Multi-currency support

**Tech Stack**: Node.js 20, Express, Stripe SDK, Pub/Sub

**Endpoints**:
- `POST /payments/intent` - Create payment intent
- `POST /payments/webhook` - Stripe webhook handler
- `POST /payments/refund` - Process refund

**Events Published**:
- `PaymentSucceeded`
- `PaymentFailed`
- `SubscriptionCreated`
- `RefundProcessed`

**Dependencies**: api-auth (token validation)

---

### 4. API Notifications

**Purpose**: Multi-channel notification delivery

**Key Features**:
- Email notifications (SendGrid)
- SMS notifications (Twilio)
- Push notifications (Firebase Cloud Messaging)
- Template management
- Delivery tracking
- Rate limiting

**Tech Stack**: Node.js 20, Express, SendGrid, Twilio, FCM

**Endpoints**:
- `POST /webhooks/pubsub` - Pub/Sub push endpoint
- `POST /notifications/send` - Send notification (internal)

**Events Subscribed**:
- `AppointmentCreated` → Send confirmation email
- `AppointmentReminder` → Send SMS reminder
- `PaymentSucceeded` → Send receipt email

**Notification Types**:
- Appointment confirmation
- Appointment reminder (24h before)
- Appointment cancellation
- Payment receipt
- Professional approval

---

### 5. API Admin

**Purpose**: Administrative operations

**Key Features**:
- Professional application review
- Professional approval/rejection
- User management
- System configuration
- Audit logging
- Professional verification

**Tech Stack**: Python 3.12, FastAPI, Firestore

**Endpoints**:
- `GET /admin/professionals/pending` - List pending approvals
- `POST /admin/professionals/{id}/approve` - Approve professional
- `POST /admin/professionals/{id}/reject` - Reject professional
- `GET /admin/users` - List users
- `GET /admin/audit-log` - View audit log

**Dependencies**: api-auth (requires admin role)

---

### 6. API Analytics

**Purpose**: Data aggregation and reporting

**Key Features**:
- Event aggregation from Pub/Sub
- Metrics calculation
- Report generation
- BigQuery data warehouse
- Dashboard data API
- Cost attribution

**Tech Stack**: Python 3.12, BigQuery, Pub/Sub

**Endpoints**:
- `GET /analytics/dashboard` - Dashboard metrics
- `GET /analytics/appointments/stats` - Appointment statistics
- `GET /analytics/revenue` - Revenue reports
- `POST /webhooks/pubsub` - Pub/Sub push endpoint

**Events Subscribed**:
- All events from all services (for analytics)

**Data Stored**:
- Appointment metrics
- Payment metrics
- User behavior
- System performance

## 🔐 Security

### Authentication Flow

```
1. User → api-auth (login with credentials)
2. api-auth → Firebase Auth (validate)
3. Firebase Auth → api-auth (user data)
4. api-auth → User (JWT token)
5. User → api-appointments (request with JWT in header)
6. api-appointments → api-auth (validate token - internal endpoint)
7. api-auth → api-appointments (user info + permissions)
8. api-appointments → User (response)
```

### Multi-Tenancy

Each professional is a tenant. Firestore structure:

```
/tenants/{tenantId}/
  /appointments/{appointmentId}
  /patients/{patientId}
  /settings/{settingId}
```

Firestore rules enforce tenant isolation at the database level.

## 📊 Observability

### Logging

All services use **structured logging** (JSON format) with:
- Correlation IDs for request tracing
- Tenant ID for cost attribution
- Service name and version
- Log level (DEBUG, INFO, WARNING, ERROR)

### Tracing

**Cloud Trace** with **OpenTelemetry**:
- Trace ID propagates across services
- Distributed tracing for multi-service requests
- Performance bottleneck identification

### Metrics

**Cloud Monitoring** + **Prometheus**:
- Request rate, latency, error rate
- Resource utilization (CPU, memory)
- Business metrics (appointments created, payments processed)
- Cost per tenant

### Alerts

- High error rate (>5% for 5 minutes)
- High latency (p99 >500ms)
- Budget exceeded (50%, 75%, 90%, 100%)
- Failed deployments

## 💰 Cost Optimization

### Scale-to-Zero

All services configured with `min_instances = 0` in staging:
- **Idle cost**: $0/month
- **Active development**: $100-150/month
- **Budget alert**: $150/month threshold

### Resource Allocation

| Service | CPU | Memory | Cost Impact |
|---------|-----|--------|-------------|
| api-auth | 1 vCPU | 512Mi | Medium |
| api-appointments | 1 vCPU | 512Mi | Medium |
| api-payments | 1 vCPU | 512Mi | Medium |
| api-notifications | 0.5 vCPU | 256Mi | Low |
| api-admin | 1 vCPU | 512Mi | Low (infrequent) |
| api-analytics | 1 vCPU | 1Gi | Medium |

## 🚀 Deployment

### CI/CD Pipeline

1. **Push to branch** → Trigger GitHub Actions
2. **Lint & Type Check** → Fail fast on code quality issues
3. **Unit Tests** → 80% coverage required
4. **Security Scan** → Bandit, Safety, Trivy
5. **Build Docker Image** → Multi-stage builds
6. **Push to Artifact Registry** → Tagged with commit SHA
7. **Deploy to Cloud Run** → Terraform or gcloud CLI
8. **Health Check** → Ensure service is responding
9. **Notify** → Slack notification

### Deployment Workflow

```bash
# Deploy all services to staging
./.github/workflows/cd-deploy-staging.yml

# Deploy specific service
gh workflow run cd-deploy-staging.yml -f services=api-auth
```

## 📚 Related Documentation

- [Microservices Migration Strategy](../docs/architecture/microservices-migration-strategy.md)
- [Service Communication Patterns](../docs/architecture/service-communication-patterns.md)
- [Multi-Tenancy Hybrid Model](../docs/architecture/multi-tenancy-hybrid-model.md)
- [Observability Distributed Systems](../docs/infrastructure/observability-distributed-systems.md)
- [Testing Strategy Microservices](../docs/quality/testing-strategy-microservices.md)
- [FinOps Cost Analysis](../docs/finops/cost-analysis-and-budgets.md)

## 🛠️ Development

### Setup Local Environment

```bash
# Clone repository
git clone https://github.com/adyela/adyela.git
cd adyela

# Install dependencies for all services
make install-all

# Start all services with Docker Compose
docker-compose up
```

### Testing

```bash
# Run all tests
make test-all

# Run specific service tests
cd apps/api-auth && poetry run pytest

# Run E2E tests
make test-e2e
```

### Code Quality

```bash
# Lint all services
make lint-all

# Format all services
make format-all

# Type check all services
make type-check-all
```

---

**Version**: 1.0.0
**Last Updated**: 2025-10-18
**Status**: 🚧 In Development (scaffolding phase)
