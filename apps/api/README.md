# Adyela API

FastAPI backend for medical appointments with video calls using hexagonal
architecture.

## 🏗️ Architecture

This project follows **Hexagonal Architecture** (Ports and Adapters):

```
adyela_api/
├── domain/              # Business logic and entities
│   ├── entities/        # Domain entities
│   ├── value_objects/   # Value objects
│   └── exceptions.py    # Domain exceptions
├── application/         # Use cases and application logic
│   ├── use_cases/       # Business use cases
│   └── ports/           # Interfaces (repositories, services)
├── infrastructure/      # External adapters
│   ├── repositories/    # Database implementations
│   └── services/        # External service implementations
├── presentation/        # API layer
│   ├── api/v1/          # REST endpoints
│   ├── middleware/      # HTTP middleware
│   └── schemas/         # Pydantic schemas
└── config/              # Configuration
```

## 🚀 Quick Start

### Prerequisites

- Python 3.12+
- Poetry
- Docker (optional)

### Local Development

```bash
# Install dependencies
poetry install

# Copy environment variables
cp .env.example .env

# Edit .env with your configuration

# Run the application
poetry run uvicorn adyela_api.main:app --reload

# Or use the script
poetry run dev
```

The API will be available at `http://localhost:8000`

### With Docker

```bash
# Build image
docker build -t adyela-api .

# Run container
docker run -p 8000:8000 --env-file .env adyela-api
```

## 📋 Available Endpoints

- `GET /` - API information
- `GET /health` - Health check
- `GET /readiness` - Readiness probe
- `GET /docs` - Swagger UI (dev only)
- `GET /redoc` - ReDoc (dev only)
- `POST /api/v1/appointments` - Create appointment
- `GET /api/v1/appointments` - List appointments
- `GET /api/v1/appointments/{id}` - Get appointment
- `PATCH /api/v1/appointments/{id}/confirm` - Confirm appointment
- `PATCH /api/v1/appointments/{id}/cancel` - Cancel appointment

## 🧪 Testing

```bash
# Run all tests
poetry run pytest

# Run with coverage
poetry run pytest --cov=adyela_api

# Run specific test types
poetry run pytest -m unit
poetry run pytest -m integration
poetry run pytest -m contract

# Run with verbose output
poetry run pytest -v
```

## 🔍 Code Quality

```bash
# Format code
poetry run black .

# Lint code
poetry run ruff check .

# Type checking
poetry run mypy .

# Sort imports
poetry run isort .
```

## 📦 Dependencies

Key dependencies:

- **FastAPI** - Modern web framework
- **Pydantic** - Data validation
- **Firebase Admin** - Authentication
- **Google Cloud Firestore** - Database
- **Twilio** - SMS notifications
- **SendGrid** - Email notifications
- **Structlog** - Structured logging
- **SlowAPI** - Rate limiting

## 🔐 Security

- Firebase Authentication
- Multi-tenant isolation via middleware
- Rate limiting
- CORS configuration
- Structured logging
- Secret management with GCP Secret Manager

## 🌍 Environment Variables

See `.env.example` for all available configuration options.

Required variables:

- `SECRET_KEY` - JWT secret key
- `FIREBASE_PROJECT_ID` - Firebase project
- `GCP_PROJECT_ID` - GCP project

## 📝 API Documentation

When running in development mode, API documentation is available at:

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 🔄 CI/CD

GitHub Actions workflows:

- Lint and type checking
- Unit and integration tests
- Docker image build
- Deployment to GCP

## 📚 Additional Documentation

- [Architecture Decision Records](../../docs/adrs/)
- [API Contracts](../../docs/api/)
- [Deployment Guide](../../docs/deployment/)

## 🤝 Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md)

## 📄 License

See [LICENSE](../../LICENSE)
