# Query Capture — Flutter AI-Native

## Original Query

Build two Flutter mobile applications (Guru App for Member "DK", Trainer App for "Aarav") that interoperate on the same local network. Apps use 100ms SDK for video calling, local Hive storage per app, and a Node.js token server as relay hub for chat and 100ms authentication. Entire process must be AI-native with AI_LEDGER.md evidence. 6-hour deadline.

## Refined Query

1. **Two Flutter apps** in a monorepo (`wtf_flutter_test/`):
   - `guru_app/` — Member persona "DK", primary color Blue `#1769E0`
   - `trainer_app/` — Trainer persona "Aarav", primary color Red `#E50914`
2. **Shared Dart package** (`shared/`) — models, services, widgets, utils
3. **Node.js token server** (`token_server/`) — relay hub for chat messages, call request management, 100ms JWT token generation, session logs
4. **100ms SDK** (`hmssdk_flutter`) — video conferencing using pre-created room with host/guest roles
5. **Features:** Onboarding → Chat → Call Scheduling → Video Call → Session Logs
6. **State management:** Bloc
7. **Local storage:** Hive (per-app cache, server is truth)
8. **Inter-app communication:** HTTP polling (1s interval) to token server running on Mac's local IP

## Key Assumptions

- Using Bloc for state management (confirmed by user)
- Using Hive for local cache per app (confirmed)
- Token server handles: chat relay, 100ms tokens, call requests, session logs
- Pre-created 100ms room (ID: `69eb0eb2d63b6068ded6f1f3`) with roles: host (trainer), guest (member)
- Apps connect to token server via Mac's local network IP (`192.168.0.122:3000`)
- No Firebase — pure local
- HTTP polling at 1s for near-real-time feel

## Clarification Questions

None — all clarified with user. Proceeding with assumptions above.

## Verification Checkpoint

User confirmed architecture, credentials, and Bloc choice. Plan approved. Proceeding to execution.
