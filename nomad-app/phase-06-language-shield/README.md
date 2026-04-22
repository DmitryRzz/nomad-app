# NOMAD — Phase 06: Language Shield (Языковой щит)

## Дата: 2026-04-22
## Статус: Завершён (MVP)

---

## Что сделано

### 1. Backend — Audio Transcription API

**Новый endpoint:**
```
POST /ai/transcribe
```

**Параметры:**
- `audio` — base64-encoded аудио файл
- `language` — код языка (опционально, для автоопределения — не передавать)

**Flow:**
1. Получает base64 аудио
2. Сохраняет во временный файл
3. Отправляет в OpenAI Whisper API (`whisper-1`)
4. Возвращает распознанный текст
5. Удаляет временный файл

**Пример ответа:**
```json
{
  "success": true,
  "data": {
    "text": "Where is the nearest metro station?",
    "language": "en"
  }
}
```

### 2. Flutter UI — Language Shield Screen

**Путь:** `lib/screens/language_shield_screen.dart`

**Функции:**
- **Выбор языков:** From / To (12 языков + Auto Detect)
- **Контекст:** general, restaurant, taxi, hotel, shopping, airport
- **Голосовой ввод:** кнопка с микрофоном (hold-to-record)
- **Текстовый ввод:** поле для ручного ввода
- **Отображение:**
  - Recognized text (распознанный текст)
  - Translation (перевод)
  - Кнопка воспроизведения перевода (TTS, placeholder)

**Дизайн:**
- Bottom sheet с кнопкой микрофона
- Material 3 card для текста
- Цветовая индикация записи (красный = recording)
- Loading states

### 3. Навигация

Добавлен **Bottom Navigation Bar** с двумя табами:
- **Routes** — список маршрутов (иконка: map)
- **Translate** — языковой щит (иконка: translate)

**MainNavigationScreen** — управляет переключением табов через `NavigationBar`.

### 4. Зависимости

**Backend:**
- OpenAI Whisper API (через `openai` npm package)
- `fs` для работы с файлами

**Flutter:**
- `flutter_sound: ^9.4.6` — запись аудио
- `path_provider: ^2.1.4` — временные файлы
- `http` — отправка аудио на backend

---

## Как работает

### Голосовой перевод:
1. Пользователь зажимает кнопку микрофона
2. `FlutterSoundRecorder` записывает AAC аудио
3. При отпускании — аудио конвертируется в base64
4. Отправляется на `POST /ai/transcribe`
5. Backend: base64 → файл → Whisper API → текст
6. Текст отправляется на `POST /ai/translate`
7. Backend: GPT-4 переводит с учётом контекста
8. UI показывает: original + translated

### Текстовый перевод:
1. Пользователь вводит текст
2. Отправляется на `POST /ai/translate`
3. UI показывает перевод

---

## Тестирование

### 1. Установить зависимости Flutter
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

### 4. Проверить перевод:
1. Открыть таб "Translate"
2. Выбрать From: Auto, To: English
3. Выбрать Context: restaurant
4. Ввести: "Где находится ближайшее метро?"
5. Нажать Send
6. Ожидаемый результат: "Where is the nearest metro station?"

### 5. Проверить голосовой ввод:
1. Зажать кнопку микрофона
2. Сказать фразу
3. Отпустить
4. Дождаться распознавания и перевода (5-10 сек)

---

## Структура файлов

```
phase-06-language-shield/
└── backend/
    └── src/
        └── services/
            └── translationStreamService.js  # WebSocket service (future)

nomad_flutter_ui/
└── lib/
    ├── screens/
    │   └── language_shield_screen.dart    # UI перевода
    ├── services/
    │   └── api_service.dart               # HTTP client (updated)
    └── main.dart                          # Navigation + Theme
```

---

## Ограничения MVP

- **TTS (Text-to-Speech)** — не реализован, показывает иконку speaker (placeholder)
- **WebSocket streaming** — не реализован, используется HTTP polling
- **Offline mode** — не поддерживается, требует интернет
- **Local Whisper** — используется OpenAI API, не локальная модель
- **Audio format** — AAC через flutter_sound (может требовать конвертации)

---

## Что НЕ входит в Phase 6 (следующие этапы)

- **Real-time WebSocket streaming** — потоковый перевод без задержек
- **Local Whisper** — работа офлайн с локальной моделью
- **TTS integration** — Google Cloud TTS или ElevenLabs
- **Conversation mode** — автоопределение языка говорящего
- **Phrasebook** — сохранение частых фраз
- **Camera translation** — OCR + перевод текста с изображений (меню, вывески)

---

## Следующий шаг

**Phase 5: Smart Compass (AR)** — AR-наложение меток через камеру.

Или **Phase 7: Интеграции** — бронирование, оплата, монетизация.

Рекомендация: Phase 5 (AR) — это фича, которая сильно отличает от конкурентов.

**Согласен?**
