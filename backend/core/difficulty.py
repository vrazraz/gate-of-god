CEFR_LEVELS = ["A1", "A2", "B1", "B2", "C1"]


def adjust_difficulty(recent_answers: list[bool], current_level: str) -> str:
    """
    Adjust CEFR level based on recent answer accuracy.

    recent_answers: list of booleans (True=correct) for last 20 answers
    current_level: current CEFR level string
    """
    if len(recent_answers) < 5:
        return current_level

    accuracy = sum(1 for a in recent_answers if a) / len(recent_answers)

    if accuracy > 0.85:
        return _increase_cefr(current_level)
    elif accuracy < 0.60:
        return _decrease_cefr(current_level)
    return current_level


def _increase_cefr(level: str) -> str:
    idx = CEFR_LEVELS.index(level) if level in CEFR_LEVELS else 2
    return CEFR_LEVELS[min(idx + 1, len(CEFR_LEVELS) - 1)]


def _decrease_cefr(level: str) -> str:
    idx = CEFR_LEVELS.index(level) if level in CEFR_LEVELS else 2
    return CEFR_LEVELS[max(idx - 1, 0)]
