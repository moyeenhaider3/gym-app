import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'session_log.g.dart';

@HiveType(typeId: 3)
class SessionLog extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String memberId;

  @HiveField(2)
  final String trainerId;

  @HiveField(3)
  final String startedAt;

  @HiveField(4)
  final String endedAt;

  @HiveField(5)
  final int durationSec;

  @HiveField(6)
  final int? rating;

  @HiveField(7)
  final String? trainerNotes;

  @HiveField(8)
  final String? memberNotes;

  @HiveField(9)
  final String createdAt;

  const SessionLog({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    this.rating,
    this.trainerNotes,
    this.memberNotes,
    required this.createdAt,
  });

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    return SessionLog(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      trainerId: json['trainerId'] as String,
      startedAt: json['startedAt'] as String,
      endedAt: json['endedAt'] as String,
      durationSec: json['durationSec'] as int,
      rating: json['rating'] as int?,
      trainerNotes: json['trainerNotes'] as String?,
      memberNotes: json['memberNotes'] as String?,
      createdAt: json['createdAt'] as String? ?? json['startedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'trainerId': trainerId,
    'startedAt': startedAt,
    'endedAt': endedAt,
    'durationSec': durationSec,
    'rating': rating,
    'trainerNotes': trainerNotes,
    'memberNotes': memberNotes,
    'createdAt': createdAt,
  };

  SessionLog copyWith({int? rating, String? trainerNotes, String? memberNotes}) {
    return SessionLog(
      id: id,
      memberId: memberId,
      trainerId: trainerId,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSec: durationSec,
      rating: rating ?? this.rating,
      trainerNotes: trainerNotes ?? this.trainerNotes,
      memberNotes: memberNotes ?? this.memberNotes,
      createdAt: createdAt,
    );
  }

  /// Format duration as "Xm Ys"
  String get durationFormatted {
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  DateTime get startDateTime => DateTime.parse(startedAt);
  DateTime get endDateTime => DateTime.parse(endedAt);

  @override
  List<Object?> get props => [id, memberId, trainerId, startedAt, endedAt, durationSec, rating, trainerNotes, memberNotes];
}
