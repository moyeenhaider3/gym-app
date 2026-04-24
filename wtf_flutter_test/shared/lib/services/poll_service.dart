import 'dart:async';
import '../models/models.dart';
import 'api_service.dart';
import '../config/app_config.dart';

/// Polling service — periodic fetch of new messages, call request updates.
class PollService {
  final ApiService _api;
  final String userId;
  Timer? _timer;
  String _lastPollTime = DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();

  final _messageController = StreamController<List<Message>>.broadcast();
  final _callRequestController = StreamController<List<CallRequest>>.broadcast();
  final _readUpdateController = StreamController<List<Message>>.broadcast();

  Stream<List<Message>> get newMessages => _messageController.stream;
  Stream<List<CallRequest>> get callRequestUpdates => _callRequestController.stream;
  Stream<List<Message>> get readUpdates => _readUpdateController.stream;

  PollService(this._api, this.userId);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(AppConfig.pollInterval, (_) => _poll());
    // Also poll immediately
    _poll();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      final data = await _api.get('/api/poll', queryParams: {
        'userId': userId,
        'since': _lastPollTime,
      });

      final serverTime = data['serverTime'] as String?;
      if (serverTime != null) _lastPollTime = serverTime;

      // New messages
      final msgList = data['newMessages'] as List? ?? [];
      if (msgList.isNotEmpty) {
        final messages = msgList.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
        _messageController.add(messages);
      }

      // Call request updates
      final crList = data['callRequests'] as List? ?? [];
      if (crList.isNotEmpty) {
        final requests = crList.map((c) => CallRequest.fromJson(c as Map<String, dynamic>)).toList();
        _callRequestController.add(requests);
      }

      // Read status updates
      final readList = data['readUpdates'] as List? ?? [];
      if (readList.isNotEmpty) {
        final reads = readList.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
        _readUpdateController.add(reads);
      }
    } catch (e) {
      // Silent fail on poll — network blip, server down, etc.
      // App keeps working with cached data.
    }
  }

  void dispose() {
    stop();
    _messageController.close();
    _callRequestController.close();
    _readUpdateController.close();
  }
}
