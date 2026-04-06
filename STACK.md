# STACK — Lexica Spire (Технологический стек)

**Версия:** 1.0
**Дата:** 2026-02-13

---

## Обзор архитектуры

```
┌─────────────────────────────────────────────────────────┐
│                     КЛИЕНТ (Godot)                      │
│  GDScript · Сцены · UI · Анимации · Локальные сейвы    │
│                         │                               │
│                    HTTP requests                        │
│                         ▼                               │
│              ┌─────────────────────┐                    │
│              │  БЭКЕНД (FastAPI)   │                    │
│              │  Python 3.12        │                    │
│              │  NLP · Валидация    │                    │
│              │  Spaced Repetition  │                    │
│              └────────┬────────────┘                    │
│                       ▼                                 │
│              ┌─────────────────────┐                    │
│              │   PostgreSQL 16     │                    │
│              │   Vocabulary stats  │                    │
│              │   Player progress   │                    │
│              └─────────────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

---

## Игровой движок (Frontend)

| Компонент | Версия | Назначение |
|-----------|--------|------------|
| **Godot Engine** | 4.3 stable | Основной движок игры |
| **GDScript** | (встроен в Godot 4.3) | Язык скриптов |
| **Godot UI (Control nodes)** | (встроен) | Весь пользовательский интерфейс |
| **HTTPRequest** | (встроен) | Запросы к бэкенду |
| **JSON** | (встроен) | Данные карт, врагов, событий, сейвы |
| **SQLite** | via GDExtension (`godot-sqlite` v2.1) | Локальные сейвы (альтернатива JSON) |

### Плагины Godot

| Плагин | Версия | Назначение |
|--------|--------|------------|
| **godot-sqlite** | 2.1 | SQLite для локальных данных |
| **Dialogic** | 2.0 | Система диалогов и событий (опционально) |

### Шрифты (встраиваются в проект)

| Шрифт | Формат | Назначение |
|-------|--------|------------|
| **Merriweather** | .ttf (Google Fonts, OFL) | Основной текст, UI, карты |
| **Merriweather Bold** | .ttf | Заголовки, названия карт |
| **OpenDyslexic** | .ttf (опционально) | Accessibility: шрифт для дислексии |

---

## Бэкенд (Linguistic Engine)

| Компонент | Версия | Назначение |
|-----------|--------|------------|
| **Python** | 3.12.x | Язык бэкенда |
| **FastAPI** | 0.115.x | HTTP API фреймворк |
| **Uvicorn** | 0.34.x | ASGI сервер |
| **Pydantic** | 2.10.x | Валидация данных и схемы |

### NLP и лингвистика

| Библиотека | Версия | Назначение |
|------------|--------|------------|
| **language-tool-python** | 2.8.x | Проверка грамматики (обёртка LanguageTool) |
| **spaCy** | 3.8.x | NLP: токенизация, лемматизация, POS-тегирование |
| **en_core_web_sm** | 3.8.x (spaCy model) | Английская языковая модель для spaCy |
| **nltk** | 3.9.x | WordNet (синонимы, определения, дистракторы) |

### База данных

| Компонент | Версия | Назначение |
|-----------|--------|------------|
| **PostgreSQL** | 16.x | Основная БД (vocabulary stats, player progress) |
| **asyncpg** | 0.30.x | Асинхронный PostgreSQL драйвер для Python |
| **SQLAlchemy** | 2.0.x | ORM (опционально, для сложных запросов) |
| **Alembic** | 1.14.x | Миграции БД |

### Утилиты

| Библиотека | Версия | Назначение |
|------------|--------|------------|
| **httpx** | 0.28.x | HTTP клиент для внешних API (Dictionary API) |
| **python-dotenv** | 1.0.x | Переменные окружения (.env) |
| **loguru** | 0.7.x | Логирование |
| **pytest** | 8.3.x | Тесты |
| **pytest-asyncio** | 0.24.x | Асинхронные тесты |

---

## Внешние API

| API | Endpoint | Тип | Назначение |
|-----|----------|-----|------------|
| **Free Dictionary API** | `api.dictionaryapi.dev/api/v2/entries/en/{word}` | Бесплатный, без ключа | Определения, фонетика, примеры |
| **LanguageTool API** | `api.languagetool.org/v2/check` | Бесплатный (20 req/min) | Проверка грамматики (fallback если self-hosted) |

> **Примечание:** LanguageTool рекомендуется использовать self-hosted через `language-tool-python` для снятия rate limit.

---

## Инструменты разработки

| Инструмент | Версия | Назначение |
|------------|--------|------------|
| **Git** | 2.x | Контроль версий |
| **VS Code** | latest | Редактор для Python бэкенда |
| **Godot Editor** | 4.3 | Редактор для игры |
| **Docker** | 27.x (опционально) | Контейнеризация бэкенда + PostgreSQL |
| **Docker Compose** | 2.x (опционально) | Оркестрация контейнеров |

---

## Структура проекта

```
slay_the_spire/
├── godot/                      # Godot проект
│   ├── project.godot           # Конфигурация проекта
│   ├── scenes/                 # Сцены (.tscn)
│   │   ├── main_menu.tscn
│   │   ├── combat.tscn
│   │   ├── map.tscn
│   │   ├── shop.tscn
│   │   ├── rest_site.tscn
│   │   ├── event.tscn
│   │   └── ui/
│   │       ├── card.tscn
│   │       ├── challenge_popup.tscn
│   │       ├── enemy_display.tscn
│   │       └── hud.tscn
│   ├── scripts/                # GDScript файлы
│   │   ├── combat/
│   │   │   ├── combat_manager.gd
│   │   │   ├── card.gd
│   │   │   ├── deck.gd
│   │   │   ├── enemy.gd
│   │   │   └── challenge.gd
│   │   ├── map/
│   │   │   ├── map_generator.gd
│   │   │   └── map_node.gd
│   │   ├── data/
│   │   │   ├── card_database.gd
│   │   │   ├── enemy_database.gd
│   │   │   └── relic_database.gd
│   │   └── systems/
│   │       ├── save_manager.gd
│   │       ├── api_client.gd
│   │       └── game_state.gd
│   ├── data/                   # JSON данные
│   │   ├── cards.json
│   │   ├── enemies.json
│   │   ├── relics.json
│   │   ├── events.json
│   │   └── curses.json
│   ├── assets/                 # Ресурсы
│   │   ├── fonts/
│   │   │   ├── Merriweather-Regular.ttf
│   │   │   ├── Merriweather-Bold.ttf
│   │   │   └── OpenDyslexic-Regular.ttf
│   │   ├── sprites/            # AI-генерированный арт
│   │   │   ├── cards/
│   │   │   ├── enemies/
│   │   │   ├── relics/
│   │   │   └── ui/
│   │   ├── audio/
│   │   │   ├── music/
│   │   │   └── sfx/
│   │   └── themes/             # Godot Theme ресурсы
│   └── exports/                # Экспортированные билды
│
├── backend/                    # Python бэкенд
│   ├── main.py                 # FastAPI app entry point
│   ├── requirements.txt        # Python зависимости
│   ├── .env.example
│   ├── api/
│   │   ├── routes/
│   │   │   ├── validate.py     # POST /api/validate-answer
│   │   │   ├── challenge.py    # POST /api/generate-challenge
│   │   │   └── progress.py     # GET/POST /api/player-progress
│   │   └── deps.py             # Зависимости (DB connection)
│   ├── core/
│   │   ├── config.py           # Настройки приложения
│   │   ├── grammar_checker.py  # LanguageTool wrapper
│   │   ├── vocabulary.py       # WordNet + Dictionary API
│   │   ├── spaced_repetition.py # SM-2 алгоритм
│   │   └── difficulty.py       # Адаптивная сложность
│   ├── models/
│   │   ├── schemas.py          # Pydantic модели
│   │   └── database.py         # SQLAlchemy модели
│   ├── db/
│   │   ├── init.sql            # Начальная схема
│   │   └── migrations/         # Alembic миграции
│   └── tests/
│       ├── test_validate.py
│       ├── test_challenge.py
│       └── test_spaced_repetition.py
│
├── docker-compose.yml          # PostgreSQL + Backend
├── GAME_DESIGN.md
├── PRD.md
├── FLOW.md
├── STACK.md
├── FRONTEND.md
├── BACKEND.md
└── PROGRESS.md
```

---

## Команды запуска

### Бэкенд (разработка)
```bash
cd backend
pip install -r requirements.txt
python -m spacy download en_core_web_sm
uvicorn main:app --reload --port 8000
```

### PostgreSQL (Docker)
```bash
docker run -d \
  --name lexica-postgres \
  -e POSTGRES_DB=lexica_spire \
  -e POSTGRES_USER=lexica \
  -e POSTGRES_PASSWORD=devpassword \
  -p 5432:5432 \
  postgres:16
```

### Godot
```
Открыть godot/project.godot в Godot Editor 4.3
F5 — запуск игры
```

---

## requirements.txt (Python бэкенд)

```
fastapi==0.115.6
uvicorn[standard]==0.34.0
pydantic==2.10.4
asyncpg==0.30.0
sqlalchemy[asyncio]==2.0.36
alembic==1.14.1
language-tool-python==2.8.1
spacy==3.8.3
nltk==3.9.1
httpx==0.28.1
python-dotenv==1.0.1
loguru==0.7.3
pytest==8.3.4
pytest-asyncio==0.24.0
```
