# API Auth Microservice

Authentication and authorization microservice for Adyela platform.

## Responsibilities

- User authentication (Google, Facebook, Apple, email/password)
- JWT token generation and validation
- Role-Based Access Control (RBAC)
- Multi-tenancy enforcement
- Service-to-service authentication
- Password reset and email verification

## Tech Stack

- **Language**: Python 3.12
- **Framework**: FastAPI 0.115+
- **Database**: Firestore (multi-tenant structure)
- **Auth Provider**: Firebase Authentication
- **Container**: Docker with Gunicorn + Uvicorn workers

## Architecture

Following Hexagonal Architecture (Clean Architecture):

```
api-auth/
├── adyela_api_auth/
│   ├── domain/              # Business entities & logic
│   │   ├── entities/        # User, Role, Tenant
│   │   ├── value_objects/   # Email, Password, Token
│   │   └── interfaces/      # Repository interfaces
│   ├── application/         # Use cases
│   │   ├── use_cases/       # Login, Register, ValidateToken
│   │   └── ports/           # Input/Output ports
│   ├── infrastructure/      # External dependencies
│   │   ├── repositories/    # Firestore implementations
│   │   ├── auth_providers/  # Firebase Auth
│   │   └── security/        # JWT, hashing
│   ├── presentation/        # HTTP layer
│   │   ├── api/             # FastAPI routes
│   │   ├── middleware/      # CORS, auth middleware
│   │   └── schemas/         # Pydantic models
│   └── config/              # Settings
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── Dockerfile
├── pyproject.toml
└── README.md
```

## API Endpoints

### Public Endpoints

- `POST /auth/register` - Register new user
- `POST /auth/login` - Login with credentials
- `POST /auth/login/google` - Login with Google OAuth
- `POST /auth/login/facebook` - Login with Facebook OAuth
- `POST /auth/login/apple` - Login with Apple OAuth
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password with token

### Protected Endpoints

- `GET /auth/me` - Get current user info
- `POST /auth/logout` - Logout (invalidate token)
- `POST /auth/refresh` - Refresh access token
- `GET /auth/verify-email/{token}` - Verify email address

### Internal Endpoints (Service-to-Service)

- `POST /internal/auth/validate-token` - Validate JWT token
- `GET /internal/auth/user/{user_id}` - Get user by ID
- `POST /internal/auth/check-permission` - Check user permission

### Health & Monitoring

- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

## Environment Variables

```bash
# Environment
ENVIRONMENT=staging
PROJECT_ID=adyela-staging
REGION=us-central1

# Firestore
FIRESTORE_DATABASE=(default)

# Firebase Auth
FIREBASE_API_KEY=<from_secret_manager>
FIREBASE_PROJECT_ID=adyela-staging

# JWT
JWT_SECRET=<from_secret_manager>
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
CORS_ORIGINS=https://staging.adyela.care,https://admin.staging.adyela.care

# Logging
LOG_LEVEL=INFO
LOG_FORMAT=json
```

## Local Development

```bash
# Install dependencies
poetry install

# Run locally
poetry run uvicorn adyela_api_auth.main:app --reload --port 8000

# Run tests
poetry run pytest

# Run with Docker
docker build -t api-auth .
docker run -p 8000:8000 api-auth
```

## Testing

```bash
# Unit tests
poetry run pytest tests/unit -v

# Integration tests (requires Firestore emulator)
poetry run pytest tests/integration -v

# Coverage
poetry run pytest --cov=adyela_api_auth --cov-report=html

# Load testing
k6 run tests/load/auth-load-test.js
```

## Deployment

Deployed via GitHub Actions to Cloud Run:

- **Staging**: `api-auth-staging.staging.adyela.care`
- **Production**: `api-auth.adyela.care`

See `.github/workflows/ci-api-auth.yml` for CI/CD pipeline.

## Performance

- **Target**: <100ms p50, <200ms p99 for token validation
- **Scaling**: 0-10 instances (scale-to-zero enabled in staging)
- **Concurrency**: 80 requests per instance

## Security

- Secrets stored in GCP Secret Manager
- JWT tokens signed with HS256
- Password hashing with bcrypt
- Rate limiting on login endpoints
- CORS whitelist enforcement
- Input validation with Pydantic

## Monitoring

- **Logs**: Cloud Logging (structured JSON)
- **Traces**: Cloud Trace with correlation IDs
- **Metrics**: Cloud Monitoring + Prometheus
- **Alerts**: Failed login attempts, high error rates

## Related Documentation

- [Service Communication Patterns](../../docs/architecture/service-communication-patterns.md)
- [Multi-Tenancy Model](../../docs/architecture/multi-tenancy-hybrid-model.md)
- [Observability Strategy](../../docs/infrastructure/observability-distributed-systems.md)
