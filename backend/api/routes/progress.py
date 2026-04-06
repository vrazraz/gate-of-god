from fastapi import APIRouter

from api.deps import get_db
from core.difficulty import adjust_difficulty_from_accuracy
from db.repository import (
    get_or_create_player,
    get_vocabulary_summary,
    get_recent_runs,
    create_run,
    finish_run,
    update_player_stats,
    increment_runs_completed,
    get_recent_accuracy,
    upsert_vocabulary_stat,
)
from core.spaced_repetition import calculate_next_review
from models.schemas import (
    SaveProgressRequest,
    SaveProgressResponse,
    PlayerProgressResponse,
    PlayerInfo,
    PlayerStats,
    VocabularyInfo,
)

router = APIRouter()


@router.get("/player/{player_id}/progress", response_model=PlayerProgressResponse)
async def get_progress(player_id: str):
    pool = await get_db()

    if not pool:
        return _empty_progress(player_id)

    player = await get_or_create_player(pool, player_id)
    if not player:
        return _empty_progress(player_id)

    vocab = await get_vocabulary_summary(pool, player_id)
    runs = await get_recent_runs(pool, player_id, limit=10)

    total_answers = player["total_correct"] + player["total_mistakes"]
    accuracy = player["total_correct"] / total_answers if total_answers > 0 else 0.0

    return PlayerProgressResponse(
        player=PlayerInfo(
            id=str(player["id"]),
            display_name=player["display_name"],
            cefr_level=player["cefr_level"],
            insight_points=player["insight_points"],
            runs_completed=player["runs_completed"],
            stats=PlayerStats(
                total_perfect=player["total_perfect"],
                total_correct=player["total_correct"],
                total_mistakes=player["total_mistakes"],
                accuracy_rate=round(accuracy, 2),
            ),
        ),
        vocabulary=VocabularyInfo(
            total_words_seen=vocab["total_words_seen"],
            mastered_words=vocab["mastered_words"],
            struggling_words=vocab["struggling_words"],
            due_for_review=vocab["due_for_review"],
        ),
        runs=runs,
    )


@router.post("/player/{player_id}/progress", response_model=SaveProgressResponse)
async def save_progress(player_id: str, req: SaveProgressRequest):
    pool = await get_db()

    if not pool:
        return SaveProgressResponse(saved=True, player_updated=True)

    player = await get_or_create_player(pool, player_id)
    if not player:
        return SaveProgressResponse(saved=False, player_updated=False)

    cs = req.combat_stats or {}

    # Update player stats from combat
    perfect = cs.get("perfect_count", 0)
    correct = cs.get("correct_count", 0)
    mistake = cs.get("mistake_count", 0)

    if perfect or correct or mistake:
        await update_player_stats(
            pool, player_id,
            perfect_delta=perfect,
            correct_delta=correct,
            mistake_delta=mistake,
        )

    # Create or update run record
    if req.event_type == "run_end":
        run_id = await create_run(pool, player_id, {
            "run_data": req.run_data,
            "combat_stats": cs,
        })
        await finish_run(pool, run_id)
        await increment_runs_completed(pool, player_id)

    # Update vocabulary stats for encountered words
    words = cs.get("words_encountered", [])
    for word in words:
        word_stats = {"easiness_factor": 2.5, "interval_days": 1.0, "streak": 0}
        updated = calculate_next_review(word_stats, 4)  # default quality=correct
        await upsert_vocabulary_stat(
            pool, player_id, word,
            correct_delta=1,
            mistake_delta=0,
            streak=updated["streak"],
            interval_days=updated["interval_days"],
            easiness_factor=updated["easiness_factor"],
            next_review=updated["next_review"],
            last_seen=updated["last_seen"],
        )

    # Adjust difficulty based on recent accuracy
    recent_acc = await get_recent_accuracy(pool, player_id)
    if recent_acc is not None:
        new_level = adjust_difficulty_from_accuracy(player["cefr_level"], recent_acc)
        if new_level != player["cefr_level"]:
            await update_player_stats(pool, player_id, cefr_level=new_level)

    return SaveProgressResponse(saved=True, player_updated=True)


def _empty_progress(player_id: str) -> PlayerProgressResponse:
    return PlayerProgressResponse(
        player=PlayerInfo(id=player_id),
        vocabulary=VocabularyInfo(),
        runs=[],
    )
