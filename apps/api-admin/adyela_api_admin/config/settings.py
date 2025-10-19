"""Application settings."""

from functools import lru_cache

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
    app_name: str = "Adyela Admin API"
    app_version: str = "0.1.0"
    debug: bool = False
    environment: str = "development"

    # API
    api_prefix: str = "/api/v1"
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:5173"]

    # Google Cloud
    gcp_project_id: str
    firestore_database: str = "(default)"

    # Auth Service
    auth_service_url: str = "http://localhost:8001"
    auth_validate_token_endpoint: str = "/api/v1/auth/validate-token"

    # Security
    allowed_hosts: list[str] = ["*"]
    require_admin_role: bool = True

    # Logging
    log_level: str = "INFO"
    json_logs: bool = True


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
