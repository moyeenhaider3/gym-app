import '../models/user.dart';
import 'api_service.dart';

/// Authentication service — login, profile, trainer assignment.
class AuthService {
  final ApiService _api;

  AuthService(this._api);

  Future<User> login({
    required String userId,
    required String role,
    required String name,
    String? email,
  }) async {
    final data = await _api.post('/api/auth/login', {
      'userId': userId,
      'role': role,
      'name': name,
      'email': email ?? '',
    });
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> assignTrainer({
    required String memberId,
    required String trainerId,
  }) async {
    final data = await _api.patch('/api/auth/assign-trainer', {
      'memberId': memberId,
      'trainerId': trainerId,
    });
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<List<User>> getUsers({String? role}) async {
    final params = <String, String>{};
    if (role != null) params['role'] = role;
    final data = await _api.get('/api/users', queryParams: params);
    final list = data['users'] as List;
    return list.map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
  }
}
