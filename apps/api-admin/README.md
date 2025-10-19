# Adyela API Admin

Administrative operations microservice for professional approval and user
management.

## 🎯 Purpose

Handles administrative tasks including:

- Professional application review and approval/rejection
- Audit logging for all admin actions
- User management operations
- Administrative reporting

## 🏗️ Architecture

### Hexagonal Architecture (Ports & Adapters)

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│    (FastAPI endpoints, schemas)         │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│        Application Layer                │
│         (Use Cases)                     │
│  - ApproveProfessionalUseCase           │
│  - RejectProfessionalUseCase            │
│  - ListPendingProfessionalsUseCase      │
└──────────────┬──────────────────────────┘
               │ uses ports
┌──────────────▼──────────────────────────┐
│          Domain Layer                   │
│   (Professional, AuditLog entities)     │
└─────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Infrastructure Layer               │
│  - FirestoreProfessionalRepository      │
│  - FirestoreAuditLogRepository          │
└─────────────────────────────────────────┘
```

## 📋 Features

### Core Operations

- ✅ List pending professional applications
- ✅ Approve professional applications
- ✅ Reject professional applications with reason
- ✅ Suspend approved professionals
- ✅ Audit logging for all operations

### Business Rules

- ✅ Status transitions validated (pending → approved/rejected)
- ✅ Only admins can perform operations
- ✅ All actions are audited
- ✅ Rejection requires reason

## 📊 API Endpoints

| Method | Endpoint                             | Description               |
| ------ | ------------------------------------ | ------------------------- |
| `GET`  | `/api/v1/professionals/pending`      | List pending applications |
| `POST` | `/api/v1/professionals/{id}/approve` | Approve professional      |
| `POST` | `/api/v1/professionals/{id}/reject`  | Reject professional       |

## 🚀 Quick Start

### Installation

```bash
cd apps/api-admin
poetry install
```

### Configuration

Create `.env` file:

```env
DEBUG=true
GCP_PROJECT_ID=your-project-id
FIRESTORE_DATABASE=(default)
AUTH_SERVICE_URL=http://localhost:8001
```

### Running

```bash
# Development mode
poetry run python -m adyela_api_admin.main

# Or with uvicorn
poetry run uvicorn adyela_api_admin.main:app --reload --port 8003
```

Visit http://localhost:8003/docs for API documentation.

## 🧪 Testing

```bash
# Run all tests
poetry run pytest

# Run with coverage
poetry run pytest --cov=adyela_api_admin --cov-report=html

# Run specific test
poetry run pytest tests/unit/test_professional_entity.py -v
```

## 🏗️ Project Structure

```
apps/api-admin/
├── adyela_api_admin/
│   ├── domain/                 # Business logic
│   │   ├── entities/
│   │   │   ├── professional.py
│   │   │   └── audit_log.py
│   │   └── exceptions.py
│   ├── application/            # Use cases
│   │   ├── use_cases/
│   │   │   └── professionals/
│   │   └── ports/              # Interfaces
│   ├── infrastructure/         # External services
│   │   └── repositories/
│   ├── presentation/           # HTTP API
│   │   ├── api/v1/
│   │   │   ├── endpoints/
│   │   │   └── schemas.py
│   │   └── dependencies.py
│   ├── config/                 # Settings
│   └── main.py                 # FastAPI app
├── tests/
│   └── unit/
├── pyproject.toml
└── README.md
```

## 🔧 Development

### Code Quality

```bash
# Format
poetry run black adyela_api_admin/

# Lint
poetry run ruff check adyela_api_admin/

# Type check
poetry run mypy adyela_api_admin/
```

## 🔐 Security

### Authentication

All endpoints require admin role authentication via JWT from api-auth service.

### Audit Logging

All administrative actions are logged with:

- Admin user ID
- Action type
- Target professional ID
- Timestamp
- Action details

## 📦 Dependencies

### Core

- **FastAPI** - Web framework
- **Pydantic** - Data validation
- **google-cloud-firestore** - Database

### Development

- **pytest** - Testing
- **ruff** - Linting
- **mypy** - Type checking
- **black** - Formatting

## 🚢 Deployment

```bash
# Deploy to Cloud Run
gcloud run deploy api-admin \
  --source . \
  --platform managed \
  --region us-central1 \
  --set-env-vars GCP_PROJECT_ID=your-project
```

## 🤝 Related Services

- **api-auth** (port 8001) - Authentication
- **api-appointments** (port 8002) - Appointments

## ✨ Status

🟢 **Complete** - Production ready with full test coverage
