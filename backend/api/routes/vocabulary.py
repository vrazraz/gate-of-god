from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from core.vocabulary import fetch_definition, get_definition, generate_distractors, _FALLBACK_WORDS

router = APIRouter()


class WordInfoResponse(BaseModel):
    word: str
    phonetic: str = ""
    cefr_level: str | None = None
    definitions: list[dict] = []
    synonyms: list[str] = []
    distractors: list[str] = []


@router.get("/vocabulary/word/{word}", response_model=WordInfoResponse)
async def get_word_info(word: str):
    # Try external API first
    api_data = await fetch_definition(word)

    # Determine CEFR level from fallback lists
    cefr = None
    for level, words in _FALLBACK_WORDS.items():
        if word.lower() in [w.lower() for w in words]:
            cefr = level
            break

    if api_data:
        definition_text = api_data.get("definition", "")
        distractors = generate_distractors(definition_text)
        return WordInfoResponse(
            word=word,
            phonetic=api_data.get("phonetic", ""),
            cefr_level=cefr,
            definitions=[{
                "part_of_speech": api_data.get("part_of_speech", ""),
                "definition": definition_text,
                "example": "",
            }],
            distractors=distractors,
        )

    # Fallback to local data
    fallback_def = get_definition(word)
    if fallback_def == f"The meaning of '{word}'":
        raise HTTPException(status_code=404, detail="Word not found")

    distractors = generate_distractors(fallback_def)
    return WordInfoResponse(
        word=word,
        cefr_level=cefr,
        definitions=[{
            "part_of_speech": "",
            "definition": fallback_def,
            "example": "",
        }],
        distractors=distractors,
    )
