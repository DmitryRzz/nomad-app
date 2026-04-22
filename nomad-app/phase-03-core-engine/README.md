# NOMAD — Phase 03: Core Engine (AI Route Planner)

## Дата: 2026-04-22
## Статус: Завершён (MVP backend)

---

## Что сделано

### 1. Backend-сервис на Node.js + Fastify
- Сервер REST API на порту 3000
- CORS для мобильного клиента
- JWT middleware (заглушка для разработки)
- Error handling

### 2. AI-сервис (services/aiService.js)
**Генерация маршрутов через GPT-4:**
- Формирует системный промпт с правилами (погода, бюджет, темп)
- Отправляет контекст города + предпочтения пользователя
- Парсит JSON-ответ от GPT-4
- Валидирует структуру маршрута

**Адаптация под погоду:**
- Перестраивает outdoor → indoor при дожде/снеге
- Сохраняет логику маршрута (не прыгает по городу)

**Перевод с контекстом:**
- Переводит текст с учётом ситуации (ресторан, такси)
- Сохраняет тон и краткость для разговора

### 3. Route-сервис (services/routeService.js)
**Создание маршрута:**
1. Получает предпочтения пользователя из БД
2. Запрашивает погоду (mock — интеграция позже)
3. Генерирует маршрут через AI
4. Сохраняет в PostgreSQL:
   - routes — заголовок, город, статус
   - route_stops — последовательность точек
   - poi — точки интереса (find-or-create)
5. Возвращает полный маршрут с координатами

**Операции:**
- Получить маршрут по ID (с stops)
- Список маршрутов пользователя
- Обновить статус stop (visited/skipped)
- Удалить маршрут

### 4. API Endpoints

**Routes:**
```
GET    /routes              → Список маршрутов пользователя
POST   /routes              → Создать маршрут (body: city, country, preferences)
GET    /routes/:id          → Детали маршрута со stops
DELETE /routes/:id          → Удалить маршрут
PATCH  /routes/stops/:id    → Обновить статус точки
```

**AI:**
```
POST /ai/generate-route      → Сгенерировать маршрут (тестовый endpoint)
POST /ai/adapt-route         → Адаптировать под погоду
POST /ai/translate           → Перевод текста
```

**Health:**
```
GET /health                  → Проверка сервера
```

### 5. Database Schema
10 миграций:
- users — профили
- user_preferences — интересы, бюджет, темп
- poi — точки интереса с координатами (PostGIS)
- routes — маршруты
- route_stops — точки маршрута
- reviews — отзывы
- translation_cache — кеш переводов
- PostGIS extension + spatial index на poi
- Индексы на частые запросы

### 6. Project Structure
```
backend/
├── src/
│   ├── app.js              # Entry point
│   ├── config/
│   │   ├── index.js        # Env configuration
│   │   └── database.js     # PostgreSQL pool
│   ├── middleware/
│   │   └── auth.js         # JWT middleware
│   ├── routes/
│   │   ├── routes.js       # Route API
│   │   └── ai.js           # AI API
│   └── services/
│       ├── aiService.js    # OpenAI integration
│       └── routeService.js # Business logic
├── migrations/
│   └── run.js              # Database migrations
├── .env.example            # Environment template
├── package.json
└── .gitignore
```

---

## Как запустить

### 1. Установить зависимости
```bash
cd backend
npm install
```

### 2. Создать .env
```bash
cp .env.example .env
# Отредактировать: добавить OPENAI_API_KEY, DB credentials
```

### 3. Создать базу данных PostgreSQL
```bash
createdb nomad
```

### 4. Запустить миграции
```bash
npm run migrate
```

### 5. Запустить сервер
```bash
npm start
# или для разработки:
npm run dev
```

### 6. Проверить
```bash
curl http://localhost:3000/health
```

---

## Тестовый запрос (генерация маршрута)

```bash
curl -X POST http://localhost:3000/ai/generate-route \
  -H "Content-Type: application/json" \
  -d '{
    "city": "Paris",
    "country": "France",
    "interests": ["art", "food", "history"],
    "budgetLevel": 3,
    "pace": "balanced"
  }'
```

---

## Что НЕ входит в Phase 3 (следующие этапы)

- **Frontend Flutter app** — Phase 4+ (или параллельно)
- **Real-time weather integration** — интеграция с Weather API
- **Mapbox Directions** — построение реальных маршрутов между точками
- **Redis caching** — кеширование маршрутов и переводов
- **WebSocket translation** — потоковый перевод диалога
- **Authentication** — OAuth, email verification
- **Payment integration** — Stripe
- **Push notifications** — Firebase

---

## Следующий шаг

**Phase 4: Smart Compass (AR)** или **параллельно Flutter frontend**.

Рекомендация: сначала базовый Flutter UI для отображения маршрутов, потом AR.

**Согласен?**
