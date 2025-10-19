"""Create tenant use case."""

import secrets
from datetime import UTC, datetime
from uuid import uuid4

from adyela_api_admin.application.ports import AuditLogRepository, TenantRepository
from adyela_api_admin.domain.entities import AuditLog, Tenant


class CreateTenantUseCase:
    """Use case for creating new tenants."""

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
        owner_id: str,
        name: str,
        email: str,
        phone: str,
        tier: str = "free",
        admin_id: str | None = None,
        timezone: str = "America/Bogota",
        language: str = "es",
        organization_id: str | None = None,
    ) -> Tenant:
        """
        Create a new tenant.

        Args:
            owner_id: User ID of the tenant owner
            name: Tenant name (e.g., "Dr. Carlos García - Psicología")
            email: Tenant contact email
            phone: Tenant contact phone
            tier: Subscription tier (free, pro, enterprise)
            admin_id: Admin creating the tenant (for audit log)
            timezone: Tenant timezone (default: America/Bogota)
            language: Tenant language (default: es)
            organization_id: Organization ID for enterprise tier

        Returns:
            Created tenant

        Raises:
            ValueError: If tier is invalid
        """
        # Validate tier
        valid_tiers = ["free", "pro", "enterprise"]
        if tier not in valid_tiers:
            raise ValueError(f"Invalid tier: {tier}. Must be one of {valid_tiers}")

        # Generate tenant ID: tenant_{name_slug}_{random_suffix}
        name_slug = name.lower().replace(" ", "_")[:20]
        random_suffix = secrets.token_hex(3)
        tenant_id = f"tenant_{name_slug}_{random_suffix}"

        # Create tenant entity
        tenant = Tenant(
            id=tenant_id,
            owner_id=owner_id,
            name=name,
            email=email,
            phone=phone,
            tier=tier,
            status="active",
            timezone=timezone,
            language=language,
            organization_id=organization_id,
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )

        # Create tenant in repository
        created_tenant = await self.tenant_repository.create(tenant)

        # Create audit log
        audit_log = AuditLog(
            id=str(uuid4()),
            action="TENANT_CREATED",
            performed_by=admin_id or owner_id,
            target_id=tenant_id,
            details={
                "tenant_name": name,
                "tenant_email": email,
                "tier": tier,
                "owner_id": owner_id,
            },
        )
        await self.audit_repository.create(audit_log)

        return created_tenant
