# BACKEND — Lexica Spire (Серверная часть)

**Версия:** 1.0
**Дата:** 2026-02-13

---

## Архитектура

```
Godot Client (GDScript)
        │
        │ HTTP (JSON)
        ▼
┌──────────────────┐
│  FastAPI (Python) │
│  :8000            │
├──────────────────┤
│  /api/validate    │ ← Проверка ответов
│  /api/challenge   │ ← Генерация заданий
│  /api/progress    │ ← Сохранение/загрузка прогресса
│  /api/vocabulary  │ ← Словарные данные
└────────┬─────────┘
         │
    ┌────┴────┐
    ▼         ▼
PostgreSQL   External APIs
 :5432       (Dictionary, LanguageTool)
```

**Примечание:** В MVP авторизация отсутствует. Все данные привязаны к локальному `player_id`, который генерируется на клиенте (UUID) и передаётся в каждом запросе.

---

## Схема базы данных (PostgreSQL 16)

### Диаграмма связей

```
players ──< vocabulary_stats
players ──< run_history
players ──< curse_history
```

### Таблица: `players`

```sql
CREATE TABLE players (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name    VARCHAR(50) NOT NULL DEFAULT 'Player',
    cefr_level      VARCHAR(2) NOT NULL DEFAULT 'B1',  -- A1, A2, B1, B2, C1
    insight_points  INT NOT NULL DEFAULT 0,
    runs_completed  INT NOT NULL DEFAULT 0,
    total_perfect   INT NOT NULL DEFAULT 0,
    total_correct   INT NOT NULL DEFAULT 0,
    total_mistakes  INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_players_cefr ON players(cefr_level);
```

### Таблица: `vocabulary_stats`

Трекинг каждого слова для Spaced Repetition.

```sql
CREATE TABLE vocabulary_stats (
    player_id       UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    word            VARCHAR(100) NOT NULL,
    correct_count   INT NOT NULL DEFAULT 0,
    mistake_count   INT NOT NULL DEFAULT 0,
    streak          INT NOT NULL DEFAULT 0,        -- Текущая серия правильных ответов
    last_seen       TIMESTAMPTZ,
    next_review     TIMESTAMPTZ,                   -- Когда показать снова (SM-2)
    interval_days   FLOAT NOT NULL DEFAULT 1.0,    -- Интервал повторения в днях
    easiness_factor FLOAT NOT NULL DEFAULT 2.5,    -- SM-2 easiness factor (min 1.3)
    cefr_level      VARCHAR(2),                    -- Уровень слова
    PRIMARY KEY (player_id, word)
);

CREATE INDEX idx_vocab_next_review ON vocabulary_stats(player_id, next_review);
CREATE INDEX idx_vocab_mistakes ON vocabulary_stats(player_id, mistake_count DESC);
```

### Таблица: `run_history`

```sql
CREATE TABLE run_history (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id       UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    cefr_level      VARCHAR(2) NOT NULL,
    deck_json       JSONB NOT NULL,               -- Полная колода на момент завершения
    relics_json     JSONB DEFAULT '[]',           -- Реликвии
    floor_reached   INT NOT NULL DEFAULT 0,
    enemies_killed  INT NOT NULL DEFAULT 0,
    curses_active   INT NOT NULL DEFAULT 0,
    lex_coins_total INT NOT NULL DEFAULT 0,
    perfect_count   INT NOT NULL DEFAULT 0,
    correct_count   INT NOT NULL DEFAULT 0,
    mistake_count   INT NOT NULL DEFAULT 0,
    victory         BOOLEAN NOT NULL DEFAULT FALSE,
    duration_sec    INT,                          -- Длительность рана в секундах
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at     TIMESTAMPTZ
);

CREATE INDEX idx_runs_player ON run_history(player_id, started_at DESC);
```

### Таблица: `curse_history`

Отслеживание проклятий для аналитики.

```sql
CREATE TABLE curse_history (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id       UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    run_id          UUID REFERENCES run_history(id) ON DELETE SET NULL,
    curse_type      VARCHAR(50) NOT NULL,         -- 'echo_of_typo', 'tense_fog'
    source_word     VARCHAR(100),                 -- Слово/правило вызвавшее проклятие
    intensity       INT NOT NULL DEFAULT 0,
    purged          BOOLEAN NOT NULL DEFAULT FALSE,
    purge_method    VARCHAR(50),                  -- 'combat', 'rest_site', 'merchant', 'event'
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    purged_at       TIMESTAMPTZ
);

CREATE INDEX idx_curses_player ON curse_history(player_id, purged);
```

---

## API Контракты

### Base URL

```
http://localhost:8000/api
```

Все ответы в формате JSON. Ошибки возвращают стандартный формат:

```json
{
  "detail": "Описание ошибки",
  "code": "ERROR_CODE"
}
```

---

### POST `/api/validate-answer`

Валидация ответа игрока на лингвистическое задание.

**Request:**
```json
{
  "player_id": "uuid-string",
  "challenge_type": "vocabulary | grammar | conjugation | synonym",
  "challenge_id": "vocab_strike_01_q1",
  "user_answer": "She doesn't like apples.",
  "correct_answer": "She doesn't like apples.",
  "time_taken": 3.5,
  "word": "ubiquitous",
  "card_id": "vocab_strike_01"
}
```

**Response (200):**
```json
{
  "correct": true,
  "quality": "perfect",
  "quality_score": 5,
  "effect_modifier": 1.25,
  "feedback": {
    "message": "Perfect!",
    "correct_answer": "She doesn't like apples.",
    "explanation": null
  },
  "spaced_repetition": {
    "word": "ubiquitous",
    "next_review_days": 6.0,
    "easiness_factor": 2.6,
    "streak": 4
  },
  "curse_added": null
}
```

**Response при ошибке (200 — это игровой результат, не ошибка сервера):**
```json
{
  "correct": false,
  "quality": "mistake",
  "quality_score": 0,
  "effect_modifier": 0.0,
  "feedback": {
    "message": "Incorrect!",
    "correct_answer": "She doesn't like apples.",
    "explanation": "Use 'doesn't' (does not) for third person singular negative."
  },
  "spaced_repetition": {
    "word": "like",
    "next_review_days": 1.0,
    "easiness_factor": 2.18,
    "streak": 0
  },
  "curse_added": {
    "type": "tense_fog",
    "source_word": "like",
    "intensity": 0
  }
}
```

**Логика quality:**

| Quality | Условие | `quality_score` | `effect_modifier` |
|---------|---------|-----------------|-------------------|
| `perfect` | correct + time < 2 сек | 5 | 1.25 |
| `correct` | correct + time 2-10 сек | 4 | 1.00 |
| `slow` | correct + time 10-20 сек | 3 | 0.75 |
| `mistake` | incorrect (любое время) | 0 | 0.00 |

---

### POST `/api/generate-challenge`

Генерация задания для конкретной карты.

**Request:**
```json
{
  "player_id": "uuid-string",
  "card_id": "vocab_strike_01",
  "challenge_type": "vocabulary",
  "difficulty": "B1",
  "active_debuffs": ["confusion"]
}
```

**Response (200):**
```json
{
  "challenge_id": "ch_abc123",
  "type": "vocabulary",
  "question": "What does 'ubiquitous' mean?",
  "input_type": "multiple_choice",
  "options": [
    {"id": "a", "text": "Rare and valuable"},
    {"id": "b", "text": "Found everywhere"},
    {"id": "c", "text": "Dangerous and threatening"},
    {"id": "d", "text": "Ancient and forgotten"}
  ],
  "correct_option": "b",
  "word": "ubiquitous",
  "time_limit": 10,
  "debuff_effects": {
    "confusion": {
      "typos_inserted": true,
      "affected_options": ["a", "c"]
    }
  }
}
```

**Для grammar-задания:**
```json
{
  "challenge_id": "ch_def456",
  "type": "grammar",
  "question": "Correct the sentence:",
  "prompt": "She don't like apples.",
  "input_type": "text",
  "correct_answer": "She doesn't like apples.",
  "accepted_variants": [
    "She does not like apples.",
    "She doesn't like apples."
  ],
  "word": "don't/doesn't",
  "time_limit": 15,
  "debuff_effects": {}
}
```

**Для conjugation-задания:**
```json
{
  "challenge_id": "ch_ghi789",
  "type": "conjugation",
  "question": "Conjugate 'go' in Past Simple:",
  "input_type": "text",
  "correct_answer": "went",
  "accepted_variants": ["went"],
  "word": "go",
  "time_limit": 10,
  "debuff_effects": {}
}
```

---

### GET `/api/player/{player_id}/progress`

Получение прогресса игрока.

**Response (200):**
```json
{
  "player": {
    "id": "uuid-string",
    "display_name": "Player",
    "cefr_level": "B1",
    "insight_points": 15,
    "runs_completed": 3,
    "stats": {
      "total_perfect": 142,
      "total_correct": 387,
      "total_mistakes": 65,
      "accuracy_rate": 0.89
    }
  },
  "vocabulary": {
    "total_words_seen": 250,
    "mastered_words": 120,
    "struggling_words": ["ubiquitous", "albeit", "pragmatic"],
    "due_for_review": 15
  },
  "runs": [
    {
      "id": "uuid",
      "victory": false,
      "floor_reached": 8,
      "accuracy": 0.72,
      "duration_sec": 1800,
      "finished_at": "2026-02-13T14:30:00Z"
    }
  ]
}
```

---

### POST `/api/player/{player_id}/progress`

Сохранение прогресса (вызывается после каждого боя и в конце рана).

**Request:**
```json
{
  "event_type": "combat_end | run_end | rest_site | shop",
  "run_data": {
    "floor": 8,
    "deck": [...],
    "relics": [...],
    "hp": 65,
    "max_hp": 100,
    "lex_coins": 245,
    "curses": [...]
  },
  "combat_stats": {
    "perfect_count": 3,
    "correct_count": 8,
    "mistake_count": 1,
    "words_encountered": ["ubiquitous", "diligent", "commence"]
  }
}
```

**Response (200):**
```json
{
  "saved": true,
  "player_updated": true
}
```

---

### GET `/api/vocabulary/word/{word}`

Получение данных о слове (определения, синонимы для дистракторов).

**Response (200):**
```json
{
  "word": "ubiquitous",
  "phonetic": "/juːˈbɪkwɪtəs/",
  "cefr_level": "C1",
  "frequency_rank": 12500,
  "definitions": [
    {
      "part_of_speech": "adjective",
      "definition": "present, appearing, or found everywhere",
      "example": "His ubiquitous influence was felt in every department."
    }
  ],
  "synonyms": ["omnipresent", "pervasive", "universal"],
  "distractors": [
    "Rare and valuable",
    "Dangerous and threatening",
    "Ancient and forgotten"
  ]
}
```

---

### POST `/api/spaced-repetition/update`

Обновление данных Spaced Repetition после ответа (вызывается внутри validate-answer, но доступен и отдельно).

**Request:**
```json
{
  "player_id": "uuid-string",
  "word": "ubiquitous",
  "quality_score": 5
}
```

**Response (200):**
```json
{
  "word": "ubiquitous",
  "new_interval_days": 6.0,
  "new_easiness_factor": 2.6,
  "next_review": "2026-02-19T14:30:00Z",
  "streak": 4,
  "mastered": false
}
```

---

## Алгоритмы

### Spaced Repetition (SM-2)

```python
def calculate_next_review(word_stats: dict, quality: int) -> dict:
    """
    Модифицированный SM-2 алгоритм.

    quality: 0-5
      0 = полный провал (Mistake)
      3 = правильно с усилием (Slow)
      4 = правильно (Correct)
      5 = идеально (Perfect)
    """
    ef = word_stats['easiness_factor']
    interval = word_stats['interval_days']

    if quality < 3:
        # Ошибка — сброс интервала
        interval = 1.0
        word_stats['streak'] = 0
    else:
        # Успех — увеличение интервала
        if word_stats['streak'] == 0:
            interval = 1.0
        elif word_stats['streak'] == 1:
            interval = 6.0
        else:
            interval = interval * ef

        word_stats['streak'] += 1

    # Обновление easiness factor
    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    ef = max(1.3, ef)

    word_stats['easiness_factor'] = ef
    word_stats['interval_days'] = interval
    word_stats['next_review'] = now() + timedelta(days=interval)

    return word_stats
```

### Adaptive Difficulty

```python
def adjust_difficulty(player_id: str) -> str:
    """
    Возвращает рекомендуемый CEFR уровень на основе последних 20 ответов.
    """
    recent = get_last_n_answers(player_id, n=20)
    accuracy = sum(1 for a in recent if a.correct) / len(recent)

    current = get_player_cefr(player_id)

    if accuracy > 0.85:
        return increase_cefr(current)  # A1→A2→B1→B2→C1
    elif accuracy < 0.60:
        return decrease_cefr(current)  # C1→B2→B1→A2→A1
    else:
        return current  # Остаётся на месте
```

### Challenge Generation

```python
def generate_vocabulary_challenge(player_id: str, difficulty: str) -> dict:
    """
    Генерация vocabulary задания с учётом spaced repetition.
    """
    # 1. Проверить есть ли слова на повторение
    due_words = get_due_words(player_id)

    if due_words:
        word = due_words[0]  # Приоритет: слова для повторения
    else:
        word = get_random_word(difficulty)  # Новое слово

    # 2. Получить определение
    definition = get_definition(word)

    # 3. Сгенерировать дистракторы (неправильные ответы)
    distractors = generate_distractors(word, count=3)

    # 4. Перемешать
    options = shuffle([definition] + distractors)
    correct_index = options.index(definition)

    return {
        'word': word,
        'question': f"What does '{word}' mean?",
        'options': options,
        'correct_index': correct_index,
        'time_limit': 10
    }
```

### Damage Formula

```python
def calculate_damage(base_damage: int, time_taken: float,
                     quality: str, modifiers: float = 1.0) -> int:
    """
    Формула урона: Damage = B * (1 + S/t) * M * quality_mod
    """
    speed_bonus = 1.0

    # Speed component
    if time_taken > 0:
        damage = base_damage * (1 + speed_bonus / time_taken) * modifiers
    else:
        damage = base_damage * 2 * modifiers  # Мгновенный ответ = макс бонус

    # Quality modifier
    quality_mods = {
        'perfect': 1.25,
        'correct': 1.00,
        'slow': 0.75,
        'mistake': 0.00  # Карта fizzle
    }

    damage *= quality_mods.get(quality, 1.0)

    return max(0, int(damage))
```

---

## Логика авторизации (MVP)

В MVP нет серверной авторизации. Используется следующая схема:

```
1. Первый запуск Godot клиента
   └→ Генерирует UUID (player_id)
   └→ Сохраняет в user://player_id.cfg

2. При каждом API запросе
   └→ Передаёт player_id в теле запроса или query param

3. Бэкенд
   └→ Если player_id не существует в БД → создаёт нового игрока
   └→ Если существует → использует существующего
```

**GDScript (клиент):**
```gdscript
# Генерация player_id
func get_or_create_player_id() -> String:
    var config = ConfigFile.new()
    var path = "user://player_id.cfg"

    if config.load(path) == OK:
        return config.get_value("player", "id", "")

    var new_id = str(UUID.v4())  # или используем OS.get_unique_id()
    config.set_value("player", "id", new_id)
    config.save(path)
    return new_id
```

**Будущая авторизация (Phase 4):**
- JWT токены
- Регистрация через email или Steam OAuth
- Облачные сейвы
- Leaderboards

---

## Конфигурация

### `.env` файл

```env
# Database
DATABASE_URL=postgresql+asyncpg://lexica:devpassword@localhost:5432/lexica_spire

# Server
HOST=0.0.0.0
PORT=8000
DEBUG=true

# External APIs
DICTIONARY_API_URL=https://api.dictionaryapi.dev/api/v2/entries/en
LANGUAGE_TOOL_ENABLED=true

# Game Settings
DEFAULT_CEFR_LEVEL=B1
CHALLENGE_TIME_LIMIT_DEFAULT=10
SPACED_REPETITION_ENABLED=true
```

---

## Docker Compose (разработка)

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: lexica_spire
      POSTGRES_USER: lexica
      POSTGRES_PASSWORD: devpassword
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./backend/db/init.sql:/docker-entrypoint-initdb.d/init.sql

  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql+asyncpg://lexica:devpassword@postgres:5432/lexica_spire
    depends_on:
      - postgres
    volumes:
      - ./backend:/app
    command: uvicorn main:app --host 0.0.0.0 --port 8000 --reload

volumes:
  pgdata:
```

---

## Обработка ошибок

| HTTP Code | Ситуация | Response |
|-----------|----------|----------|
| 200 | Успешный запрос | `{ "data": ... }` |
| 400 | Невалидный запрос | `{ "detail": "Invalid challenge_type", "code": "INVALID_INPUT" }` |
| 404 | Player/Word не найден | `{ "detail": "Player not found", "code": "NOT_FOUND" }` |
| 500 | Внутренняя ошибка | `{ "detail": "Internal server error", "code": "SERVER_ERROR" }` |
| 503 | Внешний API недоступен | `{ "detail": "Dictionary API unavailable", "code": "EXTERNAL_API_DOWN" }` |

**Fallback при недоступности бэкенда:**
Godot клиент должен уметь работать офлайн:
- Локальный словарь (предзагруженный JSON с ~1000 слов)
- Базовая валидация грамматики на клиенте (exact match)
- Сохранение прогресса локально, синхронизация при восстановлении связи
