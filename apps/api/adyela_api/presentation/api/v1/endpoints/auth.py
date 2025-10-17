"""Authentication endpoints for OAuth and user management."""

import logging
from datetime import datetime

from fastapi import APIRouter, Depends, Header, HTTPException, status

from adyela_api.infrastructure.services.auth.firebase_auth_service import FirebaseAuthService
from adyela_api.presentation.schemas.auth import (
    OAuthSyncRequest,
    OAuthSyncResponse,
    UserProfile,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/sync", response_model=OAuthSyncResponse)
async def sync_oauth_user(
    request: OAuthSyncRequest,
    authorization: str = Header(..., description="Firebase ID token"),
    auth_service: FirebaseAuthService = Depends(),
) -> OAuthSyncResponse:
    """Sync OAuth user with backend and create/update user profile.

    This endpoint:
    1. Verifies the Firebase ID token
    2. Creates or updates user profile in Firestore
    3. Returns user data with roles and tenant information
    """
    try:
        # Extract token from Authorization header
        token = authorization.replace("Bearer ", "")

        # Verify Firebase token
        claims = await auth_service.verify_token(token)

        # Extract user data from request
        user_data = request.user_data

        # Create or update user profile
        user_profile = {
            "uid": user_data.uid,
            "email": user_data.email or claims.get("email", ""),
            "displayName": user_data.displayName or claims.get("name", ""),
            "photoURL": user_data.photoURL,
            "provider": user_data.provider,
            "emailVerified": user_data.emailVerified or claims.get("email_verified", False),
            "tenant_id": claims.get("tenant_id") or "default",
            "roles": claims.get("roles", ["patient"]),
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }

        # TODO: Save to Firestore using repository
        # For now, we'll return the profile data
        # In a real implementation, you would:
        # 1. Check if user exists in Firestore
        # 2. Create or update user document
        # 3. Handle tenant assignment logic
        # 4. Set appropriate roles based on business logic

        logger.info(
            "OAuth user synced successfully",
            extra={
                "uid": user_data.uid,
                "email": user_data.email,
                "provider": user_data.provider,
                "tenant_id": user_profile["tenant_id"],
            },
        )

        return OAuthSyncResponse(
            user=user_profile, tenant_id=user_profile["tenant_id"], roles=user_profile["roles"]
        )

    except Exception as e:
        logger.exception(
            "Error syncing OAuth user", extra={"error": str(e), "uid": request.user_data.uid}
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Authentication failed: {e!s}"
        ) from e


@router.get("/profile", response_model=UserProfile)
async def get_user_profile(
    authorization: str = Header(..., description="Firebase ID token"),
    auth_service: FirebaseAuthService = Depends(),
) -> UserProfile:
    """Get current user profile."""
    try:
        token = authorization.replace("Bearer ", "")
        claims = await auth_service.verify_token(token)

        # TODO: Fetch user profile from Firestore
        # For now, return basic profile from claims

        return UserProfile(
            uid=claims["uid"],
            email=claims.get("email", ""),
            displayName=claims.get("name", ""),
            photoURL=claims.get("picture"),
            provider=claims.get("firebase", {}).get("sign_in_provider", "unknown"),
            emailVerified=claims.get("email_verified", False),
            tenant_id=claims.get("tenant_id", "default"),
            roles=claims.get("roles", ["patient"]),
        )

    except Exception as e:
        logger.exception("Error getting user profile", extra={"error": str(e)})
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Authentication failed: {e!s}"
        ) from e


@router.post("/logout")
async def logout_user(
    authorization: str = Header(..., description="Firebase ID token")
) -> dict[str, str]:
    """Logout user (client-side token invalidation).

    Note: Firebase tokens are stateless, so logout is primarily handled
    on the client side by removing the token from storage.
    """
    try:
        # In a real implementation, you might:
        # 1. Add token to a blacklist
        # 2. Update user's last logout time
        # 3. Clear any server-side sessions

        logger.info("User logged out successfully")

        return {"message": "Logged out successfully"}

    except Exception as e:
        logger.exception("Error during logout", extra={"error": str(e)})
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Logout failed"
        ) from e
