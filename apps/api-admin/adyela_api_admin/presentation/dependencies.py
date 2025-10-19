"""Dependency injection for FastAPI."""

from functools import lru_cache

from google.cloud import firestore  # type: ignore

from adyela_api_admin.application.ports import (
    AuditLogRepository,
    ProfessionalRepository,
    TenantRepository,
)
from adyela_api_admin.application.use_cases.professionals import (
    ApproveProfessionalUseCase,
    ListPendingProfessionalsUseCase,
    RejectProfessionalUseCase,
)
from adyela_api_admin.application.use_cases.tenants import (
    ActivateTenantUseCase,
    CancelTenantUseCase,
    CreateTenantUseCase,
    GetTenantUseCase,
    ListTenantsUseCase,
    SuspendTenantUseCase,
    UpdateTenantUseCase,
)
from adyela_api_admin.config import get_settings
from adyela_api_admin.infrastructure.repositories import (
    FirestoreAuditLogRepository,
    FirestoreProfessionalRepository,
    FirestoreTenantRepository,
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


# Tenant dependencies


def get_tenant_repository() -> TenantRepository:
    """Get tenant repository instance."""
    db = get_firestore_client()
    return FirestoreTenantRepository(db)


def get_create_tenant_use_case() -> CreateTenantUseCase:
    """Get create tenant use case."""
    return CreateTenantUseCase(
        tenant_repository=get_tenant_repository(),
        audit_repository=get_audit_log_repository(),
    )


def get_get_tenant_use_case() -> GetTenantUseCase:
    """Get get tenant use case."""
    return GetTenantUseCase(
        tenant_repository=get_tenant_repository(),
    )


def get_update_tenant_use_case() -> UpdateTenantUseCase:
    """Get update tenant use case."""
    return UpdateTenantUseCase(
        tenant_repository=get_tenant_repository(),
        audit_repository=get_audit_log_repository(),
    )


def get_list_tenants_use_case() -> ListTenantsUseCase:
    """Get list tenants use case."""
    return ListTenantsUseCase(
        tenant_repository=get_tenant_repository(),
    )


def get_suspend_tenant_use_case() -> SuspendTenantUseCase:
    """Get suspend tenant use case."""
    return SuspendTenantUseCase(
        tenant_repository=get_tenant_repository(),
        audit_repository=get_audit_log_repository(),
    )


def get_activate_tenant_use_case() -> ActivateTenantUseCase:
    """Get activate tenant use case."""
    return ActivateTenantUseCase(
        tenant_repository=get_tenant_repository(),
        audit_repository=get_audit_log_repository(),
    )


def get_cancel_tenant_use_case() -> CancelTenantUseCase:
    """Get cancel tenant use case."""
    return CancelTenantUseCase(
        tenant_repository=get_tenant_repository(),
        audit_repository=get_audit_log_repository(),
    )
