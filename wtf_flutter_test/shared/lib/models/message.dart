import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 1)
class Message extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String receiverId;

  @HiveField(4)
  final String text;

  @HiveField(5)
  final String createdAt;

  @HiveField(6)
  final String status; // 'sent' | 'read'

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.status = 'sent',
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      text: json['text'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String? ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatId': chatId,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'createdAt': createdAt,
    'status': status,
  };

  Message copyWith({String? status}) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  bool get isSystemMessage => senderId == 'system';
  bool get isRead => status == 'read';
  DateTime get dateTime => DateTime.parse(createdAt);

  @override
  List<Object?> get props => [id, chatId, senderId, receiverId, text, createdAt, status];
}
