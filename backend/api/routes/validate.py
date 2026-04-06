from fastapi import APIRouter

from core.spaced_repetition import calculate_next_review, quality_from_answer
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

    # Update spaced repetition
    word_stats = {
        "easiness_factor": 2.5,
        "interval_days": 1.0,
        "streak": 0,
    }
    updated = calculate_next_review(word_stats, quality_score)

    sr_response = SpacedRepetitionResponse(
        word=req.word,
        next_review_days=updated["interval_days"],
        easiness_factor=updated["easiness_factor"],
        streak=updated["streak"],
    )

    # Determine if curse should be added
    curse = None
    if not correct:
        curse = CurseAdded(
            type="echo_of_typo" if req.challenge_type == "vocabulary" else "tense_fog",
            source_word=req.word,
            intensity=0,
        )

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
    user_clean = user_answer.strip().lower()
    correct_clean = correct_answer.strip().lower()
    return user_clean == correct_clean


def _generate_explanation(challenge_type: str, user_answer: str, correct_answer: str) -> str:
    if challenge_type == "grammar":
        return f"The correct form is: '{correct_answer}'"
    elif challenge_type == "vocabulary":
        return f"The correct answer is: '{correct_answer}'"
    elif challenge_type == "conjugation":
        return f"The correct conjugation is: '{correct_answer}'"
    return f"Expected: '{correct_answer}'"
