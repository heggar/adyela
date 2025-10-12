"""Unit tests for Appointment entity."""

from datetime import datetime, timedelta, timezone

import pytest

from adyela_api.config import AppointmentStatus, AppointmentType
from adyela_api.domain import Appointment, BusinessRuleViolationError
from adyela_api.domain.value_objects import DateTimeRange, TenantId


@pytest.fixture
def appointment() -> Appointment:
    """Create a test appointment."""
    start = datetime.now(timezone.utc) + timedelta(days=1)
    end = start + timedelta(hours=1)

    return Appointment(
        id="appt-123",
        tenant_id=TenantId("tenant-123"),
        patient_id="patient-123",
        practitioner_id="doc-123",
        schedule=DateTimeRange(start=start, end=end),
        appointment_type=AppointmentType.VIDEO_CALL,
        reason="Checkup",
    )


class TestAppointment:
    """Test Appointment entity."""

    def test_create_appointment(self, appointment: Appointment) -> None:
        """Test creating an appointment."""
        assert appointment.id == "appt-123"
        assert appointment.status == AppointmentStatus.SCHEDULED
        assert appointment.duration_minutes == 60

    def test_confirm_appointment(self, appointment: Appointment) -> None:
        """Test confirming an appointment."""
        appointment.confirm()
        assert appointment.status == AppointmentStatus.CONFIRMED

    def test_cannot_confirm_completed_appointment(self, appointment: Appointment) -> None:
        """Test that completed appointments cannot be confirmed."""
        appointment.status = AppointmentStatus.COMPLETED

        with pytest.raises(BusinessRuleViolationError):
            appointment.confirm()

    def test_cancel_appointment(self, appointment: Appointment) -> None:
        """Test canceling an appointment."""
        appointment.cancel()
        assert appointment.status == AppointmentStatus.CANCELLED

    def test_cannot_cancel_completed_appointment(self, appointment: Appointment) -> None:
        """Test that completed appointments cannot be cancelled."""
        appointment.status = AppointmentStatus.COMPLETED

        with pytest.raises(BusinessRuleViolationError):
            appointment.cancel()

    def test_set_video_room(self, appointment: Appointment) -> None:
        """Test setting video room URL."""
        room_url = "https://meet.jit.si/adyela-appt-123"
        appointment.set_video_room(room_url)
        assert appointment.video_room_url == room_url

    def test_cannot_set_video_room_for_in_person(self) -> None:
        """Test that video room cannot be set for in-person appointments."""
        start = datetime.now(timezone.utc) + timedelta(days=1)
        end = start + timedelta(hours=1)

        appointment = Appointment(
            id="appt-456",
            tenant_id=TenantId("tenant-123"),
            patient_id="patient-123",
            practitioner_id="doc-123",
            schedule=DateTimeRange(start=start, end=end),
            appointment_type=AppointmentType.IN_PERSON,
        )

        with pytest.raises(BusinessRuleViolationError):
            appointment.set_video_room("https://meet.jit.si/test")
