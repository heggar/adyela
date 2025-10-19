"""API v1."""

from fastapi import APIRouter

from .endpoints import professionals, tenants

router = APIRouter()
router.include_router(professionals.router, prefix="/professionals", tags=["professionals"])
router.include_router(tenants.router, prefix="/tenants", tags=["tenants"])

__all__ = ["router"]
