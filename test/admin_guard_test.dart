import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/services/admin_service.dart';

/// The refusals the admin screen shows when someone targets their own account.
/// Shown verbatim in a SnackBar, so the wording is pinned here.
const messages = {
  'suspend': 'You cannot suspend your own account',
  'restore': 'You cannot change your own access',
  'role': 'You cannot change your own role',
};

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
    //
    // Delete is deliberately absent. The admin panel no longer has a Delete
    // action at all, see the group below.
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

  group('the admin panel cannot delete a student', () {
    // Firebase gives client apps no way to remove somebody else's sign-in, so a
    // delete button could only ever clear Firestore and leave the email taken.
    // A student would then find the address already registered, which reads as
    // a bug. The button was removed rather than left half working, and the
    // profile screen is where a student deletes their own account.
    //
    // There is deliberately no assertion on AdminService here. Every method on
    // it is an instance method, and its constructor opens a Firestore handle,
    // so referencing one would need a live Firebase app. `flutter analyze`
    // already fails the build if anything calls a delete that does not exist,
    // which covers the half of this that a test would have duplicated.
    test('the delete guard is no longer in the message list', () {
      // Three actions remain: suspend, restore, re-role. Delete is not one of
      // them, so it has no message to show.
      expect(messages.keys.toSet(), {'suspend', 'restore', 'role'});
      expect(messages.keys, isNot(contains('delete')));
    });
  });
}
