# Architectural Decision Records

## ADR #1 — State Management: Bloc

**Status:** Accepted

**Context:** Requirements allow Bloc or Provider. Need testable, scalable state management for complex flows (chat, video calls, scheduling).

**Decision:** Use `flutter_bloc` (Bloc + Cubit) throughout.

**Rationale:**
- 100ms provides official Bloc sample app — proven pattern for RTC state
- Clear separation: Events → Bloc → States
- Excellent testability with `bloc_test`
- Equatable states enable efficient rebuilds
- Scales well for complex features like chat + video call

**Consequences:** Slightly more boilerplate than Provider, but better structure for this scope.

---

## ADR #2 — Storage: Hive (Local Cache) + Server (Truth)

**Status:** Accepted

**Context:** Need local storage per app + shared data between two apps on different devices.

**Decision:** Each app uses Hive for local caching. Token server (Node.js) holds source of truth. Apps poll server at 1s interval.

**Rationale:**
- Hive is fast, pure Dart, no native dependencies
- Each app has isolated Hive instance (no file locking issues)
- Server as truth source solves inter-app data sharing cleanly
- 1s polling provides near-real-time UX for demo purposes
- Simple HTTP — no WebSocket complexity within 6h budget

**Alternatives considered:**
- SQLite (sqflite) — more complex, native deps, overkill for this scope
- Firebase Realtime DB — user explicitly chose pure local
- WebSocket — better real-time but more complexity

---

## ADR #3 — RTC Strategy: hmssdk_flutter (Manual)

**Status:** Accepted

**Context:** 100ms offers `hmssdk_flutter` (low-level) and `hms_room_kit` (prebuilt UI).

**Decision:** Use `hmssdk_flutter` directly with custom UI.

**Rationale:**
- Full control over pre-join modal, in-call UI, post-call sheets
- Requirements specify custom UI elements (device check, role-based controls, rating)
- `hms_room_kit` too opinionated — hard to customize for this assignment's specific UX
- Official Bloc sample uses `hmssdk_flutter` directly — proven pattern

**Implementation:**
- Pre-created room ID used for all calls (single room, both roles)
- Token server generates JWT with room_id, user_id, role
- `PreviewCubit` for device check, `RoomOverviewBloc` for in-call state
