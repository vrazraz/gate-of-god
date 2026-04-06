import random
import uuid

import httpx
from loguru import logger

from core.config import settings

_FALLBACK_WORDS = {
    "A1": ["cat", "dog", "house", "food", "water", "book", "school", "friend", "family", "happy"],
    "A2": ["travel", "weather", "hobby", "garden", "invite", "polite", "manage", "perform", "create", "solve"],
    "B1": ["achieve", "communicate", "environment", "opportunity", "responsible", "tradition", "influence", "permanent", "approach", "beneficial"],
    "B2": ["ambiguous", "comprehensive", "diligent", "eloquent", "inevitable", "meticulous", "pragmatic", "resilient", "substantial", "versatile"],
    "C1": ["ubiquitous", "pragmatic", "ephemeral", "juxtapose", "quintessential", "paradigm", "albeit", "nuance", "superfluous", "conundrum"],
}

_FALLBACK_DEFINITIONS = {
    "cat": "A small domesticated carnivorous mammal",
    "dog": "A domesticated carnivorous mammal",
    "achieve": "Successfully bring about or reach a desired objective",
    "communicate": "Share or exchange information, news, or ideas",
    "environment": "The surroundings or conditions in which a person lives",
    "ubiquitous": "Present, appearing, or found everywhere",
    "pragmatic": "Dealing with things sensibly and realistically",
    "ephemeral": "Lasting for a very short time",
    "diligent": "Having or showing care in one's work or duties",
    "resilient": "Able to recover quickly from difficulties",
    "versatile": "Able to adapt to many different functions or activities",
    "ambiguous": "Open to more than one interpretation",
    "comprehensive": "Complete, including all or nearly all elements",
    "meticulous": "Showing great attention to detail",
    "inevitable": "Certain to happen, unavoidable",
}


async def fetch_definition(word: str) -> dict | None:
    """Fetch word definition from Free Dictionary API."""
    url = f"{settings.DICTIONARY_API_URL}/{word}"
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(url)
            if resp.status_code == 200:
                data = resp.json()
                if data and isinstance(data, list):
                    entry = data[0]
                    meanings = entry.get("meanings", [])
                    if meanings:
                        definition = meanings[0].get("definitions", [{}])[0].get("definition", "")
                        return {
                            "word": word,
                            "phonetic": entry.get("phonetic", ""),
                            "definition": definition,
                            "part_of_speech": meanings[0].get("partOfSpeech", ""),
                        }
    except Exception as e:
        logger.warning(f"Dictionary API error for '{word}': {e}")
    return None


def get_random_word(difficulty: str = "B1") -> str:
    words = _FALLBACK_WORDS.get(difficulty, _FALLBACK_WORDS["B1"])
    return random.choice(words)


def get_definition(word: str) -> str:
    return _FALLBACK_DEFINITIONS.get(word, f"The meaning of '{word}'")


def generate_distractors(correct_definition: str, difficulty: str = "B1", count: int = 3) -> list[str]:
    """Generate plausible but incorrect answer options."""
    all_defs = list(_FALLBACK_DEFINITIONS.values())
    distractors = [d for d in all_defs if d != correct_definition]
    random.shuffle(distractors)
    return distractors[:count]


def generate_vocabulary_challenge(difficulty: str = "B1") -> dict:
    word = get_random_word(difficulty)
    correct_def = get_definition(word)
    distractors = generate_distractors(correct_def, difficulty)

    options = [correct_def] + distractors
    random.shuffle(options)
    correct_index = options.index(correct_def)

    option_labels = ["a", "b", "c", "d"]
    formatted_options = [
        {"id": option_labels[i], "text": opt}
        for i, opt in enumerate(options)
    ]

    return {
        "challenge_id": f"ch_{uuid.uuid4().hex[:8]}",
        "type": "vocabulary",
        "question": f"What does '{word}' mean?",
        "input_type": "multiple_choice",
        "options": formatted_options,
        "correct_option": option_labels[correct_index],
        "word": word,
        "time_limit": 10,
    }


def generate_grammar_challenge(difficulty: str = "B1") -> dict:
    """Generate a basic grammar correction challenge."""
    challenges = [
        {
            "prompt": "She don't like apples.",
            "correct": "She doesn't like apples.",
            "variants": ["She does not like apples.", "She doesn't like apples."],
            "word": "don't/doesn't",
        },
        {
            "prompt": "He go to school every day.",
            "correct": "He goes to school every day.",
            "variants": ["He goes to school every day."],
            "word": "go/goes",
        },
        {
            "prompt": "They was happy yesterday.",
            "correct": "They were happy yesterday.",
            "variants": ["They were happy yesterday."],
            "word": "was/were",
        },
        {
            "prompt": "I have went to the store.",
            "correct": "I have gone to the store.",
            "variants": ["I have gone to the store.", "I've gone to the store."],
            "word": "went/gone",
        },
        {
            "prompt": "She is more taller than me.",
            "correct": "She is taller than me.",
            "variants": ["She is taller than me.", "She is taller than I am."],
            "word": "more taller/taller",
        },
    ]

    ch = random.choice(challenges)
    return {
        "challenge_id": f"ch_{uuid.uuid4().hex[:8]}",
        "type": "grammar",
        "question": "Correct the sentence:",
        "prompt": ch["prompt"],
        "input_type": "text",
        "correct_answer": ch["correct"],
        "accepted_variants": ch["variants"],
        "word": ch["word"],
        "time_limit": 15,
    }
