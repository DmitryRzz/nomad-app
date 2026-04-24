# NOMAD AI Travel Planner

AI-powered travel planning app with Flutter frontend, Node.js backend, and offline support.

## Architecture

```
nomad-app/
├── backend/              # Node.js + Fastify + SQLite
│   ├── server.js         # Main API server (port 3000)
│   └── package.json
├── nomad_flutter_ui/     # Flutter mobile app
│   ├── lib/
│   │   ├── screens/      # UI screens (Sunset theme)
│   │   ├── services/     # API, offline sync, push
│   │   ├── models/       # Data models
│   │   └── theme/        # Sunset gradient theme
│   └── pubspec.yaml
├── prototype.html        # Interactive HTML demo
├── landing.html          # Marketing website
├── assets/               # Store assets
│   ├── icon.svg
│   ├── splash.html
│   ├── store-screenshots/
│   ├── PRIVACY_POLICY.md
│   ├── TERMS_OF_SERVICE.md
│   └── store_metadata.json
├── designs/              # 5 UI themes (HTML)
│   └── sunset.html       # Selected: Sunset Vibes
├── codemagic.yaml        # CI/CD for mobile builds
└── README.md
```

## Features

- ✨ **AI Route Generation** — Create itineraries from destination + budget + style
- 📍 **Smart Compass** — Navigate to nearby POIs
- 📅 **Day-by-Day View** — Timeline with activity tracking
- 💾 **Offline Access** — localStorage + Service Worker
- 🛡️ **Language Shield** — Offline phrasebook
- 💰 **Budget Modes** — Budget / Moderate / Luxury
- 🔔 **Push Notifications** — Trip reminders

## Quick Start

### Backend
```bash
cd backend
npm install
node server.js
# API runs on http://localhost:3000
```

### HTML Demo (iPhone Test)
```bash
python3 -m http.server 8888
# Open http://localhost:8888/prototype.html
```

### Flutter (Future)
```bash
cd nomad_flutter_ui
flutter pub get
flutter build web --release
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /auth/register | Create account |
| POST | /auth/login | Sign in |
| POST | /auth/refresh | Refresh token |
| GET | /auth/me | Current user |
| GET | /routes | User routes |
| GET | /routes/demo | Demo routes (no auth) |
| POST | /trips/generate | AI route generation |
| GET | /poi/:city | Points of interest |

## Design System: Sunset Vibes

- **Gradient**: `#ff6b6b` → `#feca57` → `#ff9ff3` → `#54a0ff`
- **Cards**: Glassmorphism with `backdrop-filter: blur(20px)`
- **Text**: White on gradient, dark (`#2D3436`) on white cards
- **Badges**: Sunset gradient pills

## Store Assets

- Screenshots: `assets/store-screenshots/`
- Description: `assets/app_store_description.txt`
- Privacy Policy: `assets/PRIVACY_POLICY.md`
- Terms: `assets/TERMS_OF_SERVICE.md`
- Metadata: `assets/store_metadata.json`

## Deployment

### Mobile (via Codemagic)
1. Connect GitHub repo to Codemagic
2. Configure signing certificates
3. Build iOS `.ipa` and Android `.aab`
4. Submit to App Store / Google Play

### Web Demo
- Currently served via localtunnel
- Flutter web build available in `build/web/`

## GitHub

https://github.com/DmitryRzz/nomad-app

## License

MIT License — See LICENSE file
