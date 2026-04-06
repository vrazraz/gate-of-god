import asyncpg
from loguru import logger

from core.config import settings

_pool: asyncpg.Pool | None = None


def _get_asyncpg_url() -> str:
    url = settings.DATABASE_URL
    if url.startswith("postgresql+asyncpg://"):
        url = url.replace("postgresql+asyncpg://", "postgresql://", 1)
    return url


async def init_db_pool():
    global _pool
    try:
        _pool = await asyncpg.create_pool(
            _get_asyncpg_url(),
            min_size=2,
            max_size=10,
        )
        logger.info("Database connection pool created")
    except Exception as e:
        logger.warning(f"Could not connect to database: {e}. Running without DB.")
        _pool = None


async def close_db_pool():
    global _pool
    if _pool:
        await _pool.close()
        logger.info("Database connection pool closed")
        _pool = None


async def get_db() -> asyncpg.Pool | None:
    return _pool
