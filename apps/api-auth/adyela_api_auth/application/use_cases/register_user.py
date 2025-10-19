"""
Register user use case
"""
import logging
from datetime import datetime

from adyela_api_auth.domain.entities.user import User, UserRole, UserStatus
from adyela_api_auth.domain.interfaces.auth_service import IAuthService
from adyela_api_auth.domain.interfaces.token_service import ITokenService
from adyela_api_auth.domain.interfaces.user_repository import IUserRepository

logger = logging.getLogger(__name__)


class RegisterUserUseCase:
    """
    Use case for registering a new user.

    This implements the business logic for user registration, including:
    1. Creating user in Firebase Auth
    2. Creating user in our database
    3. Generating JWT tokens
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

    async def execute(
        self,
        email: str,
        password: str,
        full_name: str,
        role: UserRole = UserRole.PATIENT,
    ) -> dict:
        """
        Execute user registration.

        Args:
            email: User email
            password: User password
            full_name: User full name
            role: User role (default: patient)

        Returns:
            Dict with user data and tokens

        Raises:
            ValueError: If registration fails
        """
        logger.info(f"Registering new user with email: {email}")

        # 1. Check if user already exists in our database
        existing_user = await self.user_repository.get_by_email(email)
        if existing_user:
            raise ValueError(f"User with email {email} already exists")

        # 2. Create user in Firebase Auth
        firebase_data = await self.auth_service.create_user_with_email_password(
            email=email,
            password=password,
        )

        # 3. Create user entity
        user = User(
            email=email,
            full_name=full_name,
            roles=[role],
            status=UserStatus.PENDING_VERIFICATION,
            firebase_uid=firebase_data["firebase_uid"],
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        # 4. Save user to database
        user = await self.user_repository.create(user)

        # 5. Generate JWT tokens
        access_token = self.token_service.create_access_token(user)
        refresh_token = self.token_service.create_refresh_token(user)

        # 6. Send email verification (non-blocking)
        try:
            await self.auth_service.send_email_verification(
                firebase_data["id_token"]
            )
        except Exception as e:
            # Log error but don't fail registration
            logger.error(f"Failed to send verification email: {str(e)}")

        logger.info(f"Successfully registered user {user.id}")

        return {
            "user": {
                "id": str(user.id),
                "email": user.email,
                "full_name": user.full_name,
                "roles": [role.value for role in user.roles],
                "status": user.status.value,
                "email_verified": user.email_verified,
            },
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
        }
