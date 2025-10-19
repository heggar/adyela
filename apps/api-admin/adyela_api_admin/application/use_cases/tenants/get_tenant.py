"""Get tenant use case."""

from adyela_api_admin.application.ports import TenantRepository
from adyela_api_admin.domain.entities import Tenant
from adyela_api_admin.domain.exceptions import TenantNotFoundError


class GetTenantUseCase:
    """Use case for retrieving tenant information."""

    def __init__(self, tenant_repository: TenantRepository) -> None:
        """Initialize use case."""
        self.tenant_repository = tenant_repository

    async def execute(self, tenant_id: str) -> Tenant:
        """
        Get tenant by ID.

        Args:
            tenant_id: Tenant identifier

        Returns:
            Tenant entity

        Raises:
            TenantNotFoundError: If tenant not found
        """
        tenant = await self.tenant_repository.get_by_id(tenant_id)

        if not tenant:
            raise TenantNotFoundError(f"Tenant {tenant_id} not found")

        return tenant
