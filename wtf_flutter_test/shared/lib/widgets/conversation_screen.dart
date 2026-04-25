import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:math';

class ConversationScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ConversationScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _apiService = ApiService();
  late final ChatService _chatService;
  late final String _myUserId;
  Timer? _pollTimer;
  Timer? _typingTimer;
  final _random = Random();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(_apiService);
    final settings = Hive.box('settings');
    _myUserId = settings.get('userId', defaultValue: '') as String;
    _loadMessages();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(AppConfig.pollInterval, (_) => _loadMessages());
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getMessages(
        senderId: _myUserId,
        receiverId: widget.otherUserId,
      );
      if (mounted) {
        final hadMessages = _messages.length;
        final hasNewInbound = messages.length > hadMessages &&
            messages.isNotEmpty &&
            messages.last.senderId != _myUserId;

        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        // Show typing indicator on new inbound messages
        if (hasNewInbound && hadMessages > 0) {
          _showTypingIndicator();
        }

        // Auto-scroll if new messages arrived
        if (messages.length > hadMessages) {
          _scrollToBottom();
        }
        // Mark as read
        final cid = [_myUserId, widget.otherUserId]..sort();
        _chatService.markAsRead(chatId: cid.join('_'), readerId: _myUserId);
      }
    } catch (e) {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showTypingIndicator() {
    _typingTimer?.cancel();
    setState(() => _isTyping = true);
    final delay = _random.nextInt(400) + 400; // 400–800ms
    _typingTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted) setState(() => _isTyping = false);
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    try {
      await _chatService.sendMessage(
        senderId: _myUserId,
        receiverId: widget.otherUserId,
        text: text,
      );
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No messages yet', style: TextStyle(color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            Text('Say hi! 👋', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildBubble(msg, theme);
                        },
                      ),
          ),
          // Typing indicator
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _isTyping
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _TypingDots(otherUserName: widget.otherUserName),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Quick reply chips
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: ['Hi Coach 👋', 'Quick question', 'Need help!'].map((chip) {
                  return ActionChip(
                    label: Text(chip),
                    onPressed: () {
                      _textController.text = chip;
                      _sendMessage();
                    },
                  );
                }).toList(),
              ),
            ),
          // Input bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Message msg, ThemeData theme) {
    if (msg.isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(msg.text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
        ),
      );
    }

    final isMe = msg.senderId == _myUserId;
    final time = _formatTime(msg.dateTime);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : Colors.grey.shade500,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: msg.isRead ? Colors.lightBlueAccent : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

/// Animated three-dot typing indicator widget.
class _TypingDots extends StatefulWidget {
  final String otherUserName;
  const _TypingDots({required this.otherUserName});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger the animations
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.otherUserName} is typing',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
        ),
        const SizedBox(width: 4),
        ...List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ],
    );
  }
}
