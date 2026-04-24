import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String role; // 'trainer' | 'member'

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String? avatarUrl;

  @HiveField(5)
  final String? assignedTrainerId;

  const User({
    required this.id,
    required this.role,
    required this.name,
    this.email = '',
    this.avatarUrl,
    this.assignedTrainerId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      assignedTrainerId: json['assignedTrainerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'assignedTrainerId': assignedTrainerId,
  };

  User copyWith({
    String? id,
    String? role,
    String? name,
    String? email,
    String? avatarUrl,
    String? assignedTrainerId,
  }) {
    return User(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      assignedTrainerId: assignedTrainerId ?? this.assignedTrainerId,
    );
  }

  bool get isTrainer => role == 'trainer';
  bool get isMember => role == 'member';

  @override
  List<Object?> get props => [id, role, name, email, avatarUrl, assignedTrainerId];
}
