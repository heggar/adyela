"""
Authentication service interface (Port)
"""
from abc import ABC, abstractmethod
from typing import Optional

from adyela_api_auth.domain.entities.user import User


class IAuthService(ABC):
    """
    Interface for authentication service.

    This port defines authentication operations using Firebase Auth
    or other identity providers.
    """

    @abstractmethod
    async def create_user_with_email_password(
        self, email: str, password: str
    ) -> dict:
        """
        Create a new user with email and password in Firebase Auth.

        Args:
            email: User email
            password: User password

        Returns:
            Dict with firebase_uid and other auth data

        Raises:
            ValueError: If user already exists or invalid credentials
        """
        pass

    @abstractmethod
    async def sign_in_with_email_password(
        self, email: str, password: str
    ) -> dict:
        """
        Sign in user with email and password.

        Args:
            email: User email
            password: User password

        Returns:
            Dict with id_token, refresh_token, firebase_uid, expires_in

        Raises:
            ValueError: If credentials are invalid
        """
        pass

    @abstractmethod
    async def sign_in_with_oauth(
        self, provider: str, id_token: str
    ) -> dict:
        """
        Sign in with OAuth provider (Google, Facebook, Apple).

        Args:
            provider: OAuth provider name (google, facebook, apple)
            id_token: OAuth ID token from provider

        Returns:
            Dict with firebase_uid, email, name, photo_url

        Raises:
            ValueError: If token is invalid
        """
        pass

    @abstractmethod
    async def verify_id_token(self, id_token: str) -> dict:
        """
        Verify Firebase ID token.

        Args:
            id_token: Firebase ID token

        Returns:
            Dict with decoded token claims (firebase_uid, email, etc.)

        Raises:
            ValueError: If token is invalid or expired
        """
        pass

    @abstractmethod
    async def refresh_token(self, refresh_token: str) -> dict:
        """
        Refresh access token using refresh token.

        Args:
            refresh_token: Firebase refresh token

        Returns:
            Dict with new id_token and expires_in

        Raises:
            ValueError: If refresh token is invalid
        """
        pass

    @abstractmethod
    async def send_email_verification(self, id_token: str) -> bool:
        """
        Send email verification to user.

        Args:
            id_token: User's Firebase ID token

        Returns:
            True if email sent successfully

        Raises:
            ValueError: If token is invalid
        """
        pass

    @abstractmethod
    async def send_password_reset(self, email: str) -> bool:
        """
        Send password reset email.

        Args:
            email: User email

        Returns:
            True if email sent successfully
        """
        pass

    @abstractmethod
    async def delete_user(self, firebase_uid: str) -> bool:
        """
        Delete user from Firebase Auth.

        Args:
            firebase_uid: Firebase UID

        Returns:
            True if deleted successfully

        Raises:
            ValueError: If user not found
        """
        pass
