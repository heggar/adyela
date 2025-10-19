"""
Authentication request/response schemas
"""
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator

from adyela_api_auth.domain.entities.user import UserRole, UserStatus


class RegisterRequest(BaseModel):
    """User registration request"""

    email: EmailStr
    password: str = Field(..., min_length=8, max_length=100)
    full_name: str = Field(..., min_length=2, max_length=100)
    phone: Optional[str] = None

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        """Validate password strength"""
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.islower() for c in v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one digit")
        return v

    class Config:
        json_schema_extra = {
            "example": {
                "email": "patient@example.com",
                "password": "SecurePass123!",
                "full_name": "John Doe",
                "phone": "+573001234567",
            }
        }


class RegisterResponse(BaseModel):
    """User registration response"""

    user: "UserResponse"
    access_token: str
    token_type: str = "Bearer"
    expires_in: int = 1800  # 30 minutes


class LoginRequest(BaseModel):
    """User login request"""

    email: EmailStr
    password: str

    class Config:
        json_schema_extra = {
            "example": {
                "email": "patient@example.com",
                "password": "SecurePass123!",
            }
        }


class LoginResponse(BaseModel):
    """User login response"""

    user: "UserResponse"
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int = 1800  # 30 minutes


class UserResponse(BaseModel):
    """User data response"""

    id: UUID
    email: EmailStr
    email_verified: bool
    full_name: str
    phone: Optional[str]
    phone_verified: bool
    roles: List[UserRole]
    status: UserStatus
    tenant_id: Optional[UUID]
    photo_url: Optional[str]
    created_at: datetime
    last_login_at: Optional[datetime]

    class Config:
        json_schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "email": "patient@example.com",
                "email_verified": True,
                "full_name": "John Doe",
                "phone": "+573001234567",
                "phone_verified": True,
                "roles": ["patient"],
                "status": "active",
                "tenant_id": None,
                "photo_url": "https://example.com/photo.jpg",
                "created_at": "2025-01-15T10:00:00Z",
                "last_login_at": "2025-01-18T15:30:00Z",
            }
        }


class TokenValidationRequest(BaseModel):
    """Token validation request (internal endpoint)"""

    token: str


class TokenValidationResponse(BaseModel):
    """Token validation response"""

    valid: bool
    user: Optional[UserResponse] = None
    error: Optional[str] = None
