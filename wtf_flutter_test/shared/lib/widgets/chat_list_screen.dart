import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _apiService = ApiService();
  late final ChatService _chatService;
  late final String _myUserId;
  Timer? _pollTimer;

  List<ChatPreview> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(_apiService);
    final settings = Hive.box('settings');
    _myUserId = settings.get('userId', defaultValue: '') as String;
    _loadChats();
    _pollTimer = Timer.periodic(AppConfig.pollInterval, (_) => _loadChats());
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatService.getChatList(_myUserId);
      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No conversations yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Start a chat!', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _chats.length,
                  separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return _buildChatTile(context, chat, theme);
                  },
                ),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatPreview chat, ThemeData theme) {
    final isSystemMsg = chat.lastMessage.isSystemMessage;
    final previewText = isSystemMsg ? '📢 ${chat.lastMessage.text}' : chat.lastMessage.text;
    final timeAgo = _relativeTime(chat.lastMessage.dateTime);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Text(
          chat.otherUserName[0].toUpperCase(),
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.otherUserName,
              style: TextStyle(
                fontWeight: chat.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(timeAgo, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              previewText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(
              otherUserId: chat.otherUserId,
              otherUserName: chat.otherUserName,
            ),
          ),
        );
      },
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
