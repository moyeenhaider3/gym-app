import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/shared.dart';

class GuruHomeScreen extends StatelessWidget {
  const GuruHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Hive.box('settings');
    final userName = settings.get('userName', defaultValue: 'DK') as String;

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
                'Member',
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
            Text('Welcome, $userName 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('What would you like to do today?', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            _buildCard(
              context,
              icon: Icons.chat_bubble_outline,
              title: 'Chat with Trainer',
              subtitle: 'Message Aarav directly',
              color: const Color(0xFF1769E0),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ConversationScreen(
                    otherUserId: 'trainer_aarav',
                    otherUserName: 'Aarav',
                  ),
                ));
              },
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              icon: Icons.calendar_today,
              title: 'Schedule Call',
              subtitle: 'Book a video session',
              color: const Color(0xFFF79009),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ScheduleCallScreen(),
                ));
              },
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              icon: Icons.notifications_none,
              title: 'My Requests',
              subtitle: 'View call request status',
              color: const Color(0xFF7C3AED),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CallRequestsScreen(isTrainer: false),
                ));
              },
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              icon: Icons.history,
              title: 'My Sessions',
              subtitle: 'View past call logs & ratings',
              color: const Color(0xFF12B76A),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const SessionLogsScreen(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
