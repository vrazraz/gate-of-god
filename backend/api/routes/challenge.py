from fastapi import APIRouter

from api.deps import get_db
from core.vocabulary import generate_vocabulary_challenge, generate_grammar_challenge
from db.repository import get_or_create_player, get_due_words
from models.schemas import GenerateChallengeRequest, GenerateChallengeResponse, ChallengeOption

router = APIRouter()


@router.post("/generate-challenge", response_model=GenerateChallengeResponse)
async def generate_challenge(req: GenerateChallengeRequest):
    pool = await get_db()

    # Ensure player exists
    if pool:
        await get_or_create_player(pool, req.player_id)

    # Check for spaced-repetition due words
    due_word = None
    if pool and req.challenge_type == "vocabulary":
        due_list = await get_due_words(pool, req.player_id, limit=1)
        if due_list:
            due_word = due_list[0]["word"]

    if req.challenge_type == "vocabulary":
        data = generate_vocabulary_challenge(req.difficulty, override_word=due_word)
        return GenerateChallengeResponse(
            challenge_id=data["challenge_id"],
            type=data["type"],
            question=data["question"],
            input_type=data["input_type"],
            options=[ChallengeOption(**opt) for opt in data["options"]],
            correct_option=data["correct_option"],
            word=data["word"],
            time_limit=data["time_limit"],
        )
    elif req.challenge_type in ("grammar", "conjugation"):
        data = generate_grammar_challenge(req.difficulty)
        return GenerateChallengeResponse(
            challenge_id=data["challenge_id"],
            type=data["type"],
            question=data["question"],
            input_type=data["input_type"],
            correct_answer=data["correct_answer"],
            accepted_variants=data["accepted_variants"],
            word=data["word"],
            time_limit=data["time_limit"],
        )
    else:
        data = generate_vocabulary_challenge(req.difficulty, override_word=due_word)
        return GenerateChallengeResponse(
            challenge_id=data["challenge_id"],
            type=data["type"],
            question=data["question"],
            input_type=data["input_type"],
            options=[ChallengeOption(**opt) for opt in data["options"]],
            correct_option=data["correct_option"],
            word=data["word"],
            time_limit=data["time_limit"],
        )
