"""
Validate token use case
"""
import logging
from uuid import UUID

from adyela_api_auth.domain.interfaces.token_service import ITokenService
from adyela_api_auth.domain.interfaces.user_repository import IUserRepository

logger = logging.getLogger(__name__)


class ValidateTokenUseCase:
    """
    Use case for validating JWT tokens.

    This is used for service-to-service authentication where other
    microservices need to validate tokens.
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

    async def execute(self, token: str) -> dict:
        """
        Execute token validation.

        Args:
            token: JWT token to validate

        Returns:
            Dict with user data and token claims

        Raises:
            ValueError: If token is invalid
        """
        logger.debug("Validating JWT token")

        # 1. Decode and verify token
        payload = self.token_service.decode_token(token)

        # 2. Get user ID from token
        user_id = UUID(payload.get("user_id"))

        # 3. Get user from database (verify user still exists and is active)
        user = await self.user_repository.get_by_id(user_id)
        if not user:
            raise ValueError("User not found")

        if not user.is_active():
            raise ValueError("User account is not active")

        logger.debug(f"Token validated for user {user.id}")

        return {
            "valid": True,
            "user": {
                "id": str(user.id),
                "email": user.email,
                "full_name": user.full_name,
                "roles": [role.value for role in user.roles],
                "status": user.status.value,
                "tenant_id": str(user.tenant_id) if user.tenant_id else None,
            },
            "claims": payload,
        }
