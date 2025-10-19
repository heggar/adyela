# api-analytics

Analytics and reporting microservice for the Adyela healthcare platform.
Provides BigQuery integration for event tracking and dashboard metrics
aggregation.

## Architecture

This microservice follows **Hexagonal Architecture (Clean Architecture)** with
clear separation of concerns:

```
adyela_api_analytics/
├── domain/              # Business entities and domain logic
│   ├── entities/        # Event, Metric, DashboardMetrics entities
│   └── exceptions/      # Domain-specific exceptions
├── application/         # Use cases and ports (interfaces)
│   ├── ports/           # Repository and client interfaces
│   └── use_cases/       # Business logic orchestration
├── infrastructure/      # External service implementations
│   ├── bigquery/        # BigQuery client implementation
│   └── repositories/    # Firestore event repository
├── presentation/        # HTTP API layer
│   └── api/v1/          # FastAPI endpoints
└── config/              # Configuration and settings
```

## Features

- ✅ **Event Tracking** - Track all platform events in BigQuery
- ✅ **Dashboard Metrics** - Aggregated metrics for reporting
- ✅ **Revenue Reporting** - Payment analytics and revenue tracking
- ✅ **Appointment Analytics** - Appointment metrics and conversion rates
- ✅ **User Metrics** - Professional and patient counts
- ✅ **BigQuery Integration** - Scalable data warehouse for analytics
- ✅ **Firestore Cache** - Quick access to recent events
- ✅ **RESTful API** - FastAPI endpoints for analytics access

## Tech Stack

- **Runtime**: Python 3.12
- **Framework**: FastAPI 0.115+
- **Data Warehouse**: Google BigQuery
- **Database**: Google Cloud Firestore
- **Event Streaming**: Google Cloud Pub/Sub (future)
- **Testing**: Pytest, Pytest-asyncio
- **Code Quality**: Ruff, Black, MyPy

## Prerequisites

- Python >= 3.12
- Google Cloud Project with BigQuery enabled
- Google Cloud Firestore database
- Poetry for dependency management

## Environment Variables

Create a `.env` file with the following variables:

```bash
# Application
ENVIRONMENT=development
DEBUG=true
PORT=3003
API_PREFIX=/api/v1

# Google Cloud
GCP_PROJECT_ID=your-gcp-project-id
GCP_LOCATION=us-central1

# BigQuery
BIGQUERY_DATASET=adyela_analytics
BIGQUERY_EVENTS_TABLE=events
BIGQUERY_METRICS_TABLE=metrics

# Pub/Sub (future)
PUBSUB_SUBSCRIPTION_APPOINTMENTS=appointments-analytics
PUBSUB_SUBSCRIPTION_PAYMENTS=payments-analytics
PUBSUB_SUBSCRIPTION_NOTIFICATIONS=notifications-analytics

# Auth Service
AUTH_SERVICE_URL=http://localhost:8001
AUTH_VALIDATE_TOKEN_ENDPOINT=/api/v1/auth/validate-token

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:5173

# Logging
LOG_LEVEL=INFO
```

## Installation

```bash
# Install Poetry if not already installed
curl -sSL https://install.python-poetry.org | python3 -

# Install dependencies
cd apps/api-analytics
poetry install

# Activate virtual environment
poetry shell
```

## Development

```bash
# Run development server
poetry run uvicorn adyela_api_analytics.main:app --reload --port 3003

# Run tests
poetry run pytest

# Run tests with coverage
poetry run pytest --cov=adyela_api_analytics --cov-report=term-missing

# Lint code
poetry run ruff check .

# Format code
poetry run black .

# Type check
poetry run mypy .
```

## BigQuery Setup

### Create Dataset

```sql
CREATE SCHEMA IF NOT EXISTS adyela_analytics
OPTIONS(
  location="us-central1",
  description="Analytics data for Adyela platform"
);
```

### Create Events Table

```sql
CREATE TABLE adyela_analytics.events (
  event_id STRING NOT NULL,
  event_type STRING NOT NULL,
  timestamp TIMESTAMP NOT NULL,
  tenant_id STRING NOT NULL,
  user_id STRING,
  entity_id STRING NOT NULL,
  properties JSON,
  metadata JSON
)
PARTITION BY DATE(timestamp)
CLUSTER BY tenant_id, event_type;
```

### Create Metrics Table

```sql
CREATE TABLE adyela_analytics.metrics (
  metric_id STRING NOT NULL,
  metric_type STRING NOT NULL,
  value FLOAT64 NOT NULL,
  period STRING NOT NULL,
  period_start TIMESTAMP NOT NULL,
  period_end TIMESTAMP NOT NULL,
  tenant_id STRING,
  dimensions JSON,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY DATE(period_start)
CLUSTER BY tenant_id, metric_type;
```

## API Endpoints

### Health Check

```http
GET /health
```

**Response:**

```json
{
  "status": "healthy",
  "service": "api-analytics",
  "version": "0.1.0"
}
```

---

### Track Event

```http
POST /api/v1/analytics/events
Content-Type: application/json
```

**Request Body:**

```json
{
  "event_type": "appointment_created",
  "tenant_id": "tenant_123",
  "entity_id": "appt_456",
  "user_id": "user_789",
  "properties": {
    "status": "scheduled",
    "date": "2025-01-20",
    "time": "10:00 AM"
  },
  "metadata": {
    "source": "web_app"
  }
}
```

**Response (201):**

```json
{
  "event_id": "event_123",
  "event_type": "appointment_created",
  "timestamp": "2025-01-18T10:00:00Z",
  "tenant_id": "tenant_123",
  "entity_id": "appt_456"
}
```

---

### Get Dashboard Metrics

```http
GET /api/v1/analytics/dashboard?tenant_id=tenant_123&days=30
```

**Response (200):**

```json
{
  "total_appointments": 150,
  "confirmed_appointments": 120,
  "cancelled_appointments": 15,
  "total_revenue": 15000.0,
  "revenue_this_month": 4500.0,
  "total_professionals": 25,
  "active_professionals": 20,
  "total_patients": 300,
  "active_patients": 250,
  "notifications_sent_today": 45,
  "conversion_rate": 80.0,
  "period_start": "2024-12-19T10:00:00Z",
  "period_end": "2025-01-18T10:00:00Z"
}
```

## Event Types

| Event Type                | Description                        |
| ------------------------- | ---------------------------------- |
| `appointment_created`     | New appointment created            |
| `appointment_confirmed`   | Appointment confirmed by provider  |
| `appointment_cancelled`   | Appointment cancelled              |
| `appointment_completed`   | Appointment completed successfully |
| `payment_created`         | Payment intent created             |
| `payment_succeeded`       | Payment completed successfully     |
| `payment_failed`          | Payment failed                     |
| `notification_sent`       | Notification sent                  |
| `notification_delivered`  | Notification delivered             |
| `notification_failed`     | Notification failed                |
| `professional_registered` | Professional account registered    |
| `professional_approved`   | Professional account approved      |
| `patient_registered`      | Patient account registered         |

## Metric Types

| Metric Type              | Description                    | Aggregation           |
| ------------------------ | ------------------------------ | --------------------- |
| `appointments_count`     | Total appointments             | COUNT                 |
| `appointments_by_status` | Appointments grouped by status | COUNT BY status       |
| `revenue_total`          | Total revenue                  | SUM(amount)           |
| `revenue_by_period`      | Revenue per period             | SUM(amount) BY period |
| `professionals_count`    | Total professionals            | COUNT                 |
| `patients_count`         | Total patients                 | COUNT                 |
| `notifications_sent`     | Notifications sent             | COUNT                 |
| `conversion_rate`        | Appointment conversion rate    | confirmed / total     |

## Aggregation Periods

- `hour` - Hourly aggregation
- `day` - Daily aggregation
- `week` - Weekly aggregation
- `month` - Monthly aggregation
- `year` - Yearly aggregation

## Testing

```bash
# Run all tests
poetry run pytest

# Run with coverage
poetry run pytest --cov=adyela_api_analytics --cov-report=html

# Run specific test file
poetry run pytest tests/unit/test_track_event_use_case.py

# Run with verbose output
poetry run pytest -v
```

### Test Coverage

- Unit tests for use cases
- Mock implementations for BigQuery and Firestore
- Async test support with pytest-asyncio

## Integration with Other Services

### Event Sources

Events are tracked from:

- **api-appointments** - Appointment lifecycle events
- **api-payments** - Payment events
- **api-notifications** - Notification delivery events
- **api-admin** - Professional approval events

### Future: Pub/Sub Integration

Events will be consumed automatically via Pub/Sub subscriptions:

```python
# Subscribe to appointment events
pubsub.subscription('appointments-analytics').on('message', async message => {
  event = parse_event(message)
  await track_event_use_case.execute(
    event_type=event.type,
    tenant_id=event.tenant_id,
    entity_id=event.entity_id,
    properties=event.properties
  )
  message.ack()
})
```

## BigQuery Queries

### Revenue by Month

```sql
SELECT
  FORMAT_TIMESTAMP('%Y-%m', timestamp) as month,
  SUM(CAST(JSON_EXTRACT_SCALAR(properties, '$.amount') AS FLOAT64)) as revenue
FROM `adyela_analytics.events`
WHERE event_type = 'payment_succeeded'
  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 12 MONTH)
GROUP BY month
ORDER BY month DESC;
```

### Appointment Conversion Rate

```sql
SELECT
  COUNT(*) as total,
  COUNTIF(JSON_EXTRACT_SCALAR(properties, '$.status') = 'confirmed') as confirmed,
  COUNTIF(JSON_EXTRACT_SCALAR(properties, '$.status') = 'confirmed') / COUNT(*) * 100 as conversion_rate
FROM `adyela_analytics.events`
WHERE event_type LIKE 'appointment_%'
  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);
```

## Error Handling

Domain-specific exceptions:

- `EventNotFoundException` - Event not found (404)
- `MetricNotFoundException` - Metric not found (404)
- `InvalidAggregationPeriodError` - Invalid period (400)
- `BigQueryError` - BigQuery operation failed (500)
- `EventProcessingError` - Event processing failed (422)

## Security Considerations

- ✅ **Authentication required** - All endpoints require valid JWT (future)
- ✅ **Tenant isolation** - Data filtered by tenant_id
- ✅ **Input validation** - Pydantic models validate all inputs
- ⚠️ **PHI protection** - Ensure no PHI in event properties
- ✅ **BigQuery IAM** - Proper service account permissions

## Performance Considerations

- **Partitioning**: Tables partitioned by date for efficient queries
- **Clustering**: Clustered by tenant_id and event_type
- **Batch Inserts**: Events batched for BigQuery insertion
- **Caching**: Recent events cached in Firestore
- **Indexes**: Firestore composite indexes for common queries

## Future Enhancements

- [ ] Real-time dashboards with streaming inserts
- [ ] Pub/Sub event consumption
- [ ] Custom report builder
- [ ] Data export (CSV, Excel)
- [ ] Scheduled reports via email
- [ ] Anomaly detection
- [ ] Predictive analytics
- [ ] A/B testing analytics

## License

UNLICENSED - Private use only

---

**Maintained by**: Adyela Development Team **Version**: 0.1.0 **Last Updated**:
2025-01-18
