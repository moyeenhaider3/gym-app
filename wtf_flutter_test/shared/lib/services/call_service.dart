import '../models/call_request.dart';
import 'api_service.dart';

/// Call request service — create, list, approve, decline.
class CallService {
  final ApiService _api;

  CallService(this._api);

  Future<CallRequest> createRequest({
    required String memberId,
    required String trainerId,
    required String scheduledFor,
    String note = '',
  }) async {
    final data = await _api.post('/api/call-requests', {
      'memberId': memberId,
      'trainerId': trainerId,
      'scheduledFor': scheduledFor,
      'note': note,
    });
    return CallRequest.fromJson(data['callRequest'] as Map<String, dynamic>);
  }

  Future<List<CallRequest>> getRequests({
    String? trainerId,
    String? memberId,
    String? status,
  }) async {
    final params = <String, String>{};
    if (trainerId != null) params['trainerId'] = trainerId;
    if (memberId != null) params['memberId'] = memberId;
    if (status != null) params['status'] = status;

    final data = await _api.get('/api/call-requests', queryParams: params);
    final list = data['callRequests'] as List;
    return list.map((c) => CallRequest.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<CallRequest> approve(String requestId) async {
    final data = await _api.patch('/api/call-requests/$requestId', {
      'status': 'approved',
    });
    return CallRequest.fromJson(data['callRequest'] as Map<String, dynamic>);
  }

  Future<CallRequest> decline(String requestId, {String reason = ''}) async {
    final data = await _api.patch('/api/call-requests/$requestId', {
      'status': 'declined',
      'declineReason': reason,
    });
    return CallRequest.fromJson(data['callRequest'] as Map<String, dynamic>);
  }

  Future<String> getToken({
    required String userId,
    required String role,
    String? roomId,
  }) async {
    final params = <String, String>{
      'userId': userId,
      'role': role,
    };
    if (roomId != null) params['roomId'] = roomId;

    final data = await _api.get('/api/token', queryParams: params);
    return data['token'] as String;
  }
}
