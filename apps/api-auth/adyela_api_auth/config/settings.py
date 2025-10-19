"""
Application settings and configuration
"""
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # Environment
    ENVIRONMENT: str = "development"
    PROJECT_ID: str = "adyela-staging"
    REGION: str = "us-central1"

    # API Configuration
    API_VERSION: str = "v1"
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"

    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "https://staging.adyela.care",
        "https://admin.staging.adyela.care",
    ]

    # Firestore
    FIRESTORE_DATABASE: str = "(default)"

    # JWT Configuration
    JWT_SECRET: str = "dev-secret-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Firebase Auth
    FIREBASE_API_KEY: str = ""
    FIREBASE_PROJECT_ID: str = "adyela-staging"

    # Password Hashing
    BCRYPT_ROUNDS: int = 12

    # Rate Limiting
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_LOGIN: int = 5  # attempts per minute
    RATE_LIMIT_REGISTER: int = 3  # attempts per minute

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
