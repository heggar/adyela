"""Use case for getting dashboard metrics."""

from datetime import datetime

from adyela_api_analytics.application.ports import BigQueryClient
from adyela_api_analytics.domain.entities import (
    AggregationPeriod,
    DashboardMetrics,
    MetricType,
)


class GetDashboardMetricsUseCase:
    """Use case for retrieving dashboard metrics."""

    def __init__(self, bigquery_client: BigQueryClient) -> None:
        self.bigquery_client = bigquery_client

    async def execute(
        self, tenant_id: str | None, start_date: datetime, end_date: datetime
    ) -> DashboardMetrics:
        """Execute the use case to get dashboard metrics."""

        # Aggregate appointments
        appointments_metrics = await self.bigquery_client.aggregate_metrics(
            metric_type=MetricType.APPOINTMENTS_BY_STATUS,
            period=AggregationPeriod.DAY,
            start_date=start_date,
            end_date=end_date,
            tenant_id=tenant_id,
        )

        # Calculate appointment counts
        total_appointments = sum(m.get("count", 0) for m in appointments_metrics)
        confirmed_appointments = sum(
            m.get("count", 0) for m in appointments_metrics if m.get("status") == "confirmed"
        )
        cancelled_appointments = sum(
            m.get("count", 0) for m in appointments_metrics if m.get("status") == "cancelled"
        )

        # Aggregate revenue
        revenue_metrics = await self.bigquery_client.aggregate_metrics(
            metric_type=MetricType.REVENUE_TOTAL,
            period=AggregationPeriod.MONTH,
            start_date=start_date,
            end_date=end_date,
            tenant_id=tenant_id,
        )

        total_revenue = sum(m.get("revenue", 0) for m in revenue_metrics)

        # Get current month revenue
        current_month_metrics = await self.bigquery_client.aggregate_metrics(
            metric_type=MetricType.REVENUE_BY_PERIOD,
            period=AggregationPeriod.MONTH,
            start_date=datetime.now().replace(day=1, hour=0, minute=0, second=0),
            end_date=end_date,
            tenant_id=tenant_id,
        )

        revenue_this_month = sum(m.get("revenue", 0) for m in current_month_metrics)

        # Get professionals count
        professionals_metrics = await self.bigquery_client.aggregate_metrics(
            metric_type=MetricType.PROFESSIONALS_COUNT,
            period=AggregationPeriod.DAY,
            start_date=start_date,
            end_date=end_date,
            tenant_id=tenant_id,
        )

        total_professionals = max((m.get("count", 0) for m in professionals_metrics), default=0)
        active_professionals = max(
            (m.get("active_count", 0) for m in professionals_metrics), default=0
        )

        # Get patients count
        patients_metrics = await self.bigquery_client.aggregate_metrics(
            metric_type=MetricType.PATIENTS_COUNT,
            period=AggregationPeriod.DAY,
            start_date=start_date,
            end_date=end_date,
            tenant_id=tenant_id,
        )

        total_patients = max((m.get("count", 0) for m in patients_metrics), default=0)
        active_patients = max((m.get("active_count", 0) for m in patients_metrics), default=0)

        # Get notifications sent today
        notifications_metrics = await self.bigquery_client.aggregate_metrics(
            metric_type=MetricType.NOTIFICATIONS_SENT,
            period=AggregationPeriod.DAY,
            start_date=datetime.now().replace(hour=0, minute=0, second=0),
            end_date=end_date,
            tenant_id=tenant_id,
        )

        notifications_sent_today = sum(m.get("count", 0) for m in notifications_metrics)

        # Calculate conversion rate (confirmed / total appointments)
        conversion_rate = (
            (confirmed_appointments / total_appointments * 100) if total_appointments > 0 else 0.0
        )

        return DashboardMetrics(
            total_appointments=total_appointments,
            confirmed_appointments=confirmed_appointments,
            cancelled_appointments=cancelled_appointments,
            total_revenue=total_revenue,
            revenue_this_month=revenue_this_month,
            total_professionals=total_professionals,
            active_professionals=active_professionals,
            total_patients=total_patients,
            active_patients=active_patients,
            notifications_sent_today=notifications_sent_today,
            conversion_rate=conversion_rate,
            period_start=start_date,
            period_end=end_date,
        )
