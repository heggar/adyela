"""API schemas."""

from datetime import datetime

from pydantic import BaseModel, Field

from adyela_api_admin.config import ProfessionalStatus


class ProfessionalResponse(BaseModel):
    """Response schema for a professional."""

    id: str
    email: str
    full_name: str
    specialty: str
    license_number: str
    status: ProfessionalStatus
    submitted_at: datetime
    reviewed_at: datetime | None
    reviewed_by: str | None
    rejection_reason: str | None


class ApproveProfessionalRequest(BaseModel):
    """Request schema for approving a professional."""

    admin_id: str = Field(..., description="Admin user ID")


class RejectProfessionalRequest(BaseModel):
    """Request schema for rejecting a professional."""

    admin_id: str = Field(..., description="Admin user ID")
    reason: str = Field(..., description="Reason for rejection")


class ProfessionalListResponse(BaseModel):
    """Response schema for list of professionals."""

    items: list[ProfessionalResponse]
    total: int


# Tenant schemas


class TenantStatsResponse(BaseModel):
    """Response schema for tenant statistics."""

    total_appointments: int
    total_patients: int
    total_revenue: float
    last_appointment_date: datetime | None


class TenantResponse(BaseModel):
    """Response schema for a tenant."""

    id: str
    owner_id: str
    name: str
    email: str
    phone: str
    tier: str
    status: str
    organization_id: str | None
    timezone: str
    language: str
    created_at: datetime
    updated_at: datetime
    migrated_from_legacy: bool
    subscription_expires_at: datetime | None
    payment_method_id: str | None
    stats: TenantStatsResponse


class CreateTenantRequest(BaseModel):
    """Request schema for creating a tenant."""

    owner_id: str = Field(..., description="Owner user ID")
    name: str = Field(..., description="Tenant name", min_length=1, max_length=200)
    email: str = Field(..., description="Contact email")
    phone: str = Field(..., description="Contact phone")
    tier: str = Field(default="free", description="Subscription tier (free, pro, enterprise)")
    timezone: str = Field(default="America/Bogota", description="Timezone")
    language: str = Field(default="es", description="Language (es, en)")
    organization_id: str | None = Field(None, description="Organization ID for enterprise")
    admin_id: str = Field(..., description="Admin creating the tenant")


class UpdateTenantRequest(BaseModel):
    """Request schema for updating a tenant."""

    name: str | None = Field(None, description="New tenant name")
    email: str | None = Field(None, description="New email")
    phone: str | None = Field(None, description="New phone")
    timezone: str | None = Field(None, description="New timezone")
    language: str | None = Field(None, description="New language")
    admin_id: str = Field(..., description="Admin performing update")


class SuspendTenantRequest(BaseModel):
    """Request schema for suspending a tenant."""

    admin_id: str = Field(..., description="Admin user ID")
    reason: str = Field(..., description="Reason for suspension")


class ActivateTenantRequest(BaseModel):
    """Request schema for activating a tenant."""

    admin_id: str = Field(..., description="Admin user ID")


class CancelTenantRequest(BaseModel):
    """Request schema for cancelling a tenant."""

    admin_id: str = Field(..., description="Admin user ID")
    reason: str = Field(..., description="Reason for cancellation")


class TenantListResponse(BaseModel):
    """Response schema for list of tenants."""

    items: list[TenantResponse]
    total: int
