import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    APP_NAME: str = "MyJournal API"
    APP_ENV: str = os.getenv("ENVIRONMENT", "development")
    PORT: int = int(os.getenv("PORT", 8000))
    FRONTEND_URL: str = os.getenv("FRONTEND_URL", "http://localhost:3000")
    
    # SMTP Config
    SMTP_HOST: str = os.getenv("SMTP_HOST", "smtp.gmail.com")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", 587))
    SMTP_USER: str = os.getenv("SMTP_USER", "")
    SMTP_PASS: str = os.getenv("SMTP_PASS", "")
    SMTP_FROM_NAME: str = "MyJournal App"

    # --- Security, Storage & API Keys ---
    GOOGLE_STORAGE_BUCKET: str = os.getenv("GOOGLE_STORAGE_BUCKET", "my-journal.appspot.com")
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    JWT_SECRET: str = "myjournal-super-secret-key-development"
    JWT_ALGORITHM: str = "HS256"
    
    # Konfigurasi keamanan
    CORS_ORIGINS: list[str] = [FRONTEND_URL]
    if APP_ENV == "development":
        CORS_ORIGINS.extend([
            f"http://localhost:{PORT}",
            f"http://127.0.0.1:{PORT}"
        ])

    model_config = SettingsConfigDict(
        env_file=os.getenv("ENV_PATH", "app/config/env/Development.env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
