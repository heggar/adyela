"""Authentication schemas for OAuth and user management."""

from pydantic import BaseModel


class OAuthUserData(BaseModel):
    """OAuth user data from frontend."""

    uid: str
    email: str | None = None
    displayName: str | None = None
    photoURL: str | None = None
    provider: str
    emailVerified: bool = False


class OAuthSyncRequest(BaseModel):
    """OAuth synchronization request."""

    user_data: OAuthUserData


class OAuthSyncResponse(BaseModel):
    """OAuth synchronization response."""

    user: dict
    tenant_id: str
    roles: list[str]


class UserProfile(BaseModel):
    """User profile data."""

    uid: str
    email: str
    displayName: str | None = None
    photoURL: str | None = None
    provider: str
    emailVerified: bool
    tenant_id: str
    roles: list[str]
    created_at: str | None = None
    updated_at: str | None = None


class AuthError(BaseModel):
    """Authentication error response."""

    detail: str
    error_code: str | None = None
