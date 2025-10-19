"""Configuration module for api-analytics."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    app_name: str = "adyela-api-analytics"
    environment: str = "development"
    debug: bool = True
    port: int = 3003
    host: str = "0.0.0.0"
    api_prefix: str = "/api/v1"

    # Google Cloud
    gcp_project_id: str
    gcp_location: str = "us-central1"

    # BigQuery
    bigquery_dataset: str = "adyela_analytics"
    bigquery_events_table: str = "events"
    bigquery_metrics_table: str = "metrics"

    # Pub/Sub
    pubsub_subscription_appointments: str = "appointments-analytics"
    pubsub_subscription_payments: str = "payments-analytics"
    pubsub_subscription_notifications: str = "notifications-analytics"

    # Auth Service
    auth_service_url: str = "http://localhost:8001"
    auth_validate_token_endpoint: str = "/api/v1/auth/validate-token"

    # CORS
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:5173"]

    # Logging
    log_level: str = "INFO"


settings = Settings()
