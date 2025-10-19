"""Suspend tenant use case."""

from uuid import uuid4

from adyela_api_admin.application.ports import AuditLogRepository, TenantRepository
from adyela_api_admin.domain.entities import AuditLog, Tenant
from adyela_api_admin.domain.exceptions import TenantNotFoundError


class SuspendTenantUseCase:
    """Use case for suspending tenants."""

    def __init__(
        self,
        tenant_repository: TenantRepository,
        audit_repository: AuditLogRepository,
    ) -> None:
        """Initialize use case."""
        self.tenant_repository = tenant_repository
        self.audit_repository = audit_repository

    async def execute(self, tenant_id: str, admin_id: str, reason: str) -> Tenant:
        """
        Suspend a tenant.

        Args:
            tenant_id: Tenant identifier
            admin_id: Admin performing the suspension
            reason: Reason for suspension

        Returns:
            Suspended tenant

        Raises:
            TenantNotFoundError: If tenant not found
            InvalidStatusTransitionError: If tenant cannot be suspended
        """
        # Get tenant
        tenant = await self.tenant_repository.get_by_id(tenant_id)

        if not tenant:
            raise TenantNotFoundError(f"Tenant {tenant_id} not found")

        # Suspend (domain logic validates state transition)
        tenant.suspend(reason)

        # Update tenant
        updated_tenant = await self.tenant_repository.update(tenant)

        # Create audit log
        audit_log = AuditLog(
            id=str(uuid4()),
            action="TENANT_SUSPENDED",
            performed_by=admin_id,
            target_id=tenant_id,
            details={
                "tenant_name": tenant.name,
                "reason": reason,
            },
        )
        await self.audit_repository.create(audit_log)

        return updated_tenant
