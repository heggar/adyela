"""
JWT Token service interface (Port)
"""
from abc import ABC, abstractmethod
from datetime import timedelta
from typing import Optional
from uuid import UUID

from adyela_api_auth.domain.entities.user import User


class ITokenService(ABC):
    """
    Interface for JWT token service.

    This port defines operations for creating and validating JWT tokens
    for service-to-service authentication and authorization.
    """

    @abstractmethod
    def create_access_token(
        self,
        user: User,
        expires_delta: Optional[timedelta] = None,
    ) -> str:
        """
        Create JWT access token for user.

        Args:
            user: User entity
            expires_delta: Optional custom expiration time

        Returns:
            Encoded JWT token string
        """
        pass

    @abstractmethod
    def create_refresh_token(
        self,
        user: User,
        expires_delta: Optional[timedelta] = None,
    ) -> str:
        """
        Create JWT refresh token for user.

        Args:
            user: User entity
            expires_delta: Optional custom expiration time

        Returns:
            Encoded JWT refresh token string
        """
        pass

    @abstractmethod
    def decode_token(self, token: str) -> dict:
        """
        Decode and validate JWT token.

        Args:
            token: JWT token string

        Returns:
            Decoded token payload

        Raises:
            ValueError: If token is invalid or expired
        """
        pass

    @abstractmethod
    def get_user_id_from_token(self, token: str) -> UUID:
        """
        Extract user ID from JWT token.

        Args:
            token: JWT token string

        Returns:
            User UUID

        Raises:
            ValueError: If token is invalid or missing user_id
        """
        pass

    @abstractmethod
    def verify_token(self, token: str, token_type: str = "access") -> bool:
        """
        Verify JWT token validity and type.

        Args:
            token: JWT token string
            token_type: Expected token type ("access" or "refresh")

        Returns:
            True if valid, False otherwise
        """
        pass
