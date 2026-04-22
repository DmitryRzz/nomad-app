# NOMAD — Handover Document
## AI Travel Planner | Полный стек 8 фаз

> Для: следующего Kimi Claw агента или разработчика, продолжающего проект.
> Автор: RDSkimibot2_bot (Telegram) | Qwerty Agent
> Дата: 2026-04-23

---

## 1. Что это

**NOMAD** — мобильное приложение для путешественников с AI-планированием маршрутов.
- Генерация персонализированных маршрутов по городу
- AR-компас с ближайшими POI
- Офлайн-переводчик (Language Shield)
- Бронирование экскурсий (GetYourGuide)
- Групповые платежи (Split Payments)
- Pro-подписка (Stripe)
- Push-уведомления + offline mode

---

## 2. Структура проекта

```
nomad-app/
├── nomad_flutter_ui/          ← Основной Flutter проект (интегрировано)
│   ├── lib/main.dart           ← Точка входа с AuthGate + Navigation
│   ├── lib/screens/
│   ├── lib/services/
│   ├── lib/providers/
│   ├── lib/models/
│   └── pubspec.yaml
│
├── phase-01-discovery/         ← Исследование, бизнес-требования
├── phase-02-architecture/      ← Диаграммы, архитектура, выбор стека
├── phase-03-core-engine/       ← Backend MVP: Fastify + PostgreSQL + Redis
│   └── backend/
│       ├── src/app.js
│       ├── src/routes/ (routes, ai, poi, bookings, payments)
│       ├── src/services/
│       ├── src/middleware/auth.js
│       ├── migrations/run.js
│       └── package.json
│
├── phase-04-flutter-ui/        ← Первый Flutter UI (базовый)
├── phase-05-smart-compass/     ← Компас + AR + POI
│   ├── flutter/
│   └── backend/
├── phase-06-language-shield/   ← Переводчик + офлайн-кэш
│   ├── flutter/
│   └── backend/
├── phase-07-integrations/      ← Бронирование + Stripe + Pro UI
│   └── backend/
└── phase-08-launch/            ← Auth + Push + Offline + Store
    ├── flutter/                ← Новые экраны и сервисы
    ├── backend/                ← Auth API, Push API, миграции
    ├── store/                  ← Метаданные App Store / Google Play
    └── README.md

├── prototype.html              ← Интерактивный HTML-прототип (кликабельный)
└── nomad-roadmap.pdf           ← Визуальная дорожная карта
```

---

## 3. Технологический стек

| Слой | Технология | Версия |
|------|-----------|--------|
| **Frontend** | Flutter | 3.5.3 |
| **State Management** | flutter_riverpod | 2.5.0 |
| **Backend** | Fastify (Node.js) | 5.8.5 |
| **База данных** | PostgreSQL + PostGIS | 15+ |
| **Кэш** | Redis | 7+ |
| **Auth** | JWT (access + refresh) | jsonwebtoken |
| **Платежи** | Stripe | 22.0.2 |
| **Push** | Firebase Cloud Messaging | firebase_messaging |
| **Offline** | SQLite (sqflite) + SharedPreferences | - |

---

## 4. Фазы реализации (сводка)

| Фаза | Что реализовано | Статус |
|------|----------------|--------|
| 01 | Discovery: требования, persona, JTBD | ✅ |
| 02 | Architecture: C4 диаграммы, стек, БД | ✅ |
| 03 | Core Engine: AI-маршруты, POI, базовый backend | ✅ |
| 04 | Flutter UI: карты, списки, темы | ✅ |
| 05 | Smart Compass: AR-навигация, POI радар | ✅ |
| 06 | Language Shield: перевод, офлайн-кэш | ✅ |
| 07 | Интеграции: Stripe, бронирование, Pro UI | ✅ (mock) |
| 08 | Launch: Auth, Push, Offline, Store | ✅ |

---

## 5. API Endpoints

### Auth (новое в Phase 08)
```
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout
GET    /auth/me
PATCH  /auth/me
POST   /auth/password-reset-request
POST   /auth/password-reset
```

### Core (Phase 03)
```
GET    /health
GET    /routes
POST   /routes
GET    /routes/:id
POST   /ai/generate-route
POST   /poi/search
GET    /poi/:id
```

### Phase 07
```
GET    /bookings/search?city=
POST   /bookings
GET    /bookings
PATCH  /bookings/:id/cancel
POST   /payments/intent
POST   /payments/subscription
GET    /payments/subscription
DELETE /payments/subscription/:id
POST   /payments/split
```

### Phase 08
```
POST   /push/token
DELETE /push/token
GET    /push/notifications
PATCH  /push/notifications/:id/read
POST   /push/notifications/read-all
POST   /push/send
```

---

## 6. Таблицы базы данных

```sql
users                    ← + email_verified, reset_token
user_preferences
user_sessions            ← refresh токены, device info
poi
routes
route_stops
reviews
translation_cache
bookings
payments
subscriptions
split_payments
split_payment_participants
fcm_tokens               ← Phase 08
notifications            ← Phase 08
offline_routes           ← SQLite (Flutter)
offline_poi              ← SQLite (Flutter)
sync_queue               ← SQLite (Flutter)
```

---

## 7. Environment Variables (Backend)

```env
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost:5432/nomad
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key
OPENAI_API_KEY=sk-...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
GETYOURGUIDE_API_KEY=...
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
```

---

## 8. Как запустить Backend

```bash
cd nomad-app/phase-03-core-engine/backend
npm install
# Создать .env из .env.example
npm run migrate      # или: node migrations/run.js
npm run dev          # nodemon
```

Миграции Phase 08:
```bash
cd nomad-app/phase-08-launch/backend
node migrations/phase08.js
```

---

## 9. Как запустить Flutter

```bash
cd nomad-app/nomad_flutter_ui
flutter pub get

# Для Firebase:
# - положить google-services.json в android/app/
# - положить GoogleService-Info.plist в ios/Runner/

flutter run
```

---

## 10. Что ТРЕБУЕТ реальных ключей (ограничения)

| Компонент | Статус | Действие |
|-----------|--------|----------|
| Stripe | Mock UI | Нужны `pk_live_` / `sk_live_` + flutter_stripe |
| GetYourGuide | Mock данные | Нужен API ключ + реальный endpoint |
| Firebase | Шаблон | Нужен `google-services.json` / `.plist` |
| OpenAI | Работает | Нужен `OPENAI_API_KEY` |
| Deep Links | Не настроены | Нужен `uni_links` конфиг |
| App Store | Метаданные | Нужна подписка Apple Developer |
| Google Play | Метаданные | Нужна подписка Google Play Console |

---

## 11. Интерактивный прототип

Файл: `nomad-app/prototype.html`
- Открыть в браузере или на телефоне
- Все экраны кликабельны
- Auth flow, Routes, Compass, Translate, Profile, Pro

---

## 12. Архивы проекта

Все фазы упакованы в:
- `nomad-project.zip` (все фазы до Phase 07)
- `phase-08-launch.zip` (полный проект включая Phase 08)

---

## 13. Где искать контекст

- `USER.md` — предпочтения человека (language, workflow)
- `SOUL.md` — стиль агента (Stoic Advisor)
- `memory/` — ежедневные заметки
- `MEMORY.md` — долгосрочная память
- `SKILL.md` — инструкции по skills

---

## 14. Что делать следующему агенту

1. **Запустить backend локально** — проверить миграции и health endpoint
2. **Добавить Firebase конфиг** — push-уведомления заработают
3. **Интегрировать flutter_stripe** — UI готов, нужна нативная оплата
4. **Подключить реальный GetYourGuide API** — заменить mock
5. **Настроить deep links** — push → конкретный экран
6. **Добавить тесты** — unit + widget + integration
7. **Подготовить скриншоты для Store**
8. **Собрать beta-версию** — TestFlight / Internal Testing

---

*End of handover.*
