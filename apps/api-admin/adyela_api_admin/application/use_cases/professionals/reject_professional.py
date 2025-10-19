"""Reject professional use case."""

from uuid import uuid4

from adyela_api_admin.application.ports import AuditLogRepository, ProfessionalRepository
from adyela_api_admin.config import AuditAction
from adyela_api_admin.domain.entities import AuditLog, Professional
from adyela_api_admin.domain.exceptions import ProfessionalNotFoundError


class RejectProfessionalUseCase:
    """Use case for rejecting professional applications."""

    def __init__(
        self,
        professional_repository: ProfessionalRepository,
        audit_repository: AuditLogRepository,
    ) -> None:
        """Initialize use case."""
        self.professional_repository = professional_repository
        self.audit_repository = audit_repository

    async def execute(self, professional_id: str, admin_id: str, reason: str) -> Professional:
        """Reject a professional application."""
        professional = await self.professional_repository.get_by_id(professional_id)

        if not professional:
            raise ProfessionalNotFoundError(f"Professional {professional_id} not found")

        professional.reject(admin_id, reason)
        updated_professional = await self.professional_repository.update(professional)

        audit_log = AuditLog(
            id=str(uuid4()),
            action=AuditAction.PROFESSIONAL_REJECTED,
            performed_by=admin_id,
            target_id=professional_id,
            details={
                "professional_email": professional.email,
                "reason": reason,
            },
        )
        await self.audit_repository.create(audit_log)

        return updated_professional
