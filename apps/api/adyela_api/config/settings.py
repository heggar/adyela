"""Application settings and configuration."""

from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    app_name: str = "Adyela API"
    app_version: str = "0.1.0"
    environment: Literal["development", "staging", "production"] = "development"
    debug: bool = False
    log_level: str = "INFO"

    # API
    api_v1_prefix: str = "/api/v1"
    allowed_hosts_str: str = Field(default="*", alias="ALLOWED_HOSTS")
    cors_origins_str: str = Field(default="http://localhost:3000", alias="CORS_ORIGINS")

    @property
    def allowed_hosts(self) -> list[str]:
        """Parse allowed hosts from comma-separated string."""
        return [host.strip() for host in self.allowed_hosts_str.split(",") if host.strip()]

    @property
    def cors_origins(self) -> list[str]:
        """Parse CORS origins from comma-separated string."""
        return [origin.strip() for origin in self.cors_origins_str.split(",") if origin.strip()]

    # Server
    host: str = (
        "0.0.0.0"  # nosec B104 - Required for Docker containers, GCP controls external access
    )
    port: int = 8000
    workers: int = 4

    # Security
    secret_key: SecretStr = Field(..., description="Secret key for JWT encoding")
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    # Firebase
    firebase_project_id: str = Field(..., description="Firebase project ID")
    firebase_credentials_path: str | None = Field(
        None, description="Path to Firebase credentials JSON"
    )
    firebase_api_key: str | None = None

    # Google Cloud
    gcp_project_id: str = Field(..., description="GCP project ID")
    gcp_region: str = "us-central1"
    use_secret_manager: bool = False

    # Firestore
    firestore_emulator_host: str | None = None

    # Redis
    redis_url: str = "redis://localhost:6379/0"
    redis_max_connections: int = 10

    # Rate Limiting
    rate_limit_enabled: bool = True
    rate_limit_per_minute: int = 60
    rate_limit_per_hour: int = 1000

    # Twilio
    twilio_account_sid: SecretStr | None = None
    twilio_auth_token: SecretStr | None = None
    twilio_phone_number: str | None = None

    # SendGrid
    sendgrid_api_key: SecretStr | None = None
    sendgrid_from_email: str | None = None

    # Jitsi
    jitsi_domain: str = "meet.jit.si"
    jitsi_app_id: str | None = None
    jitsi_api_key: SecretStr | None = None

    # Sentry
    sentry_dsn: str | None = None
    sentry_traces_sample_rate: float = 0.1
    sentry_environment: str | None = None

    # Database
    database_pool_size: int = 20
    database_max_overflow: int = 10
    database_pool_timeout: int = 30

    @property
    def is_development(self) -> bool:
        """Check if running in development mode."""
        return self.environment == "development"

    @property
    def is_production(self) -> bool:
        """Check if running in production mode."""
        return self.environment == "production"


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()  # type: ignore[call-arg]
