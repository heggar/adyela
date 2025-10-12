"""API v1 router."""

from fastapi import APIRouter

from .endpoints import appointments, auth, data_deletion, health

api_router = APIRouter()

# Include health check routes (no auth required)
api_router.include_router(health.router, tags=["health"])

# Include public routes (no auth required)
api_router.include_router(data_deletion.router, prefix="/api/v1")

# Include protected routes
api_router.include_router(appointments.router, prefix="/api/v1")
api_router.include_router(auth.router, prefix="/api/v1")

__all__ = ["api_router"]
