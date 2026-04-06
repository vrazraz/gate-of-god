from datetime import datetime, timedelta, timezone


def calculate_next_review(word_stats: dict, quality: int) -> dict:
    """
    Modified SM-2 spaced repetition algorithm.

    quality: 0-5
      0 = complete failure (Mistake)
      3 = correct with effort (Slow)
      4 = correct (Correct)
      5 = perfect recall (Perfect)

    Returns updated word_stats dict.
    """
    ef = word_stats.get("easiness_factor", 2.5)
    interval = word_stats.get("interval_days", 1.0)
    streak = word_stats.get("streak", 0)

    if quality < 3:
        interval = 1.0
        streak = 0
    else:
        if streak == 0:
            interval = 1.0
        elif streak == 1:
            interval = 6.0
        else:
            interval = interval * ef
        streak += 1

    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    ef = max(1.3, ef)

    now = datetime.now(timezone.utc)

    word_stats["easiness_factor"] = round(ef, 4)
    word_stats["interval_days"] = round(interval, 2)
    word_stats["streak"] = streak
    word_stats["next_review"] = (now + timedelta(days=interval)).isoformat()
    word_stats["last_seen"] = now.isoformat()

    return word_stats


def quality_from_answer(correct: bool, time_taken: float) -> tuple[str, int, float]:
    """
    Determine quality label, score, and effect modifier from answer result.

    Returns: (quality_label, quality_score, effect_modifier)
    """
    if not correct:
        return "mistake", 0, 0.0

    if time_taken < 2.0:
        return "perfect", 5, 1.25
    elif time_taken <= 10.0:
        return "correct", 4, 1.0
    else:
        return "slow", 3, 0.75
