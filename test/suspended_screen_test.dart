import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/screens/contact_support_screen.dart';
import 'package:penny_pal/screens/suspended_screen.dart';
import 'package:penny_pal/theme/app_theme.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(theme: AppTheme.light(AppColors.brand), home: child);

  group('SuspendedScreen', () {
    testWidgets('offers a way to contact the admin', (tester) async {
      // A blocked user who cannot reach support has no way to appeal, which is
      // the exact gap this screen had.
      await tester.pumpWidget(host(const SuspendedScreen(name: 'Ali')));
      await tester.pumpAndSettle();

      expect(find.text('Contact admin'), findsOneWidget);
      expect(find.byIcon(Icons.support_agent_rounded), findsOneWidget);
    });

    testWidgets('still allows signing out', (tester) async {
      await tester.pumpWidget(host(const SuspendedScreen(name: 'Ali')));
      await tester.pumpAndSettle();

      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
    });

    testWidgets('the reason is shown when the admin gave one', (tester) async {
      await tester.pumpWidget(
        host(
          const SuspendedScreen(
            name: 'Ali',
            reason: 'Multiple accounts detected',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Multiple accounts detected'), findsOneWidget);
      expect(find.textContaining('Ali'), findsWidgets);
    });

    testWidgets('tapping Contact admin opens the pre-filled appeal form', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SuspendedScreen(
            name: 'Ali',
            reason: 'Multiple accounts detected',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contact admin'));
      await tester.pumpAndSettle();

      // The pushed form is inspected rather than read off screen, so the
      // pre-fill is checked directly on the widget that was passed.
      final pushed = tester.widget<ContactSupportScreen>(
        find.byType(ContactSupportScreen),
      );
      expect(pushed.title, 'Appeal Suspension');
      expect(pushed.initialSubject, 'Request to restore access');
      expect(pushed.initialTopic, 'Account & login');
      // The name and the stated reason are carried into the message, so the
      // admin knows who is appealing and what was cited.
      expect(pushed.initialMessage, contains('Ali'));
      expect(pushed.initialMessage, contains('Multiple accounts detected'));
    });

    testWidgets('the appeal form still renders when the backend is down', (
      tester,
    ) async {
      // A suspended user with no working Firestore must still be able to read
      // the form. Only the history list is allowed to fail.
      await tester.pumpWidget(
        host(
          const ContactSupportScreen(
            title: 'Appeal Suspension',
            initialSubject: 'Request to restore access',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Appeal Suspension'), findsOneWidget);
      expect(find.text('Request to restore access'), findsOneWidget);
      expect(find.text('Submit query'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives 2x text scaling without overflowing', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: host(
            const SuspendedScreen(
              name: 'Ali',
              reason: 'Multiple accounts detected',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Contact admin'), findsOneWidget);
    });
  });
}
