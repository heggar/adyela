"""API v1."""

from fastapi import APIRouter

from .endpoints import professionals

router = APIRouter()
router.include_router(professionals.router, prefix="/professionals", tags=["professionals"])

__all__ = ["router"]
