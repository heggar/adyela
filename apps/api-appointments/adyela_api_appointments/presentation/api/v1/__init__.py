"""API v1 - Endpoints and schemas."""

from fastapi import APIRouter

from .endpoints import appointments

router = APIRouter()

# Include routers
router.include_router(appointments.router, prefix="/appointments", tags=["appointments"])

__all__ = ["router"]
