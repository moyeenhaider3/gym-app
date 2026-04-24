import '../models/session_log.dart';
import 'api_service.dart';

/// Session log service — create, list, update with rating/notes.
class LogService {
  final ApiService _api;

  LogService(this._api);

  Future<SessionLog> createLog({
    required String memberId,
    required String trainerId,
    required String startedAt,
    required String endedAt,
  }) async {
    final data = await _api.post('/api/session-logs', {
      'memberId': memberId,
      'trainerId': trainerId,
      'startedAt': startedAt,
      'endedAt': endedAt,
    });
    return SessionLog.fromJson(data['sessionLog'] as Map<String, dynamic>);
  }

  Future<List<SessionLog>> getLogs({String? userId}) async {
    final params = <String, String>{};
    if (userId != null) params['userId'] = userId;

    final data = await _api.get('/api/session-logs', queryParams: params);
    final list = data['sessionLogs'] as List;
    return list.map((l) => SessionLog.fromJson(l as Map<String, dynamic>)).toList();
  }

  Future<SessionLog> updateLog(String logId, {int? rating, String? trainerNotes, String? memberNotes}) async {
    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (trainerNotes != null) body['trainerNotes'] = trainerNotes;
    if (memberNotes != null) body['memberNotes'] = memberNotes;

    final data = await _api.patch('/api/session-logs/$logId', body);
    return SessionLog.fromJson(data['sessionLog'] as Map<String, dynamic>);
  }
}
