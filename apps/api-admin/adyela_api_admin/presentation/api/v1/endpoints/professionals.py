"""Professional endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status

from adyela_api_admin.application.use_cases.professionals import (
    ApproveProfessionalUseCase,
    ListPendingProfessionalsUseCase,
    RejectProfessionalUseCase,
)
from adyela_api_admin.domain.exceptions import (
    InvalidStatusTransitionError,
    ProfessionalNotFoundError,
)
from adyela_api_admin.presentation.api.v1.schemas import (
    ApproveProfessionalRequest,
    ProfessionalListResponse,
    ProfessionalResponse,
    RejectProfessionalRequest,
)
from adyela_api_admin.presentation.dependencies import (
    get_approve_professional_use_case,
    get_list_pending_use_case,
    get_reject_professional_use_case,
)

router = APIRouter()


@router.get(
    "/pending",
    response_model=ProfessionalListResponse,
    status_code=status.HTTP_200_OK,
    summary="List pending professionals",
    description="List all professional applications pending verification",
)
async def list_pending_professionals(
    limit: int = 50,
    use_case: ListPendingProfessionalsUseCase = Depends(get_list_pending_use_case),
) -> ProfessionalListResponse:
    """List pending professional applications."""
    professionals = await use_case.execute(limit=limit)

    items = [
        ProfessionalResponse(
            id=p.id,
            email=p.email,
            full_name=p.full_name,
            specialty=p.specialty,
            license_number=p.license_number,
            status=p.status,
            submitted_at=p.submitted_at,
            reviewed_at=p.reviewed_at,
            reviewed_by=p.reviewed_by,
            rejection_reason=p.rejection_reason,
        )
        for p in professionals
    ]

    return ProfessionalListResponse(items=items, total=len(items))


@router.post(
    "/{professional_id}/approve",
    response_model=ProfessionalResponse,
    status_code=status.HTTP_200_OK,
    summary="Approve professional",
    description="Approve a professional application",
)
async def approve_professional(
    professional_id: str,
    request: ApproveProfessionalRequest,
    use_case: ApproveProfessionalUseCase = Depends(get_approve_professional_use_case),
) -> ProfessionalResponse:
    """Approve a professional application."""
    try:
        professional = await use_case.execute(
            professional_id=professional_id,
            admin_id=request.admin_id,
        )

        return ProfessionalResponse(
            id=professional.id,
            email=professional.email,
            full_name=professional.full_name,
            specialty=professional.specialty,
            license_number=professional.license_number,
            status=professional.status,
            submitted_at=professional.submitted_at,
            reviewed_at=professional.reviewed_at,
            reviewed_by=professional.reviewed_by,
            rejection_reason=professional.rejection_reason,
        )

    except ProfessionalNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except InvalidStatusTransitionError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post(
    "/{professional_id}/reject",
    response_model=ProfessionalResponse,
    status_code=status.HTTP_200_OK,
    summary="Reject professional",
    description="Reject a professional application",
)
async def reject_professional(
    professional_id: str,
    request: RejectProfessionalRequest,
    use_case: RejectProfessionalUseCase = Depends(get_reject_professional_use_case),
) -> ProfessionalResponse:
    """Reject a professional application."""
    try:
        professional = await use_case.execute(
            professional_id=professional_id,
            admin_id=request.admin_id,
            reason=request.reason,
        )

        return ProfessionalResponse(
            id=professional.id,
            email=professional.email,
            full_name=professional.full_name,
            specialty=professional.specialty,
            license_number=professional.license_number,
            status=professional.status,
            submitted_at=professional.submitted_at,
            reviewed_at=professional.reviewed_at,
            reviewed_by=professional.reviewed_by,
            rejection_reason=professional.rejection_reason,
        )

    except ProfessionalNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except InvalidStatusTransitionError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
