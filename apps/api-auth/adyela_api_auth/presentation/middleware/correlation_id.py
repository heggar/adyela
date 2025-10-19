"""
Correlation ID middleware for distributed tracing
"""
import uuid
from typing import Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware


class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """
    Add correlation ID to requests for distributed tracing.

    The correlation ID is:
    1. Read from X-Correlation-ID header if present
    2. Generated as new UUID if not present
    3. Added to response headers
    4. Stored in request state for logging

    This enables tracing requests across multiple microservices.
    """

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Get or generate correlation ID
        correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))

        # Store in request state
        request.state.correlation_id = correlation_id

        # Process request
        response = await call_next(request)

        # Add to response headers
        response.headers["X-Correlation-ID"] = correlation_id

        return response
