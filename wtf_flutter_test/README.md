# WTF Flutter Test — AI-Native Assignment

Two Flutter mobile applications (Guru App + Trainer App) with 100ms video calling, real-time chat, call scheduling, and session logging.

## Quick Start

### Prerequisites
- Flutter 3.3.0+
- Node.js 18+
- Two Android devices on same WiFi as dev machine

### 1. Start Token Server
```bash
cd token_server
cp .env.example .env    # Add your 100ms credentials
npm install
npm start               # Runs on http://0.0.0.0:3000
```

### 2. Update Server IP
Edit `shared/lib/config/app_config.dart` — set `serverUrl` to your Mac's local IP:
```dart
static const String serverUrl = "http://192.168.0.122:3000";
```

### 3. Run Apps
```bash
# Terminal 1 — Guru App (Member)
cd guru_app && flutter run -d <device1_id>

# Terminal 2 — Trainer App
cd trainer_app && flutter run -d <device2_id>
```

## Architecture
See [ARCHITECTURE.md](ARCHITECTURE.md)

## AI Usage
See [AI_LEDGER.md](AI_LEDGER.md)

## Decisions
See [DECISIONS.md](DECISIONS.md)
