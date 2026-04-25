# AI Ledger — Flutter AI-Native Assignment

| Prompt # | Tool | Intent | Output Snippet | Commit Link |
|----------|------|--------|----------------|-------------|
| 1 | Claude | Architecture planning — monorepo structure, state mgmt choice, inter-app communication strategy | Bloc + Hive + Node.js relay server architecture. Token server as hub for chat + 100ms tokens. | `b479898` |
| 2 | Claude | 100ms Flutter SDK research — quickstart guide, Bloc sample app, token generation | JWT HS256 payload structure, HMSUpdateListener callbacks, HMSVideoView widget usage | `b479898` |
| 3 | Claude | Token server design — Express API endpoints for chat relay, 100ms auth, call request management | Full REST API with in-memory store, polling endpoint for near-real-time updates | `b479898` |
| 4 | Claude | Data model design — User, Message, CallRequest, SessionLog, RoomMeta with Hive TypeAdapters | Equatable models with toJson/fromJson, Hive TypeIds 0-4 | `b479898` |
| 5 | Claude | Shared services layer — ApiService, ChatService, CallService, PollService architecture | HTTP client with polling strategy, StreamController-based reactive updates | `b479898` |
| 6 | Claude | Investigate UTC to IST timezone issues in display formatting | Use `.toLocal()` on UI layer without modifying underlying Hive UTC storage | `bbd5d56` |
| 7 | Claude | Fix 10-minute 'Join Call' button visibility condition | Use `DateTime.now().toUtc()` instead of local time, ensuring consistent comparison against `scheduledDateTime.toUtc()` | `bbd5d56` |
| 8 | Claude | Generate animated typing indicator widget for ConversationScreen | Custom `_TypingDots` widget using staggered `AnimationController`s | `bbd5d56` |
| 9 | Claude | Resolve `CantAccessCaptureDevice (code=3001)` from 100ms SDK | Add `permission_handler` checks for Camera/Microphone before calling `hmsSDK.build()` | `a006e92` |
| 10 | Claude | Fix software keyboard overlapping BottomSheet post-call | Enable `isScrollControlled: true` and apply `MediaQuery.of(context).viewInsets.bottom` padding to modal content | `a006e92` |
| 11 | Claude | Enforce 10-minute pre-join window | Revert joinable interval to exactly 10 minutes to meet specification | Pending |

## Debugging with AI

**1. Bug:** `CantAccessCaptureDevice (code=3001)` in `hmssdk_flutter`
- **Error Context:** The 100ms SDK attempts to access capture devices when initializing `HMSConfig`, causing an immediate crash on physical Android devices because the app lacks permission.
- **AI Steps to Fix:** 
  1. Identified that `permission_handler` is needed to explicitly request `Permission.camera` and `Permission.microphone`.
  2. Moved the `hmsSDK.build()` call to execute *only after* permissions are successfully granted.
  3. Built a pre-join workflow displaying a `SnackBar` and `openAppSettings()` fallback if the user denies permissions.

**2. Bug:** Chat timestamps displaying in UTC instead of device-local IST.
- **Error Context:** Timestamps (e.g. `2:40 AM`) were completely off from the physical time (e.g. `9:10 PM`).
- **AI Steps to Fix:** 
  1. Confirmed storage convention to remain UTC ISO8601 strings to maintain consistency across the Token Server relay.
  2. Implemented `.toLocal()` within `_formatTime` inside `ConversationScreen` and DateFormat usages across `SessionLogsScreen` and `ScheduleCallScreen`.

## Refactor with AI

**1. Refactoring Schedule Call Time Slot Logic:**
- **Before:** The UI was rendering past time slots in the Schedule view. String-based array slicing was leading to error-prone Date-time manipulation.
- **After:** Extracted a `_TimeSlot` model class. Filtered `_availableSlots` conditionally by validating `slotTime.isAfter(DateTime.now())` strictly for today, rendering a 'select future date' message automatically when the user has no slots left for the current day.

**2. Refactoring Independent Call Leaves:**
- **Before:** When a user left the 100ms room, the SDK's `onPeerUpdate` (triggered on peer leave) forced the local user's controls to lock up, simulating a global end-call state.
- **After:** Refactored the `HMSUpdateListener` callbacks. `onPeerUpdate` now merely flags `_remotePeerLeft = true` and shows a SnackBar (plus graying out the remote video tile). The local user retains full media control and actively ends their own session independently by calling `_leaveCall()`.
