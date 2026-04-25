from fastapi import APIRouter

from api.deps import get_db
from core.spaced_repetition import calculate_next_review, quality_from_answer
from db.repository import (
    get_or_create_player,
    get_vocabulary_stat,
    upsert_vocabulary_stat,
    update_player_stats,
    create_curse,
)
from models.schemas import (
    ValidateAnswerRequest,
    ValidateAnswerResponse,
    FeedbackResponse,
    SpacedRepetitionResponse,
    CurseAdded,
)

router = APIRouter()


@router.post("/validate-answer", response_model=ValidateAnswerResponse)
async def validate_answer(req: ValidateAnswerRequest):
    pool = await get_db()

    # Determine correctness
    correct = _check_answer(req.challenge_type, req.user_answer, req.correct_answer)

    # Calculate quality
    quality_label, quality_score, effect_modifier = quality_from_answer(correct, req.time_taken)

    # Build feedback
    if correct:
        feedback = FeedbackResponse(
            message="Perfect!" if quality_label == "perfect" else "Correct!",
            correct_answer=req.correct_answer,
        )
    else:
        feedback = FeedbackResponse(
            message="Incorrect!",
            correct_answer=req.correct_answer,
            explanation=_generate_explanation(req.challenge_type, req.user_answer, req.correct_answer),
        )

    # Load existing word stats from DB (or use defaults)
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

    # Update spaced repetition
    updated = calculate_next_review(word_stats, quality_score)

    sr_response = SpacedRepetitionResponse(
        word=req.word,
        next_review_days=updated["interval_days"],
        easiness_factor=updated["easiness_factor"],
        streak=updated["streak"],
    )

    # Persist to DB
    if pool:
        await upsert_vocabulary_stat(
            pool, req.player_id, req.word,
            correct_delta=1 if correct else 0,
            mistake_delta=0 if correct else 1,
            streak=updated["streak"],
            interval_days=updated["interval_days"],
            easiness_factor=updated["easiness_factor"],
            next_review=updated["next_review"],
            last_seen=updated["last_seen"],
        )
        if correct:
            delta_key = "perfect_delta" if quality_label == "perfect" else "correct_delta"
            await update_player_stats(pool, req.player_id, **{delta_key: 1})
        else:
            await update_player_stats(pool, req.player_id, mistake_delta=1)

    # Determine if curse should be added
    curse = None
    if not correct:
        curse = CurseAdded(
            type="echo_of_typo" if req.challenge_type == "vocabulary" else "tense_fog",
            source_word=req.word,
            intensity=0,
        )
        if pool:
            await create_curse(pool, req.player_id, curse.type, curse.source_word, curse.intensity)

    return ValidateAnswerResponse(
        correct=correct,
        quality=quality_label,
        quality_score=quality_score,
        effect_modifier=effect_modifier,
        feedback=feedback,
        spaced_repetition=sr_response,
        curse_added=curse,
    )


def _check_answer(challenge_type: str, user_answer: str, correct_answer: str) -> bool:
    user_clean = user_answer.strip().lower().replace("ё", "е")
    correct_clean = correct_answer.strip().lower().replace("ё", "е")
    return user_clean == correct_clean


def _generate_explanation(challenge_type: str, user_answer: str, correct_answer: str) -> str:
    if challenge_type == "grammar":
        return f"The correct form is: '{correct_answer}'"
    elif challenge_type == "vocabulary":
        return f"The correct answer is: '{correct_answer}'"
    elif challenge_type == "conjugation":
        return f"The correct conjugation is: '{correct_answer}'"
    return f"Expected: '{correct_answer}'"
