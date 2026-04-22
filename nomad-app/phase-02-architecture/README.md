# NOMAD — Phase 02: Архитектура и Техстек

## Дата начала: 2026-04-22
## Статус: В работе

---

## 1. Выбор стека

### 1.1 Frontend — Flutter
**Почему Flutter:**
- Единый код для iOS + Android
- Быстрая разработка (hot reload)
- Отличная производительность (близко к нативной)
- Хорошая интеграция с картами (Google Maps Flutter, Mapbox)
- Встроенная поддержка камеры (для AR/фото-меню)

**Альтернатива:** React Native — хуже производительность для AR, больше проблем с нативными модулями.

### 1.2 Backend — Node.js + Fastify
**Почему Node.js:**
- I/O-bound задачи (много API-вызовов)
- JavaScript-стек = один язык для фулстека
- Быстрый старт, огромная экосистема

**Почему Fastify (не Express):**
- В 2-3 раза быстрее Express
- Встроенная валидация с JSON Schema
- Хорошая поддержка async/await
- Меньше магии, больше контроля

**Альтернатива:** Python + FastAPI — хорошо для ML, но разные языки фронт/бэк.

### 1.3 База данных

**PostgreSQL + PostGIS**
- Реляционная — структурированные данные (пользователи, маршруты, POI)
- PostGIS — геопространственные запросы (расстояние, близость)
- ACID — консистентность бронирований и оплаты

**Redis**
- Кеш маршрутов и POI
- Сессии пользователей
- Rate limiting для AI API

### 1.4 AI / ML

**OpenAI GPT-4** — генерация маршрутов
- API: chat.completions
- Системный промпт с контекстом
- Функциональные вызовы для структурированного выхода

**OpenAI Whisper** — голосовой перевод
- API: audio/transcriptions
- Поддержка 99 языков
- Офлайн-модель (medium) для fallback

**TTS (Text-to-Speech)**
- Google Cloud Text-to-Speech
- Azure Speech Services
- Или ElevenLabs для качества

### 1.5 Карты и Геолокация

**Mapbox Flutter Plugin**
- Красивые кастомные карты
- Векторные тайлы (быстрее)
- Построение маршрутов (Directions API)
- Геокодинг (адрес → координаты)

**Альтернатива:** Google Maps SDK — ограничения на кастомизацию, лицензирование.

### 1.6 Облачная инфраструктура

**Hetzner Cloud** (старт)
- Дешевле AWS/GCP в 2-3 раза
- Сервер в Германии — хорошая связность
- Можно масштабировать позже

**AWS S3 / Hetzner Storage Box**
- Хранение фото пользователей
- Кеширование тайлов карт

**Cloudflare**
- CDN для статики
- DDoS защита
- DNS

---

## 2. Архитектура системы

```
┌─────────────────────────────────────────────────────────────┐
│                         CLIENT                              │
│                    (Flutter App)                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   UI Layer   │  │  Map Widget   │  │  Camera/AR   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  State Mgmt  │  │  Local Cache  │  │  Audio Rec   │     │
│  │  (Riverpod)  │  │  (Hive/SQLite)│  │  (Flutter     │     │
│  └──────────────┘  └──────────────┘  │   Sound)       │     │
│                                       └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │ HTTPS/WebSocket
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      API GATEWAY                              │
│                    (Fastify + Node.js)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Auth/JWT    │  │ Rate Limit   │  │  Validation  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     MICROSERVICES                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Route      │  │    POI       │  │   User       │     │
│  │  Service     │  │  Service     │  │  Service     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   AI/LLM     │  │ Translation  │  │  Payment     │     │
│  │  Service     │  │  Service     │  │  Service     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     DATA LAYER                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  PostgreSQL  │  │    Redis     │  │     S3       │     │
│  │  + PostGIS   │  │   (Cache)    │  │  (Storage)   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   EXTERNAL APIs                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   OpenAI     │  │   Mapbox     │  │   Weather    │     │
│  │  (GPT-4)     │  │  (Maps)      │  │   API        │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Google     │  │  GetYourGuide│  │   Stripe     │     │
│  │  Places      │  │   API        │  │  (Payments)  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. API Design (REST + WebSocket)

### 3.1 Authentication
```
POST /auth/register
POST /auth/login
POST /auth/refresh
POST /auth/logout
```

### 3.2 Users
```
GET    /users/me
PATCH  /users/me
GET    /users/me/preferences
PATCH  /users/me/preferences
```

### 3.3 Routes (Маршруты)
```
POST   /routes              # Сгенерировать маршрут
GET    /routes              # Список моих маршрутов
GET    /routes/:id          # Детали маршрута
PATCH  /routes/:id          # Обновить маршрут
DELETE /routes/:id          # Удалить маршрут
POST   /routes/:id/optimize # Оптимизировать порядок точек
```

### 3.4 POI (Points of Interest)
```
GET /poi/nearby?lat=...&lng=...&radius=500&category=...
GET /poi/:id
GET /poi/:id/reviews
```

### 3.5 AI / Generation
```
POST /ai/generate-route     # Генерация маршрута через LLM
POST /ai/adapt-route        # Адаптация под погоду/энергию
POST /ai/translate          # Перевод текста
POST /ai/transcribe         # Распознавание голоса (Whisper)
```

### 3.6 Translation (Real-time)
```
WebSocket /ws/translation   # Потоковый перевод диалога
```

---

## 4. Database Schema (PostgreSQL)

### 4.1 Таблицы

```sql
-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    avatar_url TEXT,
    native_language VARCHAR(10) DEFAULT 'ru',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User Preferences (для персонализации)
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    interests TEXT[], -- ['food', 'art', 'hiking', 'music']
    budget_level INT CHECK (budget_level BETWEEN 1 AND 5),
    pace VARCHAR(20) CHECK (pace IN ('relaxed', 'balanced', 'intense')),
    accessibility_needs TEXT[],
    dietary_restrictions TEXT[],
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Routes
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'draft', -- draft, active, completed, archived
    total_distance_km DECIMAL(10,2),
    estimated_duration_hours INT,
    weather_adapted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Route Stops (точки маршрута)
CREATE TABLE route_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
    poi_id UUID REFERENCES poi(id),
    sequence_number INT NOT NULL,
    planned_time TIMESTAMP,
    duration_minutes INT DEFAULT 60,
    notes TEXT,
    visited BOOLEAN DEFAULT FALSE,
    skipped BOOLEAN DEFAULT FALSE
);

-- POI (Points of Interest)
CREATE TABLE poi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- museum, restaurant, park, etc.
    subcategory VARCHAR(50),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    rating DECIMAL(2, 1) CHECK (rating BETWEEN 0 AND 5),
    review_count INT DEFAULT 0,
    price_level INT CHECK (price_level BETWEEN 1 AND 5),
    indoor BOOLEAN DEFAULT FALSE,
    accessibility_friendly BOOLEAN DEFAULT FALSE,
    opening_hours JSONB,
    tags TEXT[],
    source VARCHAR(50), -- google_places, osm, manual, ai_generated
    external_id VARCHAR(255), -- ID из внешнего API
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- PostGIS для геопространственных запросов
CREATE INDEX idx_poi_location ON poi USING GIST (
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
);

-- Reviews
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poi_id UUID REFERENCES poi(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    text TEXT,
    language VARCHAR(10),
    source VARCHAR(50) DEFAULT 'app', -- app, google, tripadvisor
    created_at TIMESTAMP DEFAULT NOW()
);

-- Translation Cache (кеш переводов)
CREATE TABLE translation_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_text TEXT NOT NULL,
    source_lang VARCHAR(10) NOT NULL,
    target_lang VARCHAR(10) NOT NULL,
    translated_text TEXT NOT NULL,
    model VARCHAR(50) DEFAULT 'gpt-4',
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(source_text, source_lang, target_lang)
);

-- Sessions (для WebSocket перевода)
CREATE TABLE translation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    source_lang VARCHAR(10) NOT NULL,
    target_lang VARCHAR(10) NOT NULL,
    context TEXT, -- "restaurant", "taxi", "hotel"
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '24 hours')
);
```

---

## 5. AI Integration Architecture

### 5.1 Генерация маршрутов

**Flow:**
```
1. Пользователь вводит: город, даты, предпочтения
2. Backend собирает контекст:
   - Погода (Weather API)
   - Топ POI в городе (из базы)
   - Предпочтения пользователя
3. Формируется промпт для GPT-4
4. GPT-4 возвращает структурированный JSON:
   {
     "stops": [
       {
         "name": "Louvre Museum",
         "category": "museum",
         "duration_minutes": 180,
         "time": "09:00",
         "reason": "Must-see, less crowded in morning"
       }
     ],
     "logic": "Morning: indoor culture. Afternoon: walk in gardens."
   }
5. Backend валидирует, дополняет координатами
6. Сохраняет в базу
7. Возвращает клиенту
```

### 5.2 Промпт для GPT-4 (System)

```
You are NOMAD, an expert travel planner. Generate a daily route.

Rules:
- Consider weather: {weather_data}
- Consider user interests: {user_interests}
- Balance indoor/outdoor based on weather
- Walking distance between consecutive stops: < 2km or suggest transport
- Include meal breaks
- Respect opening hours
- Mix must-see with hidden gems

Output format: JSON with stops array.
Each stop: name, category, duration_minutes, time, reason, coordinates (if known).
```

### 5.3 Адаптация под погоду

**Flow:**
```
1. Cron-job каждые 6 часов проверяет погоду
2. Если изменилась → триггер на активные маршруты
3. AI перестраивает: outdoor → indoor
4. Push-уведомление пользователю
```

---

## 6. Real-time Translation Flow

```
┌─────────┐     ┌─────────────┐     ┌──────────┐
│ Speaker │────▶│  Flutter App│────▶│  Backend │
│ (Local) │     │  (Recording) │     │  (WS)    │
└─────────┘     └─────────────┘     └────┬─────┘
                                           │
                    ┌──────────────────────┘
                    ▼
            ┌──────────────┐
            │   Whisper    │
            │ Transcribe   │
            └──────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │  GPT-4       │
            │  Translate   │
            │  + Context   │
            └──────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │   TTS        │
            │  (Generate   │
            │   Audio)      │
            └──────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │   User       │
            │  (Hears     │
            │  translation)│
            └──────────────┘
```

**Latency target:** < 3 секунды (whisper + translate + tts)

**Оптимизация:**
- Кеш частых фраз ("How much?", "Where is...?")
- Предзагрузка TTS для типичных диалогов
- WebSocket для потоковой передачи

---

## 7. Offline Strategy

**Что работает офлайн:**
- Карты (Mapbox offline tiles)
- Сохранённые маршруты
- POI в текущем городе
- Базовый phrasebook (статический)

**Что требует сети:**
- AI-генерация маршрута
- Реал-time перевод
- Обновление погоды
- Социальные функции

**Sync:**
- При подключении: синхронизация маршрутов, статус visited/skipped
- Фоновая загрузка карт перед поездкой

---

## 8. Security

### 8.1 Auth
- JWT access token (15 min)
- Refresh token (7 days) в secure httpOnly cookie
- OAuth 2.0 (Google, Apple) для быстрого входа

### 8.2 Data
- HTTPS everywhere
- API keys в env, не в коде
- Rate limiting: 100 req/min на endpoint
- SQL injection protection (parameterized queries)

### 8.3 Privacy
- Геолокация: точные координаты только на устройстве
- На сервере: город/район, не точные координаты
- GDPR compliance: право на удаление данных

---

## Следующий шаг
Согласовать архитектуру и перейти к Этапу 3 — Core Engine (AI-планировщик).

**Критические вопросы:**
1. Flutter подтверждаем? Или React Native?
2. Hetzner подходит для старта? Или сразу AWS?
3. Mapbox или Google Maps?
