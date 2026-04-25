import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'call_request.g.dart';

@HiveType(typeId: 2)
class CallRequest extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String memberId;

  @HiveField(2)
  final String trainerId;

  @HiveField(3)
  final String requestedAt;

  @HiveField(4)
  final String scheduledFor;

  @HiveField(5)
  final String note;

  @HiveField(6)
  final String status; // 'pending' | 'approved' | 'declined' | 'cancelled'

  @HiveField(7)
  final String? declineReason;

  @HiveField(8)
  final RoomMeta? roomMeta;

  const CallRequest({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.requestedAt,
    required this.scheduledFor,
    this.note = '',
    this.status = 'pending',
    this.declineReason,
    this.roomMeta,
  });

  factory CallRequest.fromJson(Map<String, dynamic> json) {
    return CallRequest(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      trainerId: json['trainerId'] as String,
      requestedAt: json['requestedAt'] as String,
      scheduledFor: json['scheduledFor'] as String,
      note: json['note'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      declineReason: json['declineReason'] as String?,
      roomMeta: json['roomMeta'] != null
          ? RoomMeta.fromJson(json['roomMeta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'trainerId': trainerId,
        'requestedAt': requestedAt,
        'scheduledFor': scheduledFor,
        'note': note,
        'status': status,
        'declineReason': declineReason,
        'roomMeta': roomMeta?.toJson(),
      };

  CallRequest copyWith(
      {String? status, String? declineReason, RoomMeta? roomMeta}) {
    return CallRequest(
      id: id,
      memberId: memberId,
      trainerId: trainerId,
      requestedAt: requestedAt,
      scheduledFor: scheduledFor,
      note: note,
      status: status ?? this.status,
      declineReason: declineReason ?? this.declineReason,
      roomMeta: roomMeta ?? this.roomMeta,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDeclined => status == 'declined';
  DateTime get scheduledDateTime => DateTime.parse(scheduledFor);

  /// Call joinable if approved and within 10 minutes of scheduled time.
  bool get isJoinable {
    if (!isApproved || roomMeta == null) return false;
    final now = DateTime.now().toUtc();
    final scheduled = scheduledDateTime.toUtc();
    final diff = scheduled.difference(now).inMinutes;
    return diff <= 10 && diff >= -60;
  }

  @override
  List<Object?> get props => [
        id,
        memberId,
        trainerId,
        requestedAt,
        scheduledFor,
        note,
        status,
        declineReason,
        roomMeta
      ];
}

@HiveType(typeId: 4)
class RoomMeta extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String callRequestId;

  @HiveField(2)
  final String hmsRoomId;

  @HiveField(3)
  final String hmsRoleMember;

  @HiveField(4)
  final String hmsRoleTrainer;

  const RoomMeta({
    required this.id,
    required this.callRequestId,
    required this.hmsRoomId,
    required this.hmsRoleMember,
    required this.hmsRoleTrainer,
  });

  factory RoomMeta.fromJson(Map<String, dynamic> json) {
    return RoomMeta(
      id: json['id'] as String,
      callRequestId: json['callRequestId'] as String,
      hmsRoomId: json['hmsRoomId'] as String,
      hmsRoleMember: json['hmsRoleMember'] as String,
      hmsRoleTrainer: json['hmsRoleTrainer'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'callRequestId': callRequestId,
        'hmsRoomId': hmsRoomId,
        'hmsRoleMember': hmsRoleMember,
        'hmsRoleTrainer': hmsRoleTrainer,
      };

  @override
  List<Object?> get props =>
      [id, callRequestId, hmsRoomId, hmsRoleMember, hmsRoleTrainer];
}
