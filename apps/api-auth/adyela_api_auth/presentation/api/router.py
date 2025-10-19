"""
Main API router
"""
from fastapi import APIRouter

from adyela_api_auth.presentation.api.v1 import auth_router

# Create main API router
api_router = APIRouter()

# Include v1 routes
api_router.include_router(auth_router, prefix="/auth", tags=["Authentication"])
