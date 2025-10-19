"""Update tenant use case."""

from uuid import uuid4

from adyela_api_admin.application.ports import AuditLogRepository, TenantRepository
from adyela_api_admin.domain.entities import AuditLog, Tenant
from adyela_api_admin.domain.exceptions import TenantNotFoundError


class UpdateTenantUseCase:
    """Use case for updating tenant information."""

    def __init__(
        self,
        tenant_repository: TenantRepository,
        audit_repository: AuditLogRepository,
    ) -> None:
        """Initialize use case."""
        self.tenant_repository = tenant_repository
        self.audit_repository = audit_repository

    async def execute(
        self,
        tenant_id: str,
        admin_id: str,
        name: str | None = None,
        email: str | None = None,
        phone: str | None = None,
        timezone: str | None = None,
        language: str | None = None,
    ) -> Tenant:
        """
        Update tenant information.

        Args:
            tenant_id: Tenant identifier
            admin_id: Admin performing the update
            name: New tenant name (optional)
            email: New email (optional)
            phone: New phone (optional)
            timezone: New timezone (optional)
            language: New language (optional)

        Returns:
            Updated tenant

        Raises:
            TenantNotFoundError: If tenant not found
        """
        # Get tenant
        tenant = await self.tenant_repository.get_by_id(tenant_id)

        if not tenant:
            raise TenantNotFoundError(f"Tenant {tenant_id} not found")

        # Track changes for audit
        changes = {}

        # Update fields if provided
        if name is not None and name != tenant.name:
            changes["name"] = {"old": tenant.name, "new": name}
            tenant.name = name

        if email is not None and email != tenant.email:
            changes["email"] = {"old": tenant.email, "new": email}
            tenant.email = email

        if phone is not None and phone != tenant.phone:
            changes["phone"] = {"old": tenant.phone, "new": phone}
            tenant.phone = phone

        if timezone is not None and timezone != tenant.timezone:
            changes["timezone"] = {"old": tenant.timezone, "new": timezone}
            tenant.timezone = timezone

        if language is not None and language != tenant.language:
            changes["language"] = {"old": tenant.language, "new": language}
            tenant.language = language

        # Update tenant
        updated_tenant = await self.tenant_repository.update(tenant)

        # Create audit log if there were changes
        if changes:
            audit_log = AuditLog(
                id=str(uuid4()),
                action="TENANT_UPDATED",
                performed_by=admin_id,
                target_id=tenant_id,
                details={"changes": changes, "tenant_name": tenant.name},
            )
            await self.audit_repository.create(audit_log)

        return updated_tenant
