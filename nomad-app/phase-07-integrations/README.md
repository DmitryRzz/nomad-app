# NOMAD — Phase 07: Интеграции и Монетизация

## Дата: 2026-04-22
## Статус: Завершён (MVP backend + UI)

---

## Что сделано

### 1. Booking Service (Экскурсии и активности)

**Backend:** `services/bookingService.js`
- `searchActivities(city, date, adults)` — поиск через GetYourGuide API (с mock fallback)
- `createBooking()` — создание бронирования в БД
- `getUserBookings()` — список бронирований пользователя
- `cancelBooking()` — отмена бронирования

**API Endpoints:**
```
GET  /bookings/search?city=Paris&date=2026-05-01&adults=2
POST /bookings              — создать бронирование
GET  /bookings              — мои бронирования
PATCH /bookings/:id/cancel  — отменить
```

**Таблица bookings:**
- activity_id, activity_name, provider
- booking_date, adults, children
- total_price, currency, status
- contact_email, contact_phone

### 2. Payment Service (Stripe)

**Backend:** `services/paymentService.js`
- `createPaymentIntent()` — создание платежа (Stripe)
- `recordPayment()` — запись в БД
- `refundPayment()` — возврат
- `createSubscription()` — подписка Pro
- `cancelSubscription()` — отмена подписки
- `createSplitPayment()` — разделённый платёж

**API Endpoints:**
```
POST /payments/intent         — создать payment intent
POST /payments/record         — записать платёж
GET  /payments/history        — история платежей
POST /payments/subscription   — создать подписку
GET  /payments/subscription   — активная подписка
DELETE /payments/subscription/:id — отмена
POST /payments/split          — разделённый платёж
```

**Таблицы:**
- payments — stripe_payment_intent_id, amount, status
- subscriptions — stripe_customer_id, plan_type, period
- split_payments — total_amount, participant_count
- split_payment_participants — user_id, amount, status

### 3. Monetization — Pro Subscription

**Планы:**
- **Free:** 3 маршрута/мес, базовые функции
- **Pro ($9.99/мес):** безлимит, AR, офлайн, приоритет
- **Team ($29.99/мес):** 5 человек, shared routes, API

**Flutter UI:** `screens/subscription_screen.dart`
- Карточки планов с ценами и фичами
- "Recommended" бейдж на Pro
- FAQ секция
- Placeholder для Stripe интеграции

### 4. Навигация обновлена

**4 таба + 1 модальный:**
- Routes | Compass | Translate | Pro
- Pro открывает fullscreen SubscriptionScreen

---

## Новые зависимости

**Backend:**
- `stripe` — платежи
- `axios` — API вызовы (уже был)

**Flutter:**
- Для полной интеграции нужен `flutter_stripe` (не добавлен в MVP)

---

## Тестирование

### Бронирование:
```bash
curl "http://localhost:3000/bookings/search?city=Paris&adults=2"
```

### Платёж:
```bash
curl -X POST http://localhost:3000/payments/intent \
  -H "Content-Type: application/json" \
  -d '{"amount": 99.99, "currency": "USD"}'
```

---

## Ограничения MVP

- **Stripe** — требует реальных API ключей (сейчас placeholder)
- **GetYourGuide API** — mock данные без реального ключа
- **flutter_stripe** — не интегрирован (требует настройки)
- **Webhooks** — не настроены для Stripe callbacks
- **Split payment UI** — не создано (только backend)

---

## Что НЕ входит в Phase 7 (следующие этапы)

- **Stripe Connect** — для выплат партнёрам
- **In-app purchases** — Apple/Google native billing
- **Promo codes** — скидочные купоны
- **Referral system** — приведи друга
- **Analytics dashboard** — метрики для админов
- **Affiliate tracking** — отслеживание конверсий

---

## Следующий шаг

**Phase 8: Полировка и Запуск**
- Auth (OAuth, email)
- Push notifications (Firebase)
- Offline maps
- ASO + публикация в сторы

**Согласен?**
