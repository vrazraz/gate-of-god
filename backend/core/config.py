from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://lexica:devpassword@localhost:5432/lexica_spire"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = True

    DICTIONARY_API_URL: str = "https://api.dictionaryapi.dev/api/v2/entries/en"
    LANGUAGE_TOOL_ENABLED: bool = True

    DEFAULT_CEFR_LEVEL: str = "B1"
    CHALLENGE_TIME_LIMIT_DEFAULT: int = 10
    SPACED_REPETITION_ENABLED: bool = True

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
