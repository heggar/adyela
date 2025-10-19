"""
Refresh token use case
"""
import logging
from uuid import UUID

from adyela_api_auth.domain.interfaces.token_service import ITokenService
from adyela_api_auth.domain.interfaces.user_repository import IUserRepository

logger = logging.getLogger(__name__)


class RefreshTokenUseCase:
    """
    Use case for refreshing JWT access tokens.

    This allows clients to get a new access token using a valid refresh token
    without requiring the user to log in again.
    """

    def __init__(
        self,
        user_repository: IUserRepository,
        token_service: ITokenService,
    ):
        """
        Initialize use case with required dependencies.

        Args:
            user_repository: User repository for database operations
            token_service: JWT token service
        """
        self.user_repository = user_repository
        self.token_service = token_service

    async def execute(self, refresh_token: str) -> dict:
        """
        Execute token refresh.

        Args:
            refresh_token: JWT refresh token

        Returns:
            Dict with new access token

        Raises:
            ValueError: If refresh token is invalid
        """
        logger.info("Refreshing access token")

        # 1. Verify refresh token
        if not self.token_service.verify_token(refresh_token, token_type="refresh"):
            raise ValueError("Invalid refresh token")

        # 2. Get user ID from refresh token
        user_id = self.token_service.get_user_id_from_token(refresh_token)

        # 3. Get user from database
        user = await self.user_repository.get_by_id(user_id)
        if not user:
            raise ValueError("User not found")

        if not user.is_active():
            raise ValueError("User account is not active")

        # 4. Generate new access token
        access_token = self.token_service.create_access_token(user)

        logger.info(f"Access token refreshed for user {user.id}")

        return {
            "access_token": access_token,
            "token_type": "Bearer",
        }
