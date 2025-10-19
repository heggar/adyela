"""
User domain entity
"""
from datetime import datetime
from enum import Enum
from typing import List, Optional
from uuid import UUID, uuid4

from pydantic import BaseModel, EmailStr, Field


class UserRole(str, Enum):
    """User roles for RBAC"""

    PATIENT = "patient"
    PROFESSIONAL = "professional"
    ADMIN = "admin"
    SUPERADMIN = "superadmin"


class UserStatus(str, Enum):
    """User account status"""

    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    PENDING_VERIFICATION = "pending_verification"


class User(BaseModel):
    """
    User entity representing an authenticated user in the system.

    Attributes:
        id: Unique user identifier
        email: User's email address (unique)
        email_verified: Whether email has been verified
        full_name: User's full name
        phone: Optional phone number
        phone_verified: Whether phone has been verified
        roles: List of roles assigned to user (RBAC)
        status: Account status
        tenant_id: Associated tenant ID (for multi-tenancy)
        firebase_uid: Firebase Authentication UID
        photo_url: Optional profile photo URL
        created_at: Account creation timestamp
        updated_at: Last update timestamp
        last_login_at: Last login timestamp
        metadata: Additional user metadata
    """

    id: UUID = Field(default_factory=uuid4)
    email: EmailStr
    email_verified: bool = False
    full_name: str
    phone: Optional[str] = None
    phone_verified: bool = False
    roles: List[UserRole] = Field(default_factory=lambda: [UserRole.PATIENT])
    status: UserStatus = UserStatus.PENDING_VERIFICATION
    tenant_id: Optional[UUID] = None
    firebase_uid: Optional[str] = None
    photo_url: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_login_at: Optional[datetime] = None
    metadata: dict = Field(default_factory=dict)

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
                "firebase_uid": "firebase_abc123",
                "photo_url": "https://example.com/photo.jpg",
            }
        }

    def has_role(self, role: UserRole) -> bool:
        """Check if user has a specific role"""
        return role in self.roles

    def is_active(self) -> bool:
        """Check if user account is active"""
        return self.status == UserStatus.ACTIVE

    def is_verified(self) -> bool:
        """Check if user email is verified"""
        return self.email_verified

    def can_access_tenant(self, tenant_id: UUID) -> bool:
        """Check if user can access a specific tenant"""
        # Admins and superadmins can access all tenants
        if UserRole.ADMIN in self.roles or UserRole.SUPERADMIN in self.roles:
            return True
        # Regular users can only access their own tenant
        return self.tenant_id == tenant_id

    def add_role(self, role: UserRole) -> None:
        """Add a role to user if not already present"""
        if role not in self.roles:
            self.roles.append(role)
            self.updated_at = datetime.utcnow()

    def remove_role(self, role: UserRole) -> None:
        """Remove a role from user"""
        if role in self.roles:
            self.roles.remove(role)
            self.updated_at = datetime.utcnow()

    def activate(self) -> None:
        """Activate user account"""
        self.status = UserStatus.ACTIVE
        self.updated_at = datetime.utcnow()

    def suspend(self) -> None:
        """Suspend user account"""
        self.status = UserStatus.SUSPENDED
        self.updated_at = datetime.utcnow()

    def update_last_login(self) -> None:
        """Update last login timestamp"""
        self.last_login_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
