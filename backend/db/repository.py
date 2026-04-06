"""Database repository layer — asyncpg CRUD for all game entities."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

import asyncpg


# ── Players ──────────────────────────────────────────────────────────

async def get_or_create_player(pool: asyncpg.Pool, player_id: str) -> dict | None:
    """Return existing player or auto-create one with defaults."""
    try:
        pid = uuid.UUID(player_id)
    except ValueError:
        return None

    async with pool.acquire() as conn:
        row = await conn.fetchrow("SELECT * FROM players WHERE id = $1", pid)
        if row:
            return dict(row)

        await conn.execute(
            """
            INSERT INTO players (id, display_name, cefr_level, insight_points,
                                 runs_completed, total_perfect, total_correct, total_mistakes)
            VALUES ($1, 'Player', 'B1', 0, 0, 0, 0, 0)
            """,
            pid,
        )
        row = await conn.fetchrow("SELECT * FROM players WHERE id = $1", pid)
        return dict(row) if row else None


async def get_player(pool: asyncpg.Pool, player_id: str) -> dict | None:
    try:
        pid = uuid.UUID(player_id)
    except ValueError:
        return None
    async with pool.acquire() as conn:
        row = await conn.fetchrow("SELECT * FROM players WHERE id = $1", pid)
        return dict(row) if row else None


async def update_player_stats(
    pool: asyncpg.Pool,
    player_id: str,
    *,
    perfect_delta: int = 0,
    correct_delta: int = 0,
    mistake_delta: int = 0,
    insight_delta: int = 0,
    cefr_level: str | None = None,
) -> None:
    pid = uuid.UUID(player_id)
    async with pool.acquire() as conn:
        await conn.execute(
            """
            UPDATE players
            SET total_perfect  = total_perfect  + $2,
                total_correct  = total_correct  + $3,
                total_mistakes = total_mistakes + $4,
                insight_points = insight_points + $5,
                cefr_level     = COALESCE($6, cefr_level),
                updated_at     = NOW()
            WHERE id = $1
            """,
            pid, perfect_delta, correct_delta, mistake_delta, insight_delta, cefr_level,
        )


async def increment_runs_completed(pool: asyncpg.Pool, player_id: str) -> None:
    pid = uuid.UUID(player_id)
    async with pool.acquire() as conn:
        await conn.execute(
            "UPDATE players SET runs_completed = runs_completed + 1, updated_at = NOW() WHERE id = $1",
            pid,
        )


# ── Vocabulary Stats ─────────────────────────────────────────────────

async def get_vocabulary_stat(pool: asyncpg.Pool, player_id: str, word: str) -> dict | None:
    pid = uuid.UUID(player_id)
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM vocabulary_stats WHERE player_id = $1 AND word = $2",
            pid, word,
        )
        return dict(row) if row else None


async def upsert_vocabulary_stat(
    pool: asyncpg.Pool,
    player_id: str,
    word: str,
    *,
    correct_delta: int = 0,
    mistake_delta: int = 0,
    streak: int,
    interval_days: float,
    easiness_factor: float,
    next_review: str,
    last_seen: str,
    cefr_level: str | None = None,
) -> None:
    pid = uuid.UUID(player_id)
    next_rev = datetime.fromisoformat(next_review)
    last_s = datetime.fromisoformat(last_seen)

    async with pool.acquire() as conn:
        await conn.execute(
            """
            INSERT INTO vocabulary_stats
                (player_id, word, correct_count, mistake_count, streak,
                 interval_days, easiness_factor, next_review, last_seen, cefr_level)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            ON CONFLICT (player_id, word) DO UPDATE SET
                correct_count  = vocabulary_stats.correct_count  + $3,
                mistake_count  = vocabulary_stats.mistake_count  + $4,
                streak         = $5,
                interval_days  = $6,
                easiness_factor = $7,
                next_review    = $8,
                last_seen      = $9,
                cefr_level     = COALESCE($10, vocabulary_stats.cefr_level)
            """,
            pid, word, correct_delta, mistake_delta, streak,
            interval_days, easiness_factor, next_rev, last_s, cefr_level,
        )


async def get_due_words(pool: asyncpg.Pool, player_id: str, limit: int = 10) -> list[dict]:
    pid = uuid.UUID(player_id)
    now = datetime.now(timezone.utc)
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT * FROM vocabulary_stats
            WHERE player_id = $1 AND next_review <= $2
            ORDER BY next_review ASC
            LIMIT $3
            """,
            pid, now, limit,
        )
        return [dict(r) for r in rows]


async def get_vocabulary_summary(pool: asyncpg.Pool, player_id: str) -> dict:
    """Return aggregate vocabulary info for the progress endpoint."""
    pid = uuid.UUID(player_id)
    now = datetime.now(timezone.utc)
    async with pool.acquire() as conn:
        total = await conn.fetchval(
            "SELECT COUNT(*) FROM vocabulary_stats WHERE player_id = $1", pid
        )
        mastered = await conn.fetchval(
            "SELECT COUNT(*) FROM vocabulary_stats WHERE player_id = $1 AND streak >= 5", pid
        )
        due = await conn.fetchval(
            "SELECT COUNT(*) FROM vocabulary_stats WHERE player_id = $1 AND next_review <= $2",
            pid, now,
        )
        struggling_rows = await conn.fetch(
            """
            SELECT word FROM vocabulary_stats
            WHERE player_id = $1 AND mistake_count > correct_count
            ORDER BY mistake_count DESC LIMIT 10
            """,
            pid,
        )
        return {
            "total_words_seen": total or 0,
            "mastered_words": mastered or 0,
            "due_for_review": due or 0,
            "struggling_words": [r["word"] for r in struggling_rows],
        }


# ── Run History ──────────────────────────────────────────────────────

async def create_run(pool: asyncpg.Pool, player_id: str, data: dict) -> str:
    """Insert a new run record. Returns the new run id."""
    pid = uuid.UUID(player_id)
    run_id = uuid.uuid4()
    rd = data.get("run_data", {})
    cs = data.get("combat_stats", {})
    async with pool.acquire() as conn:
        await conn.execute(
            """
            INSERT INTO run_history
                (id, player_id, cefr_level, deck_json, relics_json,
                 floor_reached, enemies_killed, curses_active, lex_coins_total,
                 perfect_count, correct_count, mistake_count, victory, duration_sec)
            VALUES ($1, $2, $3, $4::jsonb, $5::jsonb,
                    $6, $7, $8, $9,
                    $10, $11, $12, $13, $14)
            """,
            run_id, pid,
            rd.get("cefr_level", "B1"),
            _to_json(rd.get("deck", [])),
            _to_json(rd.get("relics", [])),
            rd.get("floor", 0),
            rd.get("enemies_killed", 0),
            len(rd.get("curses", [])),
            rd.get("lex_coins", 0),
            cs.get("perfect_count", 0),
            cs.get("correct_count", 0),
            cs.get("mistake_count", 0),
            rd.get("victory", False),
            rd.get("duration_sec"),
        )
    return str(run_id)


async def finish_run(pool: asyncpg.Pool, run_id: str) -> None:
    rid = uuid.UUID(run_id)
    async with pool.acquire() as conn:
        await conn.execute(
            "UPDATE run_history SET finished_at = NOW() WHERE id = $1", rid
        )


async def get_recent_runs(pool: asyncpg.Pool, player_id: str, limit: int = 10) -> list[dict]:
    pid = uuid.UUID(player_id)
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT id, victory, floor_reached,
                   perfect_count, correct_count, mistake_count,
                   duration_sec, finished_at
            FROM run_history
            WHERE player_id = $1
            ORDER BY started_at DESC
            LIMIT $2
            """,
            pid, limit,
        )
        result = []
        for r in rows:
            total = (r["correct_count"] or 0) + (r["mistake_count"] or 0)
            accuracy = (r["correct_count"] or 0) / total if total > 0 else 0.0
            result.append({
                "id": str(r["id"]),
                "victory": r["victory"],
                "floor_reached": r["floor_reached"],
                "accuracy": round(accuracy, 2),
                "duration_sec": r["duration_sec"],
                "finished_at": r["finished_at"].isoformat() if r["finished_at"] else None,
            })
        return result


# ── Curse History ────────────────────────────────────────────────────

async def create_curse(
    pool: asyncpg.Pool,
    player_id: str,
    curse_type: str,
    source_word: str,
    intensity: int = 0,
    run_id: str | None = None,
) -> None:
    pid = uuid.UUID(player_id)
    rid = uuid.UUID(run_id) if run_id else None
    async with pool.acquire() as conn:
        await conn.execute(
            """
            INSERT INTO curse_history (player_id, run_id, curse_type, source_word, intensity)
            VALUES ($1, $2, $3, $4, $5)
            """,
            pid, rid, curse_type, source_word, intensity,
        )


# ── Difficulty (recent accuracy) ─────────────────────────────────────

async def get_recent_accuracy(pool: asyncpg.Pool, player_id: str, n: int = 20) -> float | None:
    """Return accuracy of last N vocabulary interactions, or None if no data."""
    pid = uuid.UUID(player_id)
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT correct_count, mistake_count FROM vocabulary_stats
            WHERE player_id = $1 AND last_seen IS NOT NULL
            ORDER BY last_seen DESC LIMIT $2
            """,
            pid, n,
        )
    if not rows:
        return None
    total_c = sum(r["correct_count"] for r in rows)
    total_m = sum(r["mistake_count"] for r in rows)
    total = total_c + total_m
    return total_c / total if total > 0 else None


# ── Helpers ──────────────────────────────────────────────────────────

def _to_json(obj) -> str:
    import json
    return json.dumps(obj)
