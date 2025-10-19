"""Get appointment use case."""

from uuid import UUID

from adyela_api_appointments.application.ports import AppointmentRepository
from adyela_api_appointments.domain.entities import Appointment
from adyela_api_appointments.domain.exceptions import AppointmentNotFoundError
from adyela_api_appointments.domain.value_objects import TenantId


class GetAppointmentUseCase:
    """Use case for retrieving a single appointment."""

    def __init__(self, repository: AppointmentRepository) -> None:
        """Initialize use case."""
        self.repository = repository

    async def execute(self, appointment_id: str, tenant_id: UUID) -> Appointment:
        """
        Get appointment by ID.

        Args:
            appointment_id: Appointment identifier
            tenant_id: Tenant identifier

        Returns:
            Appointment

        Raises:
            AppointmentNotFoundError: If appointment not found
        """
        tenant = TenantId(tenant_id)

        appointment = await self.repository.get_by_id(appointment_id, tenant)

        if not appointment:
            raise AppointmentNotFoundError(f"Appointment {appointment_id} not found")

        return appointment
