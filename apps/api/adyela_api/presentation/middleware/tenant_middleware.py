"""Tenant isolation middleware."""

from fastapi import Request, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware


class TenantMiddleware(BaseHTTPMiddleware):
    """Middleware to extract and validate tenant context."""

    async def dispatch(self, request: Request, call_next):
        """Process request and inject tenant context."""
        # Skip tenant validation for health and docs endpoints
        if request.url.path in ["/health", "/readiness", "/docs", "/openapi.json", "/redoc"]:
            return await call_next(request)

        # Extract tenant_id from header
        tenant_id = request.headers.get("X-Tenant-ID")

        if not tenant_id:
            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={"detail": "Missing X-Tenant-ID header"},
            )

        # Store tenant_id in request state for use in endpoints
        request.state.tenant_id = tenant_id

        response = await call_next(request)
        return response
