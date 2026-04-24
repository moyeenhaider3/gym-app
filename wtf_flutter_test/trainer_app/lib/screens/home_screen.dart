import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/shared.dart';

class TrainerHomeScreen extends StatelessWidget {
  const TrainerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Hive.box('settings');
    final userName = settings.get('userName', defaultValue: 'Aarav') as String;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Trainer',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $userName 💪', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Manage your members and sessions', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildTile(
                    context,
                    icon: Icons.chat_bubble_outline,
                    title: 'Chats',
                    color: const Color(0xFFE50914),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ChatListScreen(),
                      ));
                    },
                  ),
                  _buildTile(
                    context,
                    icon: Icons.notifications_none,
                    title: 'Requests',
                    color: const Color(0xFFF79009),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const CallRequestsScreen(isTrainer: true),
                      ));
                    },
                  ),
                  _buildTile(
                    context,
                    icon: Icons.history,
                    title: 'Sessions',
                    color: const Color(0xFF12B76A),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const SessionLogsScreen(),
                      ));
                    },
                  ),
                  _buildTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'DK Chat',
                    color: const Color(0xFF1769E0),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ConversationScreen(
                          otherUserId: 'member_dk',
                          otherUserName: 'DK',
                        ),
                      ));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
