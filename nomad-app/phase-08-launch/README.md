# Phase 08 — Полировка и Запуск (Launch)

## Что реализовано

### 1. Auth Flow (Аутентификация)

**Backend:**
- `POST /auth/register` — регистрация с валидацией
- `POST /auth/login` — вход
- `POST /auth/refresh` — обновление access токена
- `POST /auth/logout` — выход (отзыв сессий)
- `GET /auth/me` — текущий пользователь
- `PATCH /auth/me` — обновление профиля
- `POST /auth/password-reset-request` — запрос сброса пароля
- `POST /auth/password-reset` — сброс пароля по токену
- JWT access (15 мин) + refresh (7 дней) токены
- Хранение хешей refresh токенов в БД
- Мульти-сессии (device-based)

**Flutter:**
- Welcome screen с onboarding
- Login screen с валидацией
- Register screen с подтверждением пароля
- Profile screen со статистикой и настройками
- Auth provider (Riverpod) с автопроверкой токена
- Автоматический logout при истечении сессии

### 2. Push-уведомления

**Backend:**
- `POST /push/token` — регистрация FCM токена
- `DELETE /push/token` — удаление токена
- `GET /push/notifications` — список уведомлений с пагинацией
- `PATCH /push/notifications/:id/read` — прочитать
- `POST /push/notifications/read-all` — прочитать все
- `POST /push/send` — отправка (admin)
- Firebase Admin SDK интеграция

**Flutter:**
- Firebase Cloud Messaging
- Локальные уведомления (flutter_local_notifications)
- Deep links из уведомлений
- Кэширование уведомлений offline
- Топики для групповых рассылок

### 3. Offline Mode

**SQLite кэш:**
- `offline_routes` — кэш маршрутов
- `offline_poi` — кэш точек интереса
- `sync_queue` — очередь действий при offline
- `offline_notifications` — кэш уведомлений

**Sync Service:**
- Автоочередь при отсутствии сети
- Retry logic (до 5 попыток)
- Приоритизация (bookings > routes > другое)
- Progress stream

### 4. App Store / Google Play

**Подготовка:**
- App icons placeholders
- Скриншоты guidelines
- Store descriptions (ru/en)
- Privacy policy template
- Terms of service template

## Миграции

Запустить:
```bash
cd backend
node migrations/phase08.js
```

## Зависимости

**Backend (дополнительно):**
- `firebase-admin` — FCM отправка
- `bcryptjs` — хеширование паролей (уже в проекте)

**Flutter (дополнительно):**
- `firebase_core`
- `firebase_messaging`
- `flutter_local_notifications`
- `shared_preferences`
- `sqflite`
- `connectivity_plus`
- `uni_links`

## Конфигурация

### Firebase
1. Создать проект в Firebase Console
2. Добавить Android/iOS приложения
3. Скачать `google-services.json` (Android) и `GoogleService-Info.plist` (iOS)
4. Добавить в проект
5. Скопировать `firebase-adminsdk` JSON в `FIREBASE_SERVICE_ACCOUNT` env

### API URL
В `lib/services/api_service.dart` заменить:
```dart
static const String baseUrl = 'https://your-api.com';
```

## Следующие шаги

- [ ] Интеграция реальных Stripe ключей
- [ ] Подключение GetYourGuide API
- [ ] flutter_stripe интеграция
- [ ] App Store Review подготовка
- [ ] Google Play Console публикация
- [ ] Firebase Crashlytics
- [ ] Analytics (Amplitude / Mixpanel)
