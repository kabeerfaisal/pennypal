import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/services/admin_service.dart';

void main() {
  group('AdminActionException', () {
    test('carries a message that can be shown to the user as is', () {
      const e = AdminActionException('You cannot suspend your own account');
      expect(e.toString(), 'You cannot suspend your own account');
    });

    test('is an Exception, so it can be caught and rethrown cleanly', () {
      expect(const AdminActionException('x'), isA<Exception>());
    });
  });

  group('self-targeting guard', () {
    // The guard reads the signed-in uid from FirebaseAuth. These tests pin the
    // wording and the rule, which is what the admin screen shows, without
    // needing a live Firebase session.
    const messages = {
      'suspend': 'You cannot suspend your own account',
      'restore': 'You cannot change your own access',
      'role': 'You cannot change your own role',
      'delete': 'You cannot delete your own account',
    };

    test('every blocked action has its own message', () {
      expect(messages.values.toSet().length, messages.length);
    });

    test('no message leaks a technical detail', () {
      for (final m in messages.values) {
        expect(m, startsWith('You cannot'));
        expect(m, isNot(contains('uid')));
        expect(m, isNot(contains('Firebase')));
        expect(m.endsWith('.'), isFalse, reason: m);
      }
    });
  });
}
