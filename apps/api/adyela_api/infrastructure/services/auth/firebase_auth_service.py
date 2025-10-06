"""Firebase authentication service implementation."""

from typing import Any

from firebase_admin import auth  # type: ignore

from adyela_api.application.ports import AuthenticationService
from adyela_api.domain import AuthenticationError


class FirebaseAuthService(AuthenticationService):
    """Firebase authentication service implementation."""

    async def verify_token(self, token: str) -> dict[str, Any]:
        """Verify Firebase ID token and return decoded claims."""
        try:
            decoded_token = auth.verify_id_token(token)
            return {
                "uid": decoded_token["uid"],
                "email": decoded_token.get("email"),
                "email_verified": decoded_token.get("email_verified", False),
                "tenant_id": decoded_token.get("tenant_id"),
                "roles": decoded_token.get("roles", []),
            }
        except Exception as e:
            raise AuthenticationError(f"Invalid or expired token: {str(e)}") from e

    async def create_custom_token(self, user_id: str) -> str:
        """Create a custom Firebase token for a user."""
        try:
            custom_token = auth.create_custom_token(user_id)
            return str(custom_token.decode("utf-8"))
        except Exception as e:
            raise AuthenticationError(f"Failed to create custom token: {str(e)}") from e
