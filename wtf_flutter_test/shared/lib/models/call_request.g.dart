part of 'call_request.dart';

// Hand-written Hive TypeAdapters for CallRequest + RoomMeta


class CallRequestAdapter extends TypeAdapter<CallRequest> {
  @override
  final int typeId = 2;

  @override
  CallRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CallRequest(
      id: fields[0] as String,
      memberId: fields[1] as String,
      trainerId: fields[2] as String,
      requestedAt: fields[3] as String,
      scheduledFor: fields[4] as String,
      note: fields[5] as String? ?? '',
      status: fields[6] as String? ?? 'pending',
      declineReason: fields[7] as String?,
      roomMeta: fields[8] as RoomMeta?,
    );
  }

  @override
  void write(BinaryWriter writer, CallRequest obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.memberId)
      ..writeByte(2)..write(obj.trainerId)
      ..writeByte(3)..write(obj.requestedAt)
      ..writeByte(4)..write(obj.scheduledFor)
      ..writeByte(5)..write(obj.note)
      ..writeByte(6)..write(obj.status)
      ..writeByte(7)..write(obj.declineReason)
      ..writeByte(8)..write(obj.roomMeta);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CallRequestAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class RoomMetaAdapter extends TypeAdapter<RoomMeta> {
  @override
  final int typeId = 4;

  @override
  RoomMeta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoomMeta(
      id: fields[0] as String,
      callRequestId: fields[1] as String,
      hmsRoomId: fields[2] as String,
      hmsRoleMember: fields[3] as String,
      hmsRoleTrainer: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RoomMeta obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.callRequestId)
      ..writeByte(2)..write(obj.hmsRoomId)
      ..writeByte(3)..write(obj.hmsRoleMember)
      ..writeByte(4)..write(obj.hmsRoleTrainer);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoomMetaAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
