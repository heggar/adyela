"""
OAuth login use case
"""
import logging
from datetime import datetime

from adyela_api_auth.domain.entities.user import User, UserRole, UserStatus
from adyela_api_auth.domain.interfaces.auth_service import IAuthService
from adyela_api_auth.domain.interfaces.token_service import ITokenService
from adyela_api_auth.domain.interfaces.user_repository import IUserRepository

logger = logging.getLogger(__name__)


class OAuthLoginUseCase:
    """
    Use case for OAuth login (Google, Facebook, Apple).

    This implements the business logic for OAuth authentication, including:
    1. Validating OAuth token with provider
    2. Creating user if new
    3. Logging in existing user
    4. Generating JWT tokens
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
        provider: str,
        id_token: str,
        role: UserRole = UserRole.PATIENT,
    ) -> dict:
        """
        Execute OAuth login.

        Args:
            provider: OAuth provider (google, facebook, apple)
            id_token: OAuth ID token from provider
            role: Default role for new users (default: patient)

        Returns:
            Dict with user data and tokens

        Raises:
            ValueError: If OAuth login fails
        """
        logger.info(f"OAuth login attempt with provider: {provider}")

        # 1. Sign in with OAuth provider via Firebase
        oauth_data = await self.auth_service.sign_in_with_oauth(
            provider=provider,
            id_token=id_token,
        )

        firebase_uid = oauth_data["firebase_uid"]
        email = oauth_data.get("email")
        name = oauth_data.get("name", "")
        photo_url = oauth_data.get("photo_url")
        is_new_user = oauth_data.get("is_new_user", False)

        if not email:
            raise ValueError("Email not provided by OAuth provider")

        # 2. Check if user exists in our database
        user = await self.user_repository.get_by_firebase_uid(firebase_uid)

        if not user:
            # Try to find by email (user may have registered with email/password)
            user = await self.user_repository.get_by_email(email)

            if user:
                # Link Firebase UID to existing user
                user.firebase_uid = firebase_uid
                if photo_url and not user.photo_url:
                    user.photo_url = photo_url
                user.email_verified = True  # OAuth emails are pre-verified
                user.updated_at = datetime.utcnow()
                await self.user_repository.update(user)
                logger.info(f"Linked Firebase UID to existing user {user.id}")

        if not user:
            # 3. Create new user
            logger.info(f"Creating new user from OAuth: {email}")

            user = User(
                email=email,
                full_name=name or email.split("@")[0],
                roles=[role],
                status=UserStatus.ACTIVE,  # OAuth users are active immediately
                firebase_uid=firebase_uid,
                photo_url=photo_url,
                email_verified=True,  # OAuth emails are pre-verified
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )

            user = await self.user_repository.create(user)
            logger.info(f"Created new user {user.id} from OAuth")

        # 4. Update last login
        user.update_last_login()
        await self.user_repository.update(user)

        # 5. Generate JWT tokens
        access_token = self.token_service.create_access_token(user)
        refresh_token = self.token_service.create_refresh_token(user)

        logger.info(f"OAuth login successful for user {user.id}")

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
            "is_new_user": is_new_user,
        }
