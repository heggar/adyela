from pydantic import BaseModel, EmailStr
from typing import Optional
from enum import Enum

class DataDeletionStatus(str, Enum):
    """Status of data deletion request."""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"

class DataDeletionRequest(BaseModel):
    """Request for data deletion."""
    email: EmailStr
    reason: Optional[str] = None
    confirmation_required: bool = True

class DataDeletionResponse(BaseModel):
    """Response for data deletion request."""
    request_id: str
    status: DataDeletionStatus
    message: str
    estimated_completion: Optional[str] = None

class DataDeletionStatusResponse(BaseModel):
    """Response for checking deletion status."""
    request_id: str
    status: DataDeletionStatus
    created_at: str
    completed_at: Optional[str] = None
    message: str
