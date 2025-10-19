"""Create appointment use case."""

from datetime import datetime
from uuid import UUID, uuid4

from adyela_api_appointments.application.ports import AppointmentRepository, EventPublisher
from adyela_api_appointments.config import AppointmentType
from adyela_api_appointments.domain.entities import Appointment
from adyela_api_appointments.domain.exceptions import AppointmentConflictError
from adyela_api_appointments.domain.value_objects import DateTimeRange, TenantId


class CreateAppointmentUseCase:
    """Use case for creating appointments."""

    def __init__(
        self,
        repository: AppointmentRepository,
        event_publisher: EventPublisher,
    ) -> None:
        """Initialize use case."""
        self.repository = repository
        self.event_publisher = event_publisher

    async def execute(
        self,
        tenant_id: UUID,
        patient_id: str,
        practitioner_id: str,
        start_time: datetime,
        end_time: datetime,
        appointment_type: AppointmentType,
        reason: str | None = None,
    ) -> Appointment:
        """
        Create a new appointment.

        Args:
            tenant_id: Tenant identifier
            patient_id: Patient identifier
            practitioner_id: Practitioner identifier
            start_time: Appointment start time
            end_time: Appointment end time
            appointment_type: Type of appointment
            reason: Optional reason for appointment

        Returns:
            Created appointment

        Raises:
            AppointmentConflictError: If there's a scheduling conflict
            BusinessRuleViolationError: If business rules are violated
        """
        # Create value objects
        tenant = TenantId(tenant_id)
        schedule = DateTimeRange(start=start_time, end=end_time)

        # Check for conflicts
        conflicts = await self.repository.find_conflicts(
            practitioner_id=practitioner_id,
            tenant_id=tenant,
            time_range=schedule,
        )

        if conflicts:
            raise AppointmentConflictError(
                f"Practitioner has {len(conflicts)} conflicting appointment(s) in this time slot"
            )

        # Create appointment entity
        appointment = Appointment(
            id=str(uuid4()),
            tenant_id=tenant,
            patient_id=patient_id,
            practitioner_id=practitioner_id,
            schedule=schedule,
            appointment_type=appointment_type,
            reason=reason,
        )

        # Persist
        created_appointment = await self.repository.create(appointment)

        # Publish event
        await self.event_publisher.publish(
            event_type="AppointmentCreated",
            data={
                "appointment_id": created_appointment.id,
                "tenant_id": str(created_appointment.tenant_id),
                "patient_id": created_appointment.patient_id,
                "practitioner_id": created_appointment.practitioner_id,
                "start_time": created_appointment.schedule.start.isoformat(),
                "end_time": created_appointment.schedule.end.isoformat(),
                "appointment_type": created_appointment.appointment_type.value,
            },
        )

        return created_appointment
