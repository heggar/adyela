"""
Unit tests for Appointment entity
"""
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from adyela_api_appointments.config import AppointmentStatus, AppointmentType
from adyela_api_appointments.domain.entities import Appointment
from adyela_api_appointments.domain.exceptions import BusinessRuleViolationError
from adyela_api_appointments.domain.value_objects import DateTimeRange, TenantId


class TestAppointmentEntity:
    """Test suite for Appointment entity"""

    def test_create_appointment_success(
        self, tenant_id, patient_id, practitioner_id, future_time_range
    ):
        """Test creating a valid appointment"""
        # Arrange & Act
        appointment = Appointment(
            id=str(uuid4()),
            tenant_id=tenant_id,
            patient_id=patient_id,
            practitioner_id=practitioner_id,
            schedule=future_time_range,
            appointment_type=AppointmentType.VIDEO_CALL,
            reason="Annual checkup",
        )

        # Assert
        assert appointment.id is not None
        assert appointment.tenant_id == tenant_id
        assert appointment.status == AppointmentStatus.SCHEDULED
        assert appointment.appointment_type == AppointmentType.VIDEO_CALL
        assert appointment.reason == "Annual checkup"

    def test_create_appointment_in_past_fails(
        self, tenant_id, patient_id, practitioner_id
    ):
        """Test that creating appointment in the past raises error"""
        # Arrange
        past_start = datetime.now(UTC) - timedelta(days=1)
        past_end = past_start + timedelta(hours=1)
        past_time_range = DateTimeRange(start=past_start, end=past_end)

        # Act & Assert
        with pytest.raises(BusinessRuleViolationError) as exc_info:
            Appointment(
                id=str(uuid4()),
                tenant_id=tenant_id,
                patient_id=patient_id,
                practitioner_id=practitioner_id,
                schedule=past_time_range,
                appointment_type=AppointmentType.IN_PERSON,
            )

        assert "past" in str(exc_info.value).lower()

    def test_confirm_scheduled_appointment(self, sample_appointment):
        """Test confirming a scheduled appointment"""
        # Arrange
        assert sample_appointment.status == AppointmentStatus.SCHEDULED

        # Act
        sample_appointment.confirm()

        # Assert
        assert sample_appointment.status == AppointmentStatus.CONFIRMED

    def test_confirm_non_scheduled_appointment_fails(self, confirmed_appointment):
        """Test that confirming already confirmed appointment fails"""
        # Arrange
        assert confirmed_appointment.status == AppointmentStatus.CONFIRMED

        # Act & Assert
        with pytest.raises(BusinessRuleViolationError) as exc_info:
            confirmed_appointment.confirm()

        assert "cannot confirm" in str(exc_info.value).lower()

    def test_start_appointment(self, sample_appointment):
        """Test starting an appointment"""
        # Arrange
        sample_appointment.confirm()
        assert sample_appointment.status == AppointmentStatus.CONFIRMED

        # Act
        sample_appointment.start()

        # Assert
        assert sample_appointment.status == AppointmentStatus.IN_PROGRESS

    def test_complete_appointment(self, sample_appointment):
        """Test completing an appointment"""
        # Arrange
        sample_appointment.confirm()
        sample_appointment.start()
        assert sample_appointment.status == AppointmentStatus.IN_PROGRESS

        # Act
        sample_appointment.complete(notes="Patient responded well to treatment")

        # Assert
        assert sample_appointment.status == AppointmentStatus.COMPLETED
        assert "responded well" in sample_appointment.notes

    def test_complete_not_in_progress_fails(self, sample_appointment):
        """Test that completing appointment not in progress fails"""
        # Arrange
        assert sample_appointment.status == AppointmentStatus.SCHEDULED

        # Act & Assert
        with pytest.raises(BusinessRuleViolationError):
            sample_appointment.complete()

    def test_cancel_scheduled_appointment(self, sample_appointment):
        """Test canceling a scheduled appointment"""
        # Arrange
        assert sample_appointment.status == AppointmentStatus.SCHEDULED

        # Act
        sample_appointment.cancel()

        # Assert
        assert sample_appointment.status == AppointmentStatus.CANCELLED

    def test_cancel_completed_appointment_fails(self, sample_appointment):
        """Test that canceling completed appointment fails"""
        # Arrange
        sample_appointment.confirm()
        sample_appointment.start()
        sample_appointment.complete()
        assert sample_appointment.status == AppointmentStatus.COMPLETED

        # Act & Assert
        with pytest.raises(BusinessRuleViolationError):
            sample_appointment.cancel()

    def test_mark_no_show(self, sample_appointment):
        """Test marking appointment as no-show"""
        # Arrange
        sample_appointment.confirm()
        assert sample_appointment.status == AppointmentStatus.CONFIRMED

        # Act
        sample_appointment.mark_no_show()

        # Assert
        assert sample_appointment.status == AppointmentStatus.NO_SHOW

    def test_set_video_room_for_video_call(self, sample_appointment):
        """Test setting video room URL for video call appointment"""
        # Arrange
        assert sample_appointment.appointment_type == AppointmentType.VIDEO_CALL
        room_url = "https://meet.jit.si/appointment-12345"

        # Act
        sample_appointment.set_video_room(room_url)

        # Assert
        assert sample_appointment.video_room_url == room_url

    def test_set_video_room_for_in_person_fails(
        self, tenant_id, patient_id, practitioner_id, future_time_range
    ):
        """Test that setting video room for in-person appointment fails"""
        # Arrange
        appointment = Appointment(
            id=str(uuid4()),
            tenant_id=tenant_id,
            patient_id=patient_id,
            practitioner_id=practitioner_id,
            schedule=future_time_range,
            appointment_type=AppointmentType.IN_PERSON,
        )

        # Act & Assert
        with pytest.raises(BusinessRuleViolationError) as exc_info:
            appointment.set_video_room("https://meet.jit.si/test")

        assert "video call" in str(exc_info.value).lower()

    def test_duration_minutes_property(self, sample_appointment):
        """Test duration_minutes property"""
        # Assert
        assert sample_appointment.duration_minutes == 60  # 1 hour

    def test_is_upcoming_property(self, sample_appointment):
        """Test is_upcoming property"""
        # Assert
        assert sample_appointment.is_upcoming is True

    def test_is_not_upcoming_when_cancelled(self, sample_appointment):
        """Test that cancelled appointments are not upcoming"""
        # Arrange
        sample_appointment.cancel()

        # Assert
        assert sample_appointment.is_upcoming is False

    def test_can_be_modified_property(self, sample_appointment):
        """Test can_be_modified property"""
        # Assert
        assert sample_appointment.can_be_modified is True

        # Confirm and check again
        sample_appointment.confirm()
        assert sample_appointment.can_be_modified is True

        # Complete and check
        sample_appointment.start()
        sample_appointment.complete()
        assert sample_appointment.can_be_modified is False

    def test_to_dict(self, sample_appointment):
        """Test converting appointment to dictionary"""
        # Act
        data = sample_appointment.to_dict()

        # Assert
        assert data["id"] == sample_appointment.id
        assert data["tenant_id"] == str(sample_appointment.tenant_id)
        assert data["patient_id"] == sample_appointment.patient_id
        assert data["practitioner_id"] == sample_appointment.practitioner_id
        assert data["appointment_type"] == AppointmentType.VIDEO_CALL.value
        assert data["status"] == AppointmentStatus.SCHEDULED.value
        assert "start_time" in data
        assert "end_time" in data

    def test_from_dict(self, sample_appointment):
        """Test creating appointment from dictionary"""
        # Arrange
        data = sample_appointment.to_dict()

        # Act
        restored_appointment = Appointment.from_dict(data)

        # Assert
        assert restored_appointment.id == sample_appointment.id
        assert str(restored_appointment.tenant_id) == str(sample_appointment.tenant_id)
        assert restored_appointment.patient_id == sample_appointment.patient_id
        assert restored_appointment.practitioner_id == sample_appointment.practitioner_id
        assert restored_appointment.appointment_type == sample_appointment.appointment_type
        assert restored_appointment.status == sample_appointment.status
