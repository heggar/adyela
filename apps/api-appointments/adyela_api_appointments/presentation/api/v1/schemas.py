"""API schemas - Request and response models."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from adyela_api_appointments.config import AppointmentStatus, AppointmentType


class AppointmentCreate(BaseModel):
    """Request schema for creating an appointment."""

    patient_id: str = Field(..., description="Patient identifier")
    practitioner_id: str = Field(..., description="Practitioner identifier")
    start_time: datetime = Field(..., description="Appointment start time")
    end_time: datetime = Field(..., description="Appointment end time")
    appointment_type: AppointmentType = Field(..., description="Type of appointment")
    reason: str | None = Field(None, description="Reason for appointment")


class AppointmentResponse(BaseModel):
    """Response schema for an appointment."""

    id: str
    tenant_id: str
    patient_id: str
    practitioner_id: str
    start_time: datetime
    end_time: datetime
    appointment_type: AppointmentType
    status: AppointmentStatus
    reason: str | None
    notes: str | None
    video_room_url: str | None
    created_at: datetime
    updated_at: datetime


class AppointmentListResponse(BaseModel):
    """Response schema for a list of appointments."""

    items: list[AppointmentResponse]
    total: int
    page: int
    page_size: int


class AvailabilityCheck(BaseModel):
    """Request schema for checking availability."""

    practitioner_id: str = Field(..., description="Practitioner identifier")
    start_time: datetime = Field(..., description="Start time to check")
    end_time: datetime = Field(..., description="End time to check")


class AvailabilityResponse(BaseModel):
    """Response schema for availability check."""

    available: bool
    practitioner_id: str
    start_time: datetime
    end_time: datetime
