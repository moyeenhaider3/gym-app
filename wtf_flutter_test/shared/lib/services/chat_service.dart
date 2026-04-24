import 'dart:async';
import '../models/message.dart';
import 'api_service.dart';

/// Chat service — send, receive, mark read, list chats.
class ChatService {
  final ApiService _api;
  final _messageController = StreamController<List<Message>>.broadcast();

  Stream<List<Message>> get messageStream => _messageController.stream;

  ChatService(this._api);

  Future<Message> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final data = await _api.post('/api/messages', {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
    });
    return Message.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<List<Message>> getMessages({
    String? chatId,
    String? senderId,
    String? receiverId,
    String? after,
  }) async {
    final params = <String, String>{};
    if (chatId != null) params['chatId'] = chatId;
    if (senderId != null) params['senderId'] = senderId;
    if (receiverId != null) params['receiverId'] = receiverId;
    if (after != null) params['after'] = after;

    final data = await _api.get('/api/messages', queryParams: params);
    final list = data['messages'] as List;
    return list.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<void> markAsRead({required String chatId, required String readerId}) async {
    await _api.patch('/api/messages/read', {
      'chatId': chatId,
      'readerId': readerId,
    });
  }

  Future<List<ChatPreview>> getChatList(String userId) async {
    final data = await _api.get('/api/chats', queryParams: {'userId': userId});
    final list = data['chats'] as List;
    return list.map((c) => ChatPreview.fromJson(c as Map<String, dynamic>)).toList();
  }

  void pushMessages(List<Message> messages) {
    _messageController.add(messages);
  }

  void dispose() => _messageController.close();
}

/// Chat list preview model.
class ChatPreview {
  final String chatId;
  final Map<String, dynamic> otherUser;
  final Message lastMessage;
  final int unreadCount;

  ChatPreview({
    required this.chatId,
    required this.otherUser,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    return ChatPreview(
      chatId: json['chatId'] as String,
      otherUser: json['otherUser'] as Map<String, dynamic>,
      lastMessage: Message.fromJson(json['lastMessage'] as Map<String, dynamic>),
      unreadCount: json['unreadCount'] as int,
    );
  }

  String get otherUserName => otherUser['name'] as String? ?? 'Unknown';
  String get otherUserId => otherUser['id'] as String? ?? '';
}
