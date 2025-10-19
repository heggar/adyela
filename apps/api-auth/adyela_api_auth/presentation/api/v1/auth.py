"""
Authentication endpoints
"""
import logging

from fastapi import APIRouter, Depends, HTTPException, status

from adyela_api_auth.application.ports import (
    get_login_user_use_case,
    get_oauth_login_use_case,
    get_refresh_token_use_case,
    get_register_user_use_case,
    get_validate_token_use_case,
)
from adyela_api_auth.application.use_cases import (
    LoginUserUseCase,
    OAuthLoginUseCase,
    RefreshTokenUseCase,
    RegisterUserUseCase,
    ValidateTokenUseCase,
)
from adyela_api_auth.domain.entities.user import UserRole
from adyela_api_auth.presentation.schemas.auth import (
    LoginRequest,
    LoginResponse,
    OAuthLoginRequest,
    OAuthLoginResponse,
    RefreshTokenRequest,
    RefreshTokenResponse,
    RegisterRequest,
    RegisterResponse,
    TokenValidationRequest,
    TokenValidationResponse,
)

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def register(
    request: RegisterRequest,
    use_case: RegisterUserUseCase = Depends(get_register_user_use_case),
):
    """
    Register a new user with email and password.

    Args:
        request: Registration data (email, password, full_name)
        use_case: Register user use case (injected)

    Returns:
        RegisterResponse with user data and access token

    Raises:
        HTTPException: If email already exists or validation fails
    """
    try:
        # Get role from request (default: PATIENT)
        role = UserRole(request.role) if request.role else UserRole.PATIENT

        # Execute registration use case
        result = await use_case.execute(
            email=request.email,
            password=request.password,
            full_name=request.full_name,
            role=role,
        )

        return RegisterResponse(**result)

    except ValueError as e:
        logger.error(f"Registration failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except Exception as e:
        logger.error(f"Unexpected error during registration: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed",
        )


@router.post("/login", response_model=LoginResponse)
async def login(
    request: LoginRequest,
    use_case: LoginUserUseCase = Depends(get_login_user_use_case),
):
    """
    Login with email and password.

    Args:
        request: Login credentials (email, password)
        use_case: Login user use case (injected)

    Returns:
        LoginResponse with user data and access token

    Raises:
        HTTPException: If credentials are invalid
    """
    try:
        # Execute login use case
        result = await use_case.execute(
            email=request.email,
            password=request.password,
        )

        return LoginResponse(**result)

    except ValueError as e:
        logger.error(f"Login failed for {request.email}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    except Exception as e:
        logger.error(f"Unexpected error during login: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Login failed",
        )


@router.post("/login/google")
async def login_with_google():
    """Login with Google OAuth"""
    # TODO: Implement Google OAuth
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Google OAuth not yet implemented",
    )


@router.post("/login/facebook")
async def login_with_facebook():
    """Login with Facebook OAuth"""
    # TODO: Implement Facebook OAuth
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Facebook OAuth not yet implemented",
    )


@router.post("/login/apple")
async def login_with_apple():
    """Login with Apple OAuth"""
    # TODO: Implement Apple Sign In
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Apple Sign In not yet implemented",
    )


@router.post("/validate-token", response_model=TokenValidationResponse)
async def validate_token(request: TokenValidationRequest):
    """
    Validate JWT token (internal endpoint for service-to-service auth).

    Args:
        request: Token validation request

    Returns:
        TokenValidationResponse with user data if valid

    Raises:
        HTTPException: If token is invalid or expired
    """
    # TODO: Implement token validation
    # 1. Decode JWT token
    # 2. Validate signature
    # 3. Check expiration
    # 4. Get user from Firestore
    # 5. Return user data

    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Token validation not yet implemented",
    )


@router.post("/refresh")
async def refresh_token():
    """Refresh access token using refresh token"""
    # TODO: Implement token refresh
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Token refresh not yet implemented",
    )


@router.post("/forgot-password")
async def forgot_password():
    """Request password reset"""
    # TODO: Implement password reset request
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Password reset not yet implemented",
    )


@router.post("/reset-password")
async def reset_password():
    """Reset password with token"""
    # TODO: Implement password reset
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Password reset not yet implemented",
    )


@router.get("/me")
async def get_current_user():
    """Get current authenticated user info"""
    # TODO: Implement get current user
    # Requires authentication middleware
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Get current user not yet implemented",
    )
