"""Approve professional use case."""

from uuid import uuid4

from adyela_api_admin.application.ports import AuditLogRepository, ProfessionalRepository
from adyela_api_admin.config import AuditAction
from adyela_api_admin.domain.entities import AuditLog, Professional
from adyela_api_admin.domain.exceptions import ProfessionalNotFoundError


class ApproveProfessionalUseCase:
    """Use case for approving professional applications."""

    def __init__(
        self,
        professional_repository: ProfessionalRepository,
        audit_repository: AuditLogRepository,
    ) -> None:
        """Initialize use case."""
        self.professional_repository = professional_repository
        self.audit_repository = audit_repository

    async def execute(self, professional_id: str, admin_id: str) -> Professional:
        """
        Approve a professional application.

        Args:
            professional_id: Professional identifier
            admin_id: Admin user identifier

        Returns:
            Approved professional

        Raises:
            ProfessionalNotFoundError: If professional not found
            InvalidStatusTransitionError: If professional cannot be approved
        """
        # Get professional
        professional = await self.professional_repository.get_by_id(professional_id)

        if not professional:
            raise ProfessionalNotFoundError(f"Professional {professional_id} not found")

        # Approve (domain logic validates state transition)
        professional.approve(admin_id)

        # Update professional
        updated_professional = await self.professional_repository.update(professional)

        # Create audit log
        audit_log = AuditLog(
            id=str(uuid4()),
            action=AuditAction.PROFESSIONAL_APPROVED,
            performed_by=admin_id,
            target_id=professional_id,
            details={
                "professional_email": professional.email,
                "professional_name": professional.full_name,
            },
        )
        await self.audit_repository.create(audit_log)

        return updated_professional
