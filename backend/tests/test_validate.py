import pytest
from httpx import AsyncClient, ASGITransport

from main import app


@pytest.fixture
def anyio_backend():
    return "asyncio"


@pytest.mark.asyncio
async def test_validate_correct_answer():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.post("/api/validate-answer", json={
            "player_id": "test-player-1",
            "challenge_type": "vocabulary",
            "challenge_id": "ch_test01",
            "user_answer": "Found everywhere",
            "correct_answer": "Found everywhere",
            "time_taken": 3.0,
            "word": "ubiquitous",
            "card_id": "vocab_strike_01",
        })
    assert resp.status_code == 200
    data = resp.json()
    assert data["correct"] is True
    assert data["quality"] == "correct"
    assert data["effect_modifier"] == 1.0
    assert data["curse_added"] is None


@pytest.mark.asyncio
async def test_validate_perfect_answer():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.post("/api/validate-answer", json={
            "player_id": "test-player-1",
            "challenge_type": "vocabulary",
            "challenge_id": "ch_test02",
            "user_answer": "Found everywhere",
            "correct_answer": "Found everywhere",
            "time_taken": 1.0,
            "word": "ubiquitous",
            "card_id": "vocab_strike_01",
        })
    assert resp.status_code == 200
    data = resp.json()
    assert data["correct"] is True
    assert data["quality"] == "perfect"
    assert data["effect_modifier"] == 1.25


@pytest.mark.asyncio
async def test_validate_wrong_answer():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.post("/api/validate-answer", json={
            "player_id": "test-player-1",
            "challenge_type": "vocabulary",
            "challenge_id": "ch_test03",
            "user_answer": "Rare and valuable",
            "correct_answer": "Found everywhere",
            "time_taken": 5.0,
            "word": "ubiquitous",
            "card_id": "vocab_strike_01",
        })
    assert resp.status_code == 200
    data = resp.json()
    assert data["correct"] is False
    assert data["quality"] == "mistake"
    assert data["effect_modifier"] == 0.0
    assert data["curse_added"] is not None


@pytest.mark.asyncio
async def test_generate_vocabulary_challenge():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.post("/api/generate-challenge", json={
            "player_id": "test-player-1",
            "card_id": "vocab_strike_01",
            "challenge_type": "vocabulary",
            "difficulty": "B1",
        })
    assert resp.status_code == 200
    data = resp.json()
    assert data["type"] == "vocabulary"
    assert data["input_type"] == "multiple_choice"
    assert len(data["options"]) == 4
    assert data["word"] is not None


@pytest.mark.asyncio
async def test_generate_grammar_challenge():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.post("/api/generate-challenge", json={
            "player_id": "test-player-1",
            "card_id": "grammar_strike_01",
            "challenge_type": "grammar",
            "difficulty": "B1",
        })
    assert resp.status_code == 200
    data = resp.json()
    assert data["type"] == "grammar"
    assert data["input_type"] == "text"
    assert data["correct_answer"] is not None


@pytest.mark.asyncio
async def test_health_check():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"
