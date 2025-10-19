# Adyela API Admin

Administrative operations microservice for managing professionals and system
users.

## Purpose

Handles administrative tasks including:

- Professional application review and approval
- User management
- Audit logging

## Architecture

Hexagonal architecture with:

- **Domain Layer**: Professional, AuditLog entities
- **Application Layer**: Approval/rejection use cases
- **Infrastructure Layer**: Firestore repositories (to be implemented)
- **Presentation Layer**: FastAPI endpoints

## Endpoints

| Method | Endpoint                            | Description               |
| ------ | ----------------------------------- | ------------------------- |
| `GET`  | `/admin/professionals/pending`      | List pending applications |
| `POST` | `/admin/professionals/{id}/approve` | Approve professional      |
| `POST` | `/admin/professionals/{id}/reject`  | Reject professional       |

## Quick Start

```bash
cd apps/api-admin
poetry install
poetry run python -m adyela_api_admin.main
```

Visit http://localhost:8003/docs for API documentation.

## Status

🟡 **In Development** - Core domain logic complete, endpoints pending
implementation
