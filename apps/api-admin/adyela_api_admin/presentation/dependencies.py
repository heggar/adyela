"""Dependency injection for FastAPI."""

from functools import lru_cache

from google.cloud import firestore  # type: ignore

from adyela_api_admin.application.ports import AuditLogRepository, ProfessionalRepository
from adyela_api_admin.application.use_cases.professionals import (
    ApproveProfessionalUseCase,
    ListPendingProfessionalsUseCase,
    RejectProfessionalUseCase,
)
from adyela_api_admin.config import get_settings
from adyela_api_admin.infrastructure.repositories import (
    FirestoreAuditLogRepository,
    FirestoreProfessionalRepository,
)


@lru_cache
def get_firestore_client() -> firestore.Client:
    """Get Firestore client instance."""
    settings = get_settings()
    return firestore.Client(
        project=settings.gcp_project_id,
        database=settings.firestore_database,
    )


def get_professional_repository() -> ProfessionalRepository:
    """Get professional repository instance."""
    db = get_firestore_client()
    return FirestoreProfessionalRepository(db)


def get_audit_log_repository() -> AuditLogRepository:
    """Get audit log repository instance."""
    db = get_firestore_client()
    return FirestoreAuditLogRepository(db)


def get_approve_professional_use_case() -> ApproveProfessionalUseCase:
    """Get approve professional use case."""
    return ApproveProfessionalUseCase(
        professional_repository=get_professional_repository(),
        audit_repository=get_audit_log_repository(),
    )


def get_reject_professional_use_case() -> RejectProfessionalUseCase:
    """Get reject professional use case."""
    return RejectProfessionalUseCase(
        professional_repository=get_professional_repository(),
        audit_repository=get_audit_log_repository(),
    )


def get_list_pending_use_case() -> ListPendingProfessionalsUseCase:
    """Get list pending professionals use case."""
    return ListPendingProfessionalsUseCase(
        professional_repository=get_professional_repository(),
    )
