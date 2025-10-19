# Adyela API Appointments

Microservice for appointment scheduling and management.

## 🎯 Purpose

This microservice handles all appointment-related operations including:

- CRUD operations for appointments
- Availability checking
- Conflict detection
- Appointment status management
- Event publishing for notifications

## 🏗️ Architecture

### Hexagonal Architecture (Ports & Adapters)

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (FastAPI endpoints, HTTP handlers)     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│        Application Layer                │
│    (Use Cases, Business Logic)          │
│  - CreateAppointmentUseCase             │
│  - ListAppointmentsUseCase              │
│  - CancelAppointmentUseCase             │
│  - CheckAvailabilityUseCase             │
└──────────────┬──────────────────────────┘
               │ uses ports (interfaces)
┌──────────────▼──────────────────────────┐
│          Domain Layer                   │
│    (Entities, Value Objects)            │
│  - Appointment                          │
│  - DateTimeRange                        │
│  - TenantId                             │
└─────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Infrastructure Layer               │
│   (Implementations of ports)            │
│  - FirestoreAppointmentRepository       │
│  - PubSubEventPublisher                 │
└─────────────────────────────────────────┘
```

## 📋 Features

### Core Operations

- ✅ Create appointment with conflict detection
- ✅ Get appointment by ID
- ✅ List appointments (filtered by patient/practitioner)
- ✅ Confirm appointment
- ✅ Cancel appointment
- ✅ Check practitioner availability

### Business Rules

- ✅ No appointments in the past
- ✅ Conflict detection for practitioners
- ✅ Status transition validation
- ✅ Time range validation

### Events Published

- `AppointmentCreated`
- `AppointmentConfirmed`
- `AppointmentCancelled`

## 🚀 Quick Start

### Prerequisites

- Python 3.12+
- Poetry
- Google Cloud Project with Firestore enabled
- Pub/Sub topic created

### Installation

```bash
cd apps/api-appointments

# Install dependencies
poetry install

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
```

### Configuration

Required environment variables in `.env`:

```env
# GCP
GCP_PROJECT_ID=your-project-id
FIRESTORE_DATABASE=(default)
PUBSUB_APPOINTMENTS_TOPIC=appointments-events

# Auth Service
AUTH_SERVICE_URL=http://localhost:8001
AUTH_VALIDATE_TOKEN_ENDPOINT=/api/v1/auth/validate-token

# Application
DEBUG=true
ENVIRONMENT=development
```

### Running Locally

```bash
# Development mode (with hot reload)
poetry run python -m adyela_api_appointments.main

# Or with uvicorn directly
poetry run uvicorn adyela_api_appointments.main:app --reload --port 8002
```

The API will be available at http://localhost:8002

### API Documentation

Once running, visit:

- **Swagger UI**: http://localhost:8002/docs
- **ReDoc**: http://localhost:8002/redoc
- **Health Check**: http://localhost:8002/health

## 📊 API Endpoints

### Appointments

| Method  | Endpoint                                  | Description            |
| ------- | ----------------------------------------- | ---------------------- |
| `POST`  | `/api/v1/appointments`                    | Create new appointment |
| `GET`   | `/api/v1/appointments`                    | List appointments      |
| `GET`   | `/api/v1/appointments/{id}`               | Get appointment by ID  |
| `PATCH` | `/api/v1/appointments/{id}/confirm`       | Confirm appointment    |
| `PATCH` | `/api/v1/appointments/{id}/cancel`        | Cancel appointment     |
| `POST`  | `/api/v1/appointments/check-availability` | Check availability     |

## 🧪 Testing

### Unit Tests

```bash
# Run all tests
poetry run pytest

# Run with coverage
poetry run pytest --cov=adyela_api_appointments --cov-report=html

# Run specific test file
poetry run pytest tests/unit/test_create_appointment.py -v
```

### Integration Tests

```bash
# Run integration tests (requires Firestore emulator)
poetry run pytest tests/integration/ -v
```

## 🏗️ Project Structure

```
apps/api-appointments/
├── adyela_api_appointments/
│   ├── domain/                 # Business entities & logic
│   │   ├── entities/
│   │   │   └── appointment.py
│   │   ├── value_objects/
│   │   │   ├── date_time_range.py
│   │   │   └── tenant_id.py
│   │   └── exceptions.py
│   ├── application/            # Use cases & ports
│   │   ├── use_cases/
│   │   │   └── appointments/
│   │   │       ├── create_appointment.py
│   │   │       ├── get_appointment.py
│   │   │       ├── list_appointments.py
│   │   │       ├── cancel_appointment.py
│   │   │       ├── confirm_appointment.py
│   │   │       └── check_availability.py
│   │   └── ports/
│   │       ├── repositories.py
│   │       └── services.py
│   ├── infrastructure/         # External service implementations
│   │   ├── repositories/
│   │   │   └── firestore_appointment_repository.py
│   │   └── pubsub/
│   │       └── event_publisher.py
│   ├── presentation/           # HTTP API
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── endpoints/
│   │   │       │   └── appointments.py
│   │   │       └── schemas.py
│   │   └── dependencies.py
│   ├── config/                 # Configuration
│   │   ├── settings.py
│   │   └── constants.py
│   └── main.py                 # FastAPI application
├── tests/
│   ├── unit/
│   └── integration/
├── pyproject.toml
└── README.md
```

## 🔧 Development

### Code Quality

```bash
# Format code
poetry run black adyela_api_appointments/

# Lint
poetry run ruff check adyela_api_appointments/

# Type check
poetry run mypy adyela_api_appointments/

# Security scan
poetry run bandit -r adyela_api_appointments/
```

### Adding New Features

1. **Domain Layer**: Define entities and business rules
2. **Application Layer**: Create use case
3. **Infrastructure Layer**: Implement adapters if needed
4. **Presentation Layer**: Add endpoint
5. **Tests**: Write unit and integration tests

## 📦 Dependencies

### Core

- **FastAPI** - Web framework
- **Uvicorn** - ASGI server
- **Pydantic** - Data validation
- **google-cloud-firestore** - Database
- **google-cloud-pubsub** - Event publishing

### Development

- **pytest** - Testing framework
- **ruff** - Linting
- **mypy** - Type checking
- **black** - Code formatting
- **bandit** - Security scanning

## 🔐 Security

### Authentication

All endpoints require valid JWT token from `api-auth` service. Token validation
is performed via middleware that:

1. Extracts JWT from Authorization header
2. Validates token with auth service
3. Extracts tenant_id and sets in request state

### Multi-Tenancy

Data is isolated by tenant:

```
/tenants/{tenantId}/appointments/{appointmentId}
```

Firestore security rules enforce tenant isolation.

## 🚢 Deployment

### Docker

```bash
# Build image
docker build -t adyela-api-appointments:latest .

# Run container
docker run -p 8002:8002 \
  -e GCP_PROJECT_ID=your-project \
  -e FIRESTORE_DATABASE=(default) \
  adyela-api-appointments:latest
```

### Cloud Run

```bash
# Deploy to Cloud Run
gcloud run deploy api-appointments \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars GCP_PROJECT_ID=your-project
```

## 📈 Monitoring

### Health Check

```bash
curl http://localhost:8002/health
```

### Metrics

- Request latency
- Error rates
- Appointment creation rate
- Conflict detection rate

### Logging

Structured JSON logs with:

- Request ID
- Tenant ID
- User ID
- Action performed

## 🤝 Related Services

- **api-auth** (port 8001) - Authentication & authorization
- **api-notifications** (port 3001) - Notifications (subscribes to events)
- **api-analytics** (port 8003) - Analytics (subscribes to events)

## 📝 License

UNLICENSED - Private

## ✨ Status

🟢 **Active Development** - Core features complete, ready for testing
