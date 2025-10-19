"""Domain exceptions for analytics."""


class EventNotFoundException(Exception):
    """Raised when an event is not found."""

    def __init__(self, event_id: str) -> None:
        self.event_id = event_id
        super().__init__(f"Event with ID {event_id} not found")


class MetricNotFoundException(Exception):
    """Raised when a metric is not found."""

    def __init__(self, metric_id: str) -> None:
        self.metric_id = metric_id
        super().__init__(f"Metric with ID {metric_id} not found")


class InvalidAggregationPeriodError(Exception):
    """Raised when an invalid aggregation period is provided."""

    def __init__(self, period: str) -> None:
        self.period = period
        super().__init__(f"Invalid aggregation period: {period}")


class BigQueryError(Exception):
    """Raised when a BigQuery operation fails."""

    def __init__(self, message: str) -> None:
        super().__init__(f"BigQuery error: {message}")


class EventProcessingError(Exception):
    """Raised when event processing fails."""

    def __init__(self, message: str) -> None:
        super().__init__(f"Event processing error: {message}")
