from pydantic import BaseModel


class ValidateAnswerRequest(BaseModel):
    player_id: str
    challenge_type: str  # vocabulary | grammar | conjugation | synonym
    challenge_id: str
    user_answer: str
    correct_answer: str
    time_taken: float
    word: str
    card_id: str


class FeedbackResponse(BaseModel):
    message: str
    correct_answer: str
    explanation: str | None = None


class SpacedRepetitionResponse(BaseModel):
    word: str
    next_review_days: float
    easiness_factor: float
    streak: int


class CurseAdded(BaseModel):
    type: str
    source_word: str
    intensity: int = 0


class ValidateAnswerResponse(BaseModel):
    correct: bool
    quality: str  # perfect | correct | slow | mistake
    quality_score: int
    effect_modifier: float
    feedback: FeedbackResponse
    spaced_repetition: SpacedRepetitionResponse
    curse_added: CurseAdded | None = None


class GenerateChallengeRequest(BaseModel):
    player_id: str
    card_id: str
    challenge_type: str  # vocabulary | grammar | conjugation | synonym
    difficulty: str = "B1"
    active_debuffs: list[str] = []


class ChallengeOption(BaseModel):
    id: str
    text: str


class GenerateChallengeResponse(BaseModel):
    challenge_id: str
    type: str
    question: str
    input_type: str  # multiple_choice | text
    options: list[ChallengeOption] | None = None
    correct_option: str | None = None
    correct_answer: str | None = None
    accepted_variants: list[str] | None = None
    word: str
    time_limit: int


class SaveProgressRequest(BaseModel):
    event_type: str  # combat_end | run_end | rest_site | shop
    run_data: dict
    combat_stats: dict | None = None


class SaveProgressResponse(BaseModel):
    saved: bool
    player_updated: bool


class PlayerStats(BaseModel):
    total_perfect: int = 0
    total_correct: int = 0
    total_mistakes: int = 0
    accuracy_rate: float = 0.0


class PlayerInfo(BaseModel):
    id: str
    display_name: str = "Player"
    cefr_level: str = "B1"
    insight_points: int = 0
    runs_completed: int = 0
    stats: PlayerStats = PlayerStats()


class VocabularyInfo(BaseModel):
    total_words_seen: int = 0
    mastered_words: int = 0
    struggling_words: list[str] = []
    due_for_review: int = 0


class PlayerProgressResponse(BaseModel):
    player: PlayerInfo
    vocabulary: VocabularyInfo
    runs: list[dict] = []
