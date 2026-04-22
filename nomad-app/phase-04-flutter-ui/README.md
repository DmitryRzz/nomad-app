# NOMAD — Phase 04: Базовый Flutter UI

## Дата: 2026-04-22
## Статус: Завершён (MVP frontend)

---

## Что сделано

### 1. Flutter проект создан
- **Путь:** `nomad-app/nomad_flutter_ui/`
- **Платформы:** Android, iOS, Web
- **State management:** Riverpod
- **HTTP клиент:** `http`
- **Карты:** Google Maps Flutter
- **Геолокация:** Geolocator

### 2. Архитектура приложения
```
lib/
├── main.dart                    # Entry point + Theme
├── models/
│   └── route.dart              # Route, RouteStop, RouteGenerationRequest
├── providers/
│   └── route_provider.dart     # Riverpod state management
├── screens/
│   ├── routes_list_screen.dart # Список маршрутов
│   ├── route_detail_screen.dart # Детали маршрута + карта
│   └── create_route_screen.dart # Создание маршрута
└── services/
    └── api_service.dart        # HTTP client для backend API
```

### 3. Экраны

#### Routes List Screen (`routes_list_screen.dart`)
- AppBar с заголовком NOMAD
- Список карточек маршрутов
- Для каждого маршрута: название, город, статус, время, количество точек
- Цветные бейджи статуса (active/draft/completed)
- FAB "New Route" для создания
- Empty state если маршрутов нет
- Pull-to-refresh (через Riverpod)

#### Route Detail Screen (`route_detail_screen.dart`)
- **Карта** (Google Maps) с маркерами точек
- **Polyline** — линия маршрута между точками
- Информационные чипы: время, количество точек, город
- **Список остановок** с номерами
- Для каждой остановки:
  - Цветной аватар с номером
  - Название, категория, время
  - Иконка indoor/outdoor
  - Статус (посещено/пропущено/ожидает)
- Кнопка удаления маршрута

#### Create Route Screen (`create_route_screen.dart`)
- Поле ввода города (обязательное)
- Поле ввода страны (опциональное)
- **Чипы интересов** (art, food, history, nature, music, architecture, shopping, nightlife, sports)
- **Уровень бюджета** (1-5, с лейблами)
- **Темп маршрута** (Relaxed / Balanced / Intense — segmented button)
- Кнопка "Generate Route" с индикатором загрузки
- Валидация обязательных полей

### 4. State Management (Riverpod)

#### `routesProvider` — StateNotifierProvider
- `loadRoutes()` — загрузка списка с backend
- `createRoute(request)` — создание + обновление списка
- `deleteRoute(id)` — удаление + обновление списка
- Автоматический loading/error/data стейты

#### `selectedRouteProvider` — StateProvider
- Хранит выбранный маршрут для детального экрана

### 5. API Integration

#### ApiService (`api_service.dart`)
- `getUserRoutes()` → GET /routes
- `getRouteById(id)` → GET /routes/:id
- `createRoute(request)` → POST /routes
- `updateStopStatus(id, visited, skipped)` → PATCH /routes/stops/:id
- `deleteRoute(id)` → DELETE /routes/:id

**Base URL:** `http://localhost:3000` (для разработки)

### 6. Theme
- **Primary color:** Travel green (#2E7D32)
- **Material 3** дизайн
- Светлая/тёмная тема (system default)
- Скруглённые углы на карточках и кнопках

---

## Как запустить

### 1. Установить зависимости
```bash
cd nomad-app/nomad_flutter_ui
flutter pub get
```

### 2. Запустить backend (в отдельном терминале)
```bash
cd nomad-app/phase-03-core-engine/backend
npm start
```

### 3. Запустить Flutter (web для тестирования)
```bash
cd nomad-app/nomad_flutter_ui
flutter run -d chrome
```

Или для Android:
```bash
flutter run
```

### 4. Для Android — настроить API keys
В `android/app/src/main/AndroidManifest.xml` добавить:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

---

## Что работает сейчас

✅ Список маршрутов (mock data или backend)
✅ Создание маршрута (форма → backend → AI → отображение)
�️ Детали маршрута с картой
✅ Маркеры на карте
✅ Линия маршрута (polyline)
✅ Удаление маршрута
✅ Статусы остановок

---

## Что НЕ входит в Phase 4 (следующие этапы)

- **Smart Compass (AR)** — Phase 5
- **Real-time translation UI** — Phase 6
- **Social features** — Phase 7
- **Payment integration** — Phase 8
- **Push notifications** — Phase 8
- **Offline maps** — Phase 8
- **Authentication** — OAuth, email
- **User profile**
- **Route optimization** (reorder stops)
- **Sharing routes**

---

## Тестирование

### Создать тестовый маршрут:
1. Открыть приложение
2. Тап "New Route"
3. Ввести: City = "Paris"
4. Выбрать интересы: art, food
5. Budget = 3, Pace = balanced
6. Тап "Generate Route"
7. Ждём ответа от AI (5-10 секунд)
8. Видим новый маршрут в списке
9. Тап на маршрут → видим карту и точки

---

## Структура данных (для интеграции)

### Route
```json
{
  "id": "uuid",
  "title": "Paris Art & Food Tour",
  "city": "Paris",
  "country": "France",
  "status": "active",
  "estimated_duration_hours": 8.5,
  "stops": [
    {
      "id": "uuid",
      "poi_name": "Louvre Museum",
      "category": "museum",
      "description": "World's largest art museum",
      "duration_minutes": 180,
      "latitude": 48.8606,
      "longitude": 2.3376,
      "indoor": true,
      "visited": false
    }
  ]
}
```

---

## Следующий шаг

**Phase 5: Smart Compass (AR)** — AR-наложение меток через камеру.

Или **Phase 6: Language Shield UI** — интерфейс для голосового перевода.

Рекомендация: Phase 6 быстрее реализовать и приносит очевидную ценность.

**Согласен?**
