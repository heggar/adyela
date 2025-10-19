"""Main FastAPI application for Admin microservice."""

from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware

from adyela_api_admin.config import get_settings

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Adyela Admin Microservice - Administrative operations",
    debug=settings.debug,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "api-admin",
        "version": settings.app_version,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "adyela_api_admin.main:app",
        host="0.0.0.0",
        port=8003,
        reload=settings.debug,
    )
