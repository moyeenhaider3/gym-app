# Execution Plan — Flutter AI-Native

## Sub-Plan Execution Order

| # | Sub-Plan | Status | Duration | Validation Gate |
|---|----------|--------|----------|-----------------|
| 1 | repo-scaffold | ✅ Done | 20 min | Both apps compile + run |
| 2 | data-models | ✅ Done | 15 min | dart analyze clean on shared/ |
| 3 | shared-services | ✅ Done | 20 min | Services compile, barrel exports work |
| 4 | token-server | ✅ Done | 15 min | npm start, GET /api/health returns 200 |
| 5 | auth-onboarding | ✅ Done | 10 min | Login as DK, login as Aarav |
| 6 | chat | ✅ Done | 30 min | Send/receive messages between apps |
| 7 | scheduler | ✅ Done | 25 min | Create request, approve, decline |
| 8 | rtc-calls | ✅ Done | 35 min | Both peers join 100ms room |
| 9 | session-logs | ✅ Done | 10 min | Logs created, filtered, rated |
| 10 | polish-dx-docs | 🔄 In Progress | 20 min | Zero lint, ledger complete, docs done |

## Key Files Created

### Shared Package
- `shared/lib/models/` — User, Message, CallRequest, RoomMeta, SessionLog
- `shared/lib/services/` — ApiService, AuthService, ChatService, CallService, LogService, PollService
- `shared/lib/widgets/` — ConversationScreen, ChatListScreen, ScheduleCallScreen, CallRequestsScreen, SessionLogsScreen, VideoCallScreen
- `shared/lib/config/app_config.dart` — Server URL, 100ms config, polling intervals

### Apps
- `guru_app/lib/main.dart` — Hive init, routing, blue theme
- `guru_app/lib/screens/` — OnboardingScreen, ProfileSetupScreen, GuruHomeScreen
- `trainer_app/lib/main.dart` — Hive init, routing, red theme
- `trainer_app/lib/screens/` — LoginScreen, TrainerHomeScreen

### Token Server
- `token_server/index.js` — Full relay hub (chat, auth, calls, logs, 100ms tokens, polling)
- `token_server/.env` — 100ms credentials

### Documentation
- `README.md`, `ARCHITECTURE.md`, `DECISIONS.md`, `AI_LEDGER.md`
