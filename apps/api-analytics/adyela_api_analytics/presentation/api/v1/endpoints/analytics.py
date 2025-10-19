"""Analytics endpoints."""

from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel

from adyela_api_analytics.application.use_cases.get_dashboard_metrics import (
    GetDashboardMetricsUseCase,
)
from adyela_api_analytics.application.use_cases.track_event import TrackEventUseCase
from adyela_api_analytics.domain.entities import EventType
from adyela_api_analytics.domain.exceptions import BigQueryError, EventProcessingError

router = APIRouter()


class TrackEventRequest(BaseModel):
    """Request model for tracking events."""

    event_type: EventType
    tenant_id: str
    entity_id: str
    user_id: str | None = None
    properties: dict | None = None
    metadata: dict | None = None


class EventResponse(BaseModel):
    """Response model for events."""

    event_id: str
    event_type: str
    timestamp: datetime
    tenant_id: str
    entity_id: str


class DashboardMetricsResponse(BaseModel):
    """Response model for dashboard metrics."""

    total_appointments: int
    confirmed_appointments: int
    cancelled_appointments: int
    total_revenue: float
    revenue_this_month: float
    total_professionals: int
    active_professionals: int
    total_patients: int
    active_patients: int
    notifications_sent_today: int
    conversion_rate: float
    period_start: datetime
    period_end: datetime


# Dependency injection - these would be provided by the main app
def get_track_event_use_case() -> TrackEventUseCase:
    """Get track event use case."""
    from google.cloud import firestore

    from adyela_api_analytics.config import settings
    from adyela_api_analytics.infrastructure.bigquery.client import BigQueryClient
    from adyela_api_analytics.infrastructure.repositories.firestore_event_repository import (
        FirestoreEventRepository,
    )

    db = firestore.Client(project=settings.gcp_project_id)
    event_repository = FirestoreEventRepository(db)
    bigquery_client = BigQueryClient(settings.gcp_project_id, settings.bigquery_dataset)

    return TrackEventUseCase(event_repository, bigquery_client)


def get_dashboard_metrics_use_case() -> GetDashboardMetricsUseCase:
    """Get dashboard metrics use case."""
    from adyela_api_analytics.config import settings
    from adyela_api_analytics.infrastructure.bigquery.client import BigQueryClient

    bigquery_client = BigQueryClient(settings.gcp_project_id, settings.bigquery_dataset)
    return GetDashboardMetricsUseCase(bigquery_client)


@router.post("/events", response_model=EventResponse, status_code=201)
async def track_event(
    request: TrackEventRequest,
    use_case: TrackEventUseCase = Depends(get_track_event_use_case),
) -> EventResponse:
    """Track an analytics event."""
    try:
        event = await use_case.execute(
            event_type=request.event_type,
            tenant_id=request.tenant_id,
            entity_id=request.entity_id,
            user_id=request.user_id,
            properties=request.properties,
            metadata=request.metadata,
        )

        return EventResponse(
            event_id=event.event_id,
            event_type=event.event_type.value,
            timestamp=event.timestamp,
            tenant_id=event.tenant_id,
            entity_id=event.entity_id,
        )

    except EventProcessingError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except BigQueryError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")


@router.get("/dashboard", response_model=DashboardMetricsResponse)
async def get_dashboard_metrics(
    tenant_id: str | None = Query(None, description="Filter by tenant ID"),
    days: int = Query(30, ge=1, le=365, description="Number of days to include"),
    use_case: GetDashboardMetricsUseCase = Depends(get_dashboard_metrics_use_case),
) -> DashboardMetricsResponse:
    """Get dashboard metrics."""
    try:
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)

        metrics = await use_case.execute(
            tenant_id=tenant_id, start_date=start_date, end_date=end_date
        )

        return DashboardMetricsResponse(
            total_appointments=metrics.total_appointments,
            confirmed_appointments=metrics.confirmed_appointments,
            cancelled_appointments=metrics.cancelled_appointments,
            total_revenue=metrics.total_revenue,
            revenue_this_month=metrics.revenue_this_month,
            total_professionals=metrics.total_professionals,
            active_professionals=metrics.active_professionals,
            total_patients=metrics.total_patients,
            active_patients=metrics.active_patients,
            notifications_sent_today=metrics.notifications_sent_today,
            conversion_rate=metrics.conversion_rate,
            period_start=metrics.period_start,
            period_end=metrics.period_end,
        )

    except BigQueryError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
