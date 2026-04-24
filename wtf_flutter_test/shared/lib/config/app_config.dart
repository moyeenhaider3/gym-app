/// Central configuration for both apps.
/// Update [serverUrl] to your Mac's local network IP before running.
class AppConfig {
  /// Token server base URL.
  /// Both Android devices must be on the same WiFi as this machine.
  static const String serverUrl = 'http://192.168.0.122:3000';

  /// 100ms pre-created room ID.
  static const String hmsRoomId = '69eb0eb2d63b6068ded6f1f3';

  /// 100ms role names (must match dashboard config).
  static const String hmsRoleTrainer = 'host';
  static const String hmsRoleMember = 'guest';

  /// Polling interval for chat / call request updates.
  static const Duration pollInterval = Duration(seconds: 1);

  /// Chat typing indicator delay range.
  static const Duration typingDelayMin = Duration(milliseconds: 400);
  static const Duration typingDelayMax = Duration(milliseconds: 800);
}
