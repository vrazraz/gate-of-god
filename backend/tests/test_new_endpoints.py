import pytest
from httpx import AsyncClient, ASGITransport

from main import app


@pytest.fixture
def anyio_backend():
    return "asyncio"


@pytest.mark.asyncio
async def test_get_progress_without_db():
    """Progress endpoint returns default data when DB is unavailable."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.get("/api/player/00000000-0000-0000-0000-000000000001/progress")
    assert resp.status_code == 200
    data = resp.json()
    assert data["player"]["id"] == "00000000-0000-0000-0000-000000000001"
    assert data["vocabulary"]["total_words_seen"] == 0
    assert data["runs"] == []


@pytest.mark.asyncio
async def test_save_progress_without_db():
    """Save progress returns success even without DB (graceful fallback)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.post("/api/player/00000000-0000-0000-0000-000000000001/progress", json={
            "event_type": "combat_end",
            "run_data": {"floor": 3, "deck": [], "relics": [], "hp": 80, "max_hp": 100},
            "combat_stats": {"perfect_count": 2, "correct_count": 5, "mistake_count": 1},
        })
    assert resp.status_code == 200
    data = resp.json()
    assert data["saved"] is True


@pytest.mark.asyncio
async def test_spaced_repetition_update():
    """Spaced repetition update endpoint works without DB."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.post("/api/spaced-repetition/update", json={
            "player_id": "00000000-0000-0000-0000-000000000001",
            "word": "ubiquitous",
            "quality_score": 5,
        })
    assert resp.status_code == 200
    data = resp.json()
    assert data["word"] == "ubiquitous"
    assert data["streak"] == 1
    assert data["new_interval_days"] == 1.0
    assert "next_review" in data
