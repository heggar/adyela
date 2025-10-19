"""List pending professionals use case."""

from adyela_api_admin.application.ports import ProfessionalRepository
from adyela_api_admin.config import ProfessionalStatus
from adyela_api_admin.domain.entities import Professional


class ListPendingProfessionalsUseCase:
    """Use case for listing pending professional applications."""

    def __init__(self, professional_repository: ProfessionalRepository) -> None:
        """Initialize use case."""
        self.professional_repository = professional_repository

    async def execute(self, limit: int = 50) -> list[Professional]:
        """List pending professional applications."""
        return await self.professional_repository.list_by_status(
            status=ProfessionalStatus.PENDING_VERIFICATION,
            limit=limit,
        )
