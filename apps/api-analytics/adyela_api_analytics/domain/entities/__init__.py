"""Domain entities for analytics."""

from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Any


class EventType(str, Enum):
    """Event types for analytics."""

    APPOINTMENT_CREATED = "appointment_created"
    APPOINTMENT_CONFIRMED = "appointment_confirmed"
    APPOINTMENT_CANCELLED = "appointment_cancelled"
    APPOINTMENT_COMPLETED = "appointment_completed"
    PAYMENT_CREATED = "payment_created"
    PAYMENT_SUCCEEDED = "payment_succeeded"
    PAYMENT_FAILED = "payment_failed"
    NOTIFICATION_SENT = "notification_sent"
    NOTIFICATION_DELIVERED = "notification_delivered"
    NOTIFICATION_FAILED = "notification_failed"
    PROFESSIONAL_REGISTERED = "professional_registered"
    PROFESSIONAL_APPROVED = "professional_approved"
    PATIENT_REGISTERED = "patient_registered"


class MetricType(str, Enum):
    """Metric types for analytics."""

    APPOINTMENTS_COUNT = "appointments_count"
    APPOINTMENTS_BY_STATUS = "appointments_by_status"
    REVENUE_TOTAL = "revenue_total"
    REVENUE_BY_PERIOD = "revenue_by_period"
    PROFESSIONALS_COUNT = "professionals_count"
    PATIENTS_COUNT = "patients_count"
    NOTIFICATIONS_SENT = "notifications_sent"
    CONVERSION_RATE = "conversion_rate"


class AggregationPeriod(str, Enum):
    """Aggregation periods for metrics."""

    HOUR = "hour"
    DAY = "day"
    WEEK = "week"
    MONTH = "month"
    YEAR = "year"


@dataclass
class Event:
    """Event entity for analytics tracking."""

    event_id: str
    event_type: EventType
    timestamp: datetime
    tenant_id: str
    user_id: str | None
    entity_id: str  # appointment_id, payment_id, etc.
    properties: dict[str, Any]
    metadata: dict[str, str]


@dataclass
class Metric:
    """Metric entity for aggregated analytics."""

    metric_id: str
    metric_type: MetricType
    value: float
    period: AggregationPeriod
    period_start: datetime
    period_end: datetime
    tenant_id: str | None
    dimensions: dict[str, Any]
    created_at: datetime
    updated_at: datetime


@dataclass
class DashboardMetrics:
    """Dashboard metrics summary."""

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
