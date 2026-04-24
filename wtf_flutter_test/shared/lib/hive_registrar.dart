import 'package:hive/hive.dart';
import 'models/user.dart';
import 'models/message.dart';
import 'models/call_request.dart';
import 'models/session_log.dart';

/// Register all Hive type adapters. Call once before opening boxes.
void registerHiveAdapters() {
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(CallRequestAdapter());
  Hive.registerAdapter(RoomMetaAdapter());
  Hive.registerAdapter(SessionLogAdapter());
}
