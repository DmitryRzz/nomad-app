# NOMAD — Phase 05: Smart Compass (AR)

## Дата: 2026-04-22
## Статус: Завершён (MVP)

---

## Что сделано

### 1. Backend — POI API

**Новые endpoints:**
```
GET /poi/nearby?lat=...&lng=...&radius=500&category=...&interests=...
GET /poi/:id
GET /poi/city/:city?category=...&limit=50
```

**POIService:**
- `findNearby()` — PostGIS spatial query с радиусом и фильтрацией
- `getById()` — детали POI
- `getByCity()` — список по городу
- Релевантность: сортировка по интересам пользователя

**PostGIS запрос:**
- `ST_DWithin` — поиск в радиусе
- `ST_Distance` — расстояние в метрах
- `ST_SetSRID(ST_MakePoint(...), 4326)::geography` — геопространственные типы

### 2. Flutter UI — Smart Compass Screen

**Путь:** `lib/screens/smart_compass_screen.dart`

**Функции:**
- **Камера на фоне** — `CameraController` с back camera
- **POI метки поверх камеры** — Positioned виджеты с координатами
- **Геолокация** — `Geolocator` для позиции пользователя
- **Магнетометр** — heading (направление устройства)
- **Акселерометр** — pitch и roll

**Расчёты:**
- **Bearing** — направление к POI от пользователя
- **Distance** — расстояние до POI (haversine formula)
- **Screen position** — проекция угла на экран
- **Field of view** — 60°, показывает только POI в поле зрения

**UI элементы:**
- Полупрозрачные карточки POI поверх камеры
- Цветные рамки по категориям (food=orange, museum=purple, landmark=blue)
- Иконки категорий
- Расстояние и рейтинг
- Top info bar: heading (компас) + количество видимых POI
- Bottom filters: All, Food, Sight, Shop

**Bottom Sheet детали:**
- Тап на POI → открывает детали
- Название, описание, расстояние, адрес, цена
- Кнопка "Add to Route"

### 3. Навигация обновлена

**3 таба:**
- Routes (иконка map)
- Compass (иконка explore)
- Translate (иконка translate)

---

## Как работает

1. Открываем Compass таб
2. Камера активируется (back camera)
3. Получаем GPS координаты пользователя
4. Запрашиваем POI в радиусе 500м с backend
5. Магнетометр определяет направление телефона
6. Для каждого POI:
   - Рассчитываем bearing (угол к POI)
   - Проверяем, попадает ли в field of view (60°)
   - Рассчитываем экранные координаты
7. Отображаем метки поверх камеры
8. Фильтры позволяют скрыть нерелевантные категории

---

## Зависимости

**Backend:**
- PostGIS extension
- poi таблица с координатами

**Flutter:**
- `camera: ^0.11.0` — доступ к камере
- `sensors_plus: ^6.1.0` — магнетометр и акселерометр
- `geolocator: ^12.0.0` — GPS
- `google_maps_flutter` — уже был

---

## Тестирование

### 1. Установить зависимости
```bash
cd nomad-app/nomad_flutter_ui
flutter pub get
```

### 2. Запустить backend
```bash
cd nomad-app/phase-03-core-engine/backend
npm start
```

### 3. Запустить Flutter
```bash
cd nomad-app/nomad_flutter_ui
flutter run
```

### 4. Проверить Compass:
1. Открыть таб "Compass"
2. Разрешить доступ к камере и геолокации
3. Навести телефон на город
4. Увидеть метки POI поверх камеры
5. Тапнуть на метку → детали
6. Нажать фильтр "Food" → только рестораны

---

## Ограничения MVP

- **Pseudo-AR** — метки позиционируются по углу, без реального AR (ARKit/ARCore)
- **Нет калибровки компаса** — может требовать figure-8 движение для калибровки
- **Фиксированный FOV** — 60°, не адаптируется под зум камеры
- **Не учитывает высоту** — POI на разных этажах показываются одинаково
- **Нет 3D позиционирования** — метки на одной плоскости
- **Нет реального построения маршрута** — "Add to Route" placeholder

---

## Что НЕ входит в Phase 5 (следующие этапы)

- **True AR** — ARCore/ARKit с plane detection
- **3D метки** — метки на разной высоте
- **Indoor AR** — метки внутри зданий
- **Навигационные стрелки** — стрелки на полу
- **Социальные метки** — где находятся друзья
- **Real-time обновление** — POI появляются/исчезают динамически

---

## Следующий шаг

**Phase 7: Интеграции и Монетизация**
- Бронирование отелей/экскурсий
- Оплата (Stripe)
- Pro-подписка
- Сплит-оплата

Или **Phase 8: Полировка и Запуск**
- Auth (OAuth)
- Push notifications
- Offline maps
- ASO и публикация

Рекомендация: Phase 7 добавляет реальную монетизацию.

**Согласен?**
