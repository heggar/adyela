"""Health check endpoints."""

from fastapi import APIRouter, status
from pydantic import BaseModel

router = APIRouter()


class HealthResponse(BaseModel):
    """Health check response model."""

    status: str
    version: str


class ReadinessResponse(BaseModel):
    """Readiness check response model."""

    status: str
    checks: dict[str, bool]


@router.get(
    "/health",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    tags=["health"],
    summary="Health check",
    description="Check if the API is up and running",
)
async def health_check() -> HealthResponse:
    """Health check endpoint."""
    return HealthResponse(status="healthy", version="0.1.0")


@router.get(
    "/readiness",
    response_model=ReadinessResponse,
    status_code=status.HTTP_200_OK,
    tags=["health"],
    summary="Readiness check",
    description="Check if the API is ready to accept requests",
)
async def readiness_check() -> ReadinessResponse:
    """Readiness check endpoint."""
    # Add actual checks for database, cache, etc.
    checks = {
        "database": True,
        "cache": True,
        "firebase": True,
    }

    all_ready = all(checks.values())
    status_text = "ready" if all_ready else "not_ready"

    return ReadinessResponse(status=status_text, checks=checks)
