from core.spaced_repetition import calculate_next_review, quality_from_answer


def test_quality_perfect():
    label, score, modifier = quality_from_answer(correct=True, time_taken=1.5)
    assert label == "perfect"
    assert score == 5
    assert modifier == 1.25


def test_quality_correct():
    label, score, modifier = quality_from_answer(correct=True, time_taken=5.0)
    assert label == "correct"
    assert score == 4
    assert modifier == 1.0


def test_quality_slow():
    label, score, modifier = quality_from_answer(correct=True, time_taken=15.0)
    assert label == "slow"
    assert score == 3
    assert modifier == 0.75


def test_quality_mistake():
    label, score, modifier = quality_from_answer(correct=False, time_taken=3.0)
    assert label == "mistake"
    assert score == 0
    assert modifier == 0.0


def test_sr_first_correct():
    stats = {"easiness_factor": 2.5, "interval_days": 1.0, "streak": 0}
    result = calculate_next_review(stats, quality=4)
    assert result["streak"] == 1
    assert result["interval_days"] == 1.0
    assert result["easiness_factor"] >= 1.3


def test_sr_second_correct():
    stats = {"easiness_factor": 2.5, "interval_days": 1.0, "streak": 1}
    result = calculate_next_review(stats, quality=4)
    assert result["streak"] == 2
    assert result["interval_days"] == 6.0


def test_sr_third_correct():
    stats = {"easiness_factor": 2.5, "interval_days": 6.0, "streak": 2}
    result = calculate_next_review(stats, quality=5)
    assert result["streak"] == 3
    assert result["interval_days"] == 6.0 * 2.5  # interval uses old EF before update


def test_sr_mistake_resets():
    stats = {"easiness_factor": 2.5, "interval_days": 15.0, "streak": 5}
    result = calculate_next_review(stats, quality=0)
    assert result["streak"] == 0
    assert result["interval_days"] == 1.0
    assert result["easiness_factor"] >= 1.3


def test_sr_ef_never_below_1_3():
    stats = {"easiness_factor": 1.3, "interval_days": 1.0, "streak": 0}
    result = calculate_next_review(stats, quality=0)
    assert result["easiness_factor"] >= 1.3


def test_sr_has_next_review_date():
    stats = {"easiness_factor": 2.5, "interval_days": 1.0, "streak": 0}
    result = calculate_next_review(stats, quality=4)
    assert "next_review" in result
    assert "last_seen" in result
