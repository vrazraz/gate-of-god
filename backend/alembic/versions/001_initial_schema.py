"""Initial schema — players, vocabulary_stats, run_history, curse_history

Revision ID: 001
Revises:
Create Date: 2026-02-19
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, JSONB

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "players",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("display_name", sa.String(50), nullable=False, server_default="Player"),
        sa.Column("cefr_level", sa.String(2), nullable=False, server_default="B1"),
        sa.Column("insight_points", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("runs_completed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_perfect", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_correct", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_mistakes", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("NOW()")),
    )
    op.create_index("idx_players_cefr", "players", ["cefr_level"])

    op.create_table(
        "vocabulary_stats",
        sa.Column("player_id", UUID(as_uuid=True), sa.ForeignKey("players.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("word", sa.String(100), primary_key=True),
        sa.Column("correct_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("mistake_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("streak", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_seen", sa.DateTime(timezone=True)),
        sa.Column("next_review", sa.DateTime(timezone=True)),
        sa.Column("interval_days", sa.Float(), nullable=False, server_default="1.0"),
        sa.Column("easiness_factor", sa.Float(), nullable=False, server_default="2.5"),
        sa.Column("cefr_level", sa.String(2)),
    )
    op.create_index("idx_vocab_next_review", "vocabulary_stats", ["player_id", "next_review"])
    op.create_index("idx_vocab_mistakes", "vocabulary_stats", [sa.text("player_id"), sa.text("mistake_count DESC")])

    op.create_table(
        "run_history",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("player_id", UUID(as_uuid=True), sa.ForeignKey("players.id", ondelete="CASCADE"), nullable=False),
        sa.Column("cefr_level", sa.String(2), nullable=False),
        sa.Column("deck_json", JSONB(), nullable=False),
        sa.Column("relics_json", JSONB(), server_default="'[]'"),
        sa.Column("floor_reached", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("enemies_killed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("curses_active", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("lex_coins_total", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("perfect_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("correct_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("mistake_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("victory", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("duration_sec", sa.Integer()),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("NOW()")),
        sa.Column("finished_at", sa.DateTime(timezone=True)),
    )
    op.create_index("idx_runs_player", "run_history", [sa.text("player_id"), sa.text("started_at DESC")])

    op.create_table(
        "curse_history",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("player_id", UUID(as_uuid=True), sa.ForeignKey("players.id", ondelete="CASCADE"), nullable=False),
        sa.Column("run_id", UUID(as_uuid=True), sa.ForeignKey("run_history.id", ondelete="SET NULL")),
        sa.Column("curse_type", sa.String(50), nullable=False),
        sa.Column("source_word", sa.String(100)),
        sa.Column("intensity", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("purged", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("purge_method", sa.String(50)),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("NOW()")),
        sa.Column("purged_at", sa.DateTime(timezone=True)),
    )
    op.create_index("idx_curses_player", "curse_history", ["player_id", "purged"])


def downgrade() -> None:
    op.drop_table("curse_history")
    op.drop_table("run_history")
    op.drop_table("vocabulary_stats")
    op.drop_table("players")
