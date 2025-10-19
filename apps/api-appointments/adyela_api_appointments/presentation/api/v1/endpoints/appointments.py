"""Appointment endpoints."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status

from adyela_api_appointments.application.use_cases.appointments import (
    CancelAppointmentUseCase,
    CheckAvailabilityUseCase,
    ConfirmAppointmentUseCase,
    CreateAppointmentUseCase,
    GetAppointmentUseCase,
    ListAppointmentsUseCase,
)
from adyela_api_appointments.domain.exceptions import (
    AppointmentConflictError,
    AppointmentNotFoundError,
    BusinessRuleViolationError,
)
from adyela_api_appointments.presentation.api.v1.schemas import (
    AppointmentCreate,
    AppointmentListResponse,
    AppointmentResponse,
    AvailabilityCheck,
    AvailabilityResponse,
)
from adyela_api_appointments.presentation.dependencies import (
    get_cancel_appointment_use_case,
    get_check_availability_use_case,
    get_confirm_appointment_use_case,
    get_create_appointment_use_case,
    get_get_appointment_use_case,
    get_list_appointments_use_case,
)

router = APIRouter()


@router.post(
    "",
    response_model=AppointmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create appointment",
    description="Create a new appointment with conflict detection",
)
async def create_appointment(
    request: Request,
    appointment_data: AppointmentCreate,
    use_case: CreateAppointmentUseCase = Depends(get_create_appointment_use_case),
) -> AppointmentResponse:
    """Create a new appointment."""
    # Get tenant_id from request state (set by auth middleware)
    tenant_id: UUID = request.state.tenant_id

    try:
        appointment = await use_case.execute(
            tenant_id=tenant_id,
            patient_id=appointment_data.patient_id,
            practitioner_id=appointment_data.practitioner_id,
            start_time=appointment_data.start_time,
            end_time=appointment_data.end_time,
            appointment_type=appointment_data.appointment_type,
            reason=appointment_data.reason,
        )

        # Convert to response
        return AppointmentResponse(
            id=appointment.id,
            tenant_id=str(appointment.tenant_id),
            patient_id=appointment.patient_id,
            practitioner_id=appointment.practitioner_id,
            start_time=appointment.schedule.start,
            end_time=appointment.schedule.end,
            appointment_type=appointment.appointment_type,
            status=appointment.status,
            reason=appointment.reason,
            notes=appointment.notes,
            video_room_url=appointment.video_room_url,
            created_at=appointment.created_at,
            updated_at=appointment.updated_at,
        )

    except AppointmentConflictError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e),
        )
    except BusinessRuleViolationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.get(
    "",
    response_model=AppointmentListResponse,
    status_code=status.HTTP_200_OK,
    summary="List appointments",
    description="List appointments with optional filtering by patient or practitioner",
)
async def list_appointments(
    request: Request,
    patient_id: str | None = Query(None, description="Filter by patient ID"),
    practitioner_id: str | None = Query(None, description="Filter by practitioner ID"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    use_case: ListAppointmentsUseCase = Depends(get_list_appointments_use_case),
) -> AppointmentListResponse:
    """List appointments."""
    tenant_id: UUID = request.state.tenant_id

    offset = (page - 1) * page_size

    appointments, total_count = await use_case.execute(
        tenant_id=tenant_id,
        patient_id=patient_id,
        practitioner_id=practitioner_id,
        limit=page_size,
        offset=offset,
    )

    items = [
        AppointmentResponse(
            id=apt.id,
            tenant_id=str(apt.tenant_id),
            patient_id=apt.patient_id,
            practitioner_id=apt.practitioner_id,
            start_time=apt.schedule.start,
            end_time=apt.schedule.end,
            appointment_type=apt.appointment_type,
            status=apt.status,
            reason=apt.reason,
            notes=apt.notes,
            video_room_url=apt.video_room_url,
            created_at=apt.created_at,
            updated_at=apt.updated_at,
        )
        for apt in appointments
    ]

    return AppointmentListResponse(
        items=items,
        total=total_count,
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
    request: Request,
    appointment_id: str,
    use_case: GetAppointmentUseCase = Depends(get_get_appointment_use_case),
) -> AppointmentResponse:
    """Get appointment by ID."""
    tenant_id: UUID = request.state.tenant_id

    try:
        appointment = await use_case.execute(
            appointment_id=appointment_id,
            tenant_id=tenant_id,
        )

        return AppointmentResponse(
            id=appointment.id,
            tenant_id=str(appointment.tenant_id),
            patient_id=appointment.patient_id,
            practitioner_id=appointment.practitioner_id,
            start_time=appointment.schedule.start,
            end_time=appointment.schedule.end,
            appointment_type=appointment.appointment_type,
            status=appointment.status,
            reason=appointment.reason,
            notes=appointment.notes,
            video_room_url=appointment.video_room_url,
            created_at=appointment.created_at,
            updated_at=appointment.updated_at,
        )

    except AppointmentNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )


@router.patch(
    "/{appointment_id}/confirm",
    response_model=AppointmentResponse,
    status_code=status.HTTP_200_OK,
    summary="Confirm appointment",
    description="Confirm a scheduled appointment",
)
async def confirm_appointment(
    request: Request,
    appointment_id: str,
    use_case: ConfirmAppointmentUseCase = Depends(get_confirm_appointment_use_case),
) -> AppointmentResponse:
    """Confirm an appointment."""
    tenant_id: UUID = request.state.tenant_id

    try:
        appointment = await use_case.execute(
            appointment_id=appointment_id,
            tenant_id=tenant_id,
        )

        return AppointmentResponse(
            id=appointment.id,
            tenant_id=str(appointment.tenant_id),
            patient_id=appointment.patient_id,
            practitioner_id=appointment.practitioner_id,
            start_time=appointment.schedule.start,
            end_time=appointment.schedule.end,
            appointment_type=appointment.appointment_type,
            status=appointment.status,
            reason=appointment.reason,
            notes=appointment.notes,
            video_room_url=appointment.video_room_url,
            created_at=appointment.created_at,
            updated_at=appointment.updated_at,
        )

    except AppointmentNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )
    except BusinessRuleViolationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.patch(
    "/{appointment_id}/cancel",
    response_model=AppointmentResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel appointment",
    description="Cancel an appointment",
)
async def cancel_appointment(
    request: Request,
    appointment_id: str,
    use_case: CancelAppointmentUseCase = Depends(get_cancel_appointment_use_case),
) -> AppointmentResponse:
    """Cancel an appointment."""
    tenant_id: UUID = request.state.tenant_id

    try:
        appointment = await use_case.execute(
            appointment_id=appointment_id,
            tenant_id=tenant_id,
        )

        return AppointmentResponse(
            id=appointment.id,
            tenant_id=str(appointment.tenant_id),
            patient_id=appointment.patient_id,
            practitioner_id=appointment.practitioner_id,
            start_time=appointment.schedule.start,
            end_time=appointment.schedule.end,
            appointment_type=appointment.appointment_type,
            status=appointment.status,
            reason=appointment.reason,
            notes=appointment.notes,
            video_room_url=appointment.video_room_url,
            created_at=appointment.created_at,
            updated_at=appointment.updated_at,
        )

    except AppointmentNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )
    except BusinessRuleViolationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.post(
    "/check-availability",
    response_model=AvailabilityResponse,
    status_code=status.HTTP_200_OK,
    summary="Check availability",
    description="Check if a practitioner is available for a time slot",
)
async def check_availability(
    request: Request,
    availability_data: AvailabilityCheck,
    use_case: CheckAvailabilityUseCase = Depends(get_check_availability_use_case),
) -> AvailabilityResponse:
    """Check practitioner availability."""
    tenant_id: UUID = request.state.tenant_id

    is_available = await use_case.execute(
        tenant_id=tenant_id,
        practitioner_id=availability_data.practitioner_id,
        start_time=availability_data.start_time,
        end_time=availability_data.end_time,
    )

    return AvailabilityResponse(
        available=is_available,
        practitioner_id=availability_data.practitioner_id,
        start_time=availability_data.start_time,
        end_time=availability_data.end_time,
    )
