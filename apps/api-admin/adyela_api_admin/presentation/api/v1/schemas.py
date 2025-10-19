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
