"""Appointment endpoints."""

from datetime import datetime

from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel, Field

from adyela_api.config import AppointmentStatus, AppointmentType

router = APIRouter(prefix="/appointments", tags=["appointments"])


class AppointmentCreate(BaseModel):
    """Appointment creation schema."""

    patient_id: str = Field(..., description="Patient ID")
    practitioner_id: str = Field(..., description="Practitioner ID")
    start_time: datetime = Field(..., description="Start time")
    end_time: datetime = Field(..., description="End time")
    appointment_type: AppointmentType = Field(..., description="Type of appointment")
    reason: str | None = Field(None, description="Reason for appointment")


class AppointmentResponse(BaseModel):
    """Appointment response schema."""

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
    """Appointment list response schema."""

    items: list[AppointmentResponse]
    total: int
    page: int
    page_size: int


@router.post(
    "",
    response_model=AppointmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create appointment",
    description="Create a new appointment",
)
async def create_appointment(
    appointment: AppointmentCreate,
    request: Request,
) -> AppointmentResponse:
    """Create a new appointment."""
    _tenant_id = request.state.tenant_id

    # This is a placeholder - actual implementation would use the use case
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Appointment creation not fully implemented yet",
    )


@router.get(
    "",
    response_model=AppointmentListResponse,
    status_code=status.HTTP_200_OK,
    summary="List appointments",
    description="List all appointments for the tenant",
)
async def list_appointments(
    request: Request,
    page: int = 1,
    page_size: int = 20,
) -> AppointmentListResponse:
    """List appointments."""
    _tenant_id = request.state.tenant_id

    # Placeholder implementation
    return AppointmentListResponse(
        items=[],
        total=0,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/{appointment_id}",
    response_model=AppointmentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get appointment",
    description="Get a specific appointment by ID",
)
async def get_appointment(
    appointment_id: str,
    request: Request,
) -> AppointmentResponse:
    """Get appointment by ID."""
    _tenant_id = request.state.tenant_id

    # Placeholder
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=f"Appointment {appointment_id} not found",
    )


@router.patch(
    "/{appointment_id}/confirm",
    response_model=AppointmentResponse,
    status_code=status.HTTP_200_OK,
    summary="Confirm appointment",
    description="Confirm an appointment",
)
async def confirm_appointment(
    appointment_id: str,
    request: Request,
) -> AppointmentResponse:
    """Confirm an appointment."""
    _tenant_id = request.state.tenant_id

    # Placeholder
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented",
    )


@router.patch(
    "/{appointment_id}/cancel",
    response_model=AppointmentResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel appointment",
    description="Cancel an appointment",
)
async def cancel_appointment(
    appointment_id: str,
    request: Request,
) -> AppointmentResponse:
    """Cancel an appointment."""
    _tenant_id = request.state.tenant_id

    # Placeholder
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented",
    )
