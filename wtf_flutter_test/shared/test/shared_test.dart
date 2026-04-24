import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('User model', () {
    test('fromJson/toJson round-trip', () {
      final json = {
        'id': 'user1',
        'role': 'member',
        'name': 'DK',
        'email': 'dk@test.com',
        'avatarUrl': null,
        'assignedTrainerId': 'trainer_aarav',
      };
      final user = User.fromJson(json);
      expect(user.id, 'user1');
      expect(user.isMember, true);
      expect(user.isTrainer, false);

      final back = user.toJson();
      expect(back['id'], 'user1');
      expect(back['role'], 'member');
    });
  });

  group('Message model', () {
    test('system message detection', () {
      final msg = Message(
        id: 'm1',
        chatId: 'c1',
        senderId: 'system',
        receiverId: 'all',
        text: 'Call approved',
        createdAt: DateTime.now().toIso8601String(),
      );
      expect(msg.isSystemMessage, true);
    });
  });

  group('SessionLog model', () {
    test('duration formatting', () {
      final log = SessionLog(
        id: 'l1',
        memberId: 'm1',
        trainerId: 't1',
        startedAt: '2026-04-24T10:00:00Z',
        endedAt: '2026-04-24T10:05:30Z',
        durationSec: 330,
        createdAt: '2026-04-24T10:05:30Z',
      );
      expect(log.durationFormatted, '5m 30s');
    });
  });
}
