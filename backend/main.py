from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from api.deps import init_db_pool, close_db_pool
from api.routes import validate, challenge, progress, vocabulary, spaced_repetition
from core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting Lexica Spire Backend...")
    await init_db_pool()
    logger.info(f"Connected to database, server running on port {settings.PORT}")
    yield
    await close_db_pool()
    logger.info("Shutting down Lexica Spire Backend.")


app = FastAPI(
    title="Lexica Spire API",
    description="Backend for the Lexica Spire educational roguelike deck-builder",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(validate.router, prefix="/api", tags=["Validation"])
app.include_router(challenge.router, prefix="/api", tags=["Challenges"])
app.include_router(progress.router, prefix="/api", tags=["Progress"])
app.include_router(vocabulary.router, prefix="/api", tags=["Vocabulary"])
app.include_router(spaced_repetition.router, prefix="/api", tags=["Spaced Repetition"])


@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "0.1.0"}
