"""
Application ports (dependency injection)
"""
from functools import lru_cache

from google.cloud import firestore

from adyela_api_auth.application.use_cases import (
    LoginUserUseCase,
    OAuthLoginUseCase,
    RefreshTokenUseCase,
    RegisterUserUseCase,
    ValidateTokenUseCase,
)
from adyela_api_auth.config.settings import get_settings
from adyela_api_auth.infrastructure.auth_providers.firebase_auth_service import (
    FirebaseAuthService,
)
from adyela_api_auth.infrastructure.repositories.firestore_user_repository import (
    FirestoreUserRepository,
)
from adyela_api_auth.infrastructure.security.jwt_token_service import JWTTokenService


@lru_cache()
def get_firestore_client() -> firestore.AsyncClient:
    """Get Firestore async client (singleton)."""
    settings = get_settings()
    return firestore.AsyncClient(project=settings.PROJECT_ID)


@lru_cache()
def get_user_repository() -> FirestoreUserRepository:
    """Get User Repository (singleton)."""
    db = get_firestore_client()
    return FirestoreUserRepository(db)


@lru_cache()
def get_auth_service() -> FirebaseAuthService:
    """Get Firebase Auth Service (singleton)."""
    settings = get_settings()
    return FirebaseAuthService(
        api_key=settings.FIREBASE_API_KEY,
        project_id=settings.PROJECT_ID,
    )


@lru_cache()
def get_token_service() -> JWTTokenService:
    """Get JWT Token Service (singleton)."""
    settings = get_settings()
    return JWTTokenService(
        secret_key=settings.JWT_SECRET,
        algorithm="HS256",
        access_token_expire_minutes=30,
        refresh_token_expire_days=7,
    )


def get_register_user_use_case() -> RegisterUserUseCase:
    """Get Register User Use Case."""
    return RegisterUserUseCase(
        user_repository=get_user_repository(),
        auth_service=get_auth_service(),
        token_service=get_token_service(),
    )


def get_login_user_use_case() -> LoginUserUseCase:
    """Get Login User Use Case."""
    return LoginUserUseCase(
        user_repository=get_user_repository(),
        auth_service=get_auth_service(),
        token_service=get_token_service(),
    )


def get_oauth_login_use_case() -> OAuthLoginUseCase:
    """Get OAuth Login Use Case."""
    return OAuthLoginUseCase(
        user_repository=get_user_repository(),
        auth_service=get_auth_service(),
        token_service=get_token_service(),
    )


def get_validate_token_use_case() -> ValidateTokenUseCase:
    """Get Validate Token Use Case."""
    return ValidateTokenUseCase(
        user_repository=get_user_repository(),
        token_service=get_token_service(),
    )


def get_refresh_token_use_case() -> RefreshTokenUseCase:
    """Get Refresh Token Use Case."""
    return RefreshTokenUseCase(
        user_repository=get_user_repository(),
        token_service=get_token_service(),
    )
