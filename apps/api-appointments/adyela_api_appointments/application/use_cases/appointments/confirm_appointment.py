"""Confirm appointment use case."""

from uuid import UUID

from adyela_api_appointments.application.ports import AppointmentRepository, EventPublisher
from adyela_api_appointments.domain.entities import Appointment
from adyela_api_appointments.domain.exceptions import AppointmentNotFoundError
from adyela_api_appointments.domain.value_objects import TenantId


class ConfirmAppointmentUseCase:
    """Use case for confirming appointments."""

    def __init__(
        self,
        repository: AppointmentRepository,
        event_publisher: EventPublisher,
    ) -> None:
        """Initialize use case."""
        self.repository = repository
        self.event_publisher = event_publisher

    async def execute(self, appointment_id: str, tenant_id: UUID) -> Appointment:
        """
        Confirm an appointment.

        Args:
            appointment_id: Appointment identifier
            tenant_id: Tenant identifier

        Returns:
            Confirmed appointment

        Raises:
            AppointmentNotFoundError: If appointment not found
            BusinessRuleViolationError: If appointment cannot be confirmed
        """
        tenant = TenantId(tenant_id)

        # Get appointment
        appointment = await self.repository.get_by_id(appointment_id, tenant)

        if not appointment:
            raise AppointmentNotFoundError(f"Appointment {appointment_id} not found")

        # Confirm (domain logic validates if confirmation is allowed)
        appointment.confirm()

        # Persist
        updated_appointment = await self.repository.update(appointment)

        # Publish event
        await self.event_publisher.publish(
            event_type="AppointmentConfirmed",
            data={
                "appointment_id": updated_appointment.id,
                "tenant_id": str(updated_appointment.tenant_id),
                "patient_id": updated_appointment.patient_id,
                "practitioner_id": updated_appointment.practitioner_id,
                "start_time": updated_appointment.schedule.start.isoformat(),
            },
        )

        return updated_appointment
