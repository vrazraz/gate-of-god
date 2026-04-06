from fastapi import APIRouter

from core.vocabulary import generate_vocabulary_challenge, generate_grammar_challenge
from models.schemas import GenerateChallengeRequest, GenerateChallengeResponse, ChallengeOption

router = APIRouter()


@router.post("/generate-challenge", response_model=GenerateChallengeResponse)
async def generate_challenge(req: GenerateChallengeRequest):
    if req.challenge_type == "vocabulary":
        data = generate_vocabulary_challenge(req.difficulty)
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
        data = generate_vocabulary_challenge(req.difficulty)
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
