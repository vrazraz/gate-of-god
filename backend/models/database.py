from sqlalchemy import (
    Column, String, Integer, Float, Boolean, DateTime, ForeignKey, Index, text
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import DeclarativeBase, relationship
from datetime import datetime, timezone


class Base(DeclarativeBase):
    pass


class Player(Base):
    __tablename__ = "players"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    display_name = Column(String(50), nullable=False, default="Player")
    cefr_level = Column(String(2), nullable=False, default="B1")
    insight_points = Column(Integer, nullable=False, default=0)
    runs_completed = Column(Integer, nullable=False, default=0)
    total_perfect = Column(Integer, nullable=False, default=0)
    total_correct = Column(Integer, nullable=False, default=0)
    total_mistakes = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    vocabulary_stats = relationship("VocabularyStat", back_populates="player")
    run_history = relationship("RunHistory", back_populates="player")


class VocabularyStat(Base):
    __tablename__ = "vocabulary_stats"

    player_id = Column(UUID(as_uuid=True), ForeignKey("players.id", ondelete="CASCADE"), primary_key=True)
    word = Column(String(100), primary_key=True)
    correct_count = Column(Integer, nullable=False, default=0)
    mistake_count = Column(Integer, nullable=False, default=0)
    streak = Column(Integer, nullable=False, default=0)
    last_seen = Column(DateTime(timezone=True))
    next_review = Column(DateTime(timezone=True))
    interval_days = Column(Float, nullable=False, default=1.0)
    easiness_factor = Column(Float, nullable=False, default=2.5)
    cefr_level = Column(String(2))

    player = relationship("Player", back_populates="vocabulary_stats")

    __table_args__ = (
        Index("idx_vocab_next_review", "player_id", "next_review"),
        Index("idx_vocab_mistakes", "player_id", mistake_count.desc()),
    )


class RunHistory(Base):
    __tablename__ = "run_history"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    player_id = Column(UUID(as_uuid=True), ForeignKey("players.id", ondelete="CASCADE"), nullable=False)
    cefr_level = Column(String(2), nullable=False)
    deck_json = Column(JSONB, nullable=False)
    relics_json = Column(JSONB, default=[])
    floor_reached = Column(Integer, nullable=False, default=0)
    enemies_killed = Column(Integer, nullable=False, default=0)
    curses_active = Column(Integer, nullable=False, default=0)
    lex_coins_total = Column(Integer, nullable=False, default=0)
    perfect_count = Column(Integer, nullable=False, default=0)
    correct_count = Column(Integer, nullable=False, default=0)
    mistake_count = Column(Integer, nullable=False, default=0)
    victory = Column(Boolean, nullable=False, default=False)
    duration_sec = Column(Integer)
    started_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    finished_at = Column(DateTime(timezone=True))

    player = relationship("Player", back_populates="run_history")

    __table_args__ = (
        Index("idx_runs_player", "player_id", started_at.desc()),
    )


class CurseHistory(Base):
    __tablename__ = "curse_history"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    player_id = Column(UUID(as_uuid=True), ForeignKey("players.id", ondelete="CASCADE"), nullable=False)
    run_id = Column(UUID(as_uuid=True), ForeignKey("run_history.id", ondelete="SET NULL"))
    curse_type = Column(String(50), nullable=False)
    source_word = Column(String(100))
    intensity = Column(Integer, nullable=False, default=0)
    purged = Column(Boolean, nullable=False, default=False)
    purge_method = Column(String(50))
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    purged_at = Column(DateTime(timezone=True))

    __table_args__ = (
        Index("idx_curses_player", "player_id", "purged"),
    )
