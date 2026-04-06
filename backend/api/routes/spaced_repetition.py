from fastapi import APIRouter
from pydantic import BaseModel

from api.deps import get_db
from core.spaced_repetition import calculate_next_review
from db.repository import get_or_create_player, get_vocabulary_stat, upsert_vocabulary_stat

router = APIRouter()


class SpacedRepetitionUpdateRequest(BaseModel):
    player_id: str
    word: str
    quality_score: int  # 0-5


class SpacedRepetitionUpdateResponse(BaseModel):
    word: str
    new_interval_days: float
    new_easiness_factor: float
    next_review: str
    streak: int
    mastered: bool


@router.post("/spaced-repetition/update", response_model=SpacedRepetitionUpdateResponse)
async def update_spaced_repetition(req: SpacedRepetitionUpdateRequest):
    pool = await get_db()

    # Load existing stats
    word_stats = {"easiness_factor": 2.5, "interval_days": 1.0, "streak": 0}
    if pool:
        await get_or_create_player(pool, req.player_id)
        existing = await get_vocabulary_stat(pool, req.player_id, req.word)
        if existing:
            word_stats = {
                "easiness_factor": existing["easiness_factor"],
                "interval_days": existing["interval_days"],
                "streak": existing["streak"],
            }

    updated = calculate_next_review(word_stats, req.quality_score)

    # Persist
    if pool:
        is_correct = req.quality_score >= 3
        await upsert_vocabulary_stat(
            pool, req.player_id, req.word,
            correct_delta=1 if is_correct else 0,
            mistake_delta=0 if is_correct else 1,
            streak=updated["streak"],
            interval_days=updated["interval_days"],
            easiness_factor=updated["easiness_factor"],
            next_review=updated["next_review"],
            last_seen=updated["last_seen"],
        )

    mastered = updated["streak"] >= 5 and updated["interval_days"] >= 21

    return SpacedRepetitionUpdateResponse(
        word=req.word,
        new_interval_days=updated["interval_days"],
        new_easiness_factor=updated["easiness_factor"],
        next_review=updated["next_review"],
        streak=updated["streak"],
        mastered=mastered,
    )
