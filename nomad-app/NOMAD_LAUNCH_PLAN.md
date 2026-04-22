# NOMAD — План от текущего момента до листинга
## AI Travel Planner | Реальное конкурентоспособное приложение

> Дата: 2026-04-23
> Статус: Phase 08 завершена (MVP backend + Flutter UI)
> Цель: Листинг в App Store & Google Play с монетизацией

---

## ЭТАП 1: Фундамент (Неделя 1-2)

### 1.1 Инфраструктура
- [ ] **Купить домен**: nomad.app / go-nomad.com / nomad-ai.travel
- [ ] **SSL сертификат**: Let's Encrypt (авто) или Cloudflare
- [ ] **Облачный сервер**: 
  - VPS: DigitalOcean $24/мес (2vCPU, 4GB RAM) — достаточно для старта
  - Альтернатива: Hetzner Cloud (дешевле, €8/мес)
- [ ] **CDN**: Cloudflare (free tier) — кэширование, DDoS защита
- [ ] **Мониторинг**: UptimeRobot (free) + Sentry (free tier) для ошибок

### 1.2 Backend Production
- [ ] **Docker-контейнеризация**:
  ```dockerfile
  # Dockerfile для Fastify + Node.js
  FROM node:20-alpine
  WORKDIR /app
  COPY package*.json ./
  RUN npm ci --only=production
  COPY . .
  EXPOSE 3000
  CMD ["node", "src/app.js"]
  ```
- [ ] **Docker Compose**: PostgreSQL + Redis + Backend + Nginx
- [ ] **CI/CD Pipeline** (GitHub Actions):
  - Автоматический deploy на push в main
  - Запуск тестов
  - Сборка и push Docker image
- [ ] **Миграции БД**: автоматический запуск при deploy
- [ ] **Бэкапы БД**: ежедневные automated backups (pg_dump → S3)

### 1.3 Environment
- [ ] Создать `.env.production` с реальными ключами
- [ ] **Stripe**: перейти с test на live ключи
- [ ] **OpenAI**: проверить лимиты и стоимость API
- [ ] **Firebase**: создать production проект (отдельно от dev)

---

## ЭТАП 2: Безопасность и стабильность (Неделя 2-3)

### 2.1 Auth & Security
- [ ] **Rate limiting**: 100 req/min на endpoint, 5 login attempts
- [ ] **CORS**: whitelist только app domains
- [ ] **Helmet.js**: security headers (HSTS, CSP, X-Frame-Options)
- [ ] **Input validation**: Joi/Zod на все endpoints
- [ ] **SQL injection защита**: проверить все raw queries → parameterized
- [ ] **XSS защита**: sanitize user-generated content
- [ ] **API versioning**: `/v1/` prefix для всех routes

### 2.2 Тестирование
- [ ] **Unit tests**: Jest для backend (>70% coverage)
- [ ] **Integration tests**: Supertest для API endpoints
- [ ] **Flutter widget tests**: для всех screens
- [ ] **Flutter integration tests**: end-to-end flow
- [ ] **Load testing**: k6 или Artillery (100 concurrent users)

### 2.3 Логирование
- [ ] **Structured logging**: Pino или Winston (JSON format)
- [ ] **Error tracking**: Sentry integration
- [ ] **Performance monitoring**: New Relic (free tier) или Datadog
- [ ] **API analytics**: количество запросов, latency, ошибки

---

## ЭТАП 3: Реальные интеграции (Неделя 3-4)

### 3.1 Stripe Live
- [ ] **Stripe Dashboard**: активировать live mode
- [ ] **Payment Intent**: тестировать с реальной картой ($1 charge)
- [ ] **Webhook endpoint**: `/payments/webhook` для событий
- [ ] **Subscription management**: обработка cancel, upgrade, downgrade
- [ ] **Receipts**: настроить email receipts через Stripe
- [ ] **Tax**: Stripe Tax для автоматического VAT
- [ ] **Flutter stripe**: интегрировать `flutter_stripe` (Payment Sheet)

### 3.2 GetYourGuide API
- [ ] **Apply for API access**: https://partner.getyourguide.com/
- [ ] **API credentials**: получить production key
- [ ] **Search integration**: реальный поиск экскурсий по городу
- [ ] **Booking flow**: affiliate links или API booking
- [ ] **Commission tracking**: отслеживать конверсии

### 3.3 Альтернативные бронирования
- [ ] **Viator API**: запасной вариант экскурсий
- [ ] **Booking.com API**: отели (опционально)
- [ ] **Rome2Rio API**: транспорт между городами
- [ ] **Skyscanner API**: авиабилеты (affiliate)

### 3.4 AI-маршруты улучшение
- [ ] **OpenAI GPT-4**: тонкая настройка промптов
- [ ] **Caching**: Redis cache для сгенерированных маршрутов (24h)
- [ ] **Fallback**: если AI недоступен — показывать шаблонные маршруты
- [ ] **Cost optimization**: использовать GPT-3.5 для простых запросов

---

## ЭТАП 4: Flutter Polish (Неделя 4-5)

### 4.1 Performance
- [ ] **App startup time**: < 2 seconds cold start
- [ ] **Image optimization**: WebP, lazy loading, caching
- [ ] **List optimization**: ListView.builder + pagination
- [ ] **Memory management**: dispose controllers, cancel streams
- [ ] **Bundle size**: analyze with `flutter build apk --analyze-size`

### 4.2 UX/UI Improvements
- [ ] **Splash screen**: анимированный логотип
- [ ] **Onboarding**: 3-4 экрана с преимуществами приложения
- [ ] **Empty states**: красивые иллюстрации для пустых списков
- [ ] **Error states**: retry buttons, offline indicators
- [ ] **Skeleton loading**: shimmer эффекты вместо спиннеров
- [ ] **Haptic feedback**: вибрация на важных действиях
- [ ] **Dark mode**: полная поддержка (уже начато)

### 4.3 Accessibility
- [ ] **Screen readers**: Semantics для всех элементов
- [ ] **Font scaling**: поддержка dynamic text size
- [ ] **Color contrast**: WCAG AA compliance
- [ ] **Touch targets**: минимум 48x48 dp

### 4.4 Localization
- [ ] **i18n**: ARB файлы для Flutter
- [ ] **Языки**: English, Russian, Spanish, French, German, Japanese, Chinese
- [ ] **RTL**: поддержка арабского и иврита
- [ ] **Date/time formatting**: intl package

---

## ЭТАП 5: Firebase и Push (Неделя 5)

### 5.1 Firebase Setup
- [ ] **Production project**: отдельный от dev
- [ ] **Google Services JSON**: для Android
- [ ] **Google Service Info Plist**: для iOS
- [ ] **Firebase Auth**: anonymous auth для onboarding
- [ ] **Firebase Analytics**: track screen views, events
- [ ] **Firebase Crashlytics**: автоматические краш-репорты
- [ ] **Firebase Performance**: network monitoring

### 5.2 Push Notifications
- [ ] **FCM topics**: `news`, `deals`, `trips`
- [ ] **Rich notifications**: images, actions (buttons)
- [ ] **Scheduled notifications**: напоминания о поездке
- [ ] **Geofenced notifications**: при приближении к POI
- [ ] **Notification preferences**: пользователь выбирает что получать

### 5.3 Deep Links
- [ ] **Universal Links** (iOS): `https://nomad.app/routes/123`
- [ ] **App Links** (Android): аналогично
- [ ] **Dynamic Links**: share route with friends
- [ ] **Deferred deep links**: после install из рекламы

---

## ЭТАП 6: Offline & Sync (Неделя 5-6)

### 6.1 Offline First
- [ ] **WorkManager**: фоновая синхронизация (Android)
- [ ] **Background Fetch**: фоновая синхронизация (iOS)
- [ ] **Conflict resolution**: last-write-wins или merge
- [ ] **Offline indicator**: UI badge когда нет сети
- [ ] **Queue UX**: показывать "syncing..." в профиле

### 6.2 Maps Offline
- [ ] **Mapbox Offline**: скачивание регионов
- [ ] **Google Maps Offline**: альтернатива
- [ ] **Custom tiles**: MBTiles для компактности
- [ ] **Route caching**: сохранять маршруты в SQLite

---

## ЭТАП 7: Analytics и Growth (Неделя 6-7)

### 7.1 Analytics Stack
- [ ] **Firebase Analytics**: базовые метрики (DAU, retention)
- [ ] **Mixpanel**: воронки, когортный анализ, event tracking
  - События: `route_created`, `translation_used`, `booking_made`, `subscription_started`
- [ ] **Amplitude**: аналог Mixpanel (выбрать один)
- [ ] **RevenueCat**: analytics для подписок (опционально)

### 7.2 Growth Features
- [ ] **Referral program**: "Приведи друга — месяц Pro бесплатно"
- [ ] **Share routes**: deep link на маршрут → открыть в app
- [ ] **Social sharing**: Instagram Stories с маршрутом
- [ ] **Trip journals**: пользователь делится опытом (UGC)
- [ ] **Reviews**: оценки маршрутов, POI

### 7.3 ASO (App Store Optimization)
- [ ] **Keywords research**: travel planner, trip organizer, AI travel
- [ ] **Title optimization**: "NOMAD — AI Travel Planner & Trip Organizer"
- [ ] **Subtitle**: "Smart routes, offline maps, language translator"
- [ ] **Description**: A/B тестировать
- [ ] **Screenshots**: 5-8 скриншотов с текстом
- [ ] **Preview video**: 30 секунд (App Store)
- [ ] **A/B тесты**: Google Play Experiments

---

## ЭТАП 8: Монетизация (Неделя 7-8)

### 8.1 Revenue Streams

| Источник | Модель | Ожидаемый % |
|----------|--------|-------------|
| **Pro Subscription** | $9.99/мес, $79.99/год | 60% |
| **Booking Affiliate** | 8-15% commission | 25% |
| **Ads (Free tier)** | Rewarded video, native | 10% |
| **Data/API** | B2B: white-label | 5% |

### 8.2 Subscription Optimization
- [ ] **Paywall A/B**: экран до/после onboarding
- [ ] **Free trial**: 7 или 14 дней
- [ ] **Annual discount**: 33% off (save $40)
- [ ] **Family Plan**: до 5 человек
- [ ] **Student discount**: 50% с .edu email
- [ ] **Win-back offers**: для churned users

### 8.3 Affiliate Partners
- [ ] **GetYourGuide**: 8% commission
- [ ] **Viator**: 8% commission  
- [ ] **Booking.com**: 4% commission
- [ ] **Klook**: 5-8% commission (Asia)
- [ ] **Airbnb Experiences**: affiliate
- [ ] **Rentalcars**: 7% commission

### 8.4 Ads (только Free tier)
- [ ] **Rewarded video**: 2x coins for watching ad
- [ ] **Native ads**: в списке маршрутов (не навязчиво)
- [ ] **Interstitial**: между экранами (редко)
- [ ] **AdMob**: Google (легко интегрировать)
- [ ] **IronSource**: mediation для лучшего fill rate

---

## ЭТАП 9: Store Preparation (Неделя 8-9)

### 9.1 App Store (iOS)
- [ ] **Apple Developer**: $99/год подписка
- [ ] **App Store Connect**: создать приложение
- [ ] **Bundle ID**: `com.nomad.travelplanner`
- [ ] **App Icon**: 1024x1024 + все размеры
- [ ] **Screenshots**: iPhone 15 Pro, iPhone SE, iPad Pro
- [ ] **App Preview Video**: 30 sec, 15-30 fps
- [ ] **Privacy Nutrition Label**: заполнить
- [ ] **App Review Guidelines**: проверить соответствие
- [ ] **TestFlight**: internal testing (100 users)
- [ ] **Beta Testing**: External Testers (10,000 users)

### 9.2 Google Play (Android)
- [ ] **Google Play Console**: $25 one-time
- [ ] **AAB Bundle**: `flutter build appbundle`
- [ ] **KeyStore**: securely backup signing key
- [ ] **Feature Graphic**: 1024x500 PNG
- [ ] **Screenshots**: phone (16:9), tablet (16:9, 4:3)
- [ ] **Promo Video**: YouTube link
- [ ] **Content Rating**: ESRB / PEGI questionnaire
- [ ] **Data Safety Form**: заполнить
- [ ] **Internal Testing**: 100 testers
- [ ] **Closed Testing**: 200 testers
- [ ] **Open Testing**: public beta

### 9.3 Общие требования
- [ ] **Privacy Policy**: страница на сайте
- [ ] **Terms of Service**: страница на сайте
- [ ] **Support URL**: email или чат
- [ ] **Marketing URL**: лендинг на сайте
- [ ] **Contact Info**: адрес компании (для EU)

---

## ЭТАП 10: Запуск (Неделя 9-10)

### 10.1 Pre-Launch
- [ ] **Press Kit**: логотипы, скриншоты, описание
- [ ] **Landing Page**: nomad.app с CTA (download)
- [ ] **Social Media**: Instagram, TikTok, Twitter/X
- [ ] **Beta Community**: Telegram/Discord группа ранних пользователей
- [ ] **Influencer Outreach**: travel bloggers, TikTok creators
- [ ] **Product Hunt**: подготовить launch page

### 10.2 Soft Launch
- [ ] **1 страна**: например, Таиланд или Япония
- [ ] **Small cohort**: 1000 organic installs
- [ ] **Metrics to track**:
  - Day 1 retention > 40%
  - Day 7 retention > 20%
  - ARPDAU > $0.10
  - Conversion to Pro > 3%
- [ ] **Feedback loop**: in-app survey, email support

### 10.3 Global Launch
- [ ] **Phased rollout**: 10% → 50% → 100%
- [ ] **Paid UA**: Facebook Ads, Google Ads, TikTok Ads
  - Target: travelers, backpackers, digital nomads
  - Creative: видео "How I planned Tokyo in 5 minutes"
- [ ] **ASO burst**: закупка инсталлов для подъема в чартах
- [ ] **PR**: press releases, travel media coverage

---

## ЭТАП 11: Пост-лаунч (Неделя 10+)

### 11.1 Feature Roadmap v2
- [ ] **Collaborative planning**: планировать с друзьями
- [ ] **AI Travel Agent**: ChatGPT-like интерфейс
- [ ] **Itinerary import**: из Google Maps, TripIt
- [ ] **Local deals**: рестораны, кафе со скидками
- [ ] **Travel insurance**: интеграция с SafetyWing
- [ ] **eSIM**: интеграция с Holafly / Airalo
- [ ] **Weather AI**: "Pack umbrella on Tuesday"
- [ ] **Currency converter**: real-time + offline
- [ ] **Emergency SOS**: местные emergency numbers
- [ ] **Public transport**: routes, tickets, schedules

### 11.2 Рынки расширения
- [ ] **B2B**: white-label для tour operators
- [ ] **API access**: продавать маршруты другим apps
- [ ] **Travel agencies**: bulk licenses
- [ ] **Airlines**: in-flight entertainment integration
- [ ] **Hotels**: concierge digital twin

### 11.3 Масштабирование
- [ ] **Kubernetes**: для auto-scaling backend
- [ ] **CDN**: Cloudflare Pro ($20/мес)
- [ ] **Database**: PostgreSQL read replicas
- [ ] **Redis Cluster**: для кэширования
- [ ] **Monitoring**: Datadog или New Relic paid
- [ ] **Support**: Zendesk или Intercom ($59/мес)

---

## Бюджет оценочный

| Статья | Месяц 1-3 | Месяц 4-6 | Месяц 7-12 |
|--------|-----------|-----------|------------|
| Server (VPS) | $24 | $48 | $96 |
| Firebase (Spark) | Free | Free | $25 (Blaze) |
| Stripe (транзакции) | 2.9% + 30¢ | 2.9% + 30¢ | 2.9% + 30¢ |
| Sentry | Free | $26 | $26 |
| Mixpanel | Free | Free | $0 (до 10M events) |
| App Store | $99/год | - | - |
| Google Play | $25 one-time | - | - |
| Domain | $12/год | - | - |
| Cloudflare | Free | Free | $20 |
| **Итого fixed** | **~$50/мес** | **~$74/мес** | **~$167/мес** |
| Marketing (UA) | $500 | $2,000 | $5,000+ |

---

## Ключевые метрики успеха

| Метрика | Цель месяц 1 | Цель месяц 6 | Цель год 1 |
|---------|--------------|--------------|------------|
| Downloads | 1,000 | 50,000 | 500,000 |
| DAU | 200 | 5,000 | 40,000 |
| Day 7 Retention | 20% | 25% | 30% |
| Conversion Free→Pro | 2% | 4% | 5% |
| MRR (Monthly Recurring) | $200 | $10,000 | $100,000 |
| ARPPU (Avg Revenue Per Paying User) | $9.99 | $12 | $15 |
| NPS Score | 30 | 40 | 50 |
| App Store Rating | 4.2 | 4.5 | 4.7 |

---

## Чеклист перед листингом

### Must Have
- [ ] Backend deployed и стабильно работает 7 дней
- [ ] Все API endpoints протестированы
- [ ] Flutter app не крашится на iOS 15+ и Android 10+
- [ ] Auth flow работает (register → login → logout)
- [ ] Push notifications доставляются
- [ ] Offline mode работает (flight mode test)
- [ ] Платежи проходят (тестовая карта + реальная)
- [ ] Privacy Policy и Terms размещены на сайте
- [ ] Support email работает и отвечает

### Should Have
- [ ] App review guidelines прочитаны и соблюдены
- [ ] Accessibility проверена (VoiceOver, TalkBack)
- [ ] Localization для топ-5 рынков
- [ ] Analytics events настроены
- [ ] Crashlytics показывает 0 critical bugs

### Nice to Have
- [ ] Промо-видео готово
- [ ] Press kit готов
- [ ] Landing page live
- [ ] Social media accounts созданы
- [ ] 100 beta testers протестировали

---

*End of plan. Ready for execution.*
