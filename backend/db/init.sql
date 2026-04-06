-- Lexica Spire Database Schema
-- PostgreSQL 16

CREATE TABLE IF NOT EXISTS players (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name    VARCHAR(50) NOT NULL DEFAULT 'Player',
    cefr_level      VARCHAR(2) NOT NULL DEFAULT 'B1',
    insight_points  INT NOT NULL DEFAULT 0,
    runs_completed  INT NOT NULL DEFAULT 0,
    total_perfect   INT NOT NULL DEFAULT 0,
    total_correct   INT NOT NULL DEFAULT 0,
    total_mistakes  INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_players_cefr ON players(cefr_level);

CREATE TABLE IF NOT EXISTS vocabulary_stats (
    player_id       UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    word            VARCHAR(100) NOT NULL,
    correct_count   INT NOT NULL DEFAULT 0,
    mistake_count   INT NOT NULL DEFAULT 0,
    streak          INT NOT NULL DEFAULT 0,
    last_seen       TIMESTAMPTZ,
    next_review     TIMESTAMPTZ,
    interval_days   FLOAT NOT NULL DEFAULT 1.0,
    easiness_factor FLOAT NOT NULL DEFAULT 2.5,
    cefr_level      VARCHAR(2),
    PRIMARY KEY (player_id, word)
);

CREATE INDEX IF NOT EXISTS idx_vocab_next_review ON vocabulary_stats(player_id, next_review);
CREATE INDEX IF NOT EXISTS idx_vocab_mistakes ON vocabulary_stats(player_id, mistake_count DESC);

CREATE TABLE IF NOT EXISTS run_history (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id       UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    cefr_level      VARCHAR(2) NOT NULL,
    deck_json       JSONB NOT NULL,
    relics_json     JSONB DEFAULT '[]',
    floor_reached   INT NOT NULL DEFAULT 0,
    enemies_killed  INT NOT NULL DEFAULT 0,
    curses_active   INT NOT NULL DEFAULT 0,
    lex_coins_total INT NOT NULL DEFAULT 0,
    perfect_count   INT NOT NULL DEFAULT 0,
    correct_count   INT NOT NULL DEFAULT 0,
    mistake_count   INT NOT NULL DEFAULT 0,
    victory         BOOLEAN NOT NULL DEFAULT FALSE,
    duration_sec    INT,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_runs_player ON run_history(player_id, started_at DESC);

CREATE TABLE IF NOT EXISTS curse_history (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id       UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    run_id          UUID REFERENCES run_history(id) ON DELETE SET NULL,
    curse_type      VARCHAR(50) NOT NULL,
    source_word     VARCHAR(100),
    intensity       INT NOT NULL DEFAULT 0,
    purged          BOOLEAN NOT NULL DEFAULT FALSE,
    purge_method    VARCHAR(50),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    purged_at       TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_curses_player ON curse_history(player_id, purged);
