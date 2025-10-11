"""Authentication schemas for OAuth and user management."""

from typing import Optional, List
from pydantic import BaseModel, EmailStr


class OAuthUserData(BaseModel):
    """OAuth user data from frontend."""
    uid: str
    email: Optional[str] = None
    displayName: Optional[str] = None
    photoURL: Optional[str] = None
    provider: str
    emailVerified: bool = False


class OAuthSyncRequest(BaseModel):
    """OAuth synchronization request."""
    user_data: OAuthUserData


class OAuthSyncResponse(BaseModel):
    """OAuth synchronization response."""
    user: dict
    tenant_id: str
    roles: List[str]


class UserProfile(BaseModel):
    """User profile data."""
    uid: str
    email: str
    displayName: Optional[str] = None
    photoURL: Optional[str] = None
    provider: str
    emailVerified: bool
    tenant_id: str
    roles: List[str]
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class AuthError(BaseModel):
    """Authentication error response."""
    detail: str
    error_code: Optional[str] = None
