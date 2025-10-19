"""Main FastAPI application for analytics."""

import logging

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from adyela_api_analytics.config import settings
from adyela_api_analytics.presentation.api.v1.endpoints import analytics

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper()),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)

logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Adyela Analytics API",
    description="Analytics and reporting microservice for Adyela healthcare platform",
    version="0.1.0",
    docs_url=f"{settings.api_prefix}/docs",
    redoc_url=f"{settings.api_prefix}/redoc",
    openapi_url=f"{settings.api_prefix}/openapi.json",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check endpoint
@app.get("/health")
async def health_check() -> dict:
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "api-analytics",
        "version": "0.1.0",
    }


# Include routers
app.include_router(
    analytics.router,
    prefix=f"{settings.api_prefix}/analytics",
    tags=["analytics"],
)


@app.on_event("startup")
async def startup_event() -> None:
    """Startup event handler."""
    logger.info("Starting api-analytics service")
    logger.info(f"Environment: {settings.environment}")
    logger.info(f"BigQuery dataset: {settings.bigquery_dataset}")


@app.on_event("shutdown")
async def shutdown_event() -> None:
    """Shutdown event handler."""
    logger.info("Shutting down api-analytics service")


if __name__ == "__main__":
    uvicorn.run(
        "adyela_api_analytics.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower(),
    )
