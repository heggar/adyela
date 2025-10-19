"""Tenant management endpoints."""

from fastapi import APIRouter, Depends, HTTPException, Query, status

from adyela_api_admin.application.use_cases.tenants import (
    ActivateTenantUseCase,
    CancelTenantUseCase,
    CreateTenantUseCase,
    GetTenantUseCase,
    ListTenantsUseCase,
    SuspendTenantUseCase,
    UpdateTenantUseCase,
)
from adyela_api_admin.domain.exceptions import (
    InvalidStatusTransitionError,
    TenantNotFoundError,
)
from adyela_api_admin.presentation.api.v1.schemas import (
    ActivateTenantRequest,
    CancelTenantRequest,
    CreateTenantRequest,
    SuspendTenantRequest,
    TenantListResponse,
    TenantResponse,
    TenantStatsResponse,
    UpdateTenantRequest,
)
from adyela_api_admin.presentation.dependencies import (
    get_activate_tenant_use_case,
    get_cancel_tenant_use_case,
    get_create_tenant_use_case,
    get_get_tenant_use_case,
    get_list_tenants_use_case,
    get_suspend_tenant_use_case,
    get_update_tenant_use_case,
)

router = APIRouter()


def _tenant_to_response(tenant) -> TenantResponse:
    """Convert tenant entity to response schema."""
    return TenantResponse(
        id=tenant.id,
        owner_id=tenant.owner_id,
        name=tenant.name,
        email=tenant.email,
        phone=tenant.phone,
        tier=tenant.tier,
        status=tenant.status,
        organization_id=tenant.organization_id,
        timezone=tenant.timezone,
        language=tenant.language,
        created_at=tenant.created_at,
        updated_at=tenant.updated_at,
        migrated_from_legacy=tenant.migrated_from_legacy,
        subscription_expires_at=tenant.subscription_expires_at,
        payment_method_id=tenant.payment_method_id,
        stats=TenantStatsResponse(
            total_appointments=tenant.stats.total_appointments,
            total_patients=tenant.stats.total_patients,
            total_revenue=tenant.stats.total_revenue,
            last_appointment_date=tenant.stats.last_appointment_date,
        ),
    )


@router.post(
    "",
    response_model=TenantResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create tenant",
    description="Create a new tenant in the system",
)
async def create_tenant(
    request: CreateTenantRequest,
    use_case: CreateTenantUseCase = Depends(get_create_tenant_use_case),
) -> TenantResponse:
    """Create a new tenant."""
    try:
        tenant = await use_case.execute(
            owner_id=request.owner_id,
            name=request.name,
            email=request.email,
            phone=request.phone,
            tier=request.tier,
            admin_id=request.admin_id,
            timezone=request.timezone,
            language=request.language,
            organization_id=request.organization_id,
        )

        return _tenant_to_response(tenant)

    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get(
    "/{tenant_id}",
    response_model=TenantResponse,
    status_code=status.HTTP_200_OK,
    summary="Get tenant",
    description="Get tenant details by ID",
)
async def get_tenant(
    tenant_id: str,
    use_case: GetTenantUseCase = Depends(get_get_tenant_use_case),
) -> TenantResponse:
    """Get tenant by ID."""
    try:
        tenant = await use_case.execute(tenant_id=tenant_id)
        return _tenant_to_response(tenant)

    except TenantNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get(
    "",
    response_model=TenantListResponse,
    status_code=status.HTTP_200_OK,
    summary="List tenants",
    description="List all tenants with optional filtering",
)
async def list_tenants(
    status_filter: str | None = Query(None, alias="status", description="Filter by status"),
    tier: str | None = Query(None, description="Filter by tier"),
    owner_id: str | None = Query(None, description="Filter by owner"),
    limit: int = Query(100, ge=1, le=500, description="Max results"),
    offset: int = Query(0, ge=0, description="Skip results"),
    use_case: ListTenantsUseCase = Depends(get_list_tenants_use_case),
) -> TenantListResponse:
    """List tenants with filtering and pagination."""
    tenants = await use_case.execute(
        status=status_filter,
        tier=tier,
        owner_id=owner_id,
        limit=limit,
        offset=offset,
    )

    items = [_tenant_to_response(t) for t in tenants]

    return TenantListResponse(items=items, total=len(items))


@router.patch(
    "/{tenant_id}",
    response_model=TenantResponse,
    status_code=status.HTTP_200_OK,
    summary="Update tenant",
    description="Update tenant information",
)
async def update_tenant(
    tenant_id: str,
    request: UpdateTenantRequest,
    use_case: UpdateTenantUseCase = Depends(get_update_tenant_use_case),
) -> TenantResponse:
    """Update tenant information."""
    try:
        tenant = await use_case.execute(
            tenant_id=tenant_id,
            admin_id=request.admin_id,
            name=request.name,
            email=request.email,
            phone=request.phone,
            timezone=request.timezone,
            language=request.language,
        )

        return _tenant_to_response(tenant)

    except TenantNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post(
    "/{tenant_id}/suspend",
    response_model=TenantResponse,
    status_code=status.HTTP_200_OK,
    summary="Suspend tenant",
    description="Suspend an active tenant",
)
async def suspend_tenant(
    tenant_id: str,
    request: SuspendTenantRequest,
    use_case: SuspendTenantUseCase = Depends(get_suspend_tenant_use_case),
) -> TenantResponse:
    """Suspend a tenant."""
    try:
        tenant = await use_case.execute(
            tenant_id=tenant_id,
            admin_id=request.admin_id,
            reason=request.reason,
        )

        return _tenant_to_response(tenant)

    except TenantNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except InvalidStatusTransitionError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post(
    "/{tenant_id}/activate",
    response_model=TenantResponse,
    status_code=status.HTTP_200_OK,
    summary="Activate tenant",
    description="Activate a suspended or cancelled tenant",
)
async def activate_tenant(
    tenant_id: str,
    request: ActivateTenantRequest,
    use_case: ActivateTenantUseCase = Depends(get_activate_tenant_use_case),
) -> TenantResponse:
    """Activate a tenant."""
    try:
        tenant = await use_case.execute(
            tenant_id=tenant_id,
            admin_id=request.admin_id,
        )

        return _tenant_to_response(tenant)

    except TenantNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except InvalidStatusTransitionError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post(
    "/{tenant_id}/cancel",
    response_model=TenantResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel tenant",
    description="Cancel a tenant (soft delete)",
)
async def cancel_tenant(
    tenant_id: str,
    request: CancelTenantRequest,
    use_case: CancelTenantUseCase = Depends(get_cancel_tenant_use_case),
) -> TenantResponse:
    """Cancel a tenant (soft delete)."""
    try:
        tenant = await use_case.execute(
            tenant_id=tenant_id,
            admin_id=request.admin_id,
            reason=request.reason,
        )

        return _tenant_to_response(tenant)

    except TenantNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except InvalidStatusTransitionError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
