"""
Authentication endpoints
"""
import logging

from fastapi import APIRouter, Depends, HTTPException, status

from adyela_api_auth.application.ports import (
    get_auth_service,
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
from adyela_api_auth.domain.interfaces.auth_service import IAuthService
from adyela_api_auth.presentation.schemas.auth import (
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    LoginRequest,
    LoginResponse,
    OAuthLoginRequest,
    OAuthLoginResponse,
    RefreshTokenRequest,
    RefreshTokenResponse,
    RegisterRequest,
    RegisterResponse,
    ResetPasswordRequest,
    ResetPasswordResponse,
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


@router.post("/login/oauth", response_model=OAuthLoginResponse)
async def login_with_oauth(
    request: OAuthLoginRequest,
    use_case: OAuthLoginUseCase = Depends(get_oauth_login_use_case),
):
    """
    Login with OAuth provider (Google, Facebook, Apple).

    Args:
        request: OAuth login request with provider and id_token
        use_case: OAuth login use case (injected)

    Returns:
        OAuthLoginResponse with user data and tokens

    Raises:
        HTTPException: If OAuth login fails
    """
    try:
        # Get role from request (default: PATIENT)
        role = UserRole(request.role) if request.role else UserRole.PATIENT

        # Execute OAuth login use case
        result = await use_case.execute(
            provider=request.provider,
            id_token=request.id_token,
            role=role,
        )

        return OAuthLoginResponse(**result)

    except ValueError as e:
        logger.error(f"OAuth login failed for provider {request.provider}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"OAuth login failed: {str(e)}",
        )
    except Exception as e:
        logger.error(f"Unexpected error during OAuth login: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="OAuth login failed",
        )


@router.post("/login/google", response_model=OAuthLoginResponse)
async def login_with_google(
    id_token: str,
    use_case: OAuthLoginUseCase = Depends(get_oauth_login_use_case),
):
    """
    Login with Google OAuth (convenience endpoint).

    Args:
        id_token: Google OAuth ID token
        use_case: OAuth login use case (injected)

    Returns:
        OAuthLoginResponse with user data and tokens
    """
    return await login_with_oauth(
        OAuthLoginRequest(provider="google", id_token=id_token),
        use_case,
    )


@router.post("/login/facebook", response_model=OAuthLoginResponse)
async def login_with_facebook(
    id_token: str,
    use_case: OAuthLoginUseCase = Depends(get_oauth_login_use_case),
):
    """
    Login with Facebook OAuth (convenience endpoint).

    Args:
        id_token: Facebook OAuth ID token
        use_case: OAuth login use case (injected)

    Returns:
        OAuthLoginResponse with user data and tokens
    """
    return await login_with_oauth(
        OAuthLoginRequest(provider="facebook", id_token=id_token),
        use_case,
    )


@router.post("/login/apple", response_model=OAuthLoginResponse)
async def login_with_apple(
    id_token: str,
    use_case: OAuthLoginUseCase = Depends(get_oauth_login_use_case),
):
    """
    Login with Apple Sign In (convenience endpoint).

    Args:
        id_token: Apple ID token
        use_case: OAuth login use case (injected)

    Returns:
        OAuthLoginResponse with user data and tokens
    """
    return await login_with_oauth(
        OAuthLoginRequest(provider="apple", id_token=id_token),
        use_case,
    )


@router.post("/validate-token", response_model=TokenValidationResponse)
async def validate_token(
    request: TokenValidationRequest,
    use_case: ValidateTokenUseCase = Depends(get_validate_token_use_case),
):
    """
    Validate JWT token (internal endpoint for service-to-service auth).

    Args:
        request: Token validation request
        use_case: Validate token use case (injected)

    Returns:
        TokenValidationResponse with user data if valid

    Raises:
        HTTPException: If token is invalid or expired
    """
    try:
        result = await use_case.execute(token=request.token)
        return TokenValidationResponse(
            valid=result["valid"],
            user=result.get("user"),
        )

    except ValueError as e:
        logger.warning(f"Token validation failed: {str(e)}")
        return TokenValidationResponse(
            valid=False,
            error=str(e),
        )
    except Exception as e:
        logger.error(f"Unexpected error during token validation: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token validation failed",
        )


@router.post("/refresh", response_model=RefreshTokenResponse)
async def refresh_token(
    request: RefreshTokenRequest,
    use_case: RefreshTokenUseCase = Depends(get_refresh_token_use_case),
):
    """
    Refresh access token using refresh token.

    Args:
        request: Refresh token request
        use_case: Refresh token use case (injected)

    Returns:
        RefreshTokenResponse with new access token

    Raises:
        HTTPException: If refresh token is invalid
    """
    try:
        result = await use_case.execute(refresh_token=request.refresh_token)
        return RefreshTokenResponse(**result)

    except ValueError as e:
        logger.warning(f"Token refresh failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )
    except Exception as e:
        logger.error(f"Unexpected error during token refresh: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token refresh failed",
        )


@router.post("/forgot-password", response_model=ForgotPasswordResponse)
async def forgot_password(
    request: ForgotPasswordRequest,
    auth_service: IAuthService = Depends(lambda: get_auth_service()),
):
    """
    Request password reset email.

    Args:
        request: Forgot password request with email
        auth_service: Firebase auth service (injected)

    Returns:
        ForgotPasswordResponse with confirmation message

    Raises:
        HTTPException: If request fails
    """
    try:
        await auth_service.send_password_reset(email=request.email)

        return ForgotPasswordResponse(
            message="Password reset email sent successfully",
            email=request.email,
        )

    except ValueError as e:
        logger.warning(f"Password reset failed for {request.email}: {str(e)}")
        # Return success even if email not found (security best practice)
        return ForgotPasswordResponse(
            message="If the email exists, a password reset link has been sent",
            email=request.email,
        )
    except Exception as e:
        logger.error(f"Unexpected error during password reset: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send password reset email",
        )


@router.post("/reset-password", response_model=ResetPasswordResponse)
async def reset_password(request: ResetPasswordRequest):
    """
    Reset password with token.

    Note: This endpoint is typically handled by Firebase Auth UI.
    For custom implementation, use Firebase Admin SDK.

    Args:
        request: Reset password request with token and new password

    Returns:
        ResetPasswordResponse with confirmation message

    Raises:
        HTTPException: Not implemented (use Firebase Auth UI)
    """
    # Firebase password reset is typically handled via email link + Firebase Auth UI
    # For custom implementation, would need Firebase Admin SDK
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Password reset is handled via Firebase Auth email link. "
        "Please use the link sent to your email.",
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
