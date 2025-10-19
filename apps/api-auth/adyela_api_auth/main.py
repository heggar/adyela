"""
Main FastAPI application for API Auth microservice
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from adyela_api_auth.config.settings import get_settings
from adyela_api_auth.presentation.api.router import api_router
from adyela_api_auth.presentation.middleware.correlation_id import CorrelationIdMiddleware
from adyela_api_auth.presentation.middleware.logging_middleware import LoggingMiddleware

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='{"timestamp": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}',
)
logger = logging.getLogger(__name__)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    logger.info(
        "Starting API Auth microservice",
        extra={
            "environment": settings.ENVIRONMENT,
            "version": "0.1.0",
        },
    )
    yield
    # Shutdown
    logger.info("Shutting down API Auth microservice")


# Create FastAPI app
app = FastAPI(
    title="Adyela API Auth",
    description="Authentication and Authorization microservice",
    version="0.1.0",
    docs_url="/docs" if settings.ENVIRONMENT != "production" else None,
    redoc_url="/redoc" if settings.ENVIRONMENT != "production" else None,
    lifespan=lifespan,
)

# Add middlewares
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(CorrelationIdMiddleware)
app.add_middleware(LoggingMiddleware)

# Include API router
app.include_router(api_router, prefix="/api/v1")


# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint for Cloud Run"""
    return JSONResponse(
        content={
            "status": "healthy",
            "service": "api-auth",
            "version": "0.1.0",
            "environment": settings.ENVIRONMENT,
        }
    )


# Metrics endpoint (Prometheus format)
@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    # TODO: Implement actual Prometheus metrics
    return JSONResponse(
        content={
            "requests_total": 0,
            "requests_in_progress": 0,
            "request_duration_seconds": {},
        }
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "adyela_api_auth.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True if settings.ENVIRONMENT == "development" else False,
    )
