part of 'session_log.dart';

// Hand-written Hive TypeAdapter for SessionLog


class SessionLogAdapter extends TypeAdapter<SessionLog> {
  @override
  final int typeId = 3;

  @override
  SessionLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionLog(
      id: fields[0] as String,
      memberId: fields[1] as String,
      trainerId: fields[2] as String,
      startedAt: fields[3] as String,
      endedAt: fields[4] as String,
      durationSec: fields[5] as int,
      rating: fields[6] as int?,
      trainerNotes: fields[7] as String?,
      memberNotes: fields[8] as String?,
      createdAt: fields[9] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, SessionLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.memberId)
      ..writeByte(2)..write(obj.trainerId)
      ..writeByte(3)..write(obj.startedAt)
      ..writeByte(4)..write(obj.endedAt)
      ..writeByte(5)..write(obj.durationSec)
      ..writeByte(6)..write(obj.rating)
      ..writeByte(7)..write(obj.trainerNotes)
      ..writeByte(8)..write(obj.memberNotes)
      ..writeByte(9)..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SessionLogAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
