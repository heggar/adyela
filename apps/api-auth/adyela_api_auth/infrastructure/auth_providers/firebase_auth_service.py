"""
Firebase Authentication service implementation
"""
import logging
from typing import Optional

import httpx

from adyela_api_auth.domain.interfaces.auth_service import IAuthService

logger = logging.getLogger(__name__)


class FirebaseAuthService(IAuthService):
    """
    Firebase Authentication service implementation.

    Uses Firebase Auth REST API for authentication operations.
    """

    # Firebase Auth REST API endpoints
    SIGN_UP_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signUp"
    SIGN_IN_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
    VERIFY_PASSWORD_URL = "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode"
    VERIFY_TOKEN_URL = "https://identitytoolkit.googleapis.com/v1/accounts:lookup"
    REFRESH_TOKEN_URL = "https://securetoken.googleapis.com/v1/token"
    SIGN_IN_WITH_IDP_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp"

    def __init__(self, api_key: str, project_id: str):
        """
        Initialize Firebase Auth service.

        Args:
            api_key: Firebase Web API key
            project_id: GCP project ID
        """
        self.api_key = api_key
        self.project_id = project_id
        self.client = httpx.AsyncClient()

    async def create_user_with_email_password(
        self, email: str, password: str
    ) -> dict:
        """Create user with email and password in Firebase Auth."""
        try:
            response = await self.client.post(
                self.SIGN_UP_URL,
                params={"key": self.api_key},
                json={
                    "email": email,
                    "password": password,
                    "returnSecureToken": True,
                },
            )
            response.raise_for_status()
            data = response.json()

            return {
                "firebase_uid": data["localId"],
                "id_token": data["idToken"],
                "refresh_token": data["refreshToken"],
                "expires_in": int(data["expiresIn"]),
                "email": data["email"],
            }

        except httpx.HTTPStatusError as e:
            error_data = e.response.json()
            error_message = error_data.get("error", {}).get("message", "Unknown error")

            if "EMAIL_EXISTS" in error_message:
                raise ValueError(f"User with email {email} already exists")
            elif "WEAK_PASSWORD" in error_message:
                raise ValueError("Password is too weak")
            elif "INVALID_EMAIL" in error_message:
                raise ValueError("Invalid email address")
            else:
                logger.error(f"Firebase signup error: {error_message}")
                raise ValueError(f"Failed to create user: {error_message}")

    async def sign_in_with_email_password(
        self, email: str, password: str
    ) -> dict:
        """Sign in user with email and password."""
        try:
            response = await self.client.post(
                self.SIGN_IN_URL,
                params={"key": self.api_key},
                json={
                    "email": email,
                    "password": password,
                    "returnSecureToken": True,
                },
            )
            response.raise_for_status()
            data = response.json()

            return {
                "firebase_uid": data["localId"],
                "id_token": data["idToken"],
                "refresh_token": data["refreshToken"],
                "expires_in": int(data["expiresIn"]),
                "email": data["email"],
            }

        except httpx.HTTPStatusError as e:
            error_data = e.response.json()
            error_message = error_data.get("error", {}).get("message", "Unknown error")

            if "EMAIL_NOT_FOUND" in error_message or "INVALID_PASSWORD" in error_message:
                raise ValueError("Invalid email or password")
            elif "USER_DISABLED" in error_message:
                raise ValueError("User account has been disabled")
            else:
                logger.error(f"Firebase signin error: {error_message}")
                raise ValueError(f"Failed to sign in: {error_message}")

    async def sign_in_with_oauth(
        self, provider: str, id_token: str
    ) -> dict:
        """Sign in with OAuth provider (Google, Facebook, Apple)."""
        # Map provider names to Firebase provider IDs
        provider_ids = {
            "google": "google.com",
            "facebook": "facebook.com",
            "apple": "apple.com",
        }

        provider_id = provider_ids.get(provider.lower())
        if not provider_id:
            raise ValueError(f"Unsupported OAuth provider: {provider}")

        try:
            # For Google, the id_token is the OAuth token
            # For Facebook/Apple, additional handling may be needed
            request_uri = f"https://{self.project_id}.firebaseapp.com"

            response = await self.client.post(
                self.SIGN_IN_WITH_IDP_URL,
                params={"key": self.api_key},
                json={
                    "postBody": f"id_token={id_token}&providerId={provider_id}",
                    "requestUri": request_uri,
                    "returnSecureToken": True,
                    "returnIdpCredential": True,
                },
            )
            response.raise_for_status()
            data = response.json()

            return {
                "firebase_uid": data["localId"],
                "email": data.get("email"),
                "name": data.get("displayName"),
                "photo_url": data.get("photoUrl"),
                "id_token": data["idToken"],
                "refresh_token": data.get("refreshToken"),
                "is_new_user": data.get("isNewUser", False),
            }

        except httpx.HTTPStatusError as e:
            error_data = e.response.json()
            error_message = error_data.get("error", {}).get("message", "Unknown error")
            logger.error(f"Firebase OAuth signin error: {error_message}")
            raise ValueError(f"Failed to sign in with {provider}: {error_message}")

    async def verify_id_token(self, id_token: str) -> dict:
        """Verify Firebase ID token."""
        try:
            response = await self.client.post(
                self.VERIFY_TOKEN_URL,
                params={"key": self.api_key},
                json={"idToken": id_token},
            )
            response.raise_for_status()
            data = response.json()

            if "users" not in data or len(data["users"]) == 0:
                raise ValueError("Invalid token")

            user = data["users"][0]
            return {
                "firebase_uid": user["localId"],
                "email": user.get("email"),
                "email_verified": user.get("emailVerified", False),
                "display_name": user.get("displayName"),
                "photo_url": user.get("photoUrl"),
            }

        except httpx.HTTPStatusError as e:
            error_data = e.response.json()
            error_message = error_data.get("error", {}).get("message", "Unknown error")

            if "INVALID_ID_TOKEN" in error_message or "TOKEN_EXPIRED" in error_message:
                raise ValueError("Token is invalid or expired")
            else:
                logger.error(f"Firebase token verification error: {error_message}")
                raise ValueError(f"Failed to verify token: {error_message}")

    async def refresh_token(self, refresh_token: str) -> dict:
        """Refresh access token."""
        try:
            response = await self.client.post(
                self.REFRESH_TOKEN_URL,
                params={"key": self.api_key},
                json={
                    "grant_type": "refresh_token",
                    "refresh_token": refresh_token,
                },
            )
            response.raise_for_status()
            data = response.json()

            return {
                "id_token": data["id_token"],
                "refresh_token": data["refresh_token"],
                "expires_in": int(data["expires_in"]),
            }

        except httpx.HTTPStatusError as e:
            error_data = e.response.json()
            error_message = error_data.get("error", {}).get("message", "Unknown error")
            logger.error(f"Firebase token refresh error: {error_message}")
            raise ValueError(f"Failed to refresh token: {error_message}")

    async def send_email_verification(self, id_token: str) -> bool:
        """Send email verification."""
        try:
            response = await self.client.post(
                self.VERIFY_PASSWORD_URL,
                params={"key": self.api_key},
                json={
                    "requestType": "VERIFY_EMAIL",
                    "idToken": id_token,
                },
            )
            response.raise_for_status()
            return True

        except httpx.HTTPStatusError as e:
            error_data = e.response.json()
            error_message = error_data.get("error", {}).get("message", "Unknown error")
            logger.error(f"Firebase email verification error: {error_message}")
            raise ValueError(f"Failed to send verification email: {error_message}")

    async def send_password_reset(self, email: str) -> bool:
        """Send password reset email."""
        try:
            response = await self.client.post(
                self.VERIFY_PASSWORD_URL,
                params={"key": self.api_key},
                json={
                    "requestType": "PASSWORD_RESET",
                    "email": email,
                },
            )
            response.raise_for_status()
            return True

        except httpx.HTTPStatusError as e:
            error_data = e.response.json()
            error_message = error_data.get("error", {}).get("message", "Unknown error")
            logger.error(f"Firebase password reset error: {error_message}")
            raise ValueError(f"Failed to send password reset email: {error_message}")

    async def delete_user(self, firebase_uid: str) -> bool:
        """
        Delete user from Firebase Auth.

        Note: This requires Firebase Admin SDK, not REST API.
        This is a placeholder that should be implemented with Admin SDK.
        """
        raise NotImplementedError(
            "User deletion requires Firebase Admin SDK. "
            "Use Admin SDK in production or delete via Firebase Console."
        )

    async def close(self):
        """Close HTTP client."""
        await self.client.aclose()
