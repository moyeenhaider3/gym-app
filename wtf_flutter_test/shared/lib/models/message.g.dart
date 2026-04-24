part of 'message.dart';

// Hand-written Hive TypeAdapter for Message


class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 1;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      id: fields[0] as String,
      chatId: fields[1] as String,
      senderId: fields[2] as String,
      receiverId: fields[3] as String,
      text: fields[4] as String,
      createdAt: fields[5] as String,
      status: fields[6] as String? ?? 'sent',
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.chatId)
      ..writeByte(2)..write(obj.senderId)
      ..writeByte(3)..write(obj.receiverId)
      ..writeByte(4)..write(obj.text)
      ..writeByte(5)..write(obj.createdAt)
      ..writeByte(6)..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MessageAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
