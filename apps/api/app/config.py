from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    web_origin: str = "http://localhost:3000"
    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/orbit_calendar"
    calendar_provider: str = "local"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
