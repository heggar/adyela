"""
JWT Token service implementation
"""
import logging
from datetime import datetime, timedelta
from typing import Optional
from uuid import UUID

import jwt

from adyela_api_auth.domain.entities.user import User
from adyela_api_auth.domain.interfaces.token_service import ITokenService

logger = logging.getLogger(__name__)


class JWTTokenService(ITokenService):
    """
    JWT Token service implementation using PyJWT.

    This service creates and validates JWT tokens for service-to-service
    authentication and authorization.
    """

    def __init__(
        self,
        secret_key: str,
        algorithm: str = "HS256",
        access_token_expire_minutes: int = 30,
        refresh_token_expire_days: int = 7,
    ):
        """
        Initialize JWT token service.

        Args:
            secret_key: Secret key for signing tokens
            algorithm: JWT algorithm (default: HS256)
            access_token_expire_minutes: Access token expiration in minutes
            refresh_token_expire_days: Refresh token expiration in days
        """
        self.secret_key = secret_key
        self.algorithm = algorithm
        self.access_token_expire_minutes = access_token_expire_minutes
        self.refresh_token_expire_days = refresh_token_expire_days

    def create_access_token(
        self,
        user: User,
        expires_delta: Optional[timedelta] = None,
    ) -> str:
        """Create JWT access token for user."""
        if expires_delta is None:
            expires_delta = timedelta(minutes=self.access_token_expire_minutes)

        expire = datetime.utcnow() + expires_delta

        payload = {
            "user_id": str(user.id),
            "email": user.email,
            "roles": [role.value for role in user.roles],
            "tenant_id": str(user.tenant_id) if user.tenant_id else None,
            "token_type": "access",
            "exp": expire,
            "iat": datetime.utcnow(),
        }

        token = jwt.encode(payload, self.secret_key, algorithm=self.algorithm)
        logger.debug(f"Created access token for user {user.id}")
        return token

    def create_refresh_token(
        self,
        user: User,
        expires_delta: Optional[timedelta] = None,
    ) -> str:
        """Create JWT refresh token for user."""
        if expires_delta is None:
            expires_delta = timedelta(days=self.refresh_token_expire_days)

        expire = datetime.utcnow() + expires_delta

        payload = {
            "user_id": str(user.id),
            "token_type": "refresh",
            "exp": expire,
            "iat": datetime.utcnow(),
        }

        token = jwt.encode(payload, self.secret_key, algorithm=self.algorithm)
        logger.debug(f"Created refresh token for user {user.id}")
        return token

    def decode_token(self, token: str) -> dict:
        """Decode and validate JWT token."""
        try:
            payload = jwt.decode(
                token,
                self.secret_key,
                algorithms=[self.algorithm],
            )
            return payload

        except jwt.ExpiredSignatureError:
            logger.warning("Token has expired")
            raise ValueError("Token has expired")

        except jwt.InvalidTokenError as e:
            logger.warning(f"Invalid token: {str(e)}")
            raise ValueError(f"Invalid token: {str(e)}")

    def get_user_id_from_token(self, token: str) -> UUID:
        """Extract user ID from JWT token."""
        payload = self.decode_token(token)

        user_id_str = payload.get("user_id")
        if not user_id_str:
            raise ValueError("Token does not contain user_id")

        try:
            return UUID(user_id_str)
        except ValueError:
            raise ValueError("Invalid user_id in token")

    def verify_token(self, token: str, token_type: str = "access") -> bool:
        """Verify JWT token validity and type."""
        try:
            payload = self.decode_token(token)

            # Check token type
            if payload.get("token_type") != token_type:
                logger.warning(
                    f"Token type mismatch: expected {token_type}, "
                    f"got {payload.get('token_type')}"
                )
                return False

            return True

        except ValueError:
            return False
