"""List tenants use case."""

from adyela_api_admin.application.ports import TenantRepository
from adyela_api_admin.domain.entities import Tenant


class ListTenantsUseCase:
    """Use case for listing tenants with filtering and pagination."""

    def __init__(self, tenant_repository: TenantRepository) -> None:
        """Initialize use case."""
        self.tenant_repository = tenant_repository

    async def execute(
        self,
        status: str | None = None,
        tier: str | None = None,
        owner_id: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> list[Tenant]:
        """
        List tenants with optional filtering.

        Args:
            status: Filter by status (active, suspended, cancelled)
            tier: Filter by tier (free, pro, enterprise)
            owner_id: Filter by owner user ID
            limit: Maximum number of results
            offset: Number of results to skip (pagination)

        Returns:
            List of tenants matching filters
        """
        # Filter by owner first if provided
        if owner_id:
            return await self.tenant_repository.get_by_owner(owner_id)

        # Filter by status
        if status:
            return await self.tenant_repository.list_by_status(status, limit)

        # Filter by tier
        if tier:
            return await self.tenant_repository.list_by_tier(tier, limit)

        # Return all with pagination
        return await self.tenant_repository.list_all(limit, offset)
