"""
Login user use case
"""
import logging

from adyela_api_auth.domain.entities.user import UserStatus
from adyela_api_auth.domain.interfaces.auth_service import IAuthService
from adyela_api_auth.domain.interfaces.token_service import ITokenService
from adyela_api_auth.domain.interfaces.user_repository import IUserRepository

logger = logging.getLogger(__name__)


class LoginUserUseCase:
    """
    Use case for user login.

    This implements the business logic for user authentication, including:
    1. Validating credentials with Firebase Auth
    2. Retrieving user from database
    3. Generating JWT tokens
    4. Updating last login timestamp
    """

    def __init__(
        self,
        user_repository: IUserRepository,
        auth_service: IAuthService,
        token_service: ITokenService,
    ):
        """
        Initialize use case with required dependencies.

        Args:
            user_repository: User repository for database operations
            auth_service: Authentication service (Firebase)
            token_service: JWT token service
        """
        self.user_repository = user_repository
        self.auth_service = auth_service
        self.token_service = token_service

    async def execute(self, email: str, password: str) -> dict:
        """
        Execute user login.

        Args:
            email: User email
            password: User password

        Returns:
            Dict with user data and tokens

        Raises:
            ValueError: If login fails
        """
        logger.info(f"User login attempt for email: {email}")

        # 1. Authenticate with Firebase (raises ValueError if invalid credentials)
        _ = await self.auth_service.sign_in_with_email_password(
            email=email,
            password=password,
        )

        # 2. Get user from database
        user = await self.user_repository.get_by_email(email)
        if not user:
            # User authenticated with Firebase but not in our database
            # This shouldn't happen in normal flow
            logger.error(f"User {email} authenticated but not found in database")
            raise ValueError("User not found in system")

        # 3. Check if user account is active
        if user.status == UserStatus.SUSPENDED:
            raise ValueError("User account has been suspended")

        if user.status == UserStatus.INACTIVE:
            raise ValueError("User account is inactive")

        # 4. Update last login timestamp
        user.update_last_login()
        await self.user_repository.update(user)

        # 5. Generate JWT tokens
        access_token = self.token_service.create_access_token(user)
        refresh_token = self.token_service.create_refresh_token(user)

        logger.info(f"User {user.id} logged in successfully")

        return {
            "user": {
                "id": str(user.id),
                "email": user.email,
                "full_name": user.full_name,
                "roles": [role.value for role in user.roles],
                "status": user.status.value,
                "email_verified": user.email_verified,
                "phone": user.phone,
                "phone_verified": user.phone_verified,
                "photo_url": user.photo_url,
                "tenant_id": str(user.tenant_id) if user.tenant_id else None,
            },
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
        }
