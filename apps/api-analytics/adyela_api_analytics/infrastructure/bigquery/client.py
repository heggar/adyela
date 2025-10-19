"""BigQuery client implementation."""

from datetime import datetime

from google.cloud import bigquery

from adyela_api_analytics.application.ports import BigQueryClient as IBigQueryClient
from adyela_api_analytics.domain.entities import (
    AggregationPeriod,
    Event,
    EventType,
    Metric,
    MetricType,
)
from adyela_api_analytics.domain.exceptions import BigQueryError


class BigQueryClient(IBigQueryClient):
    """BigQuery client for analytics data."""

    def __init__(self, project_id: str, dataset: str) -> None:
        self.client = bigquery.Client(project=project_id)
        self.project_id = project_id
        self.dataset = dataset

    async def insert_event(self, event: Event) -> None:
        """Insert an event into BigQuery."""
        try:
            table_id = f"{self.project_id}.{self.dataset}.events"

            rows_to_insert = [
                {
                    "event_id": event.event_id,
                    "event_type": event.event_type.value,
                    "timestamp": event.timestamp.isoformat(),
                    "tenant_id": event.tenant_id,
                    "user_id": event.user_id,
                    "entity_id": event.entity_id,
                    "properties": str(event.properties),
                    "metadata": str(event.metadata),
                }
            ]

            errors = self.client.insert_rows_json(table_id, rows_to_insert)
            if errors:
                raise BigQueryError(f"Failed to insert event: {errors}")

        except Exception as e:
            raise BigQueryError(f"Failed to insert event: {str(e)}")

    async def insert_metric(self, metric: Metric) -> None:
        """Insert a metric into BigQuery."""
        try:
            table_id = f"{self.project_id}.{self.dataset}.metrics"

            rows_to_insert = [
                {
                    "metric_id": metric.metric_id,
                    "metric_type": metric.metric_type.value,
                    "value": metric.value,
                    "period": metric.period.value,
                    "period_start": metric.period_start.isoformat(),
                    "period_end": metric.period_end.isoformat(),
                    "tenant_id": metric.tenant_id,
                    "dimensions": str(metric.dimensions),
                    "created_at": metric.created_at.isoformat(),
                    "updated_at": metric.updated_at.isoformat(),
                }
            ]

            errors = self.client.insert_rows_json(table_id, rows_to_insert)
            if errors:
                raise BigQueryError(f"Failed to insert metric: {errors}")

        except Exception as e:
            raise BigQueryError(f"Failed to insert metric: {str(e)}")

    async def query_events(
        self,
        event_type: EventType | None,
        start_date: datetime,
        end_date: datetime,
        tenant_id: str | None = None,
        limit: int = 100,
    ) -> list[dict]:
        """Query events from BigQuery."""
        try:
            query = f"""
                SELECT *
                FROM `{self.project_id}.{self.dataset}.events`
                WHERE timestamp BETWEEN @start_date AND @end_date
            """

            job_config = bigquery.QueryJobConfig(
                query_parameters=[
                    bigquery.ScalarQueryParameter("start_date", "TIMESTAMP", start_date),
                    bigquery.ScalarQueryParameter("end_date", "TIMESTAMP", end_date),
                ]
            )

            if event_type:
                query += " AND event_type = @event_type"
                job_config.query_parameters.append(
                    bigquery.ScalarQueryParameter("event_type", "STRING", event_type.value)
                )

            if tenant_id:
                query += " AND tenant_id = @tenant_id"
                job_config.query_parameters.append(
                    bigquery.ScalarQueryParameter("tenant_id", "STRING", tenant_id)
                )

            query += f" ORDER BY timestamp DESC LIMIT {limit}"

            query_job = self.client.query(query, job_config=job_config)
            results = query_job.result()

            return [dict(row) for row in results]

        except Exception as e:
            raise BigQueryError(f"Failed to query events: {str(e)}")

    async def aggregate_metrics(
        self,
        metric_type: MetricType,
        period: AggregationPeriod,
        start_date: datetime,
        end_date: datetime,
        tenant_id: str | None = None,
    ) -> list[dict]:
        """Aggregate metrics from BigQuery."""
        try:
            # Build aggregation query based on metric type
            query = self._build_aggregation_query(
                metric_type, period, start_date, end_date, tenant_id
            )

            query_job = self.client.query(query)
            results = query_job.result()

            return [dict(row) for row in results]

        except Exception as e:
            raise BigQueryError(f"Failed to aggregate metrics: {str(e)}")

    def _build_aggregation_query(
        self,
        metric_type: MetricType,
        period: AggregationPeriod,
        start_date: datetime,
        end_date: datetime,
        tenant_id: str | None,
    ) -> str:
        """Build aggregation query based on metric type."""

        base_filters = f"""
            WHERE timestamp BETWEEN '{start_date.isoformat()}' AND '{end_date.isoformat()}'
        """

        if tenant_id:
            base_filters += f" AND tenant_id = '{tenant_id}'"

        # Period formatting
        period_format = {
            AggregationPeriod.HOUR: "%Y-%m-%d %H:00:00",
            AggregationPeriod.DAY: "%Y-%m-%d",
            AggregationPeriod.WEEK: "%Y-W%U",
            AggregationPeriod.MONTH: "%Y-%m",
            AggregationPeriod.YEAR: "%Y",
        }[period]

        if metric_type == MetricType.APPOINTMENTS_COUNT:
            return f"""
                SELECT
                    FORMAT_TIMESTAMP('{period_format}', timestamp) as period,
                    COUNT(*) as count
                FROM `{self.project_id}.{self.dataset}.events`
                {base_filters}
                    AND event_type LIKE 'appointment_%'
                GROUP BY period
                ORDER BY period DESC
            """

        elif metric_type == MetricType.APPOINTMENTS_BY_STATUS:
            return f"""
                SELECT
                    FORMAT_TIMESTAMP('{period_format}', timestamp) as period,
                    JSON_EXTRACT_SCALAR(properties, '$.status') as status,
                    COUNT(*) as count
                FROM `{self.project_id}.{self.dataset}.events`
                {base_filters}
                    AND event_type LIKE 'appointment_%'
                GROUP BY period, status
                ORDER BY period DESC
            """

        elif metric_type == MetricType.REVENUE_TOTAL:
            return f"""
                SELECT
                    SUM(CAST(JSON_EXTRACT_SCALAR(properties, '$.amount') AS FLOAT64)) as revenue
                FROM `{self.project_id}.{self.dataset}.events`
                {base_filters}
                    AND event_type = 'payment_succeeded'
            """

        elif metric_type == MetricType.REVENUE_BY_PERIOD:
            return f"""
                SELECT
                    FORMAT_TIMESTAMP('{period_format}', timestamp) as period,
                    SUM(CAST(JSON_EXTRACT_SCALAR(properties, '$.amount') AS FLOAT64)) as revenue
                FROM `{self.project_id}.{self.dataset}.events`
                {base_filters}
                    AND event_type = 'payment_succeeded'
                GROUP BY period
                ORDER BY period DESC
            """

        else:
            # Default aggregation
            return f"""
                SELECT
                    FORMAT_TIMESTAMP('{period_format}', timestamp) as period,
                    COUNT(*) as count
                FROM `{self.project_id}.{self.dataset}.events`
                {base_filters}
                GROUP BY period
                ORDER BY period DESC
            """
